import 'package:alyra_frontend/screens/register_screen.dart';
import 'package:alyra_frontend/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 1. IMPORTA QUESTE RIGHE (il percorso esatto dipende dal tuo progetto)
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'screens/dashboard_screen.dart';

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

  runApp(
    AlyraApp(
      isLogged: userId != null && userIsValid,
    ),
  );
}

class AlyraApp extends StatelessWidget {
  final bool isLogged;
  const AlyraApp({super.key, required this.isLogged});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alyra',
      debugShowCheckedModeBanner: false,
      
      // 2. AGGIUNGI IL SUPPORTO ALLE LOCALIZZAZIONI
      localizationsDelegates: const [
        AppLocalizations.delegate, // Il delegato generato dai tuoi file .arb
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it'), // Italiano
        Locale('en'), // Inglese
      ],
      
      // Se vuoi forzare una lingua specifica per test:
      // locale: const Locale('it'), 

      home: isLogged ? const DashboardScreen() : const RegisterScreen(),
    );
  }
}