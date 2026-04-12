/// Constants file for anime_waifu application
/// Centralized configuration for all app constants
library;

// ============================================================================
// FIRESTORE COLLECTION NAMES
// ============================================================================

class FirestoreCollections {
  // User & Profile Collections
  static const String users = 'users';
  static const String userProfiles = 'user_profiles';
  static const String userStats = 'user_stats';
  static const String devices = 'devices';

  // Character & Content Collections
  static const String characters = 'characters';
  static const String characterAffection = 'character_affection';
  static const String characterVault = 'character_vault';
  static const String characterCustomization = 'character_customization';

  // Social & Interaction Collections
  static const String messages = 'messages';
  static const String notifications = 'notifications';
  static const String reminderSettings = 'reminder_settings';
  static const String notificationPreferences = 'notification_preferences';

  // Voice & AR Collections
  static const String voiceCommandHistory = 'voice_command_history';
  static const String voiceSettings = 'voice_settings';
  static const String arSettings = 'ar_settings';
  static const String arStatistics = 'ar_statistics';
  static const String locationArContent = 'location_ar_content';

  // Social Features Collections
  static const String leaderboard = 'leaderboard';
  static const String globalQuests = 'global_quests';
  static const String questCompletions = 'quest_completions';
  static const String achievements = 'achievements';
  static const String friends = 'friends';
  static const String activityFeed = 'activity_feed';

  // Offline & Sync Collections
  static const String pendingOperations = 'pending_operations';
  static const String offlineSessions = 'offline_sessions';

  // Admin & Analytics Collections
  static const String adminUsers = 'admin_users';
  static const String adminLogs = 'admin_logs';
  static const String reportedContent = 'reported_content';
  static const String systemAnnouncements = 'system_announcements';
  static const String analyticsEvents = 'analytics_events';
  static const String crashReports = 'crash_reports';
  static const String performanceMetrics = 'performance_metrics';
  static const String userSessions = 'user_sessions';
  static const String performanceAlerts = 'performance_alerts';
}

// ============================================================================
// TIMEOUTS & DURATIONS
// ============================================================================

class AppTimeouts {
  // Network timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 60);
  static const Duration downloadTimeout = Duration(seconds: 45);

  // Database timeouts
  static const Duration queryTimeout = Duration(seconds: 15);
  static const Duration transactionTimeout = Duration(seconds: 30);

  // UI timeouts
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Debounce & throttle
  static const Duration debounceDelay = Duration(milliseconds: 180);
  static const Duration throttleDelay = Duration(milliseconds: 500);

  // Cache durations
  static const Duration imageCacheDuration = Duration(hours: 24);
  static const Duration dataCacheDuration = Duration(hours: 12);
  static const Duration sessionCacheDuration = Duration(minutes: 30);
}

// ============================================================================
// LIMITS & THRESHOLDS
// ============================================================================

class AppLimits {
  // List/Pagination limits
  static const int pageSize = 20;
  static const int maxCacheSize = 100;
  static const int maxListSize = 1000;

  // Message limits
  static const int minMessageLength = 1;
  static const int maxMessageLength = 1000;
  static const int maxMessages = 10000;

  // Affection system
  static const int maxAffectionLevel = 100;
  static const int affectionMilestoneStep = 10;
  static const int maxAffectionPointsPerMessage = 5;

  // Image limits
  static const int maxImageSize = 5242880; // 5MB
  static const int maxAvatarSize = 1048576; // 1MB
  static const int imageCacheCount = 100;

  // Voice commands
  static const int maxVoiceCommandDuration = 60; // seconds
  static const int maxVoiceHistory = 500;

  // Leaderboard
  static const int leaderboardTopCount = 100;
  static const int friendLeaderboardCount = 50;

  // Security
  static const int maxLoginAttempts = 5;
  static const int accountLockoutDuration = 15; // minutes
  static const int sessionExpiryTime = 24; // hours
}

// ============================================================================
// ERROR MESSAGES
// ============================================================================

class ErrorMessages {
  // Network errors
  static const String networkError = 'Network connection failed. Please check your internet.';
  static const String networkTimeout = 'Request timed out. Please try again.';
  static const String noConnection = 'No internet connection available';

  // Authority errors
  static const String unauthorized = 'You are not authorized to perform this action';
  static const String notFound = 'The resource was not found';
  static const String forbidden = 'Access forbidden';

  // Validation errors
  static const String invalidInput = 'Invalid input provided';
  static const String emptyField = 'This field cannot be empty';
  static const String messageEmpty = 'Message cannot be empty';
  static const String imageTooLarge = 'Image is too large. Maximum size is 5MB';

  // Authentication errors
  static const String invalidCredentials = 'Invalid email or password';
  static const String userNotFound = 'User not found';
  static const String userDisabled = 'This user account has been disabled';
  static const String tooManyAttempts = 'Too many login attempts. Please try again later';

  // Database errors
  static const String databaseError = 'Database error occurred. Please try again.';
  static const String savedSuccess = 'Saved successfully';
  static const String deleteSuccess = 'Deleted successfully';

  // Generic errors
  static const String unexpectedError = 'An unexpected error occurred';
  static const String tryAgain = 'Please try again';
  static const String offline = 'You are offline. Some features may not work';
}

