import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/app_cached_image.dart';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/manga_service.dart';

class MangaReaderPage extends StatefulWidget {
  final ChapterItem chapter;
  final String mangaTitle;
  const MangaReaderPage({super.key, required this.chapter, required this.mangaTitle});
  @override
  State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage> {
  final PageController _pageCtrl = PageController();
  final ScrollController _listCtrl = ScrollController();
  
  List<String> _pages = [];
  bool _loading = true;
  bool _barsVisible = true;
  Timer? _barsTimer;
  int _currentPage = 0;
  
  bool _dataSaver = false;
  bool _rtlMode = false; // right-to-left reading
  bool _verticalMode = false; // webtoon reading

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadPages();
    _resetBarsTimer();
    
    // Auto-enable vertical mode if it's from the Manhwa scraper
    if (MangaService.currentSource == MangaSource.manhwa) {
      _verticalMode = true;
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageCtrl.dispose();
    _listCtrl.dispose();
    _barsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPages() async {
    final result = await MangaService.getChapterPages(widget.chapter.id, dataSaver: _dataSaver);
    if (mounted) {
      setState(() {
        _pages = result?.pageUrls ?? [];
        _loading = false;
      });
    }
  }

  void _toggleBars() {
    setState(() => _barsVisible = !_barsVisible);
    if (_barsVisible) _resetBarsTimer();
  }

  void _resetBarsTimer() {
    _barsTimer?.cancel();
    _barsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _barsVisible = false);
    });
  }

  void _toggleDataSaver() async {
    setState(() { _dataSaver = !_dataSaver; _loading = true; _pages = []; _currentPage = 0; });
    if (!_verticalMode && _pageCtrl.hasClients) _pageCtrl.jumpToPage(0);
    if (_verticalMode && _listCtrl.hasClients) _listCtrl.jumpTo(0);
    await _loadPages();
  }

  void _toggleDirection() {
    if (_verticalMode) return;
    setState(() => _rtlMode = !_rtlMode);
    if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(0);
    setState(() => _currentPage = 0);
  }
  
  void _toggleVerticalMode() {
    setState(() => _verticalMode = !_verticalMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleBars,
        child: Stack(
          children: [
            // Page viewer
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFBB52FF), strokeWidth: 2))
            else if (_pages.isEmpty)
              _buildError()
            else
              _verticalMode ? _buildVerticalReader() : _buildHorizontalReader(),

            // Top bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              top: _barsVisible ? 0 : -100,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),

            // Bottom bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              bottom: _barsVisible ? 0 : -100,
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
      controller: _pageCtrl,
      reverse: _rtlMode,
      itemCount: _pages.length,
      onPageChanged: (i) {
        setState(() => _currentPage = i);
        _resetBarsTimer();
      },
      itemBuilder: (ctx, i) => _buildPage(_pages[i]),
    );
  }

  Widget _buildVerticalReader() {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: ListView.builder(
        controller: _listCtrl,
        padding: EdgeInsets.zero,
        itemCount: _pages.length,
        itemBuilder: (ctx, i) {
           return AppCachedImage(url: _pages[i], width: double.infinity, height: 300, fit: BoxFit.fitWidth);
        },
      ),
    );
  }

  Widget _buildPage(String url) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Center(
        child: AppCachedImage(url: url, width: double.infinity, height: double.infinity, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 64),
        const SizedBox(height: 16),
        Text('Could not load chapter pages',
            style: GoogleFonts.outfit(color: Colors.white54)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            setState(() { _loading = true; _pages = []; });
            _loadPages();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
          child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
        ),
      ],
    ),
  );

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.mangaTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(widget.chapter.displayTitle,
                    style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11)),
              ]),
            ),
            IconButton(
              icon: Icon(_verticalMode ? Icons.swap_vert_rounded : Icons.swap_horiz_rounded,
                  color: const Color(0xFFBB52FF)),
              onPressed: _toggleVerticalMode,
              tooltip: _verticalMode ? 'Vertical scroll' : 'Horizontal Swipe',
            ),
            if (!_verticalMode)
              IconButton(
                icon: Icon(_rtlMode ? Icons.format_textdirection_r_to_l_rounded
                    : Icons.format_textdirection_l_to_r_rounded,
                    color: Colors.white70),
                onPressed: _toggleDirection,
                tooltip: _rtlMode ? 'Right to left' : 'Left to right',
              ),
            IconButton(
              icon: Icon(_dataSaver ? Icons.hd_rounded : Icons.hd_outlined,
                  color: _dataSaver ? Colors.white38 : const Color(0xFFBB52FF)),
              onPressed: _toggleDataSaver,
              tooltip: _dataSaver ? 'Data Saver ON' : 'Data Saver OFF',
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_pages.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(children: [
            // Page counter (Only valid for horizontal mode really, but we can show total)
            Text(
              _verticalMode ? 'Webtoon Mode - ${_pages.length} Pages' : '${_currentPage + 1} / ${_pages.length}',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Slider (Only for horizontal)
            if (!_verticalMode)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  trackHeight: 3,
                  activeTrackColor: const Color(0xFFBB52FF),
                  inactiveTrackColor: Colors.white12,
                  thumbColor: const Color(0xFFBB52FF),
                  overlayColor: const Color(0xFFBB52FF).withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _currentPage.toDouble(),
                  min: 0,
                  max: (_pages.length - 1).toDouble(),
                  divisions: _pages.length - 1 <= 0 ? 1 : _pages.length - 1,
                  onChanged: (val) {
                    final page = val.round();
                    if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(page);
                    setState(() => _currentPage = page);
                  },
                ),
              ),
            // Nav arrows
            if (!_verticalMode)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 32),
                    onPressed: _currentPage > 0
                        ? () => _pageCtrl.previousPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut)
                        : null,
                  ),
                  Row(
                    children: [
                      if (_dataSaver)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                          ),
                          child: Text('Data Saver',
                              style: GoogleFonts.outfit(color: Colors.orange, fontSize: 10)),
                        ),
                      if (_rtlMode) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBB52FF).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('RTL',
                              style: GoogleFonts.outfit(
                                  color: const Color(0xFFBB52FF), fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 32),
                    onPressed: _currentPage < _pages.length - 1
                        ? () => _pageCtrl.nextPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut)
                        : null,
                  ),
                ],
              ),
          ]),
        ),
      ),
    );
  }
}
