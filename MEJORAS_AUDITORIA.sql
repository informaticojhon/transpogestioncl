-- ============================================
-- MEJORAS: historial de auditoría
-- Ejecutar en Supabase SQL Editor
--
-- Registra automáticamente quién crea, edita o elimina algo en las
-- tablas sensibles de la empresa (servicios, trabajadores, turnos,
-- remuneraciones, materiales, movimientos de material). Útil ahora que
-- varias personas de una misma empresa pueden operar la plataforma.
--
-- El registro lo hace un trigger en la base de datos (no la app), así
-- que queda igual sin importar si el cambio vino de la app, de la API
-- directa, o de cualquier otro cliente.
-- ============================================

CREATE TABLE IF NOT EXISTS auditoria (
  id BIGSERIAL PRIMARY KEY,
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  accion VARCHAR(10) NOT NULL, -- insert, update, delete
  tabla VARCHAR(50) NOT NULL,
  registro_id TEXT,
  datos JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_auditoria_empresa_created ON auditoria(empresa_id, created_at DESC);

ALTER TABLE auditoria ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Solo admin ve auditoria" ON auditoria;
CREATE POLICY "Solo admin ve auditoria"
  ON auditoria FOR SELECT USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');

-- Deliberadamente no hay políticas de INSERT/UPDATE/DELETE para el rol
-- "authenticated": la única forma de escribir en esta tabla es a través
-- de fn_auditoria() (SECURITY DEFINER), así que nadie puede alterar o
-- borrar el historial llamando directo a la API de Supabase.

CREATE OR REPLACE FUNCTION fn_auditoria()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_empresa_id UUID;
  v_registro_id TEXT;
  v_datos JSONB;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_empresa_id := OLD.empresa_id;
    v_registro_id := OLD.id::TEXT;
    v_datos := to_jsonb(OLD) - 'user_id' - 'empresa_id';
  ELSE
    v_empresa_id := NEW.empresa_id;
    v_registro_id := NEW.id::TEXT;
    v_datos := to_jsonb(NEW) - 'user_id' - 'empresa_id';
  END IF;

  INSERT INTO auditoria (empresa_id, user_id, accion, tabla, registro_id, datos)
  VALUES (v_empresa_id, auth.uid(), lower(TG_OP), TG_TABLE_NAME, v_registro_id, v_datos);

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_auditoria_servicios ON servicios;
CREATE TRIGGER trg_auditoria_servicios
  AFTER INSERT OR UPDATE OR DELETE ON servicios
  FOR EACH ROW EXECUTE FUNCTION fn_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_trabajadores ON trabajadores;
CREATE TRIGGER trg_auditoria_trabajadores
  AFTER INSERT OR UPDATE OR DELETE ON trabajadores
  FOR EACH ROW EXECUTE FUNCTION fn_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_turnos ON turnos;
CREATE TRIGGER trg_auditoria_turnos
  AFTER INSERT OR UPDATE OR DELETE ON turnos
  FOR EACH ROW EXECUTE FUNCTION fn_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_remuneraciones ON remuneraciones;
CREATE TRIGGER trg_auditoria_remuneraciones
  AFTER INSERT OR UPDATE OR DELETE ON remuneraciones
  FOR EACH ROW EXECUTE FUNCTION fn_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_materiales ON materiales;
CREATE TRIGGER trg_auditoria_materiales
  AFTER INSERT OR UPDATE OR DELETE ON materiales
  FOR EACH ROW EXECUTE FUNCTION fn_auditoria();

DROP TRIGGER IF EXISTS trg_auditoria_movimientos_material ON movimientos_material;
CREATE TRIGGER trg_auditoria_movimientos_material
  AFTER INSERT OR UPDATE OR DELETE ON movimientos_material
  FOR EACH ROW EXECUTE FUNCTION fn_auditoria();

-- ✅ Listo! Desde ahora cada cambio en esas 6 tablas queda registrado.
-- Los cambios anteriores a ejecutar este script no quedan retroactivamente
-- registrados (no hay forma de reconstruir historial que no se guardó).
