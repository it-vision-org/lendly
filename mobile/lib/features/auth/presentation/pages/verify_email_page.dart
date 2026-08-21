import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_messages.dart';
import '../../data/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_code_field.dart';
import 'verify_email_args.dart';

String _maskEmail(String email) {
  final atIndex = email.indexOf('@');
  if (atIndex <= 0) return email;
  final local = email.substring(0, atIndex);
  final domain = email.substring(atIndex);
  final visibleCount = local.length > 2 ? 2 : 1;
  return '${local.substring(0, visibleCount)}***$domain';
}

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({required this.args, super.key});

  final VerifyEmailArgs args;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final _otpKey = GlobalKey<OtpCodeFieldState>();
  late String _verificationId = widget.args.verificationId;

  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;
  int _remainingSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown(widget.args.resendCooldownSeconds);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _remainingSeconds = seconds);
    if (seconds <= 0) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              Text(
                _maskEmail(widget.args.email),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OtpCodeField(
                key: _otpKey,
                length: 6,
                enabled: !_isVerifying && !_isResending,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onCompleted: _handleVerify,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: (_isVerifying || _isResending)
                    ? null
                    : () => _handleVerify(_otpKey.currentState?.code ?? ''),
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed:
                      (_remainingSeconds > 0 || _isResending || _isVerifying)
                      ? null
                      : _handleResend,
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _remainingSeconds > 0
                              ? "Didn't receive the code? Resend in ${_remainingSeconds}s"
                              : "Didn't receive the code? Resend",
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerify(String code) async {
    if (_isVerifying || code.length != 6) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyEmail(verificationId: _verificationId, code: code);
      // On success authControllerProvider becomes AsyncData(user) and the
      // router redirects to /home automatically.
    } catch (error) {
      _otpKey.currentState?.clear();
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _error = friendlyErrorMessage(error);
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      final challenge = await ref
          .read(authRepositoryProvider)
          .resendVerificationCode(verificationId: _verificationId);
      _verificationId = challenge.verificationId;
      _startCooldown(challenge.resendCooldownSeconds);
    } catch (error) {
      setState(() => _error = friendlyErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }
}
