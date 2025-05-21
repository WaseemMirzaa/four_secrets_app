import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuService {
  // Singleton instance
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;
  MenuService._internal();

  final menuKey = GlobalKey<MenueState>();

  // Cached user data
  String? userName;
  String? profilePictureUrl;
  bool isDataLoaded = false;
  String? _selectedItem;
  
  String? get selectedItem => _selectedItem;
  set selectedItem(String? value) {
    _selectedItem = value;
    _saveSelectedItem(value); // Save to SharedPreferences
  }

  Future<void> _saveSelectedItem(String? item) async {
    final prefs = await SharedPreferences.getInstance();
    if (item != null) {
      await prefs.setString('selectedItem', item);
    } else {
      await prefs.remove('selectedItem');
    }
  }


  Future<void> loadSelectedItem() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedItem = prefs.getString('selectedItem');
  }



// Each call makes a fresh Menue widget but with the same key
  Widget getMenu(Key key) {
    return Menue(key: key);
  }
  
  // Preload user data
  Future<void> preloadUserData() async {
    if (isDataLoaded) return; // Skip if already loaded
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userData.exists) {
          userName = _capitalizeFirstLetter(userData.data()?['name']);
          profilePictureUrl = userData.data()?['profilePictureUrl'];
          isDataLoaded = true;
          
          // Update the menu state if it's already created
          if (menuKey.currentState != null) {
            menuKey.currentState!.updateUserData(userName, profilePictureUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('Error preloading menu user data: $e');
    }
  }
  
  // Helper method to capitalize the first letter of a string
  String _capitalizeFirstLetter(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
  
  // Refresh user data (call this after profile updates)
  Future<void> refreshUserData() async {
    isDataLoaded = false;
    await preloadUserData();
  }
}
