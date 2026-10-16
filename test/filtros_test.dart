import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/main.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

String _caso(String id, String titulo, String estado, String prioridad) =>
    '{"id":"$id","titulo":"$titulo","descripcion":"Detalle de $titulo",'
    '"cliente":"Cliente","categoria":"Redes","estado":"$estado",'
    '"prioridad":"$prioridad","fecha":"2026-10-15"}';

final _datos = '['
    '${_caso('1', 'WiFi intermitente', 'Pendiente', 'Alta')},'
    '${_caso('2', 'WiFi en bodega', 'Pendiente', 'Baja')},'
    '${_caso('3', 'WiFi en sala', 'Resuelta', 'Alta')},'
    '${_caso('4', 'Impresora sin tinta', 'Pendiente', 'Alta')},'
    '${_caso('5', 'Correo lento', 'En proceso', 'Media')},'
    '${_caso('6', 'Teclado dañado', 'Resuelta', 'Baja')}'
    ']';

Future<void> _sembrar() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({
    'nexasoft_incidencias_v1': _datos,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GestorIncidencias.filtrar', () {
    late GestorIncidencias gestor;

    setUp(() async {
      await _sembrar();
      gestor = GestorIncidencias();
      await gestor.iniciar();
    });

    List<String> ids(List l) => l.map((x) => x.id as String).toList();

    test('sin condiciones devuelve todos los registros', () {
      expect(gestor.filtrar().length, 6);
    });

    test('FEAT-002: filtra solo por estado', () {
      expect(ids(gestor.filtrar(estado: 'Pendiente')), ['1', '2', '4']);
      expect(ids(gestor.filtrar(estado: 'En proceso')), ['5']);
    });

    test('FEAT-002: filtra solo por prioridad', () {
      expect(ids(gestor.filtrar(prioridad: 'Alta')), ['1', '3', '4']);
      expect(ids(gestor.filtrar(prioridad: 'Baja')), ['2', '6']);
    });

    test('FEAT-002: texto, estado y prioridad se aplican juntos', () {
      final r = gestor.filtrar(
          texto: 'wifi', estado: 'Pendiente', prioridad: 'Alta');
      expect(ids(r), ['1']);
    });

    test('FEAT-002: una combinación sin coincidencias devuelve vacío', () {
      expect(
          gestor.filtrar(estado: 'En proceso', prioridad: 'Alta'), isEmpty);
    });

    test('FEAT-002: volver a Todos/Todas y texto vacío muestra todo', () {
      final r = gestor.filtrar(
          texto: '  ',
          estado: filtroTodosEstados,
          prioridad: filtroTodasPrioridades);
      expect(r.length, 6);
    });
  });

  group('Pantalla principal', () {
    Future<void> abrir(WidgetTester t) async {
      t.view.physicalSize = const Size(900, 2400);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await _sembrar();
      await t.pumpWidget(const NexaSoftApp());
      await t.pumpAndSettle();
    }

    Future<void> elegir(WidgetTester t, String etiqueta, String opcion) async {
      await t.tap(find.descendant(
          of: find.ancestor(
              of: find.text(etiqueta), matching: find.byType(InputDecorator)),
          matching: find.byType(DropdownButton<String>)));
      await t.pumpAndSettle();
      await t.tap(find.text(opcion).last);
      await t.pumpAndSettle();
    }

    testWidgets('FEAT-002: buscar, filtrar por Pendiente y Alta, y limpiar',
        (t) async {
      await abrir(t);
      expect(find.text('6 registros'), findsOneWidget);

      await t.enterText(find.byType(TextField), 'wifi');
      await t.pumpAndSettle();
      expect(find.text('3 registros'), findsOneWidget);

      await elegir(t, 'Estado', 'Pendiente');
      await elegir(t, 'Prioridad', 'Alta');
      expect(find.text('1 registros'), findsOneWidget);
      expect(find.text('WiFi intermitente'), findsOneWidget);
      expect(find.text('WiFi en bodega'), findsNothing);

      await t.tap(find.text('Restablecer filtros'));
      await t.pumpAndSettle();
      expect(find.text('6 registros'), findsOneWidget);
      expect(
          t.widget<TextField>(find.byType(TextField)).controller!.text, '');
    });

    testWidgets('FEAT-002: con cero resultados muestra un mensaje claro',
        (t) async {
      await abrir(t);
      await elegir(t, 'Estado', 'En proceso');
      await elegir(t, 'Prioridad', 'Alta');

      expect(find.text('0 registros'), findsOneWidget);
      expect(find.textContaining('No hay incidencias que coincidan'),
          findsOneWidget);

      await t.tap(find.text('Restablecer filtros').last);
      await t.pumpAndSettle();
      expect(find.text('6 registros'), findsOneWidget);
    });

    testWidgets('FEAT-002: el botón de restablecer está inactivo sin filtros',
        (t) async {
      await abrir(t);
      final boton = t.widget<TextButton>(
          find.widgetWithText(TextButton, 'Restablecer filtros'));
      expect(boton.onPressed, isNull);
    });
  });
}
