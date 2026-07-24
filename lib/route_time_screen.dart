import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_language.dart';
import 'order_model.dart';
import 'send_order_screen.dart';

TextStyle _pop({double? size, FontWeight? weight, Color? color, double? height, double? letterSpacing}) {
  return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);
}

class RouteTimeScreen extends StatefulWidget {
  final OrderData orderData;
  final VoidCallback onBack;
  const RouteTimeScreen({super.key, required this.orderData, required this.onBack});

  @override
  State<RouteTimeScreen> createState() => _RouteTimeScreenState();
}

class _RouteTimeScreenState extends State<RouteTimeScreen> {
  final MapController _mapController = MapController();

  String _pickup = '';
  String _delivery = '';
  Map<String, double>? _pickupCoords;
  Map<String, double>? _deliveryCoords;
  bool _isNow = true;
  DateTime? _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _selectingPickup = true;
  String _searchQuery = '';

  String get _lang => appLanguage.lang;
  bool get _isArabic => _lang == 'AR';
  bool get _isRtl => _isArabic;

  String _t(String en, String ar, String fr) {
    if (_isArabic) return ar;
    if (_lang == 'FR') return fr;
    return en;
  }

  String? get _distance {
    if (_pickupCoords == null || _deliveryCoords == null) return null;
    final d = _calcDistance(_pickupCoords!['lat']!, _pickupCoords!['lng']!, _deliveryCoords!['lat']!, _deliveryCoords!['lng']!);
    return '${d.toStringAsFixed(2)} km';
  }

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLangChanged);
    if (widget.orderData.pickup.isNotEmpty) _pickup = widget.orderData.pickup;
    if (widget.orderData.delivery.isNotEmpty) _delivery = widget.orderData.delivery;
    if (widget.orderData.pickupCoords != null) _pickupCoords = widget.orderData.pickupCoords;
    if (widget.orderData.deliveryCoords != null) _deliveryCoords = widget.orderData.deliveryCoords;
    if (!widget.orderData.isNow) {
      _isNow = false;
      if (widget.orderData.manualDate.isNotEmpty) {
        try { _selectedDate = DateTime.parse(widget.orderData.manualDate); } catch (_) {}
      }
      if (widget.orderData.manualTime.isNotEmpty) {
        final parts = widget.orderData.manualTime.split(':');
        if (parts.length == 2) {
          _selectedTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
        }
      }
    }
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() { setState(() {}); }

  double _calcDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void _openMapModal(bool isPickup) {
    _selectingPickup = isPickup;
    _searchQuery = '';
    setState(() {});
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildMapModal(),
    );
  }

  void _openDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildDatePickerModal(),
    );
  }

  void _openTimePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildTimePickerModal(),
    );
  }

  void _validate() {
    if (_pickup.isEmpty || _delivery.isEmpty || _pickupCoords == null || _deliveryCoords == null) {
      _showError(_t(
        'Please ensure you have selected both Pickup and Delivery points on the map.',
        'تأكد من تحديد نقطة الاستلام والتسليم على الخريطة.',
        'Veuillez sélectionner les points de prise en charge et de livraison sur la carte.',
      ));
      return;
    }
    if (!_isNow && _selectedDate == null) {
      _showError(_t(
        'Please select a date.',
        'يرجى اختيار تاريخ.',
        'Veuillez sélectionner une date.',
      ));
      return;
    }
    widget.orderData.pickup = _pickup;
    widget.orderData.delivery = _delivery;
    widget.orderData.pickupCoords = _pickupCoords;
    widget.orderData.deliveryCoords = _deliveryCoords;
    widget.orderData.distance = _distance;
    widget.orderData.isNow = _isNow;
    if (_isNow) {
      final now = DateTime.now();
      widget.orderData.manualDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      widget.orderData.manualTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    } else {
      widget.orderData.manualDate = _selectedDate != null
          ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
          : '';
      widget.orderData.manualTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendOrderScreen(
          orderData: widget.orderData,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_t('Error', 'خطأ', 'Erreur'), style: _pop(size: 18, weight: FontWeight.w700)),
        content: Text(msg, style: _pop(size: 13, color: const Color(0xFF555555))),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFF5A524), borderRadius: BorderRadius.circular(14)),
              child: Text(_t('OK', 'حسناً', 'OK'), style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
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
                  const SizedBox(height: 20),
                  _buildRouteSection(),
                  const SizedBox(height: 28),
                  _buildDateTimeSection(),
                  const SizedBox(height: 32),
                  _buildNextButton(),
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

  Widget _buildRouteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          SvgPicture.asset('assets/images/solid_route.svg', width: 20, height: 20),
          const SizedBox(width: 8),
          Text(_t('Route', 'الطريق', 'Itinéraire'),
            style: _pop(size: 18, weight: FontWeight.w700, color: const Color(0xFF111111))),
        ]),
        const SizedBox(height: 20),
        _buildPointRow(true),
        const SizedBox(height: 16),
        _buildPointRow(false),
        if (_distance != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A524),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_t('Distance', 'المسافة', 'Distance')}: $_distance',
                style: _pop(size: 13, weight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPointRow(bool isPickup) {
    final address = isPickup ? _pickup : _delivery;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          SvgPicture.asset(isPickup ? 'assets/images/maplite.svg' : 'assets/images/flag.svg', width: 16, height: 16),
          const SizedBox(width: 6),
          Text(isPickup ? _t('Pickup Point', 'نقطة الاستلام', 'Point de prise en charge')
              : _t('Delivery Point', 'نقطة التسليم', 'Point de livraison'),
            style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFF555555))),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openMapModal(isPickup),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
            ),
            child: Row(
              children: [
                SvgPicture.asset('assets/images/search.svg', width: 16, height: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    address.isEmpty ? _t('Search or select on map', 'ابحث أو اختر على الخريطة', 'Rechercher ou sélectionner sur la carte') : address,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: _pop(size: 13, color: address.isEmpty ? const Color(0xFFBBBBBB) : const Color(0xFF111111)),
                  ),
                ),
                const SizedBox(width: 8),
                SvgPicture.asset('assets/images/uiw_map.svg', width: 18, height: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(children: [
                SvgPicture.asset('assets/images/agenda.svg', width: 20, height: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(_t('Pickup Date and Time', 'تاريخ ووقت الاستلام', 'Date et heure de prise en charge'),
                    style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111)),
                    overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            _buildNowLaterToggle(),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _isNow ? null : _openDatePicker,
          child: _buildInputField(
            icon: 'assets/images/agenda1.svg',
            text: _selectedDate != null
                ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                : _t('Enter the Date', 'أدخل التاريخ', 'Entrez la date'),
            enabled: !_isNow,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isNow ? null : _openTimePicker,
          child: _buildInputField(
            icon: 'assets/images/clock1.svg',
            text: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
            enabled: !_isNow,
          ),
        ),
      ],
    );
  }

  Widget _buildNowLaterToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildToggleBtn(_t('Later', 'لاحقاً', 'Plus tard'), !_isNow, () {
            setState(() { _isNow = false; });
          }),
          _buildToggleBtn(_t('Now', 'الآن', 'Maintenant'), _isNow, () {
            setState(() {
              _isNow = true;
              final now = DateTime.now();
              _selectedDate = now;
              _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
            });
          }),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF5A524) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: _pop(size: 12, weight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF999999))),
      ),
    );
  }

  Widget _buildInputField({required String icon, required String text, bool enabled = true}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8F8F8) : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Row(
        children: [
          SvgPicture.asset(icon, width: 18, height: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text,
            style: _pop(size: 13, color: enabled ? const Color(0xFF111111) : const Color(0xFFBBBBBB)))),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
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
        child: Text(_t('Next', 'التالي', 'Suivant'),
          textAlign: TextAlign.center,
          style: _pop(size: 16, weight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  // ═══════════════ MAP MODAL ═══════════════

  Widget _buildMapModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          child: Column(
            children: [
              _buildMapModalHeader(setModalState),
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(28.0339, 1.6596),
                    initialZoom: 5,
                    onTap: (tapPos, latLng) async {
                      await _handleMapTap(latLng, setModalState);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.orizzonte.app',
                    ),
                    if (_currentMarker != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _currentMarker!,
                          width: 40, height: 40,
                          child: Icon(Icons.location_pin, color: Color(0xFFF5A524), size: 40),
                        ),
                      ]),
                  ],
                ),
              ),
              _buildMapConfirmButton(setModalState),
            ],
          ),
        );
      },
    );
  }

  LatLng? _currentMarker;

  Widget _buildMapModalHeader(StateSetter setModalState) {
    final topPad = MediaQuery.of(context).viewPadding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(_t('Cancel', 'إلغاء', 'Annuler'), style: _pop(size: 14, weight: FontWeight.w600, color: const Color(0xFF999999))),
              ),
              const Spacer(),
              Text(_selectingPickup ? _t('Pickup Point', 'نقطة الاستلام', 'Prise en charge') : _t('Delivery Point', 'نقطة التسليم', 'Livraison'),
                style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
              const Spacer(),
              const SizedBox(width: 60),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SvgPicture.asset('assets/images/search.svg', width: 18, height: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (v) => _searchQuery = v,
                  style: _pop(size: 13),
                  decoration: InputDecoration(
                    hintText: _t('Search address...', 'ابحث عن عنوان...', 'Rechercher une adresse...'),
                    hintStyle: _pop(size: 13, color: const Color(0xFFBBBBBB)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (_searchQuery.isEmpty) return;
                  await _searchAddress(_searchQuery, setModalState);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF5A524), borderRadius: BorderRadius.circular(10)),
                  child: Text(_t('Find', 'بحث', 'Trouver'), style: _pop(size: 12, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapConfirmButton(StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      color: Colors.white,
      child: GestureDetector(
        onTap: () {
          if (_currentMarker == null || _currentAddress.isEmpty) return;
          if (_selectingPickup) {
            _pickup = _currentAddress;
            _pickupCoords = {'lat': _currentMarker!.latitude, 'lng': _currentMarker!.longitude};
          } else {
            _delivery = _currentAddress;
            _deliveryCoords = {'lat': _currentMarker!.latitude, 'lng': _currentMarker!.longitude};
          }
          setState(() {});
          Navigator.pop(context);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _currentMarker != null ? const Color(0xFFF5A524) : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(_t('Confirm Selection', 'تأكيد التحديد', 'Confirmer la sélection'),
            textAlign: TextAlign.center,
            style: _pop(size: 15, weight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }

  String _currentAddress = '';

  Future<void> _handleMapTap(LatLng latLng, StateSetter setModalState) async {
    setModalState(() {
      _currentMarker = latLng;
      _currentAddress = '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
    });
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}');
      final resp = await http.get(url, headers: {'User-Agent': 'OrizzonteApp/1.0'});
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final name = data['display_name'] as String? ?? '';
        if (name.isNotEmpty) {
          setModalState(() => _currentAddress = name);
        }
      }
    } catch (_) {}
  }

  Future<void> _searchAddress(String query, StateSetter setModalState) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&countrycodes=dz');
      final resp = await http.get(url, headers: {'User-Agent': 'OrizzonteApp/1.0'});
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString()) ?? 28.0339;
          final lon = double.tryParse(data[0]['lon'].toString()) ?? 1.6596;
          final name = data[0]['display_name'] as String? ?? query;
          _mapController.move(LatLng(lat, lon), 15);
          setModalState(() {
            _currentMarker = LatLng(lat, lon);
            _currentAddress = name;
            _searchQuery = '';
          });
        }
      }
    } catch (_) {}
  }

  // ═══════════════ DATE PICKER MODAL ═══════════════

  DateTime _calendarMonth = DateTime.now();

  Widget _buildDatePickerModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        final year = _calendarMonth.year;
        final month = _calendarMonth.month;
        final firstDay = DateTime(year, month, 1);
        final daysInMonth = DateTime(year, month + 1, 0).day;
        final startWeekday = firstDay.weekday % 7;

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setModalState(() {
                        _calendarMonth = DateTime(year, month - 1);
                      }),
                      child: const Icon(Icons.chevron_left, size: 24, color: Color(0xFF111111)),
                    ),
                    Text(_t('$year', '$year', '$year'),
                      style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
                    GestureDetector(
                      onTap: () => setModalState(() {
                        _calendarMonth = DateTime(year, month + 1);
                      }),
                      child: Icon(Icons.chevron_right, size: 24, color: const Color(0xFF111111)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_t(_monthName(month), _monthNameAr(month), _monthNameFr(month)),
                  style: _pop(size: 14, weight: FontWeight.w600, color: const Color(0xFF555555))),
                const SizedBox(height: 16),
                Row(
                  children: _t(
                    'Su,Mo,Tu,We,Th,Fr,Sa',
                    'أحد,إثن,ثلا,أرب,خمي,جمع,سبت',
                    'Di,Lu,Ma,Me,Je,Ve,Sa',
                  ).split(',').map((d) =>
                    Expanded(child: Center(child: Text(d, style: _pop(size: 12, weight: FontWeight.w600, color: const Color(0xFF999999)))))
                  ).toList(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(startWeekday + daysInMonth, (i) {
                    if (i < startWeekday) return const SizedBox(width: 40, height: 40);
                    final day = i - startWeekday + 1;
                    final date = DateTime(year, month, day);
                    final now = DateTime.now();
                    final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
                    final isSelected = _selectedDate != null &&
                        _selectedDate!.year == year && _selectedDate!.month == month && _selectedDate!.day == day;
                    return GestureDetector(
                      onTap: isPast ? null : () {
                        setModalState(() => _selectedDate = date);
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF5A524) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('$day', style: _pop(size: 13, weight: FontWeight.w600,
                            color: isPast ? const Color(0xFFDDDDDD) : isSelected ? Colors.white : const Color(0xFF111111))),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _monthName(int m) => ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][m - 1];
  String _monthNameAr(int m) => ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'][m - 1];
  String _monthNameFr(int m) => ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'][m - 1];

  // ═══════════════ TIME PICKER MODAL ═══════════════

  Widget _buildTimePickerModal() {
    int hour = _selectedTime.hour;
    int minute = _selectedTime.minute;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_t('Set Time', 'تعيين الوقت', 'Définir l\'heure'),
                  style: _pop(size: 18, weight: FontWeight.w700, color: const Color(0xFF111111))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeColumn('HH', hour, 23, (v) => setModalState(() => hour = v)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(':', style: _pop(size: 28, weight: FontWeight.w700, color: const Color(0xFF111111))),
                    ),
                    _buildTimeColumn('MM', minute, 59, (v) => setModalState(() => minute = v)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(_t('Dismiss', 'إلغاء', 'Annuler'),
                            textAlign: TextAlign.center,
                            style: _pop(size: 14, weight: FontWeight.w600, color: const Color(0xFF999999))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _selectedTime = TimeOfDay(hour: hour, minute: minute);
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5A524),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(_t('Save', 'حفظ', 'Enregistrer'),
                            textAlign: TextAlign.center,
                            style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeColumn(String label, int value, int max, ValueChanged<int> onChange) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => onChange((value + 1) > max ? 0 : value + 1),
          child: Container(
            width: 44, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.keyboard_arrow_up, size: 20, color: Color(0xFF111111)),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
          ),
          child: Center(
            child: Text(value.toString().padLeft(2, '0'),
              style: _pop(size: 20, weight: FontWeight.w700, color: const Color(0xFF111111))),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onChange((value - 1) < 0 ? max : value - 1),
          child: Container(
            width: 44, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF111111)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: _pop(size: 11, weight: FontWeight.w600, color: const Color(0xFF999999))),
      ],
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
