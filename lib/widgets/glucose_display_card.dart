import 'package:flutter/material.dart';

class GlucoseDisplayCard extends StatelessWidget {
  final double value;
  final String status;
  final String unit;
  final Color color;

  const GlucoseDisplayCard({
    super.key, 
    required this.value, 
    required this.status, 
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)],
      ),
      child: Column(
        children: [
          const Text("ULTIMA MISURAZIONE", style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text("$value", style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
          Text(unit, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}