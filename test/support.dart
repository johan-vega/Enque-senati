import 'dart:async';

import 'package:enfoque/core/reminders.dart';
import 'package:enfoque/data/task_repository.dart';
import 'package:enfoque/domain/task.dart';

// Test doubles only. The application always uses FirestoreTaskRepository.
class MemoryRepository implements TaskRepository {
  final changes = StreamController<TaskSnapshot>.broadcast();
  final categoryChanges = StreamController<List<TaskCategory>>.broadcast();
  final List<Task> tasks = [];
  final List<TaskCategory> categories = [
    const TaskCategory('estudios', 'Estudios'),
  ];
  Object? failure;
  int sequence = 0;
  void emit() => changes.add(TaskSnapshot(List.of(tasks)));
  void check() {
    if (failure != null) throw failure!;
  }

  @override
  Stream<TaskSnapshot> watchTasks() => changes.stream;
  @override
  Stream<List<TaskCategory>> watchCategories() => categoryChanges.stream;
  @override
  Future<void> save(Task t) async {
    check();
    if (t.id.isEmpty) {
      tasks.add(
        Task(
          id: '${++sequence}',
          title: t.title,
          description: t.description,
          categoryId: t.categoryId,
          dueAt: t.dueAt,
          priority: t.priority,
          completed: t.completed,
          reminder: t.reminder,
        ),
      );
    } else {
      tasks[tasks.indexWhere((e) => e.id == t.id)] = t;
    }
    emit();
  }

  @override
  Future<void> delete(String id) async {
    check();
    tasks.removeWhere((t) => t.id == id);
    emit();
  }

  @override
  Future<void> setCompleted(String id, bool value) async {
    check();
    final index = tasks.indexWhere((t) => t.id == id);
    tasks[index] = tasks[index].copyWith(completed: value);
    emit();
  }

  @override
  Future<void> saveCategory(
    String? id,
    String name, {
    bool restore = false,
  }) async {
    check();
  }

  @override
  Future<void> archiveCategory(String id) async {
    check();
  }

  Future<void> dispose() async {
    await changes.close();
    await categoryChanges.close();
  }
}

class RecordingReminders implements ReminderService {
  List<Task> scheduled = [];
  bool cleared = false, fail = false;
  @override
  bool get supported => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> reconcile(List<Task> tasks, bool enabled) async {
    if (fail) throw StateError('permission');
    scheduled = reminderPlan(tasks, DateTime.now(), enabled);
  }

  @override
  Future<void> clear() async {
    scheduled = [];
    cleared = true;
  }
}
