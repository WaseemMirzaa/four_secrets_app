import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/model/wedding_category_model.dart';

class WeddingCategoryDatabase {
  List<WeddingCategoryModel> categoryList = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // Create initial data for first-time users
  Future<void> createInitialWeddingCategories() async {
    if (userId == null) {
      print("Cannot create initial data: User not logged in");
      return;
    }

    // First check if user document exists
    final userDoc = await _firestore.collection('users').doc(userId).get();

    // If user document doesn't exist, create it with an initialization flag
    if (!userDoc.exists) {
      await _firestore.collection('users').doc(userId).set({
        'weddingCategoriesInitialized': false,
      });
    }

    // Get the user document (it definitely exists now)
    final userData =
        (await _firestore.collection('users').doc(userId).get()).data();

    // Check if categories have already been initialized
    final bool isInitialized =
        userData?['weddingCategoriesInitialized'] ?? false;

    if (!isInitialized) {
      print("Creating initial wedding categories for user: $userId");

      final initialCategories = [
        {
          "categoryName": "Vorbereitung & Ankunft",
          "items": [
            "⁠Braut & Bräutigam",
            "Ankunft der Gäste",
            "Transport zur Location",
            "Begrüßung durch Gastgeber"
          ]
        },
        {
          "categoryName": "Zeremonie",
          "items": [
            "Standesamtliche Trauung",
            "Freie Trauung",
            "Kirchliche Trauung",
            "Einzug der Braut",
            "Eheversprechen",
            "Ringtausch",
            "Gratulation & Umarmungen"
          ]
        },
        {
          "categoryName": "Empfang & Fotos",
          "items": [
            "Sektempfang",
            "Gruppenfoto",
            "Brautpaar-Shooting",
            "Familienfotos",
            "Gästebuch-Einträge"
          ]
        },
        {
          "categoryName": "Feier & Mahlzeiten",
          "items": [
            "Hochzeitstorte anschneiden",
            "Kaffee & Kuchen",
            "Abendessen / Dinner"
          ]
        },
        {
          "categoryName": "Party & Abschluss",
          "items": [
            "Eröffnungstanz",
            "Brautstraußwurf",
            "Hochzeitstanz mit Eltern",
            "DJ legt auf / Liveband beginnt",
            "Mitternachtssnack",
            "Feuerwerk",
            "Verabschiedung der Gäste",
            "Letzter Tanz"
          ]
        },
        {
          "categoryName": "Reden & Ansprachen",
          "items": [
            "Danksagung",
            "Spiele oder Programmpunkte",
            // "Hochzeitstanz mit Eltern",
            // "DJ legt auf / Liveband beginnt",
            // "Mitternachtssnack",
            // "Feuerwerk",
            // "Verabschiedung der Gäste",
            // "Letzter Tanz"
          ]
        }
      ];

      // Use a batch write for better performance
      final batch = _firestore.batch();

      for (var category in initialCategories) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('weddingCategories')
            .doc(); // Auto-generate document ID

        batch.set(docRef, {
          'categoryName': category['categoryName'],
          'items': category['items'],
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userId,
        });
      }

      // Set the initialization flag to true
      batch.update(_firestore.collection('users').doc(userId),
          {'weddingCategoriesInitialized': true});

      // Commit all operations at once
      await batch.commit();

      print(
          "Initial wedding categories created successfully and marked as initialized");
    } else {
      print(
          "User's wedding categories were already initialized, skipping creation");
    }
  }

  Future<bool> categoryExists(String categoryName) async {
    final categories = await loadWeddingCategories();
    return categories.any((category) =>
        category.categoryName.toLowerCase() == categoryName.toLowerCase());
  }

  // Get the index of the category with the given name
  Future<String?> getCategoryIndex(String categoryName) async {
    final categories = await loadWeddingCategories();
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].categoryName.toLowerCase() ==
          categoryName.toLowerCase()) {
        return i.toString(); // Assuming index is stored as a string
      }
    }
    return null;
  }

  // Load data from Firebase
  Future<List<WeddingCategoryModel>> loadWeddingCategories() async {
    if (userId == null) {
      print("Cannot load data: User not logged in");
      return [];
    }

    // Clear existing data to prevent duplication
    categoryList.clear();

    try {
      // First check if we need to initialize the categories
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists ||
          !(userDoc.data()?['weddingCategoriesInitialized'] ?? false)) {
        print("Wedding categories not initialized yet, creating initial data");
        await createInitialWeddingCategories();
      } else {
        print("Wedding categories already initialized, loading data");
      }

      // Now load all category items
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weddingCategories')
          .orderBy('createdAt', descending: false) // Keep original order
          .get();

      if (snapshot.docs.isEmpty) {
        print(
            "Warning: No wedding categories found even though collection should be initialized");
      }

      categoryList = snapshot.docs
          .map((doc) => WeddingCategoryModel.fromFirestore(doc))
          .toList();

      print(
          "Loaded ${categoryList.length} wedding categories for user: $userId");
      return categoryList;
    } catch (e) {
      print('Error loading wedding categories: $e');
      return [];
    }
  }

  // Add a new category to Firebase
  Future<void> addCategory(String categoryName, List<String> items) async {
    if (userId == null) {
      print("Cannot add category: User not logged in");
      return;
    }
    try {
      final now = DateTime.now();
      final newCategory = WeddingCategoryModel(
        id: '', // Will be set by Firestore
        categoryName: categoryName,
        items: items,
        createdAt: now,
        userId: userId!,
      );
      print(now);
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weddingCategories')
          .add(newCategory.toMap());
      final categoryWithId = newCategory.copyWith(id: docRef.id);
      categoryList.add(categoryWithId);
      print("Added category: $categoryName");
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  Future<void> updateCategory(
      String id, String categoryName, List<String> items) async {
    // if (userId == null || index >= categoryList.length) {

    //   print("Cannot update category: User not logged in or invalid index");
    //   return;
    // }

    try {
      // final updatedCategory = category.copyWith(
      //   categoryName: categoryName,
      //   items: items,
      // );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weddingCategories')
          .doc(id)
          .update({
        'categoryName': categoryName,
        'items': items,
      });

      // // Update local list
      // categoryList[index] = updatedCategory;

      print("Updated category: $categoryName");
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  // Delete category from Firebase
  Future<void> deleteCategory(int index) async {
    if (userId == null || index >= categoryList.length) {
      print("Cannot delete category: User not logged in or invalid index");
      return;
    }

    try {
      final category = categoryList[index];

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weddingCategories')
          .doc(category.id)
          .delete();

      // Remove from local list
      categoryList.removeAt(index);

      print("Deleted category: ${category.categoryName}");
    } catch (e) {
      print('Error deleting category: $e');
    }
  }

  // Get categories as Map for compatibility with existing UI
  Map<String, List<String>> getCategoriesAsMap() {
    Map<String, List<String>> result = {};
    for (var category in categoryList) {
      result[category.categoryName] = category.items;
    }
    return result;
  }

  // Search categories and items
  Map<String, List<String>> searchCategories(String query) {
    if (query.isEmpty) {
      return getCategoriesAsMap();
    }

    Map<String, List<String>> filteredMap = {};
    String lowerQuery = query.toLowerCase();

    for (var category in categoryList) {
      // Check if category name matches
      bool categoryMatches =
          category.categoryName.toLowerCase().contains(lowerQuery);

      // Filter items that match the search query
      List<String> matchedItems = category.items
          .where((item) => item.toLowerCase().contains(lowerQuery))
          .toList();

      // Include category if either the category name matches or it has matching items
      if (categoryMatches || matchedItems.isNotEmpty) {
        filteredMap[category.categoryName] =
            categoryMatches ? category.items : matchedItems;
      }
    }

    return filteredMap;
  }
}
