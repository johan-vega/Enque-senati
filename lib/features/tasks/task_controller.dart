import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors.dart';
import '../../core/reminders.dart';
import '../../data/task_repository.dart';
import '../../domain/task.dart';

class TaskController extends ChangeNotifier {
  TaskController(this.repository, this.reminders);
  final TaskRepository repository;
  final ReminderService reminders;
  List<Task> tasks = [];
  List<TaskCategory> categories = [];
  bool loading = true, fromCache = false, pending = false;
  String? error, reminderError;
  bool _enabled = false, _disposed = false;
  StreamSubscription<TaskSnapshot>? _tasksSub;
  StreamSubscription<List<TaskCategory>>? _categoriesSub;
  Future<void> _reminderQueue = Future.value();
  void start() {
    _tasksSub = repository.watchTasks().listen(
      (snapshot) {
        tasks = snapshot.tasks;
        fromCache = snapshot.fromCache;
        pending = snapshot.pending;
        loading = false;
        error = null;
        refreshReminders();
        notifyListeners();
      },
      onError: (Object e) {
        loading = false;
        error = readableError(e);
        notifyListeners();
      },
    );
    _categoriesSub = repository.watchCategories().listen(
      (value) {
        categories = value;
        notifyListeners();
      },
      onError: (Object e) {
        error = readableError(e);
        notifyListeners();
      },
    );
  }

  void setNotifications(bool enabled) {
    if (_enabled != enabled) {
      _enabled = enabled;
      refreshReminders();
    }
  }

  Future<void> retry() async {
    await _tasksSub?.cancel();
    await _categoriesSub?.cancel();
    if (_disposed) return;
    loading = true;
    error = null;
    notifyListeners();
    start();
    refreshReminders();
  }

  void refreshReminders() {
    _reminderQueue = _reminderQueue.then((_) async {
      if (_disposed) return;
      try {
        await reminders.reconcile(tasks, _enabled);
        reminderError = null;
      } catch (_) {
        reminderError =
            'No se pudieron programar los recordatorios. Revisa los permisos.';
      }
      if (!_disposed) notifyListeners();
    });
  }

  Future<bool> run(Future<void> Function() action) async {
    try {
      await action();
      error = null;
      return true;
    } catch (e) {
      error = readableError(e);
      return false;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> close() async {
    _disposed = true;
    await _tasksSub?.cancel();
    await _categoriesSub?.cancel();
    await _reminderQueue;
    await reminders.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_tasksSub?.cancel());
    unawaited(_categoriesSub?.cancel());
    super.dispose();
  }
}
