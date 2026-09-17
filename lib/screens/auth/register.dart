import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:biggar_braai_shop/screens/auth/login.dart';
import 'package:biggar_braai_shop/screens/loading_manager.dart';

import 'package:biggar_braai_shop/consts/contss.dart';
import 'package:biggar_braai_shop/consts/firebase_consts.dart';
import 'package:biggar_braai_shop/services/global_methods.dart';
import 'package:biggar_braai_shop/widgets/text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:biggar_braai_shop/providers/dark_theme_provider.dart';
import 'package:biggar_braai_shop/screens/auth/verify_email.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/RegisterScreen';
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _passTextController = TextEditingController();
  final _passFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  var _obscureText = true;
  @override
  void dispose() {
    _nameTextController.dispose();
    _emailTextController.dispose();
    _passTextController.dispose();
    _passFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  void _submitFormOnRegister() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      try {
        await authInstance.createUserWithEmailAndPassword(
          email: _emailTextController.text.toLowerCase().trim(),
          password: _passTextController.text.trim(),
        );
        final User? user = authInstance.currentUser;
        final _uid = user!.uid;
        await FirebaseFirestore.instance.collection('users').doc(_uid).set({
          'id': _uid,
          'name': _nameTextController.text,
          'email': _emailTextController.text.toLowerCase(),
          'userRoles': ['user'],
          'createdAt': Timestamp.now(),
          'biometricsEnabled': false,
        });
        
        // Send email verification
        await user.sendEmailVerification();

        // Optional delay to allow email propagation
        await Future.delayed(const Duration(seconds: 3));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => VerifyEmailScreen(email: _emailTextController.text.toLowerCase()),
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
            Constss.authImagesPaths[1],
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
                            text: 'Welcome',
                            color: color,
                            textSize: 28,
                            isTitle: true,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 8),
                          TextWidget(
                            text: "Sign up to continue",
                            color: color.withOpacity(0.7),
                            textSize: 16,
                            isTitle: false,
                          ),
                          const SizedBox(height: 32),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Name Field
                                TextFormField(
                                  textInputAction: TextInputAction.next,
                                  onEditingComplete: () => FocusScope.of(context)
                                      .requestFocus(_emailFocusNode),
                                  controller: _nameTextController,
                                  keyboardType: TextInputType.name,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                  style: TextStyle(color: color),
                                  decoration: InputDecoration(
                                    hintText: 'Full name',
                                    hintStyle: TextStyle(color: color.withOpacity(0.6)),
                                    prefixIcon: Icon(
                                      IconlyLight.profile,
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
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor,
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
                                // Email Field
                                TextFormField(
                                  textInputAction: TextInputAction.next,
                                  onEditingComplete: () => FocusScope.of(context)
                                      .requestFocus(_passFocusNode),
                                  controller: _emailTextController,
                                  focusNode: _emailFocusNode,
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
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor,
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
                                    _submitFormOnRegister();
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
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor,
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
                                const SizedBox(height: 32),
                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      _submitFormOnRegister();
                                    },
                                    child: Text(
                                      _isLoading ? 'Registering...' : 'Register',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Sign in link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: color.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  GlobalMethods.navigateTo(
                                    ctx: context,
                                    routeName: LoginScreen.routeName,
                                  );
                                },
                                child: Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
