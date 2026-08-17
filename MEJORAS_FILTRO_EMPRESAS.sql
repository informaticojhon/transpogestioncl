-- ============================================
-- MEJORA: lista de empresas cliente para el filtro de Historial
-- Ejecutar en Supabase SQL Editor
-- ============================================
CREATE OR REPLACE FUNCTION empresas_clientes_unicas()
RETURNS TABLE(empresa TEXT)
LANGUAGE sql
STABLE
AS $$
  SELECT DISTINCT s.empresa
  FROM servicios s
  WHERE s.empresa_id = get_empresa_id()
    AND s.empresa IS NOT NULL
    AND s.empresa <> ''
  ORDER BY s.empresa;
$$;
