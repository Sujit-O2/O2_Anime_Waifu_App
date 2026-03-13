# Enhanced Animations & Launcher-Style UI

Inspired by **Nova Launcher** (smooth page transitions, spring-physics icons, parallax wallpaper) and **Microsoft Launcher** (card-based widgets, clock overlay, floating quick actions), this plan adds a deep animation layer on top of the existing particle/pulse system — making the waifu feel truly alive and the UI premium.

---

## Proposed Changes

### 1. New Widget — `WaifuCharacterWidget`

#### [NEW] [waifu_character_widget.dart](file:///e:/jagan/Flutter/anime_waifu/lib/widgets/waifu_character_widget.dart)

A self-contained, performance-isolated widget that renders the character with layered animations:

| Animation | Mechanic | Trigger |
|---|---|---|
| **Idle Breathing** | `scale` 1.0 → 1.022, sinusoidal, 3s | Always on |
| **Eye Blink** | `scaleY` 1.0 → 0.05 → 1.0, 150ms | Random timer 4–7s |
| **Hair/Fringe Float** | `translateX` ±3px, 2.5s sine | Always on, offset phase |
| **Aura Glow Ring** | RadialGradient opacity pulse, 3 rings | Idle / Listening / Speaking |
| **Jaw / Mouth Glow** | Pink bloom radius 8–18px | `isSpeaking == true` |
| **Entrance** | Slide-from-bottom + fade, `ElasticOut` | Widget first build |

```dart
// Usage (drop into existing chat home screen):
WaifuCharacterWidget(
  imagePath: _chatImageAsset,
  isSpeaking: _isSpeaking,
  isListening: _isAutoListening,
  size: 160,
)
```

All animation controllers inside `TickerProviderStateMixin`. Wrapped in `RepaintBoundary`.

---

### 2. Upgrade [ReactivePulse](file:///e:/jagan/Flutter/anime_waifu/lib/widgets/reactive_pulse.dart#3-20) → Audio-Reactive Wave Bars

#### [MODIFY] [reactive_pulse.dart](file:///e:/jagan/Flutter/anime_waifu/lib/widgets/reactive_pulse.dart)

