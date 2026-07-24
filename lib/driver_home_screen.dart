import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';
import 'verification_flow_screen.dart';

TextStyle _pop({double? size, FontWeight? weight, Color? color, double? height, double? letterSpacing}) {
  return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);
}

class _Mission {
  final String id;
  final String clientName;
  final String clientPhone;
  final String departure;
  final String arrival;
  final String date;
  final String time;
  final String truckType;
  final String truckSize;
  final String category;
  final String capacity;
  final int workers;
  final String distance;
  final String price;
  final String status;

  const _Mission({
    required this.id, required this.clientName, required this.clientPhone,
    required this.departure, required this.arrival, required this.date,
    required this.time, required this.truckType, required this.truckSize,
    required this.category, required this.capacity, required this.workers,
    required this.distance, required this.price, required this.status,
  });
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _verified = false;
  int _activeTab = 0;
  int _statusFilter = 0;
  String _searchTerm = '';
  String _sortBy = 'date';
  bool _sortAsc = true;
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

  final List<_Mission> _availableMissions = const [
    _Mission(id: 'M-001', clientName: 'Ahmed Benali', clientPhone: '0555123456', departure: 'Algiers', arrival: 'Oran', date: '2026-07-25', time: '09:00', truckType: 'Camion', truckSize: 'Large', category: 'General', capacity: '20T', workers: 2, distance: '420 km', price: '15,000 DZD', status: 'PENDING'),
    _Mission(id: 'M-002', clientName: 'Sara Khelifi', clientPhone: '0661987654', departure: 'Constantine', arrival: 'Annaba', date: '2026-07-26', time: '14:30', truckType: 'Fourgon', truckSize: 'Medium', category: 'Furniture', capacity: '10T', workers: 1, distance: '180 km', price: '8,500 DZD', status: 'PENDING'),
    _Mission(id: 'M-003', clientName: 'Omar Saidi', clientPhone: '0770112233', departure: 'Blida', arrival: 'Setif', date: '2026-07-27', time: '08:00', truckType: 'Harbina', truckSize: 'Short', category: 'Construction', capacity: '15T', workers: 3, distance: '300 km', price: '12,000 DZD', status: 'PENDING'),
    _Mission(id: 'M-004', clientName: 'Fatima Zeroual', clientPhone: '0550445566', departure: 'Tlemcen', arrival: 'Bejaia', date: '2026-07-28', time: '10:00', truckType: 'Camion', truckSize: 'Small', category: 'Electronics', capacity: '5T', workers: 1, distance: '520 km', price: '18,000 DZD', status: 'PENDING'),
  ];

  final List<_Mission> _myMissions = const [
    _Mission(id: 'M-010', clientName: 'Yacine Brahimi', clientPhone: '0661334455', departure: 'Algiers', arrival: 'Tizi Ouzou', date: '2026-07-24', time: '07:30', truckType: 'Camion', truckSize: 'Large', category: 'Goods', capacity: '18T', workers: 2, distance: '100 km', price: '6,000 DZD', status: 'ACCEPTED'),
    _Mission(id: 'M-011', clientName: 'Nadia Amrani', clientPhone: '0770998877', departure: 'Oran', arrival: 'Mascara', date: '2026-07-23', time: '11:00', truckType: 'Fourgon', truckSize: 'Short', category: 'Food', capacity: '8T', workers: 1, distance: '90 km', price: '4,500 DZD', status: 'IN_PROGRESS'),
    _Mission(id: 'M-012', clientName: 'Karim Touati', clientPhone: '0555667788', departure: 'Setif', arrival: 'Batna', date: '2026-07-20', time: '13:00', truckType: 'Harbina', truckSize: 'Long', category: 'Industrial', capacity: '25T', workers: 3, distance: '200 km', price: '10,000 DZD', status: 'COMPLETED'),
  ];

