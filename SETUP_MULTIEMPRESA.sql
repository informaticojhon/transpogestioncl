-- ============================================
-- MIGRACIÓN A SOPORTE MULTI-EMPRESA
-- Ejecutar en Supabase SQL Editor
--
-- ⚠️ NO EJECUTAR TODAVÍA: primero hay que actualizar el código Dart
-- (repositorios + pantallas de registro) para que trabaje con
-- empresa_id, o la app dejará de poder crear registros nuevos
-- apenas se apliquen las políticas RLS de este script.
-- ============================================

-- ============================================
-- 1. TABLA DE EMPRESAS
-- ============================================
CREATE TABLE IF NOT EXISTS empresas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  codigo_invitacion TEXT NOT NULL UNIQUE DEFAULT upper(substr(md5(random()::text), 1, 8)),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE empresas IS 'Organización dueña de los datos; varios usuarios pueden pertenecer a la misma empresa y compartir su información';
COMMENT ON COLUMN empresas.codigo_invitacion IS 'Código que un usuario nuevo ingresa para unirse a esta empresa en vez de crear una propia';

-- ============================================
-- 2. USUARIOS: pertenencia a empresa + rol
-- ============================================
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS rol TEXT NOT NULL DEFAULT 'empleado' CHECK (rol IN ('admin', 'empleado'));

COMMENT ON COLUMN usuarios.rol IS 'admin: gestiona equipo, trabajadores y materiales. empleado: registra servicios de su empresa';

-- ============================================
-- 3. AGREGAR empresa_id A LAS TABLAS DE DATOS
-- (se mantiene user_id existente como "creado por"; empresa_id
--  es la nueva columna que define quién puede VER el registro)
-- ============================================
ALTER TABLE servicios ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE;
ALTER TABLE trabajadores ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE;
ALTER TABLE turnos ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE;
ALTER TABLE remuneraciones ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE;
ALTER TABLE materiales ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE;
ALTER TABLE movimientos_material ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE;

-- ============================================
-- 4. MIGRAR USUARIOS Y DATOS EXISTENTES
-- Crea una empresa individual para cada usuario que aún no
-- tenga una, lo deja como admin de ella, y reasigna todos sus
-- registros existentes a esa empresa. No se pierde ni se mezcla
-- ningún dato: cada usuario actual sigue viendo exactamente lo
-- mismo que veía antes.
-- ============================================
DO $$
DECLARE
  u RECORD;
  nueva_empresa_id UUID;
BEGIN
  FOR u IN SELECT id, nombre FROM usuarios WHERE empresa_id IS NULL LOOP
    INSERT INTO empresas (nombre, codigo_invitacion)
    VALUES (
      u.nombre || ' - Empresa',
      upper(substr(md5(random()::text || u.id::text), 1, 8))
    )
    RETURNING id INTO nueva_empresa_id;

    UPDATE usuarios SET empresa_id = nueva_empresa_id, rol = 'admin' WHERE id = u.id;
    UPDATE servicios SET empresa_id = nueva_empresa_id WHERE user_id = u.id;
    UPDATE trabajadores SET empresa_id = nueva_empresa_id WHERE user_id = u.id;
    UPDATE turnos SET empresa_id = nueva_empresa_id WHERE user_id = u.id;
    UPDATE remuneraciones SET empresa_id = nueva_empresa_id WHERE user_id = u.id;
    UPDATE materiales SET empresa_id = nueva_empresa_id WHERE user_id = u.id;
    UPDATE movimientos_material SET empresa_id = nueva_empresa_id WHERE user_id = u.id;
  END LOOP;
END $$;

-- A partir de aquí, toda fila nueva DEBE tener empresa_id.
ALTER TABLE usuarios ALTER COLUMN empresa_id SET NOT NULL;
ALTER TABLE servicios ALTER COLUMN empresa_id SET NOT NULL;
ALTER TABLE trabajadores ALTER COLUMN empresa_id SET NOT NULL;
ALTER TABLE turnos ALTER COLUMN empresa_id SET NOT NULL;
ALTER TABLE remuneraciones ALTER COLUMN empresa_id SET NOT NULL;
ALTER TABLE materiales ALTER COLUMN empresa_id SET NOT NULL;
ALTER TABLE movimientos_material ALTER COLUMN empresa_id SET NOT NULL;

