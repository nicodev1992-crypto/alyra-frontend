import 'dart:convert';
import 'package:http/http.dart' as http;

// meals_service.dart
class UserService {
  static Future<Map<String, dynamic>?> getUser(int userId) async {
    final url = Uri.parse(
      "https://alyra-backend.onrender.com/get_user?user_id=$userId",
    );
    try {
      final response = await http.get(
        url,
      ); // Uso GET come definito nel tuo backend
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data[0]; // Prendi il primo (e unico) utente nella lista
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> checkUserExists(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("https://alyra-backend.onrender.com/check_user_exists?user_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
