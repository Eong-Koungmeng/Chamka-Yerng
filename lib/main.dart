import 'package:background_fetch/background_fetch.dart';
import 'package:chamka_yerng/provider/app_settings.dart';
import 'package:chamka_yerng/screens/login_screen.dart';
import 'package:chamka_yerng/themes/darkTheme.dart';
import 'package:chamka_yerng/themes/lightTheme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'data/care.dart';
import 'data/plant.dart';
import 'data/garden.dart';
import 'screens/home_page.dart';
import 'package:chamka_yerng/notifications.dart' as notify;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Garden garden;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp();
  garden = await Garden.load();

  final appSettings = AppSettings();
  await appSettings.loadPreferences();

  final currentUser = FirebaseAuth.instance.currentUser;

  runApp(
    ChangeNotifierProvider(
      create: (_) => appSettings,
      child: ChamkaYerngApp(isLoggedIn: currentUser != null),
    ),
  );
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}


@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  var taskId = task.taskId;
  var timeout = task.timeout;
  if (timeout) {
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }

  print("helllllo");
  print("[BackgroundFetch] Headless event received: $taskId");

  Garden gr = await Garden.load();

  List<Plant> allPlants = await gr.getAllPlants();

  List<String> plants = [];
  String notificationTitle = "Plants require care";

  for (Plant p in allPlants) {
    for (Care c in p.cares) {
      var daysSinceLastCare = DateTime.now().difference(c.effected!).inDays;
      print(
          "headless chamka_yerng plant ${p.name} with days since last care $daysSinceLastCare");
      // Report all unattended care, current and past
      if (daysSinceLastCare != 0 && daysSinceLastCare / c.cycles >= 1) {
        plants.add(p.name);
        break;
      }
    }
  }

  try {
    final prefs = await SharedPreferences.getInstance();

    final String locale = prefs.getString('locale') ?? "en";

    if (AppLocalizations.delegate.isSupported(Locale(locale))) {
      final t = await AppLocalizations.delegate.load(Locale(locale));
      notificationTitle = t.careNotificationTitle;
    } else {
      print("handless chamka_yerng: unsupported locale " + locale);
    }
  } on Exception catch (_) {
    print("handless chamka_yerng: Failed to load locale");
  }

  if (plants.isNotEmpty) {
    notify.singleNotification(notificationTitle, plants.join('\n'), 7);
    print("headless chamka_yerng detected plants " + plants.join(' '));
  } else {
    print("headless chamka_yerng no plants require care");
  }

  print("[BackgroundFetch] Headless event finished: $taskId");

  BackgroundFetch.finish(taskId);
}
class ChamkaYerngApp extends StatelessWidget {
  final bool isLoggedIn;

  const ChamkaYerngApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);

    return MaterialApp(
      title: 'Chamka Yerng',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('km'), // Khmer
      ],
      locale: appSettings.locale,
      theme: buildLightThemeData(),
      darkTheme: buildDarkThemeData(),
      themeMode: appSettings.themeMode,
      home: isLoggedIn ? const MyHomePage(title: 'Today') : LoginPage(),
    );
  }
}
