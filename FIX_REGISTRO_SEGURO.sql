-- ============================================
-- FIX: el servidor decide la empresa y el rol al registrarse
-- Ejecutar en Supabase SQL Editor, en DOS partes (ver abajo)
--
-- Hallazgo (2026-11-02): al registrarse, la app insertaba ella misma
-- la fila de "usuarios" con empresa_id y rol, y la política de INSERT
-- solo verificaba que el id fuera el propio (auth.uid() = id). Quien
-- tuviera el código de invitación de una empresa podía llamar directo
-- a la API de Supabase e insertarse con rol 'admin' en esa empresa (o
-- en cualquier otra cuyo id conociera), saltándose la app. Además
-- crear_empresa y buscar_empresa_por_codigo se podían llamar sin
-- sesión (rol anon).
--
-- Con este script la app ya no inserta en "usuarios": llama a
-- registrar_usuario(), que valida el código, crea la empresa si
-- corresponde y asigna el rol en el servidor (admin solo para quien
-- crea una empresa nueva, empleado para quien se une con un código).
--
-- ORDEN:
--   PARTE 1 → ejecutar ahora (no rompe la app publicada).
--   Desplegar la app nueva (vercel --prod desde build/web).
--   PARTE 2 → ejecutar después del despliegue (cierra el hueco).
-- ============================================


-- ============================================
-- PARTE 1: función de registro
-- ============================================
CREATE OR REPLACE FUNCTION registrar_usuario(
  p_nombre TEXT,
  p_codigo_invitacion TEXT DEFAULT NULL,
  p_nombre_empresa TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_email TEXT;
  v_empresa_id UUID;
  v_rol TEXT;
  v_codigo_generado TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Debes iniciar sesión para completar el registro';
  END IF;

  IF EXISTS (SELECT 1 FROM usuarios WHERE id = v_uid) THEN
    RAISE EXCEPTION 'Este usuario ya está registrado';
  END IF;

  IF coalesce(trim(p_nombre), '') = '' THEN
    RAISE EXCEPTION 'El nombre es obligatorio';
  END IF;

  -- El correo se toma de la cuenta de Auth, no de lo que envíe la app.
  SELECT email INTO v_email FROM auth.users WHERE id = v_uid;

  IF nullif(trim(p_codigo_invitacion), '') IS NOT NULL THEN
    SELECT id INTO v_empresa_id
    FROM empresas
    WHERE codigo_invitacion = upper(trim(p_codigo_invitacion));

    IF v_empresa_id IS NULL THEN
      RAISE EXCEPTION 'El código de invitación no es válido';
    END IF;
    v_rol := 'empleado';
  ELSE
    INSERT INTO empresas (nombre)
    VALUES (coalesce(nullif(trim(p_nombre_empresa), ''), trim(p_nombre) || ' - Empresa'))
    RETURNING id, codigo_invitacion INTO v_empresa_id, v_codigo_generado;
    v_rol := 'admin';
  END IF;

  INSERT INTO usuarios (id, nombre, email, empresa_id, rol)
  VALUES (v_uid, trim(p_nombre), v_email, v_empresa_id, v_rol);

  -- Código de la empresa recién creada (para compartirlo con el
  -- equipo), o NULL si el usuario se unió a una existente.
  RETURN v_codigo_generado;
END;
$$;

REVOKE ALL ON FUNCTION registrar_usuario(TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION registrar_usuario(TEXT, TEXT, TEXT) TO authenticated;


-- ============================================
-- PARTE 2: cerrar el registro directo
-- Ejecutar SOLO después de desplegar la app nueva.
-- ============================================
DROP POLICY IF EXISTS "Los usuarios pueden crear su propio registro" ON usuarios;

-- Ya no las usa la app; se quitan los permisos en vez de borrarlas.
REVOKE ALL ON FUNCTION crear_empresa(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION buscar_empresa_por_codigo(TEXT) FROM PUBLIC, anon, authenticated;
