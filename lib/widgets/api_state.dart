import 'package:flutter/material.dart';

import '../app_language.dart';
import '../models/api_models.dart';
import 'app_text_style.dart';

String _tr(String en, String ar, String fr) {
  final lang = appLanguage.lang;
  if (lang == 'AR') return ar;
  if (lang == 'FR') return fr;
  return en;
}

TextStyle _pop({double? size, FontWeight? weight, Color? color}) =>
    appPop(size: size, weight: weight, color: color);

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
                _tr('Something went wrong', 'حدث خطأ ما', 'Une erreur est survenue'),
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
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  decoration: BoxDecoration(
                    color: _amber,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(_tr('Retry', 'إعادة المحاولة', 'Réessayer'),
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

/// Shows a SnackBar with a normalized API error message.
void showApiError(BuildContext context, dynamic error) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  showApiErrorWithMessenger(messenger, error);
}

/// Error snackbar variant safe to call after an `await`: capture the
/// [ScaffoldMessengerState] before the async gap and pass it here, so no
/// [BuildContext] is used across the gap.
void showApiErrorWithMessenger(ScaffoldMessengerState messenger, dynamic error) {
  final message = apiErrorMessage(error);
  _snack(messenger, message, const Color(0xFFE0533D));
}

/// Green success snackbar, also safe to use after an `await`.
void showSuccessWithMessenger(ScaffoldMessengerState messenger, String message) {
  _snack(messenger, message, const Color(0xFF4CAF50));
}

void _snack(ScaffoldMessengerState messenger, String message, Color color) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: _pop(size: 13, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
}
