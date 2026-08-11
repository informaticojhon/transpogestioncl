# 🔥 Guía Completa: Configurar Supabase para TranspoGestión CL

> ⚠️ **Actualizado 2026-08-11:** esta guía se escribió antes de agregar
> multi-empresa, gestión de personal/materiales y varias correcciones
> de seguridad. El "Paso 2" de abajo (tablas `usuarios`/`servicios`)
> sigue sirviendo como punto de partida, pero **después** de seguirlo
> hay que ejecutar, en este orden, los scripts en la raíz del proyecto:
> `SETUP_PERSONAL.sql` → `SETUP_MATERIALES.sql` → `SETUP_MULTIEMPRESA.sql`
> → `FIX_CASCADA_USUARIOS.sql` → `FIX_SEGURIDAD.sql` → `FIX_PAGINACION.sql`.
> Sin esos scripts el proyecto queda con el modelo viejo de "un usuario,
> sus propios datos" (sin empresas ni control de roles) y sin las
> validaciones agregadas después. El snippet de `register()` del Paso 7
> también quedó desactualizado — usa el código real en
> `lib/repositories/supabase_repository.dart`, no lo de acá.

## 📋 Requisitos Previos
- ✅ Cuenta de Supabase creada
- ✅ Organización: **jhonchiguaydev**

---

## Paso 1: Crear Nuevo Proyecto en Supabase

### 1.1 Acceder al Dashboard
1. Ve a: **https://app.supabase.com/**
2. Inicia sesión con tu cuenta
3. Verás tu organización **jhonchiguaydev**

### 1.2 Crear Proyecto
1. Haz clic en **"New project"**
2. Llena los campos:

**Name (Nombre del proyecto):**
```
TranspoGestionCL
```

**Database Password (Contraseña de la base de datos):**
```
Crea una contraseña segura y GUÁRDALA
Ejemplo: TranspoApp2026!Secure
```
⚠️ **IMPORTANTE:** Guarda esta contraseña, la necesitarás después

**Region (Región):**
```
South America (São Paulo) - sa-east-1
```
(Es la más cercana a Chile)

**Plan:**
```
Free (Gratis)
```

3. Haz clic en **"Create new project"**
4. Espera 1-2 minutos mientras se crea el proyecto

---

## Paso 2: Configurar Tablas en la Base de Datos

### 2.1 Ir al Editor SQL
1. En el menú lateral izquierdo, haz clic en **"SQL Editor"**
2. Haz clic en **"New query"**

### 2.2 Crear Tabla de Usuarios
Copia y pega este SQL:

```sql
-- Tabla de usuarios
-- (sin columna password: las credenciales las maneja Supabase Auth;
--  duplicarlas aquí en texto plano solo agrega riesgo sin ningún uso)
CREATE TABLE usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para búsquedas rápidas por email
CREATE INDEX idx_usuarios_email ON usuarios(email);

-- Habilitar Row Level Security (Seguridad)
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios pueden ver solo sus propios datos
CREATE POLICY "Los usuarios pueden ver sus propios datos"
  ON usuarios
  FOR SELECT
  USING (auth.uid()::text = id::text);

-- Política: Un usuario recién registrado puede crear su propia fila
-- (sin esto, el INSERT del registro falla con "row-level security policy" 42501)
CREATE POLICY "Los usuarios pueden crear su propio registro"
  ON usuarios
  FOR INSERT
  WITH CHECK (auth.uid()::text = id::text);
```

⚠️ **Importante:** si en **Authentication → Providers → Email** tienes activado **"Confirm email"**, `signUp()` no deja una sesión activa hasta confirmar el correo, y `auth.uid()` será `null` durante el INSERT de arriba (fallará igual aunque exista la política). Desactívalo para desarrollo/pruebas, o inserta la fila en `usuarios` después de que el usuario confirme su correo.

3. Haz clic en **"Run"** (▶️)
4. Deberías ver: **"Success. No rows returned"**

