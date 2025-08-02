// --- Core Flutter & Package Imports ---
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --- Feature Screen Imports ---
import 'package:addis_information_highway_mobile/features/auth/create_password_screen.dart';
import 'package:addis_information_highway_mobile/features/auth/login_screen.dart';
import 'package:addis_information_highway_mobile/features/auth/splash_screen.dart';
import 'package:addis_information_highway_mobile/features/dashboard/dashboard_screen.dart';
import 'package:addis_information_highway_mobile/features/requests/request_detail_screen.dart';

// --- Service Imports ---
import 'package:addis_information_highway_mobile/services/api_service.dart';
import 'package:addis_information_highway_mobile/services/auth_service.dart';
import 'package:addis_information_highway_mobile/services/notification_service.dart'; // IMPORT the new service

// A global key is needed for the navigator so that services (like NotificationService)
// can access the navigation context from outside the widget tree.
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

// The entry point of the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Run the app, wrapping the entire widget tree with our service providers.
  runApp(
    MultiProvider(
      providers: [
        // 1. Provide AuthService first, as it has no dependencies.
        ChangeNotifierProvider(create: (_) => AuthService()),

        // 2. Provide ApiService, which depends on AuthService.
        ProxyProvider<AuthService, ApiService>(
          update: (context, authService, previousApiService) => ApiService(authService),
        ),

        // 3. ADDED: Provide NotificationService, which depends on ApiService.
        // This creates a clean dependency chain: Auth -> API -> Notifications.
        ProxyProvider<ApiService, NotificationService>(
          update: (context, apiService, previousNotificationService) => NotificationService(apiService, _navigatorKey),
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
      // Attach the global navigator key to the router.
      navigatorKey: _navigatorKey,

      // The refreshListenable correctly listens to the AuthService instance.
      refreshListenable: authService,

      initialLocation: '/splash',

      // --- Routes Definition (no changes here) ---
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
          name: 'create-password',
          path: '/create-password',
          builder: (context, state) {
            final sessionToken = state.extra as String?;
            if (sessionToken == null) {
              return const LoginScreen();
            }
            return CreatePasswordScreen(sessionToken: sessionToken);
          },
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
            return RequestDetailScreen(requestId: requestId, initialData: requestData);
          },
        ),
      ],

      // --- Redirect Logic (no changes here) ---
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authService.authState;
        final currentRoute = state.matchedLocation;
        final onAuthRoute = currentRoute == '/splash' || currentRoute == '/login' || currentRoute == '/create-password';

        if (authState == AuthState.unknown) {
          return currentRoute == '/splash' ? null : '/splash';
        }
        if (authState == AuthState.unauthenticated && !onAuthRoute) {
          return '/login';
        }
        if (authState == AuthState.needsSetup && currentRoute != '/create-password') {
          return '/create-password';
        }
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