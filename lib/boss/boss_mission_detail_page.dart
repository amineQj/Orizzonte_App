import 'package:flutter/material.dart';

import '../app_language.dart';
import '../customer/mission_repository.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/api_state.dart';
import '../widgets/app_text_style.dart';
import 'boss_model.dart';
import 'boss_repository.dart';

TextStyle _pop({double? size, FontWeight? weight, Color? color}) =>
    appPop(size: size, weight: weight, color: color);

const _amber = Color(0xFFF5A524);

/// Boss mission detail screen.
///
/// The backend has no GET /api/missions/{id}/ route, so the authoritative
/// mission data is resolved from GET /api/missions/all/ (which already carries
/// the nested client and assigned driver objects). Negotiation history is
/// loaded via GET /api/missions/{id}/negotiation/ when the role allows it.
class BossMissionDetailPage extends StatefulWidget {
  final int missionId;
  /// Injectable for widget tests; production uses the live API.
  final ApiService? api;

  const BossMissionDetailPage({
    super.key,
    required this.missionId,
    this.api,
  });

  @override
  State<BossMissionDetailPage> createState() => _BossMissionDetailPageState();
}

class _BossMissionDetailPageState extends State<BossMissionDetailPage> {
  late final ApiService _api;
  Mission? _mission;
  Negotiation? _negotiation;
  bool _negotiationUnavailable = false;
  bool _loading = true;
  String? _error;
  bool _acting = false;

  String _tr(String en, String ar, String fr) {
    final lang = appLanguage.lang;
    if (lang == 'AR') return ar;
    if (lang == 'FR') return fr;
    return en;
  }

