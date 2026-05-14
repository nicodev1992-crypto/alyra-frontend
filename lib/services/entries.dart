
// Modello per la sola Glicemia
class GlucoseEntry {
  final int userId;
  final double sugarValue;
  final DateTime recordedAt;
  final String sourceType;
  final String event;

  GlucoseEntry({
    required this.userId,
    required this.sugarValue,
    required this.recordedAt,
    required this.sourceType,
    required this.event
  });

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "sugar_value": sugarValue,
    "phase": event,
    "source_type": sourceType,
    "recorded_at": recordedAt.toIso8601String(),
  };
}


// Modello per il Pasto (con il campo insulina che abbiamo detto!)
class MealEntry {
  final int userId;
  final double carbsGrams;
  final double insulinUnits; // Fondamentale per T1D
  final String description;
  final DateTime consumedAt;

  MealEntry({
    required this.userId,
    required this.carbsGrams,
    required this.insulinUnits,
    required this.description,
    required this.consumedAt,
  });

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "carbs_grams": carbsGrams,
    "insulin_units": insulinUnits,
    "description": description,
    "consumed_at": consumedAt.toIso8601String(),
  };
}

enum StatusGlucoseType { LOW, TARGET, HIGH, CRITIC }

// L'evento principale che l'utente sta vivendo
enum MainEvent {
  digiuno, // Fase di riposo (stabilità della basale)
  pasto, // Determina il calcolo dei carboidrati e dell'insulina
  sport, // Determina il consumo di zuccheri e la sensibilità insulinica
  controllo, // Semplice check o correzione di un valore alto (iperglicemia)
  notte,
}

// Fondamentale per le previsioni: "Sto per..." o "Ho appena..."
enum EventTiming {
  pre, // PREDITTIVO: L'evento deve ancora influenzare il sangue
  post, // ANALITICO: L'evento ha già influenzato il sangue
  nessuno, // Per controlli neutri o momenti di stabilità
}

// Per lo sport, serve l'intensità per prevedere il calo
enum SportIntensity {
  bassa, // Es. Passeggiata (calo lento)
  media, // Es. Corsa/Bici (calo costante)
  alta,
  nessuna, // Es. Palestra/Scatti (possibile rialzo iniziale, poi calo forte)
}
