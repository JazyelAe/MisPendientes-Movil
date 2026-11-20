// hoja_tarea.dart — Hoja inferior (bottom sheet) para crear o editar una tarea.
import 'package:flutter/material.dart';

import 'modelo.dart';

/// Abre la hoja y devuelve la tarea creada/editada, o null si se canceló.
Future<Tarea?> abrirHojaTarea(BuildContext context, {Tarea? tarea}) {
  return showModalBottomSheet<Tarea>(
    context: context,
    isScrollControlled: true, // permite que suba con el teclado
    showDragHandle: true,
    builder: (_) => HojaTarea(tarea: tarea),
  );
}

class HojaTarea extends StatefulWidget {
  const HojaTarea({super.key, this.tarea});
  final Tarea? tarea;

  @override
  State<HojaTarea> createState() => _HojaTareaState();
}

class _HojaTareaState extends State<HojaTarea> {
  late final _titulo = TextEditingController(text: widget.tarea?.titulo ?? '');
  late final _nota = TextEditingController(text: widget.tarea?.nota ?? '');
  late Prioridad _prioridad = widget.tarea?.prioridad ?? Prioridad.media;
  late DateTime? _fecha = widget.tarea?.fechaLimite;
  String? _error;

  Future<void> _elegirFecha() async {
    final hoy = soloFecha(DateTime.now());
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: hoy.subtract(const Duration(days: 365)),
      lastDate: hoy.add(const Duration(days: 365 * 3)),
      helpText: 'Fecha límite',
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  void _guardar() {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty) {
      setState(() => _error = 'Escribe un título');
      return;
    }
    final t = widget.tarea ?? Tarea(id: DateTime.now().millisecondsSinceEpoch % 2000000000, titulo: titulo);
    t
      ..titulo = titulo
      ..nota = _nota.text.trim()
      ..prioridad = _prioridad
      ..fechaLimite = _fecha;
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.tarea != null;
    return Padding(
      // deja espacio para el teclado del teléfono
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(editando ? 'Editar tarea' : 'Nueva tarea', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            key: const Key('campo_titulo'),
            controller: _titulo,
            autofocus: !editando,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: 'Título', errorText: _error, border: const OutlineInputBorder()),
            onSubmitted: (_) => _guardar(),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('campo_nota'),
            controller: _nota,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Nota (opcional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const Text('Prioridad'),
          const SizedBox(height: 6),
          SegmentedButton<Prioridad>(
            segments: [
              for (final p in Prioridad.values)
                ButtonSegment(value: p, label: Text(p.texto), icon: Icon(Icons.flag, color: colorPrioridad(p))),
            ],
            selected: {_prioridad},
            onSelectionChanged: (s) => setState(() => _prioridad = s.first),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('boton_fecha'),
                  onPressed: _elegirFecha,
                  icon: const Icon(Icons.event),
                  label: Text(_fecha == null ? 'Sin fecha límite' : 'Vence: ${fechaCorta(_fecha!)}'),
                ),
              ),
              if (_fecha != null)
                IconButton(tooltip: 'Quitar fecha', onPressed: () => setState(() => _fecha = null), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('boton_guardar'),
            onPressed: _guardar,
            icon: const Icon(Icons.check),
            label: Text(editando ? 'Guardar cambios' : 'Agregar tarea'),
          ),
        ],
      ),
    );
  }
}

Color colorPrioridad(Prioridad p) => switch (p) {
      Prioridad.alta => Colors.red.shade400,
      Prioridad.media => Colors.orange.shade400,
      Prioridad.baja => Colors.green.shade400,
    };
