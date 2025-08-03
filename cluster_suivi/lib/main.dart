import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/providers/auth_provider.dart';
import 'core/providers/sites_provider.dart';
import 'core/providers/activities_provider.dart';
import 'core/database/database_helper.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ RÉINITIALISER LA BASE DE DONNÉES (TEMPORAIRE)
  print('🔄 Réinitialisation de la base de données...');
  await DatabaseHelper().resetDatabase();
  print('✅ Base réinitialisée');
  
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
        debugShowCheckedModeBanner: false, // ← SUPPRIME LE BANNER DEBUG
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
  Timer? _statusSyncTimer;

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
      
      // Synchroniser les statuts toutes les 2 minutes
      _statusSyncTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
        if (context.read<AuthProvider>().isAuthenticated) {
          print('📊 Synchronisation automatique des statuts...');
          context.read<ActivitiesProvider>().autoSyncStatuses();
        }
      });
      
      print('✅ Timers configurés:');
      print('   - Vérification session: toutes les 5 min');
      print('   - Sync statuts: toutes les 2 min');
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _statusSyncTimer?.cancel();
    print('🔐 Timers annulés');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isAuthenticated) {
          // Démarrer la synchronisation initiale des statuts après la connexion
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<ActivitiesProvider>().autoSyncStatuses();
            }
          });
          
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}