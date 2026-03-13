import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/orb_theme.dart';

class OrbApp extends ConsumerWidget {
  const OrbApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'AI Companion Orb',
      debugShowCheckedModeBanner: false,
      theme: OrbTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
