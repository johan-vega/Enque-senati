import 'package:flutter_test/flutter_test.dart';
import 'package:enfoque/domain/task.dart';
import 'package:enfoque/features/tasks/task_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'support.dart';

Future<void> flush() => Future<void>.delayed(const Duration(milliseconds: 20));
void main() {
  late MemoryRepository repo;
  late RecordingReminders reminders;
  late TaskController controller;
  setUp(() {
    repo = MemoryRepository();
    reminders = RecordingReminders();
    controller = TaskController(repo, reminders)..start();
  });
  tearDown(() async {
    controller.dispose();
    await repo.dispose();
  });
  test('CRUD, cambios de estado y cancelación de recordatorios', () async {
    controller.setNotifications(true);
    expect(
      await controller.run(
        () => repo.save(
          Task(
            id: '',
            title: 'Exposición',
            reminder: true,
            dueAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        ),
      ),
      true,
    );
    await flush();
    expect(controller.tasks, hasLength(1));
    expect(reminders.scheduled, hasLength(1));
    final id = controller.tasks.single.id;
    await controller.run(
      () => repo.save(
        Task(
          id: id,
          title: 'Exposición revisada',
          reminder: true,
          dueAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      ),
    );
    await flush();
    expect(controller.tasks.single.title, 'Exposición revisada');
    await controller.run(() => repo.setCompleted(id, true));
    await flush();
    expect(reminders.scheduled, isEmpty);
    await controller.run(() => repo.setCompleted(id, false));
    await flush();
    expect(reminders.scheduled, hasLength(1));
    await controller.run(() => repo.delete(id));
    await flush();
    expect(controller.tasks, isEmpty);
    expect(reminders.scheduled, isEmpty);
  });
  test('reporta errores de red sin declarar éxito', () async {
    repo.failure = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );
    expect(await controller.run(() => repo.delete('x')), false);
    expect(controller.error, contains('conexión'));
    repo.changes.addError(repo.failure!);
    await flush();
    expect(controller.loading, false);
    expect(controller.error, isNotNull);
  });
  test('fallo de notificaciones visible y limpieza al cerrar sesión', () async {
    reminders.fail = true;
    controller.setNotifications(true);
    await flush();
    expect(controller.reminderError, isNotNull);
    await controller.close();
    expect(reminders.cleared, true);
  });
}
