import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/user_provider.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/delete_account_widget.dart';
import '../../providers/partner_provider.dart';
import '../../services/utils.dart';
import '../../services/global_methods.dart';
import '../auth/login.dart';
import '../partner_selection_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  MobileScannerController? _scannerController;

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  // Join Partner via QR Code
  Future<void> _joinPartnerViaQR() async {
    await _showQRScannerDialog();
  }

  // Show QR Scanner Dialog
  Future<void> _showQRScannerDialog() async {
    _scannerController = MobileScannerController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Scan Partner Code'),
          ],
        ),
        content: SizedBox(
          width: 300,
          height: 300,
          child: MobileScanner(
            controller: _scannerController,
            onDetect: _onQRDetected,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _scannerController?.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Handle QR Code Detection
  void _onQRDetected(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _scannerController?.stop();
      Navigator.of(context).pop(); // Close scanner dialog
      await _processScannerData(barcodes.first.rawValue!);
    }
  }

  // Process scanned QR data
  Future<void> _processScannerData(String qrData) async {
    await _showPinDialog(qrData);
  }

  // Show PIN input dialog
  Future<void> _showPinDialog(String qrData) async {
    final TextEditingController pinController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Enter PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 4-digit PIN to join this partner:'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length == 4) {
                Navigator.of(context).pop();
                await _verifyAndJoinPartner(qrData, pin);
              } else {
                GlobalMethods.errorDialog(
                  subtitle: 'Please enter a valid 4-digit PIN.',
                  context: context,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  // Verify PIN and join partner
  Future<void> _verifyAndJoinPartner(String qrHash, String pin) async {
    try {
      final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Fetch all partners
      await partnerProvider.fetchPartners(context);
      final allPartners = partnerProvider.getPartners;
      String? matchedPartnerId;
      String? originalUserId;

      // Try to find a matching partner by testing all combinations
      for (final partner in allPartners) {
        // Get all userIds from this partner to test
        final List<String> userIdsToTest = [
          ...partner.users,
          partner.userId, // Original partner creator
        ];

        for (final userId in userIdsToTest) {
          // Create the expected hash for this partner and user combination
          final dataToHash = '${partner.partnerId}|$userId';
          final saltedData = dataToHash + pin;
          final bytes = utf8.encode(saltedData);
          final expectedHash = sha256.convert(bytes).toString();

          if (expectedHash == qrHash) {
            matchedPartnerId = partner.partnerId;
            originalUserId = userId;
            break;
          }
        }
        
        if (matchedPartnerId != null) break;
      }

      if (matchedPartnerId == null) {
        throw Exception('Invalid QR code or PIN. Please check and try again.');
      }

      // Verify the original user is still valid (still exists in partner)
      final matchedPartner = allPartners.firstWhere((p) => p.partnerId == matchedPartnerId);
      final allPartnerUsers = [...matchedPartner.users, matchedPartner.userId];
      
      if (!allPartnerUsers.contains(originalUserId)) {
        throw Exception('The original user is no longer associated with this partner.');
      }

      // Check if current user is already in the partner
      if (allPartnerUsers.contains(currentUser.uid)) {
        throw Exception('You are already a member of this partner.');
      }

      // Add current user to the partner
      await partnerProvider.addUserToPartner(matchedPartnerId, currentUser.uid);

      // Show success message and navigate to partner selection
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined partner: ${matchedPartner.partnerName}'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to partner selection screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PartnerSelectionScreen(),
          ),
        );
      }

    } catch (error) {
      if (mounted) {
        GlobalMethods.errorDialog(
          subtitle: error.toString(),
          context: context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final Color color = Utils(context).color;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: 'Profile',
              color: color,
              textSize: 22,
              isTitle: true,
            ),
            if (userProvider.currentUser?.email != null)
              TextWidget(
                text: userProvider.currentUser!.email,
                color: Colors.grey,
                textSize: 12,
              ),
          ],
        ),
      ),
      body: userProvider.currentUser == null
          ? Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Login'),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      text: userProvider.isAdmin ? 'Admin ' : 'User ',
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: userProvider.currentUser?.name ?? '',
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextWidget(
                    text: userProvider.currentUser?.email ?? '',
                    color: color,
                    textSize: 14,
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 2),
                  const SizedBox(height: 20),
                  _buildListTile(
                    title: 'Join Partner',
                    subtitle: 'Scan QR code to join a new partner',
                    icon: Icons.qr_code_scanner,
                    onTap: () => _joinPartnerViaQR(),
                    color: color,
                  ),
                  if (userProvider.isPartner) _buildListTile(
                    title: 'Partner ID',
                    subtitle: userProvider.currentUser?.preferredPartnerId,
                    icon: Icons.business,
                    onTap: () => _showPartnerDialog(context),
                    color: color,
                  ),
                  // Only show biometric authentication if user has partner access
                  if (userProvider.isPartner)
                    SwitchListTile(
                      title: TextWidget(
                        text: 'Biometric Authentication for Payouts',
                        color: color,
                        textSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      subtitle: TextWidget(
                        text: 'Require biometric authentication when requesting payouts',
                        color: color.withOpacity(0.7),
                        textSize: 12,
                      ),
                      secondary: Icon(
                        Icons.fingerprint,
                        color: color,
                      ),
                      value: userProvider.currentUser?.biometricsEnabled ?? false,
                      onChanged: (bool value) async {
                        try {
                          await userProvider.updateUserData(
                            biometricsEnabled: value,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value 
                                    ? 'Biometric authentication enabled for payouts'
                                    : 'Biometric authentication disabled for payouts'
                                ),
                              ),
                            );
                          }
                        } catch (error) {
                          if (context.mounted) {
                            GlobalMethods.errorDialog(
                              subtitle: error.toString(),
                              context: context,
                            );
                          }
                        }
                      },
                    ),
                  _buildListTile(
                    title: 'Logout',
                    icon: Icons.logout,
                    onTap: () => _handleLogout(context),
                    color: color,
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 2),
                  const SizedBox(height: 10),
                  // Add the delete account widget
                  const DeleteAccountWidget(),
                ],
              ),
            ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required Function onTap,
    required Color color,
  }) {
    return ListTile(
      title: TextWidget(
        text: title,
        color: color,
        textSize: 16,
        fontWeight: FontWeight.w600,
      ),
      subtitle: subtitle != null
          ? TextWidget(
              text: subtitle,
              color: color.withOpacity(0.7),
              textSize: 14,
            )
          : null,
      leading: Icon(icon, color: color),
      trailing: Icon(Icons.arrow_forward_ios, color: color),
      onTap: () => onTap(),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await GlobalMethods.warningDialog(
      title: 'Sign out',
      subtitle: 'Do you want to sign out?',
      fct: () async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.signOut();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
      context: context,
    );
  }

  Future<void> _showPartnerDialog(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
    final TextEditingController partnerController = TextEditingController(
      text: userProvider.currentUser?.preferredPartnerId ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        final Color color = Utils(context).color;
        
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: TextWidget(
            text: 'Update Partner',
            color: color,
            textSize: 18,
            isTitle: true,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: partnerController.text.isEmpty ? null : partnerController.text,
                decoration: InputDecoration(
                  labelText: 'Select Partner',
                  labelStyle: TextStyle(color: color),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color.withOpacity(0.5)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color),
                  ),
                ),
                dropdownColor: Theme.of(context).cardColor,
                items: partnerProvider.getPartners.map((partner) {
                  return DropdownMenuItem(
                    value: partner.partnerId,
                    child: Text(
                      partner.partnerName,
                      style: TextStyle(color: color),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  partnerController.text = value ?? '';
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await userProvider.updateUserData(
                    preferredPartnerId: partnerController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Partner updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    GlobalMethods.errorDialog(
                      subtitle: error.toString(),
                      context: context,
                    );
                  }
                } finally {
                  // Dispose the controller after the async operation
                  partnerController.dispose();
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
              ),
              child: const TextWidget(
                text: 'Update',
                color: Colors.white,
                textSize: 16,
              ),
            ),
          ],
        );
      },
    );
    partnerController.dispose();
  }
} 