# Documentación de cambios — Panel de Administración Kiogloss

> **¿Para quién es este documento?**  
> Para cualquier persona que quiera entender qué se hizo en esta aplicación, cómo funciona cada parte y dónde encontrarla en el código, sin necesidad de saber programar.

---

## ¿Qué es esta aplicación?

Es una aplicación móvil creada con **Flutter** (tecnología de Google para hacer apps).  
Funciona como un **panel de control interno** para la empresa **Kiogloss Beauty Products**, donde los administradores pueden:

- Iniciar sesión con usuario y contraseña.
- Ver y gestionar el listado de empleados.
- Generar informes en PDF.
- Cargar archivos PDF al sistema.
- Ver un historial de todo lo que se hace dentro de la app.

---

## Resumen de todo lo que se hizo

Se realizaron **cuatro grandes grupos de cambios**:

| # | Qué se hizo | Por qué |
|---|---|---|
| 1 | **Rediseño de marca** | La app pasó de ser un proyecto universitario (FET) a ser la herramienta real de Kiogloss |
| 2 | **Nuevo tema visual** | Colores morados claros con fondo blanco, acorde a la identidad de Kiogloss |
| 3 | **Roles de usuario (RBAC)** | Cada empleado solo puede ver las secciones que le corresponden según su cargo |
| 4 | **Verificación SHA-256 de PDFs** | Al subir un archivo, la app genera una "huella digital" única para garantizar que el archivo no fue alterado |

---

## Cambio 1 — Rediseño de marca (Kiogloss)

### ¿Qué se hizo?
Se eliminaron todas las referencias a la institución anterior (FET / Ciberseguridad) y se reemplazaron con el nombre y contexto de **Kiogloss Beauty Products**.

### Cambios visibles para el usuario:
- El nombre de la app ahora dice **"Kiogloss - Panel de Administración"**.
- El ícono de la pantalla de login cambió a una hoja de spa (`spa_outlined`), más acorde a una empresa de belleza.
- El pie de página dice **"© 2026 Kiogloss Beauty Products"**.
- Los informes PDF generados tienen el encabezado **"Kiogloss Beauty Products"** y pie de página morado.
- Los empleados en el sistema son personas con roles reales de una empresa de belleza.

### Lista de empleados en el sistema (datos demo):

| Nombre | Correo | Cargo |
|---|---|---|
| María Rodríguez | maria.rodriguez@kiogloss.com | Vendedora |
| Laura Castillo | laura.castillo@kiogloss.com | Supervisora |
| Sofía Herrera | sofia.herrera@kiogloss.com | Vendedora |
| Carlos Mejía | carlos.mejia@kiogloss.com | Gerente |
| Valentina Ríos | valentina.rios@kiogloss.com | Almacenista |
| Andrés Parra | andres.parra@kiogloss.com | Vendedor |

### ¿Dónde está en el código?

```
📄 lib/login_page.dart       → Nombre, ícono y pie de página del login
📄 lib/admin_console.dart    → Lista de empleados, título de pestañas
📄 lib/pdf_service.dart      → Encabezado y pie en los PDFs generados
📄 lib/MANUAL.md             → Documentación interna actualizada
📄 pubspec.yaml              → Nombre de la aplicación ("fet_admin_console" es el ID técnico)
```

---

## Cambio 2 — Nuevo tema visual (morados claros + blanco)

### ¿Qué se hizo?
Se cambió completamente la paleta de colores de la app. Antes era oscura (fondo negro/azul marino). Ahora es clara y elegante.

### Comparación antes / después:

| Elemento | Antes (oscuro) | Después (Kiogloss) |
|---|---|---|
| Fondo principal | Negro azulado `#0F172A` | Blanco suave `#FAFAFA` |
| Tarjetas | Gris oscuro `#1E293B` | Blanco `#FFFFFF` |
| Color principal | Cyan `#06B6D4` | Morado `#7C3AED` |
| Texto principal | Blanco | Azul muy oscuro `#1E1B4B` |
| Bordes | Blancos transparentes | Lila claro `#EDE9FE` |
| Gradiente login | Azul/índigo oscuro | Violeta muy claro |

