import 'dart:convert';
import 'package:http/http.dart' as http;

// meals_service.dart
class MealsService {
  static Future<bool> sendMealToPython(
    int userId,
    String name,
    double carbs,
  ) async {
    final url = Uri.parse(
      "https://alyra-backend.onrender.com/insert/last_meal",
    );
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "description": name,
          "carbs_grams": carbs,
          "consumed_at": DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getLastMealOnPython(int userId) async {
    final url = Uri.parse(
      "https://alyra-backend.onrender.com/analyses/last_meal?user_id=$userId",
    );
    try {
      final response = await http.get(
        url,
      ); // Uso GET come definito nel tuo backend
      if (response.statusCode == 200) {
        return jsonDecode(
          response.body,
        ); // Restituisce il JSON con carbs, desc, ecc.
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> searchFood(String query) async {
    if (query.length < 2) {
      return []; // Non cerchiamo se ha scritto solo una lettera
    }

    try {
      final response = await http
          .get(Uri.parse("http://127.0.0.1:5000/search_food?q=$query"))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print("Errore ricerca: $e");
    }
    return [];
  }
}
