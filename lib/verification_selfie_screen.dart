import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'app_language.dart';

TextStyle _pop({double? size, FontWeight? weight, Color? color, double? height, double? letterSpacing}) {
  return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);
}

class VerificationSelfieScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;
  const VerificationSelfieScreen({super.key, required this.onComplete, required this.onBack});

  @override
  State<VerificationSelfieScreen> createState() => _VerificationSelfieScreenState();
}

class _VerificationSelfieScreenState extends State<VerificationSelfieScreen> {
  // Bytes from XFile.readAsBytes() work on mobile AND web; dart:io File with
  // XFile.path fails on Flutter Web ("Failed to process image").
  Uint8List? _selfieImage;
  bool _processing = false;

  String get _lang => appLanguage.lang;
  bool get _isArabic => _lang == 'AR';

  String _t(String en, String ar, String fr) {
    if (_isArabic) return ar;
    if (_lang == 'FR') return fr;
    return en;
  }

  Future<void> _takeSelfie() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final error = await _validateImage(bytes);
      if (!mounted) return;
      if (error != null) {
        _showRejectionDialog(error);
        return;
      }
      _showPreview(bytes);
    }
  }

  Future<String?> _validateImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      image.dispose();

      if (width < 300 || height < 300) {
        return _t('Image resolution is too low. Please retake.', 'دقة الصورة منخفضة جداً. أعد المحاولة.', 'La résolution est trop basse. Réessayez.');
      }

      final byteData = await _getPixelData(bytes);
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

  Future<ByteData?> _getPixelData(Uint8List bytes) async {
    try {
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

  void _showPreview(Uint8List image) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                child: ClipOval(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Image.memory(image, fit: BoxFit.cover),
                  ),
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
                        setState(() { _selfieImage = image; });
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
    );
  }

  void _onSubmit() {
    if (_selfieImage == null) return;
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.face, size: 36, color: Color(0xFFF5A524)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(_t('Take a Selfie', 'التقط صورة سيلفي', 'Prenez un selfie'),
              style: _pop(size: 18, weight: FontWeight.w700, color: const Color(0xFF111111))),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _t('This will be used to verify your identity', 'سيتم استخدامها للتحقق من هويتك', 'Sera utilisé pour vérifier votre identité'),
              textAlign: TextAlign.center,
              style: _pop(size: 13, color: const Color(0xFF999999), height: 1.5),
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _processing ? null : _takeSelfie,
            child: Center(
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  color: _selfieImage != null ? Colors.black : const Color(0xFFF8F8F8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selfieImage != null ? const Color(0xFF4CAF50) : const Color(0xFFE8E8E8),
                    width: 3,
                  ),
                ),
                child: Stack(
                  children: [
                    if (_selfieImage != null)
                      ClipOval(
                        child: Image.memory(_selfieImage!, width: 200, height: 200, fit: BoxFit.cover),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E6),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: const Icon(Icons.camera_alt, size: 30, color: Color(0xFFF5A524)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _t('Tap to take selfie', 'اضغط لالتقاط السيلفي', 'Appuyez pour un selfie'),
                              style: _pop(size: 12, color: const Color(0xFFBBBBBB)),
                            ),
                          ],
                        ),
                      ),
                    if (_selfieImage != null)
                      Positioned(
                        bottom: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check, size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
                const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFFF5A524)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t('Make sure your face is clearly visible with good lighting.', 'تأكد من أن وجهك مرئي بوضوح بإضاءة جيدة.', 'Assurez-vous que votre visage est bien visible avec un bon éclairage.'),
                    style: _pop(size: 12, color: const Color(0xFF666666)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _processing || _selfieImage == null ? null : _onSubmit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _processing || _selfieImage == null ? const Color(0xFFF0D49A) : const Color(0xFFF5A524),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _processing || _selfieImage == null ? [] : [BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 3))],
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
}
