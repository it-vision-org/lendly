import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_messages.dart';
import '../../../../core/utils/email_mask.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/otp_code_field.dart';

const _initialResendCooldownSeconds = 60;

class PasswordResetOtpPage extends ConsumerStatefulWidget {
  const PasswordResetOtpPage({required this.email, super.key});

  final String email;

  @override
  ConsumerState<PasswordResetOtpPage> createState() =>
      _PasswordResetOtpPageState();
}

class _PasswordResetOtpPageState extends ConsumerState<PasswordResetOtpPage> {
  final _otpKey = GlobalKey<OtpCodeFieldState>();

  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;
  int _remainingSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown(_initialResendCooldownSeconds);
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
                'Verify your identity',
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
                maskEmail(widget.email),
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
      final resetToken = await ref
          .read(authRepositoryProvider)
          .verifyPasswordResetCode(email: widget.email, code: code);
      if (mounted) {
        context.push('/password-reset/new-password', extra: resetToken);
      }
    } catch (error) {
      _otpKey.currentState?.clear();
      if (mounted) {
        setState(() {
          _error = friendlyErrorMessage(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .resendPasswordResetCode(email: widget.email);
      _startCooldown(_initialResendCooldownSeconds);
    } catch (error) {
      setState(() => _error = friendlyErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }
}
