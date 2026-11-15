import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_language.dart';
import '../customer/mission_model.dart';

TextStyle pop({
  double? size,
  FontWeight? weight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

String tr(String en, String ar, String fr) {
  final lang = appLanguage.lang;
  if (lang == 'AR') return ar;
  if (lang == 'FR') return fr;
  return en;
}

/// Parses an estimated price like `4,500` (or `4500`) into a number.
double parseDzd(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(cleaned) ?? 0;
}

/// Formats a number with thousands separators: `4500` -> `4,500`.
String formatDzd(double v) {
  if (v == v.roundToDouble()) {
    final s = v.toInt().toString();
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
  return v.toStringAsFixed(2);
}

class BossStatusInfo {
  final Color color;
  final Color bg;
  final String label;
  const BossStatusInfo(this.color, this.bg, this.label);
}

/// Status badge colors reused from the rest of the app.
///
/// The Boss dashboard uses the same palette as the customer/driver side and
/// labels the accepted state as "Confirmed" to match the admin specs.
BossStatusInfo bossStatusInfo(MissionStatus s) {
  switch (s) {
    case MissionStatus.pending:
      return BossStatusInfo(
        const Color(0xFF9E9E9E),
        const Color(0xFFF5F5F5),
        tr('Pending', 'قيد الانتظار', 'En attente'),
      );
    case MissionStatus.searching:
      return BossStatusInfo(
        const Color(0xFF2196F3),
        const Color(0xFFE3F2FD),
        tr('Searching', 'بحث', 'Recherche'),
      );
    case MissionStatus.accepted:
      return BossStatusInfo(
        const Color(0xFFF5A524),
        const Color(0xFFFFF3E0),
        tr('Confirmed', 'مؤكدة', 'Confirmée'),
      );
    case MissionStatus.inProgress:
      return BossStatusInfo(
        const Color(0xFF3F51B5),
        const Color(0xFFE8EAF6),
        tr('In Progress', 'قيد التنفيذ', 'En cours'),
      );
    case MissionStatus.completed:
      return BossStatusInfo(
        const Color(0xFF4CAF50),
        const Color(0xFFE8F5E9),
        tr('Completed', 'مكتملة', 'Terminée'),
      );
    case MissionStatus.cancelled:
      return BossStatusInfo(
        const Color(0xFFEF4444),
        const Color(0xFFFFEBEE),
        tr('Cancelled', 'ملغاة', 'Annulée'),
      );
  }
}

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

Color avatarColor(int index) {
  const colors = [
    Color(0xFFF5A524),
    Color(0xFF3F51B5),
    Color(0xFF4CAF50),
    Color(0xFFE53935),
    Color(0xFF00897B),
    Color(0xFF8E24AA),
  ];
  return colors[index % colors.length];
}
