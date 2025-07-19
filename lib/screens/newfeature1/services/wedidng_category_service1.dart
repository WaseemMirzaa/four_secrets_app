import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_category_model1.dart';

class WeddingCategoryDatabase1 {
  List<WeddingCategoryModel1> categoryList = [];
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
        'weddingCategoriesInitialized1': false,
      });
    }

    // Get the user document (it definitely exists now)
    final userData =
        (await _firestore.collection('users').doc(userId).get()).data();

    // Check if categories have already been initialized
    final bool isInitialized =
        userData?['weddingCategoriesInitialized1'] ?? false;

    if (!isInitialized) {
      print("Creating initial wedding categories for user: $userId");

      final initialCategories = [
        {
          "categoryName": "Ort & Location",
          "items": ["Hochzeitslocation", "Kirche", "Standesamt", "Hotel"]
        },
        {
          "categoryName": "Foto & Video",
          "items": ["Fotograf", "Videograf", "Fotobox"]
        },
        {
          "categoryName": "Musik & Unterhaltung",
          "items": [
            "DJ",
            "Live-Band",
            "Hochzeitssänger/in",
            "Entertainer",
            "Zeremonienmeister/in"
          ]
        },
        {
          "categoryName": "Essen & Getränke",
          "items": ["Catering", "Hochzeitstorte", "Barkeeper", "Foodtruck"]
        },
        {
          "categoryName": "Dekoration & Ausstattung",
          "items": [
            "Florist/in",
            "Dekorationsservice",
            "Möbelverleih",
            "Lichttechnik"
          ]
        },
        {
          "categoryName": "Styling & Kleidung",
          "items": [
            "Brautkleid",
            "Herrenausstatter",
            "Friseur/in",
            "Make-up Artist",
            "Kosmetiker/in",
            "Nageldesign",
            "Schmuckanbieter",
            "Trauringe"
          ]
        },
        {
          "categoryName": "Planung & Organisation",
          "items": ["Hochzeitsplaner/in", "Trauredner/in", "Ritualbegleiter/in"]
        },
        {
          "categoryName": "Transport",
          "items": ["Hochzeitsauto", "Shuttle-Service", "Hochzeitskutsche"]
        },
        {
          "categoryName": "Papeterie & Geschenke",
          "items": ["Einladungskarten", "Gastgeschenke", "Ringbox", "Gästebuch"]
        },
        {
          "categoryName": "Kinder & Familie",
          "items": ["Kinderbetreuung", "Babysitter"]
        },
        {
          "categoryName": "Digitale Services",
          "items": [
            "Livestream-Anbieter",
            "Wedding-Website-Anbieter",
            "Digitale Hochzeitseinladung"
          ]
        },
        {
          "categoryName": "Rechtliches & Finanzen",
          "items": [
            "Anwalt für Ehevertrag",
            "Hochzeitsversicherung",
            "Budget-Coach"
          ]
        },
        {
          "categoryName": "Pre-Wedding & Wellness",
          "items": ["Spa-Anbieter", "Personal Trainer"]
        },
        {
          "categoryName": "Tanz & Vorbereitung",
          "items": ["Tanzschule"]
        },
        {
          "categoryName": "Junggesellenabschied",
          "items": ["JGA-Eventplaner/in"]
        },
        {
          "categoryName": "Sprach- & Kulturdienste",
          "items": ["Dolmetscher/in"]
        }
      ];

      // Use a batch write for better performance
      final batch = _firestore.batch();

      for (var category in initialCategories) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('weddingCategories1')
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
          {'weddingCategoriesInitialized1': true});

      // Commit all operations at once
      await batch.commit();

      print(
          "Initial wedding categories1 created successfully and marked as initialized");
    } else {
      print(
          "User's wedding categories1 were already initialized, skipping creation");
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
  Future<List<WeddingCategoryModel1>> loadWeddingCategories() async {
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
          !(userDoc.data()?['weddingCategoriesInitialized1'] ?? false)) {
        print("Wedding categories1 not initialized yet, creating initial data");
        await createInitialWeddingCategories();
      } else {
        print("Wedding categories1 already initialized, loading data");
      }

      // Now load all category items
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weddingCategories1')
          .orderBy('createdAt', descending: false) // Keep original order
          .get();

      if (snapshot.docs.isEmpty) {
        print(
            "Warning: No wedding categories1 found even though collection should be initialized");
      }

      categoryList = snapshot.docs
          .map((doc) => WeddingCategoryModel1.fromFirestore(doc))
          .toList();

      print(
          "Loaded ${categoryList.length} wedding categories1 for user: $userId");
      return categoryList;
    } catch (e) {
      print('Error loading wedding categories1: $e');
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
      final newCategory = WeddingCategoryModel1(
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
          .collection('weddingCategories1')
          .add(newCategory.toMap());
      final categoryWithId = newCategory.copyWith(id: docRef.id);
      categoryList.add(categoryWithId);
      print("Added category1: $categoryName");
    } catch (e) {
      print('Error adding category1: $e');
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
          .collection('weddingCategories1')
          .doc(id)
          .update({
        'categoryName': categoryName,
        'items': items,
      });

      // // Update local list
      // categoryList[index] = updatedCategory;

      print("Updated category1: $categoryName");
    } catch (e) {
      print('Error updating category1: $e');
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
          .collection('weddingCategories1')
          .doc(category.id)
          .delete();

      // Remove from local list
      categoryList.removeAt(index);

      print("Deleted category1: ${category.categoryName}");
    } catch (e) {
      print('Error deleting category1: $e');
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
