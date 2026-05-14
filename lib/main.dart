import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Import dei tuoi file
import 'l10n/app_localizations.dart';
import 'services/user_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/welcome_screen.dart'; // <--- Nuovo Import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final int? userId = prefs.getInt('userId');

  bool userIsValid = false;

  if (userId != null) {
    userIsValid = await UserService().checkUserExists(userId);
    if (!userIsValid) {
      await prefs.remove('userId');
    }
  }

  runApp(AlyraApp(isLogged: userId != null && userIsValid));
}

class AlyraApp extends StatelessWidget {
  final bool isLogged;
  const AlyraApp({super.key, required this.isLogged});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alyra',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('it'), Locale('en')],

      // Logica: Se loggato Dashboard, altrimenti Schermata di Benvenuto
      home: isLogged ? const DashboardScreen() : const WelcomeScreen(),
    );
  }
}
