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

// The entry point of the application.
Future<void> main() async {
  // Ensure Flutter's widget binding is initialized before any async operations.
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the .env file at the root of the project.
  await dotenv.load(fileName: ".env");

  // Run the app, wrapping the entire widget tree with our service providers.
  runApp(
    MultiProvider(
      providers: [
        // 1. Provide AuthService first, as it has no dependencies.
        ChangeNotifierProvider(create: (_) => AuthService()),

        // 2. Provide ApiService, which depends on AuthService.
        // ProxyProvider ensures that ApiService is created with the instance of AuthService.
        ProxyProvider<AuthService, ApiService>(
          update: (context, authService, previousApiService) => ApiService(authService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// MyApp is a StatefulWidget to properly initialize and hold the GoRouter instance,
// which needs access to the providers via BuildContext.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // The GoRouter instance is a class member, initialized once.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // We can safely access the AuthService here using the widget's context.
    final authService = context.read<AuthService>();

    // The router configuration is created here.
    _router = GoRouter(
      // The refreshListenable now correctly listens to the AuthService instance.
      // Whenever authService.notifyListeners() is called, GoRouter re-evaluates
      // the current route and its redirect logic.
      refreshListenable: authService,

      initialLocation: '/splash',

      // --- Routes Definition ---
      // Using named routes is a best practice for easier navigation and maintenance.
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
            // The session token is passed as an 'extra' parameter.
            // This is a secure way to pass temporary data between routes.
            final sessionToken = state.extra as String?;

            // Safety check: If for some reason we land here without a token,
            // we redirect to login to prevent a crash or broken state.
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
        // --- ADDED: The route for the Request Detail Screen ---
        GoRoute(
          name: 'request-detail',
          path: '/request/:id', // Uses a path parameter for the request ID.
          builder: (context, state) {
            final requestId = state.pathParameters['id']!;
            // The full data object can be passed as 'extra' to avoid re-fetching.
            final requestData = state.extra as Map<String, dynamic>?;
            return RequestDetailScreen(requestId: requestId, initialData: requestData);
          },
        ),
      ],

      // --- Redirect Logic ---
      // This block is the "brain" of your app's navigation flow. It runs
      // before every navigation event to decide where the user should go.
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authService.authState;
        final currentRoute = state.matchedLocation;

        // A list of routes that are part of the initial authentication/setup flow.
        final onAuthRoute = currentRoute == '/splash' || currentRoute == '/login' || currentRoute == '/create-password';

        // 1. While auth state is being determined, always show the splash screen.
        if (authState == AuthState.unknown) {
          return currentRoute == '/splash' ? null : '/splash';
        }

        // 2. If the user is unauthenticated and NOT already on an auth route,
        // force them to the login screen.
        if (authState == AuthState.unauthenticated && !onAuthRoute) {
          return '/login';
        }

        // 3. If the user needs to set up their password, force them to that screen.
        if (authState == AuthState.needsSetup && currentRoute != '/create-password') {
          // IMPORTANT FIX: In the redirect, we just return the path string.
          // The `extra` data (session token) is implicitly carried over by GoRouter's state
          // from the navigation event that triggered this redirect (i.e., from the LoginScreen).
          return '/create-password';
        }

        // 4. If a fully authenticated user tries to go back to an auth route,
        // redirect them to their main dashboard.
        if (authState == AuthState.authenticated && onAuthRoute) {
          return '/dashboard';
        }

        // 5. If none of the above conditions are met, no redirect is needed.
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