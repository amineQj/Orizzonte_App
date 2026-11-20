import 'dart:async';

import 'package:flutter/material.dart';

import '../app_language.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/api_state.dart';
import '../widgets/app_text_style.dart';

TextStyle _pop({
  double? size,
  FontWeight? weight,
  Color? color,
  double? height,
}) =>
    appPop(size: size, weight: weight, color: color, height: height);

const _amber = Color(0xFFF5A524);

/// Negotiation detail screen: fetch state, send offers, accept or decline.
class NegotiationPage extends StatefulWidget {
  final int missionId;
  /// Used to align the offer timeline correctly on both client and driver screens.
  final String role;
  /// Injectable for widget tests; production uses the live API.
  final ApiService? api;

  const NegotiationPage({
    super.key,
    required this.missionId,
    this.role = 'client',
    this.api,
  });

  @override
  State<NegotiationPage> createState() => _NegotiationPageState();
}

class _NegotiationPageState extends State<NegotiationPage> {
  late final ApiService _api;
  final TextEditingController _amount = TextEditingController();

  Negotiation? _negotiation;
  bool _loading = true;
  String? _error;
  bool _busy = false;
  DateTime _now = DateTime.now();
  Timer? _timer;
  Timer? _pollTimer;

  /// One key per offer intent. A retry of the same offer reuses it so the
  /// backend's idempotency guard cannot create a duplicate offer.
  String? _offerKey;

  String get _lang => appLanguage.lang;
  bool get _isArabic => _lang == 'AR';

  String _t(String en, String ar, String fr) {
    if (_isArabic) return ar;
    if (_lang == 'FR') return fr;
    return en;
  }

