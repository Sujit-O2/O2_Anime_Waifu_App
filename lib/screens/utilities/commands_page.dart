import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/main.dart';

class CommandsPage extends StatefulWidget {
  const CommandsPage({super.key});

  @override
  State<CommandsPage> createState() => _CommandsPageState();
}

class _CommandsPageState extends State<CommandsPage> {
  static const String _queryKey = 'commands_page_query_v2';
  static const String _expandedKey = 'commands_page_expanded_v2';

  String _query = '';
  Set<String> _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _restoreState();
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _query = prefs.getString(_queryKey) ?? '';
      _expanded = (prefs.getStringList(_expandedKey) ?? <String>[]).toSet();
    });
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queryKey, _query);
    await prefs.setStringList(_expandedKey, _expanded.toList()..sort());
  }

  void _toggleCategory(String title) {
    setState(() {
      if (_expanded.contains(title)) {
        _expanded.remove(title);
      } else {
        _expanded.add(title);
      }
    });
    _persistState();
  }

  void _copyCommand(String example) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: example));
    showSuccessSnackbar(context, 'Copied command example.');
  }

  List<_CmdCategory> get _filteredCategories {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _categories;
    }

    return _categories
        .map((category) {
          final filteredCommands = category.commands
              .where(
                (command) =>
                    command.label.toLowerCase().contains(query) ||
                    command.example.toLowerCase().contains(query) ||
                    category.title.toLowerCase().contains(query),
              )
              .toList();
          if (filteredCommands.isEmpty &&
              !category.title.toLowerCase().contains(query)) {
            return null;
          }
          return category.copyWith(
              commands: filteredCommands.isEmpty
                  ? category.commands
                  : filteredCommands);
        })
        .whereType<_CmdCategory>()
        .toList();
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChatHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCategories;
    final totalCommands = _categories.fold<int>(
        0, (sum, category) => sum + category.commands.length);
    final visibleCommands = filtered.fold<int>(
        0, (sum, category) => sum + category.commands.length);
    final mood = visibleCommands >= 20
        ? 'achievement'
        : visibleCommands >= 8
            ? 'motivated'
            : 'neutral';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: V2Theme.surfaceDark,
        body: WaifuBackground(
          opacity: 0.08,
          tint: V2Theme.surfaceDark,
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _restoreState,
              color: V2Theme.primaryColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              IconButton(
                                onPressed: _handleBack,
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white70,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Command Reference',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'Search everything your assistant can trigger.',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          WaifuCommentary(mood: mood),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: StatCard(
                                  title: 'Categories',
                                  value: '${_categories.length}',
                                  icon: Icons.dashboard_customize_rounded,
                                  color: V2Theme.primaryColor,
                                ),
                              ),
                              Expanded(
                                child: StatCard(
                                  title: 'Total Commands',
                                  value: '$totalCommands',
                                  icon: Icons.bolt_rounded,
                                  color: V2Theme.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: StatCard(
                                  title: 'Visible',
                                  value: '$visibleCommands',
                                  icon: Icons.visibility_rounded,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                              Expanded(
                                child: StatCard(
                                  title: 'Expanded',
                                  value: '${_expanded.length}',
                                  icon: Icons.unfold_more_rounded,
                                  color: Colors.lightGreenAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          V2SearchBar(
                            hintText: 'Search commands or categories...',
                            onChanged: (value) {
                              setState(() => _query = value);
                              _persistState();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching commands',
                        subtitle:
                            'Try a broader search and the command examples will show up here.',
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final category = filtered[index];
                        final isExpanded = _expanded.contains(category.title);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AnimatedEntry(
                            index: index,
                            child: GlassCard(
                              margin: EdgeInsets.zero,
                              glow: isExpanded,
                              child: Column(
                                children: <Widget>[
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () =>
                                        _toggleCategory(category.title),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: category.color
                                                  .withValues(alpha: 0.18),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              category.icon,
                                              color: category.color,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  category.title,
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${category.commands.length} examples',
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          AnimatedRotation(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            turns: isExpanded ? 0.5 : 0,
                                            child: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: category.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    child: isExpanded
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              top: 14,
                                            ),
                                            child: Column(
                                              children: category.commands
                                                  .map(
                                                    (command) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        bottom: 10,
                                                      ),
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                        onTap: () =>
                                                            _copyCommand(
                                                          command.example,
                                                        ),
                                                        child: Ink(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(14),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withValues(
                                                              alpha: 0.04,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              16,
                                                            ),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .white10,
                                                            ),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: <Widget>[
                                                              Text(
                                                                command.label,
                                                                style:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 6),
                                                              Text(
                                                                command.example,
                                                                style:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  color: Colors
                                                                      .white70,
                                                                  height: 1.4,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 10),
                                                              Text(
                                                                'Tap to copy',
                                                                style:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  color: category
                                                                      .color,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CmdCategory {
  const _CmdCategory({
    required this.icon,
    required this.color,
    required this.title,
    required this.commands,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<_CmdItem> commands;

  _CmdCategory copyWith({
    IconData? icon,
    Color? color,
    String? title,
    List<_CmdItem>? commands,
  }) {
    return _CmdCategory(
      icon: icon ?? this.icon,
      color: color ?? this.color,
      title: title ?? this.title,
      commands: commands ?? this.commands,
    );
  }
}

class _CmdItem {
  const _CmdItem({
    required this.label,
    required this.example,
  });

  final String label;
  final String example;
}

const List<_CmdCategory> _categories = <_CmdCategory>[
  _CmdCategory(
    icon: Icons.phone_rounded,
    color: Colors.lightGreenAccent,
    title: 'Calls and Communication',
    commands: <_CmdItem>[
      _CmdItem(label: 'Call someone', example: 'Call Mom'),
      _CmdItem(
        label: 'WhatsApp message',
        example: 'WhatsApp John saying I will be late',
      ),
      _CmdItem(label: 'Send email', example: 'Open Gmail'),
      _CmdItem(label: 'Share text', example: 'Share this Hello World'),
    ],
  ),
  _CmdCategory(
    icon: Icons.search_rounded,
    color: V2Theme.secondaryColor,
    title: 'Search and Web',
    commands: <_CmdItem>[
      _CmdItem(label: 'Google search', example: 'Search anime news'),
      _CmdItem(label: 'Open website', example: 'Open github.com'),
      _CmdItem(label: 'Open YouTube', example: 'Open YouTube'),
      _CmdItem(label: 'Directions', example: 'Directions to airport'),
    ],
  ),
  _CmdCategory(
    icon: Icons.alarm_rounded,
    color: Colors.orangeAccent,
    title: 'Alarms and Timers',
    commands: <_CmdItem>[
      _CmdItem(label: 'Set alarm', example: 'Set alarm at 7:30 AM'),
      _CmdItem(label: 'Relative alarm', example: 'Set alarm in 10 minutes'),
      _CmdItem(label: 'Set timer', example: 'Set timer for 5 minutes'),
      _CmdItem(label: 'Reminder', example: 'Remind me to drink water'),
      _CmdItem(
          label: 'Calendar event', example: 'Add meeting on Friday at 3 PM'),
    ],
  ),
  _CmdCategory(
    icon: Icons.settings_remote_rounded,
    color: Colors.amberAccent,
    title: 'Device Controls',
    commands: <_CmdItem>[
      _CmdItem(label: 'Flashlight', example: 'Turn on flashlight'),
      _CmdItem(label: 'Volume', example: 'Set volume to 80 percent'),
      _CmdItem(label: 'Battery status', example: 'What is my battery'),
      _CmdItem(label: 'Network status', example: 'Check my WiFi'),
      _CmdItem(label: 'Open camera', example: 'Open camera'),
    ],
  ),
  _CmdCategory(
    icon: Icons.bolt_rounded,
    color: V2Theme.primaryColor,
    title: 'Smart Features',
    commands: <_CmdItem>[
      _CmdItem(label: 'Live weather', example: 'What is the weather in Mumbai'),
      _CmdItem(label: 'News briefing', example: 'Latest headlines'),
      _CmdItem(label: 'Play music', example: 'Play Spotify'),
      _CmdItem(label: 'Daily summary', example: 'Give me my daily summary'),
      _CmdItem(label: 'Mood tracker', example: 'Log my mood'),
    ],
  ),
  _CmdCategory(
    icon: Icons.psychology_rounded,
    color: Colors.purpleAccent,
    title: 'Memory and Intelligence',
    commands: <_CmdItem>[
      _CmdItem(label: 'Save a fact', example: 'Remember my dog name is Bruno'),
      _CmdItem(
          label: 'Recall memory', example: 'What do you remember about me'),
      _CmdItem(label: 'Forget something', example: 'Forget that memory'),
      _CmdItem(label: 'Pin a message', example: 'Pin this reply'),
    ],
  ),
  _CmdCategory(
    icon: Icons.mic_rounded,
    color: Colors.tealAccent,
    title: 'Voice and Wake Word',
    commands: <_CmdItem>[
      _CmdItem(label: 'Wake word', example: 'Use the configured wake word'),
      _CmdItem(label: 'Auto listen', example: 'Turn on auto listen'),
      _CmdItem(label: 'Manual mic', example: 'Open mic'),
      _CmdItem(label: 'TTS speed', example: 'Set voice speed to 1.2x'),
    ],
  ),
  _CmdCategory(
    icon: Icons.build_circle_outlined,
    color: Colors.lightBlueAccent,
    title: 'Developer Tools',
    commands: <_CmdItem>[
      _CmdItem(label: 'Override API key', example: 'Open dev config'),
      _CmdItem(label: 'Switch model', example: 'Change the active model'),
      _CmdItem(label: 'Debug panel', example: 'Open debug panel'),
      _CmdItem(label: 'Simulate exception', example: 'Trigger debug exception'),
    ],
  ),
];



