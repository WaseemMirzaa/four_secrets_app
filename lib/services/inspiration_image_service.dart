import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/models/inspiration_image.dart';
import 'package:four_secrets_wedding_app/services/image_upload_service.dart';

class InspirationImageService {
  List<InspirationImageModel> inspirationImagesList = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImageUploadService imageUploadService = ImageUploadService();

  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // Create initial data for first-time users
  Future<void> addImageToDB(String title, File imageFile) async {
    if (userId == null) {
      print("Cannot create initial data: User not logged in");
      return;
    }

    String? imageUrl;

    final uploadResponse =
        await imageUploadService.uploadImageAndUpdateImage(imageFile);

    imageUrl = uploadResponse.image.getFullImageUrl();

    final inspirationModel = InspirationImageModel(
        title: title,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        userId: userId!);

    // Use a batch write for better performance

    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('inspiration')
        .add(inspirationModel.toMap()); // Auto-generate document ID

    final inspirationWithId = inspirationModel.copyWith(id: docRef.id);
    inspirationImagesList.insert(0, inspirationWithId);

    print("data added to the collection for user: $userId");
  }

  // Load data from Firebase
  Future<void> loadDataToDo() async {
    if (userId == null) {
      print("Cannot load data: User not logged in");
      return;
    }

    // Clear existing data to prevent duplication
    inspirationImagesList.clear();

    try {
      // Now load all checklist items
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('inspiration')
          .orderBy('createdAt', descending: true) // Latest items on top
          .get();

      if (snapshot.docs.isEmpty) {
        print(
            "Warning: No checklist items found even though collection should be initialized");
      }

      inspirationImagesList = snapshot.docs
          .map((doc) => InspirationImageModel.fromFirestore(doc))
          .toList();

      print(
          "Loaded ${inspirationImagesList.length} checklist items for user: $userId");
    } catch (e) {
      print('Error loading checklist: $e');
    }
  }

  /// Update the inspiration item by its Firestore document ID.
  /// - If [imageFile] is non-null, replaces the previous image on the server.
  /// - Otherwise only updates the title.
  /// Returns the updated model for the UI to consume.
  Future<InspirationImageModel> updateById({
    required String id,
    required String currentImageUrl,
    required String newTitle,
    File? imageFile,
  }) async {
    if (userId == null) {
      throw Exception("User not logged in");
    }

    String updatedImageUrl = currentImageUrl;

    // 1) Replace image on the server, if provided
    if (imageFile != null) {
      final resp = await imageUploadService.uploadImageAndUpdateImage(
        imageFile,
        previousImageUrl: currentImageUrl.isNotEmpty ? currentImageUrl : null,
      );
      updatedImageUrl = resp.image.getFullImageUrl();
    }

    // 2) Persist title & (maybe) new imageUrl to Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('inspiration')
        .doc(id)
        .update({
      'title': newTitle,
      'imageUrl': updatedImageUrl,
    });

    // 3) Return updated model
    return InspirationImageModel(
      id: id,
      userId: userId!,
      title: newTitle,
      imageUrl: updatedImageUrl,
      createdAt:
          DateTime.now(), // or carry over the old DateTime if you have it
    );
  }

  // Delete task from Firebase
  Future<void> deleteImage(String id, String imageUrl) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('inspiration')
          .doc(id)
          .delete();

      var g = await imageUploadService.deleteImage(imageUrl);
      print(g);

      print("Deleted task: $id");
    } catch (e) {
      print('Error deleting task: $e');
    }
  }
}
