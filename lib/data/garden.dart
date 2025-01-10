import 'dart:convert';
import 'package:chamka_yerng/data/plant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Garden {
  final DatabaseReference databaseRef;
  final String? userId;

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
        allPlants = List<Plant>.from(values.map((model) => Plant.fromMap(model)));
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
      DatabaseReference plantRef = databaseRef.child('garden/$userId/${plant.id}');
      DataSnapshot snapshot = await plantRef.get();
      bool isUpdate = snapshot.exists;
      await plantRef.set(plant.toMap());
      return isUpdate;
    } catch (e) {
      print('Error adding or updating plant: $e');
      return false;
    }
  }

  Future<bool> deletePlant(Plant plant) async {
    if (userId == null) {
      print('User not logged in. Cannot delete plant.');
      return false;
    }

    try {
      DatabaseReference plantRef = databaseRef.child('garden/$userId/${plant.id}');
      DataSnapshot snapshot = await plantRef.get();
      if (snapshot.exists) {
        await plantRef.remove();
        return true;
      }
      return false;
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
      DatabaseReference plantRef = databaseRef.child('garden/$userId/${plant.id}');
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