import 'package:chamka_yerng/screens/plant_listing_update.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/plant_listing.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class PlantListingDetail extends StatefulWidget {
  final PlantListing listing;

  const PlantListingDetail({
    Key? key,
    required this.listing,
  }) : super(key: key);

  @override
  State<PlantListingDetail> createState() => _PlantListingDetailState();
}

class _PlantListingDetailState extends State<PlantListingDetail> {
  late PlantListing _listing;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference _favoritesRef;
  bool _isFavorite = false;
  String? _userId;
  bool _wasEdited = false;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    _loadUserData();
  }

  void _checkIfFavorite() async {
    final snapshot = await _favoritesRef.get();
    setState(() {
      _isFavorite = snapshot.exists;
    });
  }

  void _toggleFavorite() async {
    if (_isFavorite) {
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
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }


  Future<void> _loadUserData() async {
    try {
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
        _favoritesRef = FirebaseDatabase.instance
            .ref('/favorites/$_userId/${_listing.id}');
        _checkIfFavorite();
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: true,
        title: FittedBox(fit: BoxFit.fitWidth, child: Text(_listing.title)),
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        actions: [ _userId == _listing.sellerId ?
          IconButton(
            icon: const Icon(Icons.edit),
            iconSize: 25,
            color: Theme.of(context).colorScheme.primary,
            tooltip: AppLocalizations.of(context)!.tooltipEdit,
            onPressed: () async {
              final updatedListing = await Navigator.push<PlantListing>(
                context,
                MaterialPageRoute(
                  builder: (context) => PlantListingUpdateScreen(listing: _listing),
                ),
              );
              if (updatedListing != null) {
                setState(() {
                  _listing = updatedListing;
                  _wasEdited = true;
                });
              }
            },
          ) : const SizedBox.shrink(),
        ],
        titleTextStyle: Theme.of(context).textTheme.displayLarge,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child:
            Column(
              children: [
                // Image Section
                Card(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child:
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _listing.imageUrl != null
                          ? Image.network(
                        _listing.imageUrl,
                        fit: BoxFit.fitHeight,
                        height: 200,
                      )
                          : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                      ),
                    ),
                ),


                // Details Section
                Card(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child:
                  Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and Price
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _listing.title ?? 'Untitled',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "\$${_listing.price?.toStringAsFixed(2) ?? '0.00'}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              Text(
                                _listing.createdAt != null
                                    ? DateFormat('dd MMMM yyyy').format(_listing.createdAt) // Format the date
                                    : 'Unknown',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              // Description
                              const Text(
                                "Description",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _listing.description?? 'No description available.',
                                style: const TextStyle(fontSize: 16, height: 1.5),
                              ),
                              const SizedBox(height: 20),

                              // Seller Information
                              const Text(
                                "Seller Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.grey),
                                  const SizedBox(width: 10),
                                  Text(
                                    _listing.sellerName ?? 'Unknown Seller',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.phone, color: Colors.grey),
                                  const SizedBox(width: 10),
                                  Text(
                                    _listing.sellerContact ?? 'No contact info',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                            ],
                          ),
                        ),
                      ),
                    ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _listing.sellerContact)); // Copy to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Seller contact copied: $_listing.sellerContact')),
                            );
                          },
                          icon: const Icon(Icons.copy), // Changed icon to indicate copying
                          label: const Text('Copy Seller Contact'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        )
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child:
                        ElevatedButton.icon(
                          onPressed: _toggleFavorite,
                          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                          label: Text(_isFavorite ? 'Unfavourite' : 'Favourite'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFavorite ? Colors.red : Colors.lightGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
