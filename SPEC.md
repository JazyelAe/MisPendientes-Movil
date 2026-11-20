# SPEC · Mis Pendientes — Subproducto No. 4 "Aplicación Móvil"

**Materia:** Aplicaciones Web Progresivas · Unidad I · Actividad Desarrollo
**Alumno:** Jahir Jaziel Serrano Arana · 10° D
**Repositorio:** `JazyelAe/MisPendientes-Movil` (nuevo, público)
**Estado:** borrador para aprobación (Checkpoint A)

## 1. Objetivo
Crear una **aplicación móvil** para gestionar tareas personales, pensada desde el inicio para el teléfono:
- **Pantalla pequeña y uso con una mano.**
- **Interacción táctil:** deslizar, mantener presionado y jalar para actualizar.
- **Capacidades del dispositivo:** notificaciones locales y respuesta háptica (vibración).

Se construye con **Flutter + Dart**, se distribuye como **APK de Android** en un GitHub Release y, además, tiene una **demo web** en GitHub Pages para verla desde cualquier navegador.

**Cómo se distingue de los otros subproductos (se explica en el reporte):**
- **SP1 (nativa):** se programa con el SDK oficial de Android (Kotlin).
- **SP4 (móvil):** el enfoque es el **diseño y la experiencia móvil** (gestos, tamaño de pantalla, sensores y notificaciones). Flutter compila a código nativo ARM para el teléfono.
- **SP5 (multiplataforma):** el enfoque es **un solo código para Android, iOS y web** (React Native + Expo).

## 2. Auditoría
Es un **repo nuevo**, así que no hay código previo. Entorno revisado:
- **Flutter 3.47.9 / Dart 3.13.7** en `C:\Users\Irving\flutter`, fuera del PATH. Funciona para web y Windows.
- **No hay Android SDK** en la PC, por lo que el APK se compila en **GitHub Actions** (como en SP1).

## 3. Requisitos funcionales
- **RF-1 Lista de tareas.** Se pueden **dar de alta** (botón flotante + hoja inferior), **editar**, **marcar como completadas** y **borrar**. Cada tarea tiene título, nota opcional, prioridad y fecha límite.
- **RF-2 Gestos táctiles.**
  - **Deslizar a la derecha:** completar o reabrir la tarea.
  - **Deslizar a la izquierda:** borrar, con un **SnackBar "Deshacer"**.
  - **Mantener presionado:** editar.
  - **Jalar hacia abajo (pull to refresh):** recarga la lista y recalcula las tareas vencidas.
- **RF-3 Prioridad y fecha límite.**
  - **Prioridad** alta, media o baja, con color.
  - **Fecha límite** con el selector de fecha nativo de Material.
  - **Orden:** por fecha, prioridad o creación.
  - **Filtro:** todas, pendientes, completadas o vencidas.
  - Las tareas vencidas se marcan en rojo.
- **RF-4 Persistencia local** con `shared_preferences` (en el teléfono se guarda en las preferencias de Android; en la web, en `localStorage`).
- **RF-5 Capacidades del dispositivo.**
  - **Notificación local de recordatorio** (`flutter_local_notifications`): la tarea con fecha límite avisa ese día a las 9:00. Además hay un botón **"Probar notificación"** en Ajustes. En Android 13+ se pide el permiso.
  - **Vibración háptica** (`HapticFeedback`) al completar, borrar y en la pulsación larga.
  - En la demo web no hay notificaciones del sistema: se oculta la opción y se explica en pantalla.
- **RF-6 Diseño.** Material 3, **modo oscuro** (sigue al sistema o se elige en Ajustes) e **icono propio** (`flutter_launcher_icons`). Interfaz en español.

## 4. Requisitos no funcionales
- **RNF-1** Android 7.0+ (minSdk 24). Paquete `com.jaziel.mispendientes`.
- **RNF-2** Funciona sin Internet.
- **RNF-3** Código en español, comentado, en pocos archivos (`main.dart`, `modelo.dart`, `almacen.dart`, `notificaciones.dart`, pantallas).
- **RNF-4** Pruebas de widget con `flutter test` (alta, completar, borrar y ordenar).
- **RNF-5** La demo web funciona en `https://jazyelae.github.io/MisPendientes-Movil/` (`--base-href`).

