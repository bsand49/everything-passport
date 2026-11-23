import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

/// Persistent banner shown to unverified email/password accounts.
///
/// Verification is required for admin features (the Firestore `isAdmin()`
/// check requires a verified email), so the banner prompts unverified
/// password accounts to verify their address. Google sign-in accounts are
/// verified automatically and never see this banner.
class EmailVerificationBanner extends StatefulWidget {
  /// How long the Resend action stays disabled after a successful send.
  final Duration resendCooldown;

  const EmailVerificationBanner({
    super.key,
    this.resendCooldown = const Duration(seconds: 60),
  });

  @override
  State<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _isSending = false;
  bool _isRefreshing = false;
  Timer? _cooldownTimer;

  /// Remaining resend cooldown derived from the shared send timestamp in
  /// [AuthService], so every banner instance enforces the same deadline.
  /// The periodic timer only refreshes the display; elapsed time is measured
  /// against the wall clock so suspended apps cannot drift.
  Duration get _cooldownRemaining {
    final authService = context.read<AuthService>();
    final sentAt = authService.verificationEmailSentAt;
    if (sentAt == null) return Duration.zero;
    final remaining = sentAt
        .add(widget.resendCooldown)
        .difference(authService.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get _onCooldown => _cooldownRemaining > Duration.zero;

  void _ensureCooldownTimer() {
    if (_cooldownTimer != null || !_onCooldown) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        _cooldownTimer = null;
        return;
      }
      setState(() {});
      if (!_onCooldown) {
        timer.cancel();
        _cooldownTimer = null;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureCooldownTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerification() async {
    if (_onCooldown) return;
    setState(() => _isSending = true);
    final messenger = ScaffoldMessenger.of(context);
    final authService = context.read<AuthService>();
    try {
      await authService.sendEmailVerification();
      if (mounted) _ensureCooldownTimer();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Check your inbox.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not send verification email: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _refreshVerification() async {
    setState(() => _isRefreshing = true);
    final messenger = ScaffoldMessenger.of(context);
    final authService = context.read<AuthService>();
    try {
      await authService.reloadCurrentUser();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not refresh verification status: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final authService = context.read<AuthService>();
    if (!authService.requiresEmailVerificationFor(user)) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Verify your email address',
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
            ),
            TextButton(
              onPressed: (_isSending || _onCooldown) ? null : _sendVerification,
              child: _isSending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _onCooldown
                          ? 'Resend (${(_cooldownRemaining.inMilliseconds / 1000).ceil()}s)'
                          : 'Resend',
                    ),
            ),
            IconButton(
              tooltip: 'Refresh verification status',
              onPressed: _isRefreshing ? null : _refreshVerification,
              icon: _isRefreshing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps an authenticated screen with [EmailVerificationBanner] when the
/// current user is an unverified email/password account.
///
/// The banner slot collapses to zero height when verification is not needed
/// (so it does not reserve the status-bar inset a second time) while
/// [Expanded] stays at a stable index, keeping the child — and any unsaved
/// form state — mounted when the banner appears or disappears.
class EmailVerificationBannerHost extends StatelessWidget {
  final Widget child;

  const EmailVerificationBannerHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final authService = context.read<AuthService>();
    final showBanner = authService.requiresEmailVerificationFor(user);
    return Column(
      children: [
        if (showBanner)
          SafeArea(bottom: false, child: const EmailVerificationBanner())
        else
          const SizedBox.shrink(),
        Expanded(child: child),
      ],
    );
  }
}
