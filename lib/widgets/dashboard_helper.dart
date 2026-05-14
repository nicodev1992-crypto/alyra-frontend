import 'package:alyra_frontend/l10n/app_localizations.dart';
import 'package:alyra_frontend/services/entries.dart';
import 'package:flutter/material.dart'; // Fondamentale per usare 'Color' e 'Colors'


class DashboardHelper {
  static String getStatusText(BuildContext context, StatusGlucoseType status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case StatusGlucoseType.LOW:
        return l10n.glucoseLow;
      case StatusGlucoseType.TARGET:
        return l10n.glucoseInTarget;
      case StatusGlucoseType.HIGH:
        return l10n.glucoseHigh;
      case StatusGlucoseType.CRITIC:
        return l10n.glucoseCritic;
      default:
        return "";
    }
  }

  // Aggiungi 'String status' come parametro
  static Color getStatusColor(StatusGlucoseType status) {
    switch (status) {
      case StatusGlucoseType.CRITIC:
        return Colors.redAccent.shade700;
      case StatusGlucoseType.LOW:
        return Colors.orange;
      case StatusGlucoseType.HIGH:
        return Colors.amber;
      case StatusGlucoseType.TARGET:
        return Colors.green;
    }
  }

  // Puoi spostare qui anche l'icona
  static IconData getStatusIcon(StatusGlucoseType status) {
    if (status == StatusGlucoseType.TARGET) return Icons.check_circle_outline;
    return Icons.warning_amber_rounded;
  }

  // Helper per i tag (Età e Tipo Diabete)
  static Widget buildSmallTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static StatusGlucoseType setStatus(
    double lastGlucoseValue,
    int targetMin,
    int targetMax,
    int hypoThreshold,
  ) {
    StatusGlucoseType status;

    if (lastGlucoseValue < targetMin) {
      status = StatusGlucoseType.LOW;
    } else if (lastGlucoseValue < hypoThreshold) {
      status = StatusGlucoseType.CRITIC;
    } else if (lastGlucoseValue > targetMax) {
      status = StatusGlucoseType.HIGH;
    } else {
      status = StatusGlucoseType.TARGET;
    }

    return status;
  }

  // Metodo helper privato (sempre dentro DashboardWidgets)
  static Widget buildSmallInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  static Widget buildActionBtn(
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

  static Widget buildEventChip(
    StateSetter setSheetState,
    MainEvent event,
    String label,
    IconData icon,
    MainEvent current,
    Function(MainEvent) onSelected,
  ) {
    bool isSelected = current == event;

    return ChoiceChip(
      showCheckmark: false, // <--- QUESTO RIMUOVE IL SEGNO DI SPUNTA
      label: Text(label),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : Colors.blue,
      ),
      selected: isSelected,
      onSelected: (v) {
        if (v) {
          setSheetState(() {
            onSelected(event);
          });
        }
      },
      // Colore quando è selezionato (Sfondo Blu, Testo Bianco)
      selectedColor: Colors.blue,
      // Colore quando NON è selezionato (Sfondo Grigino/Bianco)
      backgroundColor: Colors.white,
      // Bordo sottile per definire meglio i tasti non cliccati
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  static Widget buildMealForm(
    BuildContext context,
    StateSetter setSheetState,
    TextEditingController descCtrl,
    TextEditingController weightCtrl,
    TextEditingController c100Ctrl,
    TextEditingController sugarCtrl,
    TextEditingController fatCtrl,
    TextEditingController protCtrl,
    TextEditingController fiberCtrl,
    EventTiming currentTiming,
    Function(EventTiming) onTimingChanged,
    // Nuovi parametri suggeriti
    String selectedGI,
    Function(String) onGIChanged,
    TextEditingController noteCtrl,
  ) {
    double calcolaGrammi(TextEditingController ctrl) {
      double peso = double.tryParse(weightCtrl.text) ?? 0;
      double valore100 = double.tryParse(ctrl.text) ?? 0;
      return (peso * valore100) / 100;
    }

    double totalCarbs = calcolaGrammi(c100Ctrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: descCtrl,
          decoration: const InputDecoration(
            labelText: "Nome alimento: (es. Pasta al pomodoro)",
            prefixIcon: Icon(Icons.description_outlined),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setSheetState(() {}),
                decoration: const InputDecoration(
                  labelText: "Peso (g)",
                  prefixIcon: Icon(Icons.scale),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: c100Ctrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setSheetState(() {}),
                decoration: const InputDecoration(
                  labelText: "Carbo/100g",
                  prefixIcon: Icon(Icons.breakfast_dining),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Text(
          "Altri nutrienti per 100g (opzionale):",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: sugarCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setSheetState(() {}),
                decoration: const InputDecoration(
                  labelText: "Zuccheri",
                  labelStyle: TextStyle(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: TextField(
                controller: fatCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setSheetState(() {}),
                decoration: const InputDecoration(
                  labelText: "Grassi",
                  labelStyle: TextStyle(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: TextField(
                controller: protCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setSheetState(() {}),
                decoration: const InputDecoration(
                  labelText: "Proteine",
                  labelStyle: TextStyle(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: TextField(
                controller: fiberCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setSheetState(() {}),
                decoration: const InputDecoration(
                  labelText: "Fibre",
                  labelStyle: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              "Indice Glicemico stimato:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () =>
                  _showGIGuide(context), // Apre il popup di spiegazione
              child: Icon(
                Icons.help_outline,
                size: 20,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGIChip(
              setSheetState,
              "Lento",
              Colors.green,
              selectedGI,
              onGIChanged,
            ),
            _buildGIChip(
              setSheetState,
              "Medio",
              Colors.orange,
              selectedGI,
              onGIChanged,
            ),
            _buildGIChip(
              setSheetState,
              "Veloce",
              Colors.red,
              selectedGI,
              onGIChanged,
            ),
          ],
        ),
        // Testo descrittivo dinamico sotto i tasti
        Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Text(
            selectedGI == "Lento"
                ? "🟢 Ideale: assorbimento lento, meno rischio di picchi."
                : selectedGI == "Medio"
                ? "🟡 Moderato: salita costante della glicemia."
                : "🔴 Attenzione: salita molto rapida. Valuta anticipo insulina.",
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(
            labelText: "Note (es. Cena fuori, pizza difficile)",
            prefixIcon: Icon(Icons.sticky_note_2_outlined),
          ),
        ),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                "CARBOIDRATI TOTALI",
                "${totalCarbs.toStringAsFixed(1)} g",
                Colors.orange[800]!,
              ),
              const Divider(),
              _buildSummaryRow(
                "di cui Zuccheri",
                "${calcolaGrammi(sugarCtrl).toStringAsFixed(1)} g",
                Colors.red[400]!,
              ),
              _buildSummaryRow(
                "Grassi",
                "${calcolaGrammi(fatCtrl).toStringAsFixed(1)} g",
                Colors.blueGrey,
              ),
              _buildSummaryRow(
                "Proteine",
                "${calcolaGrammi(protCtrl).toStringAsFixed(1)} g",
                Colors.blue,
              ),
              _buildSummaryRow(
                "Fibre",
                "${calcolaGrammi(fiberCtrl).toStringAsFixed(1)} g",
                Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "IN CHE MOMENTO SEI?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTiming == EventTiming.pre
                      ? Colors.orange
                      : Colors.grey[200],
                  foregroundColor: currentTiming == EventTiming.pre
                      ? Colors.white
                      : Colors.black,
                ),
                onPressed: () =>
                    setSheetState(() => onTimingChanged(EventTiming.pre)),
                child: const Text("PRE-PASTO"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTiming == EventTiming.post
                      ? Colors.orange
                      : Colors.grey[200],
                  foregroundColor: currentTiming == EventTiming.post
                      ? Colors.white
                      : Colors.black,
                ),
                onPressed: () =>
                    setSheetState(() => onTimingChanged(EventTiming.post)),
                child: const Text("POST-PASTO"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget per le righe del riepilogo
  static Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Funzione per il popup con esempi reali
  static void _showGIGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Guida Indice Glicemico"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuidelineRow(
                Colors.green,
                "LENTO",
                "Legumi, pasta integrale, verdure, noci, yogurt greco.",
              ),
              const SizedBox(height: 12),
              _buildGuidelineRow(
                Colors.orange,
                "MEDIO",
                "Pasta al dente, pane di segale, frutta fresca, riso basmati.",
              ),
              const SizedBox(height: 12),
              _buildGuidelineRow(
                Colors.red,
                "VELOCE",
                "Riso bianco, pizza, patate, dolci, succhi, zucchero bianco.",
              ),
              const Divider(height: 30),
              const Text(
                "💡 Trucco: Grassi e fibre (es. olio o insalata) 'rallentano' l'assorbimento dei carboidrati.",
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("HO CAPITO"),
          ),
        ],
      ),
    );
  }

  static Widget _buildGuidelineRow(Color color, String label, String examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          examples,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

  static Widget _buildGIChip(
    StateSetter setSheetState,
    String label,
    Color color,
    String selected,
    Function(String) onSelect,
  ) {
    bool isSelected = selected == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setSheetState(() => onSelect(label));
      },
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? color : Colors.grey[300]!),
      ),
    );
  }
}
