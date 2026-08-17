import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/workout_plan.dart';

class WorkoutPlanRepo {
  final FirebaseFirestore _db;

  WorkoutPlanRepo({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('workoutPlans');

  Future<String> create(String uid, WorkoutPlan plan) async {
    final ref = await _col(uid).add(plan.toJson());
    return ref.id;
  }

  Future<void> update(String uid, WorkoutPlan plan) {
    return _col(uid).doc(plan.id).update(plan.toJson());
  }

  Future<void> delete(String uid, String planId) {
    return _col(uid).doc(planId).delete();
  }

  Future<String> duplicate(String uid, WorkoutPlan plan) {
    final now = DateTime.now();
    return create(
      uid,
      plan
          .copyWith(name: '${plan.name} (copy)', updatedAt: now)
          .copyWith(id: ''),
    );
  }

  Stream<List<WorkoutPlan>> watchAll(String uid) {
    return _col(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => WorkoutPlan.fromJson(d.id, d.data()))
                  .toList(),
        );
  }
}
