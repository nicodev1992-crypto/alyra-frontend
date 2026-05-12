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
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: mainStatusColor.withOpacity(0.1),
              child: Icon(
                Icons.person_rounded,
                size: 50,
                color: mainStatusColor,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // DATI A DESTRA CON TRADUZIONI
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactInfoRow(
                  Icons.person_outline,
                  "${l10n.profileName}:",
                  fullName,
                  mainStatusColor,
                ),
                const SizedBox(height: 8),
                _buildCompactInfoRow(
                  Icons.bloodtype_outlined,
                  "${l10n.profileDiabetesType}:",
                  diabete,
                  Colors.redAccent,
                ),
                const SizedBox(height: 8),
                _buildCompactInfoRow(
                  Icons.phone_android_outlined,
                  "${l10n.profilePhone}:",
                  phoneNumber,
                  Colors.orange.shade700,
                ),
                const SizedBox(height: 8),
                _buildCompactInfoRow(
                  Icons.alternate_email_outlined,
                  "${l10n.profileEmail}:",
                  email,
                  Colors.purple.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper per le righe (rimane uguale ma compatto)
  static Widget _buildCompactInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : "-",
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget buildGlucoseCard({
    required BuildContext context,
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
    final l10n = AppLocalizations.of(context)!;

    // LOGICA DI ALLERTA CRITICA
    final bool isHypo = lastGlucose <= hypoThreshold;
    final Color mainColor = isHypo
        ? Colors.red.shade800
        : DashboardHelper.getStatusColor(status);
    bool hasPhase = selectedPhase != 'Null' && selectedPhase.isNotEmpty;

    if (!userInsertAtLastOneMeasurement) {
      return _buildEmptyGlucoseCard(
        l10n,
        DashboardHelper.getStatusColor(status),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // RIGA SUPERIORE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasPhase)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.fase(selectedPhase.toUpperCase()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (lastGlucoseMeasureTime != null)
                Text(
                  lastGlucoseMeasureTime,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // TITOLO O MESSAGGIO DI EMERGENZA
          Text(
            isHypo
                ? "ATTENZIONE: IPOGLICEMIA!"
                : l10n.lastMeasurementTitle.toUpperCase(),
            style: TextStyle(
              color: isHypo ? Colors.white : Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w900, // Più marcato se in hypo
              letterSpacing: 1.2,
            ),
          ),

          // VALORE CENTRALE CON ICONA DI ALLARME SE IN HYPO
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isHypo)
                const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              if (isHypo) const SizedBox(width: 10),
              Text(
                "$lastGlucose",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                measurementUnit,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // BARRA INFO
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHypo
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // STATO (Es: Glicemia Bassa)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isHypo
                              ? Icons.emergency_share
                              : DashboardHelper.getStatusIcon(status),
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          // <--- Aggiungi questo
                          child: Text(
                            DashboardHelper.getStatusText(context, status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow
                                .ellipsis, // Aggiunge i puntini di sospensione se il testo è troppo lungo
                            maxLines: 1, // Mantiene il testo su una riga sola
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(color: Colors.white24, thickness: 1),
                  // TARGET
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          "TARGET",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$targetMin-$targetMax",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(color: Colors.white24, thickness: 1),
                  // HYPO (ROSSO SE ATTIVO)
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          "HYPO",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "<$hypoThreshold",
                          style: TextStyle(
                            color: isHypo ? Colors.yellowAccent : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget per il caso "Nessuna misurazione" (Modernizzato)
  static Widget _buildEmptyGlucoseCard(AppLocalizations l10n, Color mainColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: mainColor.withOpacity(0.1), width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bubble_chart_outlined,
            color: mainColor.withOpacity(0.4),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noMeasurementTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            l10n.noMeasurementSubtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
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
