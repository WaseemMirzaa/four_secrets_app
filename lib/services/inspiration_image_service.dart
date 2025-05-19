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
  Future<void> createInitialDataToDo(String title, File imageFile) async {
    if (userId == null) {
      print("Cannot create initial data: User not logged in");
      return;
    }


    String? imageUrl;


    final uploadResponse = await imageUploadService.uploadImage(imageFile);
    
      imageUrl = uploadResponse.image.getFullImageUrl();


    final inspirationModel = InspirationImageModel(
    title: title, 
    imageUrl: imageUrl, 
    createdAt: FieldValue.serverTimestamp(), 
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
        print("Warning: No checklist items found even though collection should be initialized");
      }
      
      inspirationImagesList = snapshot.docs
          .map((doc) => InspirationImageModel.fromFirestore(doc))
          .toList();
      
      print("Loaded ${inspirationImagesList.length} checklist items for user: $userId");
    } catch (e) {
      print('Error loading checklist: $e');
    }
  }


  // Update task status in Firebase
  Future<void> updateImageAndTitle(int index, String title,  ) async {
    if (userId == null || index >= inspirationImagesList.length) {
      print("Cannot update task: User not logged in or invalid index");
      return;
    }
    
    try {
      //  final uploadResponse = await imageUploadService.uploadImage(imageFile);
    
      // imageUrl = uploadResponse.image.getFullImageUrl();
      final task = inspirationImagesList[index];
      final updatedTask = task.copyWith(id: task.id, title: title, );
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('inspiration')
          .doc(task.id)
          .update({
            'title': title,
            // 'imageUrl': imageUrl,
      });
      
      // Update local list
      inspirationImagesList[index] = updatedTask;
      
      print("Updated task status: ${task.title} to $title");
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  // Delete task from Firebase
  Future<void> deleteImage(int index) async {
    if (userId == null || index >= inspirationImagesList.length) {
      print("Cannot delete task: User not logged in or invalid index");
      return;
    }
    
    try {
      final task = inspirationImagesList[index];
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('inspiration')
          .doc(task.id)
          .delete();
      
      // Remove from local list
      inspirationImagesList.removeAt(index);
      
      print("Deleted task: ${task.title}");
    } catch (e) {
      print('Error deleting task: $e');
    }
  }




}