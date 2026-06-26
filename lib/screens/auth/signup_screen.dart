import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../widgets/animations.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  UserRole _role = UserRole.shopkeeper;
  String? _error;
  bool _signingUp = false;
  bool _googleSigningUp = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_signingUp) return;
    if (_firstNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your first name');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    final auth = context.read<AuthService>();
    setState(() { _error = null; _signingUp = true; });

    debugPrint('── SIGNUP ATTEMPT ──');
    debugPrint('Email: ${_emailCtrl.text.trim()}');
    debugPrint('Role: ${_role.name}');

    final err = await auth.signup(
      _firstNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
      _role,
      phone: _phoneCtrl.text.trim(),
    );

    debugPrint('── SIGNUP RESULT: ${err ?? "SUCCESS"} ──');

    if (!mounted) return;
    setState(() => _signingUp = false);
    if (err != null) {
      if (err == 'Email already registered') {
        setState(() => _error = '$err\nTry signing in instead, or use Sign in with Google.');
      } else {
        setState(() => _error = err);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err, style: const TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
      debugPrint('── Signup SUCCESS, user should be logged in ──');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _googleSignUp() async {
    if (_googleSigningUp) return;
    final auth = context.read<AuthService>();
    setState(() { _error = null; _googleSigningUp = true; });
    final err = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleSigningUp = false);
    if (err != null) setState(() => _error = err);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                StaggeredFadeIn(
                  index: 0,
                  child: Icon(Icons.person_add_rounded,
                      size: 40, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 12),
                StaggeredFadeIn(
                  index: 1,
                    child: Text('Join Zara Traders',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        )),
                ),
                const SizedBox(height: 4),
                StaggeredFadeIn(
                  index: 2,
                  child: Text('Create your account to get started',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
                const SizedBox(height: 24),
                StaggeredFadeIn(
                  index: 3,
                  child: Card(
                    elevation: 1,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _firstNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'First Name',
                                    prefixIcon: Icon(Icons.person_outlined, size: 20),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _lastNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Last Name',
                                    prefixIcon: Icon(Icons.person_outlined, size: 20),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone_outlined, size: 20),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passCtrl,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                    size: 18),
                                onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass),
                              ),
                            ),
                            obscureText: _obscurePass,
                          ),
                          const SizedBox(height: 20),
                          Text('Select role',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          _roleTile(theme, UserRole.shopkeeper, Icons.store_outlined,
                              'Shopkeeper', 'Manage inventory and orders'),
                          const SizedBox(height: 8),
                          _roleTile(theme, UserRole.admin, Icons.admin_panel_settings_outlined,
                              'Admin', 'Full access to manage the store'),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_error!,
                                      style: TextStyle(color: theme.colorScheme.error, fontSize: 13))),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _signingUp ? null : _signup,
                            icon: _signingUp
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : null,
                            label: Text('Create account',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: Divider(thickness: 0.5, color: Colors.grey.shade300)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or sign up with',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              ),
                              Expanded(child: Divider(thickness: 0.5, color: Colors.grey.shade300)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _socialButton(
                            icon: const Icon(Icons.g_mobiledata, size: 22),
                            label: 'Google',
                            loading: _googleSigningUp,
                            onPressed: _googleSigningUp ? null : _googleSignUp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required Widget icon,
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : icon,
      label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _roleTile(ThemeData theme, UserRole role, IconData icon,
      String title, String subtitle) {
    final selected = _role == role;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => setState(() => _role = role),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected ? theme.colorScheme.primary : null)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 20, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