## 5. Tecnologías
| Capa | Tecnología |
|---|---|
| Lenguaje y framework | Dart 3.13 · Flutter 3.47 (Material 3) |
| Persistencia | `shared_preferences` (JSON) |
| Notificaciones | `flutter_local_notifications` + `timezone` |
| Háptica | `HapticFeedback` (servicios de la plataforma) |
| Icono | `flutter_launcher_icons` |
| CI/CD | GitHub Actions: `flutter test`, `flutter build apk --release` → Release; `flutter build web` → GitHub Pages |
| Pruebas en dispositivo | Emulador Android 14 en GitHub Actions con `adb` (como en SP1) |

## 6. Criterios de aceptación
| # | Criterio | Cómo se verifica |
|---|---|---|
| CA-1 | `flutter test` pasa. | Actions |
| CA-2 | El APK se instala y abre en Android; los datos persisten al cerrar y volver a abrir. | Emulador Android 14 en Actions (adb) + capturas |
| CA-3 | Los gestos funcionan: deslizar a la derecha completa, a la izquierda borra (con Deshacer), mantener presionado edita y jalar actualiza. | adb `input swipe` en el emulador + capturas |
| CA-4 | Ordenar y filtrar por prioridad, fecha y estado funciona; las vencidas se ven en rojo. | Emulador o web + capturas |
| CA-5 | Llega la notificación (botón de prueba) y se registra la vibración. | `dumpsys notification` y `dumpsys vibrator_manager` en el emulador + captura |
| CA-6 | La demo web carga en Pages en vista móvil (390×844). | Playwright + capturas |
| CA-7 | El Release `v1.0.0` tiene el APK descargable. | Página del Release |
| CA-8 | README con capturas y enlaces. | Revisar el repo |

## 7. Plan de despliegue
- `.github/workflows/flutter.yml`:
  - En cada push: `flutter test`, después `flutter build web --base-href /MisPendientes-Movil/` y publica en **Pages**.
  - Al crear la etiqueta `v1.0.0`: `flutter build apk --release` y lo adjunta al **Release**.
- `.github/workflows/capturas.yml`: un emulador Android 14 instala el APK del Release, recorre la app con adb y guarda las capturas.
- **URL de la aplicación:** Release (APK) + demo web en Pages.

## 8. Capturas (todas automáticas, sin pedirte nada)
- **Android (emulador):**
  - `01_lista.png` · `02_nueva_tarea.png` · `03_selector_fecha.png` · `04_deslizar_completar.png`
  - `05_deslizar_borrar_deshacer.png` · `06_editar.png` · `07_orden_filtro.png` · `08_modo_oscuro.png`
  - `09_notificacion.png` · `10_icono.png`
- **Web (Playwright, 390×844):** `11_web_movil.png`.

**Opcional:** si quieres, en el Checkpoint B te pido 1 o 2 fotos de la app en **tu propio teléfono**.

## 9. Ejemplos reales propuestos (URL comprobadas el 20/11/2026)
| App | Por qué es móvil | URL |
|---|---|---|
| Instagram | Hecha para el celular: cámara, gestos (deslizar historias, doble toque) y notificaciones push. | https://play.google.com/store/apps/details?id=com.instagram.android |
| Uber | Depende del GPS en tiempo real, mapas, pagos y notificaciones del teléfono. | https://play.google.com/store/apps/details?id=com.ubercab |
| Duolingo | Lecciones cortas pensadas para el teléfono, recordatorios diarios y uso del micrófono para ejercicios de pronunciación. | https://play.google.com/store/apps/details?id=com.duolingo |

Fuentes técnicas (comprobadas): documentación de Flutter, Material 3, Android Developers (gestos táctiles) y pub.dev (`shared_preferences`, `flutter_local_notifications`, `flutter_launcher_icons`).

## 10. Pruebas
_(Se llena después de implementar.)_
