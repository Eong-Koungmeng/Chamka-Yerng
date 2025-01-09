
// // shop_item.dart
// class ShopItem {
//   final String id;
//   final String name;
//   final String imageUrl;
//   final double price;
//
//   ShopItem({
//     required this.id,
//     required this.name,
//     required this.imageUrl,
//     required this.price,
//   });
// }


import 'package:flutter/material.dart';

class ShopItem {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;

  ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
  });
}

class ShopData with ChangeNotifier {
  // In-memory data storage (replace with Firebase or local database as needed)
  final List<ShopItem> _items = [];

  List<ShopItem> get items => [..._items];

  void addItem(ShopItem item) {
    _items.add(item);
    notifyListeners(); // Notify UI to update
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
