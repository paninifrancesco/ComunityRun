import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/runs/run_discovery_screen.dart';
import '../screens/runs/run_details_screen.dart';
import '../screens/runs/create_run_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/verification_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/safety_screen.dart';
import '../screens/settings/privacy_settings_screen.dart';
import '../screens/settings/emergency_settings_screen.dart';
import '../screens/settings/safety_guidelines_screen.dart';
import '../screens/settings/language_settings_screen.dart';
import '../screens/messages/messages_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isOnSplash = state.fullPath == '/splash';
      final isOnAuth = state.fullPath == '/auth';
      final isOnOnboarding = state.fullPath == '/onboarding';

      if (isOnSplash) return null;
      
      if (!isAuthenticated && !isOnAuth && !isOnOnboarding) {
        return '/auth';
      }
      
      if (isAuthenticated && (isOnAuth || isOnOnboarding)) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => Scaffold(
          body: child,
          bottomNavigationBar: _buildBottomNavBar(context, state),
        ),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/discover',
            name: 'discover',
            builder: (context, state) => const RunDiscoveryScreen(),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/run/:id',
        name: 'run-details',
        builder: (context, state) => RunDetailsScreen(
          runId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/create-run',
        name: 'create-run',
        builder: (context, state) => const CreateRunScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/verification',
        name: 'verification',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/chat/:runId',
        name: 'chat',
        builder: (context, state) => ChatScreen(
          runId: state.pathParameters['runId']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/safety',
        name: 'safety',
        builder: (context, state) => const SafetyScreen(),
      ),
      GoRoute(
        path: '/privacy-settings',
        name: 'privacy-settings',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/emergency-settings',
        name: 'emergency-settings',
        builder: (context, state) => const EmergencySettingsScreen(),
      ),
      GoRoute(
        path: '/safety-guidelines',
        name: 'safety-guidelines',
        builder: (context, state) => const SafetyGuidelinesScreen(),
      ),
      GoRoute(
        path: '/language-settings',
        name: 'language-settings',
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
    ],
  );
});

Widget _buildBottomNavBar(BuildContext context, GoRouterState state) {
  final currentRoute = state.fullPath ?? '/home';
  
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: _getSelectedIndex(currentRoute),
    onTap: (index) => _onBottomNavTap(context, index),
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.explore),
        label: 'Discover',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ],
  );
}

int _getSelectedIndex(String fullPath) {
  switch (fullPath) {
    case '/home':
      return 0;
    case '/discover':
      return 1;
    case '/messages':
      return 2;
    case '/profile':
      return 3;
    default:
      return 0;
  }
}

void _onBottomNavTap(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go('/home');
      break;
    case 1:
      context.go('/discover');
      break;
    case 2:
      context.go('/messages');
      break;
    case 3:
      context.go('/profile');
      break;
  }
}