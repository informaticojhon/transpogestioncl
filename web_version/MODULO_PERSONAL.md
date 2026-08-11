# Módulo de Gestión de Personal

Este módulo permite administrar el personal de tu empresa de transporte.

## Características

### 👥 Gestión de Trabajadores
- Registro completo: RUT, nombre, apellido, cargo, fecha de ingreso
- Información de contacto: teléfono, email
- Salario base
- Estado activo/inactivo
- Búsqueda y filtrado

### 📅 Control de Turnos
- Registro de turnos trabajados
- Tipos de turno: Normal, Extra, Nocturno
- Horas trabajadas por turno
- Historial completo de turnos
- Observaciones opcionales

### 💰 Gestión de Remuneraciones
- Registro de pagos
- Periodos: Semanal, Quincenal, Mensual
- Concepto del pago
- Historial completo de pagos
- Total pagado por trabajador

### 📊 Estadísticas
- Total de turnos trabajados
- Total de horas acumuladas
- Promedio de horas por turno
- Total pagado
- Días trabajados desde ingreso

## Instalación

### 1. Ejecutar el Script SQL

Ve a tu dashboard de Supabase:
1. Abre https://app.supabase.com
2. Selecciona tu proyecto
3. Ve a **SQL Editor** en el menú lateral
4. Haz clic en **New query**
5. Copia y pega el contenido completo del archivo `SETUP_PERSONAL.sql`
6. Haz clic en **Run** o presiona Ctrl+Enter

Esto creará:
- Tabla `trabajadores`: Información de empleados
- Tabla `turnos`: Registro de turnos trabajados
- Tabla `remuneraciones`: Historial de pagos
- Políticas RLS automáticas (solo ve tus propios datos)
- Índices para mejor rendimiento
- Vista `v_trabajadores_resumen` con estadísticas

### 2. Verificar la Instalación

En el SQL Editor, ejecuta esta consulta:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('trabajadores', 'turnos', 'remuneraciones');
```

Deberías ver las 3 tablas listadas.

### 3. Probar el Módulo

1. Ejecuta tu aplicación:
   ```powershell
   cd web_version
   flutter run -d chrome --web-port=8888
   ```

2. Inicia sesión en la aplicación

3. Abre el menú lateral y selecciona **"Gestión de Personal"**

4. Registra tu primer trabajador:
   - RUT (ej: 12345678-9)
   - Nombre y Apellido
   - Cargo (opcional)
   - Fecha de ingreso
   - Salario base

5. En el detalle del trabajador puedes:
   - Ver información completa
   - Registrar turnos trabajados
   - Registrar pagos/remuneraciones
   - Ver estadísticas acumuladas

## Uso

### Registrar un Trabajador

1. En la pantalla de Gestión de Personal, presiona **"Nuevo Trabajador"**
2. Completa el formulario:
   - **RUT*** (obligatorio)
   - **Nombre*** (obligatorio)
   - **Apellido*** (obligatorio)
   - **Cargo** (opcional): Ej: Chofer, Auxiliar, Mecánico
   - **Fecha de Ingreso*** (obligatorio)
   - **Teléfono** (opcional)
   - **Email** (opcional)
   - **Salario Base*** (obligatorio)
   - **Estado**: Activo/Inactivo
3. Presiona **"Registrar"**

### Registrar un Turno

1. Entra al detalle del trabajador
2. Ve a la pestaña **"Turnos"**
3. Presiona **"Registrar Turno"**
4. Completa:
   - **Fecha**: Día del turno
   - **Horas trabajadas**: Número de horas (por defecto 8)
   - **Tipo de turno**: Normal / Extra / Nocturno
5. Presiona **"Guardar"**

### Registrar una Remuneración

1. Entra al detalle del trabajador
2. Ve a la pestaña **"Pagos"**
3. Presiona **"Registrar Pago"**
4. Completa:
   - **Fecha de pago**: Cuándo se realizó el pago
   - **Monto**: Cantidad en pesos chilenos
   - **Periodo**: Semanal / Quincenal / Mensual
   - **Concepto** (opcional): Descripción del pago
5. Presiona **"Guardar"**

## Búsqueda y Filtros

En la pantalla principal de Gestión de Personal:
- **Búsqueda**: Busca por nombre, RUT o cargo
- **Filtro activos**: Muestra solo trabajadores activos u todos
- **Ordenamiento**: Alfabético por nombre

## Acciones Disponibles

Desde el menú de cada trabajador (⋮):
- **Ver detalle**: Información completa + historial
- **Editar**: Modificar datos del trabajador
- **Dar de baja / Reactivar**: Cambiar estado
- **Eliminar**: Borrar permanentemente

## Seguridad

✅ Todas las tablas tienen Row Level Security (RLS) activado
✅ Solo puedes ver/editar tus propios trabajadores
✅ Cada trabajador está asociado a tu user_id de Supabase
✅ No es posible ver datos de otros usuarios

## Estructura de Base de Datos

### Tabla: trabajadores
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | int | ID único autogenerado |
| user_id | uuid | ID del usuario propietario |
| rut | text | RUT del trabajador |
| nombre | text | Nombre |
| apellido | text | Apellido |
| cargo | text | Cargo (opcional) |
| fecha_ingreso | date | Fecha de inicio |
| telefono | text | Teléfono (opcional) |
| email | text | Email (opcional) |
| salario_base | int | Salario en CLP |
| activo | bool | Estado activo/inactivo |
| created_at | timestamp | Fecha de creación |
| updated_at | timestamp | Última modificación |

### Tabla: turnos
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | int | ID único autogenerado |
| trabajador_id | int | Referencia al trabajador |
| user_id | uuid | ID del usuario propietario |
| fecha | date | Fecha del turno |
| horas_trabajadas | decimal | Horas trabajadas |
| tipo_turno | text | normal/extra/nocturno |
| observaciones | text | Notas (opcional) |
| created_at | timestamp | Fecha de registro |

### Tabla: remuneraciones
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | int | ID único autogenerado |
| trabajador_id | int | Referencia al trabajador |
| user_id | uuid | ID del usuario propietario |
| fecha_pago | date | Fecha del pago |
| monto | int | Monto en CLP |
| periodo | text | semanal/quincenal/mensual |
| concepto | text | Descripción (opcional) |
| created_at | timestamp | Fecha de registro |

## Solución de Problemas

### "No hay trabajadores registrados"
- Verifica que ejecutaste el script SQL en Supabase
- Asegúrate de estar autenticado en la app
- Revisa la consola del navegador (F12) para ver errores

### Error al guardar trabajador
- Verifica que el RUT está en formato correcto
- Asegúrate de completar todos los campos obligatorios (*)
- Revisa que la fecha de ingreso no sea futura

### No aparecen las tablas en Supabase
- Verifica que ejecutaste el script completo sin errores
- Revisa la pestaña de errores en SQL Editor
- Asegúrate de tener permisos de administrador en el proyecto

## Próximas Mejoras

Posibles funcionalidades a futuro:
- Exportar nómina a PDF/Excel
- Gráficos de asistencia
- Alertas de cumpleaños
- Control de vacaciones
- Cálculo automático de liquidaciones
- Generación de contratos

## Soporte

Si encuentras algún problema:
1. Revisa la consola del navegador (F12)
2. Verifica que las tablas existen en Supabase
3. Confirma que tienes conexión a internet
4. Revisa que tu sesión no haya expirado

---

**Creado para TranspoGestionCL**  
Gestión integral de personal para empresas de transporte
