-- ============================================
-- FIX: control de roles admin/empleado + validaciones básicas
-- Ejecutar en Supabase SQL Editor
--
-- Hallazgo de la auditoría de seguridad (2026-08-11): las políticas
-- RLS de trabajadores/turnos/remuneraciones/materiales/movimientos
-- solo verificaban "¿eres de esta empresa?", nunca "¿eres admin?".
-- Cualquier empleado autenticado podía leer sueldos de sus
-- compañeros y editar/borrar trabajadores o materiales de toda la
-- empresa llamando directo a la API de Supabase, sin pasar por la
-- app. Este script restringe esas 5 tablas a solo administradores
-- (servicios se mantiene compartido entre todo el equipo, que es
-- el uso normal esperado).
-- ============================================

-- ============================================
-- 1. FUNCIÓN AUXILIAR: rol del usuario actual
-- Mismo patrón que get_empresa_id(): SECURITY DEFINER porque
-- consulta "usuarios" desde dentro de políticas de "usuarios"
-- mismas (evita la recursión infinita ya explicada ahí), pero solo
-- devuelve un dato del propio auth.uid(), nunca de otro usuario.
-- ============================================
CREATE OR REPLACE FUNCTION get_rol()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT rol FROM usuarios WHERE id = auth.uid();
$$;

-- ============================================
-- 2. TRABAJADORES: solo admin
-- ============================================
DROP POLICY IF EXISTS "Empresa puede ver sus trabajadores" ON trabajadores;
DROP POLICY IF EXISTS "Empresa puede crear trabajadores" ON trabajadores;
DROP POLICY IF EXISTS "Empresa puede actualizar trabajadores" ON trabajadores;
DROP POLICY IF EXISTS "Empresa puede eliminar trabajadores" ON trabajadores;

CREATE POLICY "Solo admin ve trabajadores"
  ON trabajadores FOR SELECT USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin crea trabajadores"
  ON trabajadores FOR INSERT WITH CHECK (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin actualiza trabajadores"
  ON trabajadores FOR UPDATE USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin elimina trabajadores"
  ON trabajadores FOR DELETE USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');

-- ============================================
-- 3. TURNOS: solo admin
-- ============================================
DROP POLICY IF EXISTS "Empresa puede ver sus turnos" ON turnos;
DROP POLICY IF EXISTS "Empresa puede crear turnos" ON turnos;
DROP POLICY IF EXISTS "Empresa puede actualizar turnos" ON turnos;
DROP POLICY IF EXISTS "Empresa puede eliminar turnos" ON turnos;

CREATE POLICY "Solo admin ve turnos"
  ON turnos FOR SELECT USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin crea turnos"
  ON turnos FOR INSERT WITH CHECK (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin actualiza turnos"
  ON turnos FOR UPDATE USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin elimina turnos"
  ON turnos FOR DELETE USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');

-- ============================================
-- 4. REMUNERACIONES: solo admin (la más sensible: sueldos)
-- ============================================
DROP POLICY IF EXISTS "Empresa puede ver sus remuneraciones" ON remuneraciones;
DROP POLICY IF EXISTS "Empresa puede crear remuneraciones" ON remuneraciones;
DROP POLICY IF EXISTS "Empresa puede actualizar remuneraciones" ON remuneraciones;
DROP POLICY IF EXISTS "Empresa puede eliminar remuneraciones" ON remuneraciones;

CREATE POLICY "Solo admin ve remuneraciones"
  ON remuneraciones FOR SELECT USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin crea remuneraciones"
  ON remuneraciones FOR INSERT WITH CHECK (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin actualiza remuneraciones"
  ON remuneraciones FOR UPDATE USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin elimina remuneraciones"
  ON remuneraciones FOR DELETE USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');

-- ============================================
-- 5. MATERIALES: solo admin
-- ============================================
DROP POLICY IF EXISTS "Empresa puede ver sus materiales" ON materiales;
DROP POLICY IF EXISTS "Empresa puede crear materiales" ON materiales;
DROP POLICY IF EXISTS "Empresa puede actualizar materiales" ON materiales;
DROP POLICY IF EXISTS "Empresa puede eliminar materiales" ON materiales;

CREATE POLICY "Solo admin ve materiales"
  ON materiales FOR SELECT USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin crea materiales"
  ON materiales FOR INSERT WITH CHECK (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin actualiza materiales"
  ON materiales FOR UPDATE USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin elimina materiales"
  ON materiales FOR DELETE USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');

-- ============================================
-- 6. MOVIMIENTOS_MATERIAL: solo admin
-- ============================================
DROP POLICY IF EXISTS "Empresa puede ver sus movimientos" ON movimientos_material;
DROP POLICY IF EXISTS "Empresa puede crear movimientos" ON movimientos_material;
DROP POLICY IF EXISTS "Empresa puede actualizar movimientos" ON movimientos_material;
DROP POLICY IF EXISTS "Empresa puede eliminar movimientos" ON movimientos_material;

CREATE POLICY "Solo admin ve movimientos"
  ON movimientos_material FOR SELECT USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin crea movimientos"
  ON movimientos_material FOR INSERT WITH CHECK (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin actualiza movimientos"
  ON movimientos_material FOR UPDATE USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');
CREATE POLICY "Solo admin elimina movimientos"
  ON movimientos_material FOR DELETE USING (empresa_id = get_empresa_id() AND get_rol() = 'admin');

-- Nota: "servicios" y "usuarios" NO se tocan aquí a propósito.
-- Registrar/ver servicios es el trabajo normal de un empleado, y
-- ver la lista de compañeros (nombre/email/rol, sin datos
-- financieros) en "Gestionar mi equipo" es de bajo riesgo.

-- ============================================
-- 7. VALIDACIONES: no permitir valores negativos
-- ============================================
ALTER TABLE trabajadores ADD CONSTRAINT trabajadores_salario_base_check CHECK (salario_base >= 0);
ALTER TABLE materiales ADD CONSTRAINT materiales_stock_inicial_check CHECK (stock_inicial >= 0);
