import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../consts/firebase_consts.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/user_provider.dart';
import '../../screens/loading_manager.dart';
import '../../services/global_methods.dart';
import '../../services/stripe_service.dart';
import '../../widgets/robot_check.dart';
import '../../widgets/text_widget.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/Checkout';
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _notARobot = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = authInstance.currentUser;
    final profile = Provider.of<UserProvider>(context, listen: false).currentUser;
    _nameController.text = profile?.name ?? user?.displayName ?? '';
    _emailController.text = profile?.email ?? user?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<User> _ensureFirebaseUser() async {
    final existing = authInstance.currentUser;
    if (existing != null) return existing;
    final credential = await authInstance.signInAnonymously();
    return credential.user!;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_notARobot) {
      GlobalMethods.errorDialog(
        subtitle: 'Please confirm you are not a robot before paying.',
        context: context,
      );
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    final orders = Provider.of<OrdersProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final wasGuest = authInstance.currentUser == null ||
          (authInstance.currentUser?.isAnonymous ?? false);
      await _ensureFirebaseUser();

      final amountPence = (cart.total * 100).round();
      if (amountPence < 30) {
        throw Exception('Basket total is too low to charge.');
      }

      if (kIsWeb) {
        Fluttertoast.showToast(
          msg: 'Taking card payment…',
        );
      }

      final payment = await StripeService.createPayout(
        partnerId: cart.items.values.first.partnerId,
        amount: amountPence,
        currency: 'gbp',
        email: _emailController.text.trim(),
      );

      if (payment['success'] != true) {
        throw Exception(payment['error'] ?? 'Payment was cancelled.');
      }

      await orders.placeOrder(
        items: cart.items.values.toList(),
        total: cart.total,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        isGuest: wasGuest,
      );
      cart.clear();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Order placed'),
          content: const Text(
            'Thanks. Your order is with the partner who received that delivery.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      GlobalMethods.errorDialog(subtitle: error.toString(), context: context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest checkout'),
      ),
      body: LoadingManager(
        isLoading: _isLoading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextWidget(
              text: 'Total  £${cart.total.toStringAsFixed(2)}',
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              textSize: 22,
              isTitle: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'No account needed. We only use these details for this order.',
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (value) =>
                        (value == null || value.trim().length < 7)
                            ? 'Enter a phone number'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Delivery / collection notes',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Enter an address or collection note'
                            : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            RobotCheck(
              value: _notARobot,
              onChanged: (value) => setState(() => _notARobot = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Pay and place order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
