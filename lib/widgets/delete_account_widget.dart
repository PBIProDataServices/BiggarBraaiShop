import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/dark_theme_provider.dart';
import '../widgets/text_widget.dart';
import '../services/global_methods.dart';
import '../screens/auth/login.dart';

class DeleteAccountWidget extends StatefulWidget {
  const DeleteAccountWidget({Key? key}) : super(key: key);

  @override
  State<DeleteAccountWidget> createState() => _DeleteAccountWidgetState();
}

class _DeleteAccountWidgetState extends State<DeleteAccountWidget> {
  bool _isDeleting = false;
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final themeState = Provider.of<DarkThemeProvider>(context, listen: false);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;
    final Color cardColor = themeState.getDarkTheme ? const Color(0xFF1E1E1E) : Colors.white;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextWidget(
                      text: 'Delete Account',
                      color: Colors.red,
                      textSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'This action cannot be undone. This will permanently delete:',
                    color: color,
                    textSize: 16,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: '• Your account and profile information',
                          color: color,
                          textSize: 14,
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: '• All your order history',
                          color: color,
                          textSize: 14,
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: '• Your preferences and settings',
                          color: color,
                          textSize: 14,
                        ),
                        const SizedBox(height: 4),
                        TextWidget(
                          text: '• Your login access',
                          color: color,
                          textSize: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextWidget(
                    text: 'To confirm, type "DELETE" below:',
                    color: color,
                    textSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmationController,
                    style: TextStyle(color: color),
                    decoration: InputDecoration(
                      hintText: 'Type DELETE to confirm',
                      hintStyle: TextStyle(color: color.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {}); // Rebuild to enable/disable button
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _confirmationController.clear();
                    Navigator.of(context).pop();
                  },
                  child: TextWidget(
                    text: 'Cancel',
                    color: color,
                    textSize: 16,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _confirmationController.text.trim() == 'DELETE'
                      ? () async {
                          Navigator.of(context).pop();
                          await _deleteAccount();
                        }
                      : null,
                  child: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : TextWidget(
                          text: 'Delete Forever',
                          color: Colors.white,
                          textSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isDeleting = true;
    });

    try {
      await userProvider.deleteUserAccount();
      
      // Show success message and navigate to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        GlobalMethods.errorDialog(
          subtitle: error.toString(),
          context: context,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(
          Icons.warning_rounded,
          color: Colors.red,
          size: 24,
        ),
        title: TextWidget(
          text: 'Delete My Account',
          color: Colors.red,
          textSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitle: TextWidget(
          text: 'Permanently delete all your data',
          color: color.withOpacity(0.7),
          textSize: 14,
        ),
        trailing: Icon(
          IconlyLight.arrowRight2,
          color: Colors.red,
        ),
        onTap: _showDeleteConfirmationDialog,
      ),
    );
  }
}
