# Performance Optimization Guide for Anime Waifu App

## Identified Performance Bottlenecks

### 1. **Font Loading (CRITICAL)**
- **Issue**: GoogleFonts loaded inline in build methods causes expensive rendering
- **Impact**: Every rebuild reloads fonts, causing 100-200ms+ jank
- **Solution**: Use cached `AppTextStyles` from `performance_utils.dart`
```dart
// ❌ SLOW - Recreates style every frame
Text('Hello', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600))

// ✅ FAST - Uses cached style
Text('Hello', style: AppTextStyles.outfit14w600)
```

### 2. **Widget Tree Rebuilds**
- **Issue**: Non-const constructors force full subtree rebuilds
- **Impact**: Creates excessive widget instances and layout passes
- **Solution**: Mark all widgets as `const` where possible
```dart
// ❌ Always rebuilds
Container(
  color: Colors.blue,
  child: const Text('Static'),
)

// ✅ Only rebuilds parent
const SizedBox(width: 16, height: 16)
```

### 3. **Service Initialization**
- **Issue**: 50+ services loading synchronously on app startup
- **Impact**: 3-5 second startup delay, blocks UI thread
- **Solution**: Use `LazyServiceLoader` in `lazy_service_loader.dart`
```dart
// Critical only: Auth, Settings, Theme
// Defer: Analytics, Memory, Emotion services until needed
```

### 4. **ListView Performance**
- **Issue**: Using `ListView` instead of `ListView.builder` for large lists
- **Impact**: All items rendered in memory at once
- **Solution**: Always use `.builder` with `addAutomaticKeepAlives: false` for scroll performance

### 5. **Image Caching**
- **Issue**: Network images not cached properly
- **Impact**: Repeated downloads, storage thrashing
- **Solution**: Use `cached_network_image` package, configure cache limits

### 6. **Animation Overhead**
- **Issue**: Multiple animations running simultaneously on complex pages
- **Impact**: 60fps → 30fps on complex screens
- **Solution**: Respect `MediaQuery.disableAnimations` setting

### 7. **Provider Rebuilds**
- **Issue**: Broad provider watches trigger full widget tree rebuilds
- **Impact**: Changing one value rebuilds entire subtree
- **Solution**: Use `.select()` to watch specific properties only

## Implementation Priority

### Phase 1 (HIGH): Quick Wins (1-2 hours)
1. ✅ Replace inline `GoogleFonts` with `AppTextStyles` cache
2. ✅ Add more `const` constructors throughout app
3. ✅ Enable ProGuard/R8 in release build (already done)

### Phase 2 (MEDIUM): Architecture (2-4 hours)
1. ✅ Implement `LazyServiceLoader` for deferred initialization
2. ✅ Split providers for selective updates
3. ✅ Implement image caching configuration

### Phase 3 (LOW): Polish (1-2 hours)
1. Optimize animations
2. Add frame rate monitoring in debug mode
3. Create performance benchmarks

## Testing Performance

### Debug Command
```bash
flutter run --profile  # Profile mode captures real performance
flutter run --release  # Final optimized build
```

### Key Metrics to Monitor
- **Startup Time**: Target < 2 seconds (from app launch to home screen)
- **Frame Rate**: Target 60 FPS constant (no jank >16ms frames)
- **Memory**: Target < 150 MB on Android (varies by device)
- **First Meaningful Paint**: Target < 1 second

### Profiling Tools
- Flutter DevTools: `flutter pub global activate devtools && devtools`
- Android Profile: `android/gradlew profile`
- Memory Monitor: Built into DevTools

## Validation Checklist

- [ ] All GoogleFonts replaced with AppTextStyles
- [ ] Const constructors added to stateless widgets
- [ ] ListView converted to ListView.builder where appropriate
- [ ] Services registered in LazyServiceLoader
- [ ] Image cache configured
- [ ] No warnings in `flutter analyze`
- [ ] Startup time < 2 seconds in profile mode
- [ ] No jank visible in 60 FPS gameplay
- [ ] Memory stable after 5 mins of interaction

## Quick Reference

### File Locations for Optimization Utilities
- `lib/utils/performance_utils.dart` - Cached text styles & monitoring
- `lib/utils/lazy_service_loader.dart` - Deferred service loading
- `lib/config/performance_config.dart` - Optimization settings

### Common Slow Patterns to Avoid
```dart
// ❌ Slow
- Text(..., style: GoogleFonts.outfit(...))
- Container(child: dynamic_child) // no const
- ListView(children: big_list) // renders all at once
- Watch broad Provider<Entire State>
- ImageCache with unlimited size
- Heavy computations in build()
```

```dart
// ✅ Fast
- Text(..., style: AppTextStyles.outfitXXX)
- const Container(...) // precompiled
- ListView.builder(...) // lazy loads
- Watch .select((state) => state.field)
- Configure ImageCache limits
- Cache computed values in initState
```

## Notes for Future Work

1. Consider migrating to Riverpod for better performance tracking
2. Add Service Worker for offline-first architecture
3. Implement code splitting for large feature modules
4. Add A/B testing framework for performance regression detection
5. Profile database queries for Firestore optimization
