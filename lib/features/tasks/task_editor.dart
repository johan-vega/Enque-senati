import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/task.dart';
import 'task_controller.dart';

Future<void> openTaskEditor(
  BuildContext context,
  TaskController controller, {
  Task? task,
  DateTime? date,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => TaskEditor(controller: controller, task: task, date: date),
);

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, required this.controller, this.task, this.date});
  final TaskController controller;
  final Task? task;
  final DateTime? date;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _description;
  DateTime? _date;
  String? _category;
  int _priority = 1;
  bool _completed = false, _reminder = false, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title);
    _description = TextEditingController(text: task?.description);
    _date = task?.dueAt ?? widget.date;
    _category = task?.categoryId;
    _priority = task?.priority ?? 1;
    _completed = task?.completed ?? false;
    _reminder = task?.reminder ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null && mounted) {
      setState(
        () => _date = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _date?.hour ?? 17,
          _date?.minute ?? 0,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date ?? DateTime.now()),
    );
    if (selected != null && mounted) {
      final d = _date ?? DateTime.now();
      setState(
        () => _date = DateTime(
          d.year,
          d.month,
          d.day,
          selected.hour,
          selected.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_reminder &&
        (_date == null || !_date!.isAfter(DateTime.now()) || _completed)) {
      setState(
        () => _error = 'Para un recordatorio, elige una fecha futura y un estado pendiente.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final success = await widget.controller.run(
      () => widget.controller.repository.save(
        Task(
          id: widget.task?.id ?? '',
          title: _title.text,
          description: _description.text,
          categoryId: _category,
          dueAt: _date,
          priority: _priority,
          completed: _completed,
          reminder: _reminder,
          createdAt: widget.task?.createdAt,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cambios guardados')));
    } else {
      setState(() => _error = widget.controller.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.controller.categories
        .where((c) => !c.archived || c.id == _category)
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .92,
        ),
        child: Form(
          key: _form,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.task == null ? 'Nueva tarea' : 'Editar tarea',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _title,
                autofocus: widget.task == null,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: '¿Qué necesitas hacer?',
                ),
                validator: validateTitle,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Sin categoría'),
                  ),
                  ...categories.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        '${c.name}${c.archived ? ' (archivada)' : ''}',
                      ),
                    ),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _category = v == '' ? null : v),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      _date == null
                          ? 'Elegir fecha'
                          : DateFormat('d MMM y', 'es').format(_date!),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(
                      _date == null
                          ? 'Hora'
                          : DateFormat('HH:mm').format(_date!),
                    ),
                  ),
                  if (_date != null)
                    IconButton(
                      tooltip: 'Quitar fecha',
                      onPressed: () => setState(() {
                        _date = null;
                        _reminder = false;
                      }),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Baja')),
                  DropdownMenuItem(value: 1, child: Text('Normal')),
                  DropdownMenuItem(value: 2, child: Text('Alta')),
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Completada'),
                value: _completed,
                onChanged: (v) => setState(() {
                  _completed = v;
                  if (v) _reminder = false;
                }),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recordarme a esta hora'),
                subtitle: Text(
                  widget.controller.reminders.supported
                      ? 'Activa también las notificaciones en Configuración.'
                      : 'Se guardará para tus dispositivos Android e iOS.',
                ),
                value: _reminder,
                onChanged: (v) => setState(() => _reminder = v),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Esperando confirmación del servidor. Si no hay conexión, puedes cerrar; el cambio queda en la caché de Firestore.',
                  ),
                ),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Guardando…' : 'Guardar tarea'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
