// import 'package:flutter/material.dart';
// import "package:provider/provider.dart";
// import '../data/shop_item.dart';
//
// class AddShopItemScreen extends StatelessWidget {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _imageUrlController = TextEditingController();
//
//   AddShopItemScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Add Item')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(labelText: 'Name'),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a name';
//                   }
//                   return null;
//                 },
//               ),
//               TextFormField(
//                 controller: _priceController,
//                 decoration: const InputDecoration(labelText: 'Price'),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || double.tryParse(value) == null) {
//                     return 'Please enter a valid price';
//                   }
//                   return null;
//                 },
//               ),
//               TextFormField(
//                 controller: _descriptionController,
//                 decoration: const InputDecoration(labelText: 'Description'),
//                 maxLines: 2,
//               ),
//               TextFormField(
//                 controller: _imageUrlController,
//                 decoration: const InputDecoration(labelText: 'Image URL'),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState!.validate()) {
//                     Provider.of<ShopData>(context, listen: false).addItem(
//                       ShopItem(
//                         id: DateTime.now().toString(),
//                         name: _nameController.text,
//                         price: double.parse(_priceController.text),
//                         description: _descriptionController.text,
//                         imageUrl: _imageUrlController.text,
//                       ),
//                     );
//                     Navigator.of(context).pop();
//                   }
//                 },
//                 child: const Text('Add Item'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class GardenItem {
  final String name;
  final String image;
  final double price;

  GardenItem({required this.name, required this.image, required this.price});
}

class AddShopItemScreen extends StatefulWidget {
  final Function(GardenItem) onAddItem;

  AddShopItemScreen({required this.onAddItem});

  @override
  _AddGardenItemScreenState createState() => _AddGardenItemScreenState();
}

class _AddGardenItemScreenState extends State<AddShopItemScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageController = TextEditingController();

  void _addItem() {
    if (nameController.text.isEmpty || priceController.text.isEmpty || imageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill out all fields")),
      );
      return;
    }

    final item = GardenItem(
      name: nameController.text,
      image: imageController.text,
      price: double.tryParse(priceController.text) ?? 0.0,
    );

    widget.onAddItem(item);
    Navigator.pop(context); // Return to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Garden Item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Item Name"),
            ),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(labelText: "Image Path"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addItem,
              child: const Text("Add Item"),
            ),
          ],
        ),
      ),
    );
  }
}
