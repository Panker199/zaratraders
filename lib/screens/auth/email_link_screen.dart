import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/animations.dart';

class EmailLinkScreen extends StatefulWidget {
  const EmailLinkScreen({super.key});

  @override
  State<EmailLinkScreen> createState() => _EmailLinkScreenState();
}

class _EmailLinkScreenState extends State<EmailLinkScreen> {
  final _emailCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  bool _sending = false;
  bool _linkSent = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    final auth = context.read<AuthService>();
    setState(() {
      _error = null;
      _sending = true;
    });
    final err = await auth.sendEmailLink(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _sending = false;
    });
    if (err != null) {
      setState(() => _error = err);
    } else {
      setState(() => _linkSent = true);
    }
  }

  Future<void> _verifyLink() async {
    final auth = context.read<AuthService>();
    final link = _linkCtrl.text.trim();
    if (link.isEmpty) {
      setState(() => _error = 'Paste the link from your email');
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    final err = await auth.completeEmailLinkSignInWithEmail(
      link,
      _emailCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null) {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0a1628), const Color(0xFF0f0f0f)]
                : [const Color(0xFFe8f4fd), theme.scaffoldBackgroundColor],
            stops: const [0.0, 0.4],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icon ──
                  StaggeredFadeIn(
                    index: 0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  cs.primary.withValues(alpha: 0.2),
                                  cs.primary.withValues(alpha: 0.05),
                                ]
                              : [
                                  cs.primary.withValues(alpha: 0.15),
                                  cs.primary.withValues(alpha: 0.05),
                                ],
                        ),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.mark_email_read_rounded,
                        size: 36,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StaggeredFadeIn(
                    index: 1,
                    child: Text(
                      _linkSent
                          ? 'Check Your Email'
                          : 'Sign in with Email Link',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  StaggeredFadeIn(
                    index: 2,
                    child: Text(
                      _linkSent
                          ? 'We sent a sign-in link to\n${_emailCtrl.text}'
                          : 'No password needed. We\'ll send you a secure link to sign in.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Card ──
                  StaggeredFadeIn(
                    index: 3,
                    child: Card(
                      elevation: isDark ? 0 : 2,
                      shadowColor: Colors.black.withValues(alpha: 0.06),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email field
                            TextField(
                              controller: _emailCtrl,
                              enabled: !_linkSent,
                              decoration: InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 20,
                                ),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: _linkSent
                                    ? cs.surfaceContainerHighest.withValues(
                                        alpha: 0.3,
                                      )
                                    : null,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),

                            if (_linkSent) ...[
                              const SizedBox(height: 16),
                              // Paste link field
                              TextField(
                                controller: _linkCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Paste email link here',
                                  prefixIcon: const Icon(
                                    Icons.link_rounded,
                                    size: 20,
                                  ),
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  hintText:
                                      'https://zaratraders-2dc9e.firebaseapp.com/...',
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              // Resend
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _sending
                                      ? null
                                      : () async {
                                          setState(() {
                                            _linkSent = false;
                                            _error = null;
                                            _success = null;
                                          });
                                        },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Use a different email',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // Error
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cs.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: cs.error.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      size: 16,
                                      color: cs.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: cs.error,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Success
                            if (_success != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _success!,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Send / Verify button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: _sending
                                    ? null
                                    : (_linkSent ? _verifyLink : _sendLink),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _sending
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _linkSent
                                                ? Icons.verified_rounded
                                                : Icons.send_rounded,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _linkSent
                                                ? 'Verify & Sign In'
                                                : 'Send Sign-In Link',
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Back to login ──
                  const SizedBox(height: 24),
                  StaggeredFadeIn(
                    index: 4,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back to Sign In'),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
