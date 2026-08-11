-- ============================================
-- VERIFICAR CAMPO "EMPRESA" EN SERVICIOS
-- ============================================
-- Ejecuta este código en Supabase → SQL Editor

-- La tabla servicios ya debe tener el campo "empresa"
-- Este SQL solo es para verificar o agregarlo si no existe

-- 1. Verificar si la columna empresa existe en servicios
-- Si ejecutas esto y da error "column already exists", significa que ya está lista
ALTER TABLE servicios 
ADD COLUMN IF NOT EXISTS empresa TEXT;

-- 2. Los servicios reciben el campo "empresa" al momento de registrarse
-- NO se necesita modificar la tabla usuarios

-- ✅ Listo! La tabla servicios tiene el campo "empresa" y se captura al registrar cada servicio
