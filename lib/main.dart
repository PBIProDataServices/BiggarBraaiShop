import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:flutter/material.dart';
import 'package:biggar_braai_shop/providers/dark_theme_provider.dart';
import 'package:biggar_braai_shop/providers/user_provider.dart';
import 'package:biggar_braai_shop/providers/cart_provider.dart';
import 'package:biggar_braai_shop/providers/shop_inventory_provider.dart';
import 'package:biggar_braai_shop/providers/orders_provider.dart';
import 'package:provider/provider.dart';

import 'package:biggar_braai_shop/consts/theme_data.dart';
import 'package:biggar_braai_shop/fetch_screen.dart';
import 'package:biggar_braai_shop/screens/auth/forget_pass.dart';
import 'package:biggar_braai_shop/screens/auth/login.dart';
import 'package:biggar_braai_shop/screens/auth/register.dart';
import 'package:biggar_braai_shop/screens/shop/checkout_screen.dart';
import 'package:biggar_braai_shop/screens/shop/listing_details_screen.dart';
import 'package:biggar_braai_shop/screens/shop/orders_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  Stripe.publishableKey =
      'pk_live_51K2Og6RnlFRMO2nqu2kJOL4LABn7RfWAjITTXp9dgPXI4N36eMFcit34FKLt2abXOomUMH6pHPa4qpOGRhRMyOwg00WxFpUP4f';
  Stripe.merchantIdentifier = 'Biggar Braai Shop';
  if (!kIsWeb) {
    await Stripe.instance.applySettings();
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  @override
  void initState() {
    getCurrentAppTheme();
    super.initState();
  }

  @override
  void dispose() {
    themeChangeProvider.dispose();
    super.dispose();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.setDarkTheme =
        await themeChangeProvider.darkThemePrefs.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: themeChangeProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ShopInventoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => OrdersProvider(),
        ),
      ],
      child: Consumer<DarkThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Biggar Braai Shop',
            theme: Styles.themeData(themeProvider.getDarkTheme, context),
            home: const FetchScreen(),
            routes: {
              RegisterScreen.routeName: (ctx) => const RegisterScreen(),
              LoginScreen.routeName: (ctx) => const LoginScreen(),
              ForgetPasswordScreen.routeName: (ctx) =>
                  const ForgetPasswordScreen(),
              ListingDetailsScreen.routeName: (ctx) =>
                  const ListingDetailsScreen(),
              CheckoutScreen.routeName: (ctx) => const CheckoutScreen(),
              OrdersScreen.routeName: (ctx) => const OrdersScreen(),
            },
          );
        },
      ),
    );
  }
}
