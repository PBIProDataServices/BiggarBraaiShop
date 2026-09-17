import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import 'package:biggar_braai_shop/consts/contss.dart';
import 'package:biggar_braai_shop/consts/firebase_consts.dart';
import 'package:biggar_braai_shop/providers/shop_inventory_provider.dart';
import 'package:biggar_braai_shop/providers/user_provider.dart';
import 'package:biggar_braai_shop/screens/btm_bar.dart';

class FetchScreen extends StatefulWidget {
  const FetchScreen({Key? key}) : super(key: key);

  @override
  State<FetchScreen> createState() => _FetchScreenState();
}

class _FetchScreenState extends State<FetchScreen> {
  List<String> images = Constss.authImagesPaths;

  @override
  void initState() {
    images.shuffle();
    Future.delayed(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      final User? user = authInstance.currentUser;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final inventory =
          Provider.of<ShopInventoryProvider>(context, listen: false);

      if (user != null && !user.isAnonymous) {
        try {
          await userProvider.fetchUserData();
        } catch (error) {
          debugPrint('Could not load profile: $error');
        }
      }

      await inventory.start();

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const BottomBarScreen(),
        ));
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            images[0],
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.7),
          ),
          const Center(
            child: SpinKitFadingFour(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
