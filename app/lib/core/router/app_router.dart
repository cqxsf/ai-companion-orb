import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/orb_home/views/orb_home_page.dart';
import '../../features/orb_home/controllers/orb_home_controller.dart';
import '../../features/chat/views/chat_page.dart';
import '../../features/memory/views/memory_page.dart';
import '../../features/memory/views/memory_detail_page.dart';
import '../../features/settings/views/settings_page.dart';
import '../../features/shared/widgets/orb_bottom_nav.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ScaffoldWithNav(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const OrbHomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => const ChatPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/memory',
              builder: (context, state) => const MemoryPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return MemoryDetailPage(memoryId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class ScaffoldWithNav extends ConsumerWidget {
  final StatefulNavigationShell shell;

  const ScaffoldWithNav({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emotion = ref.watch(orbEmotionProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: shell,
      bottomNavigationBar: OrbBottomNav(
        currentIndex: shell.currentIndex,
        currentEmotion: emotion,
        onTap: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}
