import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  fb.FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  StreamSubscription<fb.User?>? _authSub;
  bool _disposed = false;

  User? _currentUser;
  bool _loading = true;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isShopkeeper => _currentUser?.role == UserRole.shopkeeper;
  bool get loading => _loading;

  AuthService() {
    try {
      _auth = fb.FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _authSub = _auth!.authStateChanges().listen(_onAuthChanged);
    } catch (_) {
      _loading = false;
      _safeNotify();
    }
  }

  AuthService.test();

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _onAuthChanged(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _loading = false;
      _safeNotify();
      return;
    }
    _loading = true;
    _safeNotify();
    try {
      if (_firestore == null) {
        _currentUser = User(
          id: firebaseUser.uid,
          firstName: firebaseUser.displayName?.split(' ').first ?? '',
          lastName: firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          role: UserRole.shopkeeper,
        );
        _loading = false;
        _safeNotify();
        return;
      }
      final doc = await _firestore!.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          _currentUser = User.fromFirestore(firebaseUser.uid, data);
        }
      } else if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
        final existingByEmail = await _firestore!
            .collection('users')
            .where('email', isEqualTo: firebaseUser.email)
            .limit(1)
            .get();

        if (existingByEmail.docs.isNotEmpty) {
          final existingDoc = existingByEmail.docs.first;
          final existingData = existingDoc.data();
          final existingRole = UserRole.values.firstWhere(
            (r) => r.name == existingData['role'] as String?,
            orElse: () => UserRole.shopkeeper,
          );
          await _firestore!.collection('users').doc(firebaseUser.uid).set({
            'firstName': existingData['firstName'] ?? firebaseUser.displayName?.split(' ').first ?? '',
            'lastName': existingData['lastName'] ?? firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
            'name': existingData['name'] ?? firebaseUser.displayName ?? '',
            'email': firebaseUser.email ?? '',
            'phone': existingData['phone'] ?? firebaseUser.phoneNumber ?? '',
            'role': existingRole.name,
            'isActive': existingData['isActive'] ?? true,
            'migratedFrom': existingDoc.id,
          });
          await existingDoc.reference.delete();
          _currentUser = User(
            id: firebaseUser.uid,
            firstName: (existingData['firstName'] as String?) ?? firebaseUser.displayName?.split(' ').first ?? '',
            lastName: (existingData['lastName'] as String?) ?? firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
            email: firebaseUser.email ?? '',
            phone: (existingData['phone'] as String?) ?? firebaseUser.phoneNumber ?? '',
            role: existingRole,
          );
        } else {
          final displayName = firebaseUser.displayName ?? '';
          final parts = displayName.split(' ');
          final userDoc = {
            'firstName': parts.isNotEmpty ? parts[0] : '',
            'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
            'name': displayName,
            'email': firebaseUser.email ?? '',
            'phone': firebaseUser.phoneNumber ?? '',
            'role': UserRole.shopkeeper.name,
          };
          await _firestore!.collection('users').doc(firebaseUser.uid).set(userDoc);
          _currentUser = User(
            id: firebaseUser.uid,
            firstName: parts.isNotEmpty ? parts[0] : '',
            lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
            email: firebaseUser.email ?? '',
            phone: firebaseUser.phoneNumber ?? '',
            role: UserRole.shopkeeper,
          );
        }
      } else {
        final displayName = firebaseUser.displayName ?? '';
        final parts = displayName.split(' ');
        final userDoc = {
          'firstName': parts.isNotEmpty ? parts[0] : '',
          'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
          'name': displayName,
          'email': firebaseUser.email ?? '',
          'phone': firebaseUser.phoneNumber ?? '',
          'role': UserRole.shopkeeper.name,
        };
        await _firestore!.collection('users').doc(firebaseUser.uid).set(userDoc);
        _currentUser = User(
          id: firebaseUser.uid,
          firstName: parts.isNotEmpty ? parts[0] : '',
          lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          role: UserRole.shopkeeper,
        );
      }
    } catch (e) {
      _currentUser = User(
        id: firebaseUser.uid,
        firstName: firebaseUser.displayName?.split(' ').first ?? '',
        lastName: firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber ?? '',
        role: UserRole.shopkeeper,
      );
    }
    _loading = false;
    _safeNotify();
  }

  bool get _available => _auth != null && _firestore != null;

  // ── Email Link (Passwordless) Auth ──

  Future<String?> sendEmailLink(String email) async {
    if (!_available) return 'Firebase not initialized';
    try {
      final actionCodeSettings = fb.ActionCodeSettings(
        url: 'https://zaratraders-2dc9e.firebaseapp.com/__/auth/links',
        handleCodeInApp: true,
        androidPackageName: 'com.company.zaratraders',
        androidInstallApp: true,
        androidMinimumVersion: '21',
      );
      await _auth!.sendSignInLinkToEmail(
        email: email.trim(),
        actionCodeSettings: actionCodeSettings,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emailForSignIn', email.trim());
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return e.toString();
    }
  }

  bool isEmailLink(String link) {
    if (_auth == null) return false;
    return _auth!.isSignInWithEmailLink(link);
  }

  Future<String?> completeEmailLinkSignIn(String link) async {
    if (!_available) return 'Firebase not initialized';
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('emailForSignIn');
      if (email == null || email.isEmpty) {
        return 'Email not found. Please enter your email and try again.';
      }
      await _auth!.signInWithEmailLink(email: email, emailLink: link);
      await prefs.remove('emailForSignIn');
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> completeEmailLinkSignInWithEmail(String link, String email) async {
    if (!_available) return 'Firebase not initialized';
    try {
      await _auth!.signInWithEmailLink(email: email.trim(), emailLink: link);
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return e.toString();
    }
  }

  // ── End Email Link ──

  Future<String?> login(String email, String password) async {
    if (!_available) return 'Firebase not initialized';
    try {
      await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Login FirebaseAuthException: ${e.code} - ${e.message}');
      return _mapAuthError(e);
    } catch (e) {
      debugPrint('Login unexpected error: $e');
      return e.toString();
    }
  }

  Future<String?> signInWithGoogle() async {
    if (!_available) return 'Firebase not initialized';
    try {
      final google = GoogleSignIn.instance;
      await google.initialize();
      final googleAccount = await google.authenticate();
      final googleAuth = googleAccount.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await _auth!.signInWithCredential(credential);
      final fbUser = _auth!.currentUser;
      if (fbUser == null) return 'Google sign-in failed';
      final doc = await _firestore!.collection('users').doc(fbUser.uid).get();
      if (!doc.exists) {
        final displayName = fbUser.displayName ?? '';
        final parts = displayName.split(' ');
        await _firestore!.collection('users').doc(fbUser.uid).set({
          'firstName': parts.isNotEmpty ? parts[0] : '',
          'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
          'name': displayName,
          'email': fbUser.email ?? '',
          'phone': fbUser.phoneNumber ?? '',
          'role': UserRole.shopkeeper.name,
        });
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      final s = e.toString();
      if (s.contains('canceled') || s.contains('cancelled')) {
        return 'Sign in cancelled';
      }
      return s;
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    if (!_available) return 'Firebase not initialized';
    try {
      await _auth!.sendPasswordResetEmail(email: email.trim());
      return null;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No account found with this email';
      return _mapAuthError(e);
    }
  }

  Future<String?> findAccountAndReset(String query) async {
    if (!_available) return 'Firebase not initialized';
    query = query.trim();
    if (query.contains('@')) {
      return sendPasswordResetEmail(query);
    }
    final phoneQuery = await _firestore!
        .collection('users')
        .where('phone', isEqualTo: query)
        .limit(1)
        .get();
    if (phoneQuery.docs.isNotEmpty) {
      final email = phoneQuery.docs.first.data()['email'] as String?;
      if (email != null && email.isNotEmpty) {
        return sendPasswordResetEmail(email);
      }
    }
    final snapshot = await _firestore!.collection('users').get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').toLowerCase();
      final uid = doc.id.toLowerCase();
      final q = query.toLowerCase();
      if (name == q || uid == q || uid.startsWith(q)) {
        final email = data['email'] as String?;
        if (email != null && email.isNotEmpty) {
          return sendPasswordResetEmail(email);
        }
      }
    }
    return 'No account found with this email, phone, or ID';
  }

  String _mask(String value) {
    if (value.length <= 3) return value;
    return '${value[0]}${'*' * (value.length - 2)}${value[value.length - 1]}';
  }

  List<Map<String, String>> _matchesFromSnapshot(
      QuerySnapshot snapshot, String q) {
    final results = <Map<String, String>>[];
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] as String? ?? '').toLowerCase();
      final email = data['email'] as String? ?? '';
      final phone = data['phone'] as String? ?? '';
      final uid = doc.id.toLowerCase();
      if (email.toLowerCase().contains(q) ||
          phone.contains(q) ||
          name.contains(q) ||
          uid.contains(q)) {
        final em = email.split('@');
        final maskedEmail = em.length == 2
            ? '${_mask(em[0])}@${em[1]}'
            : _mask(email);
        final maskedPhone = phone.length >= 6
            ? '${phone.substring(0, 3)}${'*' * (phone.length - 4)}${phone.substring(phone.length - 1)}'
            : phone;
        results.add({
          'id': uid,
          'name': data['name'] as String? ?? '',
          'email': email,
          'maskedEmail': maskedEmail,
          'phone': phone,
          'maskedPhone': maskedPhone,
        });
      }
    }
    return results;
  }

  Future<List<Map<String, String>>> searchAccounts(String query) async {
    if (!_available) return [];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final results = <Map<String, String>>[];
    if (q.contains('@')) {
      final byEmail = await _firestore!
          .collection('users')
          .where('email', isEqualTo: query.trim())
          .limit(5)
          .get();
      results.addAll(_matchesFromSnapshot(byEmail, q));
    }
    final byPhone = await _firestore!
        .collection('users')
        .where('phone', isEqualTo: query.trim())
        .limit(5)
        .get();
    results.addAll(_matchesFromSnapshot(byPhone, q));
    if (results.isEmpty) {
      final all = await _firestore!.collection('users').limit(20).get();
      results.addAll(_matchesFromSnapshot(all, q));
    }
    final seen = <String>{};
    results.retainWhere((r) => seen.add(r['id']!));
    return results.take(5).toList();
  }

  Future<String?> signup(
    String firstName,
    String lastName,
    String email,
    String password,
    UserRole role, {
    String phone = '',
  }) async {
    if (!_available) return 'Firebase not initialized';
    try {
      final result = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = result.user?.uid;
      if (uid == null) return 'Signup failed: no user created';
      final fullName = '$firstName $lastName'.trim();

      final existingByEmail = await _firestore!
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (existingByEmail.docs.isNotEmpty) {
        final existingDoc = existingByEmail.docs.first;
        final existingData = existingDoc.data();
        final existingRole = UserRole.values.firstWhere(
          (r) => r.name == existingData['role'] as String?,
          orElse: () => UserRole.shopkeeper,
        );
        await _firestore!.collection('users').doc(uid).set({
          'firstName': existingData['firstName'] ?? firstName.trim(),
          'lastName': existingData['lastName'] ?? lastName.trim(),
          'name': existingData['name'] ?? fullName,
          'email': email.trim(),
          'phone': existingData['phone'] ?? phone.trim(),
          'role': existingRole.name,
          'isActive': existingData['isActive'] ?? true,
          'migratedFrom': existingDoc.id,
        });
        await existingDoc.reference.delete();
        _currentUser = User(
          id: uid,
          firstName: (existingData['firstName'] as String?) ?? firstName.trim(),
          lastName: (existingData['lastName'] as String?) ?? lastName.trim(),
          email: email.trim(),
          phone: (existingData['phone'] as String?) ?? phone.trim(),
          role: existingRole,
        );
      } else {
        try {
          await _firestore!.collection('users').doc(uid).set({
            'firstName': firstName.trim(),
            'lastName': lastName.trim(),
            'name': fullName,
            'email': email.trim(),
            'phone': phone.trim(),
            'role': role.name,
          });
        } catch (e) {
          debugPrint('Firestore write failed: $e');
        }
        _currentUser = User(
          id: uid,
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          email: email.trim(),
          phone: phone.trim(),
          role: role,
        );
      }
      _safeNotify();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Signup FirebaseAuthException: ${e.code} - ${e.message}');
      return _mapAuthError(e);
    } catch (e) {
      debugPrint('Signup unexpected error: $e');
      return e.toString();
    }
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth?.signOut();
  }

  String _mapAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'invalid-phone-number':
        return 'Invalid phone number';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email';
      case 'operation-not-allowed':
        return 'Sign-in method not enabled';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}
