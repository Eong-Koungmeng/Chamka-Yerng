import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../data/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  final usernameController = TextEditingController();
  final phoneNumberController = TextEditingController();

  XFile? _image;
  bool _imageChanged = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    usernameController.text = widget.user.username;
    phoneNumberController.text = widget.user.phoneNumber ?? '';
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? profilePictureUrl = widget.user.profilePicture;

      if (_imageChanged && _image != null) {
        profilePictureUrl = await _uploadOrReplaceImage(_image!.path,
            existingUrl: widget.user.profilePicture);

        if (profilePictureUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error uploading image")),
          );
          return;
        }
      }

      // Update user data in Firebase Realtime Database
      await _database.child('users').child(widget.user.uid).update({
        'username': usernameController.text,
        'profilePicture': profilePictureUrl,
        'phoneNumber': phoneNumberController.text,
      });

      // Update the user model in memory if you're maintaining it somewhere
      final updatedUser = UserModel(
        uid: widget.user.uid,
        username: usernameController.text,
        email: widget.user.email,
        profilePicture: profilePictureUrl,
        phoneNumber: widget.user.phoneNumber,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      // Optionally navigate back or update parent state
      Navigator.pop(context, updatedUser);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
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
        automaticallyImplyLeading: true,
        title: const Text("Profile"),
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
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _image == null
                            ? (widget.user.profilePicture != null &&
                                    widget.user.profilePicture!.isNotEmpty
                                ? Image.network(
                                    widget.user.profilePicture!,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
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
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    'assets/default_profile.png',
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ))
                            : Image.file(
                                File(_image!.path),
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/default_profile.png',
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
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
                          initialValue: widget.user.email,
                          enabled: false,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.email),
                            labelText: 'Email',
                          ),
                        ),
                        TextFormField(
                          controller: usernameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                          cursorColor: Theme.of(context).colorScheme.secondary,
                          maxLength: 20,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.person),
                            labelText: 'Username',
                            helperText: 'Enter your display name',
                          ),
                        ),
                        TextFormField(
                          controller: phoneNumberController,
                          cursorColor: Theme.of(context).colorScheme.secondary,
                          maxLength: 20,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.phone),
                            labelText: 'Phone Number',
                            helperText: 'Enter your phone number',
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
        onPressed: _isLoading ? null : _updateProfile,
        label: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Save Changes'),
        icon: const Icon(Icons.save),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }
}
