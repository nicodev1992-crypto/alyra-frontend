// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get situazioneAttuale => 'Glicemia:';

  @override
  String fase(Object f) {
    return 'FASE: $f';
  }

  @override
  String get inTarget => 'In Target';

  @override
  String get glicemiaBassa => 'Glicemia Bassa';

  @override
  String get profileName => 'Nome';

  @override
  String get profileDiabetesType => 'Tipo';

  @override
  String get profilePhone => 'Tel';

  @override
  String get profileEmail => 'Email';

  @override
  String get noMeasurementTitle => 'Nessun dato oggi';

  @override
  String get noMeasurementSubtitle => 'Inserisci la tua prima glicemia';

  @override
  String get targetLabel => 'Target';

  @override
  String get lastMeasurementTitle => 'Ultima misurazione';

  @override
  String get glucoseLow => 'Bassa';

  @override
  String get glucoseInTarget => 'In Target';

  @override
  String get glucoseHigh => 'Alta';

  @override
  String get glucoseCritic => 'Critica';

  @override
  String get step2Title => 'Passo 2: Dati Medici';

  @override
  String get targetMin => 'Target Min *';

  @override
  String get targetMax => 'Target Max *';

  @override
  String get calcParams => 'Parametri Calcolo';

  @override
  String get targetIdeal => 'Target Ideale (mg/dL)';

  @override
  String get icRatio => 'Rapporto I/C';

  @override
  String get isf => 'Sensibilità (ISF)';

  @override
  String get insDuration => 'Durata Insulina';

  @override
  String get ketoneThreshold => 'Soglia Chetoni';

  @override
  String get hypoThreshold => 'Soglia di ipoglicemia';

  @override
  String get optional => '(opzionale)';

  @override
  String get optShort => '(opz.)';

  @override
  String get measurementUnit => 'Unità di Misura *';

  @override
  String get diabetesType => 'Tipo Diabete *';

  @override
  String get diabetesNotes => 'Note Diabete (opzionale)';

  @override
  String get completeReg => 'Completa Registrazione';

  @override
  String get validationError => 'Compila i campi richiesti per il tipo di diabete selezionato';

  @override
  String get back => 'Indietro';

  @override
  String get diabetesType_type1 => 'Tipo 1';

  @override
  String get diabetesType_type2 => 'Tipo 2';

  @override
  String get diabetesType_gestational => 'Gestazionale';

  @override
  String get diabetesType_lada => 'LADA';

  @override
  String get diabetesType_other => 'Altro';
}
