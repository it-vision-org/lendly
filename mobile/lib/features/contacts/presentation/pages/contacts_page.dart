import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_semantic_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../controllers/contacts_controller.dart';

class ContactsPage extends ConsumerWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsControllerProvider);
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/contacts/new'),
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(contactsControllerProvider.notifier).refresh(),
        child: contactsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.read(contactsControllerProvider.notifier).refresh(),
          ),
          data: (contacts) {
            if (contacts.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: EmptyState(
                      icon: Icons.people_outline,
                      title: 'No contacts yet',
                      message: 'Add the people you lend to or borrow from.',
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 96, top: 8),
              itemCount: contacts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                final netColor = contact.netBalance >= 0 ? semantic.success : semantic.warning;

                return ListTile(
                  onTap: () => context.push('/contacts/${contact.id}'),
                  leading: CircleAvatar(child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?')),
                  title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Owed to me: ${formatMoney(contact.totalOwedToMe, 'TND')} · I owe: ${formatMoney(contact.totalIOwe, 'TND')}',
                  ),
                  trailing: Text(
                    formatMoney(contact.netBalance, 'TND'),
                    style: TextStyle(fontWeight: FontWeight.w700, color: netColor),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
