import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Map<String, dynamic> registro([Map<String, dynamic> extra = const {}]) => {
        'id': 'INC-X',
        'titulo': 'Prueba',
        'descripcion': 'Caso',
        'cliente': 'Cliente',
        'categoria': 'Redes',
        'estado': 'Pendiente',
        'fecha': '2026-10-14',
        ...extra,
      };

  test('FEAT-001: una incidencia antigua sin prioridad usa Media', () {
    expect(Incidencia.desdeJson(registro()).prioridad, 'Media');
  });

  test('FEAT-001: un valor no aprobado en los datos se normaliza a Media', () {
    final r = Incidencia.desdeJson(registro({'prioridad': 'Urgente'}));
    expect(r.prioridad, 'Media');
  });

  test('FEAT-001: la prioridad se guarda en el JSON', () {
    final r = Incidencia.desdeJson(registro({'prioridad': 'Alta'}));
    expect(r.toJson()['prioridad'], 'Alta');
  });

  test('FEAT-001: los datos de ejemplo cargan con prioridad Media', () async {
    final gestor = GestorIncidencias();
    await gestor.iniciar();
    expect(gestor.incidencias, isNotEmpty);
    expect(gestor.incidencias.every((x) => x.prioridad == 'Media'), isTrue);
  });

  test('FEAT-001: crear con prioridad Alta y conservarla al reabrir', () async {
    final gestor = GestorIncidencias();
    await gestor.iniciar();
    await gestor.crear('Servidor caído', 'Sin respuesta', 'Cliente', 'Redes',
        'Alta');

    final reabierto = GestorIncidencias();
    await reabierto.iniciar();
    final nueva = reabierto.incidencias.firstWhere((x) => x.titulo == 'Servidor caído');
    expect(nueva.prioridad, 'Alta');
  });

  test('FEAT-001: sin elegir prioridad al crear se usa Media', () async {
    final gestor = GestorIncidencias();
    await gestor.iniciar();
    await gestor.crear('Sin elegir', 'Desc', 'Cliente', 'Software');
    expect(gestor.incidencias.first.prioridad, 'Media');
  });

  test('FEAT-001: cambiar la prioridad persiste tras reabrir', () async {
    final gestor = GestorIncidencias();
    await gestor.iniciar();
    final id = gestor.incidencias.first.id;
    await gestor.cambiarPrioridad(id, 'Baja');

    final reabierto = GestorIncidencias();
    await reabierto.iniciar();
    expect(reabierto.porId(id)!.prioridad, 'Baja');
  });

  test('FEAT-001: se rechazan valores distintos de Baja, Media o Alta',
      () async {
    final gestor = GestorIncidencias();
    await gestor.iniciar();
    final id = gestor.incidencias.first.id;
    expect(() => gestor.cambiarPrioridad(id, 'Urgente'), throwsArgumentError);
    expect(() => gestor.crear('T', 'D', 'C', 'Redes', 'alta'),
        throwsArgumentError);
    expect(gestor.porId(id)!.prioridad, 'Media');
  });

  test('FEAT-001: registros guardados antes de la función se abren con Media',
      () async {
    // Simula datos persistidos por la versión anterior (sin campo prioridad).
    final gestor = GestorIncidencias();
    await gestor.datos.prefs.setString('nexasoft_incidencias_v1',
        '[{"id":"INC-1","titulo":"Vieja","descripcion":"d","cliente":"c",'
        '"categoria":"Redes","estado":"Pendiente","fecha":"2026-09-01"}]');
    await gestor.iniciar();
    expect(gestor.incidencias.single.prioridad, 'Media');
  });
}
