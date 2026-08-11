# 🚀 Inicio Rápido - TranspoGestión Web

## Ejecutar en Desarrollo

```bash
# Desde la carpeta web_version
flutter run -d chrome

# Con puerto específico
flutter run -d chrome --web-port=8080
```

## Compilar para Producción

```bash
flutter build web --release
```

Los archivos estarán en `build/web/`

## Desplegar Localmente

```bash
# Opción 1: Python
cd build/web
python -m http.server 8000

# Opción 2: Node.js
npx http-server build/web -p 8000
```

Luego abrir: http://localhost:8000

## URLs Importantes

- **Desarrollo**: http://localhost:8080 (cuando ejecutas `flutter run`)
- **Supabase Dashboard**: https://rslnalvuzizmmqdbymkq.supabase.co
- **DevTools**: Aparecen en consola cuando ejecutas la app

## Características

✅ Mismo backend que versión móvil (Supabase)
✅ Autenticación funcional
✅ Registro de servicios
✅ Reportes PDF
✅ Historial completo
✅ Modo oscuro/claro

## Notas

- Requiere conexión a internet (no hay SQLite local)
- Todas las operaciones usan Supabase
- Compatible con todos los navegadores modernos
