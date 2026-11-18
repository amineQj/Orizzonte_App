import 'package:flutter/material.dart';
import '../app_language.dart';
import '../customer/mission_model.dart';
import '../customer/mission_repository.dart';
import '../widgets/api_state.dart' hide formatDzd;
import 'boss_repository.dart';
import 'boss_ui.dart';

/// Dashboard tab: live stats + recent missions.
class BossDashboardPage extends StatefulWidget {
  final VoidCallback onSeeAll;
  const BossDashboardPage({super.key, required this.onSeeAll});

  @override
  State<BossDashboardPage> createState() => _BossDashboardPageState();
}

class _BossDashboardPageState extends State<BossDashboardPage> {
  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLangChanged);
    MissionRepository.instance.addListener(_onRepoChanged);
    BossRepository.instance.addListener(_onRepoChanged);
    BossRepository.instance.load();
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    MissionRepository.instance.removeListener(_onRepoChanged);
    BossRepository.instance.removeListener(_onRepoChanged);
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
    final missions = MissionRepository.instance.missions;
    final total = missions.length;
    final completed = missions
        .where((m) => m.status == MissionStatus.completed)
        .length;
    final active = missions
        .where(
          (m) =>
              m.status == MissionStatus.accepted ||
              m.status == MissionStatus.inProgress,
        )
        .length;
    final revenue = missions
        .where((m) => m.status != MissionStatus.cancelled)
        .fold<double>(0, (sum, m) => sum + parseDzd(m.order.estimatedPrice));

    if (BossRepository.instance.isLoading && missions.isEmpty) {
      return const ApiLoadingView(message: 'Loading dashboard...');
    }
    if (BossRepository.instance.error != null && missions.isEmpty) {
      return ApiErrorView(
        message: BossRepository.instance.error!,
        onRetry: () => BossRepository.instance.retry(),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (BossRepository.instance.isDemo)
            DemoWarningBanner(
              onRetry: () => BossRepository.instance.retry(),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(
                        'Welcome back, Boss',
                        'مرحباً بك أيها الرئيس',
                        'Bon retour, patron',
                      ),
                      style: pop(
                        size: 18,
                        weight: FontWeight.w800,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(
                        'Live overview of your operations.',
                        'نظرة مباشرة على عملياتك.',
                        'Aperçu en direct de vos opérations.',
                      ),
                      style: pop(size: 12, color: const Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _statsGrid(total, completed, active, revenue),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('Recent Missions', 'أحدث المهام', 'Missions récentes'),
                  style: pop(
                    size: 16,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onSeeAll,
                child: Text(
                  tr('View all', 'عرض الكل', 'Tout voir'),
                  style: pop(
                    size: 12,
                    weight: FontWeight.w700,
                    color: const Color(0xFFF5A524),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (missions.isEmpty)
            _emptyState()
          else
            ...missions
                .take(4)
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _missionRow(m),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _statsGrid(int total, int completed, int active, double revenue) {
    final stats = [
      (
        label: tr('Total Missions', 'إجمالي المهام', 'Missions totales'),
        value: '$total',
        color: const Color(0xFFF5A524),
        bg: const Color(0xFFFFF7E6),
        icon: Icons.inventory_2_outlined,
      ),
      (
        label: tr('Completed', 'مكتملة', 'Terminées'),
        value: '$completed',
        color: const Color(0xFF4CAF50),
        bg: const Color(0xFFE8F5E9),
        icon: Icons.verified_outlined,
      ),
      (
        label: tr('Active Missions', 'مهام نشطة', 'Missions actives'),
        value: '$active',
        color: const Color(0xFF3F51B5),
        bg: const Color(0xFFE8EAF6),
        icon: Icons.local_shipping_outlined,
      ),
      (
        label: tr('Revenue (DZD)', 'الإيرادات (دج)', 'Revenus (DZD)'),
        value: formatDzd(revenue),
        color: const Color(0xFFE53935),
        bg: const Color(0xFFFFEBEE),
        icon: Icons.payments_outlined,
      ),
    ];

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _statCard(stats[0]),
              const SizedBox(height: 12),
              _statCard(stats[1]),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _statCard(stats[2]),
              const SizedBox(height: 12),
              _statCard(stats[3]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    ({String label, String value, Color color, Color bg, IconData icon}) s,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
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
                  color: s.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s.icon, size: 18, color: s.color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s.value,
            style: pop(
              size: 18,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: pop(size: 10, color: const Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _missionRow(CustomerMission m) {
    final status = bossStatusInfo(m.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: status.color.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${tr('Mission', 'مهمة', 'Mission')} · ${m.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pop(
                    size: 12,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trip_origin, size: 12, color: Color(0xFF4CAF50)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  m.order.pickup,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pop(
                    size: 12,
                    weight: FontWeight.w500,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.arrow_forward,
                  size: 13,
                  color: Color(0xFFCCCCCC),
                ),
              ),
              Expanded(
                child: Text(
                  m.order.delivery,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: pop(
                    size: 12,
                    weight: FontWeight.w500,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (m.driver != null)
                Expanded(
                  child: Text(
                    '${tr('Driver', 'السائق', 'Chauffeur')}: ${m.driver!.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pop(size: 11, color: const Color(0xFF777777)),
                  ),
                ),
              if (m.order.estimatedPrice.isNotEmpty) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${m.order.estimatedPrice} DZD',
                    style: pop(
                      size: 12,
                      weight: FontWeight.w800,
                      color: const Color(0xFFF5A524),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(BossStatusInfo status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            style: pop(size: 10, weight: FontWeight.w700, color: status.color),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 30,
              color: Color(0xFFF5A524),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            tr('No missions yet', 'لا توجد مهام بعد', 'Aucune mission'),
            style: pop(
              size: 15,
              weight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr(
              'Missions created by customers will appear here.',
              'ستظهر مهام العملاء هنا.',
              'Les missions des clients apparaîtront ici.',
            ),
            textAlign: TextAlign.center,
            style: pop(size: 12, color: const Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
