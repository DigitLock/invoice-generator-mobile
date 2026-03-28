import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  static const _config = {
    'draft': _BadgeColors(Color(0xFFF3F4F6), Color(0xFF374151)),
    'sent': _BadgeColors(Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'partially_paid': _BadgeColors(Color(0xFFFFF7ED), Color(0xFFC2410C)),
    'paid': _BadgeColors(Color(0xFFDCFCE7), Color(0xFF15803D)),
    'cancelled': _BadgeColors(Color(0xFFFEE2E2), Color(0xFFB91C1C)),
  };

  static String _label(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Sent';
      case 'partially_paid':
        return 'Partially Paid';
      case 'paid':
        return 'Paid';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _config[status] ??
        const _BadgeColors(Color(0xFFF3F4F6), Color(0xFF374151));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: colors.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BadgeColors {
  final Color background;
  final Color foreground;
  const _BadgeColors(this.background, this.foreground);
}
