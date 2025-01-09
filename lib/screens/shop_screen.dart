import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/shop_item.dart';
import 'add_shop_item_screen.dart';

class ShopScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final shopData = Provider.of<ShopData>(context);
    final items = shopData.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
      ),
      body: items.isEmpty
          ? const Center(
        child: Text(
          'No items in the shop yet!',
          style: TextStyle(fontSize: 18),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (ctx, index) {
          final item = items[index];
          return Card(
            child: Column(
              children: [
                Image.network(
                  item.imageUrl,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                Text(item.name),
                Text('\$${item.price.toStringAsFixed(2)}'),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bought ${item.name}!')),
                    );
                  },
                  child: const Text('Buy'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => AddShopItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

