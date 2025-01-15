import 'package:chamka_yerng/data/plant_listing.dart';
import 'package:chamka_yerng/screens/plant_listing_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class MyFavoriteScreen extends StatefulWidget {
  const MyFavoriteScreen({Key? key}) : super(key: key);

  @override
  State<MyFavoriteScreen> createState() => _MyFavoriteScreenState();
}

class _MyFavoriteScreenState extends State<MyFavoriteScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;
  List<PlantListing> _allPlantListings = [];
  bool _isLoading = false;
  @override
  void initState() {
    print("init shop");
    super.initState();
    _loadUserData();
  }
  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        // Handle not authenticated case
        Navigator.of(context).pop();
        return;
      }

      final userSnapshot = await _database
          .child('users')
          .child(currentUser.uid)
          .get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _userId = currentUser.uid;
        });
        _fetchPlantListings();
        setState(() {
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading user data')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _fetchPlantListings() async {
    try {
      setState(() => _isLoading = true);

      final userId = _userId;
      if (userId == null) {
        setState(() => _allPlantListings = []);
        return;
      }

      // Get favorite listing IDs
      final favoritesSnapshot = await _database
          .child('favorites')
          .child(userId)
          .get();

      final List<String> favoriteIds = [];
      if (favoritesSnapshot.exists) {
        final Map<dynamic, dynamic> favorites =
        favoritesSnapshot.value as Map<dynamic, dynamic>;
        favoriteIds.addAll(favorites.keys.cast<String>());
      }

      // Get plant listings matching favorite IDs
      if (favoriteIds.isEmpty) {
        setState(() => _allPlantListings = []);
        return;
      }

      final snapshot = await _database.child('plant_listings').get();
      if (snapshot.exists) {
        final listings = snapshot.children
            .map((data) => PlantListing.fromMap(
            data.value as Map<dynamic, dynamic>))
            .where((listing) => favoriteIds.contains(listing.id))
            .toList();

        setState(() => _allPlantListings = listings);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching listings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar:  AppBar(
          toolbarHeight: 70,
          title: Text("Favorite Listings"),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          titleTextStyle: Theme.of(context).textTheme.displayLarge,
        ),
        body:  _isLoading
            ? Center(child: CircularProgressIndicator()): _allPlantListings.isEmpty
            ? const Center(child: Text('No plants found.'))
            :
        RefreshIndicator(
          onRefresh: _fetchPlantListings,
          child: Column(
            children: [
              Expanded(
                child: _allPlantListings.isEmpty
                    ? const Center(child: Text('No plants found.'))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: _allPlantListings.length,
                  itemBuilder: (context, index) {
                    final listing = _allPlantListings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: _buildPlantCard(listing),
                    );
                  },
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildPlantCard(PlantListing listing) {
    final DatabaseReference _favoritesRef = FirebaseDatabase.instance
        .ref()
        .child('favorites')
        .child(_userId!)
        .child(listing.id!);

    return StreamBuilder<DatabaseEvent>(
      stream: _favoritesRef.onValue,
      builder: (context, snapshot) {
        final bool isFavorite = snapshot.data?.snapshot.exists ?? false;

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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: listing.imageUrl != null
                          ? Image.network(
                        listing.imageUrl,
                        fit: BoxFit.cover,
                      )
                          : const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: () async {
                      if (isFavorite) {
                        await _favoritesRef.remove();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Removed from Favorites')),
                        );
                      } else {
                        await _favoritesRef.set(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to Favorites')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
