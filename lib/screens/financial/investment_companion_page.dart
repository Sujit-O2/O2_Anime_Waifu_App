import 'package:flutter/material.dart';
import 'package:anime_waifu/services/financial/investment_companion_service.dart';

class InvestmentCompanionPage extends StatefulWidget {
  const InvestmentCompanionPage({super.key});

  @override
  State<InvestmentCompanionPage> createState() => _InvestmentCompanionPageState();
}

class _InvestmentCompanionPageState extends State<InvestmentCompanionPage> {
  final _service = InvestmentCompanionService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📈 Investment Companion'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_service.getPortfolioSummary()),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Investment tips: Diversify your portfolio...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
