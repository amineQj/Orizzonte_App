import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_language.dart';
import 'mission_notification_preferences.dart';
import 'mission_notification_service.dart';
import 'notification_catalog.dart';

TextStyle _pop({
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

class MissionNotificationsPage extends StatefulWidget {
  const MissionNotificationsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MissionNotificationsPage> createState() =>
      _MissionNotificationsPageState();
}

class _MissionNotificationsPageState extends State<MissionNotificationsPage> {
  MissionNotificationPreferences? _prefs;
  bool _saving = false;
  bool _osPermissionGranted = false;
  bool _osPermissionChecked = false;

  final MissionNotificationService _service =
      MissionNotificationService.instance;

  String get _lang => appLanguage.lang;
  bool get _isArabic => _lang == 'AR';

  String _t(String en, String ar, String fr) {
    if (_isArabic) return ar;
    if (_lang == 'FR') return fr;
    return en;
  }

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLangChanged);
    _load();
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final prefs = await MissionNotificationPreferencesStore.instance.load();
    final granted = await _service.refreshPermissionStatus();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _osPermissionGranted = granted;
      _osPermissionChecked = true;
    });
  }

  Future<void> _save(MissionNotificationPreferences prefs) async {
    if (_saving) return;
    setState(() => _saving = true);
    await MissionNotificationPreferencesStore.instance.save(prefs);
    if (!mounted) return;
    setState(() => _saving = false);
  }

  Future<void> _updatePrefs(
    void Function(MissionNotificationPreferences) change,
  ) async {
    final current = _prefs;
    if (current == null) return;
    final next = current.copy();
    change(next);
    setState(() => _prefs = next);
    await _save(next);
  }

  Future<bool> _ensurePermission() async {
    final granted = await _service.requestPermission();
    if (!mounted) return granted;
    setState(() => _osPermissionGranted = granted);
    if (!granted) {
      await _showPermissionRequiredDialog();
    }
    return granted;
  }

  Future<void> _showPermissionRequiredDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 32,
                color: Color(0xFFF5A524),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t(
                'Notification permission required',
                'إذن الإشعارات مطلوب',
                'Autorisation de notification requise',
              ),
              style: _pop(
                size: 16,
                weight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'Notifications are blocked. Allow notifications for Orizzonte to receive mission alerts.',
                'الإشعارات محظورة. اسمح بإشعارات أوريزونتي لتلقي تنبيهات المهام.',
                'Les notifications sont bloquées. Autorisez les notifications pour Orizzonte afin de recevoir les alertes de mission.',
              ),
              textAlign: TextAlign.center,
              style: _pop(size: 13, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A524),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5A524).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _t('OK', 'حسناً', 'OK'),
                  textAlign: TextAlign.center,
                  style: _pop(
                    size: 14,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(int minute) {
    final h = (minute ~/ 60).toString().padLeft(2, '0');
    final m = (minute % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime(bool isStart) async {
    final current = _prefs!;
    final initial = TimeOfDay(
      hour: (isStart ? current.startMinute : current.endMinute) ~/ 60,
      minute: (isStart ? current.startMinute : current.endMinute) % 60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF5A524),
            brightness: Theme.of(ctx).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    await _updatePrefs((p) {
      if (isStart) {
        p.startMinute = picked.hour * 60 + picked.minute;
      } else {
        p.endMinute = picked.hour * 60 + picked.minute;
      }
    });
  }

  Future<void> _selectRegion() async {
    final current = _prefs!;
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RegionPickerSheet(
        selectedCodes: current.selectedRegionCodes,
        lang: _lang,
        t: _t,
      ),
    );
    if (result == null) return;
    await _updatePrefs((p) {
      p.selectedRegionCodes
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _sendTestNotification() async {
    if (!_prefs!.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Enable notifications first',
              'فعّل الإشعارات أولاً',
              'Activez d\'abord les notifications',
            ),
            style: _pop(size: 13, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF111111),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final granted = await _service.refreshPermissionStatus();
    if (!mounted) return;
    setState(() => _osPermissionGranted = granted);
    if (!granted) {
      final ok = await _ensurePermission();
      if (!ok) return;
    }
    await _service.showTestNotification(
      title: _t('Test Notification', 'إشعار اختباري', 'Notification de test'),
      body: _t(
        'Your mission notifications are working correctly.',
        'تعمل إشعارات المهام الخاصة بك بشكل صحيح.',
        'Vos notifications de mission fonctionnent correctement.',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(
            'Test notification sent',
            'تم إرسال الإشعار الاختباري',
            'Notification de test envoyée',
          ),
          style: _pop(size: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _prefs == null
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFF5A524)),
          )
        : _content();
    if (widget.embedded) {
      return content;
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            size: 28,
            color: Color(0xFF111111),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t(
            'Mission Notifications',
            'إشعارات المهام',
            'Notifications de mission',
          ),
          style: _pop(
            size: 17,
            weight: FontWeight.w700,
            color: const Color(0xFF111111),
          ),
        ),
        centerTitle: true,
      ),
      body: content,
    );
  }

  Widget _content() {
    final prefs = _prefs!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMasterSwitchCard(prefs),
          if (_osPermissionChecked && !_osPermissionGranted) ...[
            const SizedBox(height: 12),
            _buildPermissionBanner(),
          ],
          const SizedBox(height: 24),
          Text(
            _t(
              'Notification Preferences',
              'تفضيلات الإشعارات',
              'Préférences de notification',
            ),
            style: _pop(
              size: 16,
              weight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
          _buildRegionCard(prefs),
          const SizedBox(height: 12),
          _buildVehicleCard(prefs),
          const SizedBox(height: 12),
          _buildScheduleCard(prefs),
          const SizedBox(height: 24),
          Text(
            _t('Test', 'اختبار', 'Test'),
            style: _pop(
              size: 16,
              weight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
          _buildTestCard(prefs),
        ],
      ),
    );
  }

  Widget _buildMasterSwitchCard(MissionNotificationPreferences prefs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5A524), Color(0xFFF5A524)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        'Mission Notifications',
                        'إشعارات المهام',
                        'Notifications de mission',
                      ),
                      style: _pop(
                        size: 14,
                        weight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prefs.enabled
                          ? _t(
                              'Notifications are enabled',
                              'الإشعارات مفعلة',
                              'Notifications activées',
                            )
                          : _t(
                              'Notifications are disabled',
                              'الإشعارات معطلة',
                              'Notifications désactivées',
                            ),
                      style: _pop(
                        size: 11,
                        color: prefs.enabled
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: prefs.enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFFF5A524),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE0E0E0),
                onChanged: _saving
                    ? null
                    : (value) => _onMasterSwitchChanged(value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onMasterSwitchChanged(bool value) async {
    if (value) {
      final ok = await _ensurePermission();
      if (!ok) return;
    }
    await _updatePrefs((p) => p.enabled = value);
  }

  Widget _buildPermissionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF5A524).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_off_outlined,
                size: 18,
                color: Color(0xFFF5A524),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(
                    'Notification permission required',
                    'إذن الإشعارات مطلوب',
                    'Autorisation de notification requise',
                  ),
                  style: _pop(
                    size: 13,
                    weight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              _t(
                'Mission notifications are blocked. Enable the permission to receive alerts.',
                'إشعارات المهام محظورة. فعّل الإذن لتلقي التنبيهات.',
                'Les notifications de mission sont bloquées. Activez l\'autorisation pour recevoir les alertes.',
              ),
              style: _pop(size: 11, color: const Color(0xFF666666)),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _ensurePermission(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A524),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _t(
                  'Enable notifications',
                  'تفعيل الإشعارات',
                  'Activer les notifications',
                ),
                style: _pop(
                  size: 12,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(MissionNotificationPreferences prefs) {
    final selected = regions
        .where((r) => prefs.selectedRegionCodes.contains('${r.code}'))
        .toList();
    final subtitle = selected.isEmpty
        ? _t('All regions', 'جميع المناطق', 'Toutes les régions')
        : '${selected.length}';
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A524).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Color(0xFFF5A524),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Regions', 'المناطق', 'Régions'),
                      style: _pop(
                        size: 13,
                        weight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t(
                        'Notify only about missions in selected regions',
                        'إشعار فقط بمهام في المناطق المحددة',
                        'Notifier uniquement les missions des régions sélectionnées',
                      ),
                      style: _pop(size: 10, color: const Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _selectRegion(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.expand_more,
                    size: 18,
                    color: Color(0xFF999999),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selected.isEmpty
                          ? _t(
                              'Select region',
                              'اختر المنطقة',
                              'Sélectionner la région',
                            )
                          : _t(
                              '$subtitle region(s) selected',
                              'تم تحديد $subtitle منطقة/مناطق',
                              '$subtitle région(s) sélectionnée(s)',
                            ),
                      style: _pop(
                        size: 12,
                        weight: FontWeight.w600,
                        color: selected.isEmpty
                            ? const Color(0xFF999999)
                            : const Color(0xFF111111),
                      ),
                    ),
                  ),
                  if (selected.isNotEmpty)
                    GestureDetector(
                      onTap: () =>
                          _updatePrefs((p) => p.selectedRegionCodes.clear()),
                      child: Text(
                        _t('Clear', 'مسح', 'Effacer'),
                        style: _pop(
                          size: 11,
                          weight: FontWeight.w600,
                          color: const Color(0xFFF5A524),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: selected
                  .take(4)
                  .map(
                    (r) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r.name(_lang),
                        style: _pop(
                          size: 10,
                          weight: FontWeight.w600,
                          color: const Color(0xFFF5A524),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (selected.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _t(
                    '+${selected.length - 4} more',
                    '+${selected.length - 4} أخرى',
                    '+${selected.length - 4} autres',
                  ),
                  style: _pop(size: 10, color: const Color(0xFF999999)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleCard(MissionNotificationPreferences prefs) {
    final familyMatches = truckFamilies
        .where((f) => f.id == prefs.truckId)
        .toList();
    final family = familyMatches.isEmpty ? null : familyMatches.first;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        'Vehicle / Truck',
                        'المركبة / الشاحنة',
                        'Véhicule / Camion',
                      ),
                      style: _pop(
                        size: 13,
                        weight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t(
                        'Only notify about missions your truck can handle',
                        'إشعار فقط بمهام تلائم شاحنتك',
                        'Notifier uniquement les missions compatibles avec votre camion',
                      ),
                      style: _pop(size: 10, color: const Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                label: _t('Any', 'الكل', 'Toutes'),
                selected: prefs.truckId == null,
                onTap: () => _updatePrefs((p) {
                  p.truckId = null;
                  p.truckSizeId = null;
                }),
              ),
              ...truckFamilies.map(
                (f) => _chip(
                  label: f.name(_lang),
                  selected: prefs.truckId == f.id,
                  onTap: () => _updatePrefs((p) {
                    p.truckId = f.id;
                    p.truckSizeId = null;
                  }),
                ),
              ),
            ],
          ),
          if (family != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  label: _t('Any size', 'أي حجم', 'Toute taille'),
                  selected: prefs.truckSizeId == null,
                  onTap: () => _updatePrefs((p) => p.truckSizeId = null),
                ),
                ...family.sizes.map(
                  (s) => _chip(
                    label: s.name(_lang),
                    selected: prefs.truckSizeId == s.id,
                    onTap: () => _updatePrefs((p) => p.truckSizeId = s.id),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleCard(MissionNotificationPreferences prefs) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule,
                  size: 20,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        'Notification hours',
                        'ساعات الإشعار',
                        'Heures de notification',
                      ),
                      style: _pop(
                        size: 13,
                        weight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t(
                        'Only send notifications during working hours',
                        'أرسل الإشعارات فقط خلال ساعات العمل',
                        'Recevoir les notifications uniquement pendant les heures de travail',
                      ),
                      style: _pop(size: 10, color: const Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _timeButton(
                  label: _t('Start', 'البداية', 'Début'),
                  value: _timeLabel(prefs.startMinute),
                  onTap: () => _pickTime(true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Color(0xFFCCCCCC),
                ),
              ),
              Expanded(
                child: _timeButton(
                  label: _t('End', 'النهاية', 'Fin'),
                  value: _timeLabel(prefs.endMinute),
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.all_inclusive,
                  size: 18,
                  color: Color(0xFF4CAF50),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t(
                          'Always receive notifications',
                          'استقبل الإشعارات دائماً',
                          'Recevoir toujours les notifications',
                        ),
                        style: _pop(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _t(
                          'Ignore the schedule above',
                          'تجاهل الجدول أعلاه',
                          'Ignorer l\'horaire ci-dessus',
                        ),
                        style: _pop(size: 10, color: const Color(0xFF999999)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: prefs.alwaysReceive,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF4CAF50),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE0E0E0),
                  onChanged: _saving
                      ? null
                      : (value) => _updatePrefs((p) => p.alwaysReceive = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(MissionNotificationPreferences prefs) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(
              'Send a notification now to verify everything works.',
              'أرسل إشعاراً الآن للتأكد من أن كل شيء يعمل.',
              'Envoyez une notification maintenant pour vérifier que tout fonctionne.',
            ),
            style: _pop(size: 11, color: const Color(0xFF999999), height: 1.5),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _saving ? null : () => _sendTestNotification(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A524),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF5A524).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _t(
                      'Send test notification',
                      'إرسال إشعار اختباري',
                      'Envoyer une notification de test',
                    ),
                    style: _pop(
                      size: 14,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5A524) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFF5A524) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: _pop(
            size: 11,
            weight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  Widget _timeButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          children: [
            Text(label, style: _pop(size: 10, color: const Color(0xFF999999))),
            const SizedBox(height: 2),
            Text(
              value,
              style: _pop(
                size: 18,
                weight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RegionPickerSheet extends StatefulWidget {
  final Set<String> selectedCodes;
  final String lang;
  final String Function(String, String, String) t;

  const _RegionPickerSheet({
    required this.selectedCodes,
    required this.lang,
    required this.t,
  });

  @override
  State<_RegionPickerSheet> createState() => _RegionPickerSheetState();
}

class _RegionPickerSheetState extends State<_RegionPickerSheet> {
  late final Set<String> _selection = Set.of(widget.selectedCodes);
  String _query = '';

  List<Region> get _visible {
    final normalized = normalizeRegionText(_query);
    if (normalized.isEmpty) return regions;
    return regions.where((r) {
      final names = '${r.en.toLowerCase()} ${r.fr.toLowerCase()}'.replaceAll(
        'é',
        'e',
      );
      return names.contains(normalized);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.lang == 'AR';
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.t(
                    'Select regions',
                    'اختر المناطق',
                    'Sélectionner les régions',
                  ),
                  style: _pop(
                    size: 18,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
                Text(
                  _countLabel(),
                  style: _pop(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color(0xFFF5A524),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
              child: Row(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  const Icon(Icons.search, size: 18, color: Color(0xFFBBBBBB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      textDirection: isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: widget.t(
                          'Search wilaya...',
                          'ابحث عن ولاية...',
                          'Rechercher une wilaya...',
                        ),
                        hintStyle: _pop(
                          size: 13,
                          color: const Color(0xFFBBBBBB),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: _pop(size: 13, color: const Color(0xFF111111)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              itemCount: _visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final region = _visible[index];
                final selected = _selection.contains('${region.code}');
                return GestureDetector(
                  onTap: () => setState(() {
                    final code = '${region.code}';
                    if (!_selection.add(code)) _selection.remove(code);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFFF7E6) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFF5A524)
                            : const Color(0xFFEFEFEF),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      textDirection: isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      children: [
                        Text(
                          '${region.code.toString().padLeft(2, '0')}  ${region.name(widget.lang)}',
                          style: _pop(
                            size: 13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF111111),
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Color(0xFFF5A524),
                          )
                        else
                          const Icon(
                            Icons.circle_outlined,
                            size: 20,
                            color: Color(0xFFDDDDDD),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context, _selection),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A524),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5A524).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  widget.t('Apply', 'تطبيق', 'Appliquer'),
                  textAlign: TextAlign.center,
                  style: _pop(
                    size: 14,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _countLabel() {
    if (_selection.isEmpty) return widget.t('None', 'لا شيء', 'Aucune');
    final n = _selection.length;
    return widget.t('$n selected', 'تم تحديد $n', '$n sélectionnée(s)');
  }
}
