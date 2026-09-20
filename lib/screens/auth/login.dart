import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biggar_braai_shop/consts/contss.dart';
import 'package:biggar_braai_shop/fetch_screen.dart';
import 'package:biggar_braai_shop/providers/dark_theme_provider.dart';
import 'package:biggar_braai_shop/providers/user_provider.dart';
import 'package:biggar_braai_shop/screens/auth/forget_pass.dart';
import 'package:biggar_braai_shop/screens/auth/register.dart';
import 'package:biggar_braai_shop/screens/loading_manager.dart';
import 'package:biggar_braai_shop/services/auth_service.dart';
import 'package:biggar_braai_shop/services/global_methods.dart';
import 'package:biggar_braai_shop/widgets/text_widget.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/LoginScreen';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailTextController = TextEditingController();
  final _passTextController = TextEditingController();
  final _passFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  var _obscureText = true;
  @override
  void dispose() {
    _emailTextController.dispose();
    _passTextController.dispose();
    _passFocusNode.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  void _submitFormOnLogin() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      try {
        await AuthService.signInWithEmail(
          email: _emailTextController.text.toLowerCase().trim(),
          password: _passTextController.text.trim(),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_user_email',
          _emailTextController.text.toLowerCase().trim(),
        );

        if (!mounted) return;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.fetchUserData();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const FetchScreen(),
            ),
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
    final Color cardColor = themeState.getDarkTheme ? const Color(0xFF1E1E1E) : const Color(0xFFF2FDFD);
    final Color overlayColor = themeState.getDarkTheme 
        ? Colors.black.withOpacity(0.7) 
        : Colors.white.withOpacity(0.7);

    return Scaffold(
      body: LoadingManager(
        isLoading: _isLoading,
        child: Stack(children: [
          Image.asset(
            Constss.authImagesPaths[0],
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Container(
            color: overlayColor,
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60.0),
                    // Main Card
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: 'Welcome Back',
                            color: color,
                            textSize: 28,
                            isTitle: true,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 8),
                          TextWidget(
                            text: "Sign in for batch progress and order history, or continue as a guest to buy biltong.",
                            color: color.withOpacity(0.7),
                            textSize: 16,
                            isTitle: false,
                          ),
                          const SizedBox(height: 32),
                          const SizedBox(height: 32),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email Field
                                TextFormField(
                                  textInputAction: TextInputAction.next,
                                  onEditingComplete: () => FocusScope.of(context)
                                      .requestFocus(_passFocusNode),
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
                                    hintStyle: TextStyle(color: color.withOpacity(0.6)),
                                    prefixIcon: Icon(
                                      IconlyLight.message,
                                      color: color.withOpacity(0.7),
                                    ),
                                    filled: true,
                                    fillColor: themeState.getDarkTheme 
                                        ? const Color(0xFF2A2A2A) 
                                        : Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: themeState.getDarkTheme ? Colors.blue[700]! : Colors.blue,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Password Field
                                TextFormField(
                                  textInputAction: TextInputAction.done,
                                  onEditingComplete: () {
                                    _submitFormOnLogin();
                                  },
                                  controller: _passTextController,
                                  focusNode: _passFocusNode,
                                  obscureText: _obscureText,
                                  keyboardType: TextInputType.visiblePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 7) {
                                      return 'Password must be at least 7 characters';
                                    }
                                    return null;
                                  },
                                  style: TextStyle(color: color),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle: TextStyle(color: color.withOpacity(0.6)),
                                    prefixIcon: Icon(
                                      IconlyLight.lock,
                                      color: color.withOpacity(0.7),
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                      child: Icon(
                                        _obscureText
                                            ? IconlyLight.show
                                            : IconlyLight.hide,
                                        color: color.withOpacity(0.7),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: themeState.getDarkTheme 
                                        ? const Color(0xFF2A2A2A) 
                                        : Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: themeState.getDarkTheme ? Colors.blue[700]! : Colors.blue,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                GlobalMethods.navigateTo(
                                    ctx: context,
                                    routeName: ForgetPasswordScreen.routeName);
                              },
                              child: TextWidget(
                                text: 'Forgot password?',
                                color: themeState.getDarkTheme ? Colors.blue[300]! : Colors.blue,
                                textSize: 14,
                                isTitle: false,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeState.getDarkTheme ? Colors.blue[700] : Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _submitFormOnLogin,
                              child: TextWidget(
                                text: 'Login',
                                textSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const FetchScreen(),
                                  ),
                                );
                              },
                              child: TextWidget(
                                text: 'Continue as guest',
                                textSize: 16,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Sign Up Link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Don\'t have an account? ',
                          style: TextStyle(
                            color: color.withOpacity(0.8),
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: TextStyle(
                                color: themeState.getDarkTheme ? Colors.blue[300]! : Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  GlobalMethods.navigateTo(
                                      ctx: context,
                                      routeName: RegisterScreen.routeName);
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
