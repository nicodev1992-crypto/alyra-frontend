import 'package:alyra_frontend/l10n/app_localizations.dart';
import 'package:alyra_frontend/services/meals_service.dart';
import 'package:flutter/material.dart';
import 'helper.dart'; // Importa l'helper per i colori

class DashboardWidgets {
  // dashboard_widgets.dart

static Widget buildProfileCard({
  required BuildContext context, // Aggiunto context per le traduzioni
  required StatusGlucoseType status,
  required String fullName,
  required String diabete,
  required String phoneNumber,
  required String email,
}) {
  final Color mainStatusColor = DashboardHelper.getStatusColor(status);
  final l10n = AppLocalizations.of(context)!; // Shortcut per le traduzioni

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // FOTO PROFILO A SINISTRA
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: mainStatusColor.withOpacity(0.3), 
              width: 2
            ),
          ),
          child: CircleAvatar(
            radius: 45,
            backgroundColor: mainStatusColor.withOpacity(0.1),
            child: Icon(Icons.person_rounded, size: 50, color: mainStatusColor),
          ),
        ),

        const SizedBox(width: 20),

        // DATI A DESTRA CON TRADUZIONI
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactInfoRow(Icons.person_outline, "${l10n.profileName}:", fullName, mainStatusColor),
              const SizedBox(height: 8),
              _buildCompactInfoRow(Icons.bloodtype_outlined, "${l10n.profileDiabetesType}:", diabete, Colors.redAccent),
              const SizedBox(height: 8),
              _buildCompactInfoRow(Icons.phone_android_outlined, "${l10n.profilePhone}:", phoneNumber, Colors.orange.shade700),
              const SizedBox(height: 8),
              _buildCompactInfoRow(Icons.alternate_email_outlined, "${l10n.profileEmail}:", email, Colors.purple.shade700),
            ],
          ),
        ),
      ],
    ),
  );
}

// Helper per le righe (rimane uguale ma compatto)
static Widget _buildCompactInfoRow(IconData icon, String label, String value, Color iconColor) {
  return Row(
    children: [
      Icon(icon, color: iconColor, size: 16),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          value.isNotEmpty ? value : "-",
          style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

  static Widget buildGlucoseCard({
    required StatusGlucoseType status,
    required String selectedPhase,
    required double lastGlucose,
    required String measurementUnit,
    required int targetMin,
    required int targetMax,
    required int hypoThreshold,
    required String? lastGlucoseMeasureTime,
    required bool userInsertAtLastOneMeasurement,
  }) {
    final Color mainColor = DashboardHelper.getStatusColor(status);

    // Controlliamo se la fase è valida
    bool hasPhase = selectedPhase != 'Null' && selectedPhase.isNotEmpty;

    if (userInsertAtLastOneMeasurement) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: mainColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: mainColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasPhase) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Phase: ${selectedPhase.toUpperCase()}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (lastGlucoseMeasureTime != null) ...[
              Text(
                "Time: $lastGlucoseMeasureTime",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 15),
            ],

            const Text(
              "ULTIMA MISURAZIONE",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),

            Text(
              "$lastGlucose",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              measurementUnit,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DashboardHelper.buildSmallInfoBadge(
                  Icons.track_changes,
                  "$targetMin - $targetMax",
                ),
                const SizedBox(width: 10),
                DashboardHelper.buildSmallInfoBadge(
                  Icons.notifications_active,
                  "Hypo: $hypoThreshold",
                ),
              ],
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    DashboardHelper.getStatusIcon(status),
                    color: mainColor,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    status.descrizione,
                    style: TextStyle(
                      color: mainColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Caso: Nessuna misurazione inserita
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: mainColor.withOpacity(0.2), width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.opacity, color: mainColor.withOpacity(0.5), size: 48),
          const SizedBox(height: 16),
          const Text(
            "Pronto per la prima misurazione?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Inserisci il tuo livello di glicemia.",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Widget per l'allerta cibi
  static Widget buildFoodAlertCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: const ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: Text("Pasto consigliato ora"),
        subtitle: Text(
          "Verdure a foglia verde o proteine magre. Evita succhi di frutta.",
        ),
      ),
    );
  }

  static Widget buildFoodAdviceCard() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text(
        "Consigli Alimentari 💡",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget buildFoodSearchField({
    required Function(Map<String, dynamic>) onFoodSelected,
  }) {
    return Autocomplete<Map<String, dynamic>>(
      // 1. Cosa viene mostrato nel campo di testo dopo la selezione
      displayStringForOption: (option) => option['name'],

      // 2. Logica di ricerca (interroga Python)
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 2) {
          return const Iterable<Map<String, dynamic>>.empty();
        }
        // Chiama il metodo searchFood che abbiamo aggiunto nel GlucoseService
        return await MealsService.searchFood(textEditingValue.text);
      },

      // 3. Cosa succede quando l'utente clicca su un suggerimento
      onSelected: (Map<String, dynamic> selection) {
        onFoodSelected(selection);
      },

      // 4. Personalizzazione dell'aspetto del campo di ricerca
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: "Cerca alimento...",
            hintText: "Es: Pasta, Mela, Pizza",
            prefixIcon: const Icon(Icons.search, color: Colors.orange),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        );
      },

      // 5. Personalizzazione della lista dei suggerimenti (la tendina)
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width:
                  MediaQuery.of(context).size.width - 40, // Adatta la larghezza
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option['name']),
                    subtitle: Text("${option['carbs']}g carbo per 100g"),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
