import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language.dart';

TextStyle _pop({double? size, FontWeight? weight, Color? color, double? height, double? letterSpacing}) {
  return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);
}

class _Transaction {
  final String id;
  final String description;
  final String amount;
  final String date;
  final String type; // 'credit' | 'debit'
  final String status; // 'completed' | 'pending'

  const _Transaction({required this.id, required this.description, required this.amount, required this.date, required this.type, required this.status});
}

class DriverWalletPage extends StatefulWidget {
  const DriverWalletPage({super.key});

  @override
  State<DriverWalletPage> createState() => _DriverWalletPageState();
}

class _DriverWalletPageState extends State<DriverWalletPage> {
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
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() { setState(() {}); }

  final List<_Transaction> _transactions = const [
    _Transaction(id: 'TXN-001', description: 'Mission M-012 completed', amount: '+10,000', date: '2026-07-20', type: 'credit', status: 'completed'),
    _Transaction(id: 'TXN-002', description: 'Mission M-011 completed', amount: '+4,500', date: '2026-07-18', type: 'credit', status: 'completed'),
    _Transaction(id: 'TXN-003', description: 'Withdrawal to bank', amount: '-8,000', date: '2026-07-15', type: 'debit', status: 'completed'),
    _Transaction(id: 'TXN-004', description: 'Mission M-009 completed', amount: '+12,000', date: '2026-07-12', type: 'credit', status: 'completed'),
    _Transaction(id: 'TXN-005', description: 'Mission M-008 completed', amount: '+6,500', date: '2026-07-10', type: 'credit', status: 'completed'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 24),
          Text(_t('Transactions', 'المعاملات', 'Transactions'),
            style: _pop(size: 16, weight: FontWeight.w700, color: const Color(0xFF111111))),
          const SizedBox(height: 12),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF1A1A2E).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t('Total Balance', 'الرصيد الإجمالي', 'Solde total'),
                style: _pop(size: 13, color: Colors.white.withValues(alpha: 0.6))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+12.5%', style: _pop(size: 11, weight: FontWeight.w600, color: const Color(0xFF4CAF50))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('25,000 DZD', style: _pop(size: 36, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat(_t('This Month', 'هذا الشهر', 'Ce mois'), '14,500 DZD'),
              const SizedBox(width: 24),
              _buildMiniStat(_t('Last Month', 'الشهر الماضي', 'Mois dernier'), '18,500 DZD'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _pop(size: 11, color: Colors.white.withValues(alpha: 0.5))),
        const SizedBox(height: 4),
        Text(value, style: _pop(size: 14, weight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _buildActionCard(Icons.account_balance, _t('Withdraw', 'سحب', 'Retirer'), const Color(0xFFF5A524))),
        const SizedBox(width: 12),
        Expanded(child: _buildActionCard(Icons.history, _t('History', 'التاريخ', 'Historique'), const Color(0xFF2196F3))),
        const SizedBox(width: 12),
        Expanded(child: _buildActionCard(Icons.receipt_long, _t('Invoice', 'الفاتورة', 'Facture'), const Color(0xFF4CAF50))),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 8),
            Text(label, style: _pop(size: 12, weight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Column(
      children: _transactions.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildTransactionTile(t),
      )).toList(),
    );
  }

  Widget _buildTransactionTile(_Transaction t) {
    final isCredit = t.type == 'credit';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              size: 20,
              color: isCredit ? const Color(0xFF4CAF50) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.description, style: _pop(size: 13, weight: FontWeight.w600, color: const Color(0xFF111111))),
                const SizedBox(height: 2),
                Text(t.date, style: _pop(size: 11, color: const Color(0xFF999999))),
              ],
            ),
          ),
          Text(
            '${t.amount} DZD',
            style: _pop(
              size: 14,
              weight: FontWeight.w700,
              color: isCredit ? const Color(0xFF4CAF50) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}