  List<_Mission> get _filteredAvailable {
    var list = _availableMissions.where((m) {
      if (_searchTerm.isNotEmpty) {
        final q = _searchTerm.toLowerCase();
        return m.clientName.toLowerCase().contains(q) || m.departure.toLowerCase().contains(q) || m.arrival.toLowerCase().contains(q) || m.id.toLowerCase().contains(q);
      }
      return true;
    }).toList();
    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'price': cmp = int.parse(a.price.replaceAll(RegExp(r'[^0-9]'), '')).compareTo(int.parse(b.price.replaceAll(RegExp(r'[^0-9]'), '')));
        case 'id': cmp = a.id.compareTo(b.id);
        default: cmp = a.date.compareTo(b.date);
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  List<_Mission> get _filteredMyMissions {
    final filters = ['ALL', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED'];
    final filter = _statusFilter < filters.length ? filters[_statusFilter] : 'ALL';
    return _myMissions.where((m) {
      final statusMatch = filter == 'ALL' || m.status == filter;
      if (_searchTerm.isEmpty) return statusMatch;
      final q = _searchTerm.toLowerCase();
      return statusMatch && (m.clientName.toLowerCase().contains(q) || m.departure.toLowerCase().contains(q) || m.arrival.toLowerCase().contains(q) || m.id.toLowerCase().contains(q));
    }).toList();
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
            child: RefreshIndicator(
              onRefresh: () async {},
              color: const Color(0xFFF5A524),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_verified) _buildVerificationBanner(),
                    if (!_verified) const SizedBox(height: 16),
                    _buildTabBar(),
                    const SizedBox(height: 14),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildSortBar(),
                    const SizedBox(height: 14),
                    if (_activeTab == 0) ..._buildAvailableList() else ..._buildMyMissionsList(),
                  ],
                ),
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
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 14),
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
              if (_verified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 12, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(_t('Verified', 'موثق', 'Vérifié'), style: _pop(size: 9, weight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ],
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

  Widget _buildVerificationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5A524).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF5A524), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.verified_user, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('Verify your account', 'تحقق من حسابك', 'Vérifiez votre compte'),
                    style: _pop(size: 15, weight: FontWeight.w700, color: const Color(0xFF111111))),
                  const SizedBox(height: 2),
                  Text(_t('Complete your identity and vehicle verification before you can start accepting missions.',
                    'أكمل التحقق من هويتك ومركتك قبل أن تتمكن من قبول المهام.',
                    'Complétez la vérification de votre identité et de votre véhicule avant de pouvoir accepter des missions.'),
                    style: _pop(size: 12, color: const Color(0xFF666666))),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationFlowScreen()));
              if (result == true) setState(() { _verified = true; });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A524),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 3))],
              ),
              child: Text(_t('Verify Account', 'تحقق من الحساب', 'Vérifier le compte'),
                textAlign: TextAlign.center,
                style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        Expanded(child: _buildTab(0, _t('Available', 'متاح', 'Disponibles'))),
        const SizedBox(width: 8),
        Expanded(child: _buildTab(1, _t('My Missions', 'مهامي', 'Mes missions'))),
      ],
    );
  }

  Widget _buildTab(int index, String label) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() { _activeTab = index; _statusFilter = 0; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF5A524) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label, style: _pop(size: 13, weight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF999999))),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: Color(0xFFBBBBBB)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchTerm = v),
              style: _pop(size: 13, color: const Color(0xFF111111)),
              decoration: InputDecoration(
                hintText: _t('Search by name, city or ID...', 'بحث بالاسم أو المدينة أو المعرف...', 'Rechercher par nom, ville ou ID...'),
                hintStyle: _pop(size: 13, color: const Color(0xFFBBBBBB)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Row(
      children: [
        Icon(Icons.sort, size: 18, color: const Color(0xFF999999)),
        const SizedBox(width: 6),
        DropdownButton<String>(
          value: _sortBy,
          underline: const SizedBox(),
          isDense: true,
          style: _pop(size: 12, color: const Color(0xFF555555)),
          items: [
            DropdownMenuItem(value: 'date', child: Text(_t('Date', 'التاريخ', 'Date'))),
            DropdownMenuItem(value: 'price', child: Text(_t('Price', 'السعر', 'Prix'))),
            DropdownMenuItem(value: 'id', child: Text(_t('ID', 'المعرف', 'ID'))),
          ],
          onChanged: (v) { if (v != null) setState(() => _sortBy = v); },
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _sortAsc = !_sortAsc),
          child: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 18, color: const Color(0xFFF5A524)),
        ),
        const Spacer(),
        if (_activeTab == 1) _buildStatusFilterChips(),
      ],
    );
  }

  Widget _buildStatusFilterChips() {
    final labels = [_t('All', 'الكل', 'Tous'), _t('Accepted', 'مقبول', 'Accepté'), _t('In Progress', 'قيد التنفيذ', 'En cours'), _t('Completed', 'مكتمل', 'Terminé')];
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = _statusFilter == i;
          return GestureDetector(
            onTap: () => setState(() => _statusFilter = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFF5A524) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(labels[i], style: _pop(size: 11, weight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF999999)))),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildAvailableList() {
    final list = _filteredAvailable;
    if (list.isEmpty) return [_buildEmpty()];
    return list.map((m) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildMissionCard(m, isAvailable: true),
    )).toList();
  }

  List<Widget> _buildMyMissionsList() {
    final list = _filteredMyMissions;
    if (list.isEmpty) return [_buildEmpty()];
    return list.map((m) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildMissionCard(m),
    )).toList();
  }

  Widget _buildMissionCard(_Mission m, {bool isAvailable = false}) {
    return GestureDetector(
      onTap: () => _showMissionDetails(m),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(m.id, style: _pop(size: 11, weight: FontWeight.w600, color: const Color(0xFF999999))),
                _buildStatusBadge(m.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Color(0xFF999999)),
                const SizedBox(width: 6),
                Text(m.clientName, style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFF111111))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 6),
                      Expanded(child: Text(m.departure, maxLines: 1, overflow: TextOverflow.ellipsis, style: _pop(size: 12, color: const Color(0xFF555555)))),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 14, color: Color(0xFFCCCCCC)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFFF5A524), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 6),
                      Expanded(child: Text(m.arrival, maxLines: 1, overflow: TextOverflow.ellipsis, style: _pop(size: 12, color: const Color(0xFF555555)))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoChip(Icons.calendar_today_outlined, '${m.date} ${m.time}'),
                const SizedBox(width: 8),
                _infoChip(Icons.local_shipping_outlined, '${m.truckType} ${m.truckSize}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _infoChip(Icons.straighten, m.distance),
                const SizedBox(width: 8),
                _infoChip(Icons.attach_money, m.price),
              ],
            ),
            if (isAvailable) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A524),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_t('Accept', 'قبول', 'Accepter'),
                    textAlign: TextAlign.center,
                    style: _pop(size: 13, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFFBBBBBB)),
        const SizedBox(width: 4),
        Text(text, style: _pop(size: 11, color: const Color(0xFF777777))),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg; Color fg; String label;
    switch (status) {
      case 'PENDING': bg = const Color(0xFFE8F5E9); fg = const Color(0xFF4CAF50); label = _t('Available', 'متاح', 'Disponible'); break;
      case 'ACCEPTED': bg = const Color(0xFFE3F2FD); fg = const Color(0xFF2196F3); label = _t('Accepted', 'مقبول', 'Accepté'); break;
      case 'IN_PROGRESS': bg = const Color(0xFFFFF3E0); fg = const Color(0xFFF5A524); label = _t('In Progress', 'قيد التنفيذ', 'En cours'); break;
      default: bg = const Color(0xFFF5F5F5); fg = const Color(0xFF999999); label = _t('Completed', 'مكتمل', 'Terminé');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: _pop(size: 10, weight: FontWeight.w600, color: fg)),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: const Color(0xFFDDDDDD)),
            const SizedBox(height: 12),
            Text(_t('No missions found', 'لا توجد مهام', 'Aucune mission trouvée'),
              style: _pop(size: 14, color: const Color(0xFFBBBBBB))),
          ],
        ),
      ),
    );
  }

  void _showMissionDetails(_Mission m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildMissionDetailsSheet(m),
    );
  }

  Widget _buildMissionDetailsSheet(_Mission m) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
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
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_t('Mission Details', 'تفاصيل المهمة', 'Détails de la mission'),
                        style: _pop(size: 18, weight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, size: 24, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _detailSection(_t('Client Info', 'معلومات العميل', 'Info client'), [
                    _detailRow(_t('Name', 'الاسم', 'Nom'), m.clientName),
                    _detailRow(_t('Phone', 'الهاتف', 'Téléphone'), m.clientPhone),
                  ]),
                  const SizedBox(height: 16),
                  _detailSection(_t('Route', 'المسار', 'Itinéraire'), [
                    _detailRow(_t('Departure', 'المغادرة', 'Départ'), m.departure),
                    _detailRow(_t('Arrival', 'الوصول', 'Arrivée'), m.arrival),
                    _detailRow(_t('Distance', 'المسافة', 'Distance'), m.distance),
                  ]),
                  const SizedBox(height: 16),
                  _detailSection(_t('Schedule', 'الجدول', 'Horaire'), [
                    _detailRow(_t('Date', 'التاريخ', 'Date'), m.date),
                    _detailRow(_t('Time', 'الوقت', 'Heure'), m.time),
                  ]),
                  const SizedBox(height: 16),
                  _detailSection(_t('Vehicle', 'المركبة', 'Véhicule'), [
                    _detailRow(_t('Type', 'النوع', 'Type'), m.truckType),
                    _detailRow(_t('Size', 'الحجم', 'Taille'), m.truckSize),
                    _detailRow(_t('Category', 'الفئة', 'Catégorie'), m.category),
                    _detailRow(_t('Capacity', 'القدرة', 'Capacité'), m.capacity),
                  ]),
                  const SizedBox(height: 16),
                  _detailSection(_t('Additional', 'إضافي', 'Supplémentaire'), [
                    _detailRow(_t('Workers', 'العمال', 'Ouvriers'), m.workers.toString()),
                    _detailRow(_t('Price', 'السعر', 'Prix'), m.price),
                  ]),
                  const SizedBox(height: 24),
                  if (m.status == 'ACCEPTED')
                    _actionButton(_t('Start Mission', 'بدء المهمة', 'Commencer la mission'), () => Navigator.pop(ctx)),
                  if (m.status == 'IN_PROGRESS')
                    _actionButton(_t('Complete Mission', 'إتمام المهمة', 'Terminer la mission'), () => Navigator.pop(ctx)),
                  if (m.status == 'PENDING')
                    _actionButton(_t('Accept Mission', 'قبول المهمة', 'Accepter la mission'), () => Navigator.pop(ctx)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _pop(size: 14, weight: FontWeight.w700, color: const Color(0xFFF5A524))),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _pop(size: 12, color: const Color(0xFF999999))),
          Text(value, style: _pop(size: 12, weight: FontWeight.w600, color: const Color(0xFF111111))),
        ],
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5A524),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: _pop(size: 15, weight: FontWeight.w700, color: Colors.white)),
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
