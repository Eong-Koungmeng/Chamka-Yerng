import 'package:chamka_yerng/screens/plant_listing_update.dart';
import 'package:flutter/material.dart';
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
  bool _wasEdited = false;
  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
      Navigator.pop(context, _wasEdited);
      return false;
    },
    child: Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: true,
        title: FittedBox(fit: BoxFit.fitWidth, child: Text(_listing.title)),
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        actions: [
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
          )
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
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Placeholder for future "Contact Seller" action
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Contact Seller action')),
                            );
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('Contact Seller'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder( // Add this
                              borderRadius: BorderRadius.circular(10.0), // Adjust radius as needed
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Placeholder for future "Add to Favorites" action
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to Favorites')),
                            );
                          },
                          icon: const Icon(Icons.favorite_border),
                          label: const Text('Add to Favorites'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder( // Add this
                              borderRadius: BorderRadius.circular(10.0), // Adjust radius as needed
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
      ),),
    );
  }
}
