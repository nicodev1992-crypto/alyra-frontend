// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get situazioneAttuale => 'Current Situation:';

  @override
  String fase(Object phase) {
    return 'Phase: $phase';
  }

  @override
  String get inTarget => 'In Target';

  @override
  String get glicemiaBassa => 'Low Glucose';

  @override
  String get profileName => 'Name';

  @override
  String get profileDiabetesType => 'Type';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileEmail => 'Email';
}
