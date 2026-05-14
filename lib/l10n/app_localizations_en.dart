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

  @override
  String fase(String f) {
    return 'PHASE: $f';
  }

  @override
  String get noMeasurementTitle => 'No data today';

  @override
  String get noMeasurementSubtitle => 'Enter your first glucose level';

  @override
  String get targetLabel => 'Target';

  @override
  String get lastMeasurementTitle => 'Last measurement';

  @override
  String get glucoseLow => 'Low';

  @override
  String get glucoseInTarget => 'In Target';

  @override
  String get glucoseHigh => 'High';

  @override
  String get glucoseCritic => 'Critical';

  @override
  String get step2Title => 'Step 2: Medical Data';

  @override
  String get targetMin => 'Min Target *';

  @override
  String get targetMax => 'Max Target *';

  @override
  String get calcParams => 'Calculation Parameters';

  @override
  String get targetIdeal => 'Ideal Target (mg/dL)';

  @override
  String get icRatio => 'I/C Ratio';

  @override
  String get isf => 'Sensitivity (ISF)';

  @override
  String get insDuration => 'Insulin Duration';

  @override
  String get ketoneThreshold => 'Ketone Threshold';

  @override
  String get hypoThreshold => 'Hypoglycemia Threshold';

  @override
  String get optional => '(optional)';

  @override
  String get optShort => '(opt.)';

  @override
  String get measurementUnit => 'Unit of Measurement *';

  @override
  String get diabetesType => 'Diabetes Type *';

  @override
  String get diabetesNotes => 'Diabetes Notes (optional)';

  @override
  String get completeReg => 'Complete Registration';

  @override
  String get validationError => 'Please fill in the required fields for the selected diabetes type';

  @override
  String get back => 'Back';

  @override
  String get diabetesType_type1 => 'Type 1';

  @override
  String get diabetesType_type2 => 'Type 2';

  @override
  String get diabetesType_gestational => 'Gestational';

  @override
  String get diabetesType_lada => 'LADA';

  @override
  String get diabetesType_other => 'Other';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginButton => 'Sign In';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get errorEmptyFields => 'Please fill in all fields';

  @override
  String get errorLogin => 'Invalid email or password';

  @override
  String get errorConnection => 'Connection error';

  @override
  String get privacyAgreement => 'I agree to the privacy policy and medical data processing';

  @override
  String get privacyLink => 'Read policy';

  @override
  String get privacyError => 'You must read and accept the privacy policy to continue';

  @override
  String get privacyPolicyTitle => 'Privacy Policy and Medical Data';

  @override
  String get privacyPolicyContent => '1. DATA CONTROLLER\nAlyra app is a personal project. Data is processed for diabetes management support purposes.\n\n2. DATA PROCESSED\nWe process personal data (email, name) and sensitive data (blood glucose, carbs, insulin dosages).\n\n3. STORAGE\nData is stored on Render servers and in the phone\'s local database. You can delete them at any time by deleting your account.\n\n4. LIABILITY\nAlyra provides calculations based on your input parameters. It DOES NOT replace medical advice. Use of suggestions is at your own risk.';

  @override
  String get privacyCloseButton => 'I have read and understood';

  @override
  String get welcomeTitle => 'Alyra';

  @override
  String get welcomeSubtitle => 'Your Smart Diabetes Assistant';

  @override
  String get welcomeStartButton => 'GET STARTED';

  @override
  String get welcomeLoginButton => 'I ALREADY HAVE AN ACCOUNT';
}
