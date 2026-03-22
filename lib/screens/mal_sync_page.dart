import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/mal_sync_service.dart';

/// MAL Sync settings page — configure MAL API key, login, view synced list.
class MalSyncPage extends StatefulWidget {
  const MalSyncPage({super.key});
  @override
  State<MalSyncPage> createState() => _MalSyncPageState();
}

class _MalSyncPageState extends State<MalSyncPage> {
  final TextEditingController _clientIdCtrl = TextEditingController();
  bool _isEnabled = false;
  bool _loading = true;
  List<MalAnimeEntry> _malList = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _isEnabled = await MalSyncService.isEnabled();
    final clientId = await MalSyncService.getClientId();
    _clientIdCtrl.text = clientId ?? '';
    if (_isEnabled) {
      _malList = await MalSyncService.getMyList(limit: 30);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveClientId() async {
    await MalSyncService.setClientId(_clientIdCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('MAL Client ID saved ✅'),
          backgroundColor: Colors.green),
    );
  }

  Future<void> _startAuth() async {
    final url = await MalSyncService.getAuthUrl();
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set your MAL Client ID first'),
            backgroundColor: Colors.red),
      );
      return;
    }
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _disconnect() async {
    await MalSyncService.disconnect();
    setState(() { _isEnabled = false; _malList = []; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('🎭 MAL Sync',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF2E51A2).withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.95),
            ]),
          ),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E51A2)))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isEnabled
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isEnabled ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(_isEnabled ? Icons.check_circle : Icons.warning_amber,
                    color: _isEnabled ? Colors.green : Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    _isEnabled ? 'Connected to MyAnimeList ✅'
                        : 'Not connected yet',
                    style: TextStyle(color: _isEnabled ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600))),
                ]),
              ),

              const SizedBox(height: 20),

              // Client ID input
              Text('MAL API Client ID',
                style: TextStyle(color: Colors.grey.shade300,
                    fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _clientIdCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste your Client ID here...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save, color: Color(0xFF2E51A2)),
                    onPressed: _saveClientId),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('https://myanimelist.net/apiconfig'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text('Get your Client ID at myanimelist.net/apiconfig →',
                  style: TextStyle(color: Colors.blue.shade300, fontSize: 11,
                      decoration: TextDecoration.underline)),
              ),

              const SizedBox(height: 20),

              // Auth buttons
              if (!_isEnabled)
                ElevatedButton.icon(
                  onPressed: _startAuth,
                  icon: const Icon(Icons.login),
                  label: const Text('Login with MyAnimeList'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E51A2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                )
              else
                ElevatedButton.icon(
                  onPressed: _disconnect,
                  icon: const Icon(Icons.logout),
                  label: const Text('Disconnect MAL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                ),

              // Synced list
              if (_isEnabled && _malList.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('My Anime List',
                  style: TextStyle(color: Colors.grey.shade300,
                      fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                ..._malList.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: Colors.white.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: entry.coverUrl.isNotEmpty
                        ? Image.network(entry.coverUrl, width: 42, height: 60,
                            fit: BoxFit.cover)
                        : Container(width: 42, height: 60,
                            color: Colors.grey.shade900),
                    ),
                    title: Text(entry.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${entry.status} · ${entry.episodesWatched} eps',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    trailing: entry.score > 0
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          Text('${entry.score}',
                            style: const TextStyle(color: Colors.amber, fontSize: 12)),
                        ])
                      : null,
                  ),
                )),
              ],
            ],
          ),
    );
  }
}
