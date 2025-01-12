import 'dart:convert';
import 'dart:io';

import 'package:chamka_yerng/data/default.dart';
import 'package:chamka_yerng/data/plant.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../data/care.dart';
import '../main.dart';
import '../utils/random.dart';

import 'package:http/http.dart' as http;

class ManagePlantScreen extends StatefulWidget {
  const ManagePlantScreen(
      {Key? key, required this.title, required this.update, this.plant})
      : super(key: key);

  final String title;
  final bool update;
  final Plant? plant;

  @override
  State<ManagePlantScreen> createState() => _ManagePlantScreen();
}

class _ManagePlantScreen extends State<ManagePlantScreen> {
  Map<String, Care> cares = {};

  DateTime _planted = DateTime.now();

  List<Plant> _plants = [];

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  XFile? _image;
  int _prefNumber = 1;

  final String cloudName = "dyzvp6wsh";
  final String uploadPreset = "pxmjjkdg";

  Future<String?> _uploadImageToCloudinary(String imagePath, {bool isAsset = false}) async {
    try {
      // Cloudinary credentials
      final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
      final String apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
      const String uploadFolder = "public"; // Optional folder

      // Step 1: Generate a timestamp
      final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Step 2: Create the string to sign
      final String stringToSign = "folder=$uploadFolder&timestamp=$timestamp$apiSecret";

      // Step 3: Generate the signature using HMAC SHA-1
      final signature = sha1.convert(utf8.encode(stringToSign)).toString();

      // Step 4: Prepare the image file
      late http.MultipartFile imageFile;
      if (isAsset) {
        final byteData = await rootBundle.load(imagePath);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_avatar.png');
        await tempFile.writeAsBytes(byteData.buffer.asUint8List());
        imageFile = await http.MultipartFile.fromPath('file', tempFile.path);
      } else {
        imageFile = await http.MultipartFile.fromPath('file', imagePath);
      }

      // Step 5: Send the signed request to Cloudinary
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
      print("Error uploading image to Cloudinary: $e");
      return null;
    }
  }

  Future getImageFromCam() async {
    var image =
    await _picker.pickImage(source: ImageSource.camera, imageQuality: 25);
    setState(() {
      _image = image;
    });
  }

  Future getImageFromGallery() async {
    var image =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
    setState(() {
      _image = image;
    });
  }

  void getPrefabImage() {
    if (_prefNumber < 8) {
      setState(() {
        _image = null;
        _prefNumber++;
      });
    } else {
      setState(() {
        _image = null;
        _prefNumber = 1;
      });
    }
  }

