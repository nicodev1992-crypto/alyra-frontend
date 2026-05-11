import 'dart:convert';
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

// glucose_service.dart
static Future<bool> saveGlucose({required int userId, required double glucoseValue, required String phase,required String sourceType,}) async { 
  final url = Uri.parse("https://alyra-backend.onrender.com/add_glucose");
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "sugar_value": glucoseValue,
        "recorded_at": DateTime.now().toIso8601String(),
        "source_type": sourceType, // <--- Inviato a Python
        "phase": phase,
      }),
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

  static Future<Map<String, dynamic>?> getLastGlucoseFromPython(
    int userId,
  ) async {
    final url = Uri.parse(
      "https://alyra-backend.onrender.com/analyses/last_glucose?user_id=$userId",
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
}
