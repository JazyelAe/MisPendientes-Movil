// ajustes.dart — Pantalla de ajustes: tema, notificación de prueba y ayuda de gestos.
import 'package:flutter/material.dart';

import 'notificaciones.dart';

class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key, required this.tema, required this.cambiarTema, required this.pendientes});

  final ThemeMode tema;
  final ValueChanged<ThemeMode> cambiarTema;
  final int pendientes;

  Future<void> _probar(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    final permiso = await Notificaciones.pedirPermiso();
    if (!permiso) {
      mensajero.showSnackBar(const SnackBar(content: Text('Sin permiso de notificaciones: actívalo en los ajustes del teléfono.')));
      return;
    }
    await Notificaciones.probar(pendientes);
    mensajero.showSnackBar(const SnackBar(content: Text('Notificación enviada: revisa la barra de notificaciones.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tema', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Sistema'), icon: Icon(Icons.phone_android)),
              ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode)),
            ],
            selected: {tema},
            onSelectionChanged: (s) => cambiarTema(s.first),
          ),
          const Divider(height: 32),
          Text('Notificaciones', style: Theme.of(context).textTheme.titleMedium),
          if (Notificaciones.habilitadas) ...[
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.alarm),
              title: Text('Recordatorio automático'),
              subtitle: Text('Cada tarea con fecha límite te avisa ese día a las 9:00.'),
            ),
            FilledButton.tonalIcon(
              key: const Key('boton_probar'),
              onPressed: () => _probar(context),
              icon: const Icon(Icons.notifications_active),
              label: const Text('Probar notificación'),
            ),
          ] else
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline),
              title: Text('Disponibles en la app para Android'),
              subtitle: Text('Esta es la demo web: las notificaciones y la vibración son funciones del teléfono.'),
            ),
          const Divider(height: 32),
          Text('Gestos', style: Theme.of(context).textTheme.titleMedium),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.swipe_right), title: Text('Desliza a la derecha'), subtitle: Text('Completa o reabre la tarea')),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.swipe_left), title: Text('Desliza a la izquierda'), subtitle: Text('Borra la tarea (puedes deshacer)')),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.touch_app), title: Text('Mantén presionado'), subtitle: Text('Edita la tarea')),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.refresh), title: Text('Jala hacia abajo'), subtitle: Text('Actualiza la lista')),
          const Divider(height: 32),
          const Text('Mis Pendientes v1.0.0 · Jahir Jaziel Serrano Arana · UTP 10° D', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
