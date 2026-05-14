import 'package:alyra_frontend/services/entries.dart';
import 'package:alyra_frontend/services/glucose_service.dart';
import 'package:alyra_frontend/services/meals_service.dart';
import 'package:alyra_frontend/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// dashboard_controllers.dart
class DashboardControllers {
  Future<Map<String, dynamic>?> getUser({required BuildContext context}) async {
    final prefs = await SharedPreferences.getInstance();
    // Recuperiamo l'ID e aggiungiamo un log per il debug
    final int userId = prefs.getInt('userId') ?? 0;

    if (userId == 0) {
      print("Errore: userId non trovato nelle SharedPreferences");
      return null;
    }

    try {
      print("Tentativo di recupero dati per utente..."); // DEBUG
      final userData = await UserService.getUser(userId);

      if (userData != null) {
        print("Dati ricevuti dal database: $userData"); // DEBUG
        return userData;
      } else {
        print(
          "Il database ha restituito un valore nullo per l'utente",
        ); // DEBUG
        return null;
      }
    } catch (e) {
      print("ERRORE CRITICO in getUser: $e"); // DEBUG
      return null;
    }
  }

  Future<void> getGlucoseAdvice({
    required BuildContext context,
    required GlucoseEntry glucoseDataEntry,
    required Function(String advice) onSuccess, // <--- Riceve la stringa
  }) async {
    // Chiamiamo il servizio che ora restituisce il testo del consiglio
    String? adviceFromServer = await GlucoseService.postGlucoseAndGetAdvice(
      glucoseDataEntry,
    );

    if (!context.mounted) return;

    if (adviceFromServer != null) {
      // Passiamo il consiglio ricevuto alla funzione onSuccess
      onSuccess(adviceFromServer);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Consiglio ricevuto con successo!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Errore: Impossibile ottenere il consiglio."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> insertMeal({
    required BuildContext context,
    required String mealName,
    required double totalCarbs,
    required VoidCallback onSuccess,
  }) async {
    // 1. Prendi i dati necessari prima della chiamata async
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;

    // 2. Chiamata al servizio
    bool success = await MealsService.sendMealToPython(
      userId,
      mealName,
      totalCarbs,
    );

    if (!context.mounted) {
      return; // Sicurezza extra: se l'utente è uscito, fermati.
    }

    if (success) {
      // 3. Salva localmente
      await prefs.setBool('has_enter_meal', true);
      // 5. DOPO aggiorna lo stato della Dashboard
      onSuccess();

      // 6. Mostra il feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ottimo! $mealName aggiunto."),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Errore durante l'invio del pasto."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // dashboard_controllers.dart

  Future<Map<String, dynamic>?> getMeal({required BuildContext context}) async {
    final prefs = await SharedPreferences.getInstance();
    // Recuperiamo l'ID e aggiungiamo un log per il debug
    final int userId = prefs.getInt('userId') ?? 0;

    if (userId == 0) {
      print("Errore: userId non trovato nelle SharedPreferences");
      return null;
    }

    try {
      final mealData = await MealsService.getLastMealOnPython(userId);
      if (mealData != null) {
        return mealData;
      } else {
        // Opzionale: non mostrare snackbar se è solo un caricamento vuoto all'inizio
        return null;
      }
    } catch (e) {
      print("Errore durante getMeal: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLatestGlucose({
    required BuildContext context,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;

    try {
      final glucoseData = await GlucoseService.getLastGlucoseFromPython(userId);
      if (glucoseData != null) {
        return glucoseData;
      } else {
        // Opzionale: non mostrare snackbar se è solo un caricamento vuoto all'inizio
        return null;
      }
    } catch (e) {
      print("Errore durante getMeal: $e");
      return null;
    }
  }

  Future<int> getUserID() async {
    return await UserService.getUserIDFromLocalDevice();
  }
}
