import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class OrbApp extends StatelessWidget {
  const OrbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Companion Orb',
      theme: OrbTheme.light,
      darkTheme: OrbTheme.dark,
      routerConfig: orbRouter,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
