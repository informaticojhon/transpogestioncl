-- ============================================
-- SCRIPT SQL PARA GESTIÓN DE MATERIALES
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- Tabla: materiales
CREATE TABLE IF NOT EXISTS materiales (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre VARCHAR(150) NOT NULL,
  categoria VARCHAR(100),
  unidad_medida VARCHAR(20) NOT NULL DEFAULT 'unidad',
  stock_inicial INTEGER NOT NULL DEFAULT 0,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla: movimientos_material
CREATE TABLE IF NOT EXISTS movimientos_material (
  id BIGSERIAL PRIMARY KEY,
  material_id BIGINT NOT NULL REFERENCES materiales(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('entrada', 'salida')),
  cantidad INTEGER NOT NULL CHECK (cantidad > 0),
  observaciones TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_materiales_user_id ON materiales(user_id);
CREATE INDEX IF NOT EXISTS idx_materiales_activo ON materiales(activo);
CREATE INDEX IF NOT EXISTS idx_movimientos_material_material_id ON movimientos_material(material_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_material_fecha ON movimientos_material(fecha);

-- Row Level Security
ALTER TABLE materiales ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimientos_material ENABLE ROW LEVEL SECURITY;

-- Políticas: materiales (SELECT, INSERT, UPDATE, DELETE)
CREATE POLICY "Users can view their own materiales"
  ON materiales FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own materiales"
  ON materiales FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own materiales"
  ON materiales FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own materiales"
  ON materiales FOR DELETE
  USING (auth.uid() = user_id);

-- Políticas: movimientos_material (SELECT, INSERT, UPDATE, DELETE)
CREATE POLICY "Users can view their own movimientos_material"
  ON movimientos_material FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own movimientos_material"
  ON movimientos_material FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own movimientos_material"
  ON movimientos_material FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own movimientos_material"
  ON movimientos_material FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at automáticamente
-- (reutiliza la función update_updated_at_column() creada en SETUP_PERSONAL.sql;
--  si no la has ejecutado antes, descomenta el bloque de abajo)
-- CREATE OR REPLACE FUNCTION update_updated_at_column()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     NEW.updated_at = NOW();
--     RETURN NEW;
-- END;
-- $$ language 'plpgsql';

CREATE TRIGGER update_materiales_updated_at
  BEFORE UPDATE ON materiales
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comentarios para documentación
COMMENT ON TABLE materiales IS 'Inventario general de materiales/insumos de la empresa';
COMMENT ON TABLE movimientos_material IS 'Movimientos de entrada/salida de stock por material';
COMMENT ON COLUMN materiales.stock_inicial IS 'Stock base; el stock actual se calcula como stock_inicial + entradas - salidas';
COMMENT ON COLUMN movimientos_material.tipo IS 'Tipo de movimiento: entrada (ingreso de stock) o salida (consumo de stock)';
