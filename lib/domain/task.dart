import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskFilter { all, today, upcoming, completed, overdue }

enum TaskSort { date, priority, title }

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.categoryId,
    this.dueAt,
    this.priority = 1,
    this.completed = false,
    this.reminder = false,
    this.createdAt,
    this.updatedAt,
  });
  final String id, title, description;
  final String? categoryId;
  final DateTime? dueAt, createdAt, updatedAt;
  final int priority;
  final bool completed, reminder;

  factory Task.fromMap(String id, Map<String, dynamic> data) => Task(
    id: id,
    title: data['title'] as String,
    description: data['description'] as String? ?? '',
    categoryId: data['categoryId'] as String?,
    dueAt: (data['dueAt'] as Timestamp?)?.toDate(),
    priority: data['priority'] as int? ?? 1,
    completed: data['completed'] as bool? ?? false,
    reminder: data['reminder'] as bool? ?? false,
    createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'title': title.trim(),
    'description': description.trim(),
    'categoryId': categoryId,
    'dueAt': dueAt == null ? null : Timestamp.fromDate(dueAt!),
    'priority': priority,
    'completed': completed,
    'reminder': reminder,
    'updatedAt': FieldValue.serverTimestamp(),
  };
  Task copyWith({bool? completed, bool? reminder}) => Task(
    id: id,
    title: title,
    description: description,
    categoryId: categoryId,
    dueAt: dueAt,
    priority: priority,
    completed: completed ?? this.completed,
    reminder: reminder ?? this.reminder,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
  bool isOverdue(DateTime now) =>
      !completed && dueAt != null && dueAt!.isBefore(now);
}

class TaskCategory {
  const TaskCategory(this.id, this.name, {this.archived = false});
  final String id, name;
  final bool archived;
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<Task> selectTasks(
  Iterable<Task> tasks, {
  TaskFilter filter = TaskFilter.all,
  TaskSort sort = TaskSort.date,
  String query = '',
  String? categoryId,
  DateTime? now,
}) {
  final date = now ?? DateTime.now();
  final tomorrow = DateTime(date.year, date.month, date.day + 1);
  final result = tasks.where((t) {
    if (categoryId != null && t.categoryId != categoryId) return false;
    if (!('${t.title} ${t.description}'.toLowerCase().contains(
      query.trim().toLowerCase(),
    ))) {
      return false;
    }
    return switch (filter) {
      TaskFilter.all => true,
      TaskFilter.today =>
        t.dueAt != null && sameDay(t.dueAt!, date) && !t.completed,
      TaskFilter.upcoming =>
        !t.completed && t.dueAt != null && !t.dueAt!.isBefore(tomorrow),
      TaskFilter.completed => t.completed,
      TaskFilter.overdue => t.isOverdue(date),
    };
  }).toList();
  result.sort((a, b) {
    final primary = switch (sort) {
      TaskSort.priority => b.priority.compareTo(a.priority),
      TaskSort.title => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      TaskSort.date => (a.dueAt ?? DateTime(9999)).compareTo(
        b.dueAt ?? DateTime(9999),
      ),
    };
    return primary != 0 ? primary : a.id.compareTo(b.id);
  });
  return result;
}

String? validateTitle(String? value) {
  if (value == null || value.trim().isEmpty) return 'Escribe un título.';
  if (value.trim().length > 120) return 'Usa hasta 120 caracteres.';
  return null;
}

String? validateEmail(String? value) =>
    value == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
    ? 'Escribe un correo válido.'
    : null;
String? validatePassword(String? value) =>
    value == null || value.length < 8 ? 'Usa al menos 8 caracteres.' : null;

class TaskStats {
  TaskStats(Iterable<Task> tasks, DateTime now) {
    total = tasks.length;
    completed = tasks.where((t) => t.completed).length;
    overdue = tasks.where((t) => t.isOverdue(now)).length;
  }
  late final int total, completed, overdue;
  int get pending => total - completed;
  double get ratio => total == 0 ? 0 : completed / total;
}
