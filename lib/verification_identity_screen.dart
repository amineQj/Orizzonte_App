import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'app_language.dart';

TextStyle _pop({double? size, FontWeight? weight, Color? color, double? height, double? letterSpacing}) {
  return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);
}

class VerificationIdentityScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;
  const VerificationIdentityScreen({super.key, required this.onComplete, required this.onBack});

  @override
  State<VerificationIdentityScreen> createState() => _VerificationIdentityScreenState();
}

class _VerificationIdentityScreenState extends State<VerificationIdentityScreen> {
  File? _frontImage;
  File? _backImage;
  bool _processing = false;

  String get _lang => appLanguage.lang;
  bool get _isArabic => _lang == 'AR';

  String _t(String en, String ar, String fr) {
    if (_isArabic) return ar;
    if (_lang == 'FR') return fr;
    return en;
  }

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
    if (picked != null) {
      final file = File(picked.path);
      final error = await _validateImage(file);
      if (!mounted) return;
      if (error != null) {
        _showRejectionDialog(error);
        return;
      }
      _showPreview(file, isFront);
    }
  }

  Future<String?> _validateImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      image.dispose();

      if (width < 400 || height < 300) {
        return _t('Image resolution is too low. Please retake with better quality.', 'دقة الصورة منخفضة جداً. أعد التصوير بجودة أفضل.', 'La résolution est trop basse. Réessayez avec une meilleure qualité.');
      }

      final byteData = await _getPixelData(file);
      if (byteData != null) {
        final brightness = _calculateBrightness(byteData);
        if (brightness < 30) {
          return _t('Image is too dark. Please retake with better lighting.', 'الصورة مظلمة جداً. أعد التصوير بإضاءة أفضل.', 'L\'image est trop sombre. Réessayez avec un meilleur éclairage.');
        }
        if (brightness > 220) {
          return _t('Image is overexposed. Please retake with less glare.', 'الصورة مفرطة في الإضاءة. أعد التصوير بدون وهج.', 'L\'image est surexposée. Réessayez sans éblouissement.');
        }
      }

      return null;
    } catch (_) {
      return _t('Failed to process image. Please retake.', 'فشل في معالجة الصورة. أعد المحاولة.', 'Échec du traitement. Réessayez.');
    }
  }

  Future<ByteData?> _getPixelData(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 100, targetHeight: 100);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return byteData;
    } catch (_) {
      return null;
    }
  }

  double _calculateBrightness(ByteData data) {
    final bytes = data.buffer.asUint8List();
    final pixelCount = data.lengthInBytes ~/ 4;
    if (pixelCount == 0) return 128;
    double totalBrightness = 0;
    for (int i = 0; i < bytes.length; i += 4) {
      final r = bytes[i].toDouble();
      final g = bytes[i + 1].toDouble();
      final b = bytes[i + 2].toDouble();
      totalBrightness += (0.299 * r + 0.587 * g + 0.114 * b);
    }
    return totalBrightness / pixelCount;
  }

  void _showRejectionDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.error_outline, size: 32, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            Text(_t('Image Rejected', 'تم رفض الصورة', 'Image rejetée'),
              style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
              style: _pop(size: 13, color: const Color(0xFF666666), height: 1.5)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFFF5A524), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(_t('Got it', 'حسناً', 'Compris'),
                  style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreview(File image, bool isFront) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(_t('Preview & Confirm', 'معاينة وتأكيد', 'Aperçu et confirmation'),
                style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(image, width: double.infinity, height: double.infinity, fit: BoxFit.contain),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _PreviewOverlayPainter()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(child: Text(_t('Retake', 'إعادة', 'Reprendre'),
                            style: _pop(size: 14, weight: FontWeight.w700, color: const Color(0xFF555555)))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            if (isFront) { _frontImage = image; }
                            else { _backImage = image; }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 3))],
                          ),
                          child: Center(child: Text(_t('Accept', 'قبول', 'Accepter'),
                            style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (_frontImage == null || _backImage == null) return;
    setState(() => _processing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _processing = false);
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bothUploaded = _frontImage != null && _backImage != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.badge_outlined, size: 36, color: Color(0xFFF5A524)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(_t('Identity Verification', 'التحقق من الهوية', 'Vérification d\'identité'),
              style: _pop(size: 18, weight: FontWeight.w700, color: const Color(0xFF111111))),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _t('Scan both sides of your national ID card', 'مسح картتي الهوية الوطنية من كلا الوجهين', 'Scannez les deux faces de votre carte nationale d\'identité'),
              textAlign: TextAlign.center,
              style: _pop(size: 13, color: const Color(0xFF999999), height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          _buildScanCard(
            label: _t('Front of ID', 'وجه البطاقة', 'Recto de la carte'),
            image: _frontImage,
            icon: Icons.credit_card,
            onTap: () => _pickImage(true),
          ),
          const SizedBox(height: 16),
          _buildScanCard(
            label: _t('Back of ID', 'ظهر البطاقة', 'Verso de la carte'),
            image: _backImage,
            icon: Icons.credit_card_outlined,
            onTap: () => _pickImage(false),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFFF5A524)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t('Make sure the text is clear and the card is not cropped.', 'تأكد من أن النص واضح والبطاقة غير مقصوصة.', 'Assurez-vous que le texte est lisible et que la carte n\'est pas rognée.'),
                    style: _pop(size: 12, color: const Color(0xFF666666)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _processing || !bothUploaded ? null : _onSubmit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _processing || !bothUploaded ? const Color(0xFFF0D49A) : const Color(0xFFF5A524),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _processing || !bothUploaded ? [] : [BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 3))],
              ),
              child: Center(
                child: _processing
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(_t('Continue', 'متابعة', 'Continuer'),
                      style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard({required String label, required File? image, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: _processing ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: image != null ? Colors.black : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: image != null ? const Color(0xFF4CAF50) : const Color(0xFFE8E8E8),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(image, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 28, color: const Color(0xFFF5A524)),
                    ),
                    const SizedBox(height: 12),
                    Text(label, style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFF555555))),
                    const SizedBox(height: 4),
                    Text(
                      _t('Tap to scan', 'اضغط للمسح', 'Appuyez pour scanner'),
                      style: _pop(size: 11, color: const Color(0xFFBBBBBB)),
                    ),
                  ],
                ),
              ),
            if (image != null)
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
            if (image == null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScanFramePainter(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5A524).withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final cornerLen = size.width * 0.08;
    final corners = [
      [Offset(16, 16), Offset(16 + cornerLen, 16), Offset(16, 16 + cornerLen)],
      [Offset(size.width - 16, 16), Offset(size.width - 16 - cornerLen, 16), Offset(size.width - 16, 16 + cornerLen)],
      [Offset(16, size.height - 16), Offset(16 + cornerLen, size.height - 16), Offset(16, size.height - 16 - cornerLen)],
      [Offset(size.width - 16, size.height - 16), Offset(size.width - 16 - cornerLen, size.height - 16), Offset(size.width - 16, size.height - 16 - cornerLen)],
    ];

    for (final c in corners) {
      canvas.drawLine(c[0], c[1], paint);
      canvas.drawLine(c[0], c[2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PreviewOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFF5A524).withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final margin = 12.0;
    final r = 12.0;
    final rect = Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));
    canvas.drawRRect(rrect, borderPaint);

    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1;

    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawCircle(Offset(cx, cy), 3, centerPaint);
    canvas.drawLine(Offset(cx - 15, cy), Offset(cx + 15, cy), linePaint);
    canvas.drawLine(Offset(cx, cy - 15), Offset(cx, cy + 15), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
