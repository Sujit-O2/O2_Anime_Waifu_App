import 'dart:async';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/anime_media/manga_service.dart';
import 'package:anime_waifu/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MangaReaderPage extends StatefulWidget {
  const MangaReaderPage({
    super.key,
    required this.chapter,
    required this.mangaTitle,
  });

  final ChapterItem chapter;
  final String mangaTitle;

  @override
  State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage> {
  final PageController _pageController = PageController();
  final ScrollController _listController = ScrollController();

  List<String> _pages = <String>[];
  bool _loading = true;
  bool _barsVisible = true;
  bool _dataSaver = false;
  bool _rtlMode = false;
  bool _verticalMode = false;
  int _currentPage = 0;
  Timer? _barsTimer;

  String get _settingsKey => 'manga_reader_settings_${widget.chapter.id}';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _restoreSettings();
    _listController.addListener(_onVerticalScroll);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _barsTimer?.cancel();
    _pageController.dispose();
    _listController
      ..removeListener(_onVerticalScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    final fallbackVertical = MangaService.currentSource == MangaSource.manhwa;

    if (raw != null && raw.contains('|')) {
      final parts = raw.split('|');
      if (parts.length == 4) {
        _dataSaver = parts[0] == '1';
        _rtlMode = parts[1] == '1';
        _verticalMode = parts[2] == '1';
        _currentPage = int.tryParse(parts[3]) ?? 0;
      }
    } else {
      _verticalMode = fallbackVertical;
    }

    await _loadPages();
    _resetBarsTimer();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = [
      _dataSaver ? '1' : '0',
      _rtlMode ? '1' : '0',
      _verticalMode ? '1' : '0',
      '$_currentPage',
    ].join('|');
    await prefs.setString(_settingsKey, encoded);
  }

  Future<void> _loadPages() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    final result = await MangaService.getChapterPages(
      widget.chapter.id,
      dataSaver: _dataSaver,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _pages = result?.pageUrls ?? <String>[];
      _loading = false;
      if (_pages.isNotEmpty && _currentPage >= _pages.length) {
        _currentPage = _pages.length - 1;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pages.isEmpty) {
        return;
      }
      if (_verticalMode && _listController.hasClients) {
        _listController.jumpTo((_currentPage * 320).toDouble());
      } else if (!_verticalMode && _pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  void _resetBarsTimer() {
    _barsTimer?.cancel();
    _barsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _barsVisible = false);
      }
    });
  }

  void _toggleBars() {
    setState(() => _barsVisible = !_barsVisible);
    if (_barsVisible) {
      _resetBarsTimer();
    }
  }

  void _onVerticalScroll() {
    if (!_verticalMode || !_listController.hasClients || _pages.isEmpty) {
      return;
    }
    final index =
        (_listController.offset / 320).round().clamp(0, _pages.length - 1);
    if (index != _currentPage) {
      setState(() => _currentPage = index);
      _saveSettings();
    }
  }

  Future<void> _toggleDataSaver() async {
    setState(() {
      _dataSaver = !_dataSaver;
      _currentPage = 0;
    });
    await _saveSettings();
    await _loadPages();
  }

  Future<void> _toggleDirection() async {
    if (_verticalMode) {
      return;
    }
    setState(() {
      _rtlMode = !_rtlMode;
      _currentPage = 0;
    });
    await _saveSettings();
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  Future<void> _toggleVerticalMode() async {
    setState(() => _verticalMode = !_verticalMode);
    await _saveSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_verticalMode && _listController.hasClients) {
        _listController.jumpTo((_currentPage * 320).toDouble());
      } else if (!_verticalMode && _pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mood = _verticalMode ? 'motivated' : 'relaxed';
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleBars,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: V2Theme.primaryColor,
                          strokeWidth: 2.4,
                        ),
                      )
                    : _pages.isEmpty
                        ? _buildEmptyState()
                        : (_verticalMode
                            ? _buildVerticalReader()
                            : _buildHorizontalReader()),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              top: _barsVisible ? 0 : -180,
              left: 0,
              right: 0,
              child: _buildTopBar(mood),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              bottom: _barsVisible ? 0 : -180,
              left: 0,
              right: 0,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalReader() {
    return PageView.builder(
      controller: _pageController,
      reverse: _rtlMode,
      itemCount: _pages.length,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
        _saveSettings();
        _resetBarsTimer();
      },
      itemBuilder: (context, index) =>
          _buildPage(_pages[index], fitWidth: false),
    );
  }

  Widget _buildVerticalReader() {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: ListView.builder(
        controller: _listController,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: _pages.length,
        itemBuilder: (context, index) => _buildPage(
          _pages[index],
          fitWidth: true,
        ),
      ),
    );
  }

  Widget _buildPage(String url, {required bool fitWidth}) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: AppCachedImage(
          url: url,
          width: double.infinity,
          height: fitWidth ? 320 : double.infinity,
          fit: fitWidth ? BoxFit.fitWidth : BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Could not load chapter pages',
          subtitle:
              'Try reloading this chapter or switch the reader settings if the provider is struggling.',
          buttonText: 'Retry',
          onButtonPressed: () {
            setState(() {
              _currentPage = 0;
            });
            _loadPages();
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(String mood) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: DecoratedBox(
            decoration: V2Theme.glassDecoration.copyWith(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.mangaTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              widget.chapter.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleVerticalMode,
                        icon: Icon(
                          _verticalMode
                              ? Icons.view_stream_rounded
                              : Icons.view_carousel_rounded,
                          color: V2Theme.primaryColor,
                        ),
                        tooltip: _verticalMode
                            ? 'Switch to paged mode'
                            : 'Switch to vertical mode',
                      ),
                      if (!_verticalMode)
                        IconButton(
                          onPressed: _toggleDirection,
                          icon: Icon(
                            _rtlMode
                                ? Icons.format_textdirection_r_to_l_rounded
                                : Icons.format_textdirection_l_to_r_rounded,
                            color: Colors.white70,
                          ),
                          tooltip: 'Toggle reading direction',
                        ),
                      IconButton(
                        onPressed: _toggleDataSaver,
                        icon: Icon(
                          _dataSaver ? Icons.hd_rounded : Icons.hd_outlined,
                          color:
                              _dataSaver ? Colors.orangeAccent : Colors.white70,
                        ),
                        tooltip: 'Toggle data saver',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      _readerChip(
                        icon: Icons.layers_rounded,
                        label: '${_pages.length} pages',
                        color: V2Theme.secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      _readerChip(
                        icon: Icons.auto_stories_rounded,
                        label: _verticalMode ? 'Vertical' : 'Paged',
                        color: V2Theme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      _readerChip(
                        icon: Icons.favorite_outline_rounded,
                        label: mood == 'motivated' ? 'Flow' : 'Calm',
                        color: Colors.lightGreenAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_pages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: DecoratedBox(
            decoration: V2Theme.glassDecoration.copyWith(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _verticalMode
                              ? 'Approx page ${_currentPage + 1} of ${_pages.length}'
                              : 'Page ${_currentPage + 1} of ${_pages.length}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _dataSaver ? 'Data Saver On' : 'HD Mode',
                        style: GoogleFonts.outfit(
                          color: _dataSaver
                              ? Colors.orangeAccent
                              : V2Theme.secondaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!_verticalMode)
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        trackHeight: 4,
                        activeTrackColor: V2Theme.primaryColor,
                        inactiveTrackColor: Colors.white10,
                        thumbColor: V2Theme.primaryColor,
                      ),
                      child: Slider(
                        value: _currentPage.toDouble(),
                        min: 0,
                        max: (_pages.length - 1).toDouble(),
                        divisions: _pages.length <= 1 ? 1 : _pages.length - 1,
                        onChanged: (value) {
                          final page = value.round();
                          if (_pageController.hasClients) {
                            _pageController.jumpToPage(page);
                          }
                          setState(() => _currentPage = page);
                          _saveSettings();
                        },
                      ),
                    ),
                  if (!_verticalMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        IconButton(
                          onPressed: _currentPage > 0
                              ? () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                  )
                              : null,
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white70,
                            size: 32,
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            if (_rtlMode)
                              _readerChip(
                                icon: Icons.swap_horiz_rounded,
                                label: 'RTL',
                                color: Colors.purpleAccent,
                              ),
                            if (_rtlMode) const SizedBox(width: 8),
                            _readerChip(
                              icon: Icons.bookmark_outline_rounded,
                              label: 'Saved',
                              color: Colors.lightGreenAccent,
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _currentPage < _pages.length - 1
                              ? () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                  )
                              : null,
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white70,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _readerChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}



