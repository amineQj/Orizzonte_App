import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';
import 'order_model.dart';
import 'order_confirmation_screen.dart';

TextStyle _pop({double? size, FontWeight? weight, Color? color, double? height, double? letterSpacing}) {
  return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);
}

class SendOrderScreen extends StatefulWidget {
  final OrderData orderData;
  final VoidCallback onBack;
  final void Function(OrderData data)? onMissionConfirmed;
  const SendOrderScreen({super.key, required this.orderData, required this.onBack, this.onMissionConfirmed});

  @override
  State<SendOrderScreen> createState() => _SendOrderScreenState();
}

class _SendOrderScreenState extends State<SendOrderScreen> {
  String _commodity = '';
  int _helpers = 0;
  String _phone = '';
  String? _confirmMethod;
  final TextEditingController _commodityCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

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
    _commodity = widget.orderData.commodity;
    _helpers = widget.orderData.helpers;
    _phone = widget.orderData.phoneNumber;
    _confirmMethod = widget.orderData.confirmationMethod.isNotEmpty ? widget.orderData.confirmationMethod : null;
    _commodityCtrl.text = _commodity;
    _phoneCtrl.text = _phone;
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    _commodityCtrl.dispose();
    _phoneCtrl.dispose();
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
          Text(_t('Missing Information', 'معلومات ناقصة', 'Informations manquantes'),
            style: _pop(size: 18, weight: FontWeight.w700)),
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

