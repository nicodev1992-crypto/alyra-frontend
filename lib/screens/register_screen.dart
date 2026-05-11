import 'package:alyra_frontend/screens/dashboard_screen.dart';
import 'package:alyra_frontend/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Per salvare i dati sul telefono[cite: 3]

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();

  // Controller Passo 1
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Controller Passo 2
  final _minController = TextEditingController(text: "70");
  final _maxController = TextEditingController(text: "180");
  final _hypoController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedUnit = "mg/dL";
  String _selectedDiabete = "Type 1";

  bool _isStep1Valid = false;
  bool _isStep2Valid = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _minController.addListener(_validateForm);
    _maxController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isStep1Valid =
          _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;

      _isStep2Valid =
          _minController.text.isNotEmpty && _maxController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _hypoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _creaUtente() async {
    final String url =
        "https://alyra-backend.onrender.com/insert/register_user";

    final Map<String, dynamic> requestBody = {
      "full_name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
      "measurement_unit": _selectedUnit,
      "diabetes_type": _selectedDiabete,
      "target_min": int.tryParse(_minController.text) ?? 70,
      "target_max": int.tryParse(_maxController.text) ?? 180,
      "hypo_threshold": int.tryParse(_hypoController.text) ?? 70,
      "phone_number": _phoneController.text.isEmpty
          ? ""
          : _phoneController.text,
      "diabetes_note": _noteController.text.isEmpty ? "" : _noteController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // --- LOGICA DI SALVATAGGIO PERSISTENTE ---
        final responseData = jsonDecode(response.body);

        // Trasformiamo l'ID in numero in modo sicuro (anche se arriva come stringa)
        final dynamic rawId = responseData['user_id'];
        final int? newUserId = rawId is int
            ? rawId
            : int.tryParse(rawId.toString());

        if (newUserId != null) {
          // Salviamo l'ID nel telefono
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', newUserId);
          // 3. Salviamo i target LOCALMENTE prendendoli dai Controller dello screenshot
          // In questo modo la dashboard sarà subito pronta senza richiederli a internet
          await prefs.setInt(
            'target_min',
            int.tryParse(_minController.text) ?? 70,
          );
          await prefs.setInt(
            'target_max',
            int.tryParse(_maxController.text) ?? 180,
          );
          await prefs.setInt(
            'hypo_threshold',
            int.tryParse(_hypoController.text) ?? 70,
          );
          await prefs.setString('measurement_unit', _selectedUnit);
          await prefs.setString('diabete', _selectedDiabete);
          await prefs.setString('full_name', _nameController.text.trim());
          await prefs.setString('email', _emailController.text.trim());


          _showSnackBar(
            "✅ Profilo creato e dati salvati sul telefono!",
            Colors.green,
          );

          _showSnackBar(
            "✅ Profilo creato! Benvenuto ${_nameController.text}",
            Colors.green,
          );

          // Navighiamo alla Dashboard e rimuoviamo la pagina di registrazione dalla memoria
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        } else {
          // Se arrivi qui, il server ha risposto OK ma non ha mandato l'ID
          print(
            "ERRORE: user_id mancante nella risposta del server: ${response.body}",
          );
          _showSnackBar("⚠️ Errore: ID non ricevuto dal server", Colors.orange);
        }
      } else {
        _showSnackBar(
          "⚠️ Errore server: ${response.statusCode}",
          Colors.orange,
        );
      }
    } catch (e) {
      print("ERRORE DI CONNESSIONE: $e");
      _showSnackBar("❌ Errore di connessione. Controlla Render!", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrazione Alyra")),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildStep1(), _buildStep2()],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Passo 1: Credenziali",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildField(_nameController, "Nome Completo *"),
          _buildField(_emailController, "Email *"),
          _buildField(_passwordController, "Password *", obscure: true),
          _buildField(_phoneController, "Telefono (opzionale)", isNum: true),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isStep1Valid
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  )
                : null,
            child: const Text("Continua"),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Hai già un account?"),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Accedi",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Passo 2: Dati Medici",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildField(_minController, "Target Min *", isNum: true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(_maxController, "Target Max *", isNum: true),
              ),
            ],
          ),
          _buildField(
            _hypoController,
            "Soglia di ipoglicemia (opzionale)",
            isNum: true,
          ),
          _buildDropdown(
            "Unità di Misura *",
            _selectedUnit,
            ["mg/dL", "mmol/L"],
            (v) => setState(() => _selectedUnit = v!),
          ),
          _buildDropdown(
            "Tipo Diabete *",
            _selectedDiabete,
            ["Type 1", "Type 2", "Gestational", "LADA", "Other"],
            (v) => setState(() => _selectedDiabete = v!),
          ),
          _buildField(_noteController, "Note Diabete (opzionale)", lines: 2),
          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: _isStep2Valid ? _creaUtente : null,
            child: const Text("Completa Registrazione"),
          ),

          if (!_isStep2Valid)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                "Compila i campi obbligatori (*) per continuare",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          TextButton(
            onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            ),
            child: const Text("Indietro"),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool isNum = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        maxLines: lines,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
