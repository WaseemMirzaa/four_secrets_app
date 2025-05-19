import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/guest.dart';

class GuestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<Guest>> getGuests() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('guests')
          .orderBy('createdAt', descending: false)  // Changed from descending: true to false
          .get();

      return snapshot.docs
          .map((doc) => Guest.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching guests: $e');
      rethrow;
    }
  }

  Future<String?> uploadProfilePicture(File image, String guestId) async {
    try {
      final ref = _storage.ref().child('guest_profiles/$guestId.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  Future<void> addGuest({
    required String name,
    required String guestType,
    String? contactNumber,
    File? profilePicture,
  }) async {
    try {
      final docRef = _firestore.collection('guests').doc();
      String? profilePictureUrl;

      if (profilePicture != null) {
        profilePictureUrl = await uploadProfilePicture(profilePicture, docRef.id);
      }

      final guest = Guest(
        id: docRef.id,
        name: name,
        contactNumber: contactNumber,
        guestType: guestType,
        profilePicture: profilePictureUrl,
        createdAt: DateTime.now(),
      );

      await docRef.set(guest.toMap());
    } catch (e) {
      print('Error adding guest: $e');
      rethrow;
    }
  }

  Future<void> updateGuest({
    required String id,
    required String name,
    required String guestType,
    String? contactNumber,
    File? newProfilePicture,
  }) async {
    try {
      String? profilePictureUrl;

      if (newProfilePicture != null) {
        profilePictureUrl = await uploadProfilePicture(newProfilePicture, id);
      }

      final updates = {
        'name': name,
        'guestType': guestType,
        'contactNumber': contactNumber,
        'updatedAt': DateTime.now(),
      };

      if (profilePictureUrl != null) {
        updates['profilePicture'] = profilePictureUrl;
      }

      await _firestore
          .collection('guests')
          .doc(id)
          .update(updates);
    } catch (e) {
      print('Error updating guest: $e');
      rethrow;
    }
  }

  Future<void> deleteGuest(String id) async {
    try {
      // Delete profile picture if exists
      try {
        await _storage.ref().child('guest_profiles/$id.jpg').delete();
      } catch (_) {}

      // Delete guest document
      await _firestore.collection('guests').doc(id).delete();
    } catch (e) {
      print('Error deleting guest: $e');
      rethrow;
    }
  }
}
