import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // Create initial categories for first-time users
  Future<void> createInitialCategories() async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // First check if user document exists
    final userDoc = await _firestore.collection('users').doc(userId).get();

    // If user document doesn't exist, create it with an initialization flag
    if (!userDoc.exists) {
      await _firestore.collection('users').doc(userId).set({
        'categoriesInitialized': false,
      });
    }

    // Get the user document
    final userData =
        (await _firestore.collection('users').doc(userId).get()).data();

    // Check if categories have already been initialized
    final bool isInitialized = userData?['categoriesInitialized'] ?? false;

    if (!isInitialized) {
      final initialCategories = [
        {
          "categoryName": "Dokumente & Organisatorisches",
          "todos": [
            "Personalausweis oder Reisepass",
            "Ablaufplan",
            "Kontaktdaten wichtiger Dienstleister",
            "Trinkgeld (in Umschlägen vorbereitet)"
          ]
        },
        {
          "categoryName": "Braut",
          "todos": [
            "Notfallset: Pflaster, Sicherheitsnadeln, Nähset, Kopfschmerztabletten",
            "Make-up zum Nachbessern (Puder, Lippenstift, Taschentücher)",
            "Deo & Parfum",
            "Ersatzstrumpfhose / -schuhe",
            "Mini-Haarspray",
          ]
        },
        {
          "categoryName": "Bräutigam",
          "todos": [
            "Ersatzhemd (bei warmem Wetter)",
            "Schuhputztuch",
            "Deo",
            "Taschentücher",
          ]
        },
        {
          "categoryName": "Technik",
          "todos": [
            "Geladene Handys + Powerbank",
            "Eheringe",
            "Traurede",
          ]
        },
        {
          "categoryName": "Snacks & Getränke",
          "todos": [
            "Kleine Snacks (Nüsse, Riegel)",
            "Wasserflaschen",
            "Strohhalm (für die Braut mit Make-up)",
          ]
        },
        {
          "categoryName": "Sonstiges",
          "todos": [
            "Kleine Decke (falls Fotos draußen stattfinden)",
            "Regenschirm",
          ]
        },
      ];

      // Use a batch write for better performance
      final batch = _firestore.batch();

      for (var category in initialCategories) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .doc();

        batch.set(docRef, {
          'categoryName': category['categoryName'],
          'todos': category['todos'],
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userId,
        });
      }

      // Set the initialization flag to true
      batch.update(_firestore.collection('users').doc(userId),
          {'categoriesInitialized': true});

      // Commit all operations at once
      await batch.commit();
    }
  }

  // Check if a category name already exists
  Future<bool> categoryExists(String categoryName) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .where('categoryName', isEqualTo: categoryName)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Create a new category
  Future<CategoryModel> createCategory(
      String categoryName, List<String> todos) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc();

    final category = CategoryModel(
      id: docRef.id,
      categoryName: categoryName,
      todos: todos,
      createdAt: DateTime.now(),
      userId: userId!,
    );

    await docRef.set(category.toMap());
    return category;
  }

  // Get all categories for the current user
  Future<List<CategoryModel>> getCategories([String? userId1]) async {
    if (userId == null && userId1 == null) {
      throw Exception('User not logged in');
    }

    try {
      String user = userId1 ?? userId!;
      // First check if we need to initialize the categories
      final userDoc = await _firestore.collection('users').doc(user).get();

      if (!userDoc.exists ||
          !(userDoc.data()?['categoriesInitialized'] ?? false)) {
        await createInitialCategories();
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user)
          .collection('categories')
          .get();

      final categories =
          snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();

      // No need to sort since we're getting them in order from Firestore
      return categories;
    } catch (e) {
      print('Error loading categories: $e');
      throw Exception('Failed to load categories: $e');
    }
  }

  // Get only custom categories (excluding initial default categories)
  Future<List<CategoryModel>> getCustomCategories([String? userId1]) async {
    if (userId == null && userId1 == null) {
      throw Exception('User not logged in');
    }

    try {
      String user = userId1 ?? userId!;

      // Get all categories first
      final allCategories = await getCategories(userId1);

      // Define the initial category names to exclude
      final initialCategoryNames = {
        "Dokumente & Organisatorisches",
        "Braut",
        "Bräutigam",
        "Technik",
        "Snacks & Getränke",
        "Sonstiges"
      };

      // Filter out initial categories, keeping only custom ones
      final customCategories = allCategories
          .where((category) =>
              !initialCategoryNames.contains(category.categoryName))
          .toList();

      return customCategories;
    } catch (e) {
      print('Error loading custom categories: $e');
      throw Exception('Failed to load custom categories: $e');
    }
  }

  // Update a category
  Future<void> updateCategory(CategoryModel category) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    if (category.userId != userId) {
      throw Exception('User does not have access to this category');
    }

    // Check for duplicate category name, excluding the current category
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .where('categoryName', isEqualTo: category.categoryName)
        .get();

    final hasDuplicate = snapshot.docs.any((doc) => doc.id != category.id);
    if (hasDuplicate) {
      throw Exception('Eine Kategorie mit diesem Namen existiert bereits');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final categoryDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .get();

    if (!categoryDoc.exists) {
      throw Exception('Category not found');
    }

    final category = CategoryModel.fromFirestore(categoryDoc);
    if (category.userId != userId) {
      throw Exception('Only the owner can delete the category');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  // Get a specific category
  Future<CategoryModel?> getCategory(String categoryId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return CategoryModel.fromFirestore(doc);
  }
}
