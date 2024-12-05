import 'dart:io';
import 'package:background_fetch/background_fetch.dart';
import 'package:chamka_yerng/screens/error.dart';
import 'package:chamka_yerng/screens/forgot_password_screen.dart';
import 'package:chamka_yerng/screens/login_screen.dart';
import 'package:chamka_yerng/screens/register_screen.dart';
import 'package:chamka_yerng/themes/darkTheme.dart';
import 'package:chamka_yerng/themes/lightTheme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'data/care.dart';
import 'data/plant.dart';
import 'data/garden.dart';
import 'screens/home_page.dart';
import 'package:chamka_yerng/notifications.dart' as notify;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Garden garden;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  garden = await Garden.load();

  await Firebase.initializeApp();

  // Set default locale for background service
  final prefs = await SharedPreferences.getInstance();
  String? locale = Platform.localeName.substring(0, 2);
  await prefs.setString('locale', locale);

  runApp(const ChamkaYerngApp());

  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

/// This "Headless Task" is run when app is terminated.
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  var taskId = task.taskId;
  var timeout = task.timeout;
  if (timeout) {
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }

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
  const ChamkaYerngApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Chamka Yerng',
        localizationsDelegates: const [
          AppLocalizations.delegate, // Add this line
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (BuildContext context, Widget? widget) {
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            return ErrorPage(errorDetails: errorDetails);
          };

          return widget!;
        },
        supportedLocales: const [
          Locale('en'), // English
          Locale('km'),
        ],
        theme: buildLightThemeData(),
        darkTheme: buildDarkThemeData(),
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginPage(),
          '/register': (context) => RegisterPage(),
          '/forgot-password': (context) => ForgotPasswordPage(),
          '/home': (context) => MyHomePage(title: 'Today'),
        },
        );
  }
}
