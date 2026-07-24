import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';
import 'verification_flow_screen.dart';

TextStyle _pop({double? size, FontWeight? weight, Color? color, double? height, double? letterSpacing}) {
  return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);
}

String _truckImage(String truckType, String truckSize) {
  final t = truckType.toLowerCase();
  final s = truckSize.toLowerCase();
  if (t == 'camion') {
    if (s == 'small') return 'assets/images/CAMION_SMALL.png';
    if (s == 'large') return 'assets/images/CAMION_LARGE.png';
    return 'assets/images/CAMION_GENERAL.png';
  }
  if (t == 'fourgon') {
    if (s == 'short') return 'assets/images/FOURGON_SHORT.png';
    if (s == 'medium') return 'assets/images/FOURGON_MEDIUM.png';
    if (s == 'long') return 'assets/images/FOURGON_LONG.png';
    return 'assets/images/FOURGON_GENERAL.png';
  }
  if (t == 'harbina') {
    if (s == 'short') return 'assets/images/HARBINA_SHORT.png';
    if (s == 'long') return 'assets/images/HARBINA_LONG.png';
    return 'assets/images/HARBINA_GENERAL.png';
  }
  return 'assets/images/truck.svg';
}

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _verified = 0;

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
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() { setState(() {}); }

  final List<Map<String, String>> _available = const [
    {'id': 'M-001', 'client': 'Ahmed Benali', 'from': 'Algiers', 'to': 'Oran', 'date': '25 Jul 09:00', 'truck': 'Camion', 'size': 'Large', 'dist': '420 km', 'price': '15,000 DZD'},
    {'id': 'M-002', 'client': 'Sara Khelifi', 'from': 'Constantine', 'to': 'Annaba', 'date': '26 Jul 14:30', 'truck': 'Fourgon', 'size': 'Medium', 'dist': '180 km', 'price': '8,500 DZD'},
    {'id': 'M-003', 'client': 'Omar Saidi', 'from': 'Blida', 'to': 'Setif', 'date': '27 Jul 08:00', 'truck': 'Harbina', 'size': 'Short', 'dist': '300 km', 'price': '12,000 DZD'},
    {'id': 'M-004', 'client': 'Fatima Zeroual', 'from': 'Tlemcen', 'to': 'Bejaia', 'date': '28 Jul 10:00', 'truck': 'Camion', 'size': 'Small', 'dist': '520 km', 'price': '18,000 DZD'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_verified == 0) ...[
            _buildVerifyBanner(),
            const SizedBox(height: 16),
          ],
          if (_verified == 1) ...[
            _buildReviewBanner(),
            const SizedBox(height: 16),
          ],
          _buildQuickStats(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t('Available Missions', 'المهام المتاحة', 'Missions disponibles'),
                style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
              Row(
                children: [
                  Text('${_available.length}', style: _pop(size: 14, weight: FontWeight.w700, color: const Color(0xFFF5A524))),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _showFilterPage(),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                      ),
                      child: const Icon(Icons.tune, size: 16, color: Color(0xFF999999)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._available.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProfessionalCard(m),
          )),
        ],
      ),
    );
  }

  Widget _buildVerifyBanner() {
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
                  Text(_t('Complete verification to start accepting missions.', 'أكمل التحقق لتتمكن من قبول المهام.', 'Complétez la vérification pour accepter des missions.'),
                    style: _pop(size: 12, color: const Color(0xFF666666))),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationFlowScreen()));
              if (result == true) setState(() { _verified = 1; });
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

  Widget _buildReviewBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFF2196F3), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.hourglass_top, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('Documents under review', 'المستندات قيد المراجعة', 'Documents en cours de révision'),
                  style: _pop(size: 15, weight: FontWeight.w700, color: const Color(0xFF111111))),
                const SizedBox(height: 2),
                Text(_t('Your submitted documents are being reviewed. This usually takes 24-48 hours.', 'مستنداتك المرسلة قيد المراجعة. يستغرق هذا عادة 24-48 ساعة.', 'Vos documents sont en cours de révision. 24-48 heures.'),
                  style: _pop(size: 12, color: const Color(0xFF666666))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(_t('Available', 'متاح', 'Disponibles'), '${_available.length}', Icons.assignment_outlined, const Color(0xFFF5A524))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(_t('Accepted', 'مقبول', 'Acceptées'), '1', Icons.check_circle_outline, const Color(0xFF2196F3))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(_t('Completed', 'مكتمل', 'Terminées'), '3', Icons.verified_outlined, const Color(0xFF4CAF50))),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(value, style: _pop(size: 24, weight: FontWeight.w800, color: const Color(0xFF111111))),
          const SizedBox(height: 4),
          Text(label, style: _pop(size: 11, color: const Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildProfessionalCard(Map<String, String> m) {
    final img = _truckImage(m['truck']!, m['size']!);
    final isSvg = img.endsWith('.svg');
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Row 1: image LEFT, type + client RIGHT
            Row(
              children: [
                Container(
                  width: 80, height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isSvg
                    ? Padding(padding: const EdgeInsets.all(8), child: SvgPicture.asset(img, fit: BoxFit.contain))
                    : Padding(padding: const EdgeInsets.all(4), child: Image.asset(img, fit: BoxFit.contain)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${m['truck']} ${m['size']}', style: _pop(size: 14, weight: FontWeight.w700, color: const Color(0xFF111111))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                            child: Text(_t('Available', 'متاح', 'Disponible'), style: _pop(size: 9, weight: FontWeight.w700, color: const Color(0xFF4CAF50))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(m['client']!, style: _pop(size: 12, color: const Color(0xFF999999))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(m['from']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: _pop(size: 10, weight: FontWeight.w500, color: const Color(0xFF333333)))),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.arrow_forward, size: 10, color: Color(0xFFCCCCCC))),
                          Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFF5A524), shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(m['to']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: _pop(size: 10, weight: FontWeight.w500, color: const Color(0xFF333333)))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Row 2: date, distance, price
            Row(
              children: [
                _metaChip(Icons.calendar_today_outlined, m['date']!),
                const SizedBox(width: 12),
                _metaChip(Icons.straighten, m['dist']!),
                const Spacer(),
                Text(m['price']!, style: _pop(size: 13, weight: FontWeight.w800, color: const Color(0xFFF5A524))),
              ],
            ),
            const SizedBox(height: 10),
            // Row 3: action button
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A524),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text(_t('Accept Mission', 'قبول المهمة', 'Accepter la mission'),
                  textAlign: TextAlign.center,
                  style: _pop(size: 12, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFFBBBBBB)),
        const SizedBox(width: 4),
        Text(text, style: _pop(size: 11, color: const Color(0xFF777777))),
      ],
    );
  }

  void _showFilterPage() {
    String vehicleType = 'All';
    String priceRange = 'All';
    String distanceRange = 'All';
    String sortBy = 'Date';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_t('Filters', 'الفلاتر', 'Filtres'),
                        style: _pop(size: 20, weight: FontWeight.w700, color: const Color(0xFF111111))),
                      GestureDetector(
                        onTap: () => setModalState(() {
                          vehicleType = 'All';
                          priceRange = 'All';
                          distanceRange = 'All';
                          sortBy = 'Date';
                        }),
                        child: Text(_t('Reset', 'إعادة', 'Réinitialiser'),
                          style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFFF5A524))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _filterSectionTitle(_t('Vehicle Type', 'نوع المركبة', 'Type de véhicule')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['All', 'Camion', 'Fourgon', 'Harbina'].map((t) {
                      final sel = vehicleType == t;
                      return GestureDetector(
                        onTap: () => setModalState(() => vehicleType = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFF5A524) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? const Color(0xFFF5A524) : const Color(0xFFE0E0E0)),
                          ),
                          child: Text(t == 'All' ? _t('All', 'الكل', 'Toutes') : t,
                            style: _pop(size: 12, weight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF666666))),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _filterSectionTitle(_t('Price Range', 'نطاق السعر', 'Fourchette de prix')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['All', '< 10,000', '10,000 - 15,000', '15,000 - 20,000', '> 20,000'].map((p) {
                      final sel = priceRange == p;
                      return GestureDetector(
                        onTap: () => setModalState(() => priceRange = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFF5A524) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? const Color(0xFFF5A524) : const Color(0xFFE0E0E0)),
                          ),
                          child: Text(p == 'All' ? _t('All', 'الكل', 'Toutes') : '$p DZD',
                            style: _pop(size: 11, weight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF666666))),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _filterSectionTitle(_t('Distance', 'المسافة', 'Distance')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['All', '< 200 km', '200 - 400 km', '400 - 600 km', '> 600 km'].map((d) {
                      final sel = distanceRange == d;
                      return GestureDetector(
                        onTap: () => setModalState(() => distanceRange = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFF5A524) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? const Color(0xFFF5A524) : const Color(0xFFE0E0E0)),
                          ),
                          child: Text(d == 'All' ? _t('All', 'الكل', 'Toutes') : d,
                            style: _pop(size: 11, weight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF666666))),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _filterSectionTitle(_t('Sort By', 'ترتيب حسب', 'Trier par')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['Date', 'Price ↑', 'Price ↓', 'Distance'].map((s) {
                      final sel = sortBy == s;
                      return GestureDetector(
                        onTap: () => setModalState(() => sortBy = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFF5A524) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? const Color(0xFFF5A524) : const Color(0xFFE0E0E0)),
                          ),
                          child: Text(s,
                            style: _pop(size: 11, weight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF666666))),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A524),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: const Color(0xFFF5A524).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                      child: Text(_t('Apply Filters', 'تطبيق الفلاتر', 'Appliquer'),
                        textAlign: TextAlign.center,
                        style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterSectionTitle(String title) {
    return Text(title, style: _pop(size: 14, weight: FontWeight.w700, color: const Color(0xFF111111)));
  }
}
