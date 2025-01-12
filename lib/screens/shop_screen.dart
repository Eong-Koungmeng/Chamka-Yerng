import 'package:flutter/material.dart';
import 'add_shop_item_screen.dart';

class ShopItem {
  final String name;
  final String image;
  final double price;

  ShopItem({required this.name, required this.image, required this.price});
}

class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final List<ShopItem> shopItems = [];

  void addNewItem(GardenItem newItem) {
    setState(() {
      shopItems.add(
        ShopItem(
          name: newItem.name,
          image: newItem.image,
          price: newItem.price,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddShopItemScreen(
                    onAddItem: (GardenItem newItem) {
                      addNewItem(newItem);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: shopItems.isEmpty
          ? const Center(child: Text("No items in the shop yet!"))
          : GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2 / 3,
        ),
        itemCount: shopItems.length,
        itemBuilder: (context, index) {
          final item = shopItems[index];
          return Card(
            elevation: 5,
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(item.image, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("\$${item.price.toStringAsFixed(2)}"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
