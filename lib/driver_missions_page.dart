import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';

import 'services/driver_mission_store.dart';
import 'widgets/api_state.dart';

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

class DriverMissionsPage extends StatefulWidget {
  const DriverMissionsPage({super.key});

  @override
  State<DriverMissionsPage> createState() => _DriverMissionsPageState();
}

class _DriverMissionsPageState extends State<DriverMissionsPage> {
  int _selectedTab = 0;

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
    DriverMissionStore.instance.addListener(_onStoreChanged);
    DriverMissionStore.instance.load();
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    DriverMissionStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onLangChanged() {
    setState(() {});
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  List<Map<String, String>> get _inProgressMissions => DriverMissionStore
      .instance
      .inProgressMissions
      .map((m) => m.toMap())
      .toList();

  List<Map<String, String>> get _completedMissions => DriverMissionStore
      .instance
      .completedMissions
      .map((m) => m.toMap())
      .toList();

  List<Map<String, String>> get _currentMissions {
    switch (_selectedTab) {
      case 0:
        return _inProgressMissions;
      case 1:
        return _completedMissions;
      default:
        return _inProgressMissions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          // 3 Tab buttons + filter icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _tabButton(
                    0,
                    _t('In Progress', 'قيد التنفيذ', 'En cours'),
                    _inProgressMissions.length,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tabButton(
                    1,
                    _t('Completed', 'مكتمل', 'Terminées'),
                    _completedMissions.length,
                    const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Mission list
          Expanded(child: _buildMissionList()),
        ],
      ),
    );
  }

  Widget _buildMissionList() {
    final store = DriverMissionStore.instance;
    return Column(
      children: [
        if (store.isDemo) DemoWarningBanner(onRetry: () => store.retry()),
        Expanded(
          child: store.isLoading
              ? const ApiLoadingView(message: 'Loading your missions...')
              : store.error != null && _currentMissions.isEmpty
                  ? ApiErrorView(
                      message: store.error!,
                      onRetry: () => store.retry(),
                    )
                  : _currentMissions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedTab == 0
                                    ? Icons.local_shipping_outlined
                                    : Icons.verified_outlined,
                                size: 48,
                                color: const Color(0xFFDDDDDD),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _t('No missions', 'لا توجد مهام', 'Aucune mission'),
                                style: _pop(size: 15, color: const Color(0xFF999999)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: _currentMissions.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildMissionCard(_currentMissions[index]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _tabButton(int index, String label, int count, Color color) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : const Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: _pop(
                size: 11,
                weight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF666666),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: _pop(
                  size: 9,
                  weight: FontWeight.w700,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(Map<String, String> m) {
    final img = _truckImage(m['truck']!, m['size']!);
    final isSvg = img.endsWith('.svg');
    final status = m['status']!;

    Color statusColor;
    String statusLabel;
    String statusBg;
    if (status == 'Accepted') {
      statusColor = const Color(0xFFF5A524);
      statusLabel = _t('Accepted', 'مقبول', 'Acceptée');
      statusBg = '0xFFFFF3E0';
    } else if (status == 'In Progress') {
      statusColor = const Color(0xFF2196F3);
      statusLabel = _t('In Progress', 'قيد التنفيذ', 'En cours');
      statusBg = '0xFFE3F2FD';
    } else {
      statusColor = const Color(0xFF4CAF50);
      statusLabel = _t('Completed', 'مكتمل', 'Terminée');
      statusBg = '0xFFE8F5E9';
    }

    String actionLabel;
    if (status == 'Accepted') {
      actionLabel = _t('Start Mission', 'بدء المهمة', 'Commencer');
    } else if (status == 'In Progress') {
      actionLabel = _t('Complete Mission', 'إكمال المهمة', 'Terminer');
    } else {
      actionLabel = _t('View Details', 'عرض التفاصيل', 'Voir détails');
    }

    return GestureDetector(
      onTap: () => _showDetailsModal(m),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Row 1: image LEFT, type + client RIGHT
            Row(
              children: [
                Container(
                  width: 80,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isSvg
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: SvgPicture.asset(img, fit: BoxFit.contain),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(img, fit: BoxFit.contain),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${m['truck']} ${m['size']}',
                            style: _pop(
                              size: 14,
                              weight: FontWeight.w700,
                              color: const Color(0xFF111111),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Color(int.parse(statusBg)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: _pop(
                                size: 9,
                                weight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        m['client']!,
                        style: _pop(size: 12, color: const Color(0xFF999999)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              m['from']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _pop(
                                size: 10,
                                weight: FontWeight.w500,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 10,
                              color: Color(0xFFCCCCCC),
                            ),
                          ),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              m['to']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _pop(
                                size: 10,
                                weight: FontWeight.w500,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
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
                const SizedBox(width: 10),
                _metaChip(Icons.straighten, m['dist']!),
                const Spacer(),
                Text(
                  m['price']!,
                  style: _pop(
                    size: 13,
                    weight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Row 3: action button
            GestureDetector(
              onTap: () => _showDetailsModal(m),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: status == 'Completed'
                      ? const Color(0xFFF5F5F5)
                      : statusColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: status != 'Completed'
                      ? [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  actionLabel,
                  textAlign: TextAlign.center,
                  style: _pop(
                    size: 12,
                    weight: FontWeight.w700,
                    color: status == 'Completed'
                        ? const Color(0xFF666666)
                        : Colors.white,
                  ),
                ),
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
        Icon(icon, size: 12, color: const Color(0xFFBBBBBB)),
        const SizedBox(width: 3),
        Text(text, style: _pop(size: 10, color: const Color(0xFF777777))),
      ],
    );
  }

  void _showDetailsModal(Map<String, String> m) {
    final img = _truckImage(m['truck']!, m['size']!);
    final isSvg = img.endsWith('.svg');
    final status = m['status']!;
    Color statusColor;
    String statusLabel;
    if (status == 'Accepted') {
      statusColor = const Color(0xFFF5A524);
      statusLabel = _t('Accepted', 'مقبول', 'Acceptée');
    } else if (status == 'In Progress') {
      statusColor = const Color(0xFF2196F3);
      statusLabel = _t('In Progress', 'قيد التنفيذ', 'En cours');
    } else {
      statusColor = const Color(0xFF4CAF50);
      statusLabel = _t('Completed', 'مكتمل', 'Terminée');
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _t(
                          'Mission Details',
                          'تفاصيل المهمة',
                          'Détails mission',
                        ),
                        style: _pop(
                          size: 20,
                          weight: FontWeight.w700,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: _pop(
                            size: 12,
                            weight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 120,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: isSvg
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SvgPicture.asset(img, fit: BoxFit.contain),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(img, fit: BoxFit.contain),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _detailRow(
                    Icons.tag,
                    _t('Mission ID', 'رقم المهمة', 'ID Mission'),
                    m['id']!,
                  ),
                  _detailRow(
                    Icons.person_outline,
                    _t('Client', 'العميل', 'Client'),
                    m['client']!,
                  ),
                  _detailRow(
                    Icons.local_shipping_outlined,
                    _t('Vehicle', 'المركبة', 'Véhicule'),
                    '${m['truck']} ${m['size']}',
                  ),
                  _detailRow(
                    Icons.calendar_today_outlined,
                    _t('Date', 'التاريخ', 'Date'),
                    m['date']!,
                  ),
                  _detailRow(
                    Icons.straighten,
                    _t('Distance', 'المسافة', 'Distance'),
                    m['dist']!,
                  ),
                  _detailRow(
                    Icons.attach_money,
                    _t('Price', 'السعر', 'Prix'),
                    m['price']!,
                  ),
                  _detailRow(
                    Icons.circle_outlined,
                    _t('From', 'من', 'De'),
                    m['from']!,
                  ),
                  _detailRow(
                    Icons.location_on_outlined,
                    _t('To', 'إلى', 'À'),
                    m['to']!,
                  ),
                  if (status == 'Accepted') ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        final ok = await DriverMissionStore.instance
                            .startMission(m['id']!);
                        if (!ok) {
                          final error = DriverMissionStore.instance.error;
                          if (error != null && context.mounted) {
                            showApiError(context, error);
                          }
                          return;
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A524),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFF5A524,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _t('Start Mission', 'بدء المهمة', 'Commencer'),
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
                  if (status == 'In Progress') ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        final ok = await DriverMissionStore.instance
                            .completeMission(m['id']!);
                        if (!ok) {
                          final error = DriverMissionStore.instance.error;
                          if (error != null && context.mounted) {
                            showApiError(context, error);
                          }
                          return;
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2196F3,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _t('Complete Mission', 'إكمال المهمة', 'Terminer'),
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFBBBBBB)),
          const SizedBox(width: 12),
          Text(label, style: _pop(size: 13, color: const Color(0xFF999999))),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _pop(
                size: 13,
                weight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
