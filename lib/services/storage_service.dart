import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads meal photo bytes (works uniformly on web and mobile) and
  /// returns the public download URL to store on the meal document.
  Future<String> uploadMealPhoto({
    required String uid,
    required String mealId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref('users/$uid/meals/$mealId.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<void> deleteMealPhoto({
    required String uid,
    required String mealId,
  }) async {
    final ref = _storage.ref('users/$uid/meals/$mealId.jpg');
    try {
      await ref.delete();
    } on FirebaseException {
      // Already gone — nothing to do.
    }
  }

  /// Uploads a weight-log photo (also used as a body-transformation progress
  /// pic) and returns its public download URL.
  Future<String> uploadWeightPhoto({
    required String uid,
    required String logId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref('users/$uid/weightLogs/$logId.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<void> deleteWeightPhoto({
    required String uid,
    required String logId,
  }) async {
    final ref = _storage.ref('users/$uid/weightLogs/$logId.jpg');
    try {
      await ref.delete();
    } on FirebaseException {
      // Already gone — nothing to do.
    }
  }
}
