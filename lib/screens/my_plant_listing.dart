import 'package:chamka_yerng/data/plant_listing.dart';
import 'package:chamka_yerng/screens/plant_listing_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class MyPlantListing extends StatefulWidget {
  const MyPlantListing({Key? key}) : super(key: key);

  @override
  State<MyPlantListing> createState() => _MyPlantListingState();
}

class _MyPlantListingState extends State<MyPlantListing> {
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
      setState(() {
        _isLoading = true;
      });

      final snapshot = await _database.child('plant_listings').get();
      if (snapshot.exists) {
        final Iterable<DataSnapshot> data = snapshot.children;
        final userId = _userId; // Ensure `_userId` is loaded

        if (userId != null) {
          final listings = data
              .map((data) => PlantListing.fromMap(data.value as Map<dynamic, dynamic>))
              .where((listing) => listing.sellerId == userId) // Filter by sellerId
              .toList();

          setState(() {
            _allPlantListings = listings;
          });
        } else {
          setState(() {
            _allPlantListings = [];
          });
        }
      } else {
        setState(() {
          _allPlantListings = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching listings: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar:  AppBar(
      toolbarHeight: 70,
      title: Text("My Listing"),
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
            // Listings
            Expanded(
              child: _allPlantListings.isEmpty
                  ? const Center(child: Text('No plants found.'))
                  : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: _allPlantListings.length,
                itemBuilder: (context, index) {
                  final listing = _allPlantListings[index];
                  return _buildPlantCard(listing);
                },
              ),
            ),
          ],
        )));
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
