import '../data/almacen_local.dart';
import '../model/incidencia.dart';

const filtroTodosEstados = 'Todos';
const filtroTodasPrioridades = 'Todas';
const estadosValidos = ['Pendiente', 'En proceso', 'Resuelta'];

class GestorIncidencias {
  final AlmacenLocal datos = AlmacenLocal();
  List<Incidencia> incidencias = [];

  Future<void> iniciar() async {
    incidencias = await datos.leer();
  }

  List<Incidencia> buscar(String texto) {
    if (texto.trim().isEmpty) return incidencias;
    final termino = texto.trim().toLowerCase();
    return incidencias
        .where((x) =>
            x.titulo.toLowerCase().contains(termino) ||
            x.descripcion.toLowerCase().contains(termino))
        .toList();
  }

  /// Aplica juntas todas las condiciones activas: texto, estado y prioridad.
  List<Incidencia> filtrar({
    String texto = '',
    String estado = filtroTodosEstados,
    String prioridad = filtroTodasPrioridades,
  }) {
    return buscar(texto)
        .where((x) =>
            (estado == filtroTodosEstados || x.estado == estado) &&
            (prioridad == filtroTodasPrioridades || x.prioridad == prioridad))
        .toList();
  }

  Incidencia? porId(String id) {
    for (var x in incidencias) {
      if (x.id == id) return x;
    }
    return null;
  }

  int contar(String estado) {
    return incidencias.where((x) => x.estado == estado).length;
  }

  Future<void> cambiarEstado(String id, String estado) async {
    for (var i = 0; i < incidencias.length; i++) {
      if (incidencias[i].id == id) {
        incidencias[i].estado = estado;
        break;
      }
    }
    await datos.guardar(incidencias);
  }

  Future<void> cambiarPrioridad(String id, String prioridad) async {
    if (!prioridadesValidas.contains(prioridad)) {
      throw ArgumentError.value(prioridad, 'prioridad', 'Prioridad no válida');
    }
    for (var i = 0; i < incidencias.length; i++) {
      if (incidencias[i].id == id) {
        incidencias[i].prioridad = prioridad;
        break;
      }
    }
    await datos.guardar(incidencias);
  }

  Future<void> crear(String titulo, String descripcion, String cliente,
      String categoria,
      [String prioridad = prioridadPorDefecto]) async {
    if (!prioridadesValidas.contains(prioridad)) {
      throw ArgumentError.value(prioridad, 'prioridad', 'Prioridad no válida');
    }
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      prioridad: prioridad,
      fecha: DateTime.now().toIso8601String().split('T').first,
    );
    incidencias.insert(0, nuevo);
    await datos.guardar(incidencias);
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}