  void _validate() {
    if (_phone.isEmpty || _confirmMethod == null) {
      _showError(_t(
        'Please provide your phone number and select a confirmation method.',
        'يرجى إدخال رقم الهاتف واختيار طريقة التأكيد.',
        'Veuillez fournir votre numéro de téléphone et sélectionner une méthode de confirmation.',
      ));
      return;
    }
    if (!RegExp(r'^0[567]\d{8}$').hasMatch(_phone)) {
      _showError(_t(
        'Invalid phone number. It must be 10 digits and start with 05, 06, or 07.',
        'رقم الهاتف غير صالح. يجب أن يكون 10 أرقام ويبدأ بـ 05 أو 06 أو 07.',
        'Numéro de téléphone invalide. Il doit comporter 10 chiffres et commencer par 05, 06 ou 07.',
      ));
      return;
    }
    widget.orderData.commodity = _commodity;
    widget.orderData.helpers = _helpers;
    widget.orderData.phoneNumber = _phone;
    widget.orderData.confirmationMethod = _confirmMethod!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          orderData: widget.orderData,
          onBack: () => Navigator.pop(context),
          onRouteEdit: () { Navigator.pop(context); },
          onVehicleEdit: () { Navigator.popUntil(context, (route) => route.isFirst); },
          onTimeEdit: () { Navigator.pop(context); },
          onConfirmDone: () {
            widget.onMissionConfirmed?.call(widget.orderData);
            Navigator.of(context).popUntil(
              (route) => route.settings.name == '/customer' || route.isFirst,
            );
          },
        ),
      ),
    );
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
                  _buildOrderSummary(),
                  const SizedBox(height: 20),
                  _buildCargoSection(),
                  const SizedBox(height: 20),
                  _buildHelpersSection(),
                  const SizedBox(height: 24),
                  Divider(color: const Color(0xFFEFEFEF), thickness: 1),
                  const SizedBox(height: 20),
                  _buildInfoSection(),
                  const SizedBox(height: 20),
                  _buildPhoneSection(),
                  const SizedBox(height: 20),
                  _buildConfirmMethodSection(),
                  const SizedBox(height: 28),
                  _buildSendButton(),
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

  Widget _buildOrderSummary() {
    final d = widget.orderData;
    if (d.pickup.isEmpty && d.delivery.isEmpty) return const SizedBox.shrink();
    final dateStr = d.isNow ? _t('Now', 'الآن', 'Maintenant') : (d.manualDate.isNotEmpty ? d.manualDate : '-');
    final timeStr = d.manualTime.isNotEmpty ? d.manualTime : '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow(Icons.location_on_outlined, _t('Pickup', 'نقطة الاستلام', 'Prise en charge'), d.pickup),
          const SizedBox(height: 8),
          _summaryRow(Icons.flag_outlined, _t('Delivery', 'نقطة التسليم', 'Livraison'), d.delivery),
          if (d.distance != null) ...[
            const SizedBox(height: 8),
            _summaryRow(Icons.straighten, _t('Distance', 'المسافة', 'Distance'), d.distance!),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: const Color(0xFF999999)),
            const SizedBox(width: 6),
            Text(dateStr, style: _pop(size: 11, color: const Color(0xFF777777))),
            const SizedBox(width: 14),
            Icon(Icons.access_time, size: 14, color: const Color(0xFF999999)),
            const SizedBox(width: 6),
            Text(timeStr, style: _pop(size: 11, color: const Color(0xFF777777))),
          ]),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF999999)),
        const SizedBox(width: 6),
        Text('$label: ', style: _pop(size: 11, weight: FontWeight.w600, color: const Color(0xFF555555))),
        Expanded(
          child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: _pop(size: 11, color: const Color(0xFF777777))),
        ),
      ],
    );
  }

  Widget _buildCargoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          SvgPicture.asset('assets/images/cubes.svg', width: 20, height: 20),
          const SizedBox(width: 8),
          Text(_t('Cargo details', 'تفاصيل الشحنة', 'Détails de la cargaison'),
            style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
          ),
          child: TextField(
            controller: _commodityCtrl,
            maxLines: 4,
            onChanged: (v) => _commodity = v,
            style: _pop(size: 13, color: const Color(0xFF111111)),
            decoration: InputDecoration(
              hintText: _t('Add a description of your cargo details...', 'أضف وصفاً لتفاصيل شحنتك...', 'Ajoutez une description de votre cargaison...'),
              hintStyle: _pop(size: 13, color: const Color(0xFFBBBBBB)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          SvgPicture.asset('assets/images/2mans.svg', width: 20, height: 20),
          const SizedBox(width: 8),
          Text(_t('Loading helpers', 'مساعدات التحميل', 'Aides au chargement'),
            style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
        ]),
        const SizedBox(height: 4),
        Text(_t('Do you need Helpers?', 'هل تحتاج مساعدين؟', 'Avez-vous besoin d\'aide ?'),
          style: _pop(size: 13, color: const Color(0xFF777777))),
        const SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: () { if (_helpers > 0) setState(() => _helpers--); },
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _helpers > 0 ? const Color(0xFFF5A524) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text('-', style: _pop(size: 22, weight: FontWeight.w700,
                    color: _helpers > 0 ? Colors.white : const Color(0xFFCCCCCC))),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 52, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
              ),
              child: Center(
                child: Text('$_helpers', style: _pop(size: 18, weight: FontWeight.w700, color: const Color(0xFF111111))),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => setState(() => _helpers++),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A524),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text('+', style: _pop(size: 22, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Row(children: [
      SvgPicture.asset('assets/images/contact.svg', width: 20, height: 20),
      const SizedBox(width: 8),
      Text(_t('Your Informations', 'معلوماتك', 'Vos informations'),
        style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
    ]);
  }

  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          SvgPicture.asset('assets/images/linephone.svg', width: 16, height: 16),
          const SizedBox(width: 6),
          Text(_t('Enter your namber', 'أدخل رقمك', 'Entrez votre numéro'),
            style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFF555555))),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Text('+213', style: _pop(size: 14, weight: FontWeight.w700, color: const Color(0xFF111111))),
              ),
              Container(width: 1, height: 24, color: const Color(0xFFEFEFEF)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onChanged: (v) {
                    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits != v) {
                      _phoneCtrl.text = digits;
                      _phoneCtrl.selection = TextSelection.fromPosition(TextPosition(offset: digits.length));
                    }
                    _phone = digits;
                  },
                  style: _pop(size: 14, color: const Color(0xFF111111)),
                  decoration: InputDecoration(
                    hintText: '06 XX XX XX XX',
                    hintStyle: _pop(size: 14, color: const Color(0xFFBBBBBB)),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          SvgPicture.asset('assets/images/3points.svg', width: 18, height: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(_t('How would you like to receive the confirmation message?', 'كيف تريد استلام رسالة التأكيد؟', 'Comment souhaitez-vous recevoir le message de confirmation ?'),
              style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFF555555))),
          ),
        ]),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMethodCard('sms')),
            const SizedBox(width: 12),
            Expanded(child: _buildMethodCard('whatsapp')),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodCard(String method) {
    final selected = _confirmMethod == method;
    final isSms = method == 'sms';
    return GestureDetector(
      onTap: () => setState(() => _confirmMethod = method),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7E6) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFF5A524) : const Color(0xFFEFEFEF),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              isSms ? 'assets/images/memory_message-text.svg' : 'assets/images/logos_whatsapp-monochrome-icon.svg',
              width: 24, height: 24,
            ),
            const SizedBox(height: 8),
            Text(isSms ? 'SMS' : 'WhatsApp',
              style: _pop(size: 14, weight: FontWeight.w700, color: selected ? const Color(0xFFF5A524) : const Color(0xFF111111))),
            const SizedBox(height: 4),
            Text(
              isSms
                ? _t('A confirmation SMS will be sent to the provided phone number.', 'سيتم إرسال رسالة تأكيد إلى رقم الهاتف المقدم.', 'Un SMS de confirmation sera envoyé au numéro de téléphone fourni.')
                : _t('A confirmation message will be sent through WhatsApp.', 'سيتم إرسال رسالة تأكيد عبر واتساب.', 'Un message de confirmation sera envoyé via WhatsApp.'),
              style: _pop(size: 11, color: const Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _validate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: const Color(0xFFF5A524),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_t('Send Order', 'إرسال الطلب', 'Envoyer la commande'),
              style: _pop(size: 16, weight: FontWeight.w700, color: Colors.white)),
            const SizedBox(width: 8),
            SvgPicture.asset('assets/images/send.svg', width: 18, height: 18, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          ],
        ),
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
