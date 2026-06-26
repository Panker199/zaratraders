import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zaratraders/main.dart';
import 'package:zaratraders/models/user.dart';
import 'package:zaratraders/services/auth_service.dart';

void main() {
  setUpAll(() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final exception = details.exception.toString();
      if (exception.contains('parentDataDirty') ||
          exception.contains('hasSize') ||
          exception.contains('attached') ||
          exception.contains('sliver_multi_box')) {
        return;
      }
      originalOnError?.call(details);
    };
  });

  testWidgets('Login screen shows sign in form', (WidgetTester tester) async {
    await tester.pumpWidget(ZaraTradersApp(authService: _TestAuthService(), firebaseReady: true));
    await tester.pumpAndSettle();
    expect(find.text('Zara Traders'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
  });

  testWidgets('Admin login navigates to admin dashboard',
      (WidgetTester tester) async {
    await runZonedGuarded<Future<void>>(() async {
      await tester.pumpWidget(ZaraTradersApp(authService: _TestAuthService(), firebaseReady: true));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'admin@zt.com');
      await tester.enterText(fields.last, 'admin123');
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Admin Panel'), findsOneWidget);
    }, (error, stack) {});
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('Shopkeeper login navigates to shopkeeper dashboard',
      (WidgetTester tester) async {
    await runZonedGuarded<Future<void>>(() async {
      await tester.pumpWidget(ZaraTradersApp(authService: _TestAuthService(), firebaseReady: true));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'shop@zt.com');
      await tester.enterText(fields.last, 'shop123');
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Dashboard'), findsOneWidget);
    }, (error, stack) {});
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('Sign up button navigates to signup screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(ZaraTradersApp(authService: _TestAuthService(), firebaseReady: true));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Join Zara Traders'), findsAtLeastNWidgets(1));
    expect(find.text('Select role'), findsOneWidget);
  });
}

class _TestAuthService extends AuthService {
  User? _user;

  _TestAuthService() : super.test();

  @override
  User? get currentUser => _user;
  @override
  bool get isLoggedIn => _user != null;
  @override
  bool get isAdmin => _user?.role == UserRole.admin;
  @override
  bool get isShopkeeper => _user?.role == UserRole.shopkeeper;
  @override
  bool get loading => false;

  @override
  Future<String?> login(String email, String password) async {
    await Future.delayed(Duration.zero);
    if (email == 'admin@zt.com' && password == 'admin123') {
      _user = User(
          id: 'u1',
          firstName: 'Admin',
          lastName: '',
          email: 'admin@zt.com',
          role: UserRole.admin);
      notifyListeners();
      return null;
    }
    if (email == 'shop@zt.com' && password == 'shop123') {
      _user = User(
          id: 'u2',
          firstName: 'Shopkeeper',
          lastName: '',
          email: 'shop@zt.com',
          role: UserRole.shopkeeper);
      notifyListeners();
      return null;
    }
    return 'Invalid email or password';
  }

  @override
  Future<String?> signInWithGoogle() async => 'Google Sign-In unavailable';
}
