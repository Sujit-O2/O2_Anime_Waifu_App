import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/widgets/waifu_background.dart';

/// Project Generator v2 — Auto-generate project structure with
/// animated cards, file tree preview, and copy-to-clipboard.
class ProjectGeneratorPage extends StatefulWidget {
  const ProjectGeneratorPage({super.key});
  @override
  State<ProjectGeneratorPage> createState() => _ProjectGeneratorPageState();
}

class _ProjectGeneratorPageState extends State<ProjectGeneratorPage> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  String? _selectedTemplate;
  bool _generating = false;
  Map<String, dynamic>? _generated;

  final _templates = [
    {'name': 'Flutter App', 'icon': '🦋', 'desc': 'Mobile app with auth + API', 'files': ['lib/main.dart', 'lib/screens/home.dart', 'lib/screens/login.dart', 'lib/services/api_service.dart', 'lib/models/user.dart', 'pubspec.yaml'], 'cmd': 'flutter create my_app && cd my_app'},
    {'name': 'React App', 'icon': '⚛️', 'desc': 'Frontend with routing + state', 'files': ['src/App.jsx', 'src/pages/Home.jsx', 'src/pages/Login.jsx', 'src/components/Navbar.jsx', 'src/hooks/useAuth.js', 'src/api/client.js', 'package.json'], 'cmd': 'npx create-react-app my-app && cd my-app'},
    {'name': 'Spring Boot API', 'icon': '☕', 'desc': 'REST API with database', 'files': ['src/main/java/App.java', 'src/main/java/controller/UserController.java', 'src/main/java/service/UserService.java', 'src/main/java/model/User.java', 'src/main/java/repository/UserRepo.java', 'application.yml', 'pom.xml'], 'cmd': 'spring init --dependencies=web,jpa,h2 my-api'},
    {'name': 'Node.js Express API', 'icon': '🟢', 'desc': 'REST API with middleware', 'files': ['index.js', 'routes/auth.js', 'routes/users.js', 'middleware/auth.js', 'models/User.js', 'config/db.js', 'package.json'], 'cmd': 'mkdir api && npm init -y && npm i express mongoose dotenv'},
    {'name': 'Next.js Full Stack', 'icon': '▲', 'desc': 'SSR + API routes', 'files': ['app/page.tsx', 'app/layout.tsx', 'app/api/users/route.ts', 'components/Navbar.tsx', 'lib/db.ts', 'lib/auth.ts', 'next.config.js'], 'cmd': 'npx create-next-app@latest my-next-app'},
    {'name': 'Python FastAPI', 'icon': '🐍', 'desc': 'Modern async Python API', 'files': ['main.py', 'routers/users.py', 'models/user.py', 'schemas/user.py', 'database.py', 'auth.py', 'requirements.txt'], 'cmd': 'pip install fastapi uvicorn sqlalchemy'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  void _generate(Map<String, dynamic> template) async {
    HapticFeedback.mediumImpact();
    setState(() { _generating = true; _selectedTemplate = template['name']?.toString() ?? ''; });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() { _generating = false; _generated = template; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: WaifuBackground(
        opacity: 0.07,
        tint: const Color(0xFF080C14),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: Column(children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('PROJECT GENERATOR', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    Text('Instant project scaffolding', style: GoogleFonts.outfit(color: Colors.cyanAccent.withValues(alpha: 0.7), fontSize: 10)),
                  ])),
                ]),
              ),

              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // ── Hero Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(colors: [Colors.cyanAccent.withValues(alpha: 0.1), Colors.teal.withValues(alpha: 0.05)]),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                    ),
                    child: Column(children: [
                      const Text('🏗️', style: TextStyle(fontSize: 42)),
                      const SizedBox(height: 8),
                      Text('Auto Project Generator', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      Text('Pick a template → instantly generate structure', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Template Grid ──
                  Text('TEMPLATES', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                    itemCount: _templates.length,
                    itemBuilder: (_, i) => _buildTemplateCard(i, _templates[i]),
                  ),
                  const SizedBox(height: 16),

                  if (_generating)
                    Column(children: [
                      const CircularProgressIndicator(color: Colors.cyanAccent),
                      const SizedBox(height: 8),
                      Text('Generating $_selectedTemplate...', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),

                  if (_generated != null && !_generating) _buildGeneratedCard(),
                ]),
              )),

              // ── Waifu Card ──
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.pinkAccent.withValues(alpha: 0.06),
                  border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Text('💕', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    '"I\'ll help you build amazing projects, Darling! Just pick a template~"',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic, height: 1.5),
                  )),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(int index, Map<String, dynamic> t) {
    final isSelected = _selectedTemplate == t['name'];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 12 * (1 - val)), child: child)),
      child: GestureDetector(
        onTap: () => _generate(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(t['icon']?.toString() ?? '', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(t['name']?.toString() ?? '', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            Text(t['desc']?.toString() ?? '', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
          ]),
        ),
      ),
    );
  }

  Widget _buildGeneratedCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.cyanAccent.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('${_generated!['icon']} ', style: const TextStyle(fontSize: 22)),
        Text('${_generated!['name']} Structure', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 12),
      ...(_generated!['files'] as List).cast<String>().map((f) {
        final indent = f.split('/').length - 1;
        return Padding(
          padding: EdgeInsets.only(left: indent * 16.0, bottom: 4),
          child: Row(children: [
            Icon(f.contains('.') ? Icons.insert_drive_file_rounded : Icons.folder_rounded, size: 14, color: Colors.cyanAccent.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(f.split('/').last, style: GoogleFonts.firaCode(color: Colors.white60, fontSize: 11)),
          ]),
        );
      }),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Text('>', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Expanded(child: Text(_generated!['cmd']?.toString() ?? '', style: GoogleFonts.firaCode(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 11))),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _generated!['cmd']?.toString() ?? ''));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Copied to clipboard!', style: GoogleFonts.outfit()),
                backgroundColor: Colors.greenAccent.withValues(alpha: 0.9),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.copy_rounded, size: 16, color: Colors.greenAccent),
            ),
          ),
        ]),
      ),
    ]),
  );
}


