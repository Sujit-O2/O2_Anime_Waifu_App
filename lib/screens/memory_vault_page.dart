import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/long_term_memory_db.dart';

class MemoryVaultPage extends StatefulWidget {
  const MemoryVaultPage({super.key});

  @override
  State<MemoryVaultPage> createState() => _MemoryVaultPageState();
}

class _MemoryVaultPageState extends State<MemoryVaultPage> {
  List<Map<String, dynamic>> _memories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);
    final mems = await LongTermMemoryDb.getAllMemories();
    if (mounted) {
      setState(() {
        _memories = mems;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMemory(String fact) async {
    await LongTermMemoryDb.deleteMemory(fact);
    await _loadMemories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text('Deep Memory Vault', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _memories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.memory, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text(
                        'Zero Two hasn\'t learned any permanent\nfacts about you yet!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _memories.length,
                  itemBuilder: (context, index) {
                    final mem = _memories[index];
                    return Card(
                      color: Colors.white.withValues(alpha: 0.05),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.pinkAccent,
                          child: Icon(Icons.lock_clock, color: Colors.white),
                        ),
                        title: Text(
                          mem['fact'].toString(),
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                        ),
                        subtitle: Text(
                          'Extracted: ${DateTime.tryParse(mem['timestamp'].toString())?.toLocal().toString().split('.').first ?? ''}',
                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white30),
                          onPressed: () => _deleteMemory(mem['fact'].toString()),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
