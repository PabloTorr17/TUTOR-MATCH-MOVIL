// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/dashboard_screen.dart';
import '../../features/sessions/presentation/screens/sessions_screen.dart';
import '../../features/sessions/presentation/screens/session_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../core/theme/app_theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final path = state.matchedLocation;

      if (isLoading) return null;
      if (!isAuth && path != '/login' && path != '/register') return '/login';
      if (isAuth && (path == '/login' || path == '/register')) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/sessions', builder: (_, __) => const SessionsScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ChatListScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Detail routes (outside shell — no bottom nav)
      GoRoute(
        path: '/sessions/:id',
        builder: (_, state) => SessionDetailScreen(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/sessions/create',
        builder: (_, __) => const CreateSessionPlaceholder(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (_, state) {
          final convId = state.pathParameters['conversationId']!;
          final receiverId = state.uri.queryParameters['receiver_id'] ?? '';
          final receiverName = Uri.decodeComponent(state.uri.queryParameters['receiver_name'] ?? 'Usuario');
          return ConversationScreen(
            conversationId: convId,
            receiverId: receiverId,
            receiverName: receiverName,
          );
        },
      ),
      GoRoute(
        path: '/users/:id',
        builder: (_, state) => UserProfileScreen(userId: state.pathParameters['id']!),
      ),
    ],
  );
});

// ── MAIN SHELL WITH BOTTOM NAV ────────────────────────────────
class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line, width: 1.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.ink,
          unselectedItemColor: AppColors.ink4,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded, size: 22), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded, size: 22), label: 'Asesorias'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded, size: 22), label: 'Mensajes'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 22), label: 'Perfil'),
          ],
          onTap: (i) {
            const routes = ['/dashboard', '/sessions', '/chat', '/profile'];
            context.go(routes[i]);
          },
        ),
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/sessions')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }
}

// ── PLACEHOLDER SCREENS ───────────────────────────────────────
class CreateSessionPlaceholder extends StatelessWidget {
  const CreateSessionPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Asesoria'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: const Center(
        child: Text('Pantalla de crear asesoria\n(implementar segun necesidad)',
          textAlign: TextAlign.center),
      ),
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Tutor'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: Center(child: Text('Perfil de usuario $userId')),
    );
  }
}
