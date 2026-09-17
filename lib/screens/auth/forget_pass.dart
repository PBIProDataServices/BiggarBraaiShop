import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:biggar_braai_shop/consts/contss.dart';
import 'package:biggar_braai_shop/consts/firebase_consts.dart';
import 'package:biggar_braai_shop/screens/loading_manager.dart';
import 'package:biggar_braai_shop/services/global_methods.dart';
import 'package:biggar_braai_shop/services/utils.dart';
import 'package:biggar_braai_shop/widgets/auth_button.dart';
import 'package:biggar_braai_shop/widgets/back_widget.dart';
import 'package:biggar_braai_shop/widgets/text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:biggar_braai_shop/providers/dark_theme_provider.dart';

class ForgetPasswordScreen extends StatefulWidget {
  static const routeName = '/ForgetPasswordScreen';
  const ForgetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _emailTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailTextController.dispose();
    super.dispose();
  }

  void _forgetPassFCT() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (isValid) {
      setState(() {
        _isLoading = true;
      });
      try {
        await authInstance.sendPasswordResetEmail(
          email: _emailTextController.text.toLowerCase().trim(),
        );
        if (mounted) {
          GlobalMethods.errorDialog(
            subtitle: 'An email has been sent to reset your password',
            context: context,
          );
        }
      } on FirebaseException catch (error) {
        GlobalMethods.errorDialog(
          subtitle: '${error.message}',
          context: context,
        );
      } catch (error) {
        GlobalMethods.errorDialog(
          subtitle: '$error',
          context: context,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;
    final Color backgroundColor = themeState.getDarkTheme ? Colors.black : Colors.white;
    final Color overlayColor = themeState.getDarkTheme 
        ? Colors.black.withOpacity(0.7) 
        : Colors.white.withOpacity(0.7);

    return Scaffold(
      body: LoadingManager(
        isLoading: _isLoading,
        child: Stack(children: [
          Image.asset(
            'assets/images/landing/6.png',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Container(
            color: overlayColor,
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(
                    height: 40.0,
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.canPop(context)
                        ? Navigator.pop(context)
                        : null,
                    child: Icon(
                      IconlyLight.arrowLeft2,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(
                    height: 40.0,
                  ),
                  TextWidget(
                    text: 'Forget password',
                    color: color,
                    textSize: 30,
                    isTitle: true,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextWidget(
                    text: "Enter the email address you used when you joined and we'll send you instructions to reset your password.",
                    color: color.withOpacity(0.9),
                    textSize: 18,
                    isTitle: false,
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () {
                        _forgetPassFCT();
                      },
                      controller: _emailTextController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                      style: TextStyle(color: color),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: color.withOpacity(0.7)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: color),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: color),
                        ),
                        errorBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  AuthButton(
                    fct: _forgetPassFCT,
                    buttonText: 'Reset now',
                  ),
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }
}
