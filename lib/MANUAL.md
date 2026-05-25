# Manual rápido — Panel de Administración Kiogloss (Flutter)

## 1. Objetivo

Aplicación móvil desarrollada en **Flutter** para **Kiogloss Beauty Products**.  
Cubre cinco funcionalidades principales:

1. **Login** con validación de credenciales, roles y efectos visuales.
2. **Panel de administración** con acceso controlado por roles (RBAC).
3. **Gestión de empleados** (activar / desactivar perfiles).
4. **Generación y descarga** de informes en PDF.
5. **Carga de archivos PDF** con validación de integridad SHA-256.
6. **Registro de auditoría** persistente de todas las acciones.

---

## 2. Credenciales de acceso (demo)

| Usuario      | Contraseña     | Rol        | Pestañas disponibles                         |
|--------------|----------------|------------|----------------------------------------------|
| `admin`      | `kiogloss2026` | Admin      | Inicio · Usuarios · Informes · Cargar · Auditoría |
| `vendedor`   | `ventas2026`   | Vendedor   | Inicio · Informes · Cargar                   |
| `supervisor` | `super2026`    | Supervisora| Inicio · Usuarios                            |

> Cualquier otra combinación muestra un mensaje de error y registra el intento fallido en auditoría.

---

## 3. Estructura del proyecto

```
kiogloss_admin/
├── pubspec.yaml                   # Dependencias (incluye crypto ^3.0.3)
└── lib/
    ├── main.dart                  # Punto de entrada — tema claro Material 3 morado
    ├── login_page.dart            # Pantalla de login multi-usuario con RBAC
    ├── admin_console.dart         # Consola con pestañas filtradas por rol
    ├── pdf_service.dart           # Generación y apertura de PDFs
    ├── audit_log_service.dart     # Log de auditoría persistente (SharedPreferences)
    └── models.dart                # Modelos AppUser y AuditLogEntry
```

---

## 4. Cómo ejecutar

1. Verificar Flutter instalado: `flutter doctor`
2. Instalar dependencias: `flutter pub get`
3. Ejecutar: `flutter run`

---

## 5. Funcionalidades principales

### 5.1 Pantalla de login
- Gradiente violeta muy claro (paleta Kiogloss).
- Tarjeta blanca con borde morado — estilo elegante.
- Animaciones fade + slide al abrir.
- Autenticación contra mapa de credenciales por rol.
- Mensaje de error via *snackbar* rojo ante credenciales incorrectas.

### 5.2 RBAC — Control de acceso por rol

Al iniciar sesión, el sistema determina el rol del usuario y muestra **solo** las pestañas que le corresponden:

```
Admin      → todas las pestañas (5)
Vendedor   → Inicio, Informes, Cargar
Supervisora→ Inicio, Usuarios
```

El rol se muestra como un badge morado en la barra superior.

### 5.3 Gestión de empleados (pestaña Usuarios)
- Lista con avatar, correo y rol.
- Interruptor para activar/desactivar. Cada cambio se registra en auditoría.

### 5.4 Informes PDF (pestaña Informes)
- **Informe de Empleados**: tabla con nombre, correo, rol y estado.
- **Informe Resumido**: KPIs numéricos del sistema.
- Ambos con encabezado y pie de página de Kiogloss en morado.
- El diálogo del sistema permite imprimir, compartir o guardar.

### 5.5 Carga de PDFs con SHA-256 (pestaña Cargar)

Al cargar un archivo PDF, el sistema:
1. Calcula el hash **SHA-256** de los bytes del archivo.
2. Muestra los primeros 16 caracteres del hash en la tarjeta (con tooltip completo).
3. Registra el hash completo en el log de auditoría.

Esto garantiza la **integridad** del archivo: si el PDF es alterado, su hash cambia.

```
Ejemplo de hash:
SHA-256: a3f2c8b91d4e7f6a…  ← primeros 16 chars + "…"
```

### 5.6 Registro de auditoría (pestaña Auditoría)
- Guarda hasta 1 000 eventos en `SharedPreferences`.
- Ordena por fecha descendente (más recientes primero).
- Filtros: Todas · Logins · Fallidos · Usuarios · Informes · Cargas · Eliminaciones.
- Cada entrada muestra acción, actor, hora y detalles expandibles.

---

## 6. Demostración (5–10 min)

| Paso | Acción | Qué se muestra |
|------|--------|----------------|
| 1 | Login con credenciales **incorrectas** | Error en snackbar + evento en auditoría |
| 2 | Login como `vendedor` | Solo 3 pestañas visibles (RBAC) |
| 3 | Login como `admin` | Las 5 pestañas disponibles |
| 4 | Activar/desactivar un empleado | Cambio inmediato en KPIs |
| 5 | Generar informe PDF | Encabezado Kiogloss morado |
| 6 | Cargar un PDF | Hash SHA-256 visible en la tarjeta |
| 7 | Ver pestaña Auditoría | Historial completo con filtros |
| 8 | Cerrar sesión | Vuelve al login con animación |

---

## 7. Conceptos demostrados

| Concepto | Implementación |
|---|---|
| Autenticación | Login multi-usuario con validación de credenciales |
| RBAC | Pestañas dinámicas según rol del usuario |
| Integridad de archivos | Hash SHA-256 calculado al momento de la carga |
| Auditoría | Log persistente de todas las acciones del sistema |
| Generación de informes | PDFs descargables con `pdf` + `printing` |