// ============================================================================
// SUCCESS MESSAGES
// ============================================================================

class SuccessMessages {
  static const String messageSent = 'Message sent successfully';
  static const String characterCreated = 'Character created successfully';
  static const String characterUpdated = 'Character updated successfully';
  static const String characterDeleted = 'Character deleted successfully';
  static const String affectionUpdated = 'Affection level updated';
  static const String vaultItemAdded = 'Item added to vault';
  static const String reminderSet = 'Reminder set successfully';
  static const String announcementSent = 'Announcement sent to all users';
  static const String profileUpdated = 'Profile updated successfully';
  static const String settingsSaved = 'Settings saved successfully';
  static const String achievementUnlocked = 'Achievement unlocked!';
  static const String challengeCompleted = 'Challenge completed successfully';
}

// ============================================================================
// UI STRINGS
// ============================================================================

class UIStrings {
  // Navigation
  static const String home = 'Home';
  static const String chat = 'Chat';
  static const String quests = 'Quests';
  static const String leaderboard = 'Leaderboard';
  static const String settings = 'Settings';
  static const String profile = 'Profile';

  // Common buttons
  static const String send = 'Send';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String done = 'Done';
  static const String add = 'Add';
  static const String close = 'Close';
  static const String ok = 'OK';
  static const String retry = 'Retry';
  static const String back = 'Back';

  // Dialog titles
  static const String confirmation = 'Confirmation';
  static const String warning = 'Warning';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String info = 'Information';

  // Loading states
  static const String loading = 'Loading...';
  static const String loadingMore = 'Loading more...';
  static const String syncing = 'Syncing...';

  // Empty states
  static const String noMessages = 'No messages yet. Start chatting!';
  static const String noCharacters = 'No characters yet. Create one!';
  static const String noQuests = 'No quests available';
  static const String noNotifications = 'No notifications';
}

// ============================================================================
// API ENDPOINTS & EXTERNAL SERVICES
// ============================================================================

class APIConstants {
  // Firebase
  static const String firebaseProjectId = 'anime-waifu';

  // External APIs
  static const String hianimeBaseUrl = 'https://api.hianime.to';
  static const String consumetBaseUrl = 'https://api.consumet.org';

  // API endpoints
  static const String searchEndpoint = '/search';
  static const String detailsEndpoint = '/details';
  static const String streamingEndpoint = '/streaming';
}

// ============================================================================
// REGULAR EXPRESSIONS
// ============================================================================

class RegexPatterns {
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  static const String passwordRegex =
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$';

  static const String usernameRegex = r'^[a-zA-Z0-9_-]{3,16}$';

  static const String urlRegex =
      r'^(https?|ftp):\/\/[^\s/$.?#].[^\s]*$';

  static const String phoneRegex = r'^\+?1?\d{9,15}$';
}

// ============================================================================
// FEATURE FLAGS
// ============================================================================

class FeatureFlags {
  // Voice features
  static const bool enableVoiceRecognition = true;
  static const bool enableVoiceCommands = true;
  static const bool enableContinuousListening = true;

  // AR features
  static const bool enableARExperience = true;
  static const bool enableLocationBasedAR = true;
  static const bool enableARSelfies = true;

  // Social features
  static const bool enableLeaderboard = true;
  static const bool enableChallenges = true;
  static const bool enableSocialSharing = true;

  // Offline features
  static const bool enableOfflineMode = true;
  static const bool enableAutoSync = true;
  static const bool enableConflictResolution = true;

  // Performance features
  static const bool enablePerformanceMonitoring = true;
  static const bool enableCrashReporting = true;
  static const bool enableAnalytics = true;

  // Security features
  static const bool enableBiometricAuth = true;
  static const bool enableDeviceVerification = true;
  static const bool enableEncryption = true;
}

// ============================================================================
// SECURITY CONSTANTS
// ============================================================================

class SecurityConstants {
  // Encryption
  static const int encryptionKeyLength = 32; // 256-bit
  static const int encryptionIterations = 10000;
  static const String encryptionAlgorithm = 'AES-256';

  // Hashing
  static const int hashIterations = 100000;
  static const String hashAlgorithm = 'PBKDF2-SHA256';

  // Device fingerprinting
  static const int fingerprintCheckInterval = 3600; // 1 hour

  // Session management
  static const int sessionExpirySeconds = 86400; // 24 hours
  static const int refreshTokenExpirySeconds = 604800; // 7 days
}

// ============================================================================
// APPEARANCE CONSTANTS
// ============================================================================

class AppearanceConstants {
  // Padding & Margins
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // Text scales
  static const double textScaleSizeSmall = 12.0;
  static const double textScaleSizeMedium = 16.0;
  static const double textScaleSizeLarge = 20.0;
  static const double textScaleSizeXLarge = 24.0;
}

// ============================================================================
// MISC CONSTANTS
// ============================================================================

class MiscConstants {
  // Version
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;

  // Database
  static const String dbName = 'anime_waifu.db';
  static const int dbVersion = 1;

  // Analytics
  static const int analyticsEventBatchSize = 50;
  static const Duration analyticsBatchInterval = Duration(minutes: 5);

  // Misc
  static const String currencySymbol = '\$';
  static const String defaultLanguage = 'en';
}


