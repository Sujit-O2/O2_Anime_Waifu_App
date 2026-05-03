import 'package:anime_waifu/services/financial/investment_companion_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class InvestmentCompanionPage extends StatefulWidget {
  const InvestmentCompanionPage({super.key});

  @override
  State<InvestmentCompanionPage> createState() =>
      _InvestmentCompanionPageState();
}

class _InvestmentCompanionPageState extends State<InvestmentCompanionPage>
    with SingleTickerProviderStateMixin {
  final _service = InvestmentCompanionService.instance;
  late TabController _tabs;
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _symbolCtrl = TextEditingController();
  PortfolioType _portfolioType = PortfolioType.stocks;
  bool _loading = true;
  bool _saving = false;

  static const _accent = Color(0xFF00D1FF);
  static const _bg = Color(0xFF0A0B14);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _symbolCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createPortfolio() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (_nameCtrl.text.trim().isEmpty || amount <= 0) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await _service.createPortfolio(
      name: _nameCtrl.text.trim(),
      description: 'Tracked from Investment Companion',
      type: _portfolioType,
      initialInvestment: amount,
      holdings: const [],
    );
    _nameCtrl.clear();
    _amountCtrl.clear();
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _addWatch() async {
    if (_symbolCtrl.text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    final symbol = _symbolCtrl.text.trim().toUpperCase();
    await _service.addToWatchlist(
      symbol: symbol,
      name: symbol,
      type: 'Stock',
      exchange: 'Manual',
    );
    _symbolCtrl.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('📈 Investment Companion',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Portfolio'),
            Tab(text: 'Watchlist'),
            Tab(text: 'Learn'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildPortfolioTab(cs),
                _buildWatchlistTab(cs),
                _buildLearnTab(cs),
              ],
            ),
    );
  }

  Widget _buildPortfolioTab(ColorScheme cs) {
    final portfolios = _service.getPortfolios();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        _gradientCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('💼', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text('Portfolio Summary',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            Text(_service.getPortfolioSummary(),
                style: GoogleFonts.outfit(
                    color: Colors.white70, fontSize: 13, height: 1.5)),
          ]),
          color: _accent,
        ),
        const SizedBox(height: 12),
        _infoCard(Icons.lightbulb_rounded, 'Recommendations',
            _service.getInvestmentRecommendations(), Colors.amberAccent),
        const SizedBox(height: 16),

        // Create portfolio form
        _formCard(
          title: 'New Portfolio',
          child: Column(children: [
            _field(_nameCtrl, 'Portfolio Name', Icons.pie_chart_rounded),
            const SizedBox(height: 10),
            _field(_amountCtrl, 'Initial Amount (\$)',
                Icons.attach_money_rounded,
                type: TextInputType.number),
            const SizedBox(height: 12),
            // Type selector
            Wrap(
              spacing: 8,
              children: PortfolioType.values.map((t) {
                final sel = _portfolioType == t;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _portfolioType = t);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? _accent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? _accent.withValues(alpha: 0.6)
                              : Colors.white12),
                    ),
                    child: Text(t.name,
                        style: GoogleFonts.outfit(
                            color: sel ? _accent : Colors.white54,
                            fontSize: 11,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _actionBtn('Create Portfolio', Icons.add_rounded, _accent,
                _saving ? null : _createPortfolio, _saving),
          ]),
        ),
        const SizedBox(height: 16),

        if (portfolios.isEmpty)
          _emptyState('No portfolios yet', 'Create one above to start tracking')
        else ...[
          _sectionLabel('Your Portfolios'),
          const SizedBox(height: 8),
          ...portfolios.map((p) {
            final gain = p.currentValue - p.initialInvestment;
            final gainPct = p.initialInvestment > 0
                ? gain / p.initialInvestment * 100
                : 0.0;
            final isPos = gain >= 0;
            return _expandableCard(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.12),
                ),
                child: const Center(
                    child: Text('📊', style: TextStyle(fontSize: 18))),
              ),
              title: p.name,
              subtitle:
                  '\$${p.currentValue.toStringAsFixed(2)} • ${p.type.name}',
              trailing: Text(
                '${isPos ? '+' : ''}${gainPct.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                    color: isPos ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
              expandedContent: Text(
                _service.getPortfolioPerformance(p.id),
                style: GoogleFonts.outfit(
                    color: Colors.white70, fontSize: 12, height: 1.5),
              ),
            );
          }),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildWatchlistTab(ColorScheme cs) {
    final watches = _service.getWatchlist();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _formCard(
          title: 'Add to Watchlist',
          child: Row(children: [
            Expanded(
                child: _field(_symbolCtrl, 'Symbol (e.g. AAPL)',
                    Icons.show_chart_rounded)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _addWatch,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accent.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.add_rounded, color: _accent, size: 20),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        if (watches.isEmpty)
          _emptyState('Watchlist empty',
              'Add stock symbols to track them here')
        else ...[
          _sectionLabel('Watching ${watches.length} symbols'),
          const SizedBox(height: 8),
          ...watches.map((w) => _listCard(
                icon: Icons.show_chart_rounded,
                iconColor: Colors.greenAccent,
                title: w.symbol,
                subtitle: '${w.name} • ${w.exchange}',
                trailing: Text(w.type,
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 11)),
              )),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLearnTab(ColorScheme cs) {
    final concepts = _service.getConcepts();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard(Icons.school_rounded, 'Financial Education',
            'Expand your investment knowledge with these key concepts.',
            Colors.purpleAccent),
        const SizedBox(height: 16),
        _sectionLabel('Key Concepts'),
        const SizedBox(height: 8),
        ...concepts.map((c) => _expandableCard(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.purpleAccent, size: 16),
              ),
              title: c.title,
              subtitle: '${c.category.label} • ${c.difficulty.label}',
              trailing: _diffBadge(c.difficulty),
              expandedContent: Text(
                _service.getFinancialConcept(c.title),
                style: GoogleFonts.outfit(
                    color: Colors.white70, fontSize: 12, height: 1.5),
              ),
            )),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _diffBadge(ConceptDifficulty d) {
    final color = d == ConceptDifficulty.beginner
        ? Colors.greenAccent
        : d == ConceptDifficulty.intermediate
            ? Colors.amberAccent
            : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(d.label,
          style: GoogleFonts.outfit(color: color, fontSize: 10)),
    );
  }

  Widget _gradientCard({required Widget child, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }

  Widget _formCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _infoCard(IconData icon, String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.outfit(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Text(body,
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 12, height: 1.5)),
      ]),
    );
  }

  Widget _expandableCard({
    required Widget leading,
    required String title,
    required String subtitle,
    required Widget trailing,
    required Widget expandedContent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ExpansionTile(
        leading: leading,
        title: Text(title,
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(subtitle,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
        trailing: trailing,
        iconColor: Colors.white38,
        collapsedIconColor: Colors.white38,
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: expandedContent,
          ),
        ],
      ),
    );
  }

  Widget _listCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            Text(subtitle,
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 11)),
          ]),
        ),
        trailing,
      ]),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        const Text('📊', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 12),
        Text(title,
            style: GoogleFonts.outfit(
                color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.outfit(
            color: Colors.white54,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.8));
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color,
      VoidCallback? onTap, bool loading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : Icon(icon, size: 18),
        label: Text(loading ? 'Saving...' : label,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
