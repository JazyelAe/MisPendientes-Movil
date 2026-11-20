// notificaciones.dart — Notificaciones locales del teléfono (flutter_local_notifications).
// - Recordatorio el día de la fecha límite a las 9:00.
// - Notificación de prueba inmediata.
// En la demo web (kIsWeb) y en las pruebas automáticas se desactivan.
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdatos;
import 'package:timezone/timezone.dart' as tz;

import 'modelo.dart';

class Notificaciones {
  static bool habilitadas = !kIsWeb;
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'recordatorios',
      'Recordatorios de tareas',
      channelDescription: 'Avisos de tareas que vencen hoy',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> inicializar() async {
    if (!habilitadas) return;
    tzdatos.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notificacion')),
    );
  }

  /// Android 13+ pide permiso para mostrar notificaciones. Devuelve true si se concedió.
  static Future<bool> pedirPermiso() async {
    if (!habilitadas) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  static Future<void> probar(int pendientes) async {
    if (!habilitadas) return;
    await _plugin.show(
      id: 0,
      title: 'Mis Pendientes',
      body: pendientes == 0 ? '¡No tienes tareas pendientes!' : 'Tienes $pendientes tarea(s) pendiente(s).',
      notificationDetails: _detalles,
    );
  }

  /// Programa (o reprograma) el aviso de una tarea para el día de su fecha límite a las 9:00.
  static Future<void> programar(Tarea t) async {
    if (!habilitadas) return;
    await cancelar(t);
    if (t.completada || t.fechaLimite == null) return;
    final f = t.fechaLimite!;
    final cuando = tz.TZDateTime(tz.local, f.year, f.month, f.day, 9);
    if (cuando.isBefore(tz.TZDateTime.now(tz.local))) return; // ya pasó
    await _plugin.zonedSchedule(
      id: t.id,
      title: 'Hoy vence: ${t.titulo}',
      body: t.nota.isEmpty ? 'Prioridad ${t.prioridad.texto.toLowerCase()}' : t.nota,
      scheduledDate: cuando,
      notificationDetails: _detalles,
      // "inexacta": Android puede retrasarla unos minutos para ahorrar batería; no requiere permisos especiales.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelar(Tarea t) async {
    if (!habilitadas) return;
    await _plugin.cancel(id: t.id);
  }
}
