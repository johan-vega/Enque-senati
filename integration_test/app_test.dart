import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enfoque/main.dart' as app;
import 'package:enfoque/core/bootstrap.dart';
import 'package:enfoque/core/reminders.dart';
import 'package:enfoque/data/task_repository.dart';
import 'package:enfoque/domain/task.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: acceso, CRUD sincronizado y programación nativa', (
    tester,
  ) async {
    expect(
      useEmulators,
      true,
      reason: 'Esta prueba solo debe ejecutarse contra emuladores.',
    );
    await app.main();
    final auth = FirebaseAuth.instance;
    await auth.signOut();
    Future<void> until(bool Function() condition) async {
      for (var i = 0; i < 120; i++) {
        await tester
            .pump(const Duration(milliseconds: 250))
            .timeout(const Duration(seconds: 15));
        if (condition()) return;
      }
      fail('La condición no se cumplió.');
    }

    await until(() => find.text('Entrar').evaluate().isNotEmpty);
    final email =
        'android-${DateTime.now().millisecondsSinceEpoch}@enfoque.test';
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: 'Proyecto123!',
    );
    await credential.user!.updateDisplayName('Andrea');
    await until(() => find.text('Tu día, con calma.').evaluate().isNotEmpty);
    final repo = FirestoreTaskRepository(
      FirebaseFirestore.instance,
      credential.user!.uid,
    );
    await repo.ensureDefaults();
    await repo.save(
      Task(
        id: '',
        title: 'Entregar proyecto SENATI',
        categoryId: 'estudios',
        dueAt: DateTime.now().add(const Duration(hours: 1)),
        reminder: true,
        priority: 2,
      ),
    );
    await until(
      () => find.text('Entregar proyecto SENATI').evaluate().isNotEmpty,
    );
    final task = (await repo.watchTasks().firstWhere(
      (s) => s.tasks.isNotEmpty && !s.pending,
    )).tasks.single;

    final secondary = await Firebase.initializeApp(
      name: 'sesion-B',
      options: Firebase.app().options,
    );
    final authB = FirebaseAuth.instanceFor(app: secondary);
    await authB.useAuthEmulator(emulatorHost, 9099);
    final dbB = FirebaseFirestore.instanceFor(app: secondary);
    dbB.useFirestoreEmulator(emulatorHost, 8080);
    await authB.signInWithEmailAndPassword(
      email: email,
      password: 'Proyecto123!',
    );
    final repoB = FirestoreTaskRepository(dbB, credential.user!.uid);
    expect(
      (await repoB.watchTasks().firstWhere((s) => s.tasks.isNotEmpty))
          .tasks
          .single
          .id,
      task.id,
    );
    await repoB.save(
      Task(
        id: task.id,
        title: 'Proyecto revisado desde B',
        categoryId: 'estudios',
        dueAt: task.dueAt,
        priority: 2,
        reminder: true,
        createdAt: task.createdAt,
      ),
    );
    await until(
      () => find.text('Proyecto revisado desde B').evaluate().isNotEmpty,
    );
    await repoB.setCompleted(task.id, true);
    await until(
      () => find.text('Hoy tienes 0 tareas pendientes').evaluate().isNotEmpty,
    );
    await repoB.setCompleted(task.id, false);
    await until(
      () => find.text('Proyecto revisado desde B').evaluate().isNotEmpty,
    );

    // Real native plugin calls. Pending requests prove scheduling, not delivery.
    final reminders = LocalReminders();
    await reminders.reconcile([task], true);
    expect(await reminders.plugin.pendingNotificationRequests(), hasLength(1));
    await reminders.reconcile([task.copyWith(completed: true)], true);
    expect(await reminders.plugin.pendingNotificationRequests(), isEmpty);
    await reminders.reconcile([task], true);
    await reminders.reconcile([], true);
    expect(await reminders.plugin.pendingNotificationRequests(), isEmpty);

    await repoB.delete(task.id);
    await until(() => find.text('Sin tareas para hoy').evaluate().isNotEmpty);
    debugPrint(
      'INTEGRACION: CRUD y programación nativa aprobados; cerrando sesión A',
    );
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Cerrar sesión'));
    debugPrint('INTEGRACION: sesión cerrada; esperando acceso');
    await until(() => find.text('Entrar').evaluate().isNotEmpty);
    debugPrint(
      'INTEGRACION: pantalla de acceso visible; iniciando sesión de nuevo',
    );
    await auth.signInWithEmailAndPassword(
      email: email,
      password: 'Proyecto123!',
    );
    await until(() => find.text('Tu día, con calma.').evaluate().isNotEmpty);
    await reminders.clear();
    await authB.signOut();
    await repo.save(
      Task(
        id: '',
        title: 'Revisar la entrega final',
        categoryId: 'estudios',
        dueAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    await until(
      () => find.text('Revisar la entrega final').evaluate().isNotEmpty,
    );
    // Screenshot bytes are returned to the host through the integration driver.
    // Convert the surface only after the interactive checks have finished.
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('android-inicio');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
