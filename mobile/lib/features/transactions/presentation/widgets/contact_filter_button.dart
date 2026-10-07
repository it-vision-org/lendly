import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../contacts/data/models/contact.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';

/// A pill-shaped button that narrows the transactions list to one contact.
/// Shows "All contacts" when nothing is picked; once a contact is picked it
/// highlights with the contact's avatar + name and a quick clear (×) action.
/// Tapping opens a searchable bottom sheet of contacts.
class ContactFilterButton extends StatelessWidget {
  const ContactFilterButton({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Contact? selected;

  /// Called with the picked contact, or `null` to show all contacts.
  final ValueChanged<Contact?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final contact = selected;
    final isActive = contact != null;

    return Material(
      color: isActive
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      shape: StadiumBorder(
        side: BorderSide(
          color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPicker(context),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Padding(
            padding: EdgeInsets.fromLTRB(6, 6, isActive ? 4 : 14, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  _Avatar(name: contact.name, radius: 14)
                else
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.people_alt_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    isActive ? contact.name : 'All contacts',
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isActive)
                  IconButton(
                    tooltip: 'Clear contact filter',
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => onChanged(null),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  )
                else ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<_PickerResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => _ContactFilterSheet(selectedContactId: selected?.id),
    );
    if (result != null) onChanged(result.contact);
  }
}

/// Wraps the sheet's answer so "All contacts" (`null`) can be told apart from
/// the sheet being dismissed without a choice.
class _PickerResult {
  const _PickerResult(this.contact);

  final Contact? contact;
}

class _ContactFilterSheet extends ConsumerStatefulWidget {
  const _ContactFilterSheet({required this.selectedContactId});

  final String? selectedContactId;

  @override
  ConsumerState<_ContactFilterSheet> createState() =>
      _ContactFilterSheetState();
}

class _ContactFilterSheetState extends ConsumerState<_ContactFilterSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contactsAsync = ref.watch(contactsControllerProvider);

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
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(
                    'Filter by contact',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Only show transactions with the person you pick.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search contacts',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: contactsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => ErrorView(
                      error: error,
                      onRetry: () => ref
                          .read(contactsControllerProvider.notifier)
                          .refresh(),
                    ),
                    data: (contacts) =>
                        _buildList(context, scrollController, contacts),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    ScrollController scrollController,
    List<Contact> contacts,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? contacts
        : contacts.where((c) => c.name.toLowerCase().contains(query)).toList();
    final allSelected = widget.selectedContactId == null;

    Widget? checkMark(bool selected) =>
        selected ? Icon(Icons.check_circle, color: colorScheme.primary) : null;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (query.isEmpty) ...[
          ListTile(
            selected: allSelected,
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.people_alt_outlined,
                color: colorScheme.primary,
              ),
            ),
            title: const Text(
              'All contacts',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Show everyone\'s transactions'),
            trailing: checkMark(allSelected),
            onTap: () => Navigator.of(context).pop(const _PickerResult(null)),
          ),
          if (contacts.isNotEmpty) const Divider(height: 1),
        ],
        if (contacts.isEmpty)
          _SheetMessage(
            icon: Icons.person_off_outlined,
            text: 'You have no contacts yet',
          )
        else if (filtered.isEmpty)
          _SheetMessage(
            icon: Icons.search_off,
            text: 'No contacts match "${_query.trim()}"',
          )
        else
          ...filtered.map((contact) {
            final isSelected = contact.id == widget.selectedContactId;
            return ListTile(
              selected: isSelected,
              leading: _Avatar(name: contact.name, radius: 20),
              title: Text(contact.name, overflow: TextOverflow.ellipsis),
              trailing: checkMark(isSelected),
              onTap: () => Navigator.of(context).pop(_PickerResult(contact)),
            );
          }),
      ],
    );
  }
}

class _SheetMessage extends StatelessWidget {
  const _SheetMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 36, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: radius * 0.9),
      ),
    );
  }
}
