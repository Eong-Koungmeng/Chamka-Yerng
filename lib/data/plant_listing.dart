class PlantListing {
  String id;
  String title;
  String description;
  String imageUrl;
  double price;
  String sellerId;
  String sellerName;
  String sellerContact;
  DateTime createdAt;

  PlantListing({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.sellerId,
    required this.sellerName,
    required this.sellerContact,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'sellerId' : sellerId,
      'sellerName': sellerName,
      'sellerContact': sellerContact,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlantListing.fromMap(Map<dynamic, dynamic> map) {
    return PlantListing(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      price: (map['price'] is int) ? (map['price'] as int).toDouble() : map['price'] is double? ? map['price'] as double : 0.0,
      sellerId: map['sellerId'] as String? ?? '',
      sellerName: map['sellerName'] as String? ?? '',
      sellerContact: map['sellerContact'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
