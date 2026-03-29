# v5.0.0 — Neural Notification & Communication Update
# 30+ structured commits for the complete update

# Reset staging area
git reset HEAD

# ═══════════════════════════════════════════════════
#  COMMIT 1-5: Core API Migration (MailJet → Brevo)
# ═══════════════════════════════════════════════════

# 1. Brevo API endpoint migration
git add lib/api_call.dart
git commit -m "feat(api): migrate email service from MailJet to Brevo SMTP API"

# 2. Settings provider update
git add lib/core/providers/settings_provider.dart
git commit -m "refactor(settings): replace MailJet credentials with Brevo API key"

# 3. Main.dart dev config UI
git add lib/main.dart
git commit -m "feat(ui): update dev config UI for Brevo API key management"

# 4. Dev config screen migration
git add lib/screens/main_dev_config.dart
git commit -m "refactor(dev-config): replace MailJet UI with Brevo key configuration"

# 5. Debug screen reset logic
git add lib/screens/main_debug.dart
git commit -m "fix(debug): update API key reset to clear Brevo key instead of MailJet"

# ═══════════════════════════════════════════════════
#  COMMIT 6-10: Email Template System
# ═══════════════════════════════════════════════════

# 6. New email template asset
git add assets/template/
git commit -m "feat(template): add premium Darling Alert HTML email template"

# 7. Environment config update
git add .example.env
git commit -m "docs(env): update .example.env with Brevo API key requirement"

# 8. Test mail script
git add test_mail.dart
git commit -m "feat(test): add Brevo email test script with real template loading"

# 9. Template extraction helper
git add extract_avatar.dart
git commit -m "chore(tools): add avatar extraction script for template image hosting"

# 10. Template update helper
git add update_template.dart
git commit -m "chore(tools): add template update script for base64 to URL migration"

# ═══════════════════════════════════════════════════
#  COMMIT 11-15: Version Bump & UI Updates
# ═══════════════════════════════════════════════════

# 11. Version bump in pubspec
git add pubspec.yaml
git commit -m "chore(version): bump app version to 5.0.0+1"

# 12. Lock file update
git add pubspec.lock
git commit -m "chore(deps): update pubspec.lock with google_sign_in v6 pin"

# 13. Settings page version update
git add lib/screens/main_settings.dart
git commit -m "feat(settings): update version display to v5.0.0"

# 14. About page version update
git add lib/screens/about_page.dart
git commit -m "feat(about): update version chip to v5.0.0"

# 15. Chat export version update
git add lib/screens/chat_share_export_page.dart
git commit -m "feat(export): update export metadata version to v5.0.0"

# ═══════════════════════════════════════════════════
#  COMMIT 16-20: Bug Fixes & Stability
# ═══════════════════════════════════════════════════

# 16. Google Sign-In compatibility fix
git add lib/screens/login_screen.dart
git commit -m "fix(auth): pin google_sign_in to v6.x for API compatibility"

# 17. File intelligence cleanup
git add lib/screens/file_intelligence_page.dart
git commit -m "fix(lint): remove unused _pathCtrl TextEditingController"

# 18. Wake word threshold tuning
git add lib/load_wakeword_code.dart
git commit -m "perf(wakeword): raise detection floor from 0.90 to 0.95 for precision"

# 19. README documentation
git add README.md
git commit -m "docs(readme): add v5.0.0 Neural Notification update and Phase 4 docs"

# 20. Background insights page
git add lib/screens/background_insights_page.dart
git commit -m "feat(ui): add background insights page for system monitoring"

# ═══════════════════════════════════════════════════
#  COMMIT 21-25: Wake Word & Model Updates
# ═══════════════════════════════════════════════════

# 21. ONNX model update
git add assets/wakeword/
git commit -m "feat(wakeword): update ONNX neural classifier model weights"

# 22. Native Android wake audio
git add android/app/src/main/kotlin/com/example/anime_waifu/WakeAudioCapture.kt
git commit -m "feat(android): optimize WakeAudioCapture native bridge"

# 23. Foreground service updates
git add android/app/src/main/kotlin/com/example/anime_waifu/AssistantForegroundService.kt
git commit -m "fix(android): improve foreground service reliability"

# 24. Plugin registrant
git add android/app/src/main/kotlin/com/example/anime_waifu/MainActivity.kt
git commit -m "chore(android): update MainActivity plugin registration"

# 25. Image gen service
git add lib/services/image_gen_service.dart
git commit -m "fix(imagegen): stabilize AI image generation service"

# ═══════════════════════════════════════════════════
#  COMMIT 26-30: Platform & Misc
# ═══════════════════════════════════════════════════

# 26. iOS config
git add ios/
git commit -m "chore(ios): sync iOS generated config files"

# 27. macOS config
git add macos/
git commit -m "chore(macos): sync macOS Flutter generated configs"

# 28. Logcat debug files
git add logcat*.txt
git commit -m "chore(debug): add logcat debug traces for wake word analysis"

# 29. Model documentation
git add model_doc.md
git commit -m "docs(model): add ONNX wake word model architecture documentation"

# 30. Test scripts
git add test_wake*.py
git commit -m "chore(test): add wake word Python verification test scripts"

# ═══════════════════════════════════════════════════
#  Catch any remaining files
# ═══════════════════════════════════════════════════
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m "chore: sync remaining project files for v5.0.0 release"
}

Write-Host ""
Write-Host "═══════════════════════════════════════"
Write-Host "  All commits created! Pushing now..."
Write-Host "═══════════════════════════════════════"

git push origin main

Write-Host ""
Write-Host "✅ v5.0.0 Neural Notification Update pushed!"
git log --oneline -35
