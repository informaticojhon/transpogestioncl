-- ============================================
-- SCRIPT SQL PARA GESTIÓN DE PERSONAL
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- Tabla: trabajadores
CREATE TABLE IF NOT EXISTS trabajadores (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rut VARCHAR(12) NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  cargo VARCHAR(100) NOT NULL,
  fecha_ingreso DATE NOT NULL,
  telefono VARCHAR(15),
  email VARCHAR(100),
  salario_base INTEGER DEFAULT 0,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, rut)
);

-- Tabla: turnos
CREATE TABLE IF NOT EXISTS turnos (
  id BIGSERIAL PRIMARY KEY,
  trabajador_id BIGINT NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  horas_trabajadas DECIMAL(4,2) DEFAULT 8.0,
  tipo_turno VARCHAR(20) DEFAULT 'normal', -- normal, extra, nocturno
  observaciones TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla: remuneraciones
CREATE TABLE IF NOT EXISTS remuneraciones (
  id BIGSERIAL PRIMARY KEY,
  trabajador_id BIGINT NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fecha_pago DATE NOT NULL,
  monto INTEGER NOT NULL,
  periodo VARCHAR(20) NOT NULL, -- semanal, quincenal, mensual
  concepto TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_trabajadores_user_id ON trabajadores(user_id);
CREATE INDEX IF NOT EXISTS idx_trabajadores_activo ON trabajadores(activo);
CREATE INDEX IF NOT EXISTS idx_turnos_trabajador_id ON turnos(trabajador_id);
CREATE INDEX IF NOT EXISTS idx_turnos_fecha ON turnos(fecha);
CREATE INDEX IF NOT EXISTS idx_remuneraciones_trabajador_id ON remuneraciones(trabajador_id);
CREATE INDEX IF NOT EXISTS idx_remuneraciones_fecha ON remuneraciones(fecha_pago);

-- Políticas de seguridad (Row Level Security)
ALTER TABLE trabajadores ENABLE ROW LEVEL SECURITY;
ALTER TABLE turnos ENABLE ROW LEVEL SECURITY;
ALTER TABLE remuneraciones ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios solo ven sus propios trabajadores
CREATE POLICY "Users can view their own trabajadores" 
  ON trabajadores FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own trabajadores" 
  ON trabajadores FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own trabajadores" 
  ON trabajadores FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own trabajadores" 
  ON trabajadores FOR DELETE 
  USING (auth.uid() = user_id);

-- Política: Los usuarios solo ven turnos de sus trabajadores
CREATE POLICY "Users can view their own turnos" 
  ON turnos FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own turnos" 
  ON turnos FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own turnos" 
  ON turnos FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own turnos" 
  ON turnos FOR DELETE 
  USING (auth.uid() = user_id);

-- Política: Los usuarios solo ven remuneraciones de sus trabajadores
CREATE POLICY "Users can view their own remuneraciones" 
  ON remuneraciones FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own remuneraciones" 
  ON remuneraciones FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own remuneraciones" 
  ON remuneraciones FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own remuneraciones" 
  ON remuneraciones FOR DELETE 
  USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_trabajadores_updated_at 
  BEFORE UPDATE ON trabajadores 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Vista: Resumen de trabajadores con estadísticas
CREATE OR REPLACE VIEW v_trabajadores_resumen AS
SELECT 
  t.id,
  t.user_id,
  t.rut,
  t.nombre,
  t.apellido,
  t.cargo,
  t.fecha_ingreso,
  t.salario_base,
  t.activo,
  COALESCE(COUNT(DISTINCT tu.id), 0) as total_turnos,
  COALESCE(SUM(tu.horas_trabajadas), 0) as total_horas,
  COALESCE(SUM(r.monto), 0) as total_remuneraciones
FROM trabajadores t
LEFT JOIN turnos tu ON t.id = tu.trabajador_id
LEFT JOIN remuneraciones r ON t.id = r.trabajador_id
GROUP BY t.id, t.user_id, t.rut, t.nombre, t.apellido, t.cargo, 
         t.fecha_ingreso, t.salario_base, t.activo;

-- Comentarios para documentación
COMMENT ON TABLE trabajadores IS 'Registro de trabajadores de la empresa';
COMMENT ON TABLE turnos IS 'Registro de turnos trabajados por cada empleado';
COMMENT ON TABLE remuneraciones IS 'Historial de pagos a trabajadores';
COMMENT ON COLUMN trabajadores.rut IS 'RUT del trabajador (formato: 12345678-9)';
COMMENT ON COLUMN turnos.tipo_turno IS 'Tipo de turno: normal, extra, nocturno';
COMMENT ON COLUMN remuneraciones.periodo IS 'Periodo de pago: semanal, quincenal, mensual';
