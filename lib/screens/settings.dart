import 'package:flutter/material.dart';
import 'package:chamka_yerng/notifications.dart' as notify;
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../provider/app_settings.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<SettingsScreen> createState() => _SettingsScreen();
}

class _SettingsScreen extends State<SettingsScreen> {
  int notificationTempo = 60;
  String selectedLanguage = 'en';
  bool isDarkTheme = false;

  void _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _showIntegerDialog() async {
    FocusManager.instance.primaryFocus?.unfocus();

    String tempHoursValue = "";

    await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.selectHours),
            content: ListTile(
                leading: const Icon(Icons.loop),
                title: TextFormField(
                  onChanged: (String txt) => tempHoursValue = txt,
                  autofocus: true,
                  initialValue: (notificationTempo / 60).round().toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
                trailing: Text(AppLocalizations.of(context)!.hours)),
            actions: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.ok),
                onPressed: () {
                  setState(() {
                    var parsedHours = int.tryParse(tempHoursValue);
                    if (parsedHours == null) {
                      notificationTempo = 1 * 60;
                    } else {
                      notificationTempo = parsedHours * 60;
                    }
                  });
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  Future<void> getSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationTempo = prefs.getInt('notificationTempo') ?? 60;
      selectedLanguage = prefs.getString('selectedLanguage') ?? 'en';
      isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationTempo', notificationTempo);
    await prefs.setString('selectedLanguage', selectedLanguage);
    await prefs.setBool('isDarkTheme', isDarkTheme);
  }

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(AppLocalizations.of(context)!.tooltipSettings)),
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: Theme.of(context).textTheme.displayLarge,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
              Card(
                semanticContainer: true,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(children: <Widget>[
                  ListTile(
                    trailing: const Icon(Icons.arrow_right),
                    leading: const Icon(Icons.alarm, color: Colors.blue),
                    title: Text(AppLocalizations.of(context)!.notifyEvery),
                    subtitle: notificationTempo != 0
                        ? Text((notificationTempo / 60).round().toString() +
                        " ${AppLocalizations.of(context)!.hours}")
                        : Text(AppLocalizations.of(context)!.never),
                    onTap: () {
                      _showIntegerDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    subtitle: Transform.translate(
                      offset: const Offset(-10, -5),
                      child:
                      Text(AppLocalizations.of(context)!.notificationInfo),
                    ),
                  ),
                  ListTile(
                      trailing: const Icon(Icons.arrow_right),
                      leading: const Icon(Icons.circle_notifications,
                          color: Colors.red),
                      title: Text(
                          AppLocalizations.of(context)!.testNotificationButton),
                      onTap: () {
                        notify.singleNotification(
                            AppLocalizations.of(context)!.testNotificationTitle,
                            AppLocalizations.of(context)!.testNotificationBody,
                            2);
                      }),
                  const Divider(height: 1),

                  // Language Selection
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.green),
                    title: Text("language"),
                    subtitle: Text(appSettings.locale.languageCode == 'en'
                        ? 'English'
                        : 'Khmer'),
                    onTap: () async {
                      final newLocale = appSettings.locale.languageCode == 'en'
                          ? const Locale('km')
                          : const Locale('en');
                      await appSettings.updateLocale(newLocale);
                    },
                  ),

                  // Theme Selection
                  ListTile(
                    leading: const Icon(Icons.brightness_6, color: Colors.amber),
                    title: Text("theme"),
                    subtitle: Text(appSettings.themeMode == ThemeMode.dark
                        ? 'Dark'
                        : 'Light'),
                    onTap: () async {
                      final newThemeMode = appSettings.themeMode ==
                          ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                      await appSettings.updateThemeMode(newThemeMode);
                    },
                  ),

                  // Logout Option
                  ListTile(
                    trailing: const Icon(Icons.arrow_right),
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title:
                    Text(AppLocalizations.of(context)?.logout ?? 'Logout'),
                    onTap: () => _handleLogout(context),
                  ),
                ]),
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('notificationTempo', notificationTempo);
          Navigator.pop(context);
        },
        label: Text(AppLocalizations.of(context)!.saveButton),
        icon: const Icon(Icons.save),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}