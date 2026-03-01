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
          Expanded(
            child: _notifHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'z12.jpg',
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

  Widget _buildNotificationsHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'bll.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
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
    return 'o2/';
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
      items.add(_EpisodeVideoItem(
        title: 'Episode ${(i + 1).toString().padLeft(2, '0')}',
        publicId: publicId,
        urls: _buildCloudinaryCandidateUrls(
          cloudName: cloudName,
          publicId: publicId,
        ),
      ));
    }
    return items;
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
  List<_EpisodeVideoItem> _episodes = const [];
  int _selectedIndex = 0;
  bool _episodesLoading = true;
  String _sourceLabel = '';
  bool _loading = false;
  String? _error;
  String? _activeVideoUrl;

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
    _controller?.dispose();
    super.dispose();
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
          !publicId.startsWith('$normalizedFolder/')) {
        continue;
      }

      final secureUrl = (resource['secure_url'] ?? '').toString().trim();
      final episodeNumber = _extractEpisodeNumber(publicId);
      final title = episodeNumber != null
          ? 'Episode ${episodeNumber.toString().padLeft(2, '0')}'
          : 'Episode ${(episodes.length + 1).toString().padLeft(2, '0')}';
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
      final aNum = _extractEpisodeNumber(a.publicId) ?? 9999;
      final bNum = _extractEpisodeNumber(b.publicId) ?? 9999;
      if (aNum != bNum) return aNum.compareTo(bNum);
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

  Future<void> _loadEpisode(int index) async {
    if (index < 0 || index >= _episodes.length) return;
    setState(() {
      _selectedIndex = index;
      _loading = true;
      _error = null;
    });

    final previous = _controller;
    _controller = null;
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
    if (!mounted) {
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
    workingController.setVolume(1.0);
    workingController.setLooping(false);
    await workingController.play();
    setState(() {
      _controller = workingController;
      _activeVideoUrl = workingUrl;
      _loading = false;
    });
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

    final returnedPosition = await navigator.push<Duration>(
      MaterialPageRoute(
        builder: (_) => _LandscapeEpisodePlayerPage(
          title: item.title,
          videoUrl: activeUrl,
          startAt: startAt,
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
                          'bll.jpg',
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
                  onPressed:
                      (controller != null && controller.value.isInitialized)
                          ? () async {
                              if (controller.value.isPlaying) {
                                await controller.pause();
                              } else {
                                await controller.play();
                              }
                              if (mounted) setState(() {});
                            }
                          : null,
                  icon: Icon(
                    (controller != null && controller.value.isPlaying)
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                IconButton(
                  onPressed:
                      (controller != null && controller.value.isInitialized)
                          ? () => controller.seekTo(Duration.zero)
                          : null,
                  icon: const Icon(Icons.replay, color: Colors.white70),
                ),
                IconButton(
                  onPressed:
                      (controller != null && controller.value.isInitialized)
                          ? _openLandscapePlayer
                          : null,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).primaryColor,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
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

  const _LandscapeEpisodePlayerPage({
    required this.title,
    required this.videoUrl,
    required this.startAt,
  });

  @override
  State<_LandscapeEpisodePlayerPage> createState() =>
      _LandscapeEpisodePlayerPageState();
}

class _LandscapeEpisodePlayerPageState
    extends State<_LandscapeEpisodePlayerPage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

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
      await controller.setVolume(1.0);
      if (widget.startAt > Duration.zero &&
          widget.startAt < controller.value.duration) {
        await controller.seekTo(widget.startAt);
      }
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not play this video in landscape.';
      });
    }
  }

  Future<void> _close() async {
    final pos = _controller?.value.position ?? widget.startAt;
    await _restorePortraitMode();
    if (!mounted) return;
    Navigator.of(context).pop(pos);
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    unawaited(_restorePortraitMode());
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
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
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _close,
                    icon: const Icon(Icons.close, color: Colors.white),
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
            if (controller != null && controller.value.isInitialized)
              Positioned(
                left: 14,
                right: 14,
                bottom: 18,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: Colors.black.withOpacity(0.45),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.redAccent,
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                if (controller.value.isPlaying) {
                                  await controller.pause();
                                } else {
                                  await controller.play();
                                }
                                if (mounted) setState(() {});
                              },
                              icon: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            IconButton(
                              onPressed: () => controller.seekTo(Duration.zero),
                              icon:
                                  const Icon(Icons.replay, color: Colors.white),
                            ),
                            const Spacer(),
                            Text(
                              '${controller.value.position.inMinutes.toString().padLeft(2, '0')}:${(controller.value.position.inSeconds % 60).toString().padLeft(2, '0')}',
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
          ],
        ),
      ),
    );
  }
}
