part of '../main.dart';

extension _MainNotificationsExtension on _ChatHomePageState {
// ── Page: Notification History ────────────────────────────────────────────
  Widget _buildNotificationsPage() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Text('NOTIFICATIONS',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                const Spacer(),
                if (_notifHistory.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep_outlined,
                        color: Colors.redAccent, size: 18),
                    label: const Text('Clear All',
                        style:
                            TextStyle(color: Colors.redAccent, fontSize: 12)),
                    onPressed: _clearNotifHistory,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: _buildNotificationsHero(),
          ),
          // ── Stats strip + Quick Actions ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _notifStatChip(
                  Icons.notifications_rounded,
                  '${_notifHistory.length}',
                  'Total',
                  Colors.pinkAccent,
                ),
                const SizedBox(width: 8),
                _notifStatChip(
                  Icons.today_rounded,
                  '${_notifHistory.where((m) {
                    try {
                      final ts = m['ts'] ?? '';
                      final d = DateTime.parse(ts);
                      final now = DateTime.now();
                      return d.year == now.year &&
                          d.month == now.month &&
                          d.day == now.day;
                    } catch (_) {
                      return false;
                    }
                  }).length}',
                  'Today',
                  Colors.cyanAccent,
                ),
                const SizedBox(width: 8),
                _notifStatChip(
                  Icons.mark_chat_unread_rounded,
                  '${_notifHistory.length}',
                  'Unread',
                  Colors.orangeAccent,
                ),
                const Spacer(),
                // Quick Test Notification button
                GestureDetector(
                  onTap: () {
                    final testMessages = [
                      'Miss me, honey? 💕',
                      'Darling, come back to me~',
                      'I\'m waiting for you~ 🌸',
                      'Don\'t forget about me, okay? 😤',
                    ];
                    final msg = testMessages[
                        DateTime.now().millisecond % testMessages.length];
                    updateState(() {
                      _notifHistory.insert(0, {
                        'msg': msg,
                        'ts': DateTime.now().toIso8601String(),
                      });
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(children: [
                          const Icon(Icons.notifications_active,
                              color: Colors.pinkAccent, size: 16),
                          const SizedBox(width: 8),
                          Text('Test notification added!',
                              style: GoogleFonts.outfit(fontSize: 12)),
                        ]),
                        backgroundColor: Colors.black87,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.pinkAccent.withOpacity(0.3),
                          Colors.purpleAccent.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: Colors.pinkAccent, size: 14),
                        const SizedBox(width: 4),
                        Text('Quick Test',
                            style: GoogleFonts.outfit(
                                color: Colors.pinkAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _notifHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/img/z12.jpg',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Icon(Icons.notifications_off_outlined,
                            color: Colors.white24, size: 48),
                        const SizedBox(height: 12),
                        Text('No notifications yet',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _notifHistory.length,
                    itemBuilder: (ctx, i) {
                      final item = _notifHistory[i];
                      final msg = item['msg'] ?? '';
                      final ts = item['ts'] ?? '';
                      DateTime? time;
                      try {
                        time = ts.isNotEmpty ? DateTime.parse(ts) : null;
                      } catch (_) {}
                      return Dismissible(
                        key: ValueKey(ts),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                        ),
                        onDismissed: (_) => _removeNotifAt(i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.favorite,
                                      color: Colors.pinkAccent, size: 14),
                                  const SizedBox(width: 6),
                                  Text('Zero Two',
                                      style: GoogleFonts.outfit(
                                          color: Colors.pinkAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  if (time != null)
                                    Text(
                                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white38, fontSize: 10),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(msg,
                                  style: GoogleFonts.outfit(
                                      color: Colors.white.withOpacity(0.87),
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _notifStatChip(
      IconData icon, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(count,
              style: GoogleFonts.outfit(
                  color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(width: 3),
          Text(label,
              style: GoogleFonts.outfit(
                  color: color.withOpacity(0.7), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildNotificationsHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/gif/notification.gif',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.32),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Check-ins',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Saved proactive and idle notifications',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// ── Page: Coming Soon ─────────────────────────────────────────────────────
  Widget _buildComingSoonPage() {
    final episodes = _buildZeroTwoEpisodes();
    return _ZeroTwoEpisodesPlayer(
      episodes: episodes,
      cloudName: _resolveCloudinaryCloudName(),
      prefix: _resolveCloudinaryPrefix(),
      usingExplicitIds: _resolveCloudinaryVideoIds().isNotEmpty,
      cloudinaryApiKey: _resolveCloudinaryApiKey(),
      cloudinaryApiSecret: _resolveCloudinaryApiSecret(),
      cloudinaryFolder: _resolveCloudinaryVideoFolder(),
    );
  }

  String _resolveCloudinaryCloudName() {
    final fromEnv = (dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '').trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'dqj7dm5h2';
  }

  String _resolveCloudinaryPrefix() {
    final fromEnv = (dotenv.env['CLOUDINARY_VIDEO_PREFIX'] ?? '').trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'zero_two/episode_';
  }

  String _resolveCloudinaryApiKey() {
    final fromEnv = (dotenv.env['CLOUDINARY_API_KEY'] ?? '').trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return '';
  }

  String _resolveCloudinaryApiSecret() {
    final fromEnv = (dotenv.env['CLOUDINARY_API_SECRET'] ?? '').trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return '';
  }

  String _resolveCloudinaryVideoFolder() {
    final envFolder = (dotenv.env['CLOUDINARY_VIDEO_FOLDER'] ??
            dotenv.env['CLOUDINARY_FOLDER'] ??
            '')
        .trim();
    if (envFolder.isNotEmpty) {
      return envFolder.endsWith('/') ? envFolder : '$envFolder/';
    }
    return 'darlingeps/o2/';
  }

  List<_EpisodeVideoItem> _buildZeroTwoEpisodes() {
    final cloudName = _resolveCloudinaryCloudName();
    final prefix = _resolveCloudinaryPrefix();
    final explicitUrls = _resolveCloudinaryVideoUrls();
    if (explicitUrls.isNotEmpty) {
      final items = <_EpisodeVideoItem>[];
      for (int i = 0; i < explicitUrls.length; i++) {
        final url = explicitUrls[i];
        items.add(
          _EpisodeVideoItem(
            title: 'Episode ${(i + 1).toString().padLeft(2, '0')}',
            publicId: 'direct_url_${i + 1}',
            urls: [url],
          ),
        );
      }
      return items;
    }

    final explicitIds = _resolveCloudinaryVideoIds();
    if (explicitIds.isNotEmpty) {
      return _buildEpisodesFromPublicIds(
        cloudName: cloudName,
        publicIds: explicitIds,
      );
    }

    final items = <_EpisodeVideoItem>[];
    for (int i = 1; i <= 24; i++) {
      final num = i.toString().padLeft(2, '0');
      final publicId = '$prefix$num';
      items.add(_EpisodeVideoItem(
        title: 'Episode $num',
        publicId: publicId,
        urls: _buildCloudinaryCandidateUrls(
          cloudName: cloudName,
          publicId: publicId,
        ),
      ));
    }
    return items;
  }

  List<_EpisodeVideoItem> _buildEpisodesFromPublicIds({
    required String cloudName,
    required List<String> publicIds,
  }) {
    final items = <_EpisodeVideoItem>[];
    for (int i = 0; i < publicIds.length; i++) {
      final publicId = publicIds[i];
      final episode = _extractEpisodeNumberFromId(publicId);
      final part = _extractPartNumberFromId(publicId);
      final baseTitle = episode != null
          ? 'Episode ${episode.toString().padLeft(2, '0')}'
          : 'Episode ${(i + 1).toString().padLeft(2, '0')}';
      final title = part != null ? '$baseTitle - Part $part' : baseTitle;
      items.add(_EpisodeVideoItem(
        title: title,
        publicId: publicId,
        urls: _buildCloudinaryCandidateUrls(
          cloudName: cloudName,
          publicId: publicId,
        ),
      ));
    }
    return items;
  }

  int? _extractEpisodeNumberFromId(String publicId) {
    final match = RegExp(r'[_-]E(\d{1,2})(?:[_-]|$)', caseSensitive: false)
            .firstMatch(publicId) ??
        RegExp(r'episode[_-]?(\d{1,2})', caseSensitive: false)
            .firstMatch(publicId);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  int? _extractPartNumberFromId(String publicId) {
    final patterns = <RegExp>[
      RegExp(r'[_\-\s]part[_\-\s]?(\d{1,2})(?:[_\-\s]|$)',
          caseSensitive: false),
      RegExp(r'[_\-\s]pt[_\-\s]?(\d{1,2})(?:[_\-\s]|$)', caseSensitive: false),
      RegExp(r'[_\-\s]p(\d{1,2})(?:[_\-\s]|$)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(publicId);
      if (match != null) {
        final value = int.tryParse(match.group(1) ?? '');
        if (value != null && value > 0) return value;
      }
    }
    return null;
  }

  List<String> _buildCloudinaryCandidateUrls({
    required String cloudName,
    required String publicId,
  }) {
    final encodedPublicId =
        publicId.split('/').map(Uri.encodeComponent).join('/');
    return [
      'https://res.cloudinary.com/$cloudName/video/upload/f_mp4,q_auto/$encodedPublicId.mp4',
      'https://res.cloudinary.com/$cloudName/video/upload/f_mp4,q_auto/$encodedPublicId',
      'https://res.cloudinary.com/$cloudName/video/upload/$encodedPublicId',
      'https://res.cloudinary.com/$cloudName/video/upload/$encodedPublicId.mkv',
    ];
  }

  List<String> _resolveCloudinaryVideoIds() {
    final raw = (dotenv.env['CLOUDINARY_VIDEO_PUBLIC_IDS'] ?? '').trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _resolveCloudinaryVideoUrls() {
    final raw = (dotenv.env['CLOUDINARY_VIDEO_URLS'] ?? '').trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class _EpisodeVideoItem {
  final String title;
  final String publicId;
  final List<String> urls;

  const _EpisodeVideoItem({
    required this.title,
    required this.publicId,
    required this.urls,
  });
}

class _ZeroTwoEpisodesPlayer extends StatefulWidget {
  final List<_EpisodeVideoItem> episodes;
  final String cloudName;
  final String prefix;
  final bool usingExplicitIds;
  final String cloudinaryApiKey;
  final String cloudinaryApiSecret;
  final String cloudinaryFolder;

  const _ZeroTwoEpisodesPlayer({
    required this.episodes,
    required this.cloudName,
    required this.prefix,
    required this.usingExplicitIds,
    required this.cloudinaryApiKey,
    required this.cloudinaryApiSecret,
    required this.cloudinaryFolder,
  });

  @override
  State<_ZeroTwoEpisodesPlayer> createState() => _ZeroTwoEpisodesPlayerState();
}

class _ZeroTwoEpisodesPlayerState extends State<_ZeroTwoEpisodesPlayer> {
  VideoPlayerController? _controller;
  VoidCallback? _controllerListener;
  List<_EpisodeVideoItem> _episodes = const [];
  int _selectedIndex = 0;
  bool _episodesLoading = true;
  String _sourceLabel = '';
  bool _loading = false;
  String? _error;
  String? _activeVideoUrl;
  bool _endHandled = false;
  bool _autoAdvancing = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _episodes = List<_EpisodeVideoItem>.from(widget.episodes);
    _sourceLabel = widget.usingExplicitIds
        ? 'CLOUDINARY_VIDEO_PUBLIC_IDS'
        : 'Prefix: ${widget.prefix}';
    unawaited(_prepareEpisodeSource());
  }

  @override
  void dispose() {
    _detachController(disposeController: true);
    super.dispose();
  }

  void _attachController(VideoPlayerController controller) {
    _detachController(disposeController: false);
    _controller = controller;
    _controllerListener = () {
      if (!mounted) return;
      _handleControllerTick();
      setState(() {});
    };
    controller.addListener(_controllerListener!);
  }

  void _detachController({required bool disposeController}) {
    final existing = _controller;
    final listener = _controllerListener;
    if (existing != null && listener != null) {
      existing.removeListener(listener);
    }
    _controllerListener = null;
    _controller = null;
    if (disposeController && existing != null) {
      unawaited(existing.dispose());
    }
  }

  bool _isAtEnd(VideoPlayerController controller) {
    if (!controller.value.isInitialized) return false;
    final duration = controller.value.duration;
    if (duration <= Duration.zero) return false;
    return controller.value.position >=
        duration - const Duration(milliseconds: 300);
  }

  int? _extractSeasonNumber(String publicId) {
    final match = RegExp(r'[_-]S(\d{1,2})[_-]', caseSensitive: false)
        .firstMatch(publicId);
    return match == null ? null : int.tryParse(match.group(1) ?? '');
  }

  int? _extractPartNumber(String publicId) {
    final patterns = <RegExp>[
      RegExp(r'[_\-\s]part[_\-\s]?(\d{1,2})(?:[_\-\s]|$)',
          caseSensitive: false),
      RegExp(r'[_\-\s]pt[_\-\s]?(\d{1,2})(?:[_\-\s]|$)', caseSensitive: false),
      RegExp(r'[_\-\s]p(\d{1,2})(?:[_\-\s]|$)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(publicId);
      if (match != null) {
        final value = int.tryParse(match.group(1) ?? '');
        if (value != null && value > 0) return value;
      }
    }
    return null;
  }

  String _buildDisplayTitle({
    required String publicId,
    required int fallbackIndex,
  }) {
    final season = _extractSeasonNumber(publicId);
    final episode = _extractEpisodeNumber(publicId);
    final part = _extractPartNumber(publicId);

    final base = (episode != null)
        ? 'Episode ${episode.toString().padLeft(2, '0')}'
        : 'Episode ${fallbackIndex.toString().padLeft(2, '0')}';
    final seasonPrefix = (season != null && season > 0)
        ? 'S${season.toString().padLeft(2, '0')} '
        : '';
    final partSuffix = (part != null) ? ' - Part $part' : '';
    return '$seasonPrefix$base$partSuffix'.trim();
  }

  void _handleControllerTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_loading || _episodesLoading) return;

    if (!_isAtEnd(controller)) {
      _endHandled = false;
      return;
    }

    if (_endHandled || _autoAdvancing) return;
    _endHandled = true;
    unawaited(_playNextEpisode(autoTriggered: true));
  }

  String _fmtTime(Duration value) {
    final safe = value < Duration.zero ? Duration.zero : value;
    final h = safe.inHours;
    final m = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final s = (safe.inSeconds % 60).toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$m:$s';
    }
    return '${safe.inMinutes.toString().padLeft(2, '0')}:$s';
  }

  Duration _safePosition(VideoPlayerController controller) {
    final p = controller.value.position;
    final d = controller.value.duration;
    if (d > Duration.zero && p > d) return d;
    if (p < Duration.zero) return Duration.zero;
    return p;
  }

  Future<void> _seekBy(Duration offset) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    var target = controller.value.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    await controller.seekTo(target);
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isAtEnd(controller)) {
      await controller.seekTo(Duration.zero);
      await controller.play();
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _prepareEpisodeSource() async {
    List<_EpisodeVideoItem> resolved = _episodes;
    var sourceLabel = _sourceLabel;
    String? sourceError;

    final canUseAdminApi = widget.cloudinaryApiKey.isNotEmpty &&
        widget.cloudinaryApiSecret.isNotEmpty;
    if (canUseAdminApi) {
      try {
        final fromAdmin = await _loadEpisodesFromCloudinaryAdmin();
        if (fromAdmin.isNotEmpty) {
          resolved = fromAdmin;
          sourceLabel = 'Cloudinary Admin (${widget.cloudinaryFolder})';
        } else {
          sourceError =
              'Cloudinary folder is empty: ${widget.cloudinaryFolder}';
        }
      } catch (e) {
        sourceError = 'Cloudinary API error: $e';
      }
    }

    if (!mounted) return;
    setState(() {
      _episodes = resolved;
      _sourceLabel = sourceLabel;
      _episodesLoading = false;
      _error = sourceError;
      _selectedIndex = 0;
    });

    if (_episodes.isNotEmpty) {
      await _loadEpisode(0);
    }
  }

  Future<List<_EpisodeVideoItem>> _loadEpisodesFromCloudinaryAdmin() async {
    final auth = base64Encode(
      utf8.encode('${widget.cloudinaryApiKey}:${widget.cloudinaryApiSecret}'),
    );
    final headers = <String, String>{'Authorization': 'Basic $auth'};
    final resources = <Map<String, dynamic>>[];
    String? nextCursor;
    final normalizedFolder = widget.cloudinaryFolder
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'^/+|/+$'), '');

    do {
      final uri = Uri.https(
        'api.cloudinary.com',
        '/v1_1/${widget.cloudName}/resources/video/upload',
        <String, String>{
          'max_results': '100',
          if (nextCursor != null && nextCursor.isNotEmpty)
            'next_cursor': nextCursor,
        },
      );
      final response = await http.get(uri, headers: headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) break;

      final page = decoded['resources'];
      if (page is List) {
        for (final item in page) {
          if (item is Map<String, dynamic>) {
            resources.add(item);
          }
        }
      }
      nextCursor = (decoded['next_cursor'] as String?)?.trim();
    } while (
        nextCursor != null && nextCursor.isNotEmpty && resources.length < 500);

    final episodes = <_EpisodeVideoItem>[];
    for (final resource in resources) {
      final publicId = (resource['public_id'] ?? '').toString().trim();
      if (publicId.isEmpty) continue;
      final assetFolder = (resource['asset_folder'] ?? '')
          .toString()
          .trim()
          .replaceAll('\\', '/');
      if (normalizedFolder.isNotEmpty &&
          assetFolder != normalizedFolder &&
          !assetFolder.startsWith('$normalizedFolder/') &&
          !assetFolder.endsWith('/$normalizedFolder') &&
          !publicId.startsWith('$normalizedFolder/')) {
        continue;
      }

      final secureUrl = (resource['secure_url'] ?? '').toString().trim();
      final title = _buildDisplayTitle(
        publicId: publicId,
        fallbackIndex: episodes.length + 1,
      );
      final urls = <String>[];
      urls.addAll(_buildCloudinaryCandidateUrls(
        cloudName: widget.cloudName,
        publicId: publicId,
      ));
      if (secureUrl.isNotEmpty) urls.add(secureUrl);
      final dedupedUrls = <String>[];
      for (final u in urls) {
        if (!dedupedUrls.contains(u)) dedupedUrls.add(u);
      }
      episodes.add(_EpisodeVideoItem(
        title: title,
        publicId: publicId,
        urls: dedupedUrls,
      ));
    }

    episodes.sort((a, b) {
      final aSeason = _extractSeasonNumber(a.publicId) ?? 1;
      final bSeason = _extractSeasonNumber(b.publicId) ?? 1;
      if (aSeason != bSeason) return aSeason.compareTo(bSeason);

      final aNum = _extractEpisodeNumber(a.publicId) ?? 9999;
      final bNum = _extractEpisodeNumber(b.publicId) ?? 9999;
      if (aNum != bNum) return aNum.compareTo(bNum);

      final aPart = _extractPartNumber(a.publicId) ?? 0;
      final bPart = _extractPartNumber(b.publicId) ?? 0;
      if (aPart != bPart) return aPart.compareTo(bPart);

      return a.publicId.compareTo(b.publicId);
    });
    return episodes;
  }

  int? _extractEpisodeNumber(String publicId) {
    final match = RegExp(r'[_-]E(\d{1,2})(?:[_-]|$)', caseSensitive: false)
            .firstMatch(publicId) ??
        RegExp(r'episode[_-]?(\d{1,2})', caseSensitive: false)
            .firstMatch(publicId);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  List<String> _buildCloudinaryCandidateUrls({
    required String cloudName,
    required String publicId,
  }) {
    final encodedPublicId =
        publicId.split('/').map(Uri.encodeComponent).join('/');
    return [
      'https://res.cloudinary.com/$cloudName/video/upload/f_mp4,q_auto/$encodedPublicId.mp4',
      'https://res.cloudinary.com/$cloudName/video/upload/f_mp4,q_auto/$encodedPublicId',
      'https://res.cloudinary.com/$cloudName/video/upload/$encodedPublicId',
      'https://res.cloudinary.com/$cloudName/video/upload/$encodedPublicId.mkv',
    ];
  }

  Future<void> _loadEpisode(int index, {bool autoplay = true}) async {
    if (index < 0 || index >= _episodes.length) return;
    final generation = ++_loadGeneration;

    setState(() {
      _selectedIndex = index;
      _loading = true;
      _error = null;
    });

    final previous = _controller;
    _detachController(disposeController: false);
    _activeVideoUrl = null;
    await previous?.dispose();

    final item = _episodes[index];
    VideoPlayerController? workingController;
    String? workingUrl;
    for (final url in item.urls) {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      try {
        await c.initialize();
        workingController = c;
        workingUrl = url;
        break;
      } catch (_) {
        await c.dispose();
      }
    }
    if (!mounted || generation != _loadGeneration) {
      await workingController?.dispose();
      return;
    }
    if (workingController == null) {
      setState(() {
        _loading = false;
        _error =
            'Could not load ${item.title}. Check Cloudinary IDs or folder access.';
      });
      return;
    }

    await workingController.setVolume(1.0);
    await workingController.setLooping(false);
    if (autoplay) {
      await workingController.play();
    } else {
      await workingController.pause();
    }
    _endHandled = false;
    _attachController(workingController);
    setState(() {
      _activeVideoUrl = workingUrl;
      _loading = false;
    });
  }

  Future<void> _playPreviousEpisode() async {
    final prev = _selectedIndex - 1;
    if (prev < 0) return;
    await _loadEpisode(prev, autoplay: true);
  }

  Future<void> _playNextEpisode({bool autoTriggered = false}) async {
    if (_episodes.isEmpty) return;
    final next = _selectedIndex + 1;
    if (next >= _episodes.length) return;

    if (autoTriggered) {
      if (_autoAdvancing) return;
      _autoAdvancing = true;
    }
    try {
      await _loadEpisode(next, autoplay: true);
    } finally {
      if (autoTriggered) {
        _autoAdvancing = false;
      }
    }
  }

  Future<void> _openLandscapePlayer() async {
    if (_selectedIndex < 0 || _selectedIndex >= _episodes.length) return;
    final navigator = Navigator.of(context);
    final item = _episodes[_selectedIndex];
    final controller = _controller;
    final activeUrl =
        _activeVideoUrl ?? (item.urls.isNotEmpty ? item.urls.first : null);
    if (activeUrl == null || activeUrl.isEmpty) return;

    final startAt = (controller != null && controller.value.isInitialized)
        ? controller.value.position
        : Duration.zero;
    final wasPlaying = controller?.value.isPlaying ?? true;
    await controller?.pause();

    Future<void> openFullscreen(int index, Duration startPosition) async {
      if (index < 0 || index >= _episodes.length) return;
      final currentItem = _episodes[index];
      final u = currentItem.urls.isNotEmpty ? currentItem.urls.first : null;
      if (u == null || u.isEmpty) return;

      final returnedPosition =
          await navigator.pushReplacement<Duration, Duration>(
        MaterialPageRoute(
          builder: (_) => _LandscapeEpisodePlayerPage(
            title: currentItem.title,
            videoUrl: u,
            startAt: startPosition,
            onNext: index < _episodes.length - 1
                ? () {
                    _loadEpisode(index + 1, autoplay: true);
                    openFullscreen(index + 1, Duration.zero);
                  }
                : null,
            onPrevious: index > 0
                ? () {
                    _loadEpisode(index - 1, autoplay: true);
                    openFullscreen(index - 1, Duration.zero);
                  }
                : null,
          ),
        ),
      );

      if (!mounted ||
          _controller == null ||
          !_controller!.value.isInitialized) {
        return;
      }
      if (returnedPosition != null) {
        await _controller!.seekTo(returnedPosition);
      }
      if (wasPlaying) {
        await _controller!.play();
      }
      setState(() {});
    }

    final returnedPosition = await navigator.push<Duration>(
      MaterialPageRoute(
        builder: (_) => _LandscapeEpisodePlayerPage(
          title: item.title,
          videoUrl: activeUrl,
          startAt: startAt,
          onNext: _selectedIndex < _episodes.length - 1
              ? () {
                  _loadEpisode(_selectedIndex + 1, autoplay: true);
                  openFullscreen(_selectedIndex + 1, Duration.zero);
                }
              : null,
          onPrevious: _selectedIndex > 0
              ? () {
                  _loadEpisode(_selectedIndex - 1, autoplay: true);
                  openFullscreen(_selectedIndex - 1, Duration.zero);
                }
              : null,
        ),
      ),
    );

    if (!mounted || controller == null || !controller.value.isInitialized) {
      return;
    }
    if (returnedPosition != null) {
      await controller.seekTo(returnedPosition);
    }
    if (wasPlaying) {
      await controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final hasVideo = controller != null && controller.value.isInitialized;
    final isPlaying = hasVideo && controller.value.isPlaying;
    final isEnded = hasVideo ? _isAtEnd(controller) : false;
    final position = hasVideo ? _safePosition(controller) : Duration.zero;
    final duration =
        hasVideo ? controller.value.duration : const Duration(minutes: 24);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Row(
              children: [
                Text(
                  'ZERO TWO EPISODES',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_episodes.length} videos',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                color: Colors.black.withOpacity(0.45),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (controller != null && controller.value.isInitialized)
                        VideoPlayer(controller)
                      else
                        Image.asset(
                          'assets/img/bll.jpg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      if (_episodesLoading || _loading)
                        const CircularProgressIndicator(
                            color: Colors.redAccent),
                      if (_error != null && !_loading && !_episodesLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: hasVideo ? _togglePlayPause : null,
                  icon: Icon(
                    isEnded
                        ? Icons.replay_circle_filled
                        : (isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                IconButton(
                  onPressed: hasVideo
                      ? () => _seekBy(const Duration(seconds: -10))
                      : null,
                  icon: const Icon(Icons.replay_10, color: Colors.white70),
                ),
                IconButton(
                  onPressed: hasVideo && _selectedIndex > 0
                      ? _playPreviousEpisode
                      : null,
                  icon: const Icon(Icons.skip_previous_rounded,
                      color: Colors.white70),
                ),
                IconButton(
                  onPressed: hasVideo
                      ? () => _seekBy(const Duration(seconds: 10))
                      : null,
                  icon: const Icon(Icons.forward_10, color: Colors.white70),
                ),
                IconButton(
                  onPressed: hasVideo && _selectedIndex < _episodes.length - 1
                      ? () => _playNextEpisode(autoTriggered: false)
                      : null,
                  icon: const Icon(Icons.skip_next_rounded,
                      color: Colors.white70),
                ),
                IconButton(
                  onPressed: hasVideo ? _openLandscapePlayer : null,
                  icon: const Icon(Icons.fullscreen, color: Colors.white70),
                ),
                Expanded(
                  child: Text(
                    _episodes.isEmpty
                        ? 'No episodes'
                        : _episodes[_selectedIndex].title,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (controller != null && controller.value.isInitialized)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmtTime(position),
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3)),
                        ),
                        child: Text(
                          _controller?.value.playbackSpeed == 1.0
                              ? "1×"
                              : "${_controller?.value.playbackSpeed.toStringAsFixed(2)}×",
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '-${_fmtTime(duration - position)}  / ${_fmtTime(duration)}',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 16),
                      activeTrackColor: Theme.of(context).primaryColor,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.white,
                      overlayColor:
                          Theme.of(context).primaryColor.withOpacity(0.2),
                      valueIndicatorShape:
                          const PaddleSliderValueIndicatorShape(),
                      valueIndicatorColor: Theme.of(context).primaryColor,
                      valueIndicatorTextStyle: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                      showValueIndicator: ShowValueIndicator.onlyForDiscrete,
                    ),
                    child: Slider(
                      value: duration.inMilliseconds > 0
                          ? (position.inMilliseconds / duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0.0,
                      onChanged: (v) {
                        final target = Duration(
                            milliseconds:
                                (v * duration.inMilliseconds).round());
                        controller.seekTo(target);
                      },
                    ),
                  ),
                  const SizedBox(height: 0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: duration.inMilliseconds > 0 &&
                              controller.value.buffered.isNotEmpty
                          ? (controller.value.buffered.last.end.inMilliseconds /
                                  duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      color: Colors.white24,
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Cloud: ${widget.cloudName} | Source: $_sourceLabel',
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _episodes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _episodes[index];
                final selected = _selectedIndex == index;
                return InkWell(
                  onTap: () => _loadEpisode(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).primaryColor.withOpacity(0.16)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).primaryColor.withOpacity(0.45)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.play_circle_fill_rounded
                              : Icons.play_circle_outline_rounded,
                          color: selected
                              ? Theme.of(context).primaryColor
                              : Colors.white54,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          item.publicId,
                          style: GoogleFonts.outfit(
                            color: Colors.white30,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LandscapeEpisodePlayerPage extends StatefulWidget {
  final String title;
  final String videoUrl;
  final Duration startAt;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const _LandscapeEpisodePlayerPage({
    required this.title,
    required this.videoUrl,
    required this.startAt,
    this.onNext,
    this.onPrevious,
  });

  @override
  State<_LandscapeEpisodePlayerPage> createState() =>
      _LandscapeEpisodePlayerPageState();
}

class _LandscapeEpisodePlayerPageState
    extends State<_LandscapeEpisodePlayerPage> {
  VideoPlayerController? _controller;
  VoidCallback? _controllerListener;
  bool _loading = true;
  String? _error;
  Timer? _controlsHideTimer;
  bool _showControls = true;
  bool _isScrubbing = false;
  double _volumeLevel = 1.0;
  double _brightnessLevel = 1.0;
  static const Duration _controlsAutoHideDelay = Duration(seconds: 2);

  double _playbackSpeed = 1.0;
  bool _isLocked = false;

  // Gesture State
  double _panStartX = 0.0;
  double _panStartY = 0.0;
  bool _isPanning = false;
  bool _isVerticalPan = false;
  bool _isHorizontalPan = false;
  double _panStartVolume = 1.0;
  double _panStartBrightness = 1.0;
  Duration _panStartPosition = Duration.zero;

  // Visual Feedback
  IconData? _feedbackIcon;
  String? _feedbackText;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _enterLandscapeMode();
    unawaited(_initPlayer());
  }

  Future<void> _enterLandscapeMode() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restorePortraitMode() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _initPlayer() async {
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(_volumeLevel);
      if (widget.startAt > Duration.zero &&
          widget.startAt < controller.value.duration) {
        await controller.seekTo(widget.startAt);
      }
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _attachController(controller);
      setState(() {
        _loading = false;
      });
      _showControlsTemporarily();
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not play this video in landscape.';
      });
      _cancelControlsHideTimer();
    }
  }

  Future<void> _close() async {
    _cancelControlsHideTimer();
    final pos = _controller?.value.position ?? widget.startAt;
    await _restorePortraitMode();
    if (!mounted) return;
    Navigator.of(context).pop(pos);
  }

  @override
  void dispose() {
    _cancelControlsHideTimer();
    _cancelFeedbackTimer();
    _detachController(disposeController: true);
    unawaited(_restorePortraitMode());
    super.dispose();
  }

  void _cancelFeedbackTimer() {
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
  }

  void _showFeedback(IconData icon, String text) {
    if (!mounted) return;
    setState(() {
      _feedbackIcon = icon;
      _feedbackText = text;
    });
    _cancelFeedbackTimer();
    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _feedbackIcon = null;
        _feedbackText = null;
      });
    });
  }

  void _cancelControlsHideTimer() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = null;
  }

  void _showControlsTemporarily() {
    if (!mounted) return;
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }
    _cancelControlsHideTimer();
    if (_loading || _error != null || _isScrubbing) return;
    _controlsHideTimer = Timer(_controlsAutoHideDelay, () {
      if (!mounted || _loading || _error != null || _isScrubbing) return;
      setState(() {
        _showControls = false;
      });
    });
  }

  void _toggleControlsVisibility() {
    if (_showControls) {
      _cancelControlsHideTimer();
      setState(() {
        _showControls = false;
      });
    } else {
      _showControlsTemporarily();
    }
  }

  void _onScrubStart() {
    _isScrubbing = true;
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }
    _cancelControlsHideTimer();
  }

  void _onScrubEnd() {
    _isScrubbing = false;
    _showControlsTemporarily();
  }

  void _attachController(VideoPlayerController controller) {
    _detachController(disposeController: false);
    _controller = controller;
    _controllerListener = () {
      if (!mounted) return;
      setState(() {});

      // Auto-play next episode on completion
      if (_controller != null && _controller!.value.isInitialized) {
        if (_controller!.value.position >= _controller!.value.duration &&
            _controller!.value.duration > Duration.zero) {
          if (widget.onNext != null) {
            widget.onNext!();
          }
        }
      }
    };
    controller.addListener(_controllerListener!);
  }

  void _detachController({required bool disposeController}) {
    final existing = _controller;
    final listener = _controllerListener;
    if (existing != null && listener != null) {
      existing.removeListener(listener);
    }
    _controller = null;
    _controllerListener = null;
    if (disposeController && existing != null) {
      unawaited(existing.dispose());
    }
  }

  bool _isAtEnd(VideoPlayerController controller) {
    if (!controller.value.isInitialized) return false;
    final duration = controller.value.duration;
    if (duration <= Duration.zero) return false;
    return controller.value.position >=
        duration - const Duration(milliseconds: 300);
  }

  String _fmtTime(Duration value) {
    final safe = value < Duration.zero ? Duration.zero : value;
    final h = safe.inHours;
    final m = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final s = (safe.inSeconds % 60).toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$m:$s';
    }
    return '${safe.inMinutes.toString().padLeft(2, '0')}:$s';
  }

  Duration _safePosition(VideoPlayerController controller) {
    final p = controller.value.position;
    final d = controller.value.duration;
    if (d > Duration.zero && p > d) return d;
    if (p < Duration.zero) return Duration.zero;
    return p;
  }

  Future<void> _seekBy(Duration offset) async {
    _showControlsTemporarily();
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    var target = controller.value.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    await controller.seekTo(target);
  }

  Future<void> _togglePlayPause() async {
    _showControlsTemporarily();
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isAtEnd(controller)) {
      await controller.seekTo(Duration.zero);
      await controller.play();
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _setVolume(double value) async {
    final next = value.clamp(0.0, 1.0).toDouble();
    if (mounted) {
      setState(() {
        _volumeLevel = next;
      });
    } else {
      _volumeLevel = next;
    }
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.setVolume(next);
    }
    _showControlsTemporarily();
  }

  void _setBrightness(double value) {
    final next = value.clamp(0.10, 1.0).toDouble();
    if (mounted) {
      setState(() {
        _brightnessLevel = next;
      });
    } else {
      _brightnessLevel = next;
    }
    _showControlsTemporarily();
  }

  Future<void> _cyclePlaybackSpeed() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    double nextSpeed = 1.0;
    if (_playbackSpeed == 1.0) {
      nextSpeed = 1.25;
    } else if (_playbackSpeed == 1.25) {
      nextSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      nextSpeed = 2.0;
    } else {
      nextSpeed = 1.0;
    }

    await controller.setPlaybackSpeed(nextSpeed);
    setState(() {
      _playbackSpeed = nextSpeed;
    });
    _showControlsTemporarily();
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _showControls = false;
      } else {
        _showControlsTemporarily();
      }
    });
  }

  void _handlePanStart(DragStartDetails details) {
    _panStartX = details.globalPosition.dx;
    _panStartY = details.globalPosition.dy;
    _isPanning = true;
    _isVerticalPan = false;
    _isHorizontalPan = false;

    _panStartVolume = _volumeLevel;
    _panStartBrightness = _brightnessLevel;
    if (_controller != null && _controller!.value.isInitialized) {
      _panStartPosition = _controller!.value.position;
    } else {
      _panStartPosition = Duration.zero;
    }
  }

  void _handlePanUpdate(
      DragUpdateDetails details, double screenWidth, double screenHeight) {
    if (!_isPanning) return;

    final dx = details.globalPosition.dx - _panStartX;
    final dy = details.globalPosition.dy - _panStartY;

    if (!_isVerticalPan && !_isHorizontalPan) {
      if (dx.abs() > 10) {
        _isHorizontalPan = true;
      } else if (dy.abs() > 10) {
        _isVerticalPan = true;
      } else {
        return;
      }
    }

    if (_isHorizontalPan) {
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) return;

      // Horizontal swipe to seek. Swipe across half the screen = 60 seconds
      final seekRatio = dx / (screenWidth / 2);
      final offsetMs = (seekRatio * 60000).toInt();
      final target = _panStartPosition + Duration(milliseconds: offsetMs);
      final clampedTarget = Duration(
        milliseconds: target.inMilliseconds
            .clamp(0, controller.value.duration.inMilliseconds),
      );

      controller.seekTo(clampedTarget);

      final sign = dx > 0 ? '+' : '';
      final secondsStr = (offsetMs / 1000).toStringAsFixed(0);
      _showFeedback(
          dx > 0 ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
          '[$sign${secondsStr}s] ${_fmtTime(clampedTarget)}');
    } else if (_isVerticalPan) {
      // Swipe up reduces Y, so we subtract dy for positive increase
      final delta = -(dy / (screenHeight / 2));

      if (_panStartX > screenWidth / 2) {
        // Right side: Volume
        final newVolume = (_panStartVolume + delta).clamp(0.0, 1.0);
        _setVolume(newVolume);

        final pct = (newVolume * 100).toInt();
        final icon = newVolume == 0
            ? Icons.volume_off
            : (newVolume > 0.5 ? Icons.volume_up : Icons.volume_down);
        _showFeedback(icon, 'Vol $pct%');
      } else {
        // Left side: Brightness
        final newBrightness = (_panStartBrightness + delta).clamp(0.1, 1.0);
        _setBrightness(newBrightness);

        final pct = (newBrightness * 100).toInt();
        _showFeedback(Icons.brightness_6, 'Bright $pct%');
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _isPanning = false;
    _isVerticalPan = false;
    _isHorizontalPan = false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final hasVideo = controller != null && controller.value.isInitialized;
    final isPlaying = hasVideo && controller.value.isPlaying;
    final isEnded = hasVideo ? _isAtEnd(controller) : false;
    final position = hasVideo ? _safePosition(controller) : Duration.zero;
    final duration =
        hasVideo ? controller.value.duration : const Duration(minutes: 24);
    return WillPopScope(
      onWillPop: () async {
        await _close();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: (controller != null && controller.value.isInitialized)
                  ? FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : Container(color: Colors.black),
            ),
            if (_brightnessLevel < 1.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black
                        .withOpacity((1.0 - _brightnessLevel) * 0.72),
                  ),
                ),
              ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isLocked
                    ? _showControlsTemporarily
                    : _toggleControlsVisibility,
                onHorizontalDragStart: _isLocked ? null : _handlePanStart,
                onHorizontalDragUpdate: _isLocked
                    ? null
                    : (d) => _handlePanUpdate(
                        d,
                        MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height),
                onHorizontalDragEnd: _isLocked ? null : _handlePanEnd,
                onVerticalDragStart: _isLocked ? null : _handlePanStart,
                onVerticalDragUpdate: _isLocked
                    ? null
                    : (d) => _handlePanUpdate(
                        d,
                        MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height),
                onVerticalDragEnd: _isLocked ? null : _handlePanEnd,
                child: const SizedBox.expand(),
              ),
            ),
            if (_feedbackIcon != null && _feedbackText != null)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_feedbackIcon, color: Colors.white, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        _feedbackText!,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: Colors.redAccent),
              ),
            if (_error != null && !_loading)
              Center(
                child: Text(
                  _error!,
                  style:
                      GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_showControls,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Stack(
                    children: [
                      if (!_isLocked)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _close,
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.title,
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasVideo && !_isLocked)
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 18,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              color: Colors.black.withOpacity(0.45),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Listener(
                                    onPointerDown: (_) => _onScrubStart(),
                                    onPointerUp: (_) => _onScrubEnd(),
                                    onPointerCancel: (_) => _onScrubEnd(),
                                    child: VideoProgressIndicator(
                                      controller,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: Colors.redAccent,
                                        bufferedColor: Colors.white30,
                                        backgroundColor: Colors.white12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: _toggleLock,
                                        icon: const Icon(
                                            Icons.lock_open_rounded,
                                            color: Colors.white70,
                                            size: 22),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: widget.onPrevious,
                                        icon: Icon(Icons.skip_previous_rounded,
                                            color: widget.onPrevious != null
                                                ? Colors.white
                                                : Colors.white24,
                                            size: 28),
                                      ),
                                      IconButton(
                                        onPressed: () => _seekBy(
                                            const Duration(seconds: -10)),
                                        icon: const Icon(Icons.replay_10,
                                            color: Colors.white),
                                      ),
                                      IconButton(
                                        onPressed: _togglePlayPause,
                                        icon: Icon(
                                          isEnded
                                              ? Icons.replay_circle_filled
                                              : (isPlaying
                                                  ? Icons.pause_circle_filled
                                                  : Icons.play_circle_fill),
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _seekBy(
                                            const Duration(seconds: 10)),
                                        icon: const Icon(Icons.forward_10,
                                            color: Colors.white),
                                      ),
                                      IconButton(
                                        onPressed: widget.onNext,
                                        icon: Icon(Icons.skip_next_rounded,
                                            color: widget.onNext != null
                                                ? Colors.white
                                                : Colors.white24,
                                            size: 28),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: _cyclePlaybackSpeed,
                                        style: TextButton.styleFrom(
                                          minimumSize: Size.zero,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                        ),
                                        child: Text(
                                          '${_playbackSpeed}x',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_fmtTime(position)} / ${_fmtTime(duration)}',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (hasVideo && _isLocked)
                        Positioned(
                          bottom: 30,
                          right: 40,
                          child: InkWell(
                            onTap: _toggleLock,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white30),
                              ),
                              child: const Icon(Icons.lock_rounded,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
