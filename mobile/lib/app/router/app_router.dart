import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_email_args.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/contacts/data/models/contact.dart';
import '../../features/contacts/presentation/pages/contact_detail_page.dart';
import '../../features/contacts/presentation/pages/contact_form_page.dart';
import '../../features/contacts/presentation/pages/contacts_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/edit_name_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/transactions/data/models/transaction.dart';
import '../../features/transactions/presentation/pages/transaction_detail_page.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../widgets/main_shell.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier();
  ref.listen(
    authControllerProvider,
    (previous, next) => refreshNotifier.notify(),
  );
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isInitializing = authState.isLoading && !authState.hasValue;
      final location = state.matchedLocation;

      if (isInitializing) {
        return location == '/splash' ? null : '/splash';
      }

      final isLoggedIn = authState.value != null;
      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/verify-email';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && (isAuthRoute || location == '/splash')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) =>
            VerifyEmailPage(args: state.extra as VerifyEmailArgs),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                name: 'transactions',
                builder: (context, state) => const TransactionsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contacts',
                name: 'contacts',
                builder: (context, state) => const ContactsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/transactions/new',
        name: 'transaction-new',
        builder: (context, state) => const TransactionFormPage(),
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        name: 'transaction-edit',
        builder: (context, state) =>
            TransactionFormPage(transaction: state.extra as Transaction?),
      ),
      GoRoute(
        path: '/transactions/:id',
        name: 'transaction-detail',
        builder: (context, state) =>
            TransactionDetailPage(transactionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/contacts/new',
        name: 'contact-new',
        builder: (context, state) => const ContactFormPage(),
      ),
      GoRoute(
        path: '/contacts/:id/edit',
        name: 'contact-edit',
        builder: (context, state) =>
            ContactFormPage(contact: state.extra as Contact?),
      ),
      GoRoute(
        path: '/contacts/:id',
        name: 'contact-detail',
        builder: (context, state) =>
            ContactDetailPage(contactId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile/edit-name',
        name: 'profile-edit-name',
        builder: (context, state) =>
            EditNamePage(currentName: state.extra as String),
      ),
      GoRoute(
        path: '/profile/change-password',
        name: 'profile-change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
    ],
  );
});
