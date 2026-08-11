-- ============================================
-- FIX: estadísticas livianas para el Home
-- Ejecutar en Supabase SQL Editor
--
-- Sin esto, calcular "Total acumulado" en el panel principal
-- requeriría traer TODAS las filas de servicios de la empresa
-- (incluso miles) solo para sumarlas en la app. Esta función hace
-- la suma en la base de datos y devuelve un solo número.
--
-- Es SECURITY INVOKER (el default, no se declara DEFINER): corre
-- como el usuario que llama, así que respeta el RLS normal de
-- "servicios" sin ningún truco especial — no hay riesgo de
-- recursión aquí porque no consulta "usuarios" dentro de una
-- política de "usuarios" (a diferencia de get_empresa_id()).
-- ============================================
CREATE OR REPLACE FUNCTION suma_servicios_empresa()
RETURNS BIGINT
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(SUM(valor), 0) FROM servicios WHERE empresa_id = get_empresa_id();
$$;