-- Índices para los filtros por empresa
CREATE INDEX IF NOT EXISTS idx_servicios_empresa_id ON servicios(empresa_id);
CREATE INDEX IF NOT EXISTS idx_trabajadores_empresa_id ON trabajadores(empresa_id);
CREATE INDEX IF NOT EXISTS idx_turnos_empresa_id ON turnos(empresa_id);
CREATE INDEX IF NOT EXISTS idx_remuneraciones_empresa_id ON remuneraciones(empresa_id);
CREATE INDEX IF NOT EXISTS idx_materiales_empresa_id ON materiales(empresa_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_material_empresa_id ON movimientos_material(empresa_id);

-- ============================================
-- 5. FUNCIÓN AUXILIAR PARA LAS POLÍTICAS RLS
--
-- Esta función SÍ necesita ser SECURITY DEFINER, y es un caso
-- distinto (y seguro) del de la vista v_trabajadores_resumen que
-- se eliminó:
--
-- - La política de SELECT de "usuarios" usa get_empresa_id() para
--   decidir qué filas mostrar. Si esta función corriera como
--   SECURITY INVOKER, su propia consulta interna a "usuarios"
--   quedaría sujeta a esa misma política → para evaluarla, Postgres
--   necesitaría evaluarla de nuevo → recursión infinita
--   ("infinite recursion detected in policy").
-- - Como SECURITY DEFINER, la consulta interna se salta el RLS,
--   pero solo devuelve UN valor: el empresa_id de auth.uid() (el
--   usuario que ya inició sesión, no algo que el cliente pueda
--   falsificar). Nunca expone filas ni datos de otros usuarios.
--   Es la misma técnica recomendada por la documentación de
--   Supabase para multi-tenancy con RLS.
-- ============================================
CREATE OR REPLACE FUNCTION get_empresa_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT empresa_id FROM usuarios WHERE id = auth.uid();
$$;

-- ============================================
-- 6. REEMPLAZAR POLÍTICAS RLS: de "es mío" a "es de mi empresa"
-- ============================================

-- usuarios: se puede ver a los demás miembros de la propia empresa
-- (necesario para la pantalla "Gestionar mi equipo")
DROP POLICY IF EXISTS "Los usuarios pueden ver sus propios datos" ON usuarios;
CREATE POLICY "Los usuarios pueden ver su empresa"
  ON usuarios FOR SELECT
  USING (empresa_id = get_empresa_id());

-- El INSERT de usuarios sigue siendo "solo mi propia fila al registrarme"
-- (la política ya existente "Los usuarios pueden crear su propio registro"
--  con auth.uid() = id se mantiene sin cambios)

-- servicios
DROP POLICY IF EXISTS "Los usuarios pueden ver sus propios servicios" ON servicios;
DROP POLICY IF EXISTS "Los usuarios pueden insertar sus propios servicios" ON servicios;
DROP POLICY IF EXISTS "Los usuarios pueden actualizar sus propios servicios" ON servicios;
DROP POLICY IF EXISTS "Los usuarios pueden eliminar sus propios servicios" ON servicios;

CREATE POLICY "Empresa puede ver sus servicios"
  ON servicios FOR SELECT USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede crear servicios"
  ON servicios FOR INSERT WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede actualizar servicios"
  ON servicios FOR UPDATE USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede eliminar servicios"
  ON servicios FOR DELETE USING (empresa_id = get_empresa_id());

-- trabajadores
DROP POLICY IF EXISTS "Users can view their own trabajadores" ON trabajadores;
DROP POLICY IF EXISTS "Users can insert their own trabajadores" ON trabajadores;
DROP POLICY IF EXISTS "Users can update their own trabajadores" ON trabajadores;
DROP POLICY IF EXISTS "Users can delete their own trabajadores" ON trabajadores;

CREATE POLICY "Empresa puede ver sus trabajadores"
  ON trabajadores FOR SELECT USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede crear trabajadores"
  ON trabajadores FOR INSERT WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede actualizar trabajadores"
  ON trabajadores FOR UPDATE USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede eliminar trabajadores"
  ON trabajadores FOR DELETE USING (empresa_id = get_empresa_id());

-- turnos
DROP POLICY IF EXISTS "Users can view their own turnos" ON turnos;
DROP POLICY IF EXISTS "Users can insert their own turnos" ON turnos;
DROP POLICY IF EXISTS "Users can update their own turnos" ON turnos;
DROP POLICY IF EXISTS "Users can delete their own turnos" ON turnos;

CREATE POLICY "Empresa puede ver sus turnos"
  ON turnos FOR SELECT USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede crear turnos"
  ON turnos FOR INSERT WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede actualizar turnos"
  ON turnos FOR UPDATE USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede eliminar turnos"
  ON turnos FOR DELETE USING (empresa_id = get_empresa_id());

-- remuneraciones
DROP POLICY IF EXISTS "Users can view their own remuneraciones" ON remuneraciones;
DROP POLICY IF EXISTS "Users can insert their own remuneraciones" ON remuneraciones;
DROP POLICY IF EXISTS "Users can update their own remuneraciones" ON remuneraciones;
DROP POLICY IF EXISTS "Users can delete their own remuneraciones" ON remuneraciones;

CREATE POLICY "Empresa puede ver sus remuneraciones"
  ON remuneraciones FOR SELECT USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede crear remuneraciones"
  ON remuneraciones FOR INSERT WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede actualizar remuneraciones"
  ON remuneraciones FOR UPDATE USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede eliminar remuneraciones"
  ON remuneraciones FOR DELETE USING (empresa_id = get_empresa_id());

-- materiales
DROP POLICY IF EXISTS "Users can view their own materiales" ON materiales;
DROP POLICY IF EXISTS "Users can insert their own materiales" ON materiales;
DROP POLICY IF EXISTS "Users can update their own materiales" ON materiales;
DROP POLICY IF EXISTS "Users can delete their own materiales" ON materiales;

CREATE POLICY "Empresa puede ver sus materiales"
  ON materiales FOR SELECT USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede crear materiales"
  ON materiales FOR INSERT WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede actualizar materiales"
  ON materiales FOR UPDATE USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede eliminar materiales"
  ON materiales FOR DELETE USING (empresa_id = get_empresa_id());

-- movimientos_material
DROP POLICY IF EXISTS "Users can view their own movimientos_material" ON movimientos_material;
DROP POLICY IF EXISTS "Users can insert their own movimientos_material" ON movimientos_material;
DROP POLICY IF EXISTS "Users can update their own movimientos_material" ON movimientos_material;
DROP POLICY IF EXISTS "Users can delete their own movimientos_material" ON movimientos_material;

CREATE POLICY "Empresa puede ver sus movimientos"
  ON movimientos_material FOR SELECT USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede crear movimientos"
  ON movimientos_material FOR INSERT WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede actualizar movimientos"
  ON movimientos_material FOR UPDATE USING (empresa_id = get_empresa_id());
CREATE POLICY "Empresa puede eliminar movimientos"
  ON movimientos_material FOR DELETE USING (empresa_id = get_empresa_id());

-- ============================================
-- 7. RLS en la tabla empresas
-- Un usuario puede ver la empresa a la que pertenece.
-- El INSERT (crear empresa nueva) se hace sin restricción de
-- pertenencia (todavía no pertenece a ninguna), pero solo
-- usuarios autenticados pueden hacerlo.
-- ============================================
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Miembros pueden ver su empresa"
  ON empresas FOR SELECT
  USING (id = get_empresa_id());

CREATE POLICY "Usuarios autenticados pueden crear una empresa"
  ON empresas FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================
-- 8. BUSCAR EMPRESA POR CÓDIGO DE INVITACIÓN (para "unirme")
--
-- Un usuario recién registrado todavía no pertenece a ninguna
-- empresa, así que la política de SELECT de arriba no le deja ver
-- NINGUNA fila de "empresas" — ni siquiera la que quiere unirse.
--
-- Esta función SÍ es SECURITY DEFINER (a diferencia de la vista
-- v_trabajadores_resumen que eliminamos), pero de forma segura:
-- solo hace un match exacto contra un código de alta entropía
-- (equivalente a una contraseña) y devuelve UNICAMENTE el id de la
-- empresa, nunca la lista completa ni otros campos. No sirve para
-- "explorar" empresas, solo para canjear un código que ya conoces.
-- ============================================
CREATE OR REPLACE FUNCTION buscar_empresa_por_codigo(codigo TEXT)
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT id FROM empresas WHERE codigo_invitacion = codigo;
$$;

-- ============================================
-- 9. CREAR EMPRESA (para "crear empresa nueva" en el registro)
--
-- Mismo problema de huevo-y-gallina que el de "unirme": justo
-- después de crear la empresa, Postgres necesita devolver la fila
-- (RETURNING) para que la app conozca su id y código, pero en ese
-- momento el usuario todavía no está vinculado a ninguna empresa
-- (eso se hace después, al insertar su fila en "usuarios") — así
-- que la política de SELECT de "empresas" bloquearía esa devolución
-- y Postgres reporta todo el INSERT como violación de RLS.
--
-- La función resuelve esto igual que buscar_empresa_por_codigo:
-- SECURITY DEFINER, pero acotada a una sola operación (crear una
-- empresa con el nombre dado) sin exponer ni depender de datos de
-- otras empresas.
-- ============================================
CREATE OR REPLACE FUNCTION crear_empresa(nombre_empresa TEXT)
RETURNS empresas
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  nueva empresas;
BEGIN
  INSERT INTO empresas (nombre) VALUES (nombre_empresa) RETURNING * INTO nueva;
  RETURN nueva;
END;
$$;
