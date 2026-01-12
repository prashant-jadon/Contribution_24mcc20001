import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/onesignal_service.dart';
import 'core/services/notification_handler.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/discovery_provider.dart';
import 'providers/app_config_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/profile/profile_view_screen.dart';
import 'models/profile_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API Service
  ApiService().init();
  
  // Initialize OneSignal
  await OneSignalService().initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const arzApp());
}

class arzApp extends StatefulWidget {
  const arzApp({super.key});

  @override
  State<arzApp> createState() => _arzAppState();
}

class _arzAppState extends State<arzApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    // Handle initial link (if app was opened via deep link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(initialLink);
        });
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen for deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Handling deep link: $uri');
    
    // Parse the link
    // Format: https://arz.vercel.app/{username}
    // or: arz://profile/{username}
    
    String? username;
    
    if (uri.scheme == 'arz' && uri.host == 'profile') {
      // Custom scheme: arz://profile/{username}
      username = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.host == 'arz.vercel.app' || 
               uri.host == 'www.arz.vercel.app' ||
               uri.host == 'arz.app') {
      // Universal link: https://arz.vercel.app/{username}
      username = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    
    if (username != null && username.isNotEmpty) {
      // Navigate to profile screen
      _navigateToProfile(username);
    }
  }

  void _navigateToProfile(String username) {
    // Wait for navigation to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        debugPrint('Navigator not ready, will retry after app loads');
        // Retry after a delay if navigator isn't ready
        Future.delayed(const Duration(seconds: 1), () {
          _navigateToProfile(username);
        });
        return;
      }
      
      // Check if user is authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (!authProvider.isAuthenticated) {
        // Show message that user needs to login first
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to view profiles'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // Fetch profile by username and navigate
      await _loadAndNavigateToProfile(username, navigator);
    });
  }

  Future<void> _loadAndNavigateToProfile(String username, NavigatorState navigator) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final apiService = ApiService();
      // Use public profile endpoint
      final response = await apiService.getPublicProfileByUsername(username);
      
      if (response.statusCode == 200 && response.data['success']) {
        final profileData = response.data['data']['profile'];
        final profile = ProfileModel.fromJson(profileData);
        
        // Close loading dialog
        if (context.mounted) {
          navigator.pop(); // Close loading dialog
          
          // Navigate to profile view
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ProfileViewScreen(profile: profile),
            ),
          );
        }
      } else {
        if (context.mounted) {
          navigator.pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Profile not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (context.mounted) {
        final navigator = navigatorKey.currentState;
        if (navigator != null) {
          navigator.pop(); // Close loading dialog if still open
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppConfigProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProvider(create: (_) => DiscoveryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );
  }
}
