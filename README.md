# O2-WAIFU

O2-WAIFU is a Flutter voice-companion app with state-aware behavior across chat screen, other in-app screens, and full background mode. It combines wake-word input, speech-to-text, LLM replies, text-to-speech, proactive check-ins, and persistent chat history in one app.

## What This App Does

- Maintains a conversation with local message memory and bounded history.
- Supports typed chat and voice chat.
- Uses wake-word detection to trigger voice capture.
- Sends user text to API and appends assistant replies to chat.
- Speaks responses with TTS (single voice or dual-voice alternating mode).
- Saves notification-driven messages and restores them into chat after app resume.

## State-Dependent Interaction Logic

### 1) Chat Screen Idle Logic
- Idle timer only runs on chat screen while app is in foreground.
- Idle message is one-shot per user-message cycle.
- After idle fires once, it stays blocked until user sends a new message.

### 2) Foreground Non-Chat Logic
- On tabs like Settings, Themes, Dev Config, Debug, and About:
  - Proactive check-ins can generate notification-style updates.
  - Messages are persisted to notification history.

### 3) Background Logic
- Android foreground service handles proactive messages in background.
- Messages are shown as notifications and queued in storage.
- On app resume, queued proactive messages are inserted into chat history.
- Wake-word stays active when possible; background wake currently notifies and keeps wake engine alive rather than forcing full STT outside active UI.

## Feature List

### Chat and Voice
- Text chat input
- Wake-word listener (Porcupine)
- STT user capture
- TTS reply playback
- Dual-voice alternating output
- Auto-listen option

### Behavior Controls
- Wake Word on/off
- Wife Mode (proactive behavior)
- Idle Timer on/off + duration slider
- Background Assistant on/off
- Check-in mode:
  - Manual interval
  - Random interval pool (10m, 30m, 1h, 2h, 5h)

### Notifications and History
- Local notification updates for proactive messages
- Notification history list with clear/remove actions
- Pending proactive message drain into chat on resume

### Visual and Personalization
- Theme pages and styled chat bubbles
- Image pack switching (code image set)
- System image picker for chat image
- Launcher icon variant switch (Android aliases)
- Chat log assistant avatar rendering

### App Launch Actions
- Assistant can return strict launch format:
  - `Action: OPEN_APP`
  - `App: <name>`
- Android intent routing resolves app by package/name aliases.

### Video Section (Cloudinary)
- Episode list from Cloudinary resources
- Cloudinary Admin API source resolution by folder
- MP4 transformed URL preference for stable playback
- In-app player + landscape fullscreen player

### Dev and Debug
- API key/model/url/system prompt overrides
- Wake debug tools and quick action buttons
- Runtime state visibility for wake/STT/TTS/notifications

## Required Environment Variables

Use `.env` in project root.

Minimum for chat:
- `API_KEY`

Wake-word:
- `WAKE_WORD_KEY`

Cloudinary videos:
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`
- `CLOUDINARY_VIDEO_FOLDER`

Optional:
- `CLOUDINARY_VIDEO_PUBLIC_IDS`
- `CLOUDINARY_VIDEO_URLS`

## Build and Run

Install deps:

```bash
flutter pub get
```

Run debug:

```bash
flutter run
```

Build debug APK:

```bash
flutter build apk --debug
```

Build release APK:

```bash
flutter build apk --release
```

Build Play Store bundle:

```bash
flutter build appbundle --release
```

## Background Reliability Checklist (Android)

- Grant microphone permission.
- Grant notifications permission.
- Set battery to Unrestricted for the app.
- Keep Background Assistant enabled.
- Reinstall app after manifest/service-level changes.

## Troubleshooting

### Wake word works in foreground but not after minimizing
- Confirm Background Assistant is ON.
- Confirm mic permission is still granted.
- Disable battery optimization for app.
- Rebuild and reinstall latest APK.

### Video player shows ExoPlayer HTTP/source errors
- Confirm Cloudinary assets are public.
- Confirm `CLOUDINARY_*` values in `.env` are correct.
- Confirm folder value matches `asset_folder` in Cloudinary.
- Prefer transformed MP4 URLs (already handled by app).

### App-open command reply not launching target app
- Ensure assistant reply follows exact two-line format.
- Confirm app is installed on device.
- Try known alias name supported by mapping.

## Security Note

Do not commit real API keys or secrets to public repositories.
Use local `.env` for development and secret management for production pipelines.
