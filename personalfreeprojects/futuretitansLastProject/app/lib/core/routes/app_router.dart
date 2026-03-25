import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/modules/presentation/screens/modules_screen.dart';
import '../../features/modules/presentation/screens/module_detail_screen.dart';
import '../../features/modules/presentation/screens/chapter_player_screen.dart';
import '../../features/ai_chat/presentation/screens/chapter_ai_chat_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/profile/presentation/screens/help_support_screen.dart';
import '../../features/ai_chat/presentation/widgets/zunova_avatar.dart';
import '../../features/submission/presentation/screens/submission_screen.dart';
import '../../shared/widgets/custom_bottom_nav.dart';
import '../../core/theme/app_theme.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard', // Changed default assuming auth protects it
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup' || state.matchedLocation == '/forgot-password';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/dashboard';
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/submit-idea',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SubmissionScreen(),
      ),
      GoRoute(
        path: '/global-chat',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChapterAiChatScreen(moduleId: 'global', chapterId: 'global'),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return AppScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/modules',
            builder: (context, state) => const ModulesScreen(),
            routes: [
              GoRoute(
                 path: ':id',
                 parentNavigatorKey: rootNavigatorKey, // Push over the bottom nav bar
                 builder: (context, state) => ModuleDetailScreen(moduleId: state.pathParameters['id']!),
                 routes: [
                    GoRoute(
                      path: 'chapter/:chapterId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => ChapterPlayerScreen(
                         moduleId: state.pathParameters['id']!,
                         chapterId: state.pathParameters['chapterId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'chat',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) => ChapterAiChatScreen(
                            moduleId: state.pathParameters['id']!,
                            chapterId: state.pathParameters['chapterId']!,
                          ),
                        ),
                      ]
                    ),
                 ]
              ),
            ]
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'payment',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const PaymentScreen(),
              ),
              GoRoute(
                path: 'help',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const HelpSupportScreen(),
              ),
            ]
          ),
        ],
      )
    ],
  );
});

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          // Chat Bubble
          Positioned(
            right: 100,
            bottom: 110,
            child: GestureDetector(
              onTap: () => context.push('/global-chat'),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4), // Tail pointing right
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "Hi, I am Zunova 👋",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          // Zunova Avatar
          Positioned(
            right: -40,
            bottom: -40,
            child: GestureDetector(
              onTap: () => context.push('/global-chat'),
              child: const ZunovaAvatar(size: 226, isTalking: false),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}



