import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // ← AJOUTÉ POUR TIMER
import 'core/providers/auth_provider.dart';
import 'core/providers/sites_provider.dart';
import 'core/providers/activities_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SitesProvider()),
        ChangeNotifierProvider(create: (_) => ActivitiesProvider()),
      ],
      child: MaterialApp(
        title: 'Conseiller App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔐 Vérification du statut d\'authentification...');
      context.read<AuthProvider>().checkAuthStatus();
      
      // Vérifier la session toutes les 5 minutes
      _sessionTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        print('⏰ Vérification automatique de session...');
        context.read<AuthProvider>().checkSession();
      });
      
      print('✅ Timer de session configuré (vérification toutes les 5 min)');
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    print('🔐 Timer de session annulé');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isAuthenticated) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}