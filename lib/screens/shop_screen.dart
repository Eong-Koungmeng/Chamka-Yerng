import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<dynamic, dynamic>> _allPlantListings = [];
  List<Map<dynamic, dynamic>> _displayedListings = [];
  String _searchQuery = "";
  bool _showLatest = true;

  @override
  void initState() {
    super.initState();
    _fetchPlantListings();
  }

  Future<void> _fetchPlantListings() async {
    try {
      final snapshot = await _database.child('plant_listings').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> listings = snapshot.value as Map<dynamic, dynamic>;
        final sortedListings = listings.values
            .toList()
            .cast<Map<dynamic, dynamic>>()
            .map((listing) => {
          ...listing,
          'createdAt': DateTime.parse(listing['createdAt']),
        })
            .toList()
          ..sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));

        setState(() {
          _allPlantListings = sortedListings;
          _displayedListings = sortedListings;
        });
      } else {
        setState(() {
          _allPlantListings = [];
          _displayedListings = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching listings: $e')),
      );
    }
  }

  void _filterListings(String query) {
    setState(() {
      _searchQuery = query;
      _displayedListings = _allPlantListings
          .where((listing) =>
          listing['title'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleListingType() {
    setState(() {
      _showLatest = !_showLatest;
      _displayedListings = _showLatest
          ? _allPlantListings
          : List.from(_allPlantListings)..shuffle(); // Example for "popular"
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                onChanged: _filterListings,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search plants...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Filters Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showLatest ? "Latest Plants" : "Popular Plants",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleListingType,
                    child: Text(
                      _showLatest ? "Show Popular" : "Show Latest",
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Listings
        Expanded(
          child: _displayedListings.isEmpty
              ? const Center(child: Text('No plants found.'))
              : GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: _displayedListings.length,
            itemBuilder: (context, index) {
              final listing = _displayedListings[index];
              return _buildPlantCard(listing);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlantCard(Map<dynamic, dynamic> listing) {
    return GestureDetector(
      onTap: () {
        // Navigate to a detailed screen or perform an action
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: listing['imageUrl'] != null
                    ? Image.network(
                  listing['imageUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
                    : const Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\$${listing['price']?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing['description'] ?? 'No description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
