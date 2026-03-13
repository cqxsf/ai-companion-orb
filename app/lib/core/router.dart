import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/home/view.dart';
import '../features/setup/view.dart';
import '../features/family/view.dart';
import '../features/conversation/view.dart';
import '../features/settings/view.dart';

final orbRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    if (state.matchedLocation == '/') {
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool('onboarded') ?? false;
      return onboarded ? '/home' : '/setup';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashRedirect()),
    GoRoute(path: '/setup', builder: (_, __) => const SetupPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    GoRoute(path: '/family', builder: (_, __) => const FamilyPage()),
    GoRoute(path: '/conversation', builder: (_, __) => const ConversationPage()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
  ],
);

/// Placeholder shown briefly during async redirect.
class SplashRedirect extends StatelessWidget {
  const SplashRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
