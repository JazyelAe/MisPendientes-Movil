#!/usr/bin/env bash
# Toma capturas REALES de Mis Pendientes en un emulador Android con adb y UI Automator.
# Incluye gestos táctiles reales (deslizar, mantener presionado y jalar para actualizar).
# Lo ejecuta .github/workflows/capturas.yml. Uso: bash scripts/capturas.sh MisPendientes.apk
set -u
APK="$1"
PKG="com.jaziel.mispendientes"
mkdir -p capturas
LOG=capturas/pruebas.txt
: > "$LOG"
anota() { echo "$*" | tee -a "$LOG"; }

# Devuelve "x1 y1 x2 y2" del primer elemento cuyo texto o descripción CONTIENE el valor.
limites() {
  # El volcado falla si la pantalla sigue animándose ("could not get idle state"): se reintenta.
  for intento in 1 2 3 4 5; do
    rm -f ui.xml
    adb shell rm -f /sdcard/ui.xml >/dev/null 2>&1
    adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
    adb pull /sdcard/ui.xml ui.xml >/dev/null 2>&1
    if [ -s ui.xml ]; then
      python3 - "$1" <<'PY'
import re, sys, xml.etree.ElementTree as ET
buscado = sys.argv[1]
nodos = list(ET.parse("ui.xml").iter("node"))
# primero coincidencia exacta, después "contiene"
for exacto in (True, False):
    for n in nodos:
        for valor in (n.get("text") or "", n.get("content-desc") or ""):
            if (valor == buscado) if exacto else (buscado in valor):
                print(*re.findall(r"\d+", n.get("bounds")))
                sys.exit(0)
sys.exit(1)  # la pantalla se leyó bien, pero el elemento no está
PY
      return $?
    fi
    sleep 1
  done
  return 1
}

centro() { local b; b=$(limites "$1"); [ -z "$b" ] && return 1; set -- $b; echo "$(( ($1+$3)/2 )) $(( ($2+$4)/2 ))"; }
existe() { [ -n "$(limites "$1")" ]; }

tocar() { # tocar "texto1" ["texto2" ...] — toca el primero que aparezca
  for intento in 1 2 3 4 5 6; do
    for valor in "$@"; do
      local xy; xy=$(centro "$valor") && { adb shell input tap $xy; sleep 1.5; anota "  tocado: $valor"; return 0; }
    done
    sleep 2
  done
  anota "  ERROR: no encontré $*"; return 1
}

esperar() { for i in $(seq 1 20); do existe "$1" && return 0; sleep 2; done; return 1; }
cap() { sleep 1; adb exec-out screencap -p > "capturas/$1"; anota "captura: $1"; }

# Deslizamiento horizontal "en pausa": baja el dedo, se mueve hasta una fracción y toma la captura antes de soltar.
deslizar_con_captura() { # texto, dirección (der|izq), archivo, soltar_en(fracción del ancho)
  local b; b=$(limites "$1") || return 1; set -- $b "$2" "$3" "$4"
  local y=$(( ($2+$4)/2 )) x0 xm xf
  if [ "$5" = der ]; then x0=$(( $1+60 )); xm=$(( $1+($3-$1)*45/100 )); xf=$(( $1+($3-$1)*$7/100 ));
  else x0=$(( $3-60 )); xm=$(( $3-($3-$1)*45/100 )); xf=$(( $3-($3-$1)*$7/100 )); fi
  adb shell input motionevent DOWN $x0 $y; sleep 0.2
  for paso in 1 2 3 4 5; do adb shell input motionevent MOVE $(( x0+(xm-x0)*paso/5 )) $y; sleep 0.05; done
  sleep 0.5; adb exec-out screencap -p > "capturas/$6"; anota "captura: $6"
  adb shell input motionevent MOVE $xf $y; sleep 0.1
  adb shell input motionevent UP $xf $y; sleep 1.5
}

# ---------- Arranque del emulador en español ----------
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done
adb root >/dev/null 2>&1; sleep 3
adb shell "setprop persist.sys.locale es-MX; setprop ctl.restart zygote"; sleep 15
for i in $(seq 1 60); do adb shell dumpsys activity activities 2>/dev/null | grep -q "ResumedActivity.*launcher" && break; sleep 3; done
sleep 10
adb shell input keyevent KEYCODE_WAKEUP; adb shell wm dismiss-keyguard
for s in window_animation_scale transition_animation_scale animator_duration_scale; do adb shell settings put global $s 0; done
anota "== Dispositivo: $(adb shell getprop ro.product.model) · Android $(adb shell getprop ro.build.version.release) (API $(adb shell getprop ro.build.version.sdk)) · idioma $(adb shell getprop persist.sys.locale)"

