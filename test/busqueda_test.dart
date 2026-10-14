import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';

Incidencia _caso(String id, String titulo, String descripcion) => Incidencia(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      cliente: 'Cliente',
      categoria: 'Redes',
      estado: 'Pendiente',
      fecha: '2026-10-12',
    );

void main() {
  final gestor = GestorIncidencias()
    ..incidencias = [
      _caso('1', 'WiFi intermitente en recepción', 'Se corta cada hora'),
      _caso('2', 'Impresora sin tinta', 'Requiere cartucho nuevo'),
    ];

  test('BUG-002: la búsqueda ignora mayúsculas y minúsculas', () {
    final r = gestor.buscar('wifi');
    expect(r.map((x) => x.id), ['1']);
  });

  test('BUG-002: la búsqueda encuentra palabras solo de la descripción', () {
    final r = gestor.buscar('cartucho');
    expect(r.map((x) => x.id), ['2']);
  });

  test('búsqueda vacía devuelve todas', () {
    expect(gestor.buscar('  ').length, 2);
  });
}