### 2.3 Crear Tabla de Servicios
Crea una **nueva query** y copia esto:

```sql
-- Tabla de servicios
CREATE TABLE servicios (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  valor INTEGER NOT NULL,
  quien TEXT NOT NULL,
  empresa TEXT NOT NULL,
  tipo TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para búsquedas rápidas
CREATE INDEX idx_servicios_user_id ON servicios(user_id);
CREATE INDEX idx_servicios_fecha ON servicios(fecha);

-- Habilitar Row Level Security
ALTER TABLE servicios ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios pueden ver solo sus propios servicios
CREATE POLICY "Los usuarios pueden ver sus propios servicios"
  ON servicios
  FOR SELECT
  USING (auth.uid()::text = user_id::text);

-- Política: Los usuarios pueden insertar sus propios servicios
CREATE POLICY "Los usuarios pueden insertar sus propios servicios"
  ON servicios
  FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

-- Política: Los usuarios pueden actualizar sus propios servicios
CREATE POLICY "Los usuarios pueden actualizar sus propios servicios"
  ON servicios
  FOR UPDATE
  USING (auth.uid()::text = user_id::text);

-- Política: Los usuarios pueden eliminar sus propios servicios
CREATE POLICY "Los usuarios pueden eliminar sus propios servicios"
  ON servicios
  FOR DELETE
  USING (auth.uid()::text = user_id::text);
```

4. Haz clic en **"Run"** (▶️)

### 2.4 Verificar que las Tablas se Crearon
1. En el menú lateral, haz clic en **"Table Editor"**
2. Deberías ver dos tablas:
   - ✅ `usuarios`
   - ✅ `servicios`

---

## Paso 3: Obtener Credenciales de Supabase

### 3.1 Ir a Configuración
1. En el menú lateral, haz clic en **⚙️ Project Settings**
2. Luego en **"API"**

### 3.2 Copiar Credenciales Importantes

**URL del Proyecto:**
```
Busca: "Project URL"
Ejemplo: https://abcdefghijklmnop.supabase.co
```
👉 **COPIA Y GUARDA esta URL**

**API Key (anon/public):**
```
Busca: "Project API keys" → "anon" "public"
Es una clave larga que empieza con: eyJhbG...
```
👉 **COPIA Y GUARDA esta clave**

**⚠️ IMPORTANTE:** Guarda estas dos credenciales en un lugar seguro:
- Project URL
- anon key

---

## Paso 4: Configurar Autenticación (Opcional pero Recomendado)

### 4.1 Habilitar Email Auth
1. En el menú lateral, ve a **"Authentication"**
2. Haz clic en **"Providers"**
3. Asegúrate de que **Email** esté habilitado (debería estar por defecto)

### 4.2 Configurar Email Templates (Opcional)
1. En **"Authentication"** → **"Email Templates"**
2. Aquí puedes personalizar los emails de confirmación (por ahora déjalo como está)

---

## Paso 5: Instalar Supabase en Flutter

### 5.1 Agregar Dependencias
Abre tu terminal en el proyecto y ejecuta:

```bash
cd "C:\Users\jhonc\Desktop\Mis Proyectos web\transporte_app"
flutter pub add supabase_flutter
```

### 5.2 Verificar pubspec.yaml
El archivo `pubspec.yaml` debería tener ahora:

```yaml
dependencies:
  supabase_flutter: ^2.0.0  # o la versión más reciente
```

---

## Paso 6: Configurar Supabase en la App Flutter

### 6.1 Crear Archivo de Configuración

Crea el archivo: `lib/config/supabase_config.dart`

```dart
class SupabaseConfig {
  // 👇 REEMPLAZA ESTOS VALORES CON TUS CREDENCIALES
  static const String supabaseUrl = 'TU_PROJECT_URL_AQUI';
  static const String supabaseAnonKey = 'TU_ANON_KEY_AQUI';
}
```

