import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/task.dart';
import '../tasks/task_controller.dart';
import '../tasks/task_widgets.dart';
import '../tasks/task_editor.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.controller});
  final TaskController controller;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selected = DateUtils.dateOnly(DateTime.now());
  late DateTime _month = DateTime(_selected.year, _selected.month);
  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final offset = (_month.weekday - 1) % 7;
    final tasks = selectTasks(widget.controller.tasks)
        .where((t) => t.dueAt != null && sameDay(t.dueAt!, _selected))
        .toList();
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      children: [
        Text('Calendario', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('MMMM y', 'es').format(_month),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Mes anterior',
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Mes siguiente',
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(d),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        LayoutBuilder(
          builder: (context, box) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: (box.maxWidth / 7).clamp(48, 64),
            ),
            itemCount: offset + days,
            itemBuilder: (context, i) {
              if (i < offset) return const SizedBox.shrink();
              final day = DateTime(_month.year, _month.month, i - offset + 1);
              final count = widget.controller.tasks
                  .where((t) => t.dueAt != null && sameDay(t.dueAt!, day))
                  .length;
              final selected = sameDay(day, _selected);
              return Semantics(
                label:
                    '${DateFormat('d MMMM', 'es').format(day)}, $count tareas',
                selected: selected,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selected = day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: selected ? scheme.primary : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: selected ? scheme.onPrimary : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: count == 0
                                ? Colors.transparent
                                : selected
                                ? scheme.onPrimary
                                : scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SectionHeading(
          DateFormat('EEEE d', 'es').format(_selected),
          trailing: '${tasks.length} tareas',
        ),
        TaskList(
          tasks: tasks,
          controller: widget.controller,
          empty: 'Sin tareas para este día',
        ),
        TextButton.icon(
          onPressed: () => openTaskEditor(
            context,
            widget.controller,
            date: DateTime(_selected.year, _selected.month, _selected.day, 17),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Agregar en esta fecha'),
        ),
      ],
    );
  }
}
