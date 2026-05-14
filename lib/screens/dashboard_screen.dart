import 'package:alyra_frontend/controllers/dashboard_controllers.dart';
import 'package:alyra_frontend/l10n/app_localizations.dart';
import 'package:alyra_frontend/services/entries.dart';
import 'package:alyra_frontend/services/glucose_service.dart';
import 'package:alyra_frontend/widgets/dashboard_widgets.dart';
import 'package:alyra_frontend/widgets/dashboard_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardControllers controller = DashboardControllers();

  //USER INFO
  String _fullName = "User";
  String _email = "noemail";
  String _cellNumber = '234';
  String _password = '0000';
  int _targetMin = 70;
  int _targetMax = 150;
  int _hypoThreshold = 150;
  String? _diabete; //Type 1 /2
  String _measurementUnit = "mg/dL"; // mg/dL ecc

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
  double? _lastMealCarbs;
  int? _selectedFoodId;
  int user_id = 99;
  double _selectedFoodCarbsPer100g = 0;
  double _currentGrams = 0;
  double _calculatedCarbs = 0;
  String _lastMealTime = "--:--";

  String selectedGI = "Medio";

  //GENERAL VALUES
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    user_id = await controller.getUserID();

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
    final data = await controller.getUser(context: context);

    if (data != null) {
      setState(() {
        _fullName = data['full_name'] ?? "No Name";
        _measurementUnit = data['measurement_unit'] ?? "NO FOUND";
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
    final data = await controller.getMeal(context: context);

    if (data != null) {
      setState(() {
        _lastMealName = data['description'] ?? "Nessuna descrizione";
        _lastMealCarbs = (data['carbs_grams'] as num?)?.toDouble() ?? 0.0;

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
      final data = await controller.getLatestGlucose(context: context);
      print("$data");
      if (data != null) {
        setState(() {
          // 1. Usa il nome esatto che manda Python (probabilmente glucose_value)
          // 2. Forza la conversione in double per evitare crash di tipo
          // Sostituisci la tua riga 59 con questa versione "blindata"
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

  void _insertMealInLocal(String mealName, double totalCarbs) {
    // Aggiorniamo SUBITO lo stato della Dashboard (Optimistic UI)
    setState(() {
      _userInsertAtLastOneMeal = true;
      _lastMealName = mealName;
      _lastMealCarbs = totalCarbs;

      DateTime date = DateTime.now();
      _lastMealTime = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    });

    controller.insertMeal(
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
              email: _email,
            ),

            const SizedBox(height: 20),

            Text(
              AppLocalizations.of(context)!.situazioneAttuale,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // CARD GLICEMIA PRINCIPALE
            DashboardWidgets.buildGlucoseCard(
              context: context,
              status: _status,
              selectedPhase: _selectedPhase,
              lastGlucose: _lastGlucose,
              measurementUnit: _measurementUnit ?? "mg/dL",
              targetMin: _targetMin,
              targetMax: _targetMax,
              hypoThreshold: _hypoThreshold,
              lastGlucoseMeasureTime: _lastGlucoseTime,
              userInsertAtLastOneMeasurement: _userInsertAtLastOneMeasurement,
            ),

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
                      child: DashboardHelper.buildActionBtn(
                        Icons.add_chart,
                        "Glicemia",
                        Colors.blue,
                        onTap: _showAddGlucoseSheet,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DashboardHelper.buildActionBtn(
                        Icons.search, // Icona differente per la ricerca
                        "Cerca Cibo",
                        Colors.green, // Colore diverso per distinguerlo
                        onTap: _showFoodSearchbar, // Apre la ricerca Python
                      ),
                    ),
                    // const SizedBox(width: 10),
                    // Expanded(
                    //   child: _buildActionBtn(
                    //     Icons.edit_note,
                    //     "Manuale",
                    //     Colors.orange,
                    //     onTap: _showAddMealSheet, // Vecchio inserimento manuale
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // void _showAddMealSheet() {
  //   final TextEditingController mealController = TextEditingController();
  //   final TextEditingController carbsPer100Controller = TextEditingController();
  //   final TextEditingController weightController = TextEditingController();

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
  //     ),
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setSheetState) {
  //         // Il tasto si attiva solo se tutti i campi sono pieni
  //         bool isReady =
  //             mealController.text.isNotEmpty &&
  //             carbsPer100Controller.text.isNotEmpty &&
  //             weightController.text.isNotEmpty;

  //         return Padding(
  //           padding: EdgeInsets.only(
  //             bottom: MediaQuery.of(context).viewInsets.bottom,
  //             left: 20,
  //             right: 20,
  //             top: 20,
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               const Text(
  //                 "Registra Pasto 🥗",
  //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //               ),
  //               const SizedBox(height: 20),
  //               TextField(
  //                 controller: mealController,
  //                 onChanged: (_) => setSheetState(() {}),
  //                 decoration: const InputDecoration(
  //                   labelText: "Cosa hai mangiato?",
  //                   prefixIcon: Icon(Icons.restaurant),
  //                 ),
  //               ),
  //               const SizedBox(height: 15),
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: TextField(
  //                       controller: carbsPer100Controller,
  //                       onChanged: (_) => setSheetState(() {}),
  //                       keyboardType: TextInputType.number,
  //                       decoration: const InputDecoration(
  //                         labelText: "Carbo (x100g)",
  //                         prefixIcon: Icon(Icons.straighten),
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 15),
  //                   Expanded(
  //                     child: TextField(
  //                       controller: weightController,
  //                       onChanged: (_) => setSheetState(() {}),
  //                       keyboardType: TextInputType.number,
  //                       decoration: const InputDecoration(
  //                         labelText: "Grammi assunti",
  //                         prefixIcon: Icon(Icons.scale),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 30),
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(
  //                   minimumSize: const Size(double.infinity, 50),
  //                   backgroundColor: isReady ? Colors.orange : Colors.grey[300],
  //                 ),
  //                 onPressed: isReady
  //                     ? () {
  //                         double c100 =
  //                             double.tryParse(
  //                               carbsPer100Controller.text.replaceAll(',', '.'),
  //                             ) ??
  //                             0;
  //                         double weight =
  //                             double.tryParse(
  //                               weightController.text.replaceAll(',', '.'),
  //                             ) ??
  //                             0;
  //                         double totalCarbs = (c100 * weight) / 100;
  //                         double roundedCarbs = double.parse(
  //                           totalCarbs.toStringAsFixed(2),
  //                         );
  //                         _insertMealInLocal(mealController.text, roundedCarbs);

  //                         Navigator.pop(context);
  //                       }
  //                     : null,
  //                 child: const Text(
  //                   "SALVA NEL DIARIO",
  //                   style: TextStyle(color: Colors.white),
  //                 ),
  //               ),
  //               const SizedBox(height: 20),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  // Widget per i bottoni in basso

  // Aggiungi questi import se non ci sono
  // dashboard_screen.dart aggiornato
  void _showAddGlucoseSheet() {
    final PageController _pageController = PageController();
    final TextEditingController glucoseController = TextEditingController();
    final TextEditingController mealDescController = TextEditingController();
    final TextEditingController weightController = TextEditingController();
    final TextEditingController c100Controller = TextEditingController();
    final TextEditingController sugarCtrl = TextEditingController();
    final TextEditingController fatCtrl = TextEditingController();
    final TextEditingController protCtrl = TextEditingController();
    final TextEditingController fiberCtrl = TextEditingController();
    final TextEditingController noteCtrl = TextEditingController();

    MainEvent selectedEvent = MainEvent.controllo;
    EventTiming mealTiming = EventTiming.pre;
    int currentPage = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Validazione: tasto attivo solo se c'è un numero valido
          bool isGlucoseValid =
              glucoseController.text.trim().isNotEmpty &&
              double.tryParse(glucoseController.text) != null;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 1,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // --- ALTEZZA DINAMICA TRIPLA ---
                        maxHeight: currentPage == 0
                            ? 320
                            : (selectedEvent == MainEvent.pasto ? 850 : 420),
                      ),
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // PAGINA 1: GLICEMIA
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "NUOVA MISURAZIONE 🩸",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: glucoseController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setSheetState(() {}),
                                decoration: InputDecoration(
                                  labelText:
                                      "Valore glicemia ($_measurementUnit)",
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(
                                    Icons.bloodtype,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "SELEZIONA STATO",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 15),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  DashboardHelper.buildEventChip(
                                    setSheetState,
                                    MainEvent.digiuno,
                                    "Digiuno",
                                    Icons.wb_twilight,
                                    selectedEvent,
                                    (val) => setSheetState(
                                      () => selectedEvent = val,
                                    ),
                                  ),
                                  DashboardHelper.buildEventChip(
                                    setSheetState,
                                    MainEvent.pasto,
                                    "Pasto",
                                    Icons.restaurant,
                                    selectedEvent,
                                    (val) => setSheetState(
                                      () => selectedEvent = val,
                                    ),
                                  ),
                                  DashboardHelper.buildEventChip(
                                    setSheetState,
                                    MainEvent.sport,
                                    "Sport",
                                    Icons.fitness_center,
                                    selectedEvent,
                                    (val) => setSheetState(
                                      () => selectedEvent = val,
                                    ),
                                  ),
                                  DashboardHelper.buildEventChip(
                                    setSheetState,
                                    MainEvent.notte,
                                    "Notte",
                                    Icons.bedtime,
                                    selectedEvent,
                                    (val) => setSheetState(
                                      () => selectedEvent = val,
                                    ),
                                  ),
                                  DashboardHelper.buildEventChip(
                                    setSheetState,
                                    MainEvent.controllo,
                                    "Check",
                                    Icons.analytics,
                                    selectedEvent,
                                    (val) => setSheetState(
                                      () => selectedEvent = val,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  backgroundColor: !isGlucoseValid
                                      ? Colors.grey.shade300
                                      : Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                // ... dentro _showAddGlucoseSheet ...
                                onPressed: !isGlucoseValid
                                    ? null
                                    : () {
                                        if (selectedEvent == MainEvent.pasto ||
                                            selectedEvent == MainEvent.sport) {
                                          // Gestione pagine successive (continua come già avevi)
                                          setSheetState(() => currentPage = 1);
                                          _pageController.nextPage(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        } else {
                                          // --- MODIFICA QUI ---

                                          // 1. Prepariamo i dati
                                          final glucoseDataEntry = GlucoseEntry(
                                            userId: user_id,
                                            sugarValue:
                                                double.tryParse(
                                                  glucoseController.text
                                                      .replaceAll(',', '.'),
                                                ) ??
                                                0.0,
                                            recordedAt: DateTime.now(),
                                            sourceType: "Manual",
                                            event: selectedEvent.name,
                                          );

                                          // 2. Chiamiamo il controller
                                          controller.getGlucoseAdvice(
                                            context: context,
                                            glucoseDataEntry: glucoseDataEntry,
                                            onSuccess: (String advice) {
                                              // Chiudiamo il BottomSheet PRIMA di mostrare il consiglio
                                              Navigator.pop(context);

                                              setState(() {
                                                _lastGlucose =
                                                    glucoseDataEntry.sugarValue;
                                                _selectedPhase =
                                                    glucoseDataEntry.event;
                                                _userInsertAtLastOneMeasurement =
                                                    true;

                                                // Aggiorna l'orario dell'ultima misurazione
                                                DateTime now = DateTime.now();
                                                _lastGlucoseTime =
                                                    "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

                                                // Ricalcola lo stato (colore scheda) in automatico tramite build
                                              });

                                              // Mostriamo il Dialog usando il context della Dashboard
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext dialogContext) {
                                                  return AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    title: const Text(
                                                      "💡 Consiglio Alyra",
                                                    ),
                                                    content: Text(advice),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              dialogContext,
                                                            ),
                                                        child: const Text(
                                                          "HO CAPITO",
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        }
                                      },
                                child: Text(
                                  (selectedEvent == MainEvent.pasto ||
                                          selectedEvent == MainEvent.sport)
                                      ? "CONTINUA"
                                      : "CONSULTA",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // PAGINA 2: DETTAGLI (Differenziata)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () {
                                      setSheetState(() => currentPage = 0);
                                      _pageController.previousPage(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                  ),
                                  Text(
                                    selectedEvent == MainEvent.pasto
                                        ? "Dettagli Pasto 🍎"
                                        : "Dettagli Sport 🏃‍♂️",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Flexible(
                                child: SingleChildScrollView(
                                  child: selectedEvent == MainEvent.pasto
                                      ? DashboardHelper.buildMealForm(
                                          context,
                                          setSheetState,
                                          mealDescController,
                                          weightController,
                                          c100Controller,
                                          sugarCtrl,
                                          fatCtrl,
                                          protCtrl,
                                          fiberCtrl,
                                          mealTiming,
                                          (v) => setSheetState(
                                            () => mealTiming = v,
                                          ),
                                          selectedGI,
                                          (g) => setSheetState(
                                            () => selectedGI = g,
                                          ),
                                          noteCtrl,
                                        )
                                      : _buildSportForm(
                                          setSheetState,
                                          SportIntensity.media,
                                          (v) => {},
                                          EventTiming.pre,
                                          (v) => {},
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      55,
                                    ),
                                    backgroundColor: Colors.green[700],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    "CONFERMA E REGISTRA",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 3. Widget Modulo Sport (Vista 2 Dinamica)
  Widget _buildSportForm(
    StateSetter setSheetState, // Aggiunto per gestire i colori dei tasti
    SportIntensity intensity,
    Function(SportIntensity?) onIntensityChanged,
    EventTiming currentTiming,
    Function(EventTiming) onTimingChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Intensità attività:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        DropdownButton<SportIntensity>(
          value: intensity,
          isExpanded: true,
          items: SportIntensity.values
              .where((i) => i != SportIntensity.nessuna)
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(i.name.toUpperCase()),
                ),
              )
              .toList(),
          onChanged: onIntensityChanged,
        ),
        const SizedBox(height: 25),
        const Text(
          "Quando ti alleni?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // --- TASTI SPORT SEMPLICI ---
        Row(
          children: [
            // Tasto PRE-SPORT
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTiming == EventTiming.pre
                      ? Colors.green
                      : Colors.grey[200],
                  foregroundColor: currentTiming == EventTiming.pre
                      ? Colors.white
                      : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  setSheetState(() => onTimingChanged(EventTiming.pre));
                },
                child: const Text("INIZIO ORA"),
              ),
            ),
            const SizedBox(width: 10),
            // Tasto POST-SPORT
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTiming == EventTiming.post
                      ? Colors.teal
                      : Colors.grey[200],
                  foregroundColor: currentTiming == EventTiming.post
                      ? Colors.white
                      : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  setSheetState(() => onTimingChanged(EventTiming.post));
                },
                child: const Text("APPENA FINITO"),
              ),
            ),
          ],
        ),
      ],
    );
  }
  // Widget Helper per i Chip di selezione

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
