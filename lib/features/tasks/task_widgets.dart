import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/task.dart';
import 'task_controller.dart';
import 'task_editor.dart';

class TaskList extends StatelessWidget {
  const TaskList({
    super.key,
    required this.tasks,
    required this.controller,
    this.empty = 'No hay tareas en esta vista.',
  });
  final List<Task> tasks;
  final TaskController controller;
  final String empty;
  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(empty, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Agrega una tarea o prueba con otro filtro.'),
          ],
        ),
      );
    }
    return Column(
      children: tasks
          .map((task) => TaskRow(task: task, controller: controller))
          .toList(),
    );
  }
}

class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task, required this.controller});
  final Task task;
  final TaskController controller;
  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Eliminar esta tarea?'),
        content: Text(
          '“${task.title}” se eliminará de tus dispositivos. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.run(() => controller.repository.delete(task.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = controller.categories
        .where((c) => c.id == task.categoryId)
        .firstOrNull;
    final metadata = [
      if (category != null)
        '${category.name}${category.archived ? ' · archivada' : ''}',
      if (task.dueAt != null)
        DateFormat('d MMM · HH:mm', 'es').format(task.dueAt!),
      if (task.priority == 2) 'Prioridad alta',
      if (task.reminder) 'Recordatorio',
    ].join('  ·  ');
    return Column(
      children: [
        InkWell(
          onTap: () => openTaskEditor(context, controller, task: task),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Checkbox(
                    value: task.completed,
                    semanticLabel: 'Completar ${task.title}',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (v) => controller.run(
                      () => controller.repository.setCompleted(task.id, v!),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 160),
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(
                                color: task.completed
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                          child: Text(task.title),
                        ),
                        if (metadata.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            metadata,
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  color: task.isOverdue(DateTime.now())
                                      ? scheme.error
                                      : scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opciones de tarea',
                  onSelected: (v) {
                    if (v == 'edit') {
                      openTaskEditor(context, controller, task: task);
                    } else {
                      _delete(context);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (trailing != null)
          Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
