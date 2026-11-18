import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';
import 'models/api_models.dart';
import 'order_model.dart';
import 'services/api_payload.dart';
import 'services/api_service.dart';
import 'widgets/api_state.dart';

TextStyle _pop({double? size, FontWeight? weight, Color? color, double? height, double? letterSpacing}) {
  return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);
}

class OrderConfirmationScreen extends StatefulWidget {
  final OrderData orderData;
  final VoidCallback onBack;
  final VoidCallback onRouteEdit;
  final VoidCallback onVehicleEdit;
  final VoidCallback onTimeEdit;
  final VoidCallback onConfirmDone;
  const OrderConfirmationScreen({
    super.key,
    required this.orderData,
    required this.onBack,
    required this.onRouteEdit,
    required this.onVehicleEdit,
    required this.onTimeEdit,
    required this.onConfirmDone,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _estimating = false;
  bool _submitting = false;
  String? _estimatePrice;
  EstimateResult? _estimate;
  bool _negotiable = false;

  final ApiService _api = ApiService();

  String get _lang => appLanguage.lang;
  bool get _isArabic => _lang == 'AR';
  bool get _isRtl => _isArabic;

  String _t(String en, String ar, String fr) {
    if (_isArabic) return ar;
    if (_lang == 'FR') return fr;
    return en;
  }

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLangChanged);
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() { setState(() {}); }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF5A524), size: 28),
          const SizedBox(width: 10),
          Text(_t('Error', 'خطأ', 'Erreur'), style: _pop(size: 18, weight: FontWeight.w700)),
        ]),
        content: Text(msg, style: _pop(size: 13, color: const Color(0xFF555555))),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFFF5A524), borderRadius: BorderRadius.circular(14)),
              child: Text(_t('Got it', 'حسناً', 'Compris'),
                textAlign: TextAlign.center,
                style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 56),
            const SizedBox(height: 16),
            Text(_t('Order Confirmed!', 'تم تأكيد الطلب!', 'Commande confirmée!'),
              style: _pop(size: 18, weight: FontWeight.w700, color: const Color(0xFF111111))),
            const SizedBox(height: 10),
            Text(_t('Your mission has been successfully created.', 'تم إنشاء مهمتك بنجاح.', 'Votre mission a été créée avec succès.'),
              textAlign: TextAlign.center,
              style: _pop(size: 13, color: const Color(0xFF555555))),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                widget.onConfirmDone();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFFF5A524), borderRadius: BorderRadius.circular(14)),
                child: Text(_t('Back to Home', 'العودة للرئيسية', 'Retour à l\'accueil'),
                  textAlign: TextAlign.center,
                  style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getEstimate() async {
    setState(() => _estimating = true);
    try {
      final result = await _api.estimateMission(
        ApiPayload.estimate(widget.orderData),
      );
      final est = result.estimate;
      final amount = est?.amount ?? result.estimatedPrice.round();
      widget.orderData.quoteId = est?.quoteId;
      widget.orderData.priceRange = est != null
          ? '${formatDzd(est.low)} – ${formatDzd(est.high)} DZD'
          : null;
      widget.orderData.estimatedPrice = formatDzd(amount);
      if (!mounted) return;
      setState(() {
        _estimate = result;
        _estimatePrice = formatDzd(amount);
        _estimating = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _estimating = false);
      _showError(_estimateErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _estimating = false);
      _showError(apiErrorMessage(e));
    }
  }

  String _estimateErrorMessage(ApiException e) {
    if (e.code == 'invalid_distance') {
      return _t('The distance is invalid. Please reselect the route on the map.',
          'المسافة غير صالحة. يرجى إعادة تحديد المسار على الخريطة.',
          'La distance est invalide. Veuillez resélectionner l\'itinéraire.');
    }
    if (e.code == 'invalid_coordinates') {
      return _t('Pickup or delivery coordinates are invalid.',
          'إحداثيات الاستلام أو التسليم غير صالحة.',
          'Les coordonnées de prise en charge ou de livraison sont invalides.');
    }
    return apiErrorMessage(e);
  }

  Future<void> _confirmOrder() async {
    setState(() => _submitting = true);
    try {
      final mission = await _api.confirmMission(
        ApiPayload.confirm(
          widget.orderData,
          quoteId: widget.orderData.quoteId,
          negotiable: _negotiable,
        ),
      );
      widget.orderData.backendMissionId = mission.id;
      widget.orderData.estimatedPrice = formatDzd(mission.price);
      widget.orderData.negotiable = mission.negotiable;
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSuccess();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(apiErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).viewPadding.top;
    final content = Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(topPad),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBackButton(),
                  const SizedBox(height: 16),
                  _buildTripRoute(),
                  const SizedBox(height: 24),
                  _buildVehicleDetails(),
                  const SizedBox(height: 24),
                  _buildTimeCommodity(),
                  const SizedBox(height: 28),
                  if (_estimatePrice != null) ...[
                    _buildEstimateDisplay(),
                    const SizedBox(height: 16),
                  ],
                  _buildEstimateButton(),
                  if (_estimate != null) ...[
                    const SizedBox(height: 14),
                    _buildNegotiableToggle(),
                  ],
                  const SizedBox(height: 12),
                  _buildConfirmButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (_isRtl) return Directionality(textDirection: TextDirection.rtl, child: content);
    return content;
  }

  Widget _buildHeader(double topPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFD),
        border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2), width: 1)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                SizedBox(
                  width: 48, height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.cover, width: 48, height: 48),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Text('ORIZZONTE', style: _pop(size: 13, weight: FontWeight.w800, color: const Color(0xFF111111), letterSpacing: -0.02)),
            ],
          ),
          GestureDetector(
            onTap: _showLanguageDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFECECEC), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 12, color: Color(0xFF333333)),
                  const SizedBox(width: 5),
                  Text(_lang, style: _pop(size: 11, weight: FontWeight.w600, color: const Color(0xFF333333), letterSpacing: 0.05)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: widget.onBack,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF5A524).withValues(alpha: 0.2), width: 1),
            ),
            child: Center(
              child: Icon(Icons.chevron_left, size: 20, color: const Color(0xFFF5A524)),
            ),
          ),
          const SizedBox(width: 10),
          Text(_isArabic ? 'رجوع' : _lang == 'FR' ? 'Retour' : 'Back',
            style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFFF5A524))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(title, style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF5A524).withValues(alpha: 0.3), width: 1),
            ),
            child: Text(_t('EDIT', 'تعديل', 'MODIFIER'),
              style: _pop(size: 11, weight: FontWeight.w700, color: const Color(0xFFF5A524))),
          ),
        ),
      ],
    );
  }

  Widget _buildTripRoute() {
    final d = widget.orderData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(_t('Trip route', 'مسار الرحلة', 'Itinéraire'), widget.onRouteEdit),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  SvgPicture.asset('assets/images/last1.svg', width: 20, height: 20),
                  Expanded(child: Container(width: 2, color: const Color(0xFFEFEFEF))),
                  SvgPicture.asset('assets/images/last2.svg', width: 20, height: 20),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.pickup.isNotEmpty ? d.pickup : '-', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: _pop(size: 13, color: const Color(0xFF111111))),
                    const SizedBox(height: 16),
                    Text(d.delivery.isNotEmpty ? d.delivery : '-', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: _pop(size: 13, color: const Color(0xFF111111))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleDetails() {
    final d = widget.orderData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(_t('Vehicle Details', 'تفاصيل المركبة', 'Détails du véhicule'), widget.onVehicleEdit),
        const SizedBox(height: 14),
        _detailRow(_t('Truck Type', 'نوع الشاحنة', 'Type de camion'), d.truckType.isNotEmpty ? d.truckType : _t('Fourgon', 'فورغون', 'Fourgon')),
        _detailRow(_t('Truck model', 'طراز الشاحنة', 'Modèle du camion'), d.truckModel.isNotEmpty ? d.truckModel : _t('Standard', 'قياسي', 'Standard')),
        _detailRow(_t('Weight/Capacity', 'الوزن/القدرة', 'Poids/Capacité'), d.weight.isNotEmpty ? d.weight : '0'),
        if (d.bodyType.isNotEmpty)
          _detailRow(_t('Body Type', 'نوع الهيكل', 'Type de carrosserie'), d.bodyType),
        if (d.length.isNotEmpty)
          _detailRow(_t('Length', 'الطول', 'Longueur'), d.length),
        if (d.width.isNotEmpty)
          _detailRow(_t('Width', 'العرض', 'Largeur'), d.width),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: _pop(size: 13, color: const Color(0xFF999999))),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value, textAlign: TextAlign.end,
              style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFF111111))),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCommodity() {
    final d = widget.orderData;
    final displayDateTime = d.isNow
      ? _t('Now', 'الآن', 'Maintenant')
      : (d.manualDate.isNotEmpty && d.manualTime.isNotEmpty)
        ? '${d.manualDate} ${d.manualTime}'
        : _t('Not scheduled', 'غير مجدول', 'Non planifié');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(_t('Time and Commodity', 'الوقت والبضاعة', 'Temps et marchandise'), widget.onTimeEdit),
        const SizedBox(height: 14),
        Text(_t('Commodity', 'البضاعة', 'Marchandise'),
          style: _pop(size: 13, color: const Color(0xFF999999))),
        const SizedBox(height: 4),
        Text(d.commodity.isNotEmpty ? d.commodity : _t('No description provided.', 'لا يوجد وصف.', 'Aucune description fournie.'),
          style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFF111111))),
        const SizedBox(height: 12),
        _detailRow(_t('Helpers', 'المساعدين', 'Aides'), d.helpers.toString().padLeft(2, '0')),
        _detailRow(_t('Date and time', 'التاريخ والوقت', 'Date et heure'), displayDateTime),
      ],
    );
  }

  Widget _buildNegotiableToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _negotiable,
        activeThumbColor: const Color(0xFFF5A524),
        onChanged: (v) => setState(() => _negotiable = v),
        title: Text(
          _t('Allow price negotiation', 'السماح بتفاوض السعر', 'Autoriser la négociation'),
          style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFF333333)),
        ),
        subtitle: Text(
          _t('Approved drivers can send offers on this mission.',
              'يمكن للسائقين المعتمدين إرسال عروض على هذه المهمة.',
              'Les chauffeurs agréés peuvent envoyer des offres.'),
          style: _pop(size: 11, color: const Color(0xFF999999)),
        ),
      ),
    );
  }

  Widget _buildEstimateDisplay() {
    final range = widget.orderData.priceRange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5A524).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(_t('ESTIMATED TOTAL', 'التقدير الإجمالي', 'TOTAL ESTIMÉ'),
            style: _pop(size: 12, weight: FontWeight.w600, color: const Color(0xFF999999), letterSpacing: 0.08)),
          const SizedBox(height: 6),
          Text('${_estimatePrice!} DZD',
            style: _pop(size: 28, weight: FontWeight.w800, color: const Color(0xFFF5A524))),
          if (range != null) ...[
            const SizedBox(height: 4),
            Text(range,
              style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFF777777))),
          ],
          if (_estimate?.estimate?.isLowConfidence ?? false) ...[
            const SizedBox(height: 8),
            Text(
              _t('Approximate estimate (route distance unavailable)',
                  'تقدير تقريبي (المسافة غير متوفرة)',
                  'Estimation approximative (distance indisponible)'),
              style: _pop(size: 11, color: const Color(0xFFE08A00)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstimateButton() {
    return GestureDetector(
      onTap: _estimating ? null : _getEstimate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: _estimating ? const Color(0xFFCCCCCC) : const Color(0xFFF5A524),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: _estimating
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                const SizedBox(width: 10),
                Text(_t('Processing...', 'جاري المعالجة...', 'En cours...'),
                  style: _pop(size: 15, weight: FontWeight.w700, color: Colors.white)),
              ],
            )
          : Text(
              _estimatePrice != null
                ? _t('Refresh Estimate', 'تحديث التقدير', 'Actualiser l\'estimation')
                : _t('Get Estimate', 'الحصول على تقدير', 'Obtenir une estimation'),
              textAlign: TextAlign.center,
              style: _pop(size: 16, weight: FontWeight.w700, color: Colors.white),
            ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _submitting ? null : _confirmOrder,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: _submitting ? const Color(0xFFCCCCCC) : const Color(0xFFF5A524),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: _submitting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                const SizedBox(width: 10),
                Text(_t('Processing...', 'جاري المعالجة...', 'En cours...'),
                  style: _pop(size: 15, weight: FontWeight.w700, color: Colors.white)),
              ],
            )
          : Text(_t('Confirm Order', 'تأكيد الطلب', 'Confirmer la commande'),
              textAlign: TextAlign.center,
              style: _pop(size: 16, weight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(_isArabic ? 'اختر اللغة' : _lang == 'FR' ? 'Choisir la langue' : 'Select Language',
              style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
            const SizedBox(height: 8),
            _langOption('EN', 'English'),
            _langOption('AR', 'العربية'),
            _langOption('FR', 'Français'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _langOption(String code, String label) {
    final selected = _lang == code;
    return InkWell(
      onTap: () { appLanguage.setLang(code); Navigator.pop(context); },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7E6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? const Color(0xFFF5A524) : const Color(0xFFEFEFEF), width: 1.5),
        ),
        child: Row(children: [
          Icon(Icons.language, size: 20, color: selected ? const Color(0xFFF5A524) : const Color(0xFF999999)),
          const SizedBox(width: 12),
          Text(label, style: _pop(size: 14, weight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? const Color(0xFFF5A524) : const Color(0xFF111111))),
          const Spacer(),
          if (selected) const Icon(Icons.check_circle, size: 20, color: Color(0xFFF5A524)),
        ]),
      ),
    );
  }
}
