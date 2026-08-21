import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/contact.dart';
import '../../data/repositories/contact_repository.dart';

final contactsControllerProvider =
    AsyncNotifierProvider.autoDispose<ContactsController, List<Contact>>(
      ContactsController.new,
    );

class ContactsController extends AsyncNotifier<List<Contact>> {
  @override
  FutureOr<List<Contact>> build() {
    return ref.watch(contactRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(contactRepositoryProvider).list(),
    );
  }
}

/// A single contact, fetched fresh (with up-to-date balances) for the detail screen.
final contactProvider = FutureProvider.autoDispose.family<Contact, String>((
  ref,
  id,
) {
  return ref.watch(contactRepositoryProvider).get(id);
});
