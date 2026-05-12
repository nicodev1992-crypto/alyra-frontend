import 'package:alyra_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart'; // Fondamentale per usare 'Color' e 'Colors'

enum StatusGlucoseType { LOW, TARGET, HIGH, CRITIC }

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
}