Replace the current 3 static rings with **5-bar animated equalizer bars** (FFT-style, like Nova Launcher's music widget):

- When `isListening`: bars animate modestly (0.3–0.7 amplitude, teal color).
- When `isSpeaking`: bars animate energetically (0.6–1.0 amplitude, pink).
- When idle: bars show a gentle breathing wave.
- Painted via `CustomPainter` with `RRect` bars, GPU friendly.
- Still wrapped in `RepaintBoundary`.

---

### 3. Nova Launcher–Inspired Parallax Background

#### [MODIFY] [animated_background.dart](file:///e:/jagan/Flutter/anime_waifu/lib/widgets/animated_background.dart)

Add a **parallax depth layer** on top of the existing particle system:

- Detect `GestureDetector.onPanUpdate` (already present) and apply a `Transform.translate` of `±8px` to the character layer and `±4px` to the gradient layer — creating depth.
- Add a `MorphingBlobPainter` (animated [Path](file:///e:/jagan/Flutter/anime_waifu/lib/main.dart#1107-1127) cubic bezier blob) behind the character — gives an organic "aura" feel inspired by Nova Launcher's live wallpapers.
- **No new packages** needed — pure Flutter canvas.

---

### 4. Spring-Physics Icon Press & Page Transitions

#### [MODIFY] [main.dart](file:///e:/jagan/Flutter/anime_waifu/lib/main.dart) — Nav & Chat Scaffold

**A) Spring Icon Press:** Wrap every navigation button / quick-action pill in a `_SpringButton` helper widget:
```dart
class _SpringButton extends StatefulWidget {
  // Animates scale: 1.0 → 0.90 on tap-down, spring back to 1.0 on tap-up
  // Uses SpringSimulation physics (mass=1, stiffness=600, damping=30)
}
```

**B) Nova-style page transitions:** Replace current `PageRouteBuilder` (if any) with a shared custom route:
```dart
Route _buildSlideSpringRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) {
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
          .animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    );
  },
  transitionDuration: const Duration(milliseconds: 320),
);
```

---

### 5. Chat Bubble Entrance Animations

#### [MODIFY] [main.dart](file:///e:/jagan/Flutter/anime_waifu/lib/main.dart) — `_buildChatBubble`

Wrap each bubble in an `AnimatedSlide` + `AnimatedOpacity`:
```dart
AnimatedSlide(
  offset: _appeared ? Offset.zero : Offset(isUser ? 0.08 : -0.08, 0),
  duration: const Duration(milliseconds: 280),
  curve: Curves.easeOutCubic,
  child: AnimatedOpacity(opacity: _appeared ? 1.0 : 0.0, ...),
)
```
Use `didUpdateWidget` / [initState](file:///e:/jagan/Flutter/anime_waifu/lib/main.dart#5937-5961) to set `_appeared = true` with a micro-delay.

---

### 6. Animated Clock + Weather Mini-Widget (Microsoft Launcher Inspired)

#### [NEW] [launcher_clock_widget.dart](file:///e:/jagan/Flutter/anime_waifu/lib/widgets/launcher_clock_widget.dart)

A floating widget shown on the home screen above the character:
- **Clock**: Displays `HH:mm` via `Stream.periodic`, animates digit changes with `AnimatedSwitcher` (vertical slide).
- **Date**: e.g. "Sat, 14 Mar" in light weight below.
- **Weather**: If `_lastWeather` is available, shows icon + temp with a subtle slide-in.
- Floats with a `Transform.translate` tied to the existing `_floatController` in [main.dart](file:///e:/jagan/Flutter/anime_waifu/lib/main.dart) (reuse, no extra controller).
- Wrapped in `RepaintBoundary` — only rebuilds on second tick.

---

### 7. `ShimmerText` Greeting

#### [MODIFY] [zero_two_welcome_card.dart](file:///e:/jagan/Flutter/anime_waifu/lib/widgets/zero_two_welcome_card.dart)

Replace the plain [Text(_greeting)](file:///e:/jagan/Flutter/anime_waifu/lib/main.dart#2748-2990) with a `ShimmerText` that sweeps a highlight gradient:
```dart
ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    colors: [color, Colors.white, color],
    stops: [0, _shimCtrl.value, 1],
  ).createShader(bounds),
  child: Text(_greeting, style: ...),
)
```
Uses the existing `_glowCtrl` offset — zero extra controllers.

---

### 8. Swipe-Up App Quick-Launch Panel (Nova Drawer Inspired)

#### [MODIFY] [main.dart](file:///e:/jagan/Flutter/anime_waifu/lib/main.dart) — Home Tab

Add a `DraggableScrollableSheet` triggered by swipe-up on the home tab:
- Shows a `GridView` of the user's top 9 most-used apps (fetched via [open_app_service.dart](file:///e:/jagan/Flutter/anime_waifu/lib/services/open_app_service.dart) which already lists packages).
- Each icon uses the `_SpringButton` wrapper from item 4.
- Background: `BackdropFilter(ImageFilter.blur)` + dark glassmorphism — Microsoft Launcher style.
- Smooth sheet handle + drag animation; dismisses by swiping back down.

---

## Verification Plan

> [!NOTE]
> This project has no unit/widget test files that cover UI animations. Verification is done via hot-reload visual inspection and a release build.

### Automated Build Test
```powershell
# In e:\jagan\Flutter\anime_waifu
flutter analyze        # No new errors
flutter build apk --release  # Must complete successfully
```

### Manual Visual Verification (On Device / Emulator)
1. **WaifuCharacterWidget** – Open app → watch character on chat screen for 10s → confirm breathing scale, random blink, hair float.
2. **Speaking animation** – Tap mic → speak → confirm pink aura + jaw glow activate during TTS playback.
3. **Parallax** – On home/chat screen, drag finger → confirm background shifts at different depth than foreground.
4. **Spring Buttons** – Tap any nav button / quick-action pill → confirm 0.90 squish + spring-back feel.
5. **Page Transitions** – Navigate to any screen → confirm smooth slide+fade (not hard cut).
6. **Chat Bubble Entrance** – Send a message → confirm bubble slides in from right edge.
7. **Equalizer Bars** – Toggle mic → confirm bars animate; tap stop → bars settle.
8. **Clock Widget** – On home screen, wait 1 minute → confirm digit flips with animation.
9. **Swipe-Up Drawer** – Swipe up on home tab → confirm glassmorphism drawer reveals icon grid.
10. **FPS Check** – Run `flutter run --profile` and open Flutter DevTools → confirm animations hold 60fps.
