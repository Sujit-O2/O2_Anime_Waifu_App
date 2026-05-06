import 'dart:async' show unawaited;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:anime_waifu/services/smart_features/document_scanner_service.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class DocumentScannerPage extends StatefulWidget {
  const DocumentScannerPage({super.key});

  @override
  State<DocumentScannerPage> createState() => _DocumentScannerPageState();
}

class _DocumentScannerPageState extends State<DocumentScannerPage>
    with TickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  late AnimationController _fadeCtrl;

  String _selectedDocType = 'note';
  bool _isScanning = false;
  String _scanResult = '';
  List<ScannedDocument> _documents = [];
  List<ScannedDocument> _filteredDocuments = [];
  ScannedDocument? _selectedDocument;
  String _searchQuery = '';

  static const _docTypes = [
    {'value': 'note', 'label': 'Note', 'icon': Icons.note_alt_outlined},
    {'value': 'bill', 'label': 'Bill', 'icon': Icons.receipt_long},
    {'value': 'id', 'label': 'ID Card', 'icon': Icons.badge_outlined},
    {'value': 'form', 'label': 'Form', 'icon': Icons.description_outlined},
    {'value': 'receipt', 'label': 'Receipt', 'icon': Icons.request_quote},
    {'value': 'screenshot', 'label': 'Screenshot', 'icon': Icons.screenshot},
    {'value': 'other', 'label': 'Other', 'icon': Icons.category_outlined},
  ];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('document_scanner'));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _loadDocuments();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _titleCtrl.dispose();
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    final docs = await DocumentScannerService.instance.getDocuments();
    if (mounted) {
      setState(() {
        _documents = docs;
        _filteredDocuments = docs;
      });
    }
  }

  void _onSearchChanged() {
    _searchQuery = _searchCtrl.text.trim();
    if (_searchQuery.isEmpty) {
      setState(() => _filteredDocuments = _documents);
    } else {
      _filterDocuments();
    }
  }

  Future<void> _filterDocuments() async {
    final results =
        await DocumentScannerService.instance.searchDocuments(_searchQuery);
    if (mounted) {
      setState(() => _filteredDocuments = results);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        final file = File(picked.path);
        final bytes = await file.readAsBytes();
        final text = bytes.isNotEmpty
            ? '[Image captured: ${picked.name} - ${bytes.length ~/ 1024}KB]\n(Paste or type the text content below)'
            : '';
        setState(() {
          _textCtrl.text = text;
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Image captured~ Add the text content below',
              style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: const Color(0xFF00BCD4),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Could not pick image~ Try again', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _scanAndAnalyze() async {
    final title = _titleCtrl.text.trim();
    final text = _textCtrl.text.trim();

    if (title.isEmpty || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a title and document text~',
            style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: const Color(0xFF00BCD4),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isScanning = true;
      _scanResult = '';
    });

    try {
      final doc =
          await DocumentScannerService.instance.analyzeAndSaveDocument(
        title: title,
        text: text,
        docType: _selectedDocType,
      );
      if (mounted) {
        setState(() {
          _scanResult = 'Document analyzed and saved successfully~';
        });
        _titleCtrl.clear();
        _textCtrl.clear();
        _loadDocuments();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Document "${doc.title}" saved and analyzed~',
              style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: const Color(0xFF00BCD4),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        await DocumentScannerService.instance.addDocument(
          title: title,
          text: text,
          docType: _selectedDocType,
        );
        setState(() {
          _scanResult = 'Document saved (AI analysis failed, will retry later)';
        });
        _titleCtrl.clear();
        _textCtrl.clear();
        _loadDocuments();
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _deleteDocument(String id) async {
    final success = await DocumentScannerService.instance.deleteDocument(id);
    if (success && mounted) {
      setState(() {
        if (_selectedDocument?.id == id) {
          _selectedDocument = null;
        }
      });
      _loadDocuments();
      HapticFeedback.lightImpact();
    }
  }

  void _showDocumentDetail(ScannedDocument doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: const BoxDecoration(
            color: Color(0xFF0A0B14),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getDocTypeIcon(doc.docType),
                            color: const Color(0xFF00BCD4),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            doc.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showDeleteConfirmation(doc);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_getDocTypeLabel(doc.docType)} • ${_formatDate(doc.createdAt)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOCUMENT TEXT',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF00BCD4),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            doc.text,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (doc.summary.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF00BCD4).withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome,
                                    color: Color(0xFF00BCD4), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'AI SUMMARY',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF00BCD4),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              doc.summary,
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (doc.keyInfo.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.purple.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.purple, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'EXTRACTED KEY INFO',
                                  style: GoogleFonts.outfit(
                                    color: Colors.purple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              doc.keyInfo,
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(ScannedDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0B14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Document?',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: Text(
          'This will permanently remove "${doc.title}".',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteDocument(doc.id);
            },
            child: Text('Delete',
                style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getDocTypeIcon(String type) {
    final match = _docTypes.firstWhere(
      (t) => t['value'] == type,
      orElse: () => _docTypes.last,
    );
    return match['icon'] as IconData;
  }

  String _getDocTypeLabel(String type) {
    final match = _docTypes.firstWhere(
      (t) => t['value'] == type,
      orElse: () => _docTypes.last,
    );
    return match['label'] as String;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'DOCUMENT SCANNER',
      subtitle: '${_documents.length} documents stored',
      onBack: () => Navigator.pop(context),
      content: FadeTransition(
        opacity: _fadeCtrl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.06),
                  border: Border.all(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.document_scanner,
                        color: Color(0xFF00BCD4), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Capture or paste document text for AI analysis~',
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'CAPTURE SOURCE',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.camera),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined,
                                color: Color(0xFF00BCD4), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Camera',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_library_outlined,
                                color: Color(0xFF00BCD4), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Gallery',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'DOCUMENT TITLE',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFF00BCD4).withValues(alpha: 0.15)),
                ),
                child: TextField(
                  controller: _titleCtrl,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  cursorColor: const Color(0xFF00BCD4),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    hintText: 'e.g. Electricity Bill March 2026',
                    hintStyle: GoogleFonts.outfit(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'DOCUMENT TYPE',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDocType,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0A0B14),
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    items: _docTypes.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['value'] as String,
                        child: Row(
                          children: [
                            Icon(t['icon'] as IconData,
                                color: Colors.white54, size: 16),
                            const SizedBox(width: 10),
                            Text(t['label'] as String,
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedDocType = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'DOCUMENT TEXT',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFF00BCD4).withValues(alpha: 0.15)),
                ),
                child: TextField(
                  controller: _textCtrl,
                  maxLines: 8,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  cursorColor: const Color(0xFF00BCD4),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    hintText:
                        'Paste or type the document content here...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isScanning ? null : _scanAndAnalyze,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.25),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isScanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _isScanning ? 'Analyzing...' : 'Scan & Analyze',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              if (_scanResult.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _scanResult,
                          style: GoogleFonts.outfit(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'SCANNED DOCUMENTS',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredDocuments.length} / ${_documents.length}',
                    style: GoogleFonts.outfit(
                        color: Colors.white30, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  cursorColor: const Color(0xFF00BCD4),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    hintText: 'Search documents...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white24),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white38, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _filteredDocuments = _documents);
                            },
                            child: const Icon(Icons.clear,
                                color: Colors.white38, size: 20),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_filteredDocuments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off_outlined
                            : Icons.folder_open_outlined,
                        color: Colors.white24,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No documents match your search'
                            : 'No documents yet~',
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Try a different query'
                            : 'Scan your first document above',
                        style: GoogleFonts.outfit(
                            color: Colors.white24, fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                ..._filteredDocuments.map((doc) {
                  final idx = _filteredDocuments.indexOf(doc);
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + idx * 60),
                    curve: Curves.easeOut,
                    builder: (_, val, child) => Opacity(
                      opacity: val,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - val)),
                        child: child,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => _showDocumentDetail(doc),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00BCD4)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getDocTypeIcon(doc.docType),
                                color: const Color(0xFF00BCD4),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    doc.text.length > 80
                                        ? '${doc.text.substring(0, 80)}...'
                                        : doc.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white54, fontSize: 11),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        _getDocTypeLabel(doc.docType),
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF00BCD4)
                                              .withValues(alpha: 0.6),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        ' • ',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white24,
                                            fontSize: 10),
                                      ),
                                      Text(
                                        _formatDate(doc.createdAt),
                                        style: GoogleFonts.outfit(
                                            color: Colors.white30,
                                            fontSize: 10),
                                      ),
                                      if (doc.summary.isNotEmpty) ...[
                                        Text(
                                          ' • ',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white24,
                                              fontSize: 10),
                                        ),
                                        const Icon(Icons.auto_awesome,
                                            color: Colors.purple, size: 10),
                                        const SizedBox(width: 3),
                                        Text(
                                          'AI analyzed',
                                          style: GoogleFonts.outfit(
                                              color: Colors.purple
                                                  .withValues(alpha: 0.6),
                                              fontSize: 10),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.white24, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              if (_documents.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storage_outlined,
                          color: Colors.white38, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_documents.length} documents stored locally',
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ),
                      Text(
                        '~${(_documents.length * 2).clamp(1, 999)}KB',
                        style: GoogleFonts.outfit(
                            color: Colors.white30, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
