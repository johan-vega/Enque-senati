import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/task.dart';

class TaskSnapshot {
  const TaskSnapshot(
    this.tasks, {
    this.fromCache = false,
    this.pending = false,
  });
  final List<Task> tasks;
  final bool fromCache, pending;
}

abstract interface class TaskRepository {
  Stream<TaskSnapshot> watchTasks();
  Stream<List<TaskCategory>> watchCategories();
  Future<void> save(Task task);
  Future<void> delete(String id);
  Future<void> setCompleted(String id, bool value);
  Future<void> saveCategory(String? id, String name, {bool restore = false});
  Future<void> archiveCategory(String id);
}

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository(FirebaseFirestore db, String uid)
    : _user = db.collection('users').doc(uid);
  final DocumentReference<Map<String, dynamic>> _user;
  CollectionReference<Map<String, dynamic>> get _tasks =>
      _user.collection('tasks');
  @override
  Stream<TaskSnapshot> watchTasks() => _tasks
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) => TaskSnapshot(
          s.docs.map((d) => Task.fromMap(d.id, d.data())).toList(),
          fromCache: s.metadata.isFromCache,
          pending: s.metadata.hasPendingWrites,
        ),
      );
  @override
  Stream<List<TaskCategory>> watchCategories() => _user
      .collection('categories')
      .snapshots()
      .map(
        (s) =>
            s.docs
                .map(
                  (d) => TaskCategory(
                    d.id,
                    d.data()['name'] as String,
                    archived: d.data()['archived'] == true,
                  ),
                )
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );
  @override
  Future<void> save(Task task) {
    final data = task.toMap();
    if (task.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      return _tasks.doc().set(data);
    }
    return _tasks.doc(task.id).update(data);
  }

  @override
  Future<void> delete(String id) => _tasks.doc(id).delete();
  @override
  Future<void> setCompleted(String id, bool value) => _tasks.doc(id).update({
    'completed': value,
    'updatedAt': FieldValue.serverTimestamp(),
  });
  @override
  Future<void> saveCategory(String? id, String name, {bool restore = false}) {
    final data = <String, dynamic>{
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final ref = _user.collection('categories').doc(id);
    if (id == null) return ref.set({...data, 'archived': false});
    if (restore) data['archived'] = false;
    return ref.update(data);
  }

  @override
  Future<void> archiveCategory(String id) => _user
      .collection('categories')
      .doc(id)
      .update({'archived': true, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> ensureDefaults() async {
    // Deterministic IDs make initialization idempotent across two devices.
    final db = _user.firestore;
    await db.runTransaction((tx) async {
      final profile = await tx.get(_user);
      if (profile.exists) return;
      tx.set(_user, {'createdAt': FieldValue.serverTimestamp()});
      for (final entry in {
        'personal': 'Personal',
        'estudios': 'Estudios',
        'trabajo': 'Trabajo',
        'hogar': 'Hogar',
      }.entries) {
        tx.set(_user.collection('categories').doc(entry.key), {
          'name': entry.value,
          'archived': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
