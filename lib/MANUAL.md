# Manual rápido — Consola de Administración FET (Flutter)

## 1. Objetivo

Aplicación móvil desarrollada en **Flutter** que demuestra, en un contexto académico de la Especialización en Ciberseguridad, cuatro funcionalidades clave:

1. **Login** con validación de credenciales y efectos visuales.
2. **Consola de administración** con gestión de usuarios.
3. **Generación y descarga** de informes en PDF.
4. **Carga (upload)** de archivos PDF dentro de la aplicación.

---

## 2. Credenciales de acceso (demo)

| Campo       | Valor              |
|-------------|--------------------|
| Usuario     | `michaelhmontilla` |
| Contraseña  | `2026`             |

> Cualquier otra combinación muestra un mensaje de error.

---

## 3. Estructura del proyecto

```
fet_admin_console/
├── pubspec.yaml              # Dependencias del proyecto
└── lib/
    ├── main.dart             # Punto de entrada y tema oscuro Material 3
    ├── login_page.dart       # Pantalla de login con animaciones
    ├── admin_console.dart    # Consola con 4 pestañas
    ├── pdf_service.dart      # Generación y apertura de PDFs
    └── models.dart           # Modelo de datos AppUser
```

---

## 4. Cómo ejecutar

1. Tener Flutter instalado: <https://docs.flutter.dev/get-started/install>
2. Verificar instalación: `flutter doctor`
3. Crear el proyecto base (una sola vez):
   ```bash
   flutter create fet_admin_console
   ```
4. Reemplazar el contenido de `pubspec.yaml` y la carpeta `lib/` con los archivos suministrados.
5. Instalar dependencias:
   ```bash
   flutter pub get
   ```
6. Ejecutar en emulador o dispositivo:
   ```bash
   flutter run
   ```

---

## 5. Componentes principales

### 5.1 Pantalla de login (`login_page.dart`)
- Fondo con **degradado** azul oscuro/púrpura (estilo ciberseguridad).
- Tarjeta con efecto **glassmorphism** (semitransparente con borde sutil).
- Animaciones de entrada **fade + slide** al abrir la pantalla.
- Validación de campos vacíos y de credenciales.
- Botón con **indicador de carga** mientras valida.
- Mensaje de error tipo *snackbar* si las credenciales son incorrectas.
- Botón para **mostrar/ocultar** la contraseña.

### 5.2 Consola de administración (`admin_console.dart`)
Cuatro pestañas accesibles desde la barra inferior:

| Pestaña    | Función                                                          |
|------------|------------------------------------------------------------------|
| Inicio     | Tarjetas de KPIs (usuarios totales, activos, inactivos, PDFs)    |
| Usuarios   | Lista de perfiles con interruptor para activar/desactivar        |
| Informes   | Dos PDFs descargables: *Listado de usuarios* y *Resumen*         |
| Cargar     | Selector de archivos PDF y lista de los ya cargados              |

### 5.3 Servicio de PDFs (`pdf_service.dart`)
- Usa el paquete `pdf` para construir el documento (encabezado, tabla, KPIs).
- Usa `printing` para mostrar el diálogo de **imprimir / compartir / guardar**.
- Usa `path_provider` y `file_picker` para gestionar archivos locales.

---

## 6. Demostración en clase (5–10 min)

| Paso | Acción                                                                | Qué se muestra                          |
|------|-----------------------------------------------------------------------|-----------------------------------------|
| 1    | Probar credenciales **incorrectas**                                   | Validación + mensaje de error           |
| 2    | Ingresar las credenciales **correctas**                               | Animación de transición a la consola    |
| 3    | Recorrer las **tarjetas de KPIs** del panel de inicio                 | Indicadores en tiempo real              |
| 4    | Activar/desactivar un usuario en **Usuarios**                         | Cambio inmediato en KPIs y avatar       |
| 5    | Generar un **informe PDF** desde la pestaña Informes                  | Descarga / vista previa del PDF         |
| 6    | **Cargar un PDF** desde el dispositivo                                | El archivo aparece listado              |
| 7    | Abrir un PDF cargado                                                  | Visor del sistema                       |
| 8    | Cerrar sesión con el ícono superior derecho                           | Vuelve al login con animación           |

---

## 7. Conceptos pedagógicos asociados

- **Autenticación básica** → analogía con la función *Identify* del NIST CSF 2.0.
- **Gestión de identidades y accesos (IAM)** → activar/desactivar perfiles.
- **Evidencias y auditoría** → generación de informes en PDF.
- **Validación de entrada** → control del tipo de archivo cargado (.pdf).

---

## 8. Mejoras propuestas como ejercicio para los estudiantes

1. Conectar a un *backend* real (Firebase, REST API).
2. Cifrar las credenciales (hash + salt con `bcrypt` o similar).
3. Implementar **roles diferenciados (RBAC)**.
4. Registrar un **log de auditoría** de cada acción.
5. Añadir **autenticación de doble factor (2FA)**.
6. Validar la **integridad** del PDF cargado (hash SHA-256).
