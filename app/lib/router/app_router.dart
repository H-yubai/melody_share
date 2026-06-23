import 'package:go_router/go_router.dart';
import '../pages/developer/developer_pages.dart';
import '../pages/group_detail_page.dart';
import '../pages/home_page.dart';
import '../pages/player_page.dart';
import '../pages/upload_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/higequ',
        name: 'higequ',
        builder: (context, state) => const UploadPage(),
      ),
      GoRoute(
        path: '/player',
        name: 'player',
        builder: (context, state) => const PlayerPage(),
      ),
      GoRoute(
        path: '/group/:id',
        name: 'group',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return GroupDetailPage(groupId: id);
        },
      ),
      GoRoute(
        path: '/developer',
        name: 'developer',
        builder: (context, state) => const DeveloperPage(),
      ),
    ],
  );
}
