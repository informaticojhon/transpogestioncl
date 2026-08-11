# 🚗 TranspoGestión CL

Aplicación Flutter para gestión de transporte: registro de servicios, reportes y gestión de personal (trabajadores, turnos y remuneraciones).

## ✨ Características

- 📊 **Registro de servicios** - Registra cada servicio de transporte
- 📈 **Reportes** - Genera reportes diarios y mensuales en PDF
- ☁️ **Backend en Supabase** - Autenticación y base de datos en la nube (Postgres)
- 📱 **Historial** - Consulta y busca todos tus servicios
- 👷 **Gestión de personal** - Trabajadores, turnos y remuneraciones
- 🎨 **Tema oscuro/claro** - Modo día/noche
- 📤 **Compartir reportes** - Exporta y comparte PDFs

---

## 🚀 Inicio Rápido

### 1. Instalar dependencias
```bash
cd transporte_app
flutter pub get
```

### 2. Configurar Supabase
Este proyecto usa Supabase como backend (ver `GUIA_SUPABASE.md` para crear el proyecto y las tablas). Las credenciales del proyecto viven en `lib/config/supabase_config.dart`.

### 3. Ejecutar aplicación
```bash
flutter run
```

---

## 📱 Pantallas Disponibles

- **Welcome Screen** - Pantalla de bienvenida
- **Login/Register** - Autenticación de usuarios (Supabase Auth)
- **Home** - Pantalla principal con acceso rápido y menú lateral
- **Registro de Servicio** - Captura datos del servicio
- **Reporte Diario** - Genera PDF del día
- **Reporte Mensual** - Genera PDF del mes
- **Historial** - Lista y busca todos los servicios
- **Gestión de Personal** - Lista de trabajadores, detalle (turnos/remuneraciones) y formulario de alta/edición

---

## 🛠️ Tecnologías Utilizadas

- **Flutter** - Framework multiplataforma
- **Supabase** - Autenticación y base de datos (Postgres) en la nube
- **PDF / Printing** - Generación y exportación de reportes
- **Shared Preferences** - Preferencia de tema (claro/oscuro)

---

## 📁 Estructura del Proyecto

```
transporte_app/
├── lib/
│   ├── config/
│   │   └── supabase_config.dart   # URL y anon key de Supabase
│   ├── models/                    # Modelos de datos
│   │   ├── servicio.dart
│   │   ├── trabajador.dart
│   │   ├── turno.dart
│   │   └── remuneracion.dart
│   ├── repositories/               # Acceso a datos (Supabase)
│   │   ├── supabase_repository.dart    # Auth + servicios
│   │   ├── auth_repository.dart        # Fachada de autenticación
│   │   ├── servicios_repository.dart   # Fachada de servicios
│   │   └── personal_repository.dart    # Trabajadores, turnos, remuneraciones
│   ├── screens/                    # Pantallas
│   │   ├── welcome_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   ├── registro_servicio_screen.dart
│   │   ├── reporte_diario_screen.dart
│   │   ├── reporte_mensual_screen.dart
│   │   ├── historial_screen.dart
│   │   ├── trabajadores_list_screen.dart
│   │   ├── trabajador_detalle_screen.dart
│   │   └── trabajador_form_screen.dart
│   ├── services/
│   │   └── api_service.dart        # Excepciones (ApiException, TokenExpiredException)
│   ├── utils/                      # Utilidades
│   │   ├── app_theme.dart
│   │   ├── currency_formatter.dart
│   │   └── validators.dart
│   └── main.dart                   # Punto de entrada
├── android/                       # Configuración Android
├── ios/                           # Configuración iOS
├── web/                           # Configuración Flutter Web
├── web_version/                   # Proyecto Flutter separado (versión web independiente)
└── assets/                        # Recursos (imágenes, íconos)
```

> Nota: no existe base de datos local ni backend propio — toda la persistencia (usuarios, servicios, trabajadores, turnos, remuneraciones) vive en Supabase.

---

## 🐛 Solución de Problemas

### La app no compila
```bash
flutter clean
flutter pub get
flutter run
```

### Error en dependencias
```bash
flutter pub upgrade
```

### No carga datos / error de autenticación
- Verifica que `lib/config/supabase_config.dart` tenga la URL y anon key correctas
- Revisa en el dashboard de Supabase que las tablas y políticas RLS descritas en `GUIA_SUPABASE.md` existan

---

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.

---

**¡Listo para empezar!** 🚀

Ejecuta `flutter run` y comienza a gestionar tus servicios de transporte.
