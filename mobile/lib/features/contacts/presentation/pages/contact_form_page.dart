import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_messages.dart';
import '../../data/models/contact.dart';
import '../../data/repositories/contact_repository.dart';
import '../controllers/contacts_controller.dart';

class ContactFormPage extends ConsumerStatefulWidget {
  const ContactFormPage({this.contact, super.key});

  final Contact? contact;

  @override
  ConsumerState<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends ConsumerState<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.contact?.name);
  late final _phoneController = TextEditingController(text: widget.contact?.phone);
  late final _emailController = TextEditingController(text: widget.contact?.email);
  late final _notesController = TextEditingController(text: widget.contact?.notes);

  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.contact != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit contact' : 'New contact')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone (optional)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email (optional)'),
                  validator: (value) =>
                      (value != null && value.isNotEmpty && !value.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  enabled: !_isSaving,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save changes' : 'Add contact'),
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
      final repo = ref.read(contactRepositoryProvider);
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      if (_isEditing) {
        await repo.update(id: widget.contact!.id, name: name, phone: phone, email: email, notes: notes);
      } else {
        await repo.create(name: name, phone: phone, email: email, notes: notes);
      }

      ref.invalidate(contactsControllerProvider);
      if (mounted) context.pop();
    } catch (error) {
      setState(() {
        _isSaving = false;
        _error = friendlyErrorMessage(error);
      });
    }
  }
}
