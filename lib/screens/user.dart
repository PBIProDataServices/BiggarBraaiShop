import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:biggar_braai_shop/providers/dark_theme_provider.dart';
import 'package:biggar_braai_shop/providers/partner_provider.dart';
import 'package:biggar_braai_shop/services/global_methods.dart';
import 'package:biggar_braai_shop/services/utils.dart';
import 'package:biggar_braai_shop/widgets/text_widget.dart';
import 'package:biggar_braai_shop/widgets/delete_account_widget.dart';
import 'package:biggar_braai_shop/screens/auth/login.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:biggar_braai_shop/consts/firebase_consts.dart';
import 'package:biggar_braai_shop/screens/auth/forget_pass.dart';
import 'package:biggar_braai_shop/screens/loading_manager.dart';
import 'package:flutter/services.dart';
//import 'package:url_launcher/url_launcher.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final TextEditingController _addressTextController =
      TextEditingController(text: "");
  final TextEditingController _preferredPartnerIDTextController =
      TextEditingController(text: "");
  
  @override
  void dispose() {
    _addressTextController.dispose();
    super.dispose();
  }

  String? _email;
  String? _name;
  String? address;
  String? _PreferredPartnerId;
  String? _role;

  bool _isLoading = false;
  final User? user = authInstance.currentUser;
  @override
  void initState() {
    getUserData();
    super.initState();
  }

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      String _uid = user!.uid;
      final themeState = Provider.of<DarkThemeProvider>(context, listen: false);

      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (!userDoc.exists) {
        return;
      } else {
        _email = userDoc.get('email');
        _name = userDoc.get('name');
        address = userDoc.get('shipping-address');
        _role = userDoc.get('userRole');
        _addressTextController.text = userDoc.get('shipping-address');
        _preferredPartnerIDTextController.text = userDoc.get('preferredPartnerID');
        _PreferredPartnerId=userDoc.get('preferredPartnerID');
        
        // Load theme preference if available
        if (userDoc.data() != null && (userDoc.data() as Map<String, dynamic>).containsKey('darkMode')) {
          bool darkMode = userDoc.get('darkMode');
          // Only update the theme if it's different from current setting
          if (darkMode != themeState.getDarkTheme) {
            themeState.setDarkTheme = darkMode;
          }
        }
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      GlobalMethods.errorDialog(subtitle: '$error', context: context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context);
    final partnerProvider = Provider.of<PartnerProvider>(context);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;
    final bool hasPartners = partnerProvider.getPartners.isNotEmpty;
    
    return Scaffold(
        body: LoadingManager(
      isLoading: _isLoading,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 15,
                ),
                RichText(
                  text: TextSpan(
                    text:  _role ?? '',
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                          text: _name ?? 'user',
                          style: TextStyle(
                            color: color,
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              print('My name is pressed');
                            }),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                TextWidget(
                  text: _email == null ? 'Email' : _email!,
                  color: color,
                  textSize: 18,
                  // isTitle: true,
                ),
                const SizedBox(
                  height: 20,
                ),
                const Divider(
                  thickness: 2,
                ),
                const SizedBox(
                  height: 20,
                ),
                _listTiles(
                  title: 'Billing Address',
                  subtitle: address,
                  icon: IconlyLight.profile,
                  onPressed: () async {
                    await _showAddressDialog();
                  },
                  color: color,
                ),
                // Only show Preferred Partner option if user has partners
                if (hasPartners)
                  _listTiles(
                    title: 'Preffered Partner',
                    subtitle: _PreferredPartnerId.toString(),
                    icon: IconlyLight.ticket,
                    onPressed: () async {
                      await _showPartnerDialog();
                    },
                    color: color,
                  ),

               /* _listTiles(
                  title: 'Viewed',
                  icon: IconlyLight.show,
                  onPressed: () {
                    GlobalMethods.navigateTo(
                        ctx: context,
                        routeName: ViewedRecentlyScreen.routeName);
                  },
                  color: color,
                ),*/
                _listTiles(
                  title: 'Forget password',
                  icon: IconlyLight.unlock,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ForgetPasswordScreen(),
                      ),
                    );
                  },
                  color: color,
                ),
                SwitchListTile(
                  title: TextWidget(
                    text: themeState.getDarkTheme ? 'Dark mode' : 'Light mode',
                    color: color,
                    textSize: 18,
                    // isTitle: true,
                  ),
                  secondary: Icon(themeState.getDarkTheme
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined),
                  onChanged: (bool value) async {
                    setState(() {
                      themeState.setDarkTheme = value;
                    });
                    
                    // Save theme preference to user model if logged in
                    if (user != null) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .update({
                          'darkMode': value,
                        });
                      } catch (err) {
                        // Silently handle error - theme will still be saved locally
                        print('Error saving theme preference: $err');
                      }
                    }
                  },
                  value: themeState.getDarkTheme,
                ),
                _listTiles(
                  title: user == null ? 'Login' : 'Logout',
                  icon: user == null ? IconlyLight.login : IconlyLight.logout,
                  onPressed: () {
                    if (user == null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                      return;
                    }
                    GlobalMethods.warningDialog(
                        title: 'Sign out',
                        subtitle: 'Do you wanna sign out?',
                        fct: () async {
                          await authInstance.signOut();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        context: context);
                  },
                  color: color,
                ),
                // Add some spacing before delete account
                const SizedBox(height: 20),
                // Add the delete account widget
                const DeleteAccountWidget(),
                // listTileAsRow(),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> _showAddressDialog() async {
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Update'),
            content: TextField(
              // onChanged: (value) {
              //   print('_addressTextController.text ${_addressTextController.text}');
              // },
              controller: _addressTextController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: "Your address"),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  String _uid = user!.uid;
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_uid)
                        .update({
                      'shipping-address': _addressTextController.text,
                    });

                    Navigator.pop(context);
                    setState(() {
                      address = _addressTextController.text;
                    });
                  } catch (err) {
                    GlobalMethods.errorDialog(
                        subtitle: err.toString(), context: context);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        });
  }

  Future<void> _showPartnerDialog() async {
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: TextWidget(
              text: 'Update Partner',
              color: Utils(context).color,
              textSize: 18,
              isTitle: true,
            ),
            content: TextField(
              controller: _preferredPartnerIDTextController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Select Partner",
                hintStyle: TextStyle(color: Utils(context).color.withOpacity(0.5)),
                labelStyle: TextStyle(color: Utils(context).color),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Utils(context).color.withOpacity(0.5)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Utils(context).color),
                ),
              ),
              style: TextStyle(color: Utils(context).color),
            ),
            
            actions: [
              TextButton(
                onPressed: () async {
                  String _uid = user!.uid;
                  try {
                    await FirebaseFirestore.instance
                        .collection('partners')
                        .doc(_uid)
                        .update({
                      'preferredPartnerID': _preferredPartnerIDTextController.text,
                    });

                    Navigator.pop(context);
                    setState(() {
                      address = _preferredPartnerIDTextController.text;
                    });
                  } catch (err) {
                    GlobalMethods.errorDialog(
                        subtitle: err.toString(), context: context);
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
                child: TextWidget(
                  text: 'Update',
                  color: Colors.white,
                  textSize: 16,
                ),
              ),
            ],
          );
        });
  }

  Widget _listTiles({
    required String title,
    String? subtitle,
    required IconData icon,
    required Function onPressed,
    required Color color,
  }) {
    return ListTile(
      title: TextWidget(
        text: title,
        color: color,
        textSize: 22,
        fontWeight: FontWeight.w600,
      ),
      subtitle: TextWidget(
        text: subtitle ?? "",
        color: color.withOpacity(0.7),
        textSize: 18,
      ),
      leading: Icon(icon, color: color),
      trailing: Icon(IconlyLight.arrowRight2, color: color),
      onTap: () {
        onPressed();
      },
    );
  }

// // Alternative code for the listTile.
//   Widget listTileAsRow() {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         children: <Widget>[
//           const Icon(Icons.settings),
//           const SizedBox(width: 10),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text('Title'),
//               Text('Subtitle'),
//             ],
//           ),
//           const Spacer(),
//           const Icon(Icons.chevron_right)
//         ],
//       ),
//     );
//   }
}
