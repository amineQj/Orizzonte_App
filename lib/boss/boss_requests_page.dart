import 'package:flutter/material.dart';
import '../app_language.dart';
import '../customer/mission_model.dart';
import '../customer/mission_repository.dart';
import 'boss_model.dart';
import 'boss_repository.dart';
import 'boss_ui.dart';
import '../widgets/api_state.dart';
import 'boss_mission_detail_page.dart';

enum _Filter { all, pending, accepted, inProgress, completed }

/// Requests tab: filterable list of every customer mission with the admin
/// actions (assign driver, details, cancel, delete).
class BossRequestsPage extends StatefulWidget {
  const BossRequestsPage({super.key});

  @override
  State<BossRequestsPage> createState() => _BossRequestsPageState();
}

class _BossRequestsPageState extends State<BossRequestsPage> {
  _Filter _filter = _Filter.all;

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

  bool _matches(CustomerMission m) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.pending:
        return m.status == MissionStatus.pending ||
            m.status == MissionStatus.searching;
      case _Filter.accepted:
        return m.status == MissionStatus.accepted;
      case _Filter.inProgress:
        return m.status == MissionStatus.inProgress;
      case _Filter.completed:
        return m.status == MissionStatus.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final missions = MissionRepository.instance.missions;
    final visible = missions.where(_matches).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            tr('Mission Requests', 'Ø·Ù„Ø¨Ø§Øª Ø§Ù„Ù…Ù‡Ø§Ù…', 'Demandes de missions'),
            style: pop(
              size: 18,
              weight: FontWeight.w800,
              color: const Color(0xFF111111),
            ),
          ),
        ),
        _filterChips(),
        const SizedBox(height: 8),
        Expanded(
          child: _buildMissionList(visible),
        ),
      ],
    );
  }

  Widget _buildMissionList(List<CustomerMission> visible) {
    final repo = MissionRepository.instance;
    if (repo.isLoading && visible.isEmpty) {
      return const ApiLoadingView(message: 'Loading missions...');
    }
    if (repo.error != null && visible.isEmpty) {
      return ApiErrorView(message: repo.error!, onRetry: () => repo.retry());
    }
    if (visible.isEmpty) return _emptyState();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _missionCard(visible[i]),
    );
  }

  Widget _filterChips() {
    final items = [
      (_Filter.all, tr('All', 'Ø§Ù„ÙƒÙ„', 'Tout')),
      (_Filter.pending, tr('Pending', 'Ù‚ÙŠØ¯ Ø§Ù„Ø§Ù†ØªØ¸Ø§Ø±', 'En attente')),
      (_Filter.accepted, tr('Confirmed', 'Ù…Ø¤ÙƒØ¯Ø©', 'ConfirmÃ©es')),
      (_Filter.inProgress, tr('In Progress', 'Ù‚ÙŠØ¯ Ø§Ù„ØªÙ†ÙÙŠØ°', 'En cours')),
      (_Filter.completed, tr('Completed', 'Ù…ÙƒØªÙ…Ù„Ø©', 'TerminÃ©es')),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = items[i];
          final active = _filter == value;
          return GestureDetector(
            onTap: () => setState(() => _filter = value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFF5A524) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? const Color(0xFFF5A524)
                      : const Color(0xFFE8E8E8),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: pop(
                  size: 12,
                  weight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? Colors.white : const Color(0xFF555555),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _missionCard(CustomerMission m) {
    final status = bossStatusInfo(m.status);
    final canCancel =
        m.status != MissionStatus.completed &&
        m.status != MissionStatus.cancelled;
    final hasDriver = m.driver != null;

    return GestureDetector(
      onTap: () => _showDetails(m),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tr('Mission', 'Ù…Ù‡Ù…Ø©', 'Mission')} Â· ${m.id}',
                      style: pop(
                        size: 13,
                        weight: FontWeight.w800,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.order.category.isNotEmpty
                          ? _category(m)
                          : tr(
                              'General shipment',
                              'Ø´Ø­Ù†Ø© Ø¹Ø§Ù…Ø©',
                              'Envoi gÃ©nÃ©ral',
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: pop(size: 11, color: const Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          _routeRow(m, status.color),
          const SizedBox(height: 12),
          Row(
            children: [
              _meta(Icons.calendar_today_outlined, _dateLabel(m)),
              const SizedBox(width: 14),
              if (m.order.distance != null && m.order.distance!.isNotEmpty)
                _meta(Icons.straighten, m.order.distance!),
              const Spacer(),
              if (m.order.estimatedPrice.isNotEmpty)
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
          ),
          if (m.driver != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    size: 14,
                    color: Color(0xFFF5A524),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tr('Assigned', 'Ø§Ù„Ù…Ø¹ÙŠÙ‘Ù†', 'AssignÃ©')}: ${m.driver!.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: pop(
                        size: 11,
                        weight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (canCancel) ...[
                Expanded(
                  child: _actionBtn(
                    label: tr('Assign', 'ØªØ¹ÙŠÙŠÙ†', 'Assigner'),
                    icon: Icons.person_add_alt,
                    color: const Color(0xFFF5A524),
                    bg: const Color(0xFFFFF7E6),
                    onTap: () => _showAssign(m),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    label: tr('Details', 'Ø§Ù„ØªÙØ§ØµÙŠÙ„', 'DÃ©tails'),
                    icon: Icons.info_outline,
                    color: const Color(0xFF3F51B5),
                    bg: const Color(0xFFE8EAF6),
                    onTap: () => _showDetails(m),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    label: tr('Cancel', 'Ø¥Ù„ØºØ§Ø¡', 'Annuler'),
                    icon: Icons.block,
                    color: const Color(0xFFEF4444),
                    bg: const Color(0xFFFFEBEE),
                    onTap: () => _confirmCancel(m),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Expanded(
                  child: _actionBtn(
                    label: tr('Details', 'Ø§Ù„ØªÙØ§ØµÙŠÙ„', 'DÃ©tails'),
                    icon: Icons.info_outline,
                    color: const Color(0xFF3F51B5),
                    bg: const Color(0xFFE8EAF6),
                    onTap: () => _showDetails(m),
                  ),
                ),
              ],
              _deleteBtn(m, hasDriver: hasDriver),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _deleteBtn(CustomerMission m, {required bool hasDriver}) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => _confirmDelete(m),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
          ),
          child: const Icon(
            Icons.delete_outline,
            size: 18,
            color: Color(0xFFEF4444),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: pop(size: 11, weight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
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
            style: pop(
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
            style: pop(
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

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFFBBBBBB)),
        const SizedBox(width: 4),
        Text(text, style: pop(size: 11, color: const Color(0xFF777777))),
      ],
    );
  }

  String _category(CustomerMission m) {
    final o = m.order;
    if (o.category.isNotEmpty &&
        o.truckType.isNotEmpty &&
        o.category != 'general') {
      return '${o.category} Â· ${o.truckType}';
    }
    if (o.truckType.isNotEmpty) return o.truckType;
    return 'General shipment';
  }

  String _dateLabel(CustomerMission m) {
    final o = m.order;
    if (o.isNow) return tr('Now', 'Ø§Ù„Ø¢Ù†', 'Maintenant');
    if (o.manualDate.isNotEmpty && o.manualTime.isNotEmpty) {
      return '${o.manualDate} ${o.manualTime}';
    }
    if (o.manualDate.isNotEmpty) return o.manualDate;
    return tr('Scheduled', 'Ù…Ø¬Ø¯ÙˆÙ„', 'PlanifiÃ©');
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
                Icons.assignment_outlined,
                size: 30,
                color: Color(0xFFF5A524),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr('No requests here', 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø·Ù„Ø¨Ø§Øª Ù‡Ù†Ø§', 'Aucune demande'),
              style: pop(
                size: 15,
                weight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                'Try another filter.',
                'Ø¬Ø±Ø¨ Ù…Ø±Ø´Ø­Ø§Ù‹ Ø¢Ø®Ø±.',
                'Essayez un autre filtre.',
              ),
              style: pop(size: 12, color: const Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssign(CustomerMission m) {
    final drivers = BossRepository.instance.drivers;
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
                tr('Assign a Driver', 'ØªØ¹ÙŠÙŠÙ† Ø³Ø§Ø¦Ù‚', 'Assigner un chauffeur'),
                style: pop(
                  size: 16,
                  weight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${tr('Mission', 'Ù…Ù‡Ù…Ø©', 'Mission')} Â· ${m.id}',
                style: pop(size: 12, color: const Color(0xFF999999)),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: drivers.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF2F2F2),
                ),
                itemBuilder: (_, i) => _driverRow(ctx, m, drivers[i], i),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _driverRow(
    BuildContext ctx,
    CustomerMission m,
    BossDriver driver,
    int index,
  ) {
    final activeCount = MissionRepository.instance.missions
        .where(
          (x) =>
              x.driver?.name == driver.name &&
              (x.status == MissionStatus.accepted ||
                  x.status == MissionStatus.inProgress),
        )
        .length;
    return InkWell(
      onTap: () async {
        Navigator.pop(ctx);
        await MissionRepository.instance.assignDriver(
          m.id,
          DriverInfo(
            id: driver.id,
            name: driver.name,
            phone: driver.phone,
            rating: driver.rating,
            vehicle: driver.vehicle,
          ),
        );
        if (!mounted) return;
        final error = MissionRepository.instance.error;
        if (error != null) {
          showApiError(context, error);
          return;
        }
        _toast(tr('Driver assigned', 'ØªÙ… ØªØ¹ÙŠÙŠÙ† Ø§Ù„Ø³Ø§Ø¦Ù‚', 'Chauffeur assignÃ©'));
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarColor(index),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  driver.initials,
                  style: pop(
                    size: 15,
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
                    driver.name,
                    style: pop(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    driver.role,
                    style: pop(size: 11, color: const Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 13, color: Color(0xFFF5A524)),
                    const SizedBox(width: 2),
                    Text(
                      '${driver.rating}',
                      style: pop(
                        size: 12,
                        weight: FontWeight.w700,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$activeCount ${tr('active', 'Ù†Ø´Ø·Ø©', 'actives')}',
                  style: pop(size: 10, color: const Color(0xFF999999)),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 13,
                color: Color(0xFFF5A524),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(CustomerMission m) {
    final id = int.tryParse(m.id);
    if (id == null) {
      showApiError(context, 'Invalid mission id: ${m.id}');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BossMissionDetailPage(missionId: id),
      ),
    );
  }


  void _confirmCancel(CustomerMission m) {
    showDialog(
      context: context,
      builder: (ctx) => _confirmDialog(
        ctx,
        title: tr(
          'Cancel this mission?',
          'Ø¥Ù„ØºØ§Ø¡ Ù‡Ø°Ù‡ Ø§Ù„Ù…Ù‡Ù…Ø©ØŸ',
          'Annuler cette mission ?',
        ),
        message: tr(
          'This action cannot be undone.',
          'Ù„Ø§ ÙŠÙ…ÙƒÙ† Ø§Ù„ØªØ±Ø§Ø¬Ø¹ Ø¹Ù† Ù‡Ø°Ø§ Ø§Ù„Ø¥Ø¬Ø±Ø§Ø¡.',
          'Cette action est irrÃ©versible.',
        ),
        confirmLabel: tr('Cancel', 'Ø¥Ù„ØºØ§Ø¡', 'Annuler'),
        cancelLabel: tr('Keep', 'Ø¥Ø¨Ù‚Ø§Ø¡', 'Garder'),
        confirmColor: const Color(0xFFEF4444),
        icon: Icons.block,
        onConfirm: () async {
          Navigator.pop(ctx);
          await MissionRepository.instance.updateStatus(
            m.id,
            MissionStatus.cancelled,
          );
          if (!mounted) return;
          final error = MissionRepository.instance.error;
          if (error != null) {
            showApiError(context, error);
            return;
          }
          _toast(tr('Mission cancelled', 'ØªÙ… Ø¥Ù„ØºØ§Ø¡ Ø§Ù„Ù…Ù‡Ù…Ø©', 'Mission annulÃ©e'));
        },
      ),
    );
  }

  void _confirmDelete(CustomerMission m) {
    showDialog(
      context: context,
      builder: (ctx) => _confirmDialog(
        ctx,
        title: tr(
          'Delete this mission?',
          'Ø­Ø°Ù Ù‡Ø°Ù‡ Ø§Ù„Ù…Ù‡Ù…Ø©ØŸ',
          'Supprimer cette mission ?',
        ),
        message: tr(
          'The mission will be removed permanently.',
          'Ø³ÙŠØªÙ… Ø­Ø°Ù Ø§Ù„Ù…Ù‡Ù…Ø© Ù†Ù‡Ø§Ø¦ÙŠØ§Ù‹.',
          'La mission sera supprimÃ©e dÃ©finitivement.',
        ),
        confirmLabel: tr('Delete', 'Ø­Ø°Ù', 'Supprimer'),
        cancelLabel: tr('Keep', 'Ø¥Ø¨Ù‚Ø§Ø¡', 'Garder'),
        confirmColor: const Color(0xFFEF4444),
        icon: Icons.delete_outline,
        onConfirm: () async {
          Navigator.pop(ctx);
          await MissionRepository.instance.deleteMission(m.id);
          if (!mounted) return;
          final error = MissionRepository.instance.error;
          if (error != null) {
            showApiError(context, error);
            return;
          }
          _toast(tr('Mission deleted', 'ØªÙ… Ø­Ø°Ù Ø§Ù„Ù…Ù‡Ù…Ø©', 'Mission supprimÃ©e'));
        },
      ),
    );
  }

  Widget _confirmDialog(
    BuildContext ctx, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    required Color confirmColor,
    required IconData icon,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: confirmColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: pop(
              size: 16,
              weight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: pop(size: 13, color: const Color(0xFF666666)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        cancelLabel,
                        style: pop(
                          size: 14,
                          weight: FontWeight.w600,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: confirmColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        confirmLabel,
                        style: pop(
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
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

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: pop(size: 13, color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}