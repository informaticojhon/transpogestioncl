-- ============================================
-- MEJORAS: alertas de stock bajo + datos para el gráfico de ingresos
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. MATERIALES: umbral de stock mínimo (por material, opcional)
-- 0 = sin alerta configurada para ese material
-- ============================================
ALTER TABLE materiales ADD COLUMN IF NOT EXISTS stock_minimo INTEGER NOT NULL DEFAULT 0;
ALTER TABLE materiales ADD CONSTRAINT materiales_stock_minimo_check CHECK (stock_minimo >= 0);
COMMENT ON COLUMN materiales.stock_minimo IS 'Umbral bajo el cual se muestra una alerta de stock bajo; 0 desactiva la alerta';

-- ============================================
-- 2. STOCK ACTUAL DE TODOS LOS MATERIALES DE LA EMPRESA EN UNA SOLA
-- CONSULTA (evita N+1 al mostrar la lista completa con su stock)
-- ============================================
CREATE OR REPLACE FUNCTION stock_materiales_empresa()
RETURNS TABLE(material_id BIGINT, stock_actual BIGINT)
LANGUAGE sql
STABLE
AS $$
  SELECT
    m.id,
    m.stock_inicial
      + COALESCE(SUM(CASE WHEN mv.tipo = 'entrada' THEN mv.cantidad ELSE 0 END), 0)
      - COALESCE(SUM(CASE WHEN mv.tipo = 'salida' THEN mv.cantidad ELSE 0 END), 0)
  FROM materiales m
  LEFT JOIN movimientos_material mv ON mv.material_id = m.id
  WHERE m.empresa_id = get_empresa_id()
  GROUP BY m.id, m.stock_inicial;
$$;

-- ============================================
-- 3. INGRESOS POR MES (últimos N meses, incluyendo meses sin
-- servicios registrados como $0) para el gráfico del panel principal
-- ============================================
CREATE OR REPLACE FUNCTION ingresos_por_mes_empresa(meses INTEGER DEFAULT 6)
RETURNS TABLE(mes DATE, total BIGINT)
LANGUAGE sql
STABLE
AS $$
  SELECT
    serie.mes,
    COALESCE(SUM(s.valor), 0) AS total
  FROM generate_series(
         date_trunc('month', CURRENT_DATE) - ((meses - 1) || ' months')::interval,
         date_trunc('month', CURRENT_DATE),
         '1 month'::interval
       ) AS serie(mes)
  LEFT JOIN servicios s
    ON s.empresa_id = get_empresa_id()
   AND date_trunc('month', s.fecha::date) = serie.mes
  GROUP BY serie.mes
  ORDER BY serie.mes;
$$;