  void _showIntegerDialog(String care) async {
    FocusManager.instance.primaryFocus?.unfocus();
    String tempDaysValue = "";

    await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.selectDays),
            content: ListTile(
                leading: const Icon(Icons.loop),
                title: TextFormField(
                  onChanged: (String txt) => tempDaysValue = txt,
                  autofocus: true,
                  initialValue: cares[care]!.cycles.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
                trailing: Text(AppLocalizations.of(context)!.days)),
            actions: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.ok),
                onPressed: () {
                  setState(() {
                    var parsedDays = int.tryParse(tempDaysValue);
                    if (parsedDays == null) {
                      cares[care]!.cycles = 0;
                    } else {
                      cares[care]!.cycles = parsedDays;
                    }
                  });
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    _loadPlants();

    // If is an update, restore old cares
    if (widget.update && widget.plant != null) {
      for (var care in widget.plant!.cares) {
        cares[care.name] = Care(
            name: care.name,
            cycles: care.cycles,
            effected: care.effected,
            id: care.name.hashCode);
      }
      _planted = widget.plant!.createdAt;
      nameController.text = widget.plant!.name;
      descriptionController.text = widget.plant!.description;
      locationController.text = widget.plant!.location ?? "";

      if (widget.plant!.picture!.contains("avatar")) {
        String? asset =
        widget.plant!.picture!.replaceAll(RegExp(r'\D'), ''); // '23'
        _prefNumber = int.tryParse(asset) ?? 1;
      } else {
        _image = XFile(widget.plant!.picture!);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Filling in the empty cares
    DefaultValues.getCares(context).forEach((key, value) {
      if (cares[key] == null) {
        cares[key] = Care(
            cycles: value.defaultCycles,
            effected: DateTime.now(),
            name: key,
            id: key.hashCode);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<ListTile> _buildCares(BuildContext context) {
    List<ListTile> list = [];

    DefaultValues.getCares(context).forEach((key, value) {
      list.add(ListTile(
          trailing: const Icon(Icons.arrow_right),
          leading: Icon(value.icon, color: value.color),
          title: Text(
              '${value.translatedName} ${AppLocalizations.of(context)!.every}'),
          subtitle: cares[key]!.cycles != 0
              ? Text(cares[key]!.cycles.toString() +
              " ${AppLocalizations.of(context)!.days}")
              : Text(AppLocalizations.of(context)!.never),
          onTap: () {
            _showIntegerDialog(key);
          }));
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: FittedBox(
            fit: BoxFit.fitWidth,
            child: widget.update
                ? Text(AppLocalizations.of(context)!.titleEditPlant)
                : Text(AppLocalizations.of(context)!.titleNewPlant)),
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: Theme.of(context).textTheme.displayLarge,
      ),
      //passing in the ListView.builder
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
              Card(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 2,
                child: SizedBox(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.0), //or 15.0
                          child: SizedBox(
                              height: 200,
                              child: _image == null
                                  ? Image.asset(
                                "assets/avatar_$_prefNumber.png",
                                fit: BoxFit.fitWidth,
                              )
                                  : Image.network(
                                _image!.path,
                                fit: BoxFit.cover, // Adjusts how the image fits the widget
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ?? 1)
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.error,
                                    size: 50,
                                    color: Colors.red,
                                  );
                                },
                              )
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            IconButton(
                              onPressed: getImageFromCam,
                              icon: const Icon(Icons.add_a_photo),
                              tooltip:
                              AppLocalizations.of(context)!.tooltipCameraImage,
                            ),
                            IconButton(
                                onPressed: getPrefabImage,
                                icon: const Icon(Icons.refresh),
                                tooltip: AppLocalizations.of(context)!
                                    .tooltipNextAvatar),
                            IconButton(
                              onPressed: getImageFromGallery,
                              icon: const Icon(Icons.wallpaper),
                              tooltip:
                              AppLocalizations.of(context)!.tooltipGalleryImage,
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    )),
              ),
              Card(
                semanticContainer: true,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Form(
                    key: _formKey,
                    child: Column(children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        validator: (name) {
                          if (name == null || name.isEmpty) {
                            return AppLocalizations.of(context)!.emptyError;
                          }
                          if (_plantExist(name)) {
                            return AppLocalizations.of(context)!.conflictError;
                          }
                          return null;
                        },
                        cursorColor: Theme.of(context).colorScheme.secondary,
                        maxLength: 20,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.local_florist),
                          labelText: AppLocalizations.of(context)!.labelName,
                          helperText: AppLocalizations.of(context)!.exampleName,
                        ),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        //Normal textInputField will be displayed
                        maxLines: 3,
                        // when user presses enter it will adapt to it
                        controller: descriptionController,
                        cursorColor: Theme.of(context).colorScheme.secondary,
                        maxLength: 100,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.topic),
                          labelText:
                          AppLocalizations.of(context)!.labelDescription,
                        ),
                      ),
                      TextFormField(
                        controller: locationController,
                        cursorColor: Theme.of(context).colorScheme.secondary,
                        maxLength: 20,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.location_on),
                          labelText:
                          AppLocalizations.of(context)!.labelLocation,
                          helperText:
                          AppLocalizations.of(context)!.exampleLocation,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              Card(
                semanticContainer: true,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(children: _buildCares(context)),
              ),
              Card(
                semanticContainer: true,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ListTile(
                  trailing: const Icon(Icons.arrow_right),
                  leading: const Icon(Icons.cake),
                  enabled: !widget.update,
                  title: Text(AppLocalizations.of(context)!.labelDayPlanted),
                  subtitle: Text(DateFormat.yMMMMEEEEd(
                      Localizations.localeOf(context).languageCode)
                      .format(_planted)),
                  onTap: () async {
                    DateTime? result = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1901, 1, 1),
                        lastDate: DateTime.now());
                    setState(() {
                      _planted = result ?? DateTime.now();
                    });
                  },
                ),
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            String? uploadedImageUrl;

            if (_image != null) {
              // Upload camera/gallery image
              uploadedImageUrl = await _uploadImageToCloudinary(_image!.path);
            } else {
              // Upload avatar asset
              uploadedImageUrl = await _uploadImageToCloudinary(
                  "assets/avatar_$_prefNumber.png",
                  isAsset: true
              );
            }

            if (uploadedImageUrl == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("errorUploadingImage"),
                  ));
              return;
            }

            final newPlant = Plant(
              id: widget.plant != null ? widget.plant!.id : generateRandomString(10).hashCode,
              name: nameController.text,
              createdAt: _planted,
              description: descriptionController.text,
              picture: uploadedImageUrl, // Always use the Cloudinary URL
              location: locationController.text,
              cares: [],
            );

            // Assign cares to the plant
            newPlant.cares.clear();
            cares.forEach((key, value) {
              if (value.cycles != 0) {
                newPlant.cares.add(Care(
                  cycles: value.cycles,
                  effected: value.effected,
                  name: key,
                  id: key.hashCode,
                ));
              }
            });

            // Save the plant
            await garden.addOrUpdatePlant(newPlant);

            Navigator.popUntil(context, ModalRoute.withName('/'));
          }
        },
        label: Text(AppLocalizations.of(context)!.saveButton),
        icon: const Icon(Icons.save),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }


  _loadPlants() async {
    List<Plant> allPlants = await garden.getAllPlants();
    setState(() => _plants = allPlants);
  }

  bool _plantExist(String name) => _plants.contains((plant) => plant.name == name);

}