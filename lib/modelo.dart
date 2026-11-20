// modelo.dart — La clase Tarea y utilidades de fechas.

enum Prioridad { alta, media, baja }

extension PrioridadTexto on Prioridad {
  String get texto => switch (this) {
        Prioridad.alta => 'Alta',
        Prioridad.media => 'Media',
        Prioridad.baja => 'Baja',
      };
}

class Tarea {
  Tarea({
    required this.id,
    required this.titulo,
    this.nota = '',
    this.prioridad = Prioridad.media,
    this.fechaLimite,
    this.completada = false,
    DateTime? creada,
  }) : creada = creada ?? DateTime.now();

  final int id; // también se usa como id de la notificación
  String titulo;
  String nota;
  Prioridad prioridad;
  DateTime? fechaLimite; // solo la fecha (sin hora)
  bool completada;
  final DateTime creada;

  /// Vencida = tiene fecha límite anterior a hoy y no está completada.
  bool get vencida {
    if (fechaLimite == null || completada) return false;
    final hoy = soloFecha(DateTime.now());
    return fechaLimite!.isBefore(hoy);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'nota': nota,
        'prioridad': prioridad.name,
        'fechaLimite': fechaLimite?.toIso8601String(),
        'completada': completada,
        'creada': creada.toIso8601String(),
      };

  factory Tarea.fromJson(Map<String, dynamic> j) => Tarea(
        id: j['id'] as int,
        titulo: j['titulo'] as String,
        nota: (j['nota'] ?? '') as String,
        prioridad: Prioridad.values.byName(j['prioridad'] as String),
        fechaLimite: j['fechaLimite'] == null ? null : DateTime.parse(j['fechaLimite'] as String),
        completada: j['completada'] as bool,
        creada: DateTime.parse(j['creada'] as String),
      );
}

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// "Hoy", "Mañana", "Ayer" o "24 nov 2026".
String fechaCorta(DateTime f) {
  final dias = soloFecha(f).difference(soloFecha(DateTime.now())).inDays;
  if (dias == 0) return 'Hoy';
  if (dias == 1) return 'Mañana';
  if (dias == -1) return 'Ayer';
  return '${f.day} ${_meses[f.month - 1]} ${f.year}';
}

// ---------- Orden y filtro (funciones puras, fáciles de probar) ----------
enum Orden { fecha, prioridad, creacion }

enum Filtro { todas, pendientes, completadas, vencidas }

extension OrdenTexto on Orden {
  String get texto => switch (this) {
        Orden.fecha => 'Fecha límite',
        Orden.prioridad => 'Prioridad',
        Orden.creacion => 'Más recientes',
      };
}

extension FiltroTexto on Filtro {
  String get texto => switch (this) {
        Filtro.todas => 'Todas',
        Filtro.pendientes => 'Pendientes',
        Filtro.completadas => 'Completadas',
        Filtro.vencidas => 'Vencidas',
      };
}

List<Tarea> ordenarYFiltrar(List<Tarea> tareas, Orden orden, Filtro filtro) {
  final lista = tareas.where((t) => switch (filtro) {
        Filtro.todas => true,
        Filtro.pendientes => !t.completada,
        Filtro.completadas => t.completada,
        Filtro.vencidas => t.vencida,
      }).toList();

  int porFecha(Tarea a, Tarea b) {
    if (a.fechaLimite == null && b.fechaLimite == null) return 0;
    if (a.fechaLimite == null) return 1; // sin fecha al final
    if (b.fechaLimite == null) return -1;
    return a.fechaLimite!.compareTo(b.fechaLimite!);
  }

  lista.sort((a, b) {
    // Las completadas siempre van al final.
    if (a.completada != b.completada) return a.completada ? 1 : -1;
    return switch (orden) {
      Orden.fecha => porFecha(a, b),
      Orden.prioridad => a.prioridad.index.compareTo(b.prioridad.index),
      Orden.creacion => b.creada.compareTo(a.creada),
    };
  });
  return lista;
}
