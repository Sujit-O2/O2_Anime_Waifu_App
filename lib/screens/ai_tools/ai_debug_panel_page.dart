import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class AiDebugPanelPage extends StatefulWidget {
  const AiDebugPanelPage({super.key});
  @override
  State<AiDebugPanelPage> createState() => _AiDebugPanelPageState();
}

class _AiDebugPanelPageState extends State<AiDebugPanelPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeCtrl;
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _apiCalls = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final rawLogs = prefs.getString('ai_debug_panel_logs_v2');
    final rawCalls = prefs.getString('ai_debug_panel_calls_v2');
    final rawStats = prefs.getString('ai_debug_panel_stats_v2');
    if (!mounted) return;
    setState(() {
      _logs = rawLogs == null
          ? _generateSampleLogs()
          : (jsonDecode(rawLogs) as List)
              .map((item) => _deserializeLog(Map<String, dynamic>.from(item)))
              .toList();
      _apiCalls = rawCalls == null
          ? _generateSampleApiCalls()
          : (jsonDecode(rawCalls) as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
      _stats = rawStats == null
          ? _buildStats(_apiCalls)
          : Map<String, dynamic>.from(jsonDecode(rawStats) as Map);
      _selectedFilter = prefs.getString('ai_debug_panel_filter_v2') ?? 'All';
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ai_debug_panel_logs_v2',
      jsonEncode(_logs.map(_serializeLog).toList()),
    );
    await prefs.setString(
      'ai_debug_panel_calls_v2',
      jsonEncode(_apiCalls),
    );
    await prefs.setString(
      'ai_debug_panel_stats_v2',
      jsonEncode(_stats),
    );
    await prefs.setString('ai_debug_panel_filter_v2', _selectedFilter);
  }

  Map<String, dynamic> _serializeLog(Map<String, dynamic> log) {
    return <String, dynamic>{
      ...log,
      'timestamp': (log['timestamp'] as DateTime).toIso8601String(),
    };
  }

  Map<String, dynamic> _deserializeLog(Map<String, dynamic> log) {
    return <String, dynamic>{
      ...log,
      'timestamp': DateTime.tryParse(log['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    };
  }

  Map<String, dynamic> _buildStats(List<Map<String, dynamic>> calls) {
    final totalRequests = calls.length;
    final successCount =
        calls.where((item) => ((item['status'] as int?) ?? 500) < 300).length;
    final avgDuration = totalRequests == 0
        ? 0
        : calls.fold<int>(
              0,
              (sum, item) => sum + ((item['duration'] as int?) ?? 0),
            ) ~/
            totalRequests;
    return <String, dynamic>{
      'total_requests': totalRequests,
      'success_rate':
          totalRequests == 0 ? 100.0 : ((successCount / totalRequests) * 100),
      'avg_response_time': '${avgDuration}ms',
      'tokens_used': 42000 + (totalRequests * 25),
      'cache_hit_rate': totalRequests == 0
          ? 0.0
          : (calls.where((item) => item['method'] == 'GET').length /
                  totalRequests) *
              100,
      'errors': _logs.where((item) => item['level'] == 'ERROR').length,
    };
  }

  Future<void> _captureSnapshot() async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final levels = <String>['INFO', 'DEBUG', 'WARN', 'ERROR'];
    final methods = <String>['GET', 'POST'];
    final endpoints = <String>[
      '/v1/chat/completions',
      '/v1/models',
      '/v1/embeddings',
      '/v1/audio/transcriptions',
    ];
    final selectedLevel = levels[now.second % levels.length];
    final status =
        selectedLevel == 'ERROR' ? 500 : (selectedLevel == 'WARN' ? 429 : 200);

    setState(() {
      _logs.insert(0, <String, dynamic>{
        'id': now.microsecondsSinceEpoch.toString(),
        'level': selectedLevel,
        'message':
            'Snapshot captured for ${endpoints[now.second % endpoints.length]}',
        'timestamp': now,
        'module': selectedLevel == 'DEBUG' ? 'Cache' : 'API',
      });
      _apiCalls.insert(0, <String, dynamic>{
        'id': 'call_${now.microsecondsSinceEpoch}',
        'endpoint': endpoints[now.second % endpoints.length],
        'method': methods[now.second % methods.length],
        'status': status,
        'duration': 120 + (now.second * 7),
      });
      _stats = _buildStats(_apiCalls);
      if (_logs.length > 40) {
        _logs = _logs.take(40).toList();
      }
      if (_apiCalls.length > 25) {
        _apiCalls = _apiCalls.take(25).toList();
      }
    });
    await _saveData();
    if (mounted) {
      showSuccessSnackbar(context, 'Snapshot captured');
    }
  }

  List<Map<String, dynamic>> _generateSampleLogs() {
    return [
      {
        'id': '1',
        'level': 'INFO',
        'message': 'User session initialized',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
        'module': 'Auth'
      },
      {
        'id': '2',
        'level': 'DEBUG',
        'message': 'Cache lookup: KEY_user_prefs',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
        'module': 'Cache'
      },
      {
        'id': '3',
        'level': 'WARN',
        'message': 'Rate limit approaching: 80%',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
        'module': 'RateLimit'
      },
      {
        'id': '4',
        'level': 'INFO',
        'message': 'API request: /v1/chat/completions',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 6)),
        'module': 'API'
      },
      {
        'id': '5',
        'level': 'ERROR',
        'message': 'Connection timeout after 30s',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
        'module': 'Network'
      },
    ];
  }

  List<Map<String, dynamic>> _generateSampleApiCalls() {
    return [
      {
        'id': '1',
        'endpoint': '/v1/chat/completions',
        'method': 'POST',
        'status': 200,
        'duration': 245
      },
      {
        'id': '2',
        'endpoint': '/v1/models',
        'method': 'GET',
        'status': 200,
        'duration': 89
      },
      {
        'id': '3',
        'endpoint': '/v1/embeddings',
        'method': 'POST',
        'status': 200,
        'duration': 312
      },
    ];
  }

  void _clearLogs() {
    final previousLogs = List<Map<String, dynamic>>.from(_logs);
    setState(() {
      _logs.clear();
      _stats = _buildStats(_apiCalls);
    });
    HapticFeedback.mediumImpact();
    _saveData();
    showUndoSnackbar(context, 'Logs cleared', () {
      setState(() {
        _logs = previousLogs;
        _stats = _buildStats(_apiCalls);
      });
      _saveData();
    });
  }

  Color _getLogColor(String level) {
    switch (level) {
      case 'ERROR':
        return Colors.red;
      case 'WARN':
        return Colors.orange;
      case 'DEBUG':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    final levelFiltered = _selectedFilter == 'All'
        ? _logs
        : _logs.where((l) => l['level'] == _selectedFilter).toList();
    if (_searchQuery.isEmpty) {
      return levelFiltered;
    }
    return levelFiltered.where((log) {
      final query = _searchQuery.toLowerCase();
      return (log['message']?.toString().toLowerCase().contains(query) ??
              false) ||
          (log['module']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/gif/debug_area.gif',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          WaifuBackground(
            opacity: 0.07,
            tint: const Color(0xFF080C14),
            child: SafeArea(
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12)),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white60, size: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('AI DEBUG PANEL',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        Text(
                            '${_logs.length} logs • ${_apiCalls.length} API calls',
                            style: GoogleFonts.outfit(
                                color:
                                    Colors.purpleAccent.withValues(alpha: 0.7),
                                fontSize: 10)),
                      ])),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white60),
                    onPressed: _captureSnapshot,
                  ),
                ]),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14)),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Colors.purple, Colors.pink]),
                      borderRadius: BorderRadius.circular(14)),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: 'Logs', icon: Icon(Icons.article, size: 18)),
                    Tab(text: 'API', icon: Icon(Icons.api, size: 18)),
                    Tab(text: 'Stats', icon: Icon(Icons.analytics, size: 18)),
                    Tab(text: 'Config', icon: Icon(Icons.settings, size: 18)),
                  ],
                ),
              ),

              Expanded(
                child: Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLogsTab(),
                        _buildApiTab(),
                        _buildStatsTab(),
                        _buildConfigTab()
                      ],
                    ),
                    if (_isLoading)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                            color: V2Theme.primaryColor),
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: V2SearchBar(
          hintText: 'Search logs or modules...',
          onChanged: (value) => setState(() => _searchQuery = value.trim()),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
            children: ['All', 'INFO', 'DEBUG', 'WARN', 'ERROR'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (s) {
                setState(() => _selectedFilter = filter);
                _saveData();
              },
              selectedColor: _getLogColor(filter).withValues(alpha: 0.3),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12),
            ),
          );
        }).toList()),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_filteredLogs.length} entries',
                style: GoogleFonts.outfit(color: Colors.white54)),
            TextButton.icon(
                onPressed: _clearLogs,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear'),
                style: TextButton.styleFrom(foregroundColor: Colors.red)),
          ],
        ),
      ),
      Expanded(
        child: _filteredLogs.isEmpty
            ? const EmptyState(
                icon: Icons.search_off_outlined,
                title: 'No matching logs',
                subtitle: 'Try a different filter or capture a fresh snapshot.',
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.only(bottom: 100, left: 16, right: 16),
                itemCount: _filteredLogs.length,
                itemBuilder: (context, index) =>
                    _buildLogCard(index, _filteredLogs[index]),
              ),
      ),
    ]);
  }

  Widget _buildLogCard(int index, Map<String, dynamic> log) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - val)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Row(children: [
          Container(
              width: 8,
              height: 50,
              decoration: BoxDecoration(
                  color: _getLogColor(log['level'] as String),
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: _getLogColor(log['level'] as String)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(log['level'] as String,
                          style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: _getLogColor(log['level'] as String),
                              fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  Text(log['module'] as String,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.white54)),
                  const Spacer(),
                  Text(_formatTime(log['timestamp'] as DateTime),
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: Colors.white38)),
                ]),
                const SizedBox(height: 8),
                Text(log['message'] as String,
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
              ])),
        ]),
      ),
    );
  }

  Widget _buildApiTab() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      itemCount: _apiCalls.length,
      itemBuilder: (context, index) => _buildApiCard(index, _apiCalls[index]),
    );
  }

  Widget _buildApiCard(int index, Map<String, dynamic> call) {
    final status = call['status'] as int;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - val)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: (status < 300 ? Colors.green : Colors.red)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(status < 300 ? Icons.check_circle : Icons.error,
                  color: status < 300 ? Colors.green : Colors.red, size: 24)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: (call['method'] == 'GET'
                                  ? Colors.blue
                                  : Colors.green)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(call['method'] as String,
                          style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: call['method'] == 'GET'
                                  ? Colors.blue
                                  : Colors.green,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(call['endpoint'] as String,
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: Colors.white),
                          overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('$status',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: status < 300 ? Colors.green : Colors.red)),
                  const SizedBox(width: 8),
                  Text('•', style: GoogleFonts.outfit(color: Colors.white38)),
                  const SizedBox(width: 8),
                  Text('${call['duration']}ms',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.white54)),
                ]),
              ])),
        ]),
      ),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WaifuCommentary(
            mood: ((_stats['errors'] as int?) ?? 0) > 0
                ? 'motivated'
                : 'achievement',
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (_, val, child) => Opacity(
              opacity: val,
              child: Transform.translate(
                  offset: Offset(0, 12 * (1 - val)), child: child)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.purple.withValues(alpha: 0.3))),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.rocket_launch, color: Colors.purple),
                const SizedBox(width: 12),
                Text('Performance Overview',
                    style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ]),
              const SizedBox(height: 20),
              _buildMiniStat(
                  'Total Requests', '${_stats['total_requests']}', Icons.api),
              _buildMiniStat('Success Rate', '${_stats['success_rate']}%',
                  Icons.check_circle),
              _buildMiniStat('Avg Response', '${_stats['avg_response_time']}',
                  Icons.speed),
              _buildMiniStat(
                  'Tokens Used', '${_stats['tokens_used']}', Icons.token),
              _buildMiniStat(
                  'Cache Hit', '${_stats['cache_hit_rate']}%', Icons.cached),
              _buildMiniStat(
                  'Errors', '${_stats['errors']}', Icons.error_outline),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, color: Colors.purpleAccent, size: 20),
        const SizedBox(width: 12),
        Text(title,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildConfigTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (_, val, child) => Opacity(opacity: val, child: child),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('API Configuration',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _buildConfigRow('Model', 'gpt-4'),
              _buildConfigRow('Temperature', '0.7'),
              _buildConfigRow('Max Tokens', '2000'),
              _buildConfigRow('API Provider', 'OpenAI'),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white54)),
        Text(value,
            style: GoogleFonts.outfit(
                color: Colors.purpleAccent, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}



