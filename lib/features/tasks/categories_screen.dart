import 'package:flutter/material.dart';

import '../../domain/task.dart';
import 'task_controller.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key, required this.controller});
  final TaskController controller;
  Future<void> _edit(BuildContext context, [TaskCategory? category]) async {
    final field = TextEditingController(text: category?.name);
    final form = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(category == null ? 'Nueva categoría' : 'Editar categoría'),
        content: Form(
          key: form,
          child: TextFormField(
            controller: field,
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Escribe un nombre.' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(c, field.text.trim());
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    // Dialog exit animation still references its controller until the next frame.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    field.dispose();
    if (name != null) {
      await controller.run(
        () => controller.repository.saveCategory(category?.id, name),
      );
    }
  }

  Future<void> _archive(BuildContext context, TaskCategory category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: const Text(
          'Se archivará y dejará de aparecer al crear tareas. Las tareas existentes conservarán su categoría. Puedes restaurarla después.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await controller.run(
        () => controller.repository.archiveCategory(category.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Categorías'),
      actions: [
        IconButton(
          tooltip: 'Crear categoría',
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Organiza tus tareas por ámbitos. Archivar una categoría conserva las tareas asociadas.',
          ),
          const SizedBox(height: 20),
          if (controller.error != null)
            Text(
              controller.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          for (final c in controller.categories)
            Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.name),
                  subtitle: Text(
                    '${controller.tasks.where((t) => t.categoryId == c.id).length} ${controller.tasks.where((t) => t.categoryId == c.id).length == 1 ? 'tarea' : 'tareas'}${c.archived ? ' · Archivada' : ''}',
                  ),
                  onTap: () => _edit(context, c),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Opciones de categoría',
                    onSelected: (v) {
                      if (v == 'edit') {
                        _edit(context, c);
                      } else if (v == 'restore') {
                        controller.run(
                          () => controller.repository.saveCategory(
                            c.id,
                            c.name,
                            restore: true,
                          ),
                        );
                      } else {
                        _archive(context, c);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(
                        value: c.archived ? 'restore' : 'archive',
                        child: Text(
                          c.archived ? 'Restaurar' : 'Eliminar categoría',
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
              ],
            ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva categoría'),
          ),
        ],
      ),
    ),
  );
}
