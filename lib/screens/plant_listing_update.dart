import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../data/plant_listing.dart';

class PlantListingUpdateScreen extends StatefulWidget {
  final PlantListing listing;

  const PlantListingUpdateScreen({Key? key, required this.listing})
      : super(key: key);

  @override
  _PlantListingUpdateScreenState createState() =>
      _PlantListingUpdateScreenState();
}

class _PlantListingUpdateScreenState extends State<PlantListingUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _priceController;
  late TextEditingController _sellerNameController;
  late TextEditingController _sellerContactController;

  XFile? _image;
  bool _imageChanged = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing.title);
    _descriptionController =
        TextEditingController(text: widget.listing.description);
    _priceController =
        TextEditingController(text: widget.listing.price.toString());
    _sellerNameController =
        TextEditingController(text: widget.listing.sellerName);
    _sellerContactController =
        TextEditingController(text: widget.listing.sellerContact);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sellerNameController.dispose();
    _sellerContactController.dispose();
    super.dispose();
  }

  Future<void> _showDeletePlantListingDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete listing"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("deletePlantBody"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('no'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('yes'),
              onPressed: () async {
                await _deleteListing();
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _deleteImageFromCloudinary(String imageUrl) async {
    try {
      final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
      final String apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        print('Invalid Cloudinary URL format');
        return false;
      }

      final publicId = pathSegments
          .sublist(uploadIndex + 2)
          .join('/')
          .replaceAll(RegExp(r'\.[^.]+$'), '');

      if (cloudName.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) {
        print("Missing Cloudinary credentials");
        return false;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final signaturePayload =
          'public_id=$publicId&timestamp=$timestamp${apiSecret}';
      final signature = sha1.convert(utf8.encode(signaturePayload)).toString();

      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');

      final requestBody = {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
        'api_key': apiKey,
        'signature': signature,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['result'] == 'ok';
      } else {
        print('Failed to delete image: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting image from Cloudinary: $e');
      return false;
    }
  }

  Future<bool> _deleteListing() async {
    try {
      DatabaseReference plantRef =
          _database.child('plant_listings/${widget.listing.id}');
      DataSnapshot snapshot = await plantRef.get();

      if (!snapshot.exists) {
        return false;
      }

      if (widget.listing.imageUrl != null &&
          widget.listing.imageUrl.contains('cloudinary.com')) {
        await _deleteImageFromCloudinary(widget.listing.imageUrl);
      }

      await plantRef.remove();
      return true;
    } catch (e) {
      print('Error deleting plant: $e');
      return false;
    }
  }

  String? _getPublicIdFromUrl(String? url) {
    if (url == null) return null;

    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 1 >= pathSegments.length)
        return null;
      final segments = pathSegments.sublist(uploadIndex + 2);
      return segments.join('/').replaceAll(RegExp(r'\.[^.]+$'), '');
    } catch (e) {
      print("Error extracting public_id: $e");
      return null;
    }
  }

  Future<String?> _uploadOrReplaceImage(String imagePath,
      {String? existingUrl}) async {
    try {
      final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
      final String apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
      const String uploadFolder = "profiles";

      final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final imageFile = await http.MultipartFile.fromPath('file', imagePath);

      final publicId = _getPublicIdFromUrl(existingUrl);

      String stringToSign;
      if (publicId != null) {
        stringToSign = "public_id=$publicId&timestamp=$timestamp$apiSecret";
      } else {
        stringToSign = "folder=$uploadFolder&timestamp=$timestamp$apiSecret";
      }

      final signature = sha1.convert(utf8.encode(stringToSign)).toString();

      final url =
          Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest("POST", url)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..files.add(imageFile);

      if (publicId != null) {
        request.fields['public_id'] = publicId;
      } else {
        request.fields['folder'] = uploadFolder;
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'];
      } else {
        print("Failed to upload image: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future getImageFromCamera() async {
    var image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 25);
    setState(() {
      _image = image;
      _imageChanged = true;
    });
  }

  Future getImageFromGallery() async {
    var image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
    setState(() {
      _image = image;
      _imageChanged = true;
    });
  }

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    if (_formKey.currentState!.validate()) {
      try {
        String? profilePictureUrl = widget.listing.imageUrl;

        if (_imageChanged && _image != null) {
          profilePictureUrl = await _uploadOrReplaceImage(_image!.path,
              existingUrl: widget.listing.imageUrl);

          if (profilePictureUrl == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error uploading image")),
            );
            return;
          }
        }
        // Update user data in Firebase Realtime Database
        await _database
            .child('plant_listings')
            .child(widget.listing.id)
            .update({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'imageUrl': profilePictureUrl,
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'sellerId':
              widget.listing.sellerId, // Preserved from the original listing
          'sellerName': _sellerNameController.text,
          'sellerContact': _sellerContactController.text,
          'createdAt': widget.listing.createdAt
              .toString(), // Preserved original creation date
        });

        final updatedListing = PlantListing(
          id: widget.listing.id,
          title: _titleController.text,
          description: _descriptionController.text,
          imageUrl: profilePictureUrl,
          price: double.tryParse(_priceController.text) ?? 0.0,
          sellerId:
              widget.listing.sellerId, // Preserved from the original listing
          sellerName: _sellerNameController.text,
          sellerContact: _sellerContactController.text,
          createdAt:
              widget.listing.createdAt, // Preserved original creation date
        );

        // Pass the updated listing back or call an API to save it
        Navigator.pop(context, updatedListing);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          automaticallyImplyLeading: true,
          title: const Text("Edit Listing"),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          titleTextStyle: Theme.of(context).textTheme.displayLarge,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Card(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 2,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        height: 200,
                        child: _image == null
                            ? (widget.listing.imageUrl != null &&
                                    widget.listing.imageUrl!.isNotEmpty
                                ? Image.network(
                                    widget.listing.imageUrl!,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.fitHeight,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  (loadingProgress
                                                          .expectedTotalBytes ??
                                                      1)
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/default_profile.png',
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.fitHeight,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    'assets/default_profile.png',
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.fitHeight,
                                  ))
                            : Image.file(
                                File(_image!.path),
                                width: 200,
                                height: 200,
                                fit: BoxFit.fitHeight,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/default_profile.png',
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.fitHeight,
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: getImageFromCamera,
                            icon: const Icon(Icons.add_a_photo),
                            tooltip: 'Take photo',
                          ),
                          IconButton(
                            onPressed: getImageFromGallery,
                            icon: const Icon(Icons.photo_library),
                            tooltip: 'Choose from gallery',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                Card(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a username';
                              }
                              return null;
                            },
                            cursorColor:
                                Theme.of(context).colorScheme.secondary,
                            maxLength: 20,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.person),
                              labelText: 'Username',
                              helperText: 'Enter your display name',
                            ),
                          ),
                          TextFormField(
                            controller: _descriptionController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                            maxLines: 3,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.description),
                              labelText: 'Description',
                              helperText: 'Describe your plant',
                            ),
                          ),
                          TextFormField(
                            controller: _priceController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a price';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.attach_money),
                              labelText: 'Price',
                              helperText: 'Enter the price in dollars',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FloatingActionButton.extended(
                heroTag: "delete",
                onPressed: () async {
                  await _showDeletePlantListingDialog();
                },
                label: Text("Delete"),
                icon: const Icon(Icons.delete),
                backgroundColor: Colors.redAccent,
              ),
              FloatingActionButton.extended(
                onPressed: _isLoading ? null : _updateListing,
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save'),
                icon: const Icon(Icons.save),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              )
            ],
          ),
        ));
  }
}
