import 'package:flutter/material.dart';

class AdPlaceholder extends StatelessWidget {
  const AdPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: Text(
        'Ad placeholder',
        style: TextStyle(
          color: const Color(0xFF9CA3AF),
          fontSize: 12,
        ),
      ),
    );
  }
}
