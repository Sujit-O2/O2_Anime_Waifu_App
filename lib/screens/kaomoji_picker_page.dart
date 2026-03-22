import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/waifu_background.dart';

class KaomojiPickerPage extends StatefulWidget {
  const KaomojiPickerPage({super.key});
  @override
  State<KaomojiPickerPage> createState() => _KaomojiPickerPageState();
}

class _KaomojiPickerPageState extends State<KaomojiPickerPage> {
  static const _categories = {
    '🌸 Waifu': [
      '(づ｡◕‿‿◕｡)づ',
      '(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧',
      '(っ◔◡◔)っ',
      '(人 •͈ᴗ•͈)',
      '(˘³˘)♥',
      'emu(^○^)emu',
      '♡(˘▽˘>ʃƪ)♡',
      '(*^ω^)',
      'ヽ(♡‿♡)ノ',
      '(o^▽^o)',
      '( ˘ ³˘)♥',
      '٩(♡ε♡)۶',
    ],
    '😄 Happy': [
      '(＾▽＾)',
      '(ﾉ≧∀≦)ﾉ',
      '(◕‿◕✿)',
      '(｀∀´)ﾉ',
      '(≧◡≦)',
      '(*≧ω≦)',
      '(✿◠‿◠)',
      '٩(^‿^)۶',
    ],
    '😢 Sad': [
      '(T_T)',
      '(；ω；)',
      '(っ˘̩╭╮˘̩)っ',
      '(´；ω；`)',
      '(._.)  ',
      '(πーπ)',
      '(T▽T)',
      '(ㄒoㄒ)',
    ],
    '😤 Angry': [
      '(╯°□°）╯︵ ┻━┻',
      '(ノಠ益ಠ)ノ彡┻━┻',
      '(҂◡_◡)',
      '٩(ఠ益ఠ)۶',
      '(╬ಠ益ಠ)',
      '(ó ì_í)=óò=(ì_í ò)',
      '(￣^￣)ゞ',
      '(◣_◢)',
    ],
    '😎 Cool': [
      '( •_•)',
      '(•_•)>⌐■-■',
      '(⌐■_■)',
      '(づ  ̄ ³ ̄)づ',
      '(¬‿¬)',
      '( ͡° ͜ʖ ͡°)',
      '(o_O)',
      'ψ(｀∇´)ψ',
    ],
    '🐾 Animals': [
      '(=^･ω･^=)',
      '（＾ｖ＾）',
      'ʕ•ᴥ•ʔ',
      'ฅ^•ﻌ•^ฅ',
      '(ᵔᴥᵔ)',
      '(^=◕ᴥ◕=^)',
      'U・ᴥ・U',
      '(*.*)✿',
    ],
    '🎉 Celebration': [
      '\\(^o^)/',
      '(ﾉ´▽`)ﾉ♪',
      '☆彡',
      '(*^▽^*)',
      'ヽ(・∀・)ﾉ',
      '٩(◕‿◕)۶',
      '(≧▽≦)/~☆',
      '(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧',
    ],
  };

  String _selectedCat = '🌸 Waifu';
  String? _lastCopied;

  void _copy(String k) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: k));
    setState(() => _lastCopied = k);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Text(k, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text('Copied to clipboard!', style: GoogleFonts.outfit()),
        ]),
        backgroundColor: Colors.pinkAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kaomojis = _categories[_selectedCat] ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.09,
        tint: const Color(0xFF0A0714),
        child: SafeArea(
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
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white60, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KAOMOJI PICKER',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      Text('Tap to copy any kaomoji~',
                          style: GoogleFonts.outfit(
                              color: Colors.pinkAccent.withOpacity(0.6),
                              fontSize: 10)),
                    ]),
              ),
              // Last copied preview
              if (_lastCopied != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                  ),
                  child:
                      Text(_lastCopied!, style: const TextStyle(fontSize: 13)),
                ),
            ]),
          ),

          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: _categories.keys.map((cat) {
                final sel = cat == _selectedCat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCat = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: sel
                          ? Colors.pinkAccent.withOpacity(0.18)
                          : Colors.white.withOpacity(0.04),
                      border: Border.all(
                          color: sel ? Colors.pinkAccent : Colors.white12),
                    ),
                    child: Text(cat,
                        style: GoogleFonts.outfit(
                            color: sel ? Colors.pinkAccent : Colors.white54,
                            fontSize: 12,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Kaomoji grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: kaomojis.length,
              itemBuilder: (ctx, i) {
                final k = kaomojis[i];
                final isCopied = _lastCopied == k;
                return GestureDetector(
                  onTap: () => _copy(k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isCopied
                          ? Colors.pinkAccent.withOpacity(0.1)
                          : Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: isCopied
                            ? Colors.pinkAccent.withOpacity(0.4)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Center(
                      child: Text(k,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ),
                  ),
                );
              },
            ),
          ),
        ])),
      ),
    );
  }
}
