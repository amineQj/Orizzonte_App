import 'package:flutter/material.dart';

import '../boss/boss_ui.dart';
import '../services/auth_session.dart';
import '../services/pricing_service.dart';

class BossPricingScreen extends StatefulWidget {
  const BossPricingScreen({super.key});

  @override
  State<BossPricingScreen> createState() => _BossPricingScreenState();
}

class _BossPricingScreenState extends State<BossPricingScreen> {
  final _service = PricingService();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _formError;
  int _version = 0;
  bool _calibrated = false;

  // Vehicle classes
  final _stdBase = TextEditingController();
  final _stdPerKm = TextEditingController();
  final _stdPerMin = TextEditingController();
  final _stdMinFare = TextEditingController();
  final _vanBase = TextEditingController();
  final _vanPerKm = TextEditingController();
  final _vanPerMin = TextEditingController();
  final _vanMinFare = TextEditingController();
  final _truckBase = TextEditingController();
  final _truckPerKm = TextEditingController();
  final _truckPerMin = TextEditingController();
  final _truckMinFare = TextEditingController();

  // Extras
  final _helperHourly = TextEditingController();
  final _perFloorFee = TextEditingController();

  // Multipliers
  final _peak = TextEditingController();
  final _night = TextEditingController();
  final _weekend = TextEditingController();

  // Commission
  final _commissionRate = TextEditingController();