adb install -r "$APK" && anota "CA-2 instalación del APK: OK"
abrir() { for i in 1 2 3 4 5; do adb shell am start -W -n "$PKG/.MainActivity" >/dev/null; sleep 5; existe "Nueva tarea" && return 0; sleep 5; done; return 1; }
if abrir; then anota "CA-2 la app abre: OK"; else
  anota "ERROR: la app no abrió. Registro del sistema (logcat):"
  adb logcat -d -t 400 | grep -iE "flutter|mispendientes|AndroidRuntime|FATAL" | tail -60 | tee -a "$LOG"
  cap 00_error.png; exit 1
fi

# 1. Lista con tareas de ejemplo
tocar "Agregar tareas de ejemplo"
existe "Pagar el internet" && anota "Tareas de ejemplo agregadas"
cap 01_lista.png

# 2-3. Nueva tarea con fecha límite (selector nativo de Material)
tocar "Nueva tarea"
adb shell input text "Repasar%sgestos%sde%sFlutter"; sleep 1
adb shell input keyevent KEYCODE_BACK; sleep 1   # oculta el teclado
tocar "Alta"
cap 02_nueva_tarea.png
tocar "Sin fecha límite"
sleep 1; cap 03_selector_fecha.png
tocar "Aceptar" "ACEPTAR" "OK"
tocar "Agregar tarea"
existe "Repasar gestos de Flutter" && anota "CA-1 alta de tarea: OK"

# 4. Deslizar a la derecha = completar
deslizar_con_captura "Comprar despensa" der 04_deslizar_completar.png 85
sleep 1
limites "pendiente(s) de" >/dev/null && anota "CA-3 deslizar a la derecha completa → contador: $(grep -o '[0-9]* pendiente(s) de [0-9]*' ui.xml | head -1) (antes 6 de 7)"

# 5. Deslizar a la izquierda = borrar, con "Deshacer"
deslizar_con_captura "Llamar al dentista" izq 05a_deslizar_borrar.png 90
existe "Llamar al dentista" || anota "CA-3 deslizar a la izquierda borra: OK"
cap 05_borrar_deshacer.png
tocar "Deshacer"
existe "Llamar al dentista" && anota "CA-3 Deshacer restaura la tarea: OK"

# 6. Mantener presionado = editar
xy=$(centro "Estudiar para el examen")
adb shell input swipe $xy $xy 1200; sleep 2
existe "Editar tarea" && anota "CA-3 mantener presionado abre la edición: OK"
cap 06_editar.png
adb shell input keyevent KEYCODE_BACK; sleep 1; existe "Editar tarea" && { adb shell input keyevent KEYCODE_BACK; sleep 1; }

# 7. Ordenar por prioridad y filtrar vencidas
tocar "Ordenar"
sleep 1; cap 07a_menu_orden.png
tocar "Ordenar por: Prioridad"
cap 07_orden_prioridad.png
tocar "Vencidas"
cap 07b_filtro_vencidas.png
existe "Pagar el internet" && anota "CA-4 filtro Vencidas muestra la tarea vencida: OK"
tocar "Todas"

# 8. Jalar para actualizar
TAM=$(adb shell wm size | grep -o '[0-9]*x[0-9]*' | tail -1); W=${TAM%x*}; H=${TAM#*x}
adb shell input swipe $((W/2)) $((H*30/100)) $((W/2)) $((H*75/100)) 600; sleep 1.5
existe "Lista actualizada" && anota "CA-3 jalar para actualizar: OK"
cap 12_jalar_actualizar.png

# 9. Persistencia: cerrar por completo y volver a abrir
adb shell am force-stop "$PKG"; sleep 1; abrir
existe "Repasar gestos de Flutter" && anota "CA-2 los datos persisten al cerrar y abrir: OK"

# 10. Notificación de prueba (pide el permiso de Android 13+)
tocar "Ajustes"
tocar "Probar notificación"
sleep 2
existe "Permitir" && { cap 09a_permiso.png; tocar "Permitir"; anota "Permiso POST_NOTIFICATIONS concedido"; }
sleep 2
adb shell dumpsys notification --noredact 2>/dev/null | grep -q "pendiente(s)" && anota "CA-5 notificación publicada: OK"
adb shell cmd statusbar expand-notifications; sleep 2
cap 09_notificacion.png
adb shell cmd statusbar collapse; sleep 1
anota "-- Recordatorios programados (AlarmManager):"
adb shell dumpsys alarm 2>/dev/null | grep -c "$PKG" | xargs -I{} echo "   alarmas de $PKG: {}" | tee -a "$LOG"
anota "-- Vibraciones registradas por el sistema (respuesta háptica):"
adb shell dumpsys vibrator_manager 2>/dev/null | grep -i "$PKG" | head -3 | cut -c1-220 | tee -a "$LOG"

# 11. Modo oscuro
tocar "Oscuro"
adb shell input keyevent KEYCODE_BACK; sleep 2
cap 08_modo_oscuro.png

# 12. Icono en el cajón de apps
adb shell input keyevent KEYCODE_HOME; sleep 2
adb shell input swipe $((W/2)) $((H*85/100)) $((W/2)) $((H*20/100)) 300; sleep 3
cap 10_icono.png
anota "== Fin"
