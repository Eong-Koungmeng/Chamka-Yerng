import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../data/plant_listing.dart';
import '../utils/random.dart';

class AddPlantListingScreen extends StatefulWidget {
  final String title;
  const AddPlantListingScreen({
    Key? key,
    required this.title

  }) : super(key: key);

  @override
  State<AddPlantListingScreen> createState() => _AddPlantListingScreenState();
}

class _AddPlantListingScreenState extends State<AddPlantListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final contactController = TextEditingController();

  XFile? _image;
  bool _isLoading = false;
  String? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
          _userName = userData['username'] as String;
          // Pre-fill contact info if available
          if (userData['phoneNumber'] != null) {
            contactController.text = userData['phoneNumber'] as String;
          }
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

  Future<String?> _uploadImage(String imagePath) async {
    try {
      final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
      final String apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
      const String uploadFolder = "plant_listings";

      final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final imageFile = await http.MultipartFile.fromPath('file', imagePath);

      final String stringToSign = "folder=$uploadFolder&timestamp=$timestamp$apiSecret";
      final signature = sha1.convert(utf8.encode(stringToSign)).toString();

      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest("POST", url)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..fields['folder'] = uploadFolder
        ..files.add(imageFile);

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
    var image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 25);
    setState(() {
      _image = image;
    });
  }

  Future getImageFromGallery() async {
    var image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
    setState(() {
      _image = image;
    });
  }

  Future<void> _createListing() async {
    if (!_formKey.currentState!.validate() || _image == null) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add an image for your listing')),
        );
      }
      return;
    }

    if (_userId == null || _userName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User data not loaded')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadImage(_image!.path);

      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error uploading image")),
        );
        return;
      }

      final listing = PlantListing(
        id: generateRandomString(20),
        title: titleController.text,
        description: descriptionController.text,
        imageUrl: imageUrl,
        price: double.parse(priceController.text),
        sellerId: _userId!,
        sellerName: _userName!,
        sellerContact: contactController.text,
        createdAt: DateTime.now(),
      );

      // Save to Firebase Realtime Database
      await _database.child('plant_listings').child(listing.id).set(listing.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing created successfully!')),
      );

      Navigator.pop(context, listing);
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating listing: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(widget.title),
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
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                      child: _image == null
                          ? Center(
                        child: Text(
                          'No image selected',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                          : Image.file(
                        File(_image!.path),
                        fit: BoxFit.fitHeight,
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
                          controller: titleController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            icon: Icon(Icons.title),
                            labelText: 'Name',
                            helperText: 'Enter the name of your plant',
                          ),
                        ),
                        TextFormField(
                          controller: descriptionController,
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
                          controller: priceController,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createListing,
        label: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Create Listing'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    contactController.dispose();
    super.dispose();
  }
}