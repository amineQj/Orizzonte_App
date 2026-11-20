import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_language.dart';
import '../order_flow.dart';
import '../customer_screen.dart';
import 'mission_model.dart';
import 'mission_repository.dart';
import 'customer_mission_details_page.dart';

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

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  String get _lang => appLanguage.lang;

  String _t(String en, String ar, String fr) {
    if (_lang == 'AR') return ar;
    if (_lang == 'FR') return fr;
    return en;
  }

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLangChanged);
    MissionRepository.instance.addListener(_onRepoChanged);
    MissionRepository.instance.load();
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    MissionRepository.instance.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) setState(() {});
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = MissionRepository.instance;

    if (repo.isLoading && repo.missions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF5A524)),
      );
    }

    if (repo.error != null && repo.missions.isEmpty) {
      return _buildError(repo.error!);
    }

    final missions = repo.missions;

    return RefreshIndicator(
      color: const Color(0xFFF5A524),
      onRefresh: () => repo.retry(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('My Missions', 'مهامي', 'Mes missions'),
              style: _pop(
                size: 18,
                weight: FontWeight.w800,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _t(
                'Track the missions you have created.',
                'تابع المهام التي أنشأتها.',
                'Suivez vos missions.',
              ),
              style: _pop(size: 12, color: const Color(0xFF999999)),
            ),
            const SizedBox(height: 16),
            if (missions.isEmpty)
              _buildEmptyState()
            else
              ...missions.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMissionCard(m),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              _t(
                'Something went wrong',
                'حدث خطأ ما',
                'Une erreur est survenue',
              ),
              textAlign: TextAlign.center,
              style: _pop(
                size: 15,
                weight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: _pop(size: 12, color: const Color(0xFF999999)),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => MissionRepository.instance.load(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A524),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _t('Retry', 'إعادة المحاولة', 'Réessayer'),
                  style: _pop(
                    size: 13,
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 34,
              color: Color(0xFFF5A524),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _t('No missions yet', 'لا توجد مهام بعد', 'Aucune mission'),
            style: _pop(
              size: 16,
              weight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t(
              'Tap + to create your first mission.',
              'اضغط + لإنشاء أول مهمة.',
              'Appuyez sur + pour créer votre première mission.',
            ),
            textAlign: TextAlign.center,
            style: _pop(size: 13, color: const Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(CustomerMission m) {
    final status = _statusInfo(m.status);
    final truck = truckTypeLabel(m.order.truckType, _lang);
    final weight = m.order.weight.isNotEmpty ? ' · ${m.order.weight}' : '';
    final title = '$truck$weight';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerMissionDetailsPage(missionId: m.id),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
          boxShadow: [
            BoxShadow(
              color: status.color.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: mission name badge + status pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: 15,
                          color: Color(0xFFF5A524),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _pop(
                              size: 13,
                              weight: FontWeight.w700,
                              color: const Color(0xFF111111),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              categoryLabel(m.order.category, _lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _pop(
                size: 12,
                weight: FontWeight.w600,
                color: const Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 12),
            _routeRow(m, status.color),
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
            const SizedBox(height: 12),
            Row(
              children: [
                _metaChip(Icons.calendar_today_outlined, _dateLabel(m)),
                if (m.order.distance != null &&
                    m.order.distance!.isNotEmpty) ...[
                  const SizedBox(width: 14),
                  _metaChip(Icons.straighten, m.order.distance!),
                ],
                const Spacer(),
                if (m.order.estimatedPrice.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${m.order.estimatedPrice} DZD',
                      style: _pop(
                        size: 13,
                        weight: FontWeight.w800,
                        color: const Color(0xFFF5A524),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(_StatusInfo status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: _pop(size: 10, weight: FontWeight.w700, color: status.color),
          ),
        ],
      ),
    );
  }

  Widget _routeRow(CustomerMission m, Color destColor) {
    return Row(
      children: [
        const Icon(Icons.trip_origin, size: 12, color: Color(0xFF4CAF50)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            m.order.pickup,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pop(
              size: 12,
              weight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward, size: 14, color: Color(0xFFCCCCCC)),
        ),
        Expanded(
          child: Text(
            m.order.delivery,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: _pop(
              size: 12,
              weight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.trip_origin, size: 12, color: destColor),
      ],
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

  String _dateLabel(CustomerMission m) {
    final o = m.order;
    if (o.isNow) return _t('Now', 'الآن', 'Maintenant');
    if (o.manualDate.isNotEmpty && o.manualTime.isNotEmpty) {
      return '${o.manualDate} ${o.manualTime}';
    }
    if (o.manualDate.isNotEmpty) return o.manualDate;
    return _t('Scheduled', 'مجدول', 'Planifié');
  }

  _StatusInfo _statusInfo(MissionStatus s) {
    switch (s) {
      case MissionStatus.pending:
        return _StatusInfo(
          const Color(0xFF9E9E9E),
          const Color(0xFFF5F5F5),
          _t('Pending', 'قيد الانتظار', 'En attente'),
        );
      case MissionStatus.searching:
        return _StatusInfo(
          const Color(0xFF2196F3),
          const Color(0xFFE3F2FD),
          _t('Searching for driver', 'البحث عن سائق', 'Recherche chauffeur'),
        );
      case MissionStatus.accepted:
        return _StatusInfo(
          const Color(0xFFF5A524),
          const Color(0xFFFFF3E0),
          _t('Accepted', 'مقبول', 'Acceptée'),
        );
      case MissionStatus.inProgress:
        return _StatusInfo(
          const Color(0xFF3F51B5),
          const Color(0xFFE8EAF6),
          _t('In Progress', 'قيد التنفيذ', 'En cours'),
        );
      case MissionStatus.completed:
        return _StatusInfo(
          const Color(0xFF4CAF50),
          const Color(0xFFE8F5E9),
          _t('Completed', 'مكتمل', 'Terminée'),
        );
      case MissionStatus.cancelled:
        return _StatusInfo(
          const Color(0xFFEF4444),
          const Color(0xFFFFEBEE),
          _t('Cancelled', 'ملغاة', 'Annulée'),
        );
    }
  }
}

class _StatusInfo {
  final Color color;
  final Color bg;
  final String label;
  const _StatusInfo(this.color, this.bg, this.label);
}
