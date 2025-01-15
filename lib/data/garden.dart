import 'dart:convert';
import 'package:chamka_yerng/data/plant.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Garden {
  final DatabaseReference databaseRef;
  final String? userId;
  final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  final String apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  final String uploadPreset = "pxmjjkdg";

  Garden(this.databaseRef, this.userId);

  static Future<Garden> load() async {
    DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print('No user is logged in.');
      return Garden(databaseRef, null);
    }

    String userId = currentUser.uid;
    return Garden(databaseRef, userId);
  }

  Future<List<Plant>> getAllPlants() async {
    List<Plant> allPlants = [];
    if (userId == null) {
      print('User not logged in. Cannot fetch plants.');
      return allPlants;
    }

    try {
      DataSnapshot snapshot = await databaseRef.child('garden/$userId').get();
      if (snapshot.exists) {
        Map<String, dynamic> rawData =
            Map<String, dynamic>.from(snapshot.value as Map);
        Iterable values = rawData.values;
        allPlants =
            List<Plant>.from(values.map((model) => Plant.fromMap(model)));
      }
    } catch (e) {
      print('Error fetching plants: $e');
    }
    return allPlants;
  }

  Future<bool> addOrUpdatePlant(Plant plant) async {
    if (userId == null) {
      print('User not logged in. Cannot add or update plant.');
      return false;
    }

    try {
      DatabaseReference plantRef =
          databaseRef.child('garden/$userId/${plant.id}');
      DataSnapshot snapshot = await plantRef.get();
      bool isUpdate = snapshot.exists;
      await plantRef.set(plant.toMap());
      return isUpdate;
    } catch (e) {
      print('Error adding or updating plant: $e');
      return false;
    }
  }

  Future<bool> _deleteImageFromCloudinary(String imageUrl) async {
    try {
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
  Future<bool> deletePlant(Plant plant) async {
    if (userId == null) {
      print('User not logged in. Cannot delete plant.');
      return false;
    }

    try {
      DatabaseReference plantRef =
          databaseRef.child('garden/$userId/${plant.id}');
      DataSnapshot snapshot = await plantRef.get();

      if (!snapshot.exists) {
        return false;
      }

      if (plant.picture != null && plant.picture!.contains('cloudinary.com')) {
        await _deleteImageFromCloudinary(plant.picture!);
      }

      await plantRef.remove();
      return true;
    } catch (e) {
      print('Error deleting plant: $e');
      return false;
    }
  }

  Future<bool> updatePlant(Plant plant) async {
    if (userId == null) {
      print('User not logged in. Cannot update plant.');
      return false;
    }

    try {
      DatabaseReference plantRef =
          databaseRef.child('garden/$userId/${plant.id}');
      DataSnapshot snapshot = await plantRef.get();
      if (snapshot.exists) {
        await plantRef.set(plant.toMap());
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating plant: $e');
      return false;
    }
  }
}