  @override
  void initState() {
    _api = widget.api ?? ApiService();
    super.initState();
    appLanguage.addListener(_onLangChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    // The other party may offer while this screen is open. Poll quietly so
    // the timeline, amounts and `your_turn` state stay live.
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && !_busy && !_loading) _silentRefresh();
    });
    _load();
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    _timer?.cancel();
    _pollTimer?.cancel();
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
      if (_amount.text.isEmpty) _amount.text = n.displayedAmount.toString();
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

  /// Background refresh that never hides the current UI and never overwrites
  /// an amount the user is typing.
  Future<void> _silentRefresh() async {
    try {
      final n = await _api.getNegotiation(widget.missionId);
      if (!mounted) return;
      setState(() => _negotiation = n);
    } catch (_) {
      // A transient failure must not interrupt an in-progress offer.
    }
  }

  Future<void> _offer() async {
    final n = _negotiation;
    if (n == null) return;
    if (n.expiresAt != null && _now.isAfter(n.expiresAt!)) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        showApiErrorWithMessenger(
          messenger,
          _t('This negotiation has expired.', 'انتهى هذا التفاوض.', 'Cette négociation a expiré.'),
        );
      }
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final value = int.tryParse(_amount.text.trim().replaceAll(',', ''));
    String? validationError;
    if (value == null || value <= 0) {
      validationError = _t('Enter a valid amount.', 'أدخل مبلغاً صحيحاً.',
          'Saisissez un montant valide.');
    } else if (value < n.minAmount || value > n.maxAmount) {
      validationError = _t(
        'Amount must be between ${n.minAmount} and ${n.maxAmount} DZD.',
        'يجب أن يكون المبلغ بين ${n.minAmount} و ${n.maxAmount} د.ج.',
        'Le montant doit être entre ${n.minAmount} et ${n.maxAmount} DZD.',
      );
    } else if (n.currentAmount != null && n.minStep > 0 &&
        (value - n.currentAmount!).abs() < n.minStep) {
      validationError = _t(
        'Amount must change by at least ${n.minStep} DZD.',
        'يجب أن يتغير المبلغ بمقدار ${n.minStep} د.ج. على الأقل.',
        'Le montant doit changer d\'au moins ${n.minStep} DZD.',
      );
    } else if (n.offersLeft <= 0) {
      validationError = _t(
        'No offers left. Accept or decline the current offer.',
        'لا توجد عروض متبقية. اقبل العرض الحالي أو ارفضه.',
        'Plus d\'offres. Acceptez ou refusez l\'offre actuelle.',
      );
    }
    if (validationError != null) {
      if (messenger != null) {
        showApiErrorWithMessenger(messenger, validationError);
      }
      return;
    }
    // Keep the same key across retries until the backend confirms the offer.
    _offerKey ??= ApiService.newIdempotencyKey();
    setState(() => _busy = true);
    try {
      final updated = await _api.makeOffer(
        widget.missionId,
        value!,
        idempotencyKey: _offerKey!,
      );
      if (!mounted) return;
      _offerKey = null;
      _amount.text = updated.displayedAmount.toString();
      setState(() => _negotiation = updated);
      if (messenger != null) {
        showSuccessWithMessenger(
            messenger,
            _t('Offer sent.', 'تم إرسال العرض.', 'Offre envoyée.'));
      }
    } catch (e) {
      if (messenger != null) showApiErrorWithMessenger(messenger, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept() async {
    final n = _negotiation;
    if (n != null && n.expiresAt != null && _now.isAfter(n.expiresAt!)) {
      showApiError(
        context,
        _t('This negotiation has expired.', 'انتهى هذا التفاوض.', 'Cette négociation a expiré.'),
      );
      return;
    }
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
    final n = _negotiation;
    if (n != null && n.expiresAt != null && _now.isAfter(n.expiresAt!)) {
      showApiError(
        context,
        _t('This negotiation has expired.', 'انتهى هذا التفاوض.', 'Cette négociation a expiré.'),
      );
      return;
    }
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
    return RefreshIndicator(
      color: _amber,
      onRefresh: _load,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
          if (n.holdExpiresAt != null && !n.isOpen) ...[
            const SizedBox(height: 8),
            Text(
              '${_t('Acceptance hold expires in', 'تنتهي مهلة القبول خلال', 'Blocage d\'acceptation expire dans')} '
              '${_formatDuration(n.holdExpiresAt!.difference(_now))}',
              style: _pop(
                size: 12,
                weight: FontWeight.w600,
                color: const Color(0xFFB87600),
              ),
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
    final isMine = offer.authorRole == widget.role;
    final mine = isMine
        ? _t('You', 'أنت', 'Vous')
        : widget.role == 'client'
            ? _t('Driver', 'السائق', 'Chauffeur')
            : _t('Client', 'العميل', 'Client');
    final time = offer.createdAt == null
        ? ''
        : '${offer.createdAt!.hour.toString().padLeft(2, '0')}:'
            '${offer.createdAt!.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: _card(
              color: isMine ? const Color(0xFFFFF3DC) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('#${offer.sequence}  $mine',
                          style: _pop(
                              size: 11,
                              weight: FontWeight.w700,
                              color: const Color(0xFF999999))),
                      const Spacer(),
                      if (time.isNotEmpty)
                        Text(time,
                            style: _pop(size: 10,
                                color: const Color(0xFFBBBBBB))),
                    ],
                  ),
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
          const SizedBox(height: 8),
          Text(
            _t(
              'Allowed range: ${n.minAmount} – ${n.maxAmount} DZD • '
              'Minimum step: ${n.minStep} • Offers left: ${n.offersLeft}',
              'النطاق المسموح: ${n.minAmount} – ${n.maxAmount} د.ج • '
              'أقل خطوة: ${n.minStep} • العروض المتبقية: ${n.offersLeft}',
              'Plage autorisée : ${n.minAmount} – ${n.maxAmount} DZD • '
              'Pas minimum : ${n.minStep} • Offres restantes : ${n.offersLeft}',
            ),
            style: _pop(size: 10, color: const Color(0xFF999999)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: _t('Send offer', 'إرسال العرض', 'Envoyer'),
                  color: _amber,
                  enabled: !_busy &&
                      n.yourTurn &&
                      n.offersLeft > 0 &&
                      (n.expiresAt == null || !_now.isAfter(n.expiresAt!)),
                  busy: _busy,
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
                  enabled: !_busy &&
                      !n.yourTurn &&
                      n.currentAmount != null &&
                      n.isOpen &&
                      (n.expiresAt == null || !_now.isAfter(n.expiresAt!)),
                  busy: _busy,
                  onTap: _accept,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  label: _t('Decline', 'رفض', 'Refuser'),
                  color: const Color(0xFFE0533D),
                  enabled: !_busy,
                  busy: _busy,
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
    bool busy = false,
  }) =>
      GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: enabled ? color : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: busy && enabled
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: _pop(
                        size: 13,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: _pop(
                    size: 13,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
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
