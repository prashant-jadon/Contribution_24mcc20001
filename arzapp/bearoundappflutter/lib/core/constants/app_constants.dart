class AppConstants {
  // App Info
  static const String appName = 'arz';
  static const String appTagline = 'Talk to people you already know';
  
  // API Configuration
  static const String baseUrl = 'https://arz-backend.vercel.app/api/v1';
  static const String wsUrl = 'ws://arz-backend.vercel.app';
  static const String apiVersion = 'v1';
  
  // Deep Links
  static const String deepLinkScheme = 'arz.vercel.app';
  static const String profileLinkBase = 'https://arz.vercel.app';
  
  // OneSignal
  static const String oneSignalAppId = '01021009-406f-4d7a-8f89-4456aa40dcc0';
  
  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_completed';
  
  // Limits
  static const int maxPhotos = 4;
  static const int maxBioLength = 500;
  static const int maxMessageLength = 2000;
  static const int maxInterests = 10;
  
  // Request Settings
  static const int requestExpiryDays = 7;
  static const int defaultDailyFreeRequests = 2;
  static const int defaultDailyFreeDiscovery = 50;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border Radius
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  // Interests List
  static const List<String> availableInterests = [
    'Travel',
    'Music',
    'Photography',
    'Gaming',
    'Fitness',
    'Food',
    'Movies',
    'Reading',
    'Art',
    'Dance',
    'Sports',
    'Technology',
    'Fashion',
    'Nature',
    'Cooking',
    'Yoga',
    'Coffee',
    'Wine',
    'Hiking',
    'Pets',
  ];

  // Relationship Intents (display text)
  static const List<String> relationshipIntents = [
    'Serious relationship',
    'Casual dating',
    'Friendship',
    'Still figuring it out',
  ];

  // Map display text to backend values
  static String? getRelationshipIntentValue(String? displayText) {
    if (displayText == null) return null;
    switch (displayText) {
      case 'Serious relationship':
        return 'serious';
      case 'Casual dating':
        return 'casual';
      case 'Friendship':
        return 'friendship';
      case 'Still figuring it out':
        return 'not_sure';
      default:
        return null;
    }
  }

  // Genders (display text)
  static const List<String> genders = [
    'Male',
    'Female',
    'Non-binary',
    'Other',
  ];

  // Interested In options (display text)
  static const List<String> interestedInOptions = [
    'Men',
    'Women',
    'Everyone',
  ];

  // Map display gender to backend enum value
  static String? getBackendGender(String? displayGender) {
    if (displayGender == null) return null;
    switch (displayGender.toLowerCase()) {
      case 'male':
        return 'male';
      case 'female':
        return 'female';
      case 'non-binary':
        return 'non-binary';
      case 'other':
        return 'other';
      default:
        return null;
    }
  }

  // Map display "interested in" to backend enum value
  static String? getBackendInterestedIn(String? displayText) {
    if (displayText == null) return null;
    switch (displayText.toLowerCase()) {
      case 'men':
        return 'male';
      case 'women':
        return 'female';
      case 'everyone':
        return 'everyone';
      default:
        return null;
    }
  }

  // Map backend "interested in" value to display text
  static String? getDisplayInterestedIn(String? backendValue) {
    if (backendValue == null) return null;
    switch (backendValue.toLowerCase()) {
      case 'male':
        return 'Men';
      case 'female':
        return 'Women';
      case 'everyone':
        return 'Everyone';
      default:
        return null;
    }
  }
}

