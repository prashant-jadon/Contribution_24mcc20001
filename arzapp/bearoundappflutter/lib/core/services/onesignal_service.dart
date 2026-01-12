import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  bool _isInitialized = false;
  String? _playerId;
  final _apiService = ApiService();

  bool get isInitialized => _isInitialized;
  String? get playerId => _playerId;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set app ID
      OneSignal.initialize(AppConstants.oneSignalAppId);

      // Request permission for notifications
      OneSignal.Notifications.requestPermission(true);

      // Set up notification handlers
      _setupNotificationHandlers();

      // Wait a bit for OneSignal to fully initialize
      await Future.delayed(const Duration(milliseconds: 1000));

      // Get player ID
      try {
        final subscriptionState = OneSignal.User.pushSubscription;
        final playerId = subscriptionState.id;
        if (playerId != null && playerId.isNotEmpty) {
          _playerId = playerId;
          debugPrint('OneSignal Player ID: $_playerId');
          // Try to send to backend (will only work if user is authenticated)
          await _sendPlayerIdToBackend();
        } else {
          debugPrint('OneSignal Player ID not available yet');
        }
      } catch (e) {
        debugPrint('Error getting initial player ID: $e');
      }

      // Listen for player ID changes
      OneSignal.User.pushSubscription.addObserver((state) {
        final newPlayerId = state.current.id;
        if (newPlayerId != null && newPlayerId.isNotEmpty && newPlayerId != _playerId) {
          _playerId = newPlayerId;
          debugPrint('OneSignal Player ID updated: $_playerId');
          _sendPlayerIdToBackend();
        }
      });

      // Notification click handler will be set up by NotificationHandler

      _isInitialized = true;
      debugPrint('OneSignal initialized successfully');
    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
    }
  }

  void _setupNotificationHandlers() {
    // Handle foreground notifications
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('Foreground notification received: ${event.notification.title}');
      // Display the notification by not preventing it
      // The notification will be shown automatically
    });

    // Handle permission changes
    OneSignal.Notifications.addPermissionObserver((hasPermission) {
      debugPrint('Notification permission changed: $hasPermission');
    });
  }

  Future<void> _sendPlayerIdToBackend() async {
    if (_playerId == null || _playerId!.isEmpty) return;

    try {
      // Determine platform
      String platform = 'android';
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
      } else if (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        platform = 'web';
      }

      final response = await _apiService.updateDeviceToken(
        _playerId!,
        platform,
      );

      if (response.statusCode == 200) {
        debugPrint('Device token sent to backend successfully');
      } else {
        debugPrint('Failed to send device token: ${response.statusMessage}');
      }
    } catch (e) {
      // Don't log error if user is not authenticated (401)
      if (e.toString().contains('401')) {
        debugPrint('User not authenticated, skipping device token update');
      } else {
        debugPrint('Error sending device token to backend: $e');
      }
    }
  }


  Future<void> sendPlayerIdToBackend() async {
    await _sendPlayerIdToBackend();
  }

  Future<void> setUserId(String userId) async {
    try {
      await OneSignal.login(userId);
      debugPrint('OneSignal user ID set: $userId');
    } catch (e) {
      debugPrint('Error setting OneSignal user ID: $e');
    }
  }

  Future<void> logout() async {
    try {
      await OneSignal.logout();
      debugPrint('OneSignal logged out');
    } catch (e) {
      debugPrint('Error logging out from OneSignal: $e');
    }
  }

  Future<bool> requestPermission() async {
    try {
      final permission = await OneSignal.Notifications.requestPermission(true);
      return permission;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }
}

