import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_language.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/api_state.dart';

TextStyle _pop({
  double? size,
  FontWeight? weight,
  Color? color,
  double? height,
}) =>
    GoogleFonts.poppins(
        fontSize: size, fontWeight: weight, color: color, height: height);

const _amber = Color(0xFFF5A524);

/// Negotiation detail screen: fetch state, send offers, accept or decline.
class NegotiationPage extends StatefulWidget {
  final int missionId;
  const NegotiationPage({super.key, required this.missionId});

  @override
  State<NegotiationPage> createState() => _NegotiationPageState();
}

class _NegotiationPageState extends State<NegotiationPage> {
  final ApiService _api = ApiService();
  final TextEditingController _amount = TextEditingController();

  Negotiation? _negotiation;
  bool _loading = true;
  String? _error;
  bool _busy = false;
  DateTime _now = DateTime.now();
  Timer? _timer;

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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _load();
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    _timer?.cancel();
    _amount.dispose();
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final n = await _api.getNegotiation(widget.missionId);
      if (!mounted) return;
      _amount.text.isEmpty
          ? _amount.text = n.displayedAmount.toString()
          : null;
      setState(() {
        _negotiation = n;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _offer() async {
    final value = int.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (value == null || value <= 0) {
      showApiError(
          context, _t('Enter a valid amount.', 'أدخل مبلغاً صحيحاً.', 'Saisissez un montant valide.'));
      return;
    }
    setState(() => _busy = true);
    try {
      final n = await _api.makeOffer(
        widget.missionId,
        value,
        idempotencyKey: ApiService.newIdempotencyKey(),
      );
      if (!mounted) return;
      setState(() => _negotiation = n);
      _amount.text = n.displayedAmount.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Offer sent.', 'تم إرسال العرض.', 'Offre envoyée.')),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      final result = await _api.acceptNegotiation(widget.missionId);
      if (!mounted) return;
      final n = await _api.getNegotiation(widget.missionId);
      if (!mounted) return;
      setState(() => _negotiation = n);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['mission'] != null
                ? _t('Offer accepted. Mission confirmed!',
                    'تم قبول العرض. تم تأكيد المهمة!', 'Offre acceptée. Mission confirmée !')
                : _t('Offer accepted.', 'تم قبول العرض.', 'Offre acceptée.'),
          ),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    try {
      final n = await _api.declineNegotiation(widget.missionId);
      if (!mounted) return;
      setState(() => _negotiation = n);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Negotiation declined.',
              'تم رفض التفاوض.', 'Négociation refusée.')),
          backgroundColor: const Color(0xFFE0533D),
        ),
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF222222)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Negotiation', 'التفاوض', 'Négociation'),
          style: _pop(size: 17, weight: FontWeight.w700, color: const Color(0xFF111111)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _amber),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const ApiLoadingView(message: 'Loading negotiation...')
          : _error != null
              ? ApiErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
    if (_isArabic) {
      return Directionality(textDirection: TextDirection.rtl, child: content);
    }
    return content;
  }

  Widget _buildBody() {
    final n = _negotiation!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusCard(n),
          const SizedBox(height: 16),
          _buildSectionTitle(
            _t('Offer timeline', 'سجل العروض', 'Historique des offres'),
          ),
          const SizedBox(height: 10),
          if (n.offers.isEmpty)
            _card(
              child: Text(
                _t('No offers yet. The driver starts.',
                    'لا توجد عروض بعد. السائق يبدأ أولاً.',
                    'Aucune offre. Le chauffeur commence.'),
                style: _pop(size: 13, color: const Color(0xFF999999)),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...n.offers.map(_offerTile),
          if (n.isOpen) ...[
            const SizedBox(height: 20),
            _buildSectionTitle(
              _t('Send an offer', 'إرسال عرض', 'Envoyer une offre'),
            ),
            const SizedBox(height: 10),
            _buildOfferForm(n),
          ],
        ],
      ),
    );
  }

  Widget _statusCard(Negotiation n) {
    final remaining = n.expiresAt != null
        ? n.expiresAt!.difference(_now)
        : const Duration(seconds: 0);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  n.status.toUpperCase(),
                  style: _pop(size: 11, weight: FontWeight.w700, color: _amber),
                ),
              ),
              const Spacer(),
              if (n.yourTurn && n.isOpen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _t('Your turn', 'دورك', 'À vous'),
                    style: _pop(
                        size: 11,
                        weight: FontWeight.w700,
                        color: const Color(0xFF4CAF50)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${formatDzd(n.displayedAmount)} ${n.currency}',
            style: _pop(size: 28, weight: FontWeight.w800, color: _amber),
          ),
          const SizedBox(height: 6),
          Text(
            '${_t('Range', 'النطاق', 'Plage')}: ${formatDzd(n.minAmount)} – ${formatDzd(n.maxAmount)} ${n.currency}',
            style: _pop(size: 12, color: const Color(0xFF777777)),
          ),
          const SizedBox(height: 6),
          Text(
            '${_t('Offers left', 'العروض المتبقية', 'Offres restantes')}: ${n.offersLeft}/${n.maxOffers}'
            '${n.isFinal ? '  •  ${_t('Final offer', 'العرض الأخير', 'Offre finale')}' : ''}',
            style: _pop(size: 12, color: const Color(0xFF777777)),
          ),
          if (n.expiresAt != null && n.isOpen) ...[
            const SizedBox(height: 8),
            Text(
              '${_t('Expires in', 'ينتهي خلال', 'Expire dans')} '
              '${_formatDuration(remaining)}',
              style: _pop(
                  size: 12,
                  weight: FontWeight.w600,
                  color: remaining.inSeconds <= 60
                      ? const Color(0xFFE0533D)
                      : const Color(0xFF777777)),
            ),
          ],
          if (n.driverNet != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_t('Driver net', 'صافي السائق', 'Net chauffeur')}: ${formatDzd(n.driverNet!)} ${n.currency}'
              '${n.commissionRate != null ? '  •  ${_t('Fee', 'عمولة', 'Commission')} ${n.commissionRate}' : ''}',
              style: _pop(size: 12, color: const Color(0xFF4CAF50)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _offerTile(NegotiationOffer offer) {
    final mine = offer.authorRole == 'client'
        ? _t('You', 'أنت', 'Vous')
        : _t('Driver', 'السائق', 'Chauffeur');
    final isClient = offer.authorRole == 'client';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isClient ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: _card(
              color: isClient ? const Color(0xFFFFF3DC) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mine,
                      style: _pop(
                          size: 11,
                          weight: FontWeight.w700,
                          color: const Color(0xFF999999))),
                  const SizedBox(height: 4),
                  Text(
                    '${formatDzd(offer.amount)} ${_negotiation!.currency}',
                    style: _pop(
                        size: 17,
                        weight: FontWeight.w800,
                        color: const Color(0xFF222222)),
                  ),
                  if (offer.isFinal)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _t('Final offer', 'العرض الأخير', 'Offre finale'),
                        style: _pop(size: 10, color: const Color(0xFFE0533D)),
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

  Widget _buildOfferForm(Negotiation n) {
    return _card(
      child: Column(
        children: [
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _t('Amount (DZD)', 'المبلغ (د.ج)', 'Montant (DZD)'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _amber, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: _t('Send offer', 'إرسال العرض', 'Envoyer'),
                  color: _amber,
                  enabled: !_busy && n.yourTurn,
                  onTap: _offer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: _t('Accept', 'قبول', 'Accepter'),
                  color: const Color(0xFF4CAF50),
                  enabled: !_busy && !n.yourTurn && n.currentAmount != null,
                  onTap: _accept,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  label: _t('Decline', 'رفض', 'Refuser'),
                  color: const Color(0xFFE0533D),
                  enabled: !_busy,
                  onTap: _decline,
                ),
              ),
            ],
          ),
          if (!n.yourTurn)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _t('Waiting for the other party.', 'في انتظار الطرف الآخر.',
                    'En attente de l\'autre partie.'),
                style: _pop(size: 11, color: const Color(0xFF999999)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: enabled ? color : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: _pop(
                size: 13, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
      );

  Widget _buildSectionTitle(String title) => Text(
        title,
        style:
            _pop(size: 15, weight: FontWeight.w700, color: const Color(0xFF111111)),
      );

  Widget _card({required Widget child, Color? color}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFEFEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  String _formatDuration(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) return '00:00';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
