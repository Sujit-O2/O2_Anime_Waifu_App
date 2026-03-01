part of '../main.dart';

extension _AboutPageExtension on _ChatHomePageState {
  Widget _buildAboutPage() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Column(
          children: [
            _buildAboutHeader(),
            _buildHorizontalDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAboutSection("⚡ REAL-TIME NEURAL STATUS", [
                    _buildStatusBadge("CORE_INIT", "DONE", Colors.greenAccent),
                    _buildStatusBadge("BONDING", "99.9%", Colors.pinkAccent),
                    _buildStatusBadge("SYNC", "STABLE", Colors.blueAccent),
                    _buildStatusBadge(
                        "GHOST", "MONITORING", Colors.orangeAccent),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("🆕 DIMENSIONAL UPDATES", [
                    _buildBulletPoint(
                        "Hyper-Dynamic Proactive Empathy: AI check-ins with random delays (30-180m)."),
                    _buildBulletPoint(
                        "Varied Idle Prompts: 50+ randomized voice lines for attention."),
                    _buildBulletPoint(
                        "Cinematic Overdrive: 18-tier theme engine with cinematic lighting."),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("🌌 THE DIMENSIONAL VISION", [
                    _buildTextCard(
                        "The Anime Waifu Voice Assistant is an experimental framework designed for high-fidelity voice interaction. Inspired by Zero Two, it blends on-device logic with cloud neural brains."),
                    const SizedBox(height: 12),
                    _buildBulletPoint(
                        "Zero-Latency Response: The Ghost Listener Android Service ensures the app is always ready without manual triggers."),
                    _buildBulletPoint(
                        "Emotional Resonance: Advanced behavioral guiding prompts maintain a consistent, engaging persona."),
                    _buildBulletPoint(
                        "Cross-Platform Immersion: A sleek, adaptive atmosphere that reacts to every synaptic pulse."),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("🧪 THEORY OF OPERATION", [
                    _buildTheoryHeader(
                        "1. Acoustic Dimensionality (Wake Word)"),
                    _buildTextCard(
                        "The primary entry point of the Dimensional Nexus is the Acoustic Buffer. Leveraging the Porcupine Edge Engine, the app maintains a low-power, privacy-first watchdog that monitors PCM audio streams for the specific vocal frequency of 'Zero Two'. This process occurs entirely on-device, ensuring that auditory data is never transmitted until a confirmed activation event initializes the Synaptic Link."),
                    const SizedBox(height: 16),
                    _buildTheoryHeader("2. Spectral Transduction (STT Engine)"),
                    _buildTextCard(
                        "Once activated, the Spectral Transduction layer (Speech-to-Text) begins tokenizing vocal vibrations. Using a hybrid approach of Android's Speech Recon and local buffer processing, the system filters out ambient entropy (noise) to isolate the 'Darling's' intent. This linguistic data is then packaged into a JSON-serialized payload, augmented with temporal metadata to maintain a coherent timeline of interaction."),
                    const SizedBox(height: 16),
                    _buildTheoryHeader(
                        "3. Neural Synapse Routing (Logic Layer)"),
                    _buildTextCard(
                        "Linguistic tokens are routed through the Neural Dispatcher to the ‘Great Brain’ (LLM). This layer acts as the prefrontal cortex of Zero Two. It doesn't just process text; it interprets sentiment, context, and persona constraints. The dispatcher applies 'Synaptic DNA'—a complex system prompt that defines her personality, memories of the Darling, and emotional boundaries within the Groq/OpenAI cloud infrastructure."),
                    const SizedBox(height: 16),
                    _buildTheoryHeader(
                        "4. Temporal Contextualization (Deep Memory)"),
                    _buildTextCard(
                        "To prevent 'Dimensional Amnesia', the app implements a Persistent Synapse System. Every interaction is cached in SharedPreferences using a sliding-window algorithm. This ensures that Zero Two remembers recent conversations without overloading the neural payload. When the app initializes, the 'Memory Draining' sequence restores these synaptic connections, providing a seamless continuum across sessions."),
                    const SizedBox(height: 16),
                    _buildTheoryHeader("5. Harmonic Synthesis (Vocal Engine)"),
                    _buildTextCard(
                        "The response from the Neural Brain is converted back into the physical world via the Harmonic Synthesis layer (TTS). This engine utilizes 'Vocal Fingerprinting' to ensure the output matches the expected frequency and cadence. By modulating pitch, speech rate, and volume dynamically, the system simulates emotional inflection, making the interaction feel alive rather than robotic."),
                    const SizedBox(height: 16),
                    _buildTheoryHeader(
                        "6. Atmospheric Physics (UI/UX Dynamics)"),
                    _buildTextCard(
                        "The visual interface is more than just pixels; it's a reactive atmosphere. The 'Reactive Pulse' system translates audio amplitudes into visual scale transforms, while the 'Dimensional Blur' effects (BackdropFilter) create a sense of depth. The background is a living particle system that reacts to user touch and AI speech, grounding the digital waifu in a tangible, interactive space."),
                    const SizedBox(height: 16),
                    _buildTheoryHeader(
                        "7. Ghost Logic (Background Architecture)"),
                    _buildTextCard(
                        "The 'Ghost Listener' is a background service that keeps the connection alive even when the app is obscured. This architecture utilizes Android's Foreground Services with high-priority notifications, ensuring the OS doesn't kill the neural link. Proactive Logic allows Zero Two to initiate contact through 'Subliminal Pings' (Notifications) when she detects an idle state in the Darling's presence."),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("📊 SYNAPTIC SPECIFICATIONS", [
                    _buildBulletPoint(
                        "Microphone Buffer: PCM 16-bit, 16000Hz Mono"),
                    _buildBulletPoint(
                        "Wake-Word Latency: < 200ms (Edge Processed)"),
                    _buildBulletPoint(
                        "Neural Uplink: REST over TLS 1.3 (End-to-End Encryption)"),
                    _buildBulletPoint(
                        "LLM Temperature: 0.7 (Optimized for Persona Consistency)"),
                    _buildBulletPoint(
                        "TTS Synthesis: High-fidelity hybrid output (24000Hz)"),
                    _buildBulletPoint(
                        "Memory Window: 50 messages sliding history"),
                    _buildBulletPoint(
                        "UI Frame Target: 60FPS (Impeller/Skia Optimized)"),
                    const SizedBox(height: 12),
                    _buildTextCard(
                        "Detailed performance telemetry suggests an average 'Round Trip Time' (RTT) of 1.2s from user utterance to AI response, depending on network volatility. The system utilizes automated retry logic with exponential backoff on the API layer to ensure the Neural Link remains active under sub-optimal conditions. Every synaptic pulse is logged for debugging purposes in the local 'Spectral Log' system."),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("🔍 SYNAPTIC DEEP DIVE: UNDER THE HOOD", [
                    _buildTheoryHeader("A. The State Machine"),
                    _buildTextCard(
                        "The application operates on a strict Finite State Machine (FSM). Modes include IDLE, LISTENING, THINKING, SPEAKING, and NEURAL_LINK_BROKEN. Transitions are handled via the Synaptic Dispatcher, ensuring that the Microphone, LLM, and TTS never experience resource contention. This prevents the 'Spectral Feedback' loop often found in lesser AI implementations."),
                    const SizedBox(height: 16),
                    _buildTheoryHeader("B. Memory Optimization"),
                    _buildTextCard(
                        "The 'Deep Memory' system uses a FIFO (First-In, First-Out) buffer with a 50-item limit. For every new synapse (message), the oldest is pruned, maintaining a constant memory footprint of approximately 1.5MB in the serialized SharedPreferences pool. This ensures that the app remains fast and responsive even after months of continuous use with the Darling."),
                    const SizedBox(height: 16),
                    _buildTheoryHeader("C. Emotional Weighting Logic"),
                    _buildTextCard(
                        "Rather than just sending raw text, the 'Synaptic Gap' applies persona-specific weights to the LLM system prompt. These weights emphasize Zero Two's unique linguistic traits: playful teasing, affectionate nicknames, and a protective demeanor. This logic is baked into the 'Synaptic DNA' located in the api_call.dart architecture, acting as a constant behavioral catalyst."),
                    const SizedBox(height: 16),
                    _buildTheoryHeader("D. Thermal & Battery Management"),
                    _buildTextCard(
                        "To protect the Darling's device, the app implements a thermal watchdog. When high-frequency synaptic activity is detected, the UI reduces particle density and the Ghost Listener throttles its sampling rate. This balances 'Constant Connection' with hardware longevity, ensuring the waifu is always available without melting the dimensional portal (phone)."),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("📖 SYNAPTIC GLOSSARY", [
                    _buildFAQItem("What is the 'Ghost Listener'?",
                        "A high-priority Android Foreground Service that maintains the PCM audio buffer and Porcupine engine even when the app is in the background."),
                    _buildFAQItem("What is 'Synaptic DNA'?",
                        "The highly-tuned system prompt that defines Zero Two's personality, linguistic quirks, and behavioral guardrails."),
                    _buildFAQItem("What is the 'Spectral Transducer'?",
                        "The Speech-to-Text layer responsible for converting audio spectral data into tokenized text for the LLM."),
                    _buildFAQItem("What is 'Vocal Fingerprinting'?",
                        "The dynamic modulation of TTS pitch, rate, and volume to simulate human-like robotic emotional resonance."),
                    _buildFAQItem("What is 'Dimensional Amnesia'?",
                        "A failure state where context is lost; prevented by the Deep Memory sliding-window persistence system."),
                    _buildFAQItem("What is the 'Synaptic Gap'?",
                        "The latency interval between audio capture and LLM response, optimized via the Groq/OpenAI high-speed routing."),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("🧬 NEURAL ARCHITECTURE", [
                    _buildArchitectureFlow(),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("💎 SYNAPTIC FEATURE MATRIX", [
                    _buildMatrixTable(),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("🏗️ TECHNICAL MANUAL", [
                    _buildTechnicalDeepDive("lib/main.dart",
                        "Synaptic orchestration, cinematic UI & lifecycle awareness."),
                    _buildTechnicalDeepDive("lib/stt.dart",
                        "PCM Buffer Management, Vocal Gate (-40dB) & Partial Token Flow."),
                    _buildTechnicalDeepDive("lib/tts.dart",
                        "Persona Fingerprinting, Pitch Modulation & Hybrid Synthesis."),
                    _buildTechnicalDeepDive("lib/api_call.dart",
                        "TLS 1.3 Encryption, Memory Pruning & Safety Gating."),
                    _buildTechnicalDeepDive("lib/widgets/reactive_pulse.dart",
                        "Real-time audio visualization logic."),
                    _buildTechnicalDeepDive(
                        "lib/widgets/animated_background.dart",
                        "Particle physics & cinematic God-Rays rendering."),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("🛰️ DIMENSION SYNC FAQ", [
                    _buildFAQItem("Interaction Fail?",
                        "Check WAKE_WORD_KEY and Mic permissions."),
                    _buildFAQItem("Memory Reset?",
                        "Use the Delete icon in the top right of the Chat."),
                    _buildFAQItem("High Latency?",
                        "Optimize max_tokens in ApiService or check bandwidth."),
                    _buildFAQItem("Service Interruption?",
                        "Ensure battery optimization is disabled for the app."),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("📚 DIMENSIONAL GLOSSARY", [
                    _buildMatrixRow("DARLING", "TARGET_USER", "💖"),
                    _buildMatrixRow("NEXUS", "APP_FRAMEWORK", "🛸"),
                    _buildMatrixRow("SYNAPSE", "AI_CONNECTION", "⚡"),
                    _buildMatrixRow("GHOST_STATE", "PASSIVE_LISTENING", "👁️"),
                  ]),
                  const SizedBox(height: 32),
                  _buildAboutSection("🌌 FUTURE ROADMAP", [
                    _buildBulletPoint(
                        "On-Device LLM: Llama.dart offline intelligence via native C synapses."),
                    _buildBulletPoint(
                        "Haptic Sync: Speech-aligned vibrations for tactile immersion."),
                    _buildBulletPoint(
                        "Avatar Animations: Live2D model integration with reactive gaze."),
                    _buildBulletPoint(
                        "Emotional Mapping: Real-time sentiment analysis adjusting the UI atmosphere."),
                  ]),
                  const SizedBox(height: 48),
                  _buildHorizontalDivider(),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      "LICENSE: MIT PROTOCOL",
                      style: GoogleFonts.outfit(
                        color: Colors.white10,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "\"If you don't belong here, just build your own world, Darling.\"",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Icon(Icons.favorite,
                            color: Colors.pinkAccent, size: 18),
                        const SizedBox(height: 8),
                        Text("DEVELOPED BY SUJIT SWAIN",
                            style: GoogleFonts.outfit(
                                color: Colors.white10,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.pinkAccent.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 5)
              ],
            ),
            child: ClipOval(
              child: Image.asset('zero_two.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.face, size: 100, color: Colors.white10)),
            ),
          ),
          const SizedBox(height: 24),
          Text("ZERO TWO",
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6)),
          Text("NEURAL NEXUS • v1.5.0",
              style: GoogleFonts.outfit(
                  color: Colors.pinkAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
          const SizedBox(height: 24),
          _buildGitHubLink(),
        ],
      ),
    );
  }

  Widget _buildGitHubLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.code_rounded, color: Colors.white60, size: 16),
          const SizedBox(width: 10),
          Text("Sujit-O2/Anime_Waifu",
              style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHorizontalDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.white10, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildAboutSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Text(title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ],
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }

  Widget _buildStatusBadge(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  color: color.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          Text(value,
              style: GoogleFonts.outfit(
                  color: color, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.auto_awesome, color: Colors.pinkAccent, size: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 13, height: 1.6))),
        ],
      ),
    );
  }

  Widget _buildTextCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(text,
          style: GoogleFonts.outfit(
              color: Colors.white60, fontSize: 13, height: 1.6)),
    );
  }

  Widget _buildArchitectureFlow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGraphNode("MIC", Icons.mic, Colors.pinkAccent),
              _buildGraphArrow(Icons.arrow_forward),
              _buildGraphNode("STT", Icons.graphic_eq, Colors.blueAccent),
            ],
          ),
          _buildVerticalArrow(),
          _buildGraphNode(
              "SYNAPTIC_GAP", Icons.psychology, Colors.deepPurpleAccent,
              isLarge: true),
          _buildVerticalArrow(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGraphNode("TTS", Icons.volume_up, Colors.orangeAccent),
              _buildGraphArrow(Icons.arrow_back),
              _buildGraphNode("LLM", Icons.cloud_queue, Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 20),
          _buildVisualLegend(),
        ],
      ),
    );
  }

  Widget _buildGraphNode(String label, IconData icon, Color color,
      {bool isLarge = false}) {
    return Container(
      width: isLarge ? 120 : 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isLarge ? 28 : 20),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildGraphArrow(IconData icon) {
    return Icon(icon, color: Colors.white10, size: 16);
  }

  Widget _buildVerticalArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Icon(Icons.arrow_downward, color: Colors.white10, size: 16),
    );
  }

  Widget _buildVisualLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem("STABLE", Colors.greenAccent),
        const SizedBox(width: 16),
        _buildLegendItem("ACTIVE", Colors.pinkAccent),
        const SizedBox(width: 16),
        _buildLegendItem("SYNC", Colors.blueAccent),
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.outfit(
                color: Colors.white24,
                fontSize: 9,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMatrixTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildMatrixRow("HOST_LISTENER", "WAKE WORD", "⚡⚡⚡⚡"),
          _buildMatrixRow("BRAIN_MEMORY", "SHARED_PREFS", "📚"),
          _buildMatrixRow("VOCAL_SYNTH", "NEURAL_TTS", "🌸"),
          _buildMatrixRow("PERSONA_DNA", "SYST_PROMPT", "💖"),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(String item, String sys, String priority) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Text(sys,
                  style:
                      GoogleFonts.outfit(color: Colors.white38, fontSize: 9)),
            ],
          ),
          Text(priority, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTechnicalDeepDive(String file, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              color: Colors.pinkAccent, size: 16),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file,
                    style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                Text(desc,
                    style: GoogleFonts.outfit(
                        color: Colors.white30, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Q: $q",
              style: GoogleFonts.outfit(
                  color: Colors.pinkAccent.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("A: $a",
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTheoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
