import 'package:flutter/material.dart';

import '../../domain/task.dart';
import '../tasks/task_controller.dart';
import '../tasks/task_widgets.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) {
    final stats = TaskStats(controller.tasks, DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      children: [
        Text('Tu avance', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        const Text(
          'Un vistazo a todas tus tareas. Las vencidas forman parte de las pendientes.',
        ),
        const SizedBox(height: 36),
        Text(
          '${(stats.ratio * 100).round()} %',
          style: Theme.of(context).textTheme.displaySmall!
              .copyWith(fontSize: 56),
        ),
        const Text('de tareas completadas'),
        const SizedBox(height: 20),
        Semantics(
          label: 'Cumplimiento: ${(stats.ratio * 100).round()} por ciento',
          child: LinearProgressIndicator(
            value: stats.ratio,
            minHeight: 10,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 28),
        for (final entry in {
          'Completadas': stats.completed,
          'Pendientes': stats.pending,
          'Vencidas': stats.overdue,
          'Total': stats.total,
        }.entries)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text(
                      '${entry.value}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const Divider(),
            ],
          ),
        const SectionHeading('Por categoría'),
        for (final category in controller.categories)
          Builder(
            builder: (context) {
              final tasks = controller.tasks.where(
                (t) => t.categoryId == category.id,
              );
              final done = tasks.where((t) => t.completed).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${category.name}${category.archived ? ' (archivada)' : ''} · $done de ${tasks.length}',
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: tasks.isEmpty ? 0 : done / tasks.length,
                      minHeight: 4,
                    ),
                  ],
                ),
              );
            },
          ),
        if (stats.total == 0)
          const Text('Cuando agregues tareas, verás aquí tu avance.'),
        const SizedBox(height: 16),
        const Text(
          'Cumplimiento = completadas ÷ total. No representa horas trabajadas ni productividad.',
        ),
      ],
    );
  }
}
