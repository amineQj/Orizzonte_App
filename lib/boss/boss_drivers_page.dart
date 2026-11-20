import 'package:flutter/material.dart';
import '../app_language.dart';
import '../customer/mission_model.dart';
import '../customer/mission_repository.dart';
import '../models/api_models.dart';
import 'boss_model.dart';
import 'boss_driver_detail_page.dart';
import 'boss_repository.dart';
import 'boss_ui.dart';

/// Drivers tab: the registered carrier list with mission history.
///
/// Drivers self-register on their own, so there is deliberately no "add
/// employee" action here.
class BossDriversPage extends StatefulWidget {
  const BossDriversPage({super.key});

  @override
  State<BossDriversPage> createState() => _BossDriversPageState();
}

class _BossDriversPageState extends State<BossDriversPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLangChanged);
    MissionRepository.instance.addListener(_onRepoChanged);
    BossRepository.instance.addListener(_onRepoChanged);
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

  List<PendingDriver> get _filteredPending {
    final q = _query.trim().toLowerCase();
    final pending = BossRepository.instance.pendingDrivers;
    if (q.isEmpty) return pending;
    return pending
        .where(
          (p) =>
              p.fullName.toLowerCase().contains(q) ||
              p.phone.toLowerCase().contains(q) ||
              p.vehiclePlate.toLowerCase().contains(q),
        )
        .toList();
  }

  List<BossDriver> get _filteredRegistered {
    final q = _query.trim().toLowerCase();
    final drivers = BossRepository.instance.drivers;
    if (q.isEmpty) return drivers;
    return drivers
        .where(
          (d) =>
              d.name.toLowerCase().contains(q) ||
              d.role.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Map<String, dynamic>> get _filteredRegisteredEmployees {
    final q = _query.trim().toLowerCase();
    final employees = BossRepository.instance.employees;
    if (q.isEmpty) return employees;
    return employees.where((e) {
      final name = (e['full_name'] ?? e['username'] ?? '').toString().toLowerCase();
      final plate = (e['vehicle_plate'] ?? '').toString().toLowerCase();
      return name.contains(q) || plate.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final registered = _filteredRegistered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            tr('Drivers', 'السائقون', 'Chauffeurs'),
            style: pop(
              size: 18,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: pop(size: 13, color: const Color(0xFF111111)),
            decoration: InputDecoration(
              hintText: tr(
                'Search drivers...',
                'ابحث عن سائق...',
                'Rechercher...',
              ),
              hintStyle: pop(size: 13, color: const Color(0xFFBBBBBB)),
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: Color(0xFFBBBBBB),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFEFEFEF),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFEFEFEF),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFF5A524),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPendingSection(),
        const SizedBox(height: 8),
        _buildRegisteredSection(),
        const SizedBox(height: 8),
        Expanded(
          child: registered.isEmpty
              ? _emptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: registered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _driverCard(registered[i], i),
                ),
        ),
      ],
    );
  }

  Widget _buildPendingSection() {
    final pending = _filteredPending;
    if (pending.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF5A524).withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_add_alt_1, color: Color(0xFFF5A524), size: 18),
                const SizedBox(width: 8),
                Text(
                  tr('Pending approvals', 'موافقات معلقة', 'Approbations en attente'),
                  style: pop(size: 14, weight: FontWeight.w700, color: const Color(0xFF111111)),
                ),
                const Spacer(),
                Text(
                  '${pending.length}',
                  style: pop(size: 13, weight: FontWeight.w700, color: const Color(0xFFF5A524)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...pending.map(
              (p) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFFFF3E0),
                      child: Text(
                        p.fullName.isEmpty
                            ? '?'
                            : p.fullName.substring(0, 1).toUpperCase(),
                        style: pop(size: 13, weight: FontWeight.w700, color: const Color(0xFFF5A524)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.fullName.isEmpty ? 'Driver #${p.userId}' : p.fullName,
                            style: pop(size: 12, weight: FontWeight.w600, color: const Color(0xFF222222)),
                          ),
                          Text(
                            '${p.phone} ${p.vehiclePlate.isNotEmpty ? '• ${p.vehiclePlate}' : ''}',
                            style: pop(size: 10, color: const Color(0xFF999999)),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final id = int.tryParse(p.userId.toString());
                        if (id == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BossDriverDetailPage(
                              driverId: id,
                              driverName: p.fullName,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tr('Review', '??????', 'Examiner'),
                          style: pop(size: 11, weight: FontWeight.w700, color: const Color(0xFF555555)),
                        ),
                      ),
                    ),
                  ],

                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisteredSection() {
    final employees = _filteredRegisteredEmployees;
    if (employees.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline, color: Color(0xFF4CAF50), size: 18),
                const SizedBox(width: 8),
                Text(
                  tr('Registered drivers', 'السائقون المسجلون', 'Chauffeurs enregistrés'),
                  style: pop(size: 14, weight: FontWeight.w700, color: const Color(0xFF111111)),
                ),
                const Spacer(),
                Text(
                  '${employees.length}',
                  style: pop(size: 13, weight: FontWeight.w700, color: const Color(0xFF4CAF50)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...employees.map((e) {
              final name = (e['full_name'] ?? e['username'] ?? 'Driver').toString();
              final id = (e['id'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(
                        name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                        style: pop(size: 12, weight: FontWeight.w700, color: const Color(0xFF4CAF50)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final id = int.tryParse((e['id'] ?? '').toString());
                          if (id == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BossDriverDetailPage(
                                driverId: id,
                                driverName: name,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          name,
                          style: pop(size: 12, weight: FontWeight.w600, color: const Color(0xFF222222)),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final ok = await BossRepository.instance.removeEmployee(id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? tr('Driver removed', 'تم حذف السائق', 'Chauffeur supprimé')
                                : (BossRepository.instance.error ??
                                    tr('Failed', 'فشل', 'Échec'))),
                            backgroundColor: ok
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE0533D),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tr('Remove', 'حذف', 'Supprimer'),
                          style: pop(size: 11, weight: FontWeight.w700, color: const Color(0xFFE0533D)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _driverCard(BossDriver d, int index) {
    final assigned = MissionRepository.instance.missions
        .where(
          (m) =>
              m.driver?.name == d.name &&
              (m.status == MissionStatus.accepted ||
                  m.status == MissionStatus.inProgress),
        )
        .length;
    final history = MissionRepository.instance.missions
        .where((m) => m.driver?.name == d.name)
        .toList();

    return Container(
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: avatarColor(index),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    d.initials,
                    style: pop(
                      size: 17,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: pop(
                        size: 14,
                        weight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.role,
                      style: pop(size: 11, color: const Color(0xFF999999)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 13,
                          color: Color(0xFFF5A524),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${d.rating}',
                          style: pop(
                            size: 12,
                            weight: FontWeight.w700,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: Color(0xFFBBBBBB),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          d.phone,
                          style: pop(size: 11, color: const Color(0xFF777777)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (d.vehicle != null && d.vehicle != '—') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 13,
                  color: Color(0xFFBBBBBB),
                ),
                const SizedBox(width: 6),
                Text(
                  d.vehicle!,
                  style: pop(size: 11, color: const Color(0xFF777777)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  value: '${d.missions}',
                  label: tr('Total', 'الإجمالي', 'Total'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  value: '$assigned',
                  label: tr('Assigned', 'معيّنة', 'Assignées'),
                  highlight: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showHistory(d, history),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.history,
                          size: 18,
                          color: Color(0xFFF5A524),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('History', 'السجل', 'Historique'),
                          style: pop(
                            size: 10,
                            weight: FontWeight.w700,
                            color: const Color(0xFFF5A524),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox({
    required String value,
    required String label,
    bool highlight = false,
  }) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: pop(
              size: 15,
              weight: FontWeight.w800,
              color: highlight
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 1),
          Text(label, style: pop(size: 9, color: const Color(0xFF999999))),
        ],
      ),
    );
  }

  void _showHistory(BossDriver d, List<CustomerMission> history) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.72,
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${d.name} — ${tr('History', 'السجل', 'Historique')}',
                style: pop(
                  size: 15,
                  weight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: history.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        tr(
                          'No missions assigned to this driver yet.',
                          'لا توجد مهام معيّنة لهذا السائق بعد.',
                          'Aucune mission assignée à ce chauffeur pour l’instant.',
                        ),
                        textAlign: TextAlign.center,
                        style: pop(size: 12, color: const Color(0xFF999999)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: history.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF2F2F2),
                      ),
                      itemBuilder: (_, i) => _historyRow(history[i]),
                    ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _historyRow(CustomerMission m) {
    final status = bossStatusInfo(m.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${tr('Mission', 'مهمة', 'Mission')} · ${m.id}',
                  style: pop(
                    size: 12,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const SizedBox(height: 4),
          Text(
            '${m.order.pickup} → ${m.order.delivery}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: pop(size: 11, color: const Color(0xFF777777)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 30,
                color: Color(0xFFF5A524),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr('No drivers found', 'لا يوجد سائقون', 'Aucun chauffeur'),
              style: pop(
                size: 15,
                weight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
