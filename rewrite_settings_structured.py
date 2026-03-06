import re

def process():
    with open('e:/jagan/Flutter/anime_waifu/lib/screens/main_settings.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to inject the _buildSectionCard helper
    helper = """
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(icon, color: Colors.white54, size: 18),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
"""

    if "_buildSectionCard" not in content:
        # insert before _buildSettingsHero
        content = content.replace("  Widget _buildSettingsHero()", helper + "\n  Widget _buildSettingsHero()")

    # 1. VOICE & ASSISTANT
    # Find the start of VOICE & ASSISTANT section
    va_match = re.search(r"(\s*)// ── VOICE & ASSISTANT ────────────────────────────────────\s*Text\('VOICE & ASSISTANT'[^\;]+\;\s*const SizedBox\(height: 10\);", content)
    if va_match:
        # replace with _buildSectionCard
        content = content[:va_match.start()] + va_match.group(1) + "_buildSectionCard(\n  title: 'VOICE & ASSISTANT',\n  icon: Icons.record_voice_over_rounded,\n  children: [" + content[va_match.end():]
        # find the end of the section (just before AI PERSONA)
        ap_match = re.search(r"(\s*)const SizedBox\(height: 16\);\s*// ── AI PERSONA", content)
        if ap_match:
            content = content[:ap_match.start()] + "\n  ],\n)," + content[ap_match.end(1):]

    # 2. AI PERSONA
    re_ap = re.search(r"(\s*)// ── AI PERSONA ────────────────────────────────────────────\s*Text\('AI PERSONA'[^\;]+\;\s*const SizedBox\(height: 10\);", content)
    if re_ap:
        content = content[:re_ap.start()] + re_ap.group(1) + "_buildSectionCard(\n  title: 'AI PERSONA',\n  icon: Icons.theater_comedy,\n  children: [" + content[re_ap.end():]
        mem_match = re.search(r"(\s*)const SizedBox\(height: 16\);\s*// ── MEMORY", content)
        if mem_match:
            content = content[:mem_match.start()] + "\n  ],\n)," + content[mem_match.end(1):]

    # 3. MEMORY
    re_mem = re.search(r"(\s*)// ── MEMORY ────────────────────────────────────────────────\s*Text\('MEMORY'[^\;]+\;\s*const SizedBox\(height: 10\);", content)
    if re_mem:
        content = content[:re_mem.start()] + re_mem.group(1) + "_buildSectionCard(\n  title: 'MEMORY',\n  icon: Icons.psychology,\n  children: [" + content[re_mem.end():]
        tools_match = re.search(r"(\s*)const SizedBox\(height: 16\);\s*// ── APPS & TOOLS", content)
        if tools_match:
            content = content[:tools_match.start()] + "\n  ],\n)," + content[tools_match.end(1):]

    # 4. APPS & TOOLS (first one)
    re_tools = re.search(r"(\s*)// ── APPS & TOOLS ──────────────────────────────────────────\s*Text\('APPS & TOOLS'[^\;]+\;\s*const SizedBox\(height: 10\);", content)
    if re_tools:
        content = content[:re_tools.start()] + re_tools.group(1) + "_buildSectionCard(\n  title: 'APPS & TOOLS',\n  icon: Icons.apps_rounded,\n  children: [" + content[re_tools.end():]
        ve_match = re.search(r"(\s*)const SizedBox\(height: 16\);\s*// ── VOICE ENGINE", content)
        if ve_match:
            content = content[:ve_match.start()] + "\n  ],\n)," + content[ve_match.end(1):]

    # 5. VOICE ENGINE
    re_ve = re.search(r"(\s*)// ── VOICE ENGINE ──────────────────────────────────────────\s*Text\('VOICE ENGINE'[^\;]+\;\s*const SizedBox\(height: 10\);", content)
    if re_ve:
        content = content[:re_ve.start()] + re_ve.group(1) + "_buildSectionCard(\n  title: 'VOICE ENGINE & STT',\n  icon: Icons.mic,\n  children: [" + content[re_ve.end():]
        # Ends at CHAT & DISPLAY
        chat_match = re.search(r"(\s*)const SizedBox\(height: 16\);\s*// ── CHAT & DISPLAY", content)
        if chat_match:
            content = content[:chat_match.start()] + "\n  ],\n)," + content[chat_match.end(1):]

    # 6. CHAT & DISPLAY
    re_chat = re.search(r"(\s*)// ── CHAT & DISPLAY ────────────────────────────────────────\s*Text\('CHAT & DISPLAY'[^\;]+\;\s*const SizedBox\(height: 10\);", content)
    if re_chat:
        content = content[:re_chat.start()] + re_chat.group(1) + "_buildSectionCard(\n  title: 'CHAT & DISPLAY',\n  icon: Icons.chat_bubble_outline,\n  children: [" + content[re_chat.end():]
        ds_match = re.search(r"(\s*)const SizedBox\(height: 20\);\s*// ── DATA & STORAGE", content)
        if ds_match:
            content = content[:ds_match.start()] + "\n  ],\n)," + content[ds_match.end(1):]

    # 7. DATA & STORAGE
    re_ds = re.search(r"(\s*)// ── DATA & STORAGE ────────────────────────────────────────\s*Text\('DATA & STORAGE'[^\;]+\;\s*const SizedBox\(height: 10\);", content)
    if re_ds:
        content = content[:re_ds.start()] + re_ds.group(1) + "_buildSectionCard(\n  title: 'DATA & STORAGE',\n  icon: Icons.storage,\n  children: [" + content[re_ds.end():]
        # Ends at the second APPS & TOOLS
        tools2_match = re.search(r"(\s*)const SizedBox\(height: 20\);\s*// ── APPS & TOOLS", content)
        if tools2_match:
            content = content[:tools2_match.start()] + "\n  ],\n)," + content[tools2_match.end(1):]

    # 8. APPS & TOOLS (second one -> CUSTOMIZATION)
    re_t2 = re.search(r"(\s*)// ── APPS & TOOLS ──────────────────────────────────────────\s*Text\('APPS & TOOLS'[^\;]+\;\s*const SizedBox\(height: 10\);", content)
    if re_t2:
        content = content[:re_t2.start()] + re_t2.group(1) + "_buildSectionCard(\n  title: 'CUSTOMIZATION',\n  icon: Icons.palette,\n  children: [" + content[re_t2.end():]
        # Ends at the end of the children array of SingleChildScrollView column
        end_match = re.search(r"(\s*)],\s*\),\s*\),\s*\),\s*],\s*\),\s*\);\s*\}", content)
        if end_match:
            content = content[:end_match.start()] + "\n  ],\n)," + content[end_match.start(1):]

    # Modify _settingsTile to remove borders and padding
    tile_search = r"Widget _settingsTile\(\{\s*.*?\)\s*\{\s*return Container\(\s*margin: const EdgeInsets.only\(bottom: 10\),\s*padding: const EdgeInsets.symmetric\(horizontal: 16, vertical: 12\),\s*decoration: BoxDecoration\([^\}]+?\),\s*child: Row\("
    tile_replace = r"""Widget _settingsTile({
  required IconData icon,
  required String label,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
  required Color activeColor,
}) {
  return InkWell(
    onTap: () => onChanged(!value),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.02))),
      ),
      child: Row("""
    content = re.sub(tile_search, tile_replace, content, flags=re.DOTALL)

    # Note: I need to handle `_buildToolShortcut` as well
    tool_search = r"Widget _buildToolShortcut\(.*?child: Container\(\s*padding: const EdgeInsets.all\(14\),\s*decoration: BoxDecoration\(\s*color: Colors.white.withValues\(alpha: 0.04\),\s*borderRadius: BorderRadius.circular\(12\),\s*border: Border.all\(color: Colors.white10\),\s*\),"
    tool_replace = r"""Widget _buildToolShortcut({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.02))),
          ),"""
    
    # Actually _buildToolShortcut starts a bit higher, let's just do a string replace
    old_tool = """  Widget _buildToolShortcut({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),"""
    
    new_tool = """  Widget _buildToolShortcut({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.02))),
          ),"""
    content = content.replace(old_tool, new_tool)

    # Also fix some of the specific containers inside the list like the sliders!
    slider_search = r"Container\(\s*margin: const EdgeInsets.only\(bottom: 10\),\s*padding: const EdgeInsets.all\(14\),\s*decoration: BoxDecoration\(\s*color: Colors.white.withValues\(alpha: 0.04\),\s*borderRadius: BorderRadius.circular\(12\),\s*border: Border.all\(color: Colors.white10\),\s*\),"
    slider_replace = r"""Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.02))),
                    ),"""
    content = re.sub(slider_search, slider_replace, content)

    with open('e:/jagan/Flutter/anime_waifu/lib/screens/main_settings.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
