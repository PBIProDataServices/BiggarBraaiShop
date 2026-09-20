import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../consts/firebase_consts.dart';
import '../../providers/dark_theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../screens/auth/login.dart';
import '../../screens/auth/register.dart';
import '../../services/utils.dart';
import '../../widgets/text_widget.dart';
import 'orders_screen.dart';
import 'batches_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authInstance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? authInstance.currentUser;
        final userProvider = Provider.of<UserProvider>(context);
        final theme = Provider.of<DarkThemeProvider>(context);
        final color = Utils(context).color;
        final isGuest = user == null || user.isAnonymous;
        return _AccountBody(
          user: user,
          isGuest: isGuest,
          userProvider: userProvider,
          theme: theme,
          color: color,
        );
      },
    );
  }
}

class _AccountBody extends StatelessWidget {
  const _AccountBody({
    required this.user,
    required this.isGuest,
    required this.userProvider,
    required this.theme,
    required this.color,
  });

  final User? user;
  final bool isGuest;
  final UserProvider userProvider;
  final DarkThemeProvider theme;
  final Color color;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Account',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextWidget(
            text: isGuest
                ? 'You are shopping as a guest'
                : (userProvider.currentUser?.name ?? user?.email ?? 'Customer'),
            color: color,
            textSize: 20,
            isTitle: true,
          ),
          const SizedBox(height: 8),
          Text(
            isGuest
                ? 'You can buy biltong without an account. Sign in to follow batch progress and see when stock is likely to become available.'
                : (user?.email ?? ''),
            style: TextStyle(color: Utils(context).secondaryColor),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Orders'),
            onTap: () {
              Navigator.of(context).pushNamed(OrdersScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.timelapse),
            title: const Text('Batch progress'),
            subtitle: Text(
              isGuest
                  ? 'Sign in to see current batches'
                  : 'See how batches are progressing',
            ),
            onTap: () {
              if (isGuest) {
                Navigator.of(context).pushNamed(LoginScreen.routeName);
              } else {
                Navigator.of(context).pushNamed(BatchesScreen.routeName);
              }
            },
          ),
          SwitchListTile(
            title: const Text('Dark theme'),
            value: theme.getDarkTheme,
            onChanged: (value) => theme.setDarkTheme = value,
          ),
          if (isGuest) ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign in'),
              onTap: () {
                Navigator.of(context).pushNamed(LoginScreen.routeName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Create an account'),
              onTap: () {
                Navigator.of(context).pushNamed(RegisterScreen.routeName);
              },
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                await userProvider.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out. You can still shop as a guest.')),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
