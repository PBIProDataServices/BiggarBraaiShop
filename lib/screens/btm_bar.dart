import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';

import 'package:biggar_braai_shop/providers/cart_provider.dart';
import 'package:biggar_braai_shop/providers/dark_theme_provider.dart';
import 'package:biggar_braai_shop/screens/shop/account_screen.dart';
import 'package:biggar_braai_shop/screens/shop/cart_screen.dart';
import 'package:biggar_braai_shop/screens/shop/home_screen.dart';
import 'package:biggar_braai_shop/widgets/text_widget.dart';

class BottomBarScreen extends StatefulWidget {
  const BottomBarScreen({Key? key}) : super(key: key);

  @override
  State<BottomBarScreen> createState() => _BottomBarScreenState();
}

class _BottomBarScreenState extends State<BottomBarScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    CartScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context);
    final isDark = themeState.getDarkTheme;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        unselectedItemColor: isDark ? Colors.white30 : Colors.black38,
        selectedItemColor: isDark ? Colors.lightBlue.shade200 : Colors.black87,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 0 ? IconlyBold.home : IconlyLight.home),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Consumer<CartProvider>(
              builder: (_, cart, __) {
                return Badge(
                  isLabelVisible: cart.itemCount > 0,
                  label: TextWidget(
                    text: cart.itemCount.toString(),
                    color: Colors.white,
                    textSize: 12,
                  ),
                  child: Icon(
                    _selectedIndex == 1 ? IconlyBold.buy : IconlyLight.buy,
                  ),
                );
              },
            ),
            label: 'Basket',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 2 ? IconlyBold.user2 : IconlyLight.user2,
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
