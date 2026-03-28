import 'package:flutter/material.dart';

class OverdueBadge extends StatelessWidget {
  const OverdueBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Overdue',
        style: TextStyle(
          color: Color(0xFFB91C1C),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
