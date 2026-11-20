// main.dart — Mis Pendientes: gestor de tareas para el teléfono (Flutter + Material 3).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ajustes.dart';
import 'almacen.dart';
import 'hoja_tarea.dart';
import 'modelo.dart';
import 'notificaciones.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Notificaciones.inicializar();
  } catch (error) {
    // Si el teléfono no permite notificaciones, la app debe abrir de todas formas.
    debugPrint('No se pudieron iniciar las notificaciones: $error');
    Notificaciones.habilitadas = false;
  }
  runApp(const MisPendientesApp());
}

class MisPendientesApp extends StatefulWidget {
  const MisPendientesApp({super.key});

  @override
  State<MisPendientesApp> createState() => _MisPendientesAppState();
}

class _MisPendientesAppState extends State<MisPendientesApp> {
  final almacen = Almacen();
  ThemeMode tema = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    almacen.cargarTema().then((t) => setState(() => tema = t));
  }

  void cambiarTema(ThemeMode t) {
    setState(() => tema = t);
    almacen.guardarTema(t);
  }

  @override
  Widget build(BuildContext context) {
    const semilla = Color(0xFF5B4BDB); // morado del icono
    return MaterialApp(
      title: 'Mis Pendientes',
      debugShowCheckedModeBanner: false,
      themeMode: tema,
      theme: ThemeData(colorSchemeSeed: semilla, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: semilla, brightness: Brightness.dark, useMaterial3: true),
      // Español: textos del calendario y de los botones del sistema.
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: PantallaLista(almacen: almacen, tema: tema, cambiarTema: cambiarTema),
    );
  }
}

class PantallaLista extends StatefulWidget {
  const PantallaLista({super.key, required this.almacen, required this.tema, required this.cambiarTema});
  final Almacen almacen;
  final ThemeMode tema;
  final ValueChanged<ThemeMode> cambiarTema;

  @override
  State<PantallaLista> createState() => _PantallaListaState();
}

