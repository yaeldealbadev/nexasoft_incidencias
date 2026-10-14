import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Incidencia _caso(String id, String estado) => Incidencia(
      id: id,
      titulo: 'Caso $id',
      descripcion: 'Descripción',
      cliente: 'Cliente',
      categoria: 'Redes',
      estado: estado,
      fecha: '2026-10-12',
    );

void main() {
  late GestorIncidencias gestor;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    gestor = GestorIncidencias()
      ..incidencias = [
        _caso('1', 'Pendiente'),
        _caso('2', 'Pendiente'),
        _caso('3', 'En proceso'),
      ];
  });

  int pendientesEnLista() =>
      gestor.incidencias.where((x) => x.estado == 'Pendiente').length;

  test('BUG-003: el contador baja al sacar una incidencia de Pendiente',
      () async {
    await gestor.cambiarEstado('1', 'Resuelta');
    expect(gestor.contar('Pendiente'), 1);
    expect(gestor.contar('Pendiente'), pendientesEnLista());
  });

  test('BUG-003: el contador sube al regresar una incidencia a Pendiente',
      () async {
    await gestor.cambiarEstado('3', 'Pendiente');
    expect(gestor.contar('Pendiente'), 3);
    expect(gestor.contar('Pendiente'), pendientesEnLista());
  });

  test('BUG-003: crear una incidencia incrementa pendientes una sola vez',
      () async {
    await gestor.crear('Nueva', 'Desc', 'Cliente', 'Redes');
    expect(gestor.contar('Pendiente'), 3);
    expect(gestor.contar('Pendiente'), pendientesEnLista());
  });
}
