import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/task.dart';
import '../tasks/task_controller.dart';
import '../tasks/task_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.name,
  });
  final TaskController controller;
  final String name;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = selectTasks(
      controller.tasks,
      filter: TaskFilter.today,
      now: now,
    );
    final next = selectTasks(
      controller.tasks,
      filter: TaskFilter.upcoming,
      now: now,
    );
    final overdue = selectTasks(
      controller.tasks,
      filter: TaskFilter.overdue,
      now: now,
    );
    final stats = TaskStats(controller.tasks, now);
    final greeting = now.hour < 12
        ? 'Buenos días'
        : now.hour < 19
        ? 'Buenas tardes'
        : 'Buenas noches';
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      children: [
        Text(
          '$greeting${name.isEmpty ? '' : ', ${name.split(' ').first}'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        Text(
          'Tu día, con calma.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(DateFormat('EEEE d \'de\' MMMM', 'es').format(now)),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: .55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoy tienes ${today.length} ${today.length == 1 ? 'tarea pendiente' : 'tareas pendientes'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: stats.ratio,
                borderRadius: BorderRadius.circular(4),
                minHeight: 5,
              ),
              const SizedBox(height: 10),
              Text(
                  'Completadas: ${stats.completed} · Pendientes: ${stats.pending}',
              ),
            ],
          ),
        ),
        SectionHeading('Para hoy', trailing: '${today.length}'),
        TaskList(
          tasks: today,
          controller: controller,
          empty: 'Sin tareas para hoy',
        ),
        if (overdue.isNotEmpty) ...[
          SectionHeading('Por retomar', trailing: '${overdue.length} vencidas'),
          TaskList(tasks: overdue.take(3).toList(), controller: controller),
        ],
        SectionHeading('En los próximos días', trailing: '${next.length}'),
        TaskList(
          tasks: next.take(5).toList(),
          controller: controller,
          empty: 'Tu agenda está despejada',
        ),
      ],
    );
  }
}
