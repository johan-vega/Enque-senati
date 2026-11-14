import 'package:flutter_test/flutter_test.dart';
import 'package:enfoque/domain/task.dart';
import 'package:enfoque/core/reminders.dart';
import 'package:enfoque/core/errors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('resuelve GMT del emulador Android y una zona IANA', () {
    tzdata.initializeTimeZones();
    expect(
      tz.TZDateTime(deviceLocation('GMT'), 2026).timeZoneOffset,
      Duration.zero,
    );
    expect(deviceLocation('America/Lima').name, 'America/Lima');
  });
  final now = DateTime(2026, 11, 14, 12);
  final tasks = [
    Task(
      id: '1',
      title: 'Exposición',
      categoryId: 'estudios',
      dueAt: DateTime(2026, 11, 14, 17),
      priority: 2,
    ),
    Task(
      id: '2',
      title: 'Pagar servicio',
      dueAt: DateTime(2026, 11, 13),
      priority: 0,
    ),
    Task(id: '3', title: 'Reunión', dueAt: DateTime(2026, 11, 15)),
    Task(
      id: '4',
      title: 'Comprar materiales',
      completed: true,
      dueAt: DateTime(2026, 11, 14),
    ),
    const Task(id: '5', title: 'Leer apuntes'),
  ];
  test('valida título, correo y contraseña', () {
    expect(validateTitle('  '), isNotNull);
    expect(validateTitle('a' * 121), isNotNull);
    expect(validateTitle('Entregar proyecto'), isNull);
    expect(validateEmail('alumno@senati.pe'), isNull);
    expect(validateEmail('correo'), isNotNull);
    expect(validatePassword('1234567'), isNotNull);
    expect(validatePassword('Proyecto123!'), isNull);
  });
  test('filtros distinguen hoy, próximas, completadas y vencidas', () {
    expect(
      selectTasks(tasks, filter: TaskFilter.today, now: now).map((t) => t.id),
      ['1'],
    );
    expect(
      selectTasks(
        tasks,
        filter: TaskFilter.upcoming,
        now: now,
      ).map((t) => t.id),
      ['3'],
    );
    expect(
      selectTasks(
        tasks,
        filter: TaskFilter.completed,
        now: now,
      ).map((t) => t.id),
      ['4'],
    );
    expect(
      selectTasks(tasks, filter: TaskFilter.overdue, now: now).map((t) => t.id),
      ['2'],
    );
    expect(selectTasks(tasks, now: now), hasLength(5));
  });
  test('combina búsqueda, categoría y orden de prioridad', () {
    expect(
      selectTasks(tasks, query: 'EXPO', categoryId: 'estudios').single.id,
      '1',
    );
    expect(selectTasks(tasks, sort: TaskSort.priority).first.id, '1');
    expect(selectTasks(tasks, sort: TaskSort.date).last.id, '5');
  });
  test('estadísticas se derivan de datos y evitan división por cero', () {
    final s = TaskStats(tasks, now);
    expect([s.total, s.completed, s.pending, s.overdue], [5, 1, 4, 1]);
    expect(s.ratio, .2);
    expect(TaskStats([], now).ratio, 0);
  });
  test(
    'recordatorios excluyen vencidas, completadas y desactivadas; límite 60',
    () {
      final future = List.generate(
        70,
        (i) => Task(
          id: '$i',
          title: 'Tarea $i',
          reminder: true,
          dueAt: now.add(Duration(minutes: i + 1)),
        ),
      );
      expect(reminderPlan(future, now, true), hasLength(60));
      expect(reminderPlan(future, now, false), isEmpty);
      expect(
        reminderPlan(
          [
            future.first.copyWith(completed: true),
            const Task(id: 'x', title: 'Sin fecha', reminder: true),
          ],
          now,
          true,
        ),
        isEmpty,
      );
      expect(
        reminderPlan(future, now.add(const Duration(days: 1)), true),
        isEmpty,
      );
    },
  );
  test('errores de autenticación y conexión en español', () {
    expect(
      readableError(FirebaseAuthException(code: 'invalid-credential')),
      contains('correo'),
    );
    expect(
      readableError(FirebaseAuthException(code: 'network-request-failed')),
      contains('conexión'),
    );
  });
}
