import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../providers/partner_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/text_widget.dart';
import '../../services/utils.dart';
import '../../services/global_methods.dart';
import '../../models/partners_model.dart';

class EditPartnerScreen extends StatefulWidget {
  static const routeName = '/EditPartner';
  final String partnerId;
  
  const EditPartnerScreen({
    Key? key,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<EditPartnerScreen> createState() => _EditPartnerScreenState();
}

class _EditPartnerScreenState extends State<EditPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partnerNameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _pinController = TextEditingController();
  final _usersController = TextEditingController();
  
  bool _isLoading = false;
  PartnerModel? _currentPartner;
  bool _canEditUsers = false;
  Map<String, String> _userIdToNameMap = {}; // Map to store user ID to name mapping

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
  }

  @override
  void dispose() {
    _partnerNameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _pinController.dispose();
    _usersController.dispose();
    super.dispose();
  }

  void _loadPartnerData() async {
    final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    _currentPartner = partnerProvider.getPartners
        .where((partner) => partner.partnerId == widget.partnerId)
        .firstOrNull;
    
    if (_currentPartner != null) {
      _partnerNameController.text = _currentPartner!.partnerName;
      _address1Controller.text = _currentPartner!.address1;
      _address2Controller.text = _currentPartner!.address2;
      _cityController.text = _currentPartner!.city;
      _postcodeController.text = _currentPartner!.postcode;
      _pinController.text = _currentPartner!.pin;
      
      // Fetch user names for the authorized users
      if (_currentPartner!.users.isNotEmpty) {
        try {
          final names = await userProvider.getUserNamesByIds(_currentPartner!.users);
          setState(() {
            _userIdToNameMap = names;
            final userNames = _currentPartner!.users
                .map((userId) => _userIdToNameMap[userId] ?? 'Unknown User')
                .toList();
            _usersController.text = userNames.join(', ');
          });
        } catch (error) {
          debugPrint('Error fetching user names: $error');
          // Fallback to showing user IDs if there's an error
          _usersController.text = _currentPartner!.users.join(', ');
        }
      } else {
        _usersController.text = '';
      }
    }
    
    // Check if user can edit the users field (admin only)
    _canEditUsers = userProvider.isAdmin;
  }

