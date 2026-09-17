import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/phone_auth_service.dart';
import '../../services/global_methods.dart';
import '../../widgets/text_widget.dart';
import '../loading_manager.dart';
import '../../providers/user_provider.dart';

class PhoneAuthScreen extends StatefulWidget {
  static const routeName = '/PhoneAuth';
  
  const PhoneAuthScreen({Key? key}) : super(key: key);

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;
  int? _resendToken;
  
  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await PhoneAuthService.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        context: context,
        onCodeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _codeSent = true;
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (String error) {
          setState(() {
            _isLoading = false;
          });
          
          GlobalMethods.errorDialog(
            subtitle: error,
            context: context,
          );
        },
        onVerificationCompleted: (UserCredential userCredential) async {
          setState(() {
            _isLoading = false;
          });
          
          // Create user profile if needed
          try {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            await userProvider.createUserProfileIfNeeded();
            await userProvider.fetchUserData();
          } catch (e) {
            debugPrint('Error creating user profile: $e');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone verification completed!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to main app or handle successful login
          Navigator.of(context).pop();
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      GlobalMethods.errorDialog(
        subtitle: e.toString(),
        context: context,
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().isEmpty) {
      GlobalMethods.errorDialog(
        subtitle: 'Please enter the OTP',
        context: context,
      );
      return;
    }

    if (_verificationId == null) {
      GlobalMethods.errorDialog(
        subtitle: 'Verification ID not found. Please resend OTP.',
        context: context,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await PhoneAuthService.signInWithOTP(
        verificationId: _verificationId!,
        otp: _otpController.text.trim(),
      );

      if (userCredential != null && mounted) {
        // Create user profile if needed
        try {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          await userProvider.createUserProfileIfNeeded();
          await userProvider.fetchUserData();
        } catch (e) {
          debugPrint('Error creating user profile: $e');
        }
        
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone verification successful!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to main app or handle successful login
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      GlobalMethods.errorDialog(
        subtitle: e.toString(),
        context: context,
      );
    }
  }

  Future<void> _resendOTP() async {
    if (_resendToken == null) {
      GlobalMethods.errorDialog(
        subtitle: 'Cannot resend OTP at this time.',
        context: context,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await PhoneAuthService.resendOTP(
        phoneNumber: _phoneController.text.trim(),
        resendToken: _resendToken!,
        context: context,
        onCodeSent: (String verificationId, int? newResendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = newResendToken;
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP resent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (String error) {
          setState(() {
            _isLoading = false;
          });
          
          GlobalMethods.errorDialog(
            subtitle: error,
            context: context,
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      GlobalMethods.errorDialog(
        subtitle: e.toString(),
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: TextWidget(
          text: _codeSent ? 'Verify OTP' : 'Phone Authentication',
          color: Theme.of(context).textTheme.bodyLarge!.color!,
          textSize: 20,
          isTitle: true,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: LoadingManager(
        isLoading: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_codeSent) ...[
                  // Phone number input
                  TextWidget(
                    text: 'Enter your phone number',
                    color: Theme.of(context).textTheme.bodyLarge!.color!,
                    textSize: 16,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '+1 234 567 8900',
                      prefixIcon: Icon(
                        Icons.phone,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      if (!value.trim().startsWith('+')) {
                        return 'Please include country code (e.g., +1)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: 'For Testing:',
                          color: Colors.blue,
                          textSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 5),
                        TextWidget(
                          text: 'Use +1 650-555-3434 with any 6-digit OTP (e.g., 123456)',
                          color: Colors.blue,
                          textSize: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Send OTP',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ] else ...[
                  // OTP input
                  TextWidget(
                    text: 'Enter the verification code',
                    color: Theme.of(context).textTheme.bodyLarge!.color!,
                    textSize: 16,
                  ),
                  const SizedBox(height: 5),
                  TextWidget(
                    text: 'Code sent to ${_phoneController.text}',
                    color: Colors.grey,
                    textSize: 14,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '123456',
                      prefixIcon: Icon(
                        Icons.security,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Verify OTP',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: _resendOTP,
                    child: const Text('Resend OTP'),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _codeSent = false;
                        _verificationId = null;
                        _resendToken = null;
                        _otpController.clear();
                      });
                    },
                    child: const Text('Change Phone Number'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
