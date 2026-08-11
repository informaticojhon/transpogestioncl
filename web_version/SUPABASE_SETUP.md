# ⚙️ Configuración de Supabase para Web

## 🚨 ERROR: XMLHttpRequest / CORS

Si ves este error al intentar hacer login:
```
AuthRetryableFetchException(message: XMLHttpRequest error., statusCode: null)
```

Es porque **Supabase no tiene autorizado tu dominio local**.

---

## ✅ Solución: Configurar URLs en Supabase

### Paso 1: Ir al Dashboard

Ve a: [https://supabase.com/dashboard/project/rslnalvuzizmmqdbymkq](https://supabase.com/dashboard/project/rslnalvuzizmmqdbymkq)

### Paso 2: Configurar Authentication

1. Click en **"Authentication"** (menú izquierdo)
2. Click en **"URL Configuration"**
3. Verás estos campos:

#### Site URL
Cambia de `http://localhost:3000` a:
```
http://localhost:8080
```

#### Redirect URLs
Agrega estas URLs (una por línea):
```
http://localhost:8080/**
http://127.0.0.1:8080/**
```

### Paso 3: Guardar

- Click en **"Save"**
- Espera 5-10 segundos

### Paso 4: Reiniciar la app

En la terminal donde está corriendo Flutter:
1. Presiona `r` (hot reload) o `R` (hot restart)
2. O cierra y ejecuta de nuevo: `flutter run -d chrome`

---

## 🌐 Para Producción

Cuando despliegues a un hosting (Netlify, Vercel, etc.), debes:

1. Obtener tu URL de producción (ej: `https://tu-app.netlify.app`)
2. Ir a Supabase → Authentication → URL Configuration
3. Cambiar **Site URL** a tu URL de producción
4. Agregar en **Redirect URLs**:
   ```
   https://tu-app.netlify.app/**
   ```

---

## 📝 URLs Permitidas (Referencia)

Para desarrollo local:
- `http://localhost:8080`
- `http://localhost:8080/**`
- `http://127.0.0.1:8080/**`

Para producción (ejemplo):
- `https://tu-app.netlify.app`
- `https://tu-app.netlify.app/**`

---

## 🔍 Verificar Configuración

Después de configurar, verifica en:
- Dashboard → Settings → API
- Deberías ver tu URL en la lista de dominios permitidos

---

## ❓ Otros Errores Comunes

### "Invalid login credentials"
- Usuario/contraseña incorrectos
- Verifica que el usuario existe en Supabase

### "Email not confirmed"
- En desarrollo, desactiva confirmación de email:
  - Authentication → Providers → Email → Disable email confirmations

### "User already registered"
- El email ya existe
- Usa otro email o haz login

---

## 💡 Tip

Para ver logs de Supabase en tiempo real:
1. Abre DevTools en Chrome (F12)
2. Ve a la pestaña "Console"
3. Verás logs de Supabase auth