  // Helper method to check if current user can edit this partner
  bool _canUserEditPartner() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentPartner == null) return false;
    
    return _currentPartner!.isUserAdmin(user.uid);
  }

  // Generate QR code data with PIN-based hashing
  String _generateQRCodeData() {
    final user = FirebaseAuth.instance.currentUser;
    final partnerId = _currentPartner?.partnerId ?? '';
    final userId = user?.uid ?? '';
    final pin = _pinController.text.trim();
    
    // Create the string to hash: PartnerID|UserID
    final dataToHash = '$partnerId|$userId';
    
    // Use PIN as salt and create the hash
    final saltedData = dataToHash + pin;
    final bytes = utf8.encode(saltedData);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  Future<bool> _confirmRemoveUser(String userName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove user?'),
            content: Text('Are you sure you want to remove "$userName" from authorized users?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _removeUser(String userId) async {
    if (!_canEditUsers || !_canUserEditPartner()) {
      GlobalMethods.errorDialog(
        subtitle: 'You do not have permission to modify authorized users.',
        context: context,
      );
      return;
    }

    final userName = _userIdToNameMap[userId] ?? 'User';
    final confirmed = await _confirmRemoveUser(userName);
    if (!confirmed) return;

    final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
    final updatedUsers = List<String>.from(_currentPartner?.users ?? []);
    updatedUsers.remove(userId);

    setState(() => _isLoading = true);
    try {
      await partnerProvider.updatePartner(
        partnerId: widget.partnerId,
        partnerName: _partnerNameController.text.trim(),
        address1: _address1Controller.text.trim(),
        address2: _address2Controller.text.trim(),
        city: _cityController.text.trim(),
        postcode: _postcodeController.text.trim(),
        pin: _pinController.text.trim(),
        users: updatedUsers,
      );

      // Update local state to reflect removal immediately
      if (_currentPartner != null) {
        final p = _currentPartner!;
        setState(() {
          _currentPartner = PartnerModel(
            partnerId: p.partnerId,
            userId: p.userId,
            partnerName: _partnerNameController.text.trim(),
            address1: _address1Controller.text.trim(),
            address2: _address2Controller.text.trim(),
            city: _cityController.text.trim(),
            postcode: _postcodeController.text.trim(),
            addresscode: p.addresscode,
            enabled: p.enabled,
            stocks: p.stocks,
            defaultSalesChannel: p.defaultSalesChannel,
            users: updatedUsers,
            pin: _pinController.text.trim(),
          );
          _userIdToNameMap.remove(userId);
          final names = updatedUsers.map((id) => _userIdToNameMap[id] ?? 'Unknown User').toList();
          _usersController.text = names.join(', ');
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $userName from authorized users.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        GlobalMethods.errorDialog(
          subtitle: 'Failed to remove user: $error',
          context: context,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Show QR code dialog
  void _showQRCodeDialog() {
    if (_pinController.text.trim().isEmpty || _pinController.text.trim().length != 4) {
      GlobalMethods.errorDialog(
        subtitle: 'Please enter a valid 4-digit PIN before proceeding.',
        context: context,
      );
      return;
    }

    final qrData = _generateQRCodeData();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Add User'),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // QR Code Display Area
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Scan this code to add a new user to this partner.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Copy QR data to clipboard
              Clipboard.setData(ClipboardData(text: qrData));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.content_copy, size: 16),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePartner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_canUserEditPartner()) {
      GlobalMethods.errorDialog(
        subtitle: 'You do not have permission to edit this partner.',
        context: context,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
      
      // Keep existing users list since the users field is now read-only
      List<String> usersList = _currentPartner?.users ?? [];
      
      await partnerProvider.updatePartner(
        partnerId: widget.partnerId,
        partnerName: _partnerNameController.text.trim(),
        address1: _address1Controller.text.trim(),
        address2: _address2Controller.text.trim(),
        city: _cityController.text.trim(),
        postcode: _postcodeController.text.trim(),
        pin: _pinController.text.trim(),
        users: usersList,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partner updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (error) {
      if (mounted) {
        GlobalMethods.errorDialog(
          subtitle: 'Error updating partner: $error',
          context: context,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;

    if (_currentPartner == null) {
      return Scaffold(
        appBar: AppBar(
          title: TextWidget(
            text: 'Edit Partner',
            color: color,
            textSize: 22,
            isTitle: true,
          ),
        ),
        body: const Center(
          child: Text('Partner not found'),
        ),
      );
    }

    if (!_canUserEditPartner()) {
      return Scaffold(
        appBar: AppBar(
          title: TextWidget(
            text: 'Edit Partner',
            color: color,
            textSize: 22,
            isTitle: true,
          ),
        ),
        body: const Center(
          child: Text('You do not have permission to edit this partner'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Edit Partner',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Partner Name
              TextFormField(
                controller: _partnerNameController,
                decoration: InputDecoration(
                  labelText: 'Partner Name *',
                  labelStyle: TextStyle(color: color),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business, color: color),
                ),
                style: TextStyle(color: color),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a partner name';
                  }
                  if (value.trim().length < 2) {
                    return 'Partner name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Address Line 1
              TextFormField(
                controller: _address1Controller,
                decoration: InputDecoration(
                  labelText: 'Address Line 1 *',
                  labelStyle: TextStyle(color: color),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on, color: color),
                ),
                style: TextStyle(color: color),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter address line 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Address Line 2
              TextFormField(
                controller: _address2Controller,
                decoration: InputDecoration(
                  labelText: 'Address Line 2',
                  labelStyle: TextStyle(color: color),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined, color: color),
                ),
                style: TextStyle(color: color),
              ),
              const SizedBox(height: 16),
              
              // City
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City *',
                  labelStyle: TextStyle(color: color),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city, color: color),
                ),
                style: TextStyle(color: color),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Postcode
              TextFormField(
                controller: _postcodeController,
                decoration: InputDecoration(
                  labelText: 'Postcode *',
                  labelStyle: TextStyle(color: color),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mail, color: color),
                ),
                style: TextStyle(color: color),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a postcode';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // PIN field
              TextFormField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'PIN *',
                  labelStyle: TextStyle(color: color),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock, color: color),
                  helperText: 'Must be exactly 4 digits',
                ),
                style: TextStyle(color: color),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a PIN';
                  }
                  if (value.trim().length != 4) {
                    return 'PIN must be exactly 4 digits';
                  }
                  if (!RegExp(r'^\d{4}$').hasMatch(value.trim())) {
                    return 'PIN must contain only numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Add User Section
              Card(
                color: Colors.green.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_add, color: Colors.green, size: 24),
                          const SizedBox(width: 8),
                          TextWidget(
                            text: 'Add User',
                            color: color,
                            textSize: 18,
                            isTitle: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextWidget(
                        text: 'Generate a secure code to add a new user to this partner.',
                        color: Colors.grey[600]!,
                        textSize: 14,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showQRCodeDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add User'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Authorized Users list with remove option (admins only)
              Align(
                alignment: Alignment.centerLeft,
                child: TextWidget(
                  text: 'Authorized Users',
                  color: color,
                  textSize: 16,
                  isTitle: true,
                ),
              ),
              const SizedBox(height: 8),
              if ((_currentPartner?.users ?? []).isEmpty)
                TextWidget(
                  text: 'No authorized users yet.',
                  color: Colors.grey,
                  textSize: 14,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_currentPartner?.users ?? []).map((userId) {
                    final name = _userIdToNameMap[userId] ?? 'Unknown User';
                    return Chip(
                      label: Text(name),
                      avatar: const CircleAvatar(child: Icon(Icons.person, size: 16)),
                      deleteIcon: _canEditUsers ? const Icon(Icons.close) : null,
                      onDeleted: _canEditUsers ? () => _removeUser(userId) : null,
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              if (!_canEditUsers)
                TextWidget(
                  text: 'Only admins can remove users.',
                  color: Colors.grey,
                  textSize: 12,
                ),
              const SizedBox(height: 32),
              
              // Update Partner Button
              ElevatedButton(
                onPressed: _isLoading ? null : _updatePartner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : TextWidget(
                        text: 'Update Partner',
                        color: Colors.white,
                        textSize: 18,
                        isTitle: true,
                      ),
              ),
              const SizedBox(height: 16),
              
              // Information text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextWidget(
                        text: _canEditUsers 
                            ? 'As an admin, you can edit all fields. Authorized users are displayed by name for easier identification.'
                            : 'Authorized users are displayed by name for easier identification. Only admins can manage user access.',
                        color: Colors.blue,
                        textSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