  @override
  void initState() {
    _api = widget.api ?? ApiService();
    super.initState();
    appLanguage.addListener(_onLanguageChanged);
    _load();
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mission = await _api.getMissionById(widget.missionId);
      if (!mounted) return;
      setState(() {
        _mission = mission;
        _loading = false;
        if (mission == null) {
          _error = _tr('Mission not found.', 'المهمة غير موجودة.', 'Mission introuvable.');
        }
      });
      if (mission == null) return;
      await _loadNegotiation();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadNegotiation() async {
    try {
      final n = await _api.getNegotiation(widget.missionId);
      if (!mounted) return;
      setState(() {
        _negotiation = n;
        _negotiationUnavailable = false;
      });
    } catch (_) {
      // The negotiation endpoint is restricted to client/approved-driver
      // roles. Bosses see a clear note instead of a generic error.
      if (!mounted) return;
      setState(() => _negotiationUnavailable = true);
    }
  }

  Future<void> _afterAction(String successMessage) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) showSuccessWithMessenger(messenger, successMessage);
    await MissionRepository.instance.load();
    await BossRepository.instance.load();
    await _load();
  }

  Future<void> _assign() async {
    final drivers = BossRepository.instance.drivers;
    if (drivers.isEmpty) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        showApiErrorWithMessenger(
            messenger,
            _tr('No approved drivers available.',
                'لا يوجد سائقون موثقون متاحون.', 'Aucun chauffeur approuvé.'));
      }
      return;
    }
    final selected = await showModalBottomSheet<BossDriver>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Text(_tr('Select a driver', 'اختر سائقاً', 'Choisir un chauffeur'),
                style: _pop(size: 16, weight: FontWeight.w700,
                    color: const Color(0xFF111111))),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: drivers.length,
                itemBuilder: (_, i) {
                  final d = drivers[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFF3DC),
                      child: Text(d.initials,
                          style: _pop(size: 12, weight: FontWeight.w700,
                              color: const Color(0xFFB87600))),
                    ),
                    title: Text(d.name,
                        style: _pop(size: 13, weight: FontWeight.w600)),
                    subtitle: Text(d.phone,
                        style: _pop(size: 11, color: const Color(0xFF999999))),
                    onTap: () => Navigator.pop(ctx, d),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(() => _acting = true);
    try {
      await _api.assignMission(widget.missionId, int.tryParse(selected.id) ?? 0);
      if (!mounted) return;
      await _afterAction(_tr('Driver assigned.', 'تم تعيين السائق.', 'Chauffeur assigné.'));
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Cancel mission?', 'إلغاء المهمة؟', 'Annuler la mission ?'),
            style: _pop(size: 16, weight: FontWeight.w700)),
        content: Text(_tr('This action cannot be undone.',
            'لا يمكن التراجع عن هذا الإجراء.', 'Cette action est irréversible.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_tr('Keep', 'الاحتفاظ', 'Garder'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_tr('Cancel mission', 'إلغاء المهمة', 'Annuler'),
                  style: const TextStyle(color: Color(0xFFE0533D)))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _acting = true);
    try {
      await _api.cancelMission(widget.missionId);
      if (!mounted) return;
      await _afterAction(_tr('Mission cancelled.', 'تم إلغاء المهمة.', 'Mission annulée.'));
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Delete mission?', 'حذف المهمة؟', 'Supprimer la mission ?'),
            style: _pop(size: 16, weight: FontWeight.w700)),
        content: Text(_tr('This permanently deletes the mission.',
            'سيتم حذف المهمة نهائياً.', 'Cela supprime définitivement la mission.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_tr('Keep', 'الاحتفاظ', 'Garder'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_tr('Delete', 'حذف', 'Supprimer'),
                  style: const TextStyle(color: Color(0xFFE0533D)))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _acting = true);
    try {
      await _api.deleteMission(widget.missionId);
      if (!mounted) return;
      await MissionRepository.instance.load();
      await BossRepository.instance.load();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _tr('Mission #${widget.missionId}', 'المهمة #${widget.missionId}',
              'Mission #${widget.missionId}'),
          style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _amber),
            onPressed: _acting ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : _error != null || _mission == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                        const SizedBox(height: 12),
                        Text(_error ?? _tr('Mission unavailable.',
                            'المهمة غير متاحة.', 'Mission indisponible.'),
                            textAlign: TextAlign.center,
                            style: _pop(size: 13, color: const Color(0xFF555555))),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _load,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                                color: _amber,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(_tr('Retry', 'إعادة المحاولة', 'Réessayer'),
                                style: _pop(size: 13, weight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: _amber,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildMissionCard(),
                      const SizedBox(height: 14),
                      _buildClientCard(),
                      const SizedBox(height: 14),
                      _buildDriverCard(),
                      const SizedBox(height: 14),
                      _buildNegotiationCard(),
                      const SizedBox(height: 14),
                      _buildActions(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMissionCard() {
    final m = _mission!;
    return _card(
      title: _tr('Mission information', 'معلومات المهمة', 'Informations mission'),
      children: [
        _row(_tr('ID', 'الرقم', 'ID'), '#${m.id}'),
        _row(_tr('Status', 'الحالة', 'Statut'), m.status),
        _row(_tr('Price', 'السعر', 'Prix'),
            '${m.price.toStringAsFixed(0)} DZD'),
        _row(_tr('Distance', 'المسافة', 'Distance'),
            '${m.distance.toStringAsFixed(1)} km'),
        _row(_tr('Departure', 'الانطلاق', 'Départ'),
            '${m.departureLat.toStringAsFixed(5)}, ${m.departureLon.toStringAsFixed(5)}'),
        _row(_tr('Arrival', 'الوصول', 'Arrivée'),
            '${m.arrivalLat.toStringAsFixed(5)}, ${m.arrivalLon.toStringAsFixed(5)}'),
        _row(_tr('Date', 'التاريخ', 'Date'), m.date.isEmpty ? '—' : m.date),
        _row(_tr('Time', 'الوقت', 'Heure'), m.time.isEmpty ? '—' : m.time),
        _row(_tr('Truck', 'الشاحنة', 'Camion'),
            '${m.truckType} / ${m.size}'),
        _row(_tr('Workers', 'العمال', 'Ouvriers'), '${m.workers}'),
        _row(_tr('Category', 'الفئة', 'Catégorie'), m.category),
        _row(_tr('Shipment', 'الشحنة', 'Expédition'), m.shipmentType),
        if (m.commissionRate != null)
          _row(_tr('Commission', 'العمولة', 'Commission'), m.commissionRate!),
        if (m.driverNet != null)
          _row(_tr('Driver net', 'صافي السائق', 'Net chauffeur'),
              '${m.driverNet} DZD'),
      ],
    );
  }

  Widget _buildClientCard() {
    final client = _mission!.client;
    return _card(
      title: _tr('Client information', 'معلومات العميل', 'Informations client'),
      children: [
        _row(_tr('Name', 'الاسم', 'Nom'),
            (client?['full_name'] ?? client?['username'] ?? '—').toString()),
        _row(_tr('Email', 'البريد الإلكتروني', 'E-mail'),
            (client?['email'] ?? '—').toString()),
        _row(_tr('Phone', 'الهاتف', 'Téléphone'),
            _mission!.phoneNumber.isEmpty ? '—' : _mission!.phoneNumber),
      ],
    );
  }

  Widget _buildDriverCard() {
    final driver = _mission!.assignedEmployee;
    return _card(
      title: _tr('Assigned driver', 'السائق المعيّن', 'Chauffeur assigné'),
      children: [
        if (driver == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _tr('No driver assigned yet.', 'لم يتم تعيين سائق بعد.',
                  'Aucun chauffeur assigné.'),
              style: _pop(size: 12, color: const Color(0xFF999999)),
            ),
          )
        else ...[
          _row(_tr('ID', 'الرقم', 'ID'), (driver['id'] ?? '—').toString()),
          _row(_tr('Name', 'الاسم', 'Nom'),
              (driver['full_name'] ?? driver['username'] ?? '—').toString()),
        ],
      ],
    );
  }

  Widget _buildNegotiationCard() {
    final n = _negotiation;
    return _card(
      title: _tr('Negotiation history', 'سجل التفاوض', 'Historique de négociation'),
      children: [
        if (_negotiationUnavailable)
          Text(
            _tr('Not available for the boss role. Open the mission as the client or driver to see offers.',
                'غير متاح لدور المدير. افتح المهمة كعميل أو سائق لعرض العروض.',
                'Non disponible pour le rôle patron. Ouvrez la mission en tant que client ou chauffeur.'),
            style: _pop(size: 12, color: const Color(0xFF999999)),
          )
        else if (n == null)
          Text(
            _tr('No negotiation on this mission.', 'لا يوجد تفاوض على هذه المهمة.',
                'Aucune négociation sur cette mission.'),
            style: _pop(size: 12, color: const Color(0xFF999999)),
          )
        else ...[
          _row(_tr('Status', 'الحالة', 'Statut'), n.status),
          _row(_tr('Current amount', 'المبلغ الحالي', 'Montant actuel'),
              '${n.displayedAmount} ${n.currency}'),
          _row(_tr('Range', 'النطاق', 'Plage'),
              '${n.minAmount} – ${n.maxAmount} ${n.currency}'),
          _row(_tr('Offers', 'العروض', 'Offres'), '${n.offerCount}/${n.maxOffers}'),
          const SizedBox(height: 8),
          if (n.offers.isEmpty)
            Text(_tr('No offers yet.', 'لا توجد عروض بعد.', 'Aucune offre.'),
                style: _pop(size: 11, color: const Color(0xFFAAAAAA)))
          else
            ...n.offers.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text('#${o.sequence}',
                          style: _pop(size: 10, color: const Color(0xFF999999))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          o.authorRole == 'driver'
                              ? _tr('Driver', 'السائق', 'Chauffeur')
                              : _tr('Client', 'العميل', 'Client'),
                          style: _pop(size: 11, weight: FontWeight.w600),
                        ),
                      ),
                      Text('${o.amount} ${n.currency}',
                          style: _pop(size: 11, weight: FontWeight.w700,
                              color: _amber)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    final m = _mission!;
    final canModify = m.status != 'completed' && m.status != 'cancelled';
    return _card(
      title: _tr('Actions', 'الإجراءات', 'Actions'),
      children: [
        if (_acting)
          const Center(child: CircularProgressIndicator(color: _amber))
        else
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: canModify && m.status == 'pending' ? _assign : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: canModify && m.status == 'pending'
                          ? _amber
                          : const Color(0xFFCCCCCC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _tr('Assign driver', 'تعيين سائق', 'Assigner un chauffeur'),
                      textAlign: TextAlign.center,
                      style: _pop(size: 12, weight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: canModify ? _cancel : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: canModify
                              ? const Color(0xFFFFF3DC)
                              : const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _tr('Cancel', 'إلغاء', 'Annuler'),
                          textAlign: TextAlign.center,
                          style: _pop(size: 12, weight: FontWeight.w700,
                              color: const Color(0xFFB87600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _delete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _tr('Delete', 'حذف', 'Supprimer'),
                          textAlign: TextAlign.center,
                          style: _pop(size: 12, weight: FontWeight.w700,
                              color: const Color(0xFFE0533D)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _card({required String title, required List<Widget> children}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: _pop(size: 14, weight: FontWeight.w800,
                    color: const Color(0xFF111111))),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: _pop(size: 11, color: const Color(0xFF999999))),
            ),
            Expanded(
              child: Text(value.isEmpty ? '—' : value,
                  style: _pop(size: 12, weight: FontWeight.w600,
                      color: const Color(0xFF333333))),
            ),
          ],
        ),
      );
}
