import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

/// Auto Project Generator — Say "create spring boot project" → generates structure + starter code.
class ProjectGeneratorPage extends StatefulWidget {
  const ProjectGeneratorPage({super.key});
  @override
  State<ProjectGeneratorPage> createState() => _ProjectGeneratorPageState();
}

class _ProjectGeneratorPageState extends State<ProjectGeneratorPage> {
  String? _selectedTemplate;
  bool _generating = false;
  Map<String, dynamic>? _generated;

  final _templates = [
    {
      'name': 'Flutter App',
      'icon': '🦋',
      'desc': 'Mobile app with auth + API',
      'files': ['lib/main.dart', 'lib/screens/home.dart', 'lib/screens/login.dart', 'lib/services/api_service.dart', 'lib/models/user.dart', 'pubspec.yaml'],
      'cmd': 'flutter create my_app && cd my_app',
    },
    {
      'name': 'React App',
      'icon': '⚛️',
      'desc': 'Frontend with routing + state',
      'files': ['src/App.jsx', 'src/pages/Home.jsx', 'src/pages/Login.jsx', 'src/components/Navbar.jsx', 'src/hooks/useAuth.js', 'src/api/client.js', 'package.json'],
      'cmd': 'npx create-react-app my-app && cd my-app',
    },
    {
      'name': 'Spring Boot API',
      'icon': '☕',
      'desc': 'REST API with database',
      'files': ['src/main/java/App.java', 'src/main/java/controller/UserController.java', 'src/main/java/service/UserService.java', 'src/main/java/model/User.java', 'src/main/java/repository/UserRepo.java', 'application.yml', 'pom.xml'],
      'cmd': 'spring init --dependencies=web,jpa,h2 my-api',
    },
    {
      'name': 'Node.js Express API',
      'icon': '🟢',
      'desc': 'REST API with middleware',
      'files': ['index.js', 'routes/auth.js', 'routes/users.js', 'middleware/auth.js', 'models/User.js', 'config/db.js', 'package.json'],
      'cmd': 'mkdir api && npm init -y && npm i express mongoose dotenv',
    },
    {
      'name': 'Next.js Full Stack',
      'icon': '▲',
      'desc': 'SSR + API routes',
      'files': ['app/page.tsx', 'app/layout.tsx', 'app/api/users/route.ts', 'components/Navbar.tsx', 'lib/db.ts', 'lib/auth.ts', 'next.config.js'],
      'cmd': 'npx create-next-app@latest my-next-app',
    },
    {
      'name': 'Python FastAPI',
      'icon': '🐍',
      'desc': 'Modern async Python API',
      'files': ['main.py', 'routers/users.py', 'models/user.py', 'schemas/user.py', 'database.py', 'auth.py', 'requirements.txt'],
      'cmd': 'pip install fastapi uvicorn sqlalchemy',
    },
  ];

  void _generate(Map<String, dynamic> template) async {
    setState(() { _generating = true; _selectedTemplate = template['name'] as String; });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _generating = false;
      _generated = template;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('PROJECT GENERATOR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(children: [
        const Text('🏗️', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 6),
        Text('Auto Project Generator', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        Text('Pick a template → instantly generate structure', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 16),

        // Template grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: _templates.length,
          itemBuilder: (_, i) {
            final t = _templates[i];
            final isSelected = _selectedTemplate == t['name'];
            return GestureDetector(
              onTap: () => _generate(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isSelected ? Colors.cyanAccent : Colors.white).withValues(alpha: isSelected ? 0.08 : 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: (isSelected ? Colors.cyanAccent : Colors.white).withValues(alpha: isSelected ? 0.4 : 0.08)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(t['icon'] as String, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(t['name'] as String, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(t['desc'] as String, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        if (_generating)
          Column(children: [
            const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 8),
            Text('Generating $_selectedTemplate...', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),

        if (_generated != null && !_generating) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${_generated!['icon']} ', style: const TextStyle(fontSize: 20)),
                Text('${_generated!['name']} Structure', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 8),
              // File tree
              ...(_generated!['files'] as List).cast<String>().map((f) {
                final indent = f.split('/').length - 1;
                return Padding(
                  padding: EdgeInsets.only(left: indent * 16.0, bottom: 3),
                  child: Row(children: [
                    Icon(f.contains('.') ? Icons.insert_drive_file_rounded : Icons.folder_rounded, size: 14, color: Colors.cyanAccent.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Text(f.split('/').last, style: GoogleFonts.firaCode(color: Colors.white60, fontSize: 11)),
                  ]),
                );
              }),
              const SizedBox(height: 10),
              // Command
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Text('>', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_generated!['cmd'] as String, style: GoogleFonts.firaCode(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 11))),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _generated!['cmd'] as String));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied!', style: GoogleFonts.outfit()), backgroundColor: Colors.greenAccent.withValues(alpha: 0.2)));
                    },
                    child: const Icon(Icons.copy_rounded, size: 16, color: Colors.greenAccent),
                  ),
                ]),
              ),
            ]),
          ),
        ],
      ])),
    );
  }
}
