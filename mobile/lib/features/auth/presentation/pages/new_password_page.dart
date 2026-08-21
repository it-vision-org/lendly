import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_messages.dart';
import '../../../../core/widgets/password_field.dart';
import '../controllers/auth_controller.dart';

class NewPasswordPage extends ConsumerStatefulWidget {
  const NewPasswordPage({required this.resetToken, super.key});

  final String resetToken;

  @override
  ConsumerState<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends ConsumerState<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create new password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter your new password.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _newPasswordController,
                  enabled: !_isSaving,
                  labelText: 'New password',
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) => (value == null || value.length < 8)
                      ? 'At least 8 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmPasswordController,
                  enabled: !_isSaving,
                  labelText: 'Confirm password',
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) => value != _newPasswordController.text
                      ? 'The passwords don\'t match'
                      : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reset password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .completePasswordReset(
            resetToken: widget.resetToken,
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          );
      // On success authControllerProvider becomes AsyncData(user) and the
      // router redirects to /home automatically, replacing the whole
      // navigation stack (forgot-password/otp/new-password screens included).
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = friendlyErrorMessage(error);
        });
      }
    }
  }
}
