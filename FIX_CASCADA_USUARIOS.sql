-- ============================================
-- FIX: no borrar datos de la empresa al eliminar un usuario
-- Ejecutar en Supabase SQL Editor
--
-- Las columnas user_id de servicios/trabajadores/turnos/
-- remuneraciones/materiales/movimientos_material apuntaban a
-- auth.users(id) ON DELETE CASCADE. Eso tenía sentido cuando el
-- dato "era" del usuario, pero ahora es de la empresa (empresa_id):
-- si se elimina la cuenta de un empleado, sus registros históricos
-- NO deben desaparecer, solo perder la referencia de "quién lo creó".
-- ============================================

ALTER TABLE servicios DROP CONSTRAINT IF EXISTS servicios_user_id_fkey;
ALTER TABLE servicios ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE servicios ADD CONSTRAINT servicios_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE trabajadores DROP CONSTRAINT IF EXISTS trabajadores_user_id_fkey;
ALTER TABLE trabajadores ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE trabajadores ADD CONSTRAINT trabajadores_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE turnos DROP CONSTRAINT IF EXISTS turnos_user_id_fkey;
ALTER TABLE turnos ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE turnos ADD CONSTRAINT turnos_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE remuneraciones DROP CONSTRAINT IF EXISTS remuneraciones_user_id_fkey;
ALTER TABLE remuneraciones ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE remuneraciones ADD CONSTRAINT remuneraciones_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE materiales DROP CONSTRAINT IF EXISTS materiales_user_id_fkey;
ALTER TABLE materiales ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE materiales ADD CONSTRAINT materiales_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE movimientos_material DROP CONSTRAINT IF EXISTS movimientos_material_user_id_fkey;
ALTER TABLE movimientos_material ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE movimientos_material ADD CONSTRAINT movimientos_material_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

-- usuarios.empresa_id sigue en CASCADE a propósito: si se borra una
-- EMPRESA completa (no un usuario individual), ahí sí tiene sentido
-- que se vayan sus miembros. No se toca esa relación.
