import 'package:flutter/material.dart';
import '../app_language.dart';
import '../customer/mission_model.dart';
import '../customer/mission_repository.dart';
import 'boss_ui.dart';

/// Revenue tab: financial stats, a monthly completions chart and the latest
/// billing entries (completed missions).
class BossRevenuePage extends StatefulWidget {
  const BossRevenuePage({super.key});

  @override
  State<BossRevenuePage> createState() => _BossRevenuePageState();
}

class _BossRevenuePageState extends State<BossRevenuePage> {
  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLangChanged);
    MissionRepository.instance.addListener(_onRepoChanged);
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
    final missions = MissionRepository.instance.missions;
    final completed = missions
        .where((m) => m.status == MissionStatus.completed)
        .toList();
    final revenue = missions
        .where((m) => m.status != MissionStatus.cancelled)
        .fold<double>(0, (sum, m) => sum + parseDzd(m.order.estimatedPrice));
    final avg = completed.isNotEmpty ? revenue / completed.length : 0.0;
    final completionRate = missions.isEmpty
        ? 0
        : (completed.length / missions.length * 100).round();
    final chart = _monthlyCompleted(missions);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Revenue Overview', 'نظرة على الإيرادات', 'Aperçu des revenus'),
            style: pop(
              size: 18,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Financial performance of your operations.',
              'الأداء المالي لعملياتك.',
              'Performance financière de vos opérations.',
            ),
            style: pop(size: 12, color: const Color(0xFF999999)),
          ),
          const SizedBox(height: 16),
          _statGrid(revenue, completed.length, avg, completionRate),
          const SizedBox(height: 20),
          _chartCard(chart),
          const SizedBox(height: 20),
          Text(
            tr('Recent Billing', 'الفواتير الأخيرة', 'Facturation récente'),
            style: pop(
              size: 15,
              weight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Completed mission invoices',
              'فواتير المهام المكتملة',
              'Factures des missions terminées',
            ),
            style: pop(size: 11, color: const Color(0xFF999999)),
          ),
          const SizedBox(height: 12),
          if (completed.isEmpty)
            _noBilling()
          else
            ...completed
                .take(5)
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _billingRow(m),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _statGrid(double revenue, int billed, double avg, int rate) {
    final items = [
      (
        label: tr(
          'Total Revenue (DZD)',
          'إجمالي الإيرادات (دج)',
          'Revenus (DZD)',
        ),
        value: formatDzd(revenue),
        color: const Color(0xFFF5A524),
        bg: const Color(0xFFFFF7E6),
        icon: Icons.payments_outlined,
      ),
      (
        label: tr('Missions Billed', 'مهام مفوترة', 'Missions facturées'),
        value: '$billed',
        color: const Color(0xFF4CAF50),
        bg: const Color(0xFFE8F5E9),
        icon: Icons.receipt_long_outlined,
      ),
      (
        label: tr(
          'Avg / Mission (DZD)',
          'المتوسط / مهمة (دج)',
          'Moyenne / mission',
        ),
        value: formatDzd(avg),
        color: const Color(0xFF3F51B5),
        bg: const Color(0xFFE8EAF6),
        icon: Icons.bar_chart,
      ),
      (
        label: tr('Completion Rate', 'معدل الإنجاز', 'Taux de réussite'),
        value: '$rate%',
        color: const Color(0xFFE53935),
        bg: const Color(0xFFFFEBEE),
        icon: Icons.flag_outlined,
      ),
    ];

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _statCard(items[0]),
              const SizedBox(height: 12),
              _statCard(items[1]),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _statCard(items[2]),
              const SizedBox(height: 12),
              _statCard(items[3]),
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
              size: 17,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: pop(size: 10, color: const Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  /// Groups completed missions by month over the last 6 months.
  List<({String label, int value})> _monthlyCompleted(
    List<CustomerMission> missions,
  ) {
    final now = DateTime.now();
    final months = <({String label, int value})>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final label = _monthName(m.month);
      final value = missions
          .where(
            (x) =>
                x.status == MissionStatus.completed &&
                x.createdAt.year == m.year &&
                x.createdAt.month == m.month,
          )
          .length;
      months.add((label: label, value: value));
    }
    return months;
  }

  String _monthName(int month) {
    const en = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const ar = [
      'جان',
      'فيف',
      'مار',
      'أفري',
      'ماي',
      'جوان',
      'جويل',
      'أوت',
      'سبت',
      'أكت',
      'نوف',
      'ديس',
    ];
    const fr = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    final lang = appLanguage.lang;
    if (lang == 'AR') return ar[month - 1];
    if (lang == 'FR') return fr[month - 1];
    return en[month - 1];
  }

  Widget _chartCard(List<({String label, int value})> data) {
    final max = data.fold<int>(0, (a, b) => b.value > a ? b.value : a);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Text(
            tr(
              'Completed by Month',
              'المكتملة حسب الشهر',
              'Terminées par mois',
            ),
            style: pop(
              size: 14,
              weight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('Last 6 months', 'آخر 6 أشهر', '6 derniers mois'),
            style: pop(size: 11, color: const Color(0xFF999999)),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(data.length, (i) {
              final d = data[i];
              final h = max == 0 ? 0.0 : (d.value / max) * 100;
              final isLast = i == data.length - 1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${d.value}',
                        style: pop(
                          size: 10,
                          weight: FontWeight.w700,
                          color: isLast
                              ? const Color(0xFFF5A524)
                              : const Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 74,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 74 * (h / 100).clamp(0.02, 1.0),
                          width: 18,
                          decoration: BoxDecoration(
                            color: isLast
                                ? const Color(0xFFF5A524)
                                : const Color(
                                    0xFFF5A524,
                                  ).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d.label,
                        style: pop(
                          size: 10,
                          weight: FontWeight.w600,
                          color: const Color(0xFF777777),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _billingRow(CustomerMission m) {
    final status = bossStatusInfo(m.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr('Mission', 'مهمة', 'Mission')} · ${m.id}',
                  style: pop(
                    size: 12,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  m.order.phoneNumber.isNotEmpty
                      ? m.order.phoneNumber
                      : '${m.order.pickup} → ${m.order.delivery}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pop(size: 11, color: const Color(0xFF999999)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (m.order.estimatedPrice.isNotEmpty)
                Text(
                  '${formatDzd(parseDzd(m.order.estimatedPrice))} DZD',
                  style: pop(
                    size: 12,
                    weight: FontWeight.w800,
                    color: const Color(0xFFF5A524),
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.label,
                  style: pop(
                    size: 9,
                    weight: FontWeight.w700,
                    color: status.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _noBilling() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 32,
            color: Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 10),
          Text(
            tr(
              'No completed invoices yet',
              'لا توجد فواتير مكتملة بعد',
              'Aucune facture terminée',
            ),
            textAlign: TextAlign.center,
            style: pop(size: 12, color: const Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