**Ejemplo de cómo debería verse:**
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://abcdefghijklmnop.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
```

### 6.2 Inicializar Supabase en main.dart

Modifica `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
// ... otros imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  Intl.defaultLocale = 'es_CL';
  runApp(const TransporteApp());
}

// Getter global para acceder a Supabase fácilmente
final supabase = Supabase.instance.client;
```

---

## Paso 7: Crear Repositorio de Supabase

### 7.1 Crear `lib/repositories/supabase_repository.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class SupabaseRepository {
  static final SupabaseRepository _instance = SupabaseRepository._internal();
  factory SupabaseRepository() => _instance;
  SupabaseRepository._internal();

  // ============ AUTENTICACIÓN ============
  
  Future<void> register(String nombre, String email, String password) async {
    try {
      // 1. Crear usuario en Supabase Auth
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Error al crear usuario');
      }
      
      // 2. Guardar datos adicionales en tabla usuarios
      // (NO se guarda la contraseña acá: Supabase Auth ya la maneja
      // de forma segura. Ver la nota al inicio de esta guía — el
      // registro real hoy también crea/une una empresa, revisa
      // lib/repositories/supabase_repository.dart para el flujo completo)
      await supabase.from('usuarios').insert({
        'id': response.user!.id,
        'nombre': nombre,
        'email': email,
      });
      
    } catch (e) {
      throw Exception('Error al registrar: ${e.toString()}');
    }
  }
  
  Future<void> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Credenciales inválidas');
      }
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }
  
  Future<void> logout() async {
    await supabase.auth.signOut();
  }
  
  String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }
  
  bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }

  // ============ SERVICIOS ============
  
  Future<List<Map<String, dynamic>>> getServicios() async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    final response = await supabase
        .from('servicios')
        .select()
        .eq('user_id', userId)
        .order('fecha', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<List<Map<String, dynamic>>> getServiciosPorFecha(String fecha) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    final response = await supabase
        .from('servicios')
        .select()
        .eq('user_id', userId)
        .eq('fecha', fecha)
        .order('id', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<void> crearServicio({
    required String fecha,
    required int valor,
    required String quien,
    required String empresa,
    required String tipo,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await supabase.from('servicios').insert({
      'user_id': userId,
      'fecha': fecha,
      'valor': valor,
      'quien': quien,
      'empresa': empresa,
      'tipo': tipo,
    });
  }
  
  Future<void> actualizarServicio({
    required int id,
    required String fecha,
    required int valor,
    required String quien,
    required String empresa,
    required String tipo,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await supabase
        .from('servicios')
        .update({
          'fecha': fecha,
          'valor': valor,
          'quien': quien,
          'empresa': empresa,
          'tipo': tipo,
        })
        .eq('id', id)
        .eq('user_id', userId);
  }
  
  Future<void> eliminarServicio(int id) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await supabase
        .from('servicios')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
  
  Future<void> eliminarTodosLosServicios() async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await supabase
        .from('servicios')
        .delete()
        .eq('user_id', userId);
  }
}
```

---

## Paso 8: Actualizar Repositorio de Autenticación

Modifica `lib/repositories/auth_repository.dart`:

```dart
import '../repositories/supabase_repository.dart';

class AuthRepository {
  final _supabaseRepo = SupabaseRepository();
  
  Future<void> login(String email, String password) async {
    await _supabaseRepo.login(email, password);
  }

  Future<void> register(String name, String email, String password) async {
    await _supabaseRepo.register(name, email, password);
  }

  Future<void> logout() async {
    await _supabaseRepo.logout();
  }
  
  Future<bool> isLoggedIn() async {
    return _supabaseRepo.isLoggedIn();
  }
}
```

---

## Paso 9: Actualizar Repositorio de Servicios

Modifica `lib/repositories/servicios_repository.dart`:

```dart
import '../repositories/supabase_repository.dart';

class ServiciosRepository {
  static final ServiciosRepository _instance = ServiciosRepository._internal();
  factory ServiciosRepository() => _instance;
  ServiciosRepository._internal();

  final _supabaseRepo = SupabaseRepository();

  Future<List<dynamic>> obtenerServicios({bool forceRefresh = false}) async {
    return await _supabaseRepo.getServicios();
  }

  Future<List<dynamic>> obtenerServiciosPorFecha(String fecha) async {
    return await _supabaseRepo.getServiciosPorFecha(fecha);
  }

  Future<Map<String, dynamic>> crearServicio({
    required String fecha,
    required int valor,
    required String quien,
    required String empresa,
    required String tipo,
  }) async {
    await _supabaseRepo.crearServicio(
      fecha: fecha,
      valor: valor,
      quien: quien,
      empresa: empresa,
      tipo: tipo,
    );
    return {'mensaje': 'Servicio creado exitosamente'};
  }

  Future<Map<String, dynamic>> actualizarServicio({
    required int id,
    required String fecha,
    required int valor,
    required String quien,
    required String empresa,
    required String tipo,
  }) async {
    await _supabaseRepo.actualizarServicio(
      id: id,
      fecha: fecha,
      valor: valor,
      quien: quien,
      empresa: empresa,
      tipo: tipo,
    );
    return {'mensaje': 'Servicio actualizado'};
  }

  Future<void> eliminarServicio(int id) async {
    await _supabaseRepo.eliminarServicio(id);
  }

  Future<void> eliminarTodosLosServicios() async {
    await _supabaseRepo.eliminarTodosLosServicios();
  }
}
```

---

## Paso 10: Probar la Conexión

### 10.1 Compilar la App
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 10.2 Probar Registro
1. Instala el APK en tu celular
2. Abre la app
3. **"Crear cuenta"**
4. Llena los datos
5. Si todo está bien, deberías poder registrarte

### 10.3 Verificar en Supabase
1. Ve a Supabase Dashboard
2. **"Table Editor"** → **"usuarios"**
3. Deberías ver tu usuario registrado

---

## 🎉 ¡Listo! Tu App Ahora Funciona con Supabase

### ✅ Lo que ya funciona:
- ✅ Registro de usuarios en la nube
- ✅ Login con validación online
- ✅ Servicios guardados en la nube
- ✅ Sincronización automática
- ✅ Cada usuario ve solo sus datos

### 📊 Panel de Control:
- Ver datos: **https://app.supabase.com/project/TU_PROJECT_ID**
- Editar tablas desde el navegador
- Monitorear usuarios activos
- Ver logs de errores

---

## 🐛 Problemas Comunes

### Error: "Invalid API key"
**Solución:** Verifica que copiaste correctamente el `anon key` en `supabase_config.dart`

### Error: "Row Level Security"
**Solución:** Asegúrate de haber ejecutado todas las políticas SQL del Paso 2

### Error: "Usuario no autenticado"
**Solución:** Cierra sesión y vuelve a iniciar sesión

### Error de conexión
**Solución:** Verifica que la URL de Supabase esté correcta y que tengas internet

---

## 📱 Ventajas de Usar Supabase

✅ **Gratis para siempre** (hasta 500MB DB)
✅ **Sin servidor que mantener**
✅ **Panel visual para administrar datos**
✅ **Backups automáticos**
✅ **Escalable** (cuando crezcas)
✅ **Seguro** (Row Level Security)

---

## 🚀 Próximos Pasos Opcionales

### 1. Activar Realtime (Sincronización en tiempo real)
```dart
// Escuchar cambios en servicios
supabase.from('servicios').stream(primaryKey: ['id']).listen((data) {
  print('Datos actualizados: $data');
});
```

### 2. Almacenamiento de Archivos
Puedes subir PDFs de reportes a Supabase Storage

### 3. Autenticación con Google/Facebook
Supabase soporta OAuth fácilmente

---

**¿Necesitas ayuda con algún paso específico?** 🤔
