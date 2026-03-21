import 'package:flutter/material.dart';
import '../services/download_service.dart';

/// Downloads page — shows offline manga chapters and anime episodes.
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});
  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<DownloadItem> _downloads = [];
  bool _loading = true;
  String _totalSize = '0 MB';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await DownloadService.getDownloads();
    final sizeBytes = await DownloadService.getTotalSize();
    final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    if (mounted) setState(() {
      _downloads = items;
      _totalSize = '$sizeMb MB';
      _loading = false;
    });
  }

  Future<void> _delete(DownloadItem item) async {
    await DownloadService.deleteDownload(item.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('📱 Downloads',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.green.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.95),
            ]),
          ),
        ),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(_totalSize,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          )),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : _downloads.isEmpty
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_done, color: Colors.grey.shade700, size: 60),
                const SizedBox(height: 12),
                Text('No downloads yet',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Download manga chapters or anime episodes\nfor offline viewing',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _downloads.length,
              itemBuilder: (_, i) {
                final item = _downloads[i];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _delete(item),
                  background: Container(
                    color: Colors.red.withValues(alpha: 0.2),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: Colors.white.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.coverUrl.isNotEmpty
                          ? Image.network(item.coverUrl, width: 45, height: 60,
                              fit: BoxFit.cover)
                          : Container(width: 45, height: 60,
                              color: Colors.grey.shade900),
                      ),
                      title: Text(item.title,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${item.type == 'manga' ? '📖' : '📺'} ${item.type.toUpperCase()}'
                        '${item.pageCount > 0 ? ' · ${item.pageCount} pages' : ''}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      trailing: const Icon(Icons.offline_pin,
                          color: Colors.green, size: 20),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
