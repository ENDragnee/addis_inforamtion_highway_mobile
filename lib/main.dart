// --- Core Flutter & Package Imports ---
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --- Feature Screen Imports ---
// The 'create_password_screen.dart' import is now removed.
import 'package:addis_information_highway_mobile/features/auth/login_screen.dart';
import 'package:addis_information_highway_mobile/features/auth/splash_screen.dart';
import 'package:addis_information_highway_mobile/features/dashboard/dashboard_screen.dart';
import 'package:addis_information_highway_mobile/features/requests/request_detail_screen.dart';
import 'package:firebase_core/firebase_core.dart';
// --- Service Imports ---
import 'package:addis_information_highway_mobile/services/api_service.dart';
import 'package:addis_information_highway_mobile/services/auth_service.dart';
import 'package:addis_information_highway_mobile/services/notification_service.dart';
import 'package:addis_information_highway_mobile/firebase_options.dart';
import 'package:addis_information_highway_mobile/services/test_user_service.dart'; // IMPORT the new service

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => TestUserService()),
        ProxyProvider<AuthService, ApiService>(
          update: (_, authService, __) => ApiService(authService),
        ),
        ProxyProvider<ApiService, NotificationService>(
          update: (_, apiService, __) => NotificationService(apiService, _navigatorKey),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();

    _router = GoRouter(
      navigatorKey: _navigatorKey,
      refreshListenable: authService,
      initialLocation: '/splash',

      // --- UPDATED: Routes Definition ---
      routes: [
        GoRoute(
          name: 'splash',
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          name: 'login',
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          name: 'dashboard',
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          name: 'request-detail',
          path: '/request/:id',
          builder: (context, state) {
            final requestId = state.pathParameters['id']!;
            final requestData = state.extra as Map<String, dynamic>?;
            return RequestDetailScreen(
                requestId: requestId, initialData: requestData);
          },
        ),
      ],

      // --- UPDATED: Redirect Logic ---
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authService.authState;
        final currentRoute = state.matchedLocation;

        // The 'onAuthRoute' check is now simpler as it no longer includes create-password.
        final onAuthRoute = currentRoute == '/splash' || currentRoute == '/login';

        if (authState == AuthState.unknown) {
          return currentRoute == '/splash' ? null : '/splash';
        }
        if (authState == AuthState.unauthenticated && !onAuthRoute) {
          return '/login';
        }
        // The 'needsSetup' redirect logic is now REMOVED.
        if (authState == AuthState.authenticated && onAuthRoute) {
          return '/dashboard';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Addis Information Highway',
      debugShowCheckedModeBanner: false,
      theme: draculaTheme,
      routerConfig: _router,
    );
  }
}