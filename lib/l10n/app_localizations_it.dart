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
  String fase(Object phase) {
    return 'Fase: $phase';
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
}
