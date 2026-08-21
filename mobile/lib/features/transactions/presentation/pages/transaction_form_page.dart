import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/error_messages.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';
import '../../data/repositories/transaction_repository.dart';
import '../controllers/transaction_detail_controller.dart';
import '../controllers/transactions_controller.dart';
import '../widgets/contact_select_field.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({this.transaction, super.key});

  final Transaction? transaction;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _amountController = TextEditingController(
    text: widget.transaction?.originalAmount.toString(),
  );
  late final _currencyController = TextEditingController(
    text: widget.transaction?.currency ?? 'TND',
  );
  late final _descriptionController = TextEditingController(
    text: widget.transaction?.description,
  );

  late TransactionType _type = widget.transaction?.type ?? TransactionType.lent;
  late DateTime _date = widget.transaction?.transactionDate ?? DateTime.now();
  String? _contactId;

  bool _isSaving = false;
  String? _error;
  String? _contactError;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _contactId = widget.transaction?.contactId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit transaction' : 'Add transaction'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.lent,
                      label: Text('I lent'),
                    ),
                    ButtonSegment(
                      value: TransactionType.borrowed,
                      label: Text('I borrowed'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: _isSaving
                      ? null
                      : (value) => setState(() => _type = value.first),
                ),
                const SizedBox(height: 20),
                contactsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(friendlyErrorMessage(error)),
                  data: (contacts) => ContactSelectField(
                    contacts: contacts,
                    selectedContactId: _contactId,
                    enabled: !_isSaving,
                    errorText: _contactError,
                    onChanged: (value) => setState(() {
                      _contactId = value;
                      _contactError = null;
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amountController,
                        enabled: !_isSaving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Amount'),
                        validator: (value) {
                          final amount = num.tryParse(value ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _currencyController,
                        enabled: !_isSaving,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 3,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          counterText: '',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('d MMM yyyy').format(_date)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _isSaving ? null : _pickDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSaving,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description / reason (optional)',
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
                      : Text(_isEditing ? 'Save changes' : 'Add transaction'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final hasContact = _contactId != null;

    if (!hasContact) {
      setState(() => _contactError = 'Choose a contact');
    }
    if (!isFormValid || !hasContact) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final amount = num.parse(_amountController.text);
      final currency = _currencyController.text.trim().toUpperCase();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      if (_isEditing) {
        await repo.update(
          id: widget.transaction!.id,
          contactId: _contactId!,
          type: _type,
          amount: amount,
          currency: currency,
          description: description,
          transactionDate: _date,
        );
        ref.invalidate(transactionDetailProvider(widget.transaction!.id));
      } else {
        await repo.create(
          contactId: _contactId!,
          type: _type,
          amount: amount,
          currency: currency,
          description: description,
          transactionDate: _date,
        );
      }

      ref.invalidate(transactionsControllerProvider);
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(recentTransactionsProvider);
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