### La paleta de colores completa:

```
Morado principal:  #7C3AED  ← botones, íconos activos, bordes de foco
Morado claro:      #A855F7  ← acentos secundarios
Lila muy claro:    #DDD6FE  ← fondos de campos de texto
Borde suave:       #EDE9FE  ← bordes de tarjetas
Fondo:             #FAFAFA  ← fondo de la app
Blanco:            #FFFFFF  ← tarjetas y superficies
Texto oscuro:      #1E1B4B  ← texto principal
Texto gris:        #6B7280  ← texto secundario / subtítulos
```

### ¿Dónde está en el código?

```
📄 lib/main.dart
   → Líneas 14–28: Definición del tema global (ThemeData)
   → Aquí se establece el color semilla (seedColor) y el fondo

📄 lib/login_page.dart
   → Líneas 95–110: Gradiente del fondo del login
   → Líneas 118–130: Estilo de la tarjeta blanca con borde morado

📄 lib/admin_console.dart
   → Líneas 16–24: Constantes de color (variables reutilizadas en toda la consola)
     _kPrimary    = morado principal
     _kAccent     = morado claro
     _kSurface    = blanco (tarjetas)
     _kBackground = fondo blanco suave
     _kCardBorder = borde lila
     _kTextMain   = texto oscuro
     _kTextSub    = texto gris

📄 lib/pdf_service.dart
   → Líneas 41, 83, 100: Color morado (PdfColors.purple900) en tablas y textos del PDF
```

---

## Cambio 3 — Roles de usuario (RBAC)

### ¿Qué significa RBAC?
**RBAC** = *Role-Based Access Control* = Control de acceso basado en roles.

En palabras simples: **cada persona que entra a la app solo puede ver las secciones que necesita según su trabajo**. Un vendedor no necesita ver el historial de auditoría, y un supervisor no necesita cargar PDFs.

### ¿Cómo funciona?

Hay 3 usuarios de prueba, cada uno con su contraseña y su nivel de acceso:

| Usuario | Contraseña | Rol | Qué puede ver |
|---|---|---|---|
| `admin` | `kiogloss2026` | Admin | **Todo**: Inicio, Empleados, Informes, Cargar PDF, Auditoría |
| `vendedor` | `ventas2026` | Vendedor | **Solo**: Inicio, Informes, Cargar PDF |
| `supervisor` | `super2026` | Supervisora | **Solo**: Inicio, Empleados |

### ¿Qué ve el usuario?
- Al ingresar, la barra de navegación inferior **solo muestra las pestañas permitidas** para ese rol.
- En la barra superior aparece un **badge morado** con el nombre del rol (ej: "Admin", "Vendedor").
- Si alguien intenta acceder a una sección no permitida... simplemente no aparece en el menú.

### ¿Cómo se implementó? (explicado sencillo)

Imagina una lista de pestañas numeradas del 0 al 4:
```
0 = Inicio
1 = Empleados
2 = Informes
3 = Cargar PDF
4 = Auditoría
```

Cada rol tiene una lista de los números que puede ver:
```
Admin      → [0, 1, 2, 3, 4]   (todas)
Vendedor   → [0, 2, 3]          (inicio, informes, cargar)
Supervisora→ [0, 1]             (inicio, empleados)
```

La app lee esa lista y construye el menú dinámicamente. Si el número no está en la lista del rol, esa pestaña no aparece.

### ¿Dónde está en el código?

```
📄 lib/login_page.dart
   → Líneas 10–14: Mapa de credenciales con rol asignado
     const _kCredentials = {
       'admin':      {'pass': 'kiogloss2026', 'role': 'Admin'},
       'vendedor':   {'pass': 'ventas2026',   'role': 'Vendedor'},
       'supervisor': {'pass': 'super2026',    'role': 'Supervisora'},
     };
   → Líneas 54–66: Al hacer login, lee el rol y lo pasa a la consola

📄 lib/admin_console.dart
   → Líneas 47–51: Tabla que define qué pestañas puede ver cada rol
     const _kRolePages = {
       'Admin':       [0, 1, 2, 3, 4],
       'Vendedor':    [0, 2, 3],
       'Supervisora': [0, 1],
     };
   → Línea 53: El widget AdminConsole recibe el parámetro "currentRole"
   → Líneas 88–91: Propiedad que calcula las pestañas permitidas
   → Líneas 207–220: Se construye el menú dinámicamente solo con las pestañas del rol
   → Líneas 242–252: Badge con el nombre del rol en el AppBar
   → Líneas 308–310: Los accesos rápidos del dashboard también se filtran por rol
```