  // Password
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _service.dispose();
    for (final c in [
      _stdBase,
      _stdPerKm,
      _stdPerMin,
      _stdMinFare,
      _vanBase,
      _vanPerKm,
      _vanPerMin,
      _vanMinFare,
      _truckBase,
      _truckPerKm,
      _truckPerMin,
      _truckMinFare,
      _helperHourly,
      _perFloorFee,
      _peak,
      _night,
      _weekend,
      _commissionRate,
      _password,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final cfg = await _service.getPricingConfig();
      _applyConfig(cfg);
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _applyConfig(PricingConfig cfg) {
    _version = cfg.version;
    _calibrated = cfg.calibrated;
    final p = cfg.parameters;
    final vc = (p['vehicle_classes'] as Map?)?.cast<String, dynamic>() ?? {};
    void fillVehicle(
      String key,
      TextEditingController base,
      TextEditingController perKm,
      TextEditingController perMin,
      TextEditingController minFare,
    ) {
      final m = (vc[key] as Map?)?.cast<String, dynamic>() ?? {};
      base.text = _numStr(m['base']);
      perKm.text = _numStr(m['per_km']);
      perMin.text = _numStr(m['per_min']);
      minFare.text = _numStr(m['min_fare']);
    }

    fillVehicle('standard', _stdBase, _stdPerKm, _stdPerMin, _stdMinFare);
    fillVehicle('van', _vanBase, _vanPerKm, _vanPerMin, _vanMinFare);
    fillVehicle('truck', _truckBase, _truckPerKm, _truckPerMin, _truckMinFare);

    final extras = (p['extras'] as Map?)?.cast<String, dynamic>() ?? {};
    _helperHourly.text = _numStr(extras['helper_hourly']);
    _perFloorFee.text = _numStr(extras['per_floor_fee']);

    final tm = (p['time_multipliers'] as Map?)?.cast<String, dynamic>() ?? {};
    _peak.text = _numStr(tm['peak']);
    _night.text = _numStr(tm['night']);
    _weekend.text = _numStr(tm['weekend']);

    _commissionRate.text = _numStr(p['commission_rate']);
  }

  String _numStr(dynamic v) {
    if (v == null) return '';
    if (v is num) {
      if (v == v.roundToDouble()) return v.toInt().toString();
      return v.toString();
    }
    return v.toString();
  }

  num? _parseNum(TextEditingController c, {bool integer = false}) {
    final t = c.text.trim().replaceAll(',', '');
    if (t.isEmpty) return null;
    if (integer) return int.tryParse(t);
    return num.tryParse(t);
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!AuthSession.instance.isBoss()) {
      setState(() => _formError = tr(
            'Access denied. Boss role required.',
            'تم رفض الوصول. مطلوب دور المدير.',
            'Accès refusé. Rôle boss requis.',
          ));
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _formError = tr(
            'Please enter your password to confirm changes.',
            'يرجى إدخال كلمة المرور لتأكيد التغييرات.',
            'Veuillez entrer votre mot de passe pour confirmer.',
          ));
      return;
    }

    Map<String, dynamic>? vehicle(String key, TextEditingController base,
        TextEditingController perKm, TextEditingController perMin, TextEditingController minFare) {
      final b = _parseNum(base);
      final k = _parseNum(perKm);
      final m = _parseNum(perMin);
      final f = _parseNum(minFare);
      if (b == null || k == null || m == null || f == null) return null;
      if (b < 0 || k < 0 || m < 0 || f < 0) return null;
      return {'base': b, 'per_km': k, 'per_min': m, 'min_fare': f};
    }

    final std = vehicle('standard', _stdBase, _stdPerKm, _stdPerMin, _stdMinFare);
    final van = vehicle('van', _vanBase, _vanPerKm, _vanPerMin, _vanMinFare);
    final truck = vehicle('truck', _truckBase, _truckPerKm, _truckPerMin, _truckMinFare);
    final helper = _parseNum(_helperHourly);
    final floor = _parseNum(_perFloorFee);
    final peak = _parseNum(_peak);
    final night = _parseNum(_night);
    final weekend = _parseNum(_weekend);
    final commission = _parseNum(_commissionRate);

    if ([std, van, truck].contains(null) ||
        helper == null ||
        floor == null ||
        peak == null ||
        night == null ||
        weekend == null ||
        commission == null) {
      setState(() => _formError = tr(
            'Please fill all fields with valid numbers (>= 0).',
            'يرجى ملء جميع الحقول بأرقام صالحة (>= 0).',
            'Veuillez remplir tous les champs avec des nombres valides (>= 0).',
          ));
      return;
    }
    if (commission < 0 || commission > 1) {
      setState(() => _formError = tr(
            'Commission rate must be between 0 and 1.',
            'يجب أن يكون معدل العمولة بين 0 و 1.',
            'Le taux de commission doit être entre 0 et 1.',
          ));
      return;
    }

    final parameters = <String, dynamic>{
      'vehicle_classes': {
        'standard': std,
        'van': van,
        'truck': truck,
      },
      'extras': {
        'helper_hourly': helper,
        'per_floor_fee': floor,
      },
      'time_multipliers': {
        'peak': peak,
        'night': night,
        'weekend': weekend,
      },
      'commission_rate': commission,
    };

    setState(() => _saving = true);
    try {
      final updated = await _service.updatePricingConfig(
        parameters: parameters,
        password: _password.text,
      );
      _applyConfig(updated);
      if (!mounted) return;
      _password.clear();
      setState(() => _saving = false);
      _toast(tr(
        'Pricing configuration saved (v$_version).',
        'تم حفظ إعدادات التسعير (الإصدار $_version).',
        'Configuration tarifaire enregistrée (v$_version).',
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = e.toString();
      });
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: pop(size: 13, color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).viewPadding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFDFDFD),
              border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Backend Pricing Config', 'إعدادات التسعير (الخادم)',
                            'Config tarifaire (backend)'),
                        style: pop(
                          size: 16,
                          weight: FontWeight.w800,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      Text(
                        tr('Boss only • password required to save',
                            'للمدير فقط • كلمة المرور مطلوبة للحفظ',
                            'Boss uniquement • mot de passe requis'),
                        style: pop(size: 11, color: const Color(0xFF999999)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _loadConfig,
                  icon: const Icon(Icons.refresh, color: Color(0xFFF5A524)),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF5A524)),
      );
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: pop(size: 13, color: const Color(0xFF555555)),
              ),
              const SizedBox(height: 16),
              _primaryButton(
                label: tr('Retry', 'إعادة المحاولة', 'Réessayer'),
                onTap: _loadConfig,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metaCard(),
          const SizedBox(height: 16),
          _vehicleCard(
            tr('Standard', 'قياسي', 'Standard'),
            _stdBase,
            _stdPerKm,
            _stdPerMin,
            _stdMinFare,
          ),
          const SizedBox(height: 12),
          _vehicleCard(tr('Van', 'شاحنة صغيرة', 'Van'), _vanBase, _vanPerKm,
              _vanPerMin, _vanMinFare),
          const SizedBox(height: 12),
          _vehicleCard(tr('Truck', 'شاحنة', 'Camion'), _truckBase, _truckPerKm,
              _truckPerMin, _truckMinFare),
          const SizedBox(height: 16),
          _extrasCard(),
          const SizedBox(height: 16),
          _multipliersCard(),
          const SizedBox(height: 16),
          _commissionCard(),
          const SizedBox(height: 16),
          _passwordCard(),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Text(
                _formError!,
                style: pop(size: 12, color: const Color(0xFFEF4444)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _saving
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF5A524)),
                )
              : _primaryButton(
                  label: tr('Save pricing configuration', 'حفظ إعدادات التسعير',
                      'Enregistrer la configuration'),
                  onTap: _save,
                ),
        ],
      ),
    );
  }

  Widget _metaCard() {
    return _card(
      title: tr('Current config', 'الإعداد الحالي', 'Configuration actuelle'),
      icon: Icons.info_outline,
      child: Row(
        children: [
          _chip(tr('Version', 'الإصدار', 'Version'), 'v$_version'),
          const SizedBox(width: 10),
          _chip(
            tr('Calibrated', 'معاير', 'Calibré'),
            _calibrated ? tr('Yes', 'نعم', 'Oui') : tr('No', 'لا', 'Non'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: pop(size: 10, color: const Color(0xFF999999))),
          Text(value,
              style: pop(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFFF5A524))),
        ],
      ),
    );
  }

  Widget _vehicleCard(String title, TextEditingController base,
      TextEditingController perKm, TextEditingController perMin, TextEditingController minFare) {
    return _card(
      title: '$title ${tr('vehicle', 'مركبة', 'véhicule')}',
      icon: Icons.local_shipping_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _numField(
                      tr('Base', 'الأساس', 'Base'), base)),
              const SizedBox(width: 10),
              Expanded(
                  child: _numField(
                      tr('Per km', 'لكل كم', 'Par km'), perKm)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _numField(
                      tr('Per min', 'لكل دقيقة', 'Par min'), perMin)),
              const SizedBox(width: 10),
              Expanded(
                  child: _numField(
                      tr('Min fare', 'الحد الأدنى', 'Tarif min'), minFare)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _extrasCard() {
    return _card(
      title: tr('Extras', 'إضافات', 'Extras'),
      icon: Icons.add_circle_outline,
      child: Row(
        children: [
          Expanded(
              child: _numField(
                  tr('Helper hourly', 'أجر المساعد/ساعة', 'Aide / heure'),
                  _helperHourly)),
          const SizedBox(width: 10),
          Expanded(
              child: _numField(
                  tr('Per floor fee', 'رسوم الطابق', 'Frais / étage'),
                  _perFloorFee)),
        ],
      ),
    );
  }

  Widget _multipliersCard() {
    return _card(
      title: tr('Time multipliers', 'مضاعفات الوقت', 'Multiplicateurs temps'),
      icon: Icons.schedule,
      child: Row(
        children: [
          Expanded(child: _numField(tr('Peak', 'ذروة', 'Pointe'), _peak)),
          const SizedBox(width: 10),
          Expanded(child: _numField(tr('Night', 'ليل', 'Nuit'), _night)),
          const SizedBox(width: 10),
          Expanded(
              child:
                  _numField(tr('Weekend', 'عطلة', 'Week-end'), _weekend)),
        ],
      ),
    );
  }

  Widget _commissionCard() {
    return _card(
      title: tr('Commission', 'العمولة', 'Commission'),
      icon: Icons.percent,
      child: _numField(
        tr('Commission rate (0-1)', 'معدل العمولة (0-1)', 'Taux (0-1)'),
        _commissionRate,
      ),
    );
  }

  Widget _passwordCard() {
    return _card(
      title: tr('Confirm with password', 'تأكيد بكلمة المرور', 'Confirmer'),
      icon: Icons.lock_outline,
      child: _fieldBase(
        label: tr('Boss password', 'كلمة مرور المدير', 'Mot de passe boss'),
        child: TextField(
          controller: _password,
          obscureText: _obscurePassword,
          style: pop(size: 13, color: const Color(0xFF111111)),
          decoration: _decoration().copyWith(
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF999999),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFF5A524)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: pop(
                    size: 14,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _fieldBase({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: pop(
              size: 11, weight: FontWeight.w600, color: const Color(0xFF555555)),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _numField(String label, TextEditingController controller) {
    return _fieldBase(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: false),
        style: pop(size: 13, color: const Color(0xFF111111)),
        decoration: _decoration(),
      ),
    );
  }

  InputDecoration _decoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF5A524), width: 1.5),
      ),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF5A524),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5A524).withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: pop(size: 13, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
