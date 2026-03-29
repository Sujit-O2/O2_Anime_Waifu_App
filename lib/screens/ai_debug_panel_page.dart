import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/simulated_life_loop.dart';
import '../services/personality_engine.dart';

class AiDebugPanelPage extends StatelessWidget {
  const AiDebugPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final life = SimulatedLifeLoop.instance;
    final pe = PersonalityEngine.instance;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A), elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.greenAccent), onPressed: () => Navigator.pop(context)),
        title: Text('AI DEBUG PANEL', style: GoogleFonts.sourceCodePro(color: Colors.greenAccent, fontWeight: FontWeight.w700, fontSize: 14)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _header('PERSONALITY ENGINE'),
          _debugCard([
            _kv('Affection', '${pe.affection}', Colors.pinkAccent),
            _kv('Playfulness', '${pe.playfulness}', Colors.amberAccent),
            _kv('Jealousy', '${pe.jealousy}', Colors.redAccent),
            _kv('Dependency', '${pe.dependency}', Colors.cyanAccent),
            _kv('Trust', '${pe.trust}', Colors.orangeAccent),
          ]),
          _header('LIFE STATE'),
          _debugCard([
            _kv('State', life.current.name, Colors.cyanAccent),
            _kv('Energy', '${life.energy}/100', Colors.greenAccent),
            _kv('Sleeping', life.isSleeping ? 'YES' : 'NO', Colors.white54),
          ]),
          _header('SYSTEM CONTEXT'),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.15))),
            child: Text(life.getLifeStateContextBlock(), style: GoogleFonts.sourceCodePro(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 10, height: 1.6)),
          ),
          const SizedBox(height: 12),
          _header('MULTI-AGENT VIEW'),
          _agentTile('Planner', 'Suggesting response', Colors.cyanAccent),
          _agentTile('Emotion', 'Bias: ${pe.affection > 70 ? "Loving" : "Balanced"}', Colors.pinkAccent),
          _agentTile('Memory', 'Retrieving context', Colors.greenAccent),
          _header('ENGINE STATUS'),
          _debugCard([
            _kv('LLM', 'Groq (llama3)', Colors.greenAccent),
            _kv('STT', 'Google Speech', Colors.greenAccent),
            _kv('TTS', 'Flutter TTS', Colors.greenAccent),
            _kv('Wake', 'ONNX CNN', Colors.greenAccent),
          ]),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _header(String t) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: Text(t, style: GoogleFonts.sourceCodePro(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)));
  Widget _debugCard(List<Widget> c) => Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.15))), child: Column(children: c));
  Widget _kv(String k, String v, Color c) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [SizedBox(width: 100, child: Text(k, style: GoogleFonts.sourceCodePro(color: Colors.white38, fontSize: 11))), Expanded(child: Text(v, style: GoogleFonts.sourceCodePro(color: c, fontSize: 11, fontWeight: FontWeight.w700)))]));
  Widget _agentTile(String n, String s, Color c) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.2))), child: Row(children: [Icon(Icons.smart_toy, color: c, size: 16), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n, style: GoogleFonts.sourceCodePro(color: c, fontSize: 10, fontWeight: FontWeight.w700)), Text(s, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10))])]));
}
