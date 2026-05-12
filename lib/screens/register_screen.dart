import 'package:alyra_frontend/l10n/app_localizations.dart';
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

enum DiabetesType { type1, type2, gestational, lada, other }

String getDiabetesTypeName(DiabetesType type, AppLocalizations l10n) {
  switch (type) {
    case DiabetesType.type1:
      return l10n.diabetesType_type1;
    case DiabetesType.type2:
      return l10n.diabetesType_type2;
    case DiabetesType.gestational:
      return l10n.diabetesType_gestational;
    case DiabetesType.lada:
      return l10n.diabetesType_lada;
    case DiabetesType.other:
      return l10n.diabetesType_other;
  }
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
  final _icRatioController =
      TextEditingController(); // Rapporto Insulina/Carboidrati
  final _isfController = TextEditingController(); // Fattore di Sensibilità
  final _targetIdealController = TextEditingController(
    text: "110",
  ); // Target puntuale per il calcolo
  final _insulinDurationController = TextEditingController(
    text: "4",
  ); // Ore di attività
  final _ketoneThresholdController = TextEditingController(
    text: "250",
  ); // Soglia per alert chetoni

  String _selectedUnit = "mg/dL";
  DiabetesType _selectedDiabete = DiabetesType.type1;

  bool _isStep1Valid = false;
  bool _isStep2Valid = true;

  @override
  void initState() {
    super.initState();
    // Listener Passo 1
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);

    // Listener Passo 2 (Target e Calcoli)
    _minController.addListener(_validateForm);
    _maxController.addListener(_validateForm);
    _targetIdealController.addListener(_validateForm);
    _icRatioController.addListener(_validateForm);
    _isfController.addListener(_validateForm);
    _insulinDurationController.addListener(_validateForm);
    _ketoneThresholdController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      // Validazione Passo 1 rimane uguale
      _isStep1Valid =
          _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;

      // Logica dinamica per il Passo 2
      bool targetPresenti =
          _minController.text.isNotEmpty && _maxController.text.isNotEmpty;

      bool isT1OrLADA =
          _selectedDiabete == DiabetesType.type1 ||
          _selectedDiabete == DiabetesType.lada;

      if (isT1OrLADA) {
        // Se Tipo 1, tutti i parametri medici sono obbligatori
        _isStep2Valid =
            targetPresenti &&
            _targetIdealController.text.isNotEmpty &&
            _icRatioController.text.isNotEmpty &&
            _isfController.text.isNotEmpty &&
            _insulinDurationController.text.isNotEmpty;
      } else {
        // Per gli altri tipi, bastano i Target Min/Max (il resto è opzionale)
        _isStep2Valid = targetPresenti;
      }
    });
  }

  @override
  void dispose() {
    // Dispose Passo 1
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();

    // Dispose Passo 2 (Esistenti)
    _minController.dispose();
    _maxController.dispose();
    _hypoController.dispose();
    _noteController.dispose();

    // Dispose Nuovi Controller medici
    _icRatioController.dispose();
    _isfController.dispose();
    _targetIdealController.dispose();
    _insulinDurationController.dispose();
    _ketoneThresholdController.dispose();

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
      "target_ideal": int.tryParse(_targetIdealController.text) ?? 110, // NUOVO
      "ic_ratio": double.tryParse(_icRatioController.text) ?? 10.0, // NUOVO
      "isf": double.tryParse(_isfController.text) ?? 50.0, // NUOVO
      "insulin_duration":
          int.tryParse(_insulinDurationController.text) ?? 4, // NUOVO
      "ketone_threshold":
          int.tryParse(_ketoneThresholdController.text) ?? 250, // NUOVO
      "hypo_threshold": int.tryParse(_hypoController.text) ?? 70,
      "phone_number": _phoneController.text.trim(),
      "diabetes_note": _noteController.text.trim(),
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
          await prefs.setString('diabete', _selectedDiabete.name);
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
        children: [_buildStep1(), _buildStep2(context)],
      ),
    );
  }

  Widget _buildStep1() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileName, // "Nome"
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          _buildField(_nameController, "${l10n.profileName} *"),
          _buildField(_emailController, "${l10n.profileEmail} *"),
          _buildField(_passwordController, "Password *", obscure: true),
          _buildField(
            _phoneController,
            "${l10n.profilePhone} (opzionale)",
            isNum: true,
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isStep1Valid
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  )
                : null,
            child: const Text(
              "Continua",
            ), // Aggiungi chiave "continue" se vuoi tradurre anche questo
          ),
        ],
      ),
    );
  }

 Widget _buildStep2(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  bool isType1OrLADA =
      _selectedDiabete == DiabetesType.type1 || _selectedDiabete == DiabetesType.lada;
  String reqSuffix = isType1OrLADA ? '*' : l10n.optShort;

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.step2Title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
        ),
        const SizedBox(height: 24),

        // 1. TIPO DIABETE (In alto come priorità)
        _buildDropdown<DiabetesType>(
          l10n.diabetesType,
          _selectedDiabete,
          DiabetesType.values,
          (v) {
            setState(() {
              _selectedDiabete = v!;
              _validateForm();
            });
          },
          itemLabelBuilder: (type) => getDiabetesTypeName(type, l10n),
        ),
        const SizedBox(height: 16),

        // 2. UNITÀ DI MISURA
        _buildDropdown(
          l10n.measurementUnit,
          _selectedUnit,
          ["mg/dL", "mmol/L"],
          (v) => setState(() => _selectedUnit = v!),
        ),
        
        const SizedBox(height: 32), // Spazio generoso prima dei dati numerici

        // SEZIONE TARGET
        Row(
          children: [
            Expanded(child: _buildField(_minController, l10n.targetMin, isNum: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildField(_maxController, l10n.targetMax, isNum: true)),
          ],
        ),
        const SizedBox(height: 24),

        // SEZIONE PARAMETRI MEDICI (Con intestazione visiva)
        Row(
          children: [
            const Icon(Icons.calculate_outlined, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.calcParams,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ],
        ),
        const Divider(color: Colors.blueAccent),
        const SizedBox(height: 16),

        _buildField(
          _targetIdealController,
          "${l10n.targetIdeal} ${isType1OrLADA ? '*' : l10n.optional}",
          isNum: true,
        ),

        Row(
          children: [
            Expanded(child: _buildField(_icRatioController, "${l10n.icRatio} $reqSuffix", isNum: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildField(_isfController, "${l10n.isf} $reqSuffix", isNum: true)),
          ],
        ),

        Row(
          children: [
            Expanded(child: _buildField(_insulinDurationController, "${l10n.insDuration} $reqSuffix", isNum: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildField(_ketoneThresholdController, "${l10n.ketoneThreshold} $reqSuffix", isNum: true)),
          ],
        ),

        _buildField(_hypoController, l10n.hypoThreshold, isNum: true),

        const SizedBox(height: 32), // <--- Spazio richiesto prima delle note

        // NOTE (Più alte per scrivere meglio)
        _buildField(_noteController, l10n.diabetesNotes, lines: 3),

        const SizedBox(height: 32),

        // BOTTONE REGISTRAZIONE
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isStep2Valid ? _creaUtente : null,
            child: Text(l10n.completeReg, style: const TextStyle(fontSize: 16)),
          ),
        ),

        if (!_isStep2Valid)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l10n.validationError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),

        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          ),
          child: Text(l10n.back),
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

  Widget _buildDropdown<T>(
    String label,
    T value,
    List<T> items,
    ValueChanged<T?> onChanged, {
    String Function(T)? itemLabelBuilder,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          // Se c'è un builder per l'etichetta lo usa, altrimenti usa toString()
          child: Text(
            itemLabelBuilder != null ? itemLabelBuilder(item) : item.toString(),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
