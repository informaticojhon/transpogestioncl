# 🌐 TranspoGestión CL - Versión Web

Versión web de la aplicación de gestión de transporte. Esta es una versión **completamente independiente** optimizada para navegadores web.

## ✨ Características Web

- ✅ **100% Compatible con navegadores** - Chrome, Firefox, Safari, Edge
- ☁️ **Solo Supabase** - Sin SQLite, todo en la nube
- 📊 **Mismas funcionalidades** - Registro, reportes, historial
- 🎨 **Modo claro/oscuro** - Persistente en localStorage
- 📱 **Responsive** - Se adapta a diferentes tamaños de pantalla

---

## 🚀 Inicio Rápido

### 1. Instalar dependencias
```bash
cd web_version
flutter pub get
```

### 2. Ejecutar en modo desarrollo
```bash
flutter run -d chrome
```

### 3. Compilar para producción
```bash
flutter build web --release
```

Los archivos compilados estarán en `build/web/`

---

## 🌍 Deployment

### Opción 1: Servidor estático local
```bash
cd build/web
python -m http.server 8000
# Abrir http://localhost:8000
```

### Opción 2: Firebase Hosting
```bash
firebase init hosting
firebase deploy
```

### Opción 3: Netlify
- Arrastra la carpeta `build/web/` a netlify.com/drop

### Opción 4: Vercel
```bash
vercel build/web
```

---

## 📁 Diferencias con la versión móvil

| Característica | Móvil | Web |
|---------------|-------|-----|
| Base de datos local | ✅ SQLite | ❌ No compatible |
| Almacenamiento | ✅ Supabase + SQLite | ✅ Solo Supabase |
| PDF | ✅ Descarga | ✅ Descarga |
| Compartir | ✅ Share nativo | ⚠️ Descarga manual |
| Offline | ⚠️ Limitado | ❌ Requiere conexión |

---

## 🔧 Configuración de Supabase

El proyecto usa la misma configuración de Supabase que la versión móvil:
- Archivo: `lib/config/supabase_config.dart`
- Requiere autenticación para todas las operaciones
- Tablas: `usuarios`, `servicios`

---

## 🐛 Solución de Problemas

### Error de CORS
Si ves errores de CORS, agrega tu dominio en la configuración de Supabase:
1. Dashboard de Supabase
2. Authentication → URL Configuration
3. Agregar tu URL en "Site URL"

### No carga en navegador
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Build falla
Verifica que tengas Flutter web habilitado:
```bash
flutter config --enable-web
flutter devices  # Debe mostrar Chrome
```

---

## 📝 Notas

- **Proyecto independiente**: Esta versión web NO comparte código con la versión móvil
- **Mantención**: Los cambios deben hacerse por separado en cada versión
- **Producción**: Asegúrate de configurar las variables de entorno de Supabase correctamente

---

## 🔗 Enlaces Útiles

- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [Supabase Flutter Docs](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- [Deploy Flutter Web](https://docs.flutter.dev/deployment/web)
