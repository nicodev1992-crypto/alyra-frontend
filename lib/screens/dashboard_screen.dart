import 'package:alyra_frontend/controllers/dashboard_controllers.dart';
import 'package:alyra_frontend/l10n/app_localizations.dart';
import 'package:alyra_frontend/widgets/dashboard_widgets.dart';
import 'package:alyra_frontend/widgets/helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardControllers _controllers = DashboardControllers();

  //USER INFO
  String _fullName = "User";
  String _email ="noemail";
  String _cellNumber = '234';
  String _password = '0000';
  int _targetMin = 70;
  int _targetMax = 150;
  int _hypoThreshold = 150;
  String? _diabete; //Type 1 /2
  String? _measurement_unit; // mg/dL ecc

  //GLUCOSE INFO
  double _lastGlucose = 110.0;
  StatusGlucoseType _status = StatusGlucoseType.TARGET;
  String _selectedPhase = "Null";
  String _tmpSelectedPhase = "Null";
  DateTime? _lastGlucoseMeasure;
  bool _userInsertAtLastOneMeasurement = false;
  bool _userInsertAtLastOneMeal = false;
  String _lastGlucoseTime = "--:--";

  //MEALS INFO
  String? _lastMealName;
  int? _lastMealCarbs;
  int? _selectedFoodId;
  double _selectedFoodCarbsPer100g = 0;
  double _currentGrams = 0;
  double _calculatedCarbs = 0;
  String _lastMealTime = "--:--";

  //GENERAL VALUES
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      DownloadAndShowUserInfo(),
      DownloadAndShowLastGlucose(),
      DownloadAndShowLastMeal(),
    ]);

    if (mounted) {
      setState(() {
        isLoading = false; // Spegne finalmente la rotella
      });
    }
  }

  Future<void> DownloadAndShowUserInfo() async {
    final data = await _controllers.getUser(context: context);

    if (data != null) {
      setState(() {
        _fullName = data['full_name'] ?? "No Name";
        _measurement_unit = data['measurement_unit'] ?? "NO FOUND";
        _diabete = data['diabetes_type'] ?? "NO FOUND";
        _targetMin = data['target_min'] ?? 23;
        _targetMax = data['target_max'] ?? 102;
        _hypoThreshold = data['hypo_threshold'] ?? 233;
        _email = data['email'] ?? 'nofound@gmail.com';
        _cellNumber = data['phone_number'] ?? '2344';
        _password = data['password'] ?? '0000';
      });
    }
  }

  Future<void> DownloadAndShowLastMeal() async {
    final data = await _controllers.getMeal(context: context);

    if (data != null) {
      setState(() {
        _lastMealName = data['description'] ?? "Nessuna descrizione";
        _lastMealCarbs = data['carbs_grams'] ?? 0;

        _userInsertAtLastOneMeal = true;

        if (data['consumed_at'] != null) {
          DateTime date = DateTime.parse(data['consumed_at']);
          _lastMealTime =
              "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
        }
      });
    }
  }

  Future<void> DownloadAndShowLastGlucose() async {
    try {
      final data = await _controllers.getLatestGlucose(context: context);
      print("$data");
      if (data != null) {
        setState(() {
          // 1. Usa il nome esatto che manda Python (probabilmente glucose_value)
          // 2. Forza la conversione in double per evitare crash di tipo
          _lastGlucose = (data['sugar_value'] as num?)?.toDouble() ?? 0.0;

          _selectedPhase = data['phase'] ?? "Non scaricata";
          _userInsertAtLastOneMeasurement = true;

          if (data['recorded_at'] != null) {
            // Controlla se Python manda 'recorded_at' o 'measured_at'
            DateTime date = DateTime.parse(data['recorded_at']);
            _lastGlucoseTime =
                "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
          }
        });
        print("Dati caricati: $_lastGlucose");
      }
    } catch (e) {
      print("ERRORE DURANTE IL DOWNLOAD: $e");
      // Se l'app si blocca sul caricamento, è perché entra qui e non "spegni" la rotella
    } finally {
      setState(() {
        // _isLoading = false; // Se hai una variabile di caricamento, spegnila qui!
      });
    }
  }

  // Funzione per il Logout
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const RegisterScreen()),
      );
    }
  }

  // dashboard_screen.dart

  void _insertGlucose(double value, String phase) {
    _controllers.trySendGlucoseToBackend(
      context: context,
      glucoseValue: value,
      phase: phase,
      sourceType: "Manuale", // <--- Qui decidi tu cosa inviare
      onSuccess: () {
        setState(() {
          _lastGlucose = value;
          _selectedPhase = phase;
          _userInsertAtLastOneMeasurement = true;
        });
      },
    );
  }

  final DashboardControllers _controller = DashboardControllers();

  void _insertMealInLocal(String mealName, double totalCarbs) {
    // Aggiorniamo SUBITO lo stato della Dashboard (Optimistic UI)
    setState(() {
      _userInsertAtLastOneMeal = true;
      _lastMealName = mealName;
      _lastMealCarbs = totalCarbs.toInt();

      DateTime date = DateTime.now();
      _lastMealTime = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    });

    _controller.insertMeal(
      context: context,
      mealName: mealName,
      totalCarbs: totalCarbs,
      onSuccess: () {
        // Qui puoi mettere un log o un piccolo messaggio di conferma
        print("Pasto sincronizzato con successo");
      },
    );
  }

  //UI
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(), // Il cerchietto che gira
        ),
      );
    }

    _status = DashboardHelper.setStatus(
      _lastGlucose,
      _targetMin,
      _targetMax,
      _hypoThreshold,
    );

    // Definiamo il colore principale in base allo stato per coerenza visiva
    Color statusColor;
    if (_status == StatusGlucoseType.CRITIC) {
      statusColor = Colors.red.shade900;
    } else if (_status == StatusGlucoseType.LOW) {
      statusColor = Colors.orange;
    } else if (_status == StatusGlucoseType.HIGH) {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.blue; // Colore standard "Normale"
    }

    return Scaffold(
      backgroundColor:
          Colors.grey[100], // Sfondo leggero per far risaltare le card
      appBar: AppBar(
        title: const Text("Alyra Diabetes Care"),
        backgroundColor:
            statusColor, // L'AppBar cambia colore in base all'emergenza
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- MEGA MESSAGGIO DI ALLARME (Appare solo in IPOGLICEMIA GRAVE) ---
            if (_status == StatusGlucoseType.CRITIC &&
                _userInsertAtLastOneMeasurement)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 25),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 45,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "IPOGLICEMIA GRAVE!",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Agisci subito: assumi 15g di carboidrati veloci (zucchero, succo o gel).",
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            DashboardWidgets.buildProfileCard(
              context: context,
              status: _status,
              fullName: _fullName,
              diabete: _diabete ?? "Tipo non specificato",
              phoneNumber: _cellNumber,
              email: _email
            ),

            const SizedBox(height: 20),

            Text(
              AppLocalizations.of(context)!.situazioneAttuale,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // CARD GLICEMIA PRINCIPALE
            DashboardWidgets.buildGlucoseCard(
              status: _status,
              selectedPhase: _selectedPhase,
              lastGlucose: _lastGlucose,
              measurementUnit: _measurement_unit ?? "mg/dL",
              targetMin: _targetMin,
              targetMax: _targetMax,
              hypoThreshold: _hypoThreshold,
              lastGlucoseMeasureTime: _lastGlucoseTime,
              userInsertAtLastOneMeasurement: _userInsertAtLastOneMeasurement,
            ),

            const SizedBox(height: 20),

            // --- QUESTO È IL WIDGET CHE MANCAVA ---
            // ... subito dopo DashboardWidgets.buildGlucoseCard(...)
            const SizedBox(height: 20),

            // --- DIARIO CIBO BELLO CON EMOJI ---
            if (!_userInsertAtLastOneMeal)
              Card(
                elevation: 2,
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const ListTile(
                  leading: Text(
                    "🍽️",
                    style: TextStyle(fontSize: 30),
                  ), // Emoji grande
                  title: Text(
                    "Diario ancora vuoto",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Inserisci il tuo primo alimento per iniziare! 🍎",
                  ),
                ),
              )
            else
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: const Text("🥗", style: TextStyle(fontSize: 30)),
                  title: Text("Ultimo pasto: $_lastMealName"),
                  subtitle: Text(
                    "Carboidrati totali: ${_lastMealCarbs.toString()} g. Ora pasto: ${_lastMealTime.toString()}",
                  ),

                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              ),

            const SizedBox(height: 25),

            // --- CONSIGLI ALIMENTARI: MOSTRATI SOLO DOPO LA MISURAZIONE ---
            if (_userInsertAtLastOneMeasurement) ...[
              DashboardWidgets.buildFoodAdviceCard(),

              const SizedBox(height: 10),

              DashboardWidgets.buildFoodAlertCard(),
              const SizedBox(height: 30),
            ],

            // TASTI AZIONE
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionBtn(
                        Icons.add_chart,
                        "Glicemia",
                        Colors.blue,
                        onTap: _showAddGlucoseSheet,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionBtn(
                        Icons.search, // Icona differente per la ricerca
                        "Cerca Cibo",
                        Colors.green, // Colore diverso per distinguerlo
                        onTap: _showFoodSearchbar, // Apre la ricerca Python
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionBtn(
                        Icons.edit_note,
                        "Manuale",
                        Colors.orange,
                        onTap: _showAddMealSheet, // Vecchio inserimento manuale
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMealSheet() {
    final TextEditingController mealController = TextEditingController();
    final TextEditingController carbsPer100Controller = TextEditingController();
    final TextEditingController weightController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Il tasto si attiva solo se tutti i campi sono pieni
          bool isReady =
              mealController.text.isNotEmpty &&
              carbsPer100Controller.text.isNotEmpty &&
              weightController.text.isNotEmpty;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Registra Pasto 🥗",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: mealController,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(
                    labelText: "Cosa hai mangiato?",
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: carbsPer100Controller,
                        onChanged: (_) => setSheetState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Carbo (x100g)",
                          prefixIcon: Icon(Icons.straighten),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        onChanged: (_) => setSheetState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Grammi assunti",
                          prefixIcon: Icon(Icons.scale),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: isReady ? Colors.orange : Colors.grey[300],
                  ),
                  onPressed: isReady
                      ? () {
                          double c100 =
                              double.tryParse(carbsPer100Controller.text) ?? 0;
                          double weight =
                              double.tryParse(weightController.text) ?? 0;
                          double totalCarbs = (c100 * weight) / 100;

                          _insertMealInLocal(mealController.text, totalCarbs);

                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text(
                    "SALVA NEL DIARIO",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget per i bottoni in basso
  Widget _buildActionBtn(
    IconData icon,
    String label,
    Color color, {
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed:
          onTap, // <--- Ora il bottone userà la funzione che gli passiamo
      child: Column(
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showAddGlucoseSheet() {
    final TextEditingController glucoseController = TextEditingController();

    // Reset iniziale a "Null" come volevi tu
    setState(() {
      _tmpSelectedPhase = "Null";
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // LOGICA: Il tasto è pronto solo se c'è testo E la fase non è "Null"
          bool isReady =
              glucoseController.text.isNotEmpty && _tmpSelectedPhase != "Null";

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Nuova Misurazione",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Campo Valore
                TextField(
                  controller: glucoseController,
                  // AGGIUNTO: setSheetState per aggiornare il tasto mentre scrivi
                  onChanged: (val) => setSheetState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Valore sugar_value ($_measurement_unit)",
                    prefixIcon: Icon(Icons.bloodtype, color: Colors.red),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "In che momento sei?",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: ["Digiuno", "Pre-Pasto", "Post-Pasto", "Notte"].map(
                    (fase) {
                      return ChoiceChip(
                        label: Text(fase),
                        selected: _tmpSelectedPhase == fase,
                        onSelected: (selected) {
                          // Aggiorniamo la fase e ridisegniamo il pannello
                          setSheetState(() => _tmpSelectedPhase = fase);
                        },
                      );
                    },
                  ).toList(),
                ),

                const SizedBox(height: 30),

                // IL TASTO DINAMICO
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    // Se pronto Blu, altrimenti Grigio
                    backgroundColor: isReady
                        ? Colors.blue[700]
                        : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // SE NON PRONTO (isReady è false), onPressed riceve NULL e il tasto si disabilita
                  onPressed: () {
                    // 1. Legge il valore dalla TextField
                    double? val = double.tryParse(glucoseController.text);

                    if (val != null && _tmpSelectedPhase != "Null") {
                      // 2. Chiama la funzione di inserimento che abbiamo sistemato prima
                      _insertGlucose(val, _tmpSelectedPhase);

                      // 3. Chiude il modal
                      Navigator.pop(context);
                    } else {
                      // Feedback se mancano dati
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Inserisci un valore valido e seleziona una fase",
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "SALVA SU SUPABASE",
                    style: TextStyle(
                      // Testo bianco se attivo, grigio scuro se spento
                      color: isReady ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFoodSearchbar() {
    // Reset variabili di calcolo ogni volta che si apre
    _selectedFoodId = null;
    _currentGrams = 0;
    _calculatedCarbs = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Fondamentale per far salire il tastierino
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Cerca Alimento nel Database 🔍",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // BARRA DI RICERCA (Si collega al tuo backend Python)
                DashboardWidgets.buildFoodSearchField(
                  onFoodSelected: (food) {
                    setSheetState(() {
                      _selectedFoodId = food['id'];
                      _selectedFoodCarbsPer100g = (food['carbs'] as num)
                          .toDouble();
                      _lastMealName =
                          food['name']; // Salviamo il nome per la UI
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Campo Grammi (appare solo se un cibo è selezionato)
                if (_selectedFoodId != null) ...[
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Quanti grammi di $_lastMealName?",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.scale),
                    ),
                    onChanged: (value) {
                      double grams = double.tryParse(value) ?? 0;
                      setSheetState(() {
                        _currentGrams = grams;
                        _calculatedCarbs =
                            (grams * _selectedFoodCarbsPer100g) / 100;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Carboidrati calcolati: ${_calculatedCarbs.toStringAsFixed(1)} g",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor:
                        _selectedFoodId != null && _currentGrams > 0
                        ? Colors.orange
                        : Colors.grey,
                  ),
                  onPressed: _selectedFoodId == null || _currentGrams <= 0
                      ? null
                      : () {
                          // Invia il pasto calcolato al diario
                          _insertMealInLocal(_lastMealName!, _calculatedCarbs);
                          Navigator.pop(context);
                        },
                  child: const Text("CONFERMA E AGGIUNGI"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
