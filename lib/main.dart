import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/voice_notes_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

void main() {
  runApp(const VoiceNotesApp());
}

class VoiceNotesApp extends StatelessWidget {
  const VoiceNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthProvider();

    final router = GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
        final isAuthed = auth.isAuthenticated;
        if (!isAuthed && !loggingIn) return '/login';
        if (isAuthed && loggingIn) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth..initialize()),
        ChangeNotifierProvider(create: (_) => VoiceNotesProvider()),
      ],
      child: MaterialApp.router(
        title: 'Speak and Save',
        themeMode: ThemeMode.light,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          primaryColor: const Color(0xFF6C5CE7),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C5CE7),
            brightness: Brightness.light,
            primary: const Color(0xFF6C5CE7),
            secondary: const Color(0xFFFD79A8),
            tertiary: const Color(0xFF00B894),
            surface: const Color(0xFFF8F9FA),
            background: const Color(0xFFF1F3F4),
            error: const Color(0xFFB00020),
            errorContainer: const Color(0xFFFFDAD6),
            onError: Colors.white,
            onErrorContainer: const Color(0xFF410002),
            surfaceVariant: const Color(0xFFF3F3F3),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF1F3F4),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFF2D3436),
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3436),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 8,
            shadowColor: const Color(0xFF6C5CE7).withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            elevation: 12,
            shape: const CircleBorder(),
            backgroundColor: const Color(0xFF6C5CE7),
            splashColor: const Color(0xFFFD79A8).withOpacity(0.3),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
            ),
            contentPadding: const EdgeInsets.all(20),
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 6,
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3436),
            ),
            headlineSmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3436),
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3436),
            ),
            titleMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3436),
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF636E72),
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF636E72),
            ),
          ),
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.purple,
          primaryColor: const Color(0xFF6C5CE7),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C5CE7),
            brightness: Brightness.dark,
            primary: const Color(0xFF6C5CE7),
            secondary: const Color(0xFFFD79A8),
            tertiary: const Color(0xFF00B894),
            surface: const Color(0xFF1E1E1E),
            background: const Color(0xFF121212),
            onBackground: Colors.white,
            onSurface: Colors.white,
            error: const Color(0xFFCF6679),
            errorContainer: const Color(0xFF93000A),
            onError: Colors.black,
            onErrorContainer: const Color(0xFFFFDAD6),
            surfaceVariant: const Color(0xFF2A2A2A),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 8,
            shadowColor: const Color(0xFF6C5CE7).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: const Color(0xFF1E1E1E),
            surfaceTintColor: Colors.transparent,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            elevation: 12,
            shape: const CircleBorder(),
            backgroundColor: const Color(0xFF6C5CE7),
            splashColor: const Color(0xFFFD79A8).withOpacity(0.3),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
            ),
            contentPadding: const EdgeInsets.all(20),
            hintStyle: TextStyle(color: Colors.grey[500]),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 6,
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            headlineSmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            titleMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
