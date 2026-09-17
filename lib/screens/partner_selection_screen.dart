import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/partner_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/text_widget.dart';
import '../services/global_methods.dart';
import 'partner/partner_dashboard_screen.dart';
import 'partner/add_partner_screen.dart';
import 'auth/login.dart';
import 'user/user_screen.dart';

class PartnerSelectionScreen extends StatefulWidget {
  static const routeName = '/PartnerSelection';
  const PartnerSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PartnerSelectionScreen> createState() => _PartnerSelectionScreenState();
}

class _PartnerSelectionScreenState extends State<PartnerSelectionScreen> {
  String? _selectedPartnerId;
  bool _isLoading = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

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
    setState(() => _isLoading = true);
    
    try {
      final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get all partners to test against
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

      // Refresh partners list
      await partnerProvider.fetchPartners(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined partner: ${matchedPartner.partnerName}'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to the partner dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PartnerDashboardScreen(
              partnerId: matchedPartnerId!,
            ),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Fetch initial data
  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
      await partnerProvider.fetchPartners(context);
      
      // Check if there's only one partner and auto-select it
      if (partnerProvider.getPartners.length == 1) {
        final singlePartner = partnerProvider.getPartners.first;
        partnerProvider.setCurrentPartner(singlePartner);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PartnerDashboardScreen(
                partnerId: singlePartner.partnerId,
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading partners: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Logout user
  Future<void> _logout() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.signOut();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).textTheme.bodyLarge!.color!;
    final partnerProvider = Provider.of<PartnerProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    // If user is a partner, redirect to their dashboard
    if (userProvider.currentUser?.preferredPartnerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PartnerDashboardScreen(
              partnerId: userProvider.currentUser!.preferredPartnerId!,
            ),
          ),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Select Partner',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
        actions: [
          // User Profile button
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserScreen(),
                ),
              );
            },
            tooltip: 'User Profile',
          ),
          // Join Partner button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _joinPartnerViaQR,
            tooltip: 'Join Partner',
          ),
          // Add Partner button (only for admin users)
          if (userProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.add_business),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddPartnerScreen(),
                  ),
                );
                
                // If a partner was successfully added, refresh the list
                if (result == true && mounted) {
                  final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
                  await partnerProvider.fetchPartners(context);
                }
              },
              tooltip: 'Add Partner',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (partnerProvider.getPartners.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.only(bottom: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  text: 'No Partnerships Found',
                                  color: Colors.orange,
                                  textSize: 16,
                                  isTitle: true,
                                ),
                                const SizedBox(height: 4),
                                TextWidget(
                                  text: 'You are not registered with any partnerships. Please contact support to get added to a partnership, or scan a QR code to join.',
                                  color: color,
                                  textSize: 14,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _joinPartnerViaQR,
                                      icon: const Icon(Icons.qr_code_scanner),
                                      label: const Text('Join Partner'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    if (userProvider.isAdmin) ...[
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const AddPartnerScreen(),
                                            ),
                                          );
                                          
                                          // If a partner was successfully added, refresh the list
                                          if (result == true && mounted) {
                                            final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
                                            await partnerProvider.fetchPartners(context);
                                          }
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Partner'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedPartnerId,
                      decoration: InputDecoration(
                        labelText: 'Select Partner',
                        labelStyle: TextStyle(color: color),
                        border: const OutlineInputBorder(),
                      ),
                      items: partnerProvider.getPartners.map((partner) {
                        return DropdownMenuItem(
                          value: partner.partnerId,
                          child: Text(partner.partnerName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPartnerId = value);
                        if (value != null) {
                          final selectedPartner = partnerProvider.getPartners
                              .firstWhere((p) => p.partnerId == value);
                          partnerProvider.setCurrentPartner(selectedPartner);
                          
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => PartnerDashboardScreen(
                                partnerId: value,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
      floatingActionButton: userProvider.isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddPartnerScreen(),
                  ),
                );
                
                // If a partner was successfully added, refresh the list
                if (result == true && mounted) {
                  final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
                  await partnerProvider.fetchPartners(context);
                }
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_business),
              tooltip: 'Add Partner',
            )
          : FloatingActionButton(
              onPressed: _joinPartnerViaQR,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              child: const Icon(Icons.qr_code_scanner),
              tooltip: 'Join Partner',
            ),
    );
  }
} 