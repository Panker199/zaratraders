import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/shopkeeper/shopkeeper_dashboard.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp().then((_) => runApp(const ZaraTradersApp(firebaseReady: true)))
      .catchError((e) {
    debugPrint('Firebase init failed: $e');
    runApp(const ZaraTradersApp(firebaseReady: false));
  });
}

class ZaraTradersApp extends StatefulWidget {
  final AuthService? authService;
  final bool firebaseReady;
  const ZaraTradersApp({super.key, this.authService, this.firebaseReady = false});

  @override
  State<ZaraTradersApp> createState() => _ZaraTradersAppState();
}

class _ZaraTradersAppState extends State<ZaraTradersApp> {
  late final AuthService _authService;
  final _navKey = GlobalKey<NavigatorState>();
  final _links = AppLinks();
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _handleInitialLink();
    _linkSub = _links.uriLinkStream.listen(_onLink, onError: (_) {});
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    if (widget.authService == null) _authService.dispose();
    super.dispose();
  }

  Future<void> _handleInitialLink() async {
    try {
      final uri = await _links.getInitialLink();
      if (uri != null) _onLink(uri);
    } catch (_) {}
  }

  void _onLink(Uri uri) {
    final link = uri.toString();
    if (_authService.isEmailLink(link)) {
      _authService.completeEmailLinkSignIn(link).then((err) {
        if (err != null && mounted) {
          ScaffoldMessenger.of(_navKey.currentContext!).showSnackBar(
            SnackBar(content: Text('Email link sign-in failed: $err')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, tp, _) => MaterialApp(
          title: 'Zara Traders',
          navigatorKey: _navKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: tp.themeMode,
          home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (!widget.firebaseReady) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Firebase initialization failed',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Check your google-services.json configuration',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              );
            }
            if (auth.loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!auth.isLoggedIn) return const LoginScreen();
            if (auth.isAdmin) return const AdminDashboard();
            if (auth.isShopkeeper) return const ShopkeeperDashboard();
            return const HomeScreen();
          },
          ),
        ),
      ),
    );
  }
}
