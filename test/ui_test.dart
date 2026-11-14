import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enfoque/app.dart';
import 'package:enfoque/core/preferences.dart';
import 'package:enfoque/core/theme.dart';
import 'package:enfoque/domain/task.dart';
import 'package:enfoque/features/auth/auth_screen.dart';
import 'package:enfoque/features/dashboard/dashboard_screen.dart';
import 'package:enfoque/features/dashboard/calendar_screen.dart';
import 'package:enfoque/features/dashboard/stats_screen.dart';
import 'package:enfoque/features/settings/settings_screen.dart';
import 'package:enfoque/features/tasks/task_controller.dart';
import 'package:enfoque/features/tasks/task_editor.dart';
import 'package:enfoque/features/tasks/tasks_screen.dart';
import 'package:enfoque/features/tasks/categories_screen.dart';

import 'support.dart';

class TestUser extends Fake implements User {
  @override
  String get uid => 'test';
  @override
  String? get displayName => 'Andrea';
  @override
  String? get email => 'andrea@example.test';
}

class TestAuth extends Fake implements FirebaseAuth {
  String? submittedEmail;
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    submittedEmail = email;
    throw FirebaseAuthException(code: 'invalid-credential');
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    submittedEmail = email;
  }
}

Widget host(Widget child, {bool dark = false, double scale = 1}) => MaterialApp(
  locale: const Locale('es', 'PE'),
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: const [Locale('es', 'PE')],
  theme: buildTheme(dark, 0),
  debugShowCheckedModeBanner: false,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: SafeArea(child: child)),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('acceso valida campos y muestra errores de credenciales', (
    tester,
  ) async {
    final auth = TestAuth();
    await tester.pumpWidget(host(AuthScreen(auth: auth)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un correo válido.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'andrea@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrecta');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(auth.submittedEmail, 'andrea@example.test');
    expect(find.text('Revisa tu correo y contraseña.'), findsOneWidget);
  });
  testWidgets('formulario bloquea título vacío y crea tarea válida', (
    tester,
  ) async {
    final repo = MemoryRepository();
    final c = TaskController(repo, RecordingReminders())..start();
    await tester.pumpWidget(host(TaskEditor(controller: c)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Guardar tarea'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Guardar tarea'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextFormField).first,
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Escribe un título.'), findsOneWidget);
    expect(repo.tasks, isEmpty);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Preparar exposición',
    );
    await tester.scrollUntilVisible(
      find.text('Guardar tarea'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Guardar tarea'));
    await tester.pumpAndSettle();
    expect(repo.tasks.single.title, 'Preparar exposición');
    c.dispose();
    await repo.dispose();
  });
  test('preferencias sobreviven a una nueva instancia', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferences.getInstance();
    final first = Preferences(store);
    await first.update(dark: true, accent: 2, notifications: true);
    final next = Preferences(store);
    expect(next.dark, true);
    expect(next.accent, 2);
    expect(next.notifications, true);
    first.dispose();
    next.dispose();
  });
  testWidgets('tema cambia en la aplicación y falta de Firebase es explícita', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final p = Preferences(await SharedPreferences.getInstance());
    await tester.pumpWidget(EnfoqueApp(preferences: p, configured: false));
    await tester.pumpAndSettle();
    expect(find.text('Conecta tu espacio.'), findsOneWidget);
    await p.update(dark: true);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('enfoque'))).brightness,
      Brightness.dark,
    );
    await tester.pumpWidget(const SizedBox());
    p.dispose();
  });
  testWidgets('auditoría: pantallas a 360 px con 50 tareas y texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final p = Preferences(await SharedPreferences.getInstance());
    final repo = MemoryRepository();
    final c = TaskController(repo, RecordingReminders());
    c.loading = false;
    c.categories = repo.categories;
    c.tasks = List.generate(
      50,
      (i) => Task(
        id: '$i',
        title: 'Preparar exposición del proyecto académico $i',
        categoryId: 'estudios',
        dueAt: DateTime.now().add(Duration(days: i % 5)),
        completed: i % 4 == 0,
      ),
    );
    final screens = <Widget>[
      DashboardScreen(controller: c, name: 'Andrea'),
      TasksScreen(controller: c),
      CalendarScreen(controller: c),
      StatsScreen(controller: c),
      SettingsScreen(
        preferences: p,
        controller: c,
        user: TestUser(),
        onSignOut: () async {},
      ),
      CategoriesScreen(controller: c),
      TaskEditor(controller: c),
      AuthScreen(auth: TestAuth()),
    ];
    for (final dark in [false, true]) {
      for (final screen in screens) {
        await tester.pumpWidget(host(screen, dark: dark, scale: 1.3));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType}, dark=$dark',
        );
        await tester.pumpWidget(const SizedBox());
      }
    }
    p.dispose();
    c.dispose();
    await repo.dispose();
  });
  testWidgets('exporta referencias renderizadas de widgets para Figma', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final p = Preferences(await SharedPreferences.getInstance());
    final repo = MemoryRepository();
    final c = TaskController(repo, RecordingReminders());
    c.loading = false;
    c.categories = repo.categories;
    final now = DateTime.now();
    c.tasks = [
      Task(
        id: '1',
        title: 'Terminar la exposición',
        categoryId: 'estudios',
        dueAt: DateTime(now.year, now.month, now.day, 18),
        priority: 2,
      ),
      Task(
        id: '2',
        title: 'Comprar materiales',
        dueAt: DateTime(now.year, now.month, now.day, 20),
      ),
      Task(
        id: '3',
        title: 'Preparar la reunión del equipo',
        dueAt: DateTime(now.year, now.month, now.day + 1, 9),
      ),
      const Task(id: '4', title: 'Revisar apuntes', completed: true),
    ];
    final screens = <String, Widget>{
      'bienvenida': AuthScreen(auth: TestAuth()),
      'inicio': DashboardScreen(controller: c, name: 'Andrea'),
      'inicio-oscuro': DashboardScreen(controller: c, name: 'Andrea'),
      'tareas': TasksScreen(controller: c),
      'crear': TaskEditor(controller: c),
      'calendario': CalendarScreen(controller: c),
      'estadisticas': StatsScreen(controller: c),
      'categorias': CategoriesScreen(controller: c),
      'configuracion': SettingsScreen(
        preferences: p,
        controller: c,
        user: TestUser(),
        onSignOut: () async {},
      ),
    };
    for (final entry in screens.entries) {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: host(entry.value, dark: entry.key.endsWith('oscuro')),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/prototipo/${entry.key}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    p.dispose();
    c.dispose();
    await repo.dispose();
  });
}
