import 'package:chamka_yerng/data/plant_listing.dart';
import 'package:chamka_yerng/screens/plant_listing_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin{
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<PlantListing> _allPlantListings = [];
  List<PlantListing> _displayedListings = [];
  bool _isLoading = false;
  String _searchQuery = "";
  bool _showLatest = true;
  late TabController _tabController;
  bool _isAscending = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    print("init shop");
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchPlantListings();
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose of the controller to avoid memory leaks
    super.dispose();
  }

  Future<void> _fetchPlantListings() async {
    try {
      final snapshot = await _database.child('plant_listings').get();
      if (snapshot.exists) {
        final Iterable<DataSnapshot> data = snapshot.children;
        final listings = data.map((data) => PlantListing.fromMap(data.value as Map<dynamic, dynamic>)).toList();

        setState(() {
          _allPlantListings = listings;
          _applyFiltersAndSorting();
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

  void _handleTabChange() {
    _applyFiltersAndSorting();
  }

  void _applyFiltersAndSorting() {
    List<PlantListing> filteredListings = _allPlantListings;

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      filteredListings = filteredListings
          .where((listing) =>
          listing.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply sorting based on the selected tab
    switch (_tabController.index) {
      case 0: // Latest
        filteredListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 1: // Popular
        filteredListings.shuffle();
        break;
      case 2: // Price Low to High
        filteredListings.sort((a, b) => a.price!.compareTo(b.price!));
        break;
      case 3: // Price High to Low
        filteredListings.sort((a, b) => b.price!.compareTo(a.price!));
        break;
    }

    setState(() {
      _displayedListings = filteredListings;
    });
  }
  void _filterListings(String query) {
    setState(() {
      _searchQuery = query;
      _applyFiltersAndSorting();
    });
  }



  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _fetchPlantListings,
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: TextField(
                  onChanged: _filterListings,
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search plants...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterListings('');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.grey), // Border color
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.5), // Default border
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.blue, width: 2), // Focused border
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
              // Filters Row
              TabBar(
                controller: _tabController,
                onTap: (index) => _handleTabChange(),
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: const [
                  Tab(text: 'Latest'),
                  Tab(text: 'Popular'),
                  Tab(text: 'Price ↑'),
                  Tab(text: 'Price ↓'),
                ],
              ),
            ],
          ),
        ),
        _isLoading
            ? Center(child: CircularProgressIndicator()): _displayedListings.isEmpty
            ? const Center(child: Text('No plants found.'))
            :
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _displayedListings.isEmpty
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
        ),);
  }

  Widget _buildPlantCard(PlantListing listing) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantListingDetail(listing: listing),
          ),
        );
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
                child: listing.imageUrl != null
                    ? Image.network(
                  listing.imageUrl,
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
                    listing.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\$${listing.price?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.description ?? 'No description',
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
