import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../contacts/data/models/contact.dart';

/// A modern, tappable field for choosing a transaction's contact. Opens a
/// bottom sheet with search + a persistent "Add new contact" action, so the
/// user can always create a contact from here — not just when the list is
/// empty. Picking "Add new contact" pushes the contact form and, on success,
/// auto-selects the newly created contact.
class ContactSelectField extends StatelessWidget {
  const ContactSelectField({
    required this.contacts,
    required this.selectedContactId,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
    super.key,
  });

  final List<Contact> contacts;
  final String? selectedContactId;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? errorText;

  Contact? get _selected {
    for (final contact in contacts) {
      if (contact.id == selectedContactId) return contact;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? () => _openPicker(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Contact',
          errorText: errorText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              CircleAvatar(
                radius: 14,
                child: Text(
                  selected.name.isNotEmpty
                      ? selected.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                selected?.name ?? 'Select a contact',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: selected == null
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ContactPickerSheet(
        contacts: contacts,
        selectedContactId: selectedContactId,
      ),
    );
    if (result != null) {
      onChanged(result.id);
    }
  }
}

class _ContactPickerSheet extends StatefulWidget {
  const _ContactPickerSheet({
    required this.contacts,
    required this.selectedContactId,
  });

  final List<Contact> contacts;
  final String? selectedContactId;

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.contacts
        : widget.contacts
              .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Select contact',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search contacts',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person_add_alt_1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          'Add new contact',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () async {
                          final created = await context.push<Contact>(
                            '/contacts/new',
                          );
                          if (created != null && context.mounted) {
                            Navigator.of(context).pop(created);
                          }
                        },
                      ),
                      if (filtered.isNotEmpty) const Divider(height: 1),
                      if (filtered.isEmpty && _query.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No contacts match "$_query"',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      else
                        ...filtered.map(
                          (contact) => ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                contact.name.isNotEmpty
                                    ? contact.name[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(contact.name),
                            trailing: contact.id == widget.selectedContactId
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(contact),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