---

## Cambio 4 — Verificación de integridad SHA-256 en PDFs

### ¿Qué es SHA-256?
SHA-256 es un algoritmo matemático que genera una **"huella digital"** única para cualquier archivo.

- Si un archivo PDF tiene cierto contenido, su huella SHA-256 es siempre la misma.
- Si alguien modifica aunque sea **un solo carácter** del PDF, la huella cambia completamente.
- Dos archivos diferentes **nunca** pueden tener la misma huella (es prácticamente imposible).

**Analogía:** Es como la huella dactilar de un documento. Cada documento tiene la suya y no se puede falsificar.

### ¿Para qué sirve en Kiogloss?
Cuando alguien sube un PDF al sistema (catálogo de productos, lista de precios, informe, etc.), la app calcula su huella SHA-256 y la guarda. Así se puede verificar en cualquier momento que el archivo **no fue alterado ni corrompido**.

### ¿Qué ve el usuario?
Al cargar un PDF, en la tarjeta del archivo aparece:

```
📄 catalogo_verano.pdf
   1,248 KB
   🛡️ SHA-256: a3f2c8b91d4e7f6a…
              (primeros 16 caracteres + "…")
```

Si el usuario pone el dedo sobre ese texto (tooltip), ve el hash completo de 64 caracteres.

El hash también queda guardado en el **registro de auditoría** junto con el nombre del archivo y su tamaño.

### ¿Cómo se implementó? (explicado sencillo)

1. El usuario elige un PDF desde su dispositivo.
2. La app lee los **bytes** (los datos internos) del archivo.
3. Pasa esos bytes por el algoritmo SHA-256.
4. El algoritmo devuelve una cadena de 64 letras y números (el hash).
5. La app guarda ese hash junto con el archivo y lo muestra en pantalla.

```
Ejemplo de hash SHA-256 real:
a3f2c8b91d4e7f6a0b5c2d9e8f7a1b4c3d6e0f9a2b5c8d1e4f7a0b3c6d9e2f5
```

### Dependencia nueva agregada

Para calcular SHA-256 se agregó el paquete `crypto` (desarrollado por Google):

```
📄 pubspec.yaml  →  línea 18:  crypto: ^3.0.3
```

### ¿Dónde está en el código?

```
📄 lib/admin_console.dart

   → Línea 2: Importación del paquete crypto
     import 'package:crypto/crypto.dart';

   → Línea 36: Campo sha256Hash en el modelo interno _UploadedPdf
     final String? sha256Hash;

   → Líneas 144–146: Función que calcula el hash
     String _computeHash(List<int> bytes) =>
         sha256.convert(bytes).toString();

   → Líneas 155–157: Se calcula el hash al subir el archivo
     final hash = _computeHash(rawBytes);

   → Líneas 196–201: El hash se guarda en el registro de auditoría
     details: {
       'name': name,
       'sizeBytes': sizeBytes,
       'sha256': hash,        ← aquí
     }

   → Líneas 625–638: El hash se muestra en la tarjeta del PDF
     if (hashShort != null)
       Row(
         children: [
           Icon(Icons.verified_user, color: verde),
           Text('SHA-256: $hashShort'),   ← aquí
         ],
       )
```

---

## Correcciones técnicas adicionales

Además de las funciones nuevas, se corrigieron tres errores que existían en la versión anterior:

### Corrección 1 — El cierre de sesión ya registra el evento correctamente

**Antes (problema):**  
Cuando el usuario cerraba sesión, la app navegaba a la pantalla de login *antes* de terminar de guardar el evento en el historial. Esto podía causar que el cierre de sesión no quedara registrado.

**Después (corrección):**  
Ahora la app espera (`await`) a que el evento se guarde antes de navegar.

