import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('BUG-001: el cambio de estado persiste al reiniciar la aplicación',
      () async {
    final gestor = GestorIncidencias();
    await gestor.iniciar();
    final incidencia =
        gestor.incidencias.firstWhere((x) => x.estado == 'Pendiente');

    await gestor.cambiarEstado(incidencia.id, 'Resuelta');

    // Simula cerrar y volver a abrir: un gestor nuevo lee del almacenamiento.
    final reabierto = GestorIncidencias();
    await reabierto.iniciar();
    expect(reabierto.porId(incidencia.id)!.estado, 'Resuelta');
  });
}
