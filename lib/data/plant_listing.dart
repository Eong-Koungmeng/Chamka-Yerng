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

  factory PlantListing.fromMap(Map<String, dynamic> map) {
    return PlantListing(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      price: map['price'],
      sellerId: map['sellerId'],
      sellerName: map['sellerName'],
      sellerContact: map['sellerContact'],
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
