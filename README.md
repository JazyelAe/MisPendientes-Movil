# ✅ Mis Pendientes — Aplicación móvil

Gestor de tareas **pensado para el teléfono**: se usa con una mano, con **gestos táctiles** (deslizar, mantener presionado, jalar para actualizar), **notificaciones locales** de recordatorio y **vibración háptica**. Hecho con **Flutter + Dart** y Material 3.

> Subproducto No. 4 · Aplicaciones Web Progresivas · Unidad I
> Universidad Tecnológica de Puebla · Jahir Jaziel Serrano Arana · 10° D

## ⬇️ Descargar y probar
- **APK para Android 7.0+:** https://github.com/JazyelAe/MisPendientes-Movil/releases/tag/v1.0.0 → descarga `MisPendientes-v1.0.0.apk` en el teléfono, ábrelo y permite instalar apps de origen desconocido.
- **Demo web (vista móvil):** https://jazyelae.github.io/MisPendientes-Movil/ — sin notificaciones ni vibración, que son funciones del teléfono.

## Funciones
| | Función |
|---|---|
| 📝 | Alta (botón flotante + hoja inferior), edición, completar y borrar tareas |
| 👉 | **Desliza a la derecha** para completar o reabrir |
| 👈 | **Desliza a la izquierda** para borrar, con **Deshacer** |
| ✋ | **Mantén presionado** para editar (con vibración corta) |
| 🔄 | **Jala hacia abajo** para actualizar la lista |
| 🚩 | Prioridad alta / media / baja, fecha límite con calendario, orden y filtros; vencidas en rojo |
| 🔔 | Recordatorio el día de la fecha límite a las 9:00 y botón "Probar notificación" (permiso de Android 13+) |
| 💾 | Datos guardados en el teléfono (`shared_preferences`), funciona sin Internet |
| 🌙 | Material 3, modo oscuro e icono propio |

## ¿Por qué es una aplicación móvil?
- Está diseñada para **pantallas pequeñas y uso táctil**: botón flotante al alcance del pulgar, hojas inferiores y gestos.
- Usa **capacidades del teléfono**: notificaciones del sistema, motor de vibración y almacenamiento local.
- Se instala en Android como cualquier app (APK) y funciona sin conexión.

## Tecnologías
Dart 3.13 · Flutter 3.47 · Material 3 · shared_preferences · flutter_local_notifications + timezone · flutter_launcher_icons · GitHub Actions (pruebas, APK y Pages)

## Estructura
```
lib/main.dart            app, lista, gestos y acciones
lib/hoja_tarea.dart      hoja inferior para crear/editar
lib/ajustes.dart         tema, notificación de prueba y ayuda de gestos
lib/modelo.dart          clase Tarea, orden y filtros
lib/almacen.dart         persistencia con shared_preferences
lib/notificaciones.dart  notificaciones locales
test/widget_test.dart    pruebas (alta, gestos, deshacer, edición, persistencia)
scripts/capturas.sh      capturas en emulador con adb
```

## Cómo ejecutarla
```
flutter pub get
flutter test
flutter run            # con un teléfono o emulador Android conectado
flutter run -d chrome  # demo web
```

## Capturas
Se encuentran en [`docs/capturas/`](docs/capturas/).

## Documentación
- Especificación y pruebas: [SPEC.md](SPEC.md)
- Repositorio central de la unidad: https://github.com/JazyelAe/AWP-Unidad-I