class _PantallaListaState extends State<PantallaLista> {
  List<Tarea> tareas = [];
  Orden orden = Orden.fecha;
  Filtro filtro = Filtro.todas;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await widget.almacen.cargarTareas();
    final o = await widget.almacen.cargarOrden();
    if (!mounted) return;
    setState(() {
      tareas = lista;
      orden = o;
      cargando = false;
    });
  }

  Future<void> _guardar() => widget.almacen.guardarTareas(tareas);

  int get pendientes => tareas.where((t) => !t.completada).length;

  // ---------- Acciones ----------
  Future<void> _nueva() async {
    final t = await abrirHojaTarea(context);
    if (t == null) return;
    setState(() => tareas.add(t));
    await _guardar();
    await Notificaciones.programar(t);
  }

  Future<void> _editar(Tarea t) async {
    HapticFeedback.mediumImpact(); // vibración corta al mantener presionado
    final editada = await abrirHojaTarea(context, tarea: t);
    if (editada == null) return;
    setState(() {});
    await _guardar();
    await Notificaciones.programar(editada);
  }

  Future<void> _alternar(Tarea t) async {
    HapticFeedback.lightImpact();
    setState(() => t.completada = !t.completada);
    await _guardar();
    await Notificaciones.programar(t); // si se completó, se cancela el recordatorio
  }

  Future<void> _borrar(Tarea t) async {
    HapticFeedback.heavyImpact();
    final posicion = tareas.indexOf(t);
    setState(() => tareas.remove(t));
    await _guardar();
    await Notificaciones.cancelar(t);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Se borró «${t.titulo}»'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            setState(() => tareas.insert(posicion, t));
            await _guardar();
            await Notificaciones.programar(t);
          },
        ),
      ));
  }

  Future<void> _actualizar() async {
    await _cargar();
    if (!mounted) return;
    final vencidas = tareas.where((t) => t.vencida).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lista actualizada · $pendientes pendiente(s) · $vencidas vencida(s)')),
    );
  }

  Future<void> _agregarEjemplos() async {
    final hoy = soloFecha(DateTime.now());
    var id = DateTime.now().millisecondsSinceEpoch % 2000000000;
    final ejemplos = [
      Tarea(id: id++, titulo: 'Entregar reporte de AWP', nota: 'Subproducto 4 en Classroom', prioridad: Prioridad.alta, fechaLimite: hoy.add(const Duration(days: 1))),
      Tarea(id: id++, titulo: 'Pagar el internet', prioridad: Prioridad.alta, fechaLimite: hoy.subtract(const Duration(days: 2))),
      Tarea(id: id++, titulo: 'Comprar despensa', nota: 'Leche, huevo y tortillas', prioridad: Prioridad.media, fechaLimite: hoy),
      Tarea(id: id++, titulo: 'Estudiar para el examen de inglés', prioridad: Prioridad.media, fechaLimite: hoy.add(const Duration(days: 5))),
      Tarea(id: id++, titulo: 'Llamar al dentista', prioridad: Prioridad.baja),
      Tarea(id: id++, titulo: 'Lavar el coche', prioridad: Prioridad.baja, completada: true),
    ];
    setState(() => tareas.addAll(ejemplos));
    await _guardar();
    for (final t in ejemplos) {
      await Notificaciones.programar(t);
    }
  }

  void _cambiarOrden(Orden o) {
    setState(() => orden = o);
    widget.almacen.guardarOrden(o);
  }

  // ---------- Interfaz ----------
  @override
  Widget build(BuildContext context) {
    final visibles = ordenarYFiltrar(tareas, orden, filtro);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mis Pendientes'),
            Text('$pendientes pendiente(s) de ${tareas.length}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          PopupMenuButton<Orden>(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.sort),
            initialValue: orden,
            onSelected: _cambiarOrden,
            itemBuilder: (_) => [for (final o in Orden.values) PopupMenuItem(value: o, child: Text('Ordenar por: ${o.texto}'))],
          ),
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PantallaAjustes(tema: widget.tema, cambiarTema: widget.cambiarTema, pendientes: pendientes),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final f in Filtro.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(f.texto), selected: filtro == f, onSelected: (_) => setState(() => filtro = f)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _actualizar,
                    child: visibles.isEmpty
                        ? _vacio(context)
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: visibles.length,
                            itemBuilder: (_, i) => _filaTarea(visibles[i]),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab_nueva'),
        onPressed: _nueva,
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
    );
  }

  Widget _vacio(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          Icon(Icons.task_alt, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            tareas.isEmpty ? 'No tienes tareas. ¡Agrega la primera!' : 'No hay tareas con este filtro.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (tareas.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                key: const Key('boton_ejemplos'),
                onPressed: _agregarEjemplos,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Agregar tareas de ejemplo'),
              ),
            ),
          ],
        ],
      );

  Widget _filaTarea(Tarea t) {
    final colores = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(t.id),
      // Fondo al deslizar a la derecha (completar) y a la izquierda (borrar).
      background: _fondo(Colors.green.shade600, t.completada ? Icons.undo : Icons.check, t.completada ? 'Reabrir' : 'Completar', Alignment.centerLeft),
      secondaryBackground: _fondo(Colors.red.shade600, Icons.delete, 'Borrar', Alignment.centerRight),
      confirmDismiss: (direccion) async {
        if (direccion == DismissDirection.startToEnd) {
          await _alternar(t);
          return false; // la tarea no desaparece, solo cambia de estado
        }
        return true;
      },
      onDismissed: (_) => _borrar(t),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          onLongPress: () => _editar(t),
          leading: Checkbox(value: t.completada, onChanged: (_) => _alternar(t)),
          title: Text(
            t.titulo,
            style: TextStyle(
              decoration: t.completada ? TextDecoration.lineThrough : null,
              color: t.completada ? colores.outline : null,
            ),
          ),
          subtitle: Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.flag, size: 16, color: colorPrioridad(t.prioridad)),
                const SizedBox(width: 2),
                Text(t.prioridad.texto),
              ]),
              if (t.fechaLimite != null)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.event, size: 16, color: t.vencida ? colores.error : null),
                  const SizedBox(width: 2),
                  Text(
                    t.vencida ? 'Vencida · ${fechaCorta(t.fechaLimite!)}' : fechaCorta(t.fechaLimite!),
                    style: TextStyle(color: t.vencida ? colores.error : null, fontWeight: t.vencida ? FontWeight.bold : null),
                  ),
                ]),
              if (t.nota.isNotEmpty) Text(t.nota, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fondo(Color color, IconData icono, String texto, Alignment alineacion) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        alignment: alineacion,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icono, color: Colors.white), const SizedBox(width: 8), Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
        ),
      );
}
