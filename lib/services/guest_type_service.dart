import 'package:cloud_firestore/cloud_firestore.dart';

class GuestTypeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getGuestTypes() async {
    try {
      final doc = await _firestore
          .collection('app_settings')
          .doc('guest_types')
          .get();

      if (!doc.exists) {
        // Initialize with default types if document doesn't exist
        await _firestore
            .collection('app_settings')
            .doc('guest_types')
            .set({
          'types': ['Close Relative', 'Friend']
        });
        return ['Close Relative', 'Friend'];
      }

      return List<String>.from(doc.data()?['types'] ?? []);
    } catch (e) {
      print('Error fetching guest types: $e');
      return ['Close Relative', 'Friend']; // Return defaults on error
    }
  }

  Future<void> addGuestType(String newType) async {
    try {
      await _firestore
          .collection('app_settings')
          .doc('guest_types')
          .update({
        'types': FieldValue.arrayUnion([newType])
      });
    } catch (e) {
      print('Error adding guest type: $e');
      rethrow;
    }
  }
}