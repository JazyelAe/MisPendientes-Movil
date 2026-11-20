// Pruebas de Mis Pendientes: lógica de orden/filtro y gestos en la interfaz.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mispendientes/main.dart';
import 'package:mispendientes/modelo.dart';
import 'package:mispendientes/notificaciones.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Notificaciones.habilitadas = false; // en las pruebas no hay teléfono
  });

  test('ordenar por prioridad y filtrar vencidas', () {
    final hoy = soloFecha(DateTime.now());
    final tareas = [
      Tarea(id: 1, titulo: 'baja', prioridad: Prioridad.baja),
      Tarea(id: 2, titulo: 'alta', prioridad: Prioridad.alta),
      Tarea(id: 3, titulo: 'vencida', prioridad: Prioridad.media, fechaLimite: hoy.subtract(const Duration(days: 1))),
      Tarea(id: 4, titulo: 'hecha', prioridad: Prioridad.alta, completada: true),
    ];
    expect(ordenarYFiltrar(tareas, Orden.prioridad, Filtro.todas).map((t) => t.titulo).toList(),
        ['alta', 'vencida', 'baja', 'hecha']);
    expect(ordenarYFiltrar(tareas, Orden.fecha, Filtro.vencidas).map((t) => t.titulo).toList(), ['vencida']);
    expect(ordenarYFiltrar(tareas, Orden.fecha, Filtro.completadas).map((t) => t.titulo).toList(), ['hecha']);
  });

  testWidgets('alta, completar deslizando, borrar deslizando y deshacer', (tester) async {
    await tester.pumpWidget(const MisPendientesApp());
    await tester.pumpAndSettle();
    expect(find.text('No tienes tareas. ¡Agrega la primera!'), findsOneWidget);

    // Alta
    await tester.tap(find.byKey(const Key('fab_nueva')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo_titulo')), 'Estudiar Flutter');
    await tester.tap(find.byKey(const Key('boton_guardar')));
    await tester.pumpAndSettle();
    expect(find.text('Estudiar Flutter'), findsOneWidget);
    expect(find.text('1 pendiente(s) de 1'), findsOneWidget);

    // Deslizar a la derecha = completar (la tarea sigue en la lista)
    await tester.drag(find.text('Estudiar Flutter'), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('0 pendiente(s) de 1'), findsOneWidget);

    // Deslizar a la izquierda = borrar, con opción de deshacer
    await tester.drag(find.text('Estudiar Flutter'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Estudiar Flutter'), findsNothing);
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(find.text('Estudiar Flutter'), findsOneWidget);
  });

  testWidgets('mantener presionado abre la edición y se guarda', (tester) async {
    await tester.pumpWidget(const MisPendientesApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton_ejemplos')));
    await tester.pumpAndSettle();
    expect(find.text('5 pendiente(s) de 6'), findsOneWidget);

    await tester.longPress(find.text('Llamar al dentista'));
    await tester.pumpAndSettle();
    expect(find.text('Editar tarea'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('campo_titulo')), 'Llamar al dentista mañana');
    await tester.tap(find.byKey(const Key('boton_guardar')));
    await tester.pumpAndSettle();
    expect(find.text('Llamar al dentista mañana'), findsOneWidget);

    // Las tareas se guardaron en shared_preferences
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tareas'), contains('Llamar al dentista mañana'));
  });
}
