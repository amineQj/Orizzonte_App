import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_language.dart';
import '../order_flow.dart';
import '../order_model.dart';
import '../customer_screen.dart';
import 'mission_model.dart';
import 'mission_repository.dart';

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

class CustomerMissionDetailsPage extends StatefulWidget {
  final String missionId;
  const CustomerMissionDetailsPage({super.key, required this.missionId});

  @override
  State<CustomerMissionDetailsPage> createState() =>
      _CustomerMissionDetailsPageState();
}

class _CustomerMissionDetailsPageState
    extends State<CustomerMissionDetailsPage> {
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
    final mission = MissionRepository.instance.byId(widget.missionId);

    if (mission == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: Center(
          child: Text(
            _t('Mission not found', 'المهمة غير موجودة', 'Mission introuvable'),
            style: _pop(size: 15, color: const Color(0xFF999999)),
          ),
        ),
      );
    }

    final o = mission.order;
    final canCancel =
        mission.status == MissionStatus.pending ||
        mission.status == MissionStatus.searching ||
        mission.status == MissionStatus.accepted ||
        mission.status == MissionStatus.inProgress;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            size: 28,
            color: Color(0xFF111111),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Mission Details', 'تفاصيل المهمة', 'Détails mission'),
          style: _pop(
            size: 17,
            weight: FontWeight.w700,
            color: const Color(0xFF111111),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(mission),
            const SizedBox(height: 20),
            _sectionCard(
              icon: Icons.route_outlined,
              title: _t('Route', 'المسار', 'Itinéraire'),
              rows: [
                _detailRow(
                  Icons.location_on_outlined,
                  _t('Pickup', 'نقطة الاستلام', 'Prise en charge'),
                  o.pickup,
                ),
                _detailRow(
                  Icons.flag_outlined,
                  _t('Delivery', 'نقطة التسليم', 'Livraison'),
                  o.delivery,
                ),
                if (o.distance != null && o.distance!.isNotEmpty)
                  _detailRow(
                    Icons.straighten,
                    _t('Distance', 'المسافة', 'Distance'),
                    o.distance!,
                  ),
                _detailRow(
                  Icons.calendar_today_outlined,
                  _t('Date and time', 'التاريخ والوقت', 'Date et heure'),
                  _dateLabel(o),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionCard(
              icon: Icons.directions_car_outlined,
              title: _t('Vehicle', 'المركبة', 'Véhicule'),
              rows: [
                _detailRow(
                  Icons.local_shipping_outlined,
                  _t('Truck type', 'نوع الشاحنة', 'Type de camion'),
                  truckTypeLabel(o.truckType, _lang),
                ),
                _detailRow(
                  Icons.category_outlined,
                  _t('Truck model', 'طراز الشاحنة', 'Modèle'),
                  o.truckModel.isNotEmpty
                      ? o.truckModel
                      : _t('Standard', 'قياسي', 'Standard'),
                ),
                _detailRow(
                  Icons.scale_outlined,
                  _t('Weight / Capacity', 'الوزن / القدرة', 'Poids / Capacité'),
                  o.weight.isNotEmpty ? o.weight : '-',
                ),
                if (o.bodyType.isNotEmpty)
                  _detailRow(
                    Icons.directions_car_outlined,
                    _t('Body type', 'نوع الهيكل', 'Carrosserie'),
                    o.bodyType,
                  ),
                if (o.length.isNotEmpty)
                  _detailRow(
                    Icons.straighten,
                    _t('Length', 'الطول', 'Longueur'),
                    o.length,
                  ),
                if (o.width.isNotEmpty)
                  _detailRow(
                    Icons.straighten,
                    _t('Width', 'العرض', 'Largeur'),
                    o.width,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionCard(
              icon: Icons.inventory_2_outlined,
              title: _t(
                'Cargo & Contact',
                'البضاعة والتواصل',
                'Marchandise & contact',
              ),
              rows: [
                _detailRow(
                  Icons.shopping_bag_outlined,
                  _t('Commodity', 'البضاعة', 'Marchandise'),
                  o.commodity.isNotEmpty
                      ? o.commodity
                      : _t(
                          'No description',
                          'لا يوجد وصف',
                          'Aucune description',
                        ),
                ),
                _detailRow(
                  Icons.people_outline,
                  _t('Helpers', 'المساعدين', 'Aides'),
                  o.helpers.toString().padLeft(2, '0'),
                ),
                if (o.estimatedPrice.isNotEmpty)
                  _detailRow(
                    Icons.attach_money,
                    _t('Estimated price', 'السعر التقديري', 'Prix estimé'),
                    '${o.estimatedPrice} DZD',
                  ),
                _detailRow(
                  Icons.phone_outlined,
                  _t('Phone', 'الهاتف', 'Téléphone'),
                  o.phoneNumber,
                ),
                _detailRow(
                  Icons.message_outlined,
                  _t('Confirmation via', 'التأكيد عبر', 'Confirmation via'),
                  o.confirmationMethod == 'whatsapp' ? 'WhatsApp' : 'SMS',
                ),
              ],
            ),
            if (mission.driver != null) ...[
              const SizedBox(height: 20),
              _buildDriverCard(mission.driver!),
            ],
            if (canCancel) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _confirmCancel,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _t(
                          'Cancel Mission',
                          'إلغاء المهمة',
                          'Annuler la mission',
                        ),
                        style: _pop(
                          size: 14,
                          weight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> rows,
  }) {
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
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFF5A524)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: _pop(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
          const SizedBox(height: 6),
          ...List.generate(rows.length, (i) {
            final row = rows[i];
            final isLast = i == rows.length - 1;
            return Column(
              children: [
                row,
                if (!isLast)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF5F5F5),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFBBBBBB)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: _pop(size: 13, color: const Color(0xFF999999)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
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

  Widget _buildHeaderCard(CustomerMission m) {
    final status = _statusInfo(m.status);
    final o = m.order;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A524), Color(0xFFF5A524)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A524).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(status.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryLabel(o.category, _lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _pop(
                        size: 18,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${truckTypeLabel(o.truckType, _lang)}${o.weight.isNotEmpty ? ' · ${o.weight}' : ''}',
                      style: _pop(
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_t('ID', 'رقم', 'ID')} · ${m.id}',
                      style: _pop(
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.label,
                      style: _pop(
                        size: 12,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(DriverInfo driver) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A524), Color(0xFFF5A524)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A524).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _t('Assigned Driver', 'السائق المعيّن', 'Chauffeur assigné'),
                style: _pop(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(driver.name),
                    style: _pop(
                      size: 16,
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
                      style: _pop(
                        size: 15,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (driver.vehicle != null)
                      Text(
                        driver.vehicle!,
                        style: _pop(
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    if (driver.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            '${driver.rating}',
                            style: _pop(
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    driver.phone.isNotEmpty
                        ? driver.phone
                        : _t('Contact', 'اتصل', 'Contacter'),
                    style: _pop(
                      size: 13,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _dateLabel(OrderData o) {
    if (o.isNow) return _t('Now', 'الآن', 'Maintenant');
    if (o.manualDate.isNotEmpty && o.manualTime.isNotEmpty) {
      return '${o.manualDate} ${o.manualTime}';
    }
    if (o.manualDate.isNotEmpty) return o.manualDate;
    return _t('Scheduled', 'مجدول', 'Planifié');
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              child: const Icon(
                Icons.cancel_outlined,
                size: 32,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t(
                'Cancel this mission?',
                'إلغاء هذه المهمة؟',
                'Annuler cette mission ?',
              ),
              style: _pop(
                size: 16,
                weight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'This action cannot be undone.',
                'لا يمكن التراجع عن هذا الإجراء.',
                'Cette action est irréversible.',
              ),
              textAlign: TextAlign.center,
              style: _pop(size: 13, color: const Color(0xFF666666)),
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
                          _t('Keep', 'إبقاء', 'Garder'),
                          style: _pop(
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
                    onTap: () {
                      Navigator.pop(ctx);
                      MissionRepository.instance.updateStatus(
                        widget.missionId,
                        MissionStatus.cancelled,
                      );
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _t('Cancel', 'إلغاء', 'Annuler'),
                          style: _pop(
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
      ),
    );
  }

  _StatusInfo _statusInfo(MissionStatus s) {
    switch (s) {
      case MissionStatus.pending:
        return _StatusInfo(
          const Color(0xFF9E9E9E),
          const Color(0xFFF5F5F5),
          _t('Pending', 'قيد الانتظار', 'En attente'),
          Icons.hourglass_empty,
        );
      case MissionStatus.searching:
        return _StatusInfo(
          const Color(0xFF2196F3),
          const Color(0xFFE3F2FD),
          _t('Searching for driver', 'البحث عن سائق', 'Recherche chauffeur'),
          Icons.search,
        );
      case MissionStatus.accepted:
        return _StatusInfo(
          const Color(0xFFF5A524),
          const Color(0xFFFFF3E0),
          _t('Accepted', 'مقبول', 'Acceptée'),
          Icons.check_circle_outline,
        );
      case MissionStatus.inProgress:
        return _StatusInfo(
          const Color(0xFF3F51B5),
          const Color(0xFFE8EAF6),
          _t('In Progress', 'قيد التنفيذ', 'En cours'),
          Icons.local_shipping_outlined,
        );
      case MissionStatus.completed:
        return _StatusInfo(
          const Color(0xFF4CAF50),
          const Color(0xFFE8F5E9),
          _t('Completed', 'مكتمل', 'Terminée'),
          Icons.verified_outlined,
        );
      case MissionStatus.cancelled:
        return _StatusInfo(
          const Color(0xFFEF4444),
          const Color(0xFFFFEBEE),
          _t('Cancelled', 'ملغاة', 'Annulée'),
          Icons.cancel_outlined,
        );
    }
  }
}

class _StatusInfo {
  final Color color;
  final Color bg;
  final String label;
  final IconData icon;
  const _StatusInfo(this.color, this.bg, this.label, this.icon);
}