```
📄 lib/admin_console.dart  →  función _logout() (líneas 218–223)
```

---

### Corrección 2 — Rutas de archivos compatibles con todos los sistemas

**Antes (problema):**  
El código usaba `f.path.split('/')` para obtener el nombre del archivo. En Windows, las rutas usan `\` en vez de `/`, lo que hacía que el nombre del archivo saliera mal.

**Después (corrección):**  
Se usa la función `p.basename()` del paquete `path`, que detecta automáticamente el separador correcto según el sistema operativo.

```
📄 lib/admin_console.dart  →  función _loadPdfs() (línea 122)
   p.basename(f.path)  ← funciona en Windows, Android, iOS y Web
```

---

### Corrección 3 — Filtro de "Logins fallidos" en Auditoría

**Antes (problema):**  
La pestaña de Auditoría no tenía un filtro para ver solo los intentos de login fallidos. Solo existía el filtro "Logins" que mostraba los exitosos.

**Después (corrección):**  
Se agregó el chip de filtro **"Fallidos"** que muestra exclusivamente los eventos `login_failed`.

```
📄 lib/admin_console.dart  →  función _auditTab() (línea 757)
   _filterChip('Fallidos', 'login_failed'),
```

---

## Mapa completo de archivos

```
flutter-proyecto/
│
├── pubspec.yaml                   ← Lista de "ingredientes" (dependencias) de la app
│                                    NUEVO: crypto ^3.0.3 (para SHA-256)
│
├── CAMBIOS.md                     ← Este documento
│
└── lib/                           ← Carpeta con todo el código de la app
    │
    ├── main.dart                  ← Punto de arranque de la app
    │                                Define el tema visual (colores, fuentes)
    │                                CAMBIADO: tema claro, paleta morada Kiogloss
    │
    ├── login_page.dart            ← Pantalla de inicio de sesión
    │                                CAMBIADO: diseño Kiogloss, gradiente morado
    │                                NUEVO: 3 usuarios con roles distintos (RBAC)
    │
    ├── admin_console.dart         ← Pantalla principal con todas las pestañas
    │                                CAMBIADO: colores, usuarios Kiogloss
    │                                NUEVO: RBAC (pestañas por rol)
    │                                NUEVO: SHA-256 al subir PDFs
    │                                CORREGIDO: logout con await
    │                                CORREGIDO: rutas de archivos con p.basename()
    │                                CORREGIDO: filtro "Fallidos" en Auditoría
    │
    ├── pdf_service.dart           ← Generador de informes PDF
    │                                CAMBIADO: encabezado y colores Kiogloss
    │
    ├── audit_log_service.dart     ← Guarda el historial de acciones
    │                                SIN CAMBIOS (ya funcionaba correctamente)
    │
    ├── models.dart                ← Define la estructura de datos
    │                                SIN CAMBIOS (ya tenía los campos necesarios)
    │
    └── MANUAL.md                  ← Manual de uso interno
                                     ACTUALIZADO: nuevas funciones y credenciales
```

---

## Glosario de términos técnicos usados en este documento

| Término | Qué significa en palabras simples |
|---|---|
| **Flutter** | Tecnología de Google para crear apps móviles con un solo código |
| **RBAC** | Sistema donde cada usuario solo ve lo que necesita según su cargo |
| **SHA-256** | Algoritmo que genera una "huella digital" única para cualquier archivo |
| **Hash** | El resultado de SHA-256: una cadena de 64 caracteres que identifica un archivo |
| **Paquete / dependencia** | Una herramienta externa que se agrega a la app para no reinventar la rueda |
| **`await`** | Instrucción que hace que el código espere a que una tarea termine antes de continuar |
| **Badge** | Pequeña etiqueta de color que aparece en pantalla (como la que muestra el rol) |
| **Tooltip** | Texto que aparece al mantener el dedo/cursor sobre un elemento |
| **AppBar** | La barra de título que aparece en la parte superior de la pantalla |
| **Snackbar** | El mensaje pequeño que aparece abajo de la pantalla por unos segundos |
| **PDF** | Formato de archivo de documento que se ve igual en cualquier dispositivo |
