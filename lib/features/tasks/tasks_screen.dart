import 'package:flutter/material.dart';

import '../../domain/task.dart';
import 'task_controller.dart';
import 'task_widgets.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.controller});
  final TaskController controller;
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.date;
  String _query = '';
  String? _category;
  @override
  Widget build(BuildContext context) {
    final selected = selectTasks(
      widget.controller.tasks,
      filter: _filter,
      sort: _sort,
      query: _query,
      categoryId: _category,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      children: [
        Text('Mis tareas', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Buscar tareas',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TaskFilter.values
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        const [
                          'Todas',
                          'Hoy',
                          'Próximas',
                          'Completadas',
                          'Vencidas',
                        ][f.index],
                      ),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              value: _category ?? '',
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Todas las categorías'),
                ),
                ...widget.controller.categories.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.name}${c.archived ? ' (archivada)' : ''}'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _category = v == '' ? null : v),
            ),
            PopupMenuButton<TaskSort>(
              tooltip: 'Ordenar tareas',
              initialValue: _sort,
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (_) => TaskSort.values
                  .map(
                    (s) => PopupMenuItem(
                      value: s,
                      child: Text(
                        const ['Fecha', 'Prioridad', 'Título'][s.index],
                      ),
                    ),
                  )
                  .toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Orden: ${const ['Fecha', 'Prioridad', 'Título'][_sort.index]} ↕',
                ),
              ),
            ),
          ],
        ),
        SectionHeading(
          '${selected.length} ${selected.length == 1 ? 'tarea' : 'tareas'}',
        ),
        TaskList(tasks: selected, controller: widget.controller),
      ],
    );
  }
}
