import 'dart:convert';
import 'package:alyra_frontend/services/entries.dart';
import 'package:alyra_frontend/widgets/dashboard_helper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GlucoseService {
  static const String _baseUrl = "https://alyra-backend.onrender.com";

  // Determina lo stato testuale
  static String getStatus(double value, int min, int max, int hypo) {
    if (value <= hypo) return "IPOGLICEMIA GRAVE";
    if (value < min) return "Basso";
    if (value > max) return "Alto";
    return "Normale";
  }

  // Carica i dati iniziali da SharedPreferences
  static Future<Map<String, dynamic>> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'last_glucose': prefs.getDouble('last_glucose') ?? 110.0,
      'target_min': prefs.getInt('target_min') ?? 70,
      'target_max': prefs.getInt('target_max') ?? 180,
      'hypo_threshold': prefs.getInt('hypo_threshold') ?? 50,
      'phase': prefs.getString('last_glucose_phase') ?? "Null",
      'unit': prefs.getString('measurement_unit') ?? "mg/dL",
      'full_name': prefs.getString('full_name') ?? "User",
    };
  }

  static Future<bool> saveGlucose(GlucoseEntry glucoseParams) async {
    final url = Uri.parse("https://alyra-backend.onrender.com/post/glucose");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(glucoseParams.toJson()), // Converte l'oggetto in JSON
      );

      // Stampa per debug (opzionale ma utile)
      if (response.statusCode != 200) {
        print("Errore Server: ${response.body}");
      }

      return response.statusCode == 200;
    } catch (e) {
      print("Errore di rete: $e");
      return false;
    }
  }

  static Future<String?> postGlucoseAndGetAdvice(GlucoseEntry entry) async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://alyra-backend.onrender.com/brain/glucose_advice",
        ), // URL del tuo Python
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(entry.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['advice']; // Restituisce la stringa calcolata da Python
      }
      return null;
    } catch (e) {
      print("Errore fetch advice: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getLastGlucoseFromPython(
    int userId,
  ) async {
    final url = Uri.parse(
      "https://alyra-backend.onrender.com/get/last_glucose?user_id=$userId",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Errore fetch glucosio: $e");
      return null;
    }
  }

  static Future<bool> saveUnifiedLog({
    required int userId,
    required double glucose,
    required MainEvent mainEvent,
    required EventTiming timing,
    double? carbs,
    String? description,
    SportIntensity sportIntensity = SportIntensity.nessuna,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/insert/unified_log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'sugar_value': glucose,
          'main_event': mainEvent.name, // Invia "pasto", "sport", ecc.
          'event_timing': timing.name, // Invia "pre", "post", ecc.
          'carbs_grams': carbs,
          'description': description,
          'sport_intensity': sportIntensity.name,
          'recorded_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
