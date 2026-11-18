import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/api_models.dart';

TextStyle _pop({double? size, FontWeight? weight, Color? color}) =>
    GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color);

const _amber = Color(0xFFF5A524);

/// Formats a numeric amount with thousands separators (e.g. 15000 -> 15,000).
String formatDzd(num amount) {
  final rounded = amount.round();
  final sign = rounded < 0 ? '-' : '';
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '$sign$buffer';
}

/// Compact centered spinner used while an API call is in flight.
class ApiLoadingView extends StatelessWidget {
  final String? message;
  const ApiLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _amber, strokeWidth: 3),
            if (message != null) ...[
              const SizedBox(height: 14),
              Text(message!, style: _pop(size: 13, color: const Color(0xFF777777))),
            ],
          ],
        ),
      );
}

/// Error state with a user-friendly message and a retry button.
class ApiErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ApiErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded,
                    color: _amber, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF222222)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: _pop(size: 13, color: const Color(0xFF777777)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                  decoration: BoxDecoration(
                    color: _amber,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('Retry',
                      style: _pop(
                          size: 13,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Amber banner shown when the app is displaying offline demo data because
/// the backend could not be reached.
class DemoWarningBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const DemoWarningBanner({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3DC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 17, color: Color(0xFFB87600)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Offline demo data — the backend is unreachable. '
                'Showing sample data; retry to load live information.',
                style: _pop(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFF8A5B00)),
              ),
            ),
            GestureDetector(
              onTap: onRetry,
              child: const Icon(Icons.refresh, size: 17, color: Color(0xFFB87600)),
            ),
          ],
        ),
      );
}

/// Shows a SnackBar with a normalized API error message.
void showApiError(BuildContext context, dynamic error) {
  final message = apiErrorMessage(error);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: _pop(size: 13, color: Colors.white)),
        backgroundColor: const Color(0xFFE0533D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
}
