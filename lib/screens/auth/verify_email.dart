import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:biggar_braai_shop/fetch_screen.dart';
import 'package:biggar_braai_shop/providers/user_provider.dart';
import 'package:biggar_braai_shop/services/global_methods.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;
  bool _resending = false;

  Future<void> _resendVerification() async {
    try {
      setState(() => _resending = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        GlobalMethods.errorDialog(subtitle: '$e', context: context);
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _checkVerifiedAndContinue() async {
    try {
      setState(() => _checking = true);
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed != null && refreshed.emailVerified) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.fetchUserData();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const FetchScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email not verified yet. Please verify and try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        GlobalMethods.errorDialog(subtitle: '$e', context: context);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'We\'ve sent a verification link to:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.email,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Text(
              'Please verify your email address. Once verified, tap the button below to continue.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resending ? null : _resendVerification,
                    child: _resending
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Resend email'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checking ? null : _checkVerifiedAndContinue,
                    child: _checking
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('I\'ve verified'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
