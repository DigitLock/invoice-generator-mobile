import 'package:flutter/material.dart';

class AdPlaceholder extends StatelessWidget {
  const AdPlaceholder({super.key});

  /// Set this to true once google_mobile_ads is integrated (Stage 4.6).
  static const bool _adsEnabled = false;

  @override
  Widget build(BuildContext context) {
    if (!_adsEnabled) return const SizedBox.shrink();

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
