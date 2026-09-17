import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/partner_provider.dart';
import '../../widgets/text_widget.dart';
import '../../services/utils.dart';
import '../../services/global_methods.dart';

class AddPartnerScreen extends StatefulWidget {
  static const routeName = '/AddPartner';
  
  const AddPartnerScreen({Key? key}) : super(key: key);

  @override
  State<AddPartnerScreen> createState() => _AddPartnerScreenState();
}

class _AddPartnerScreenState extends State<AddPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partnerNameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _partnerNameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _addPartner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
      
      await partnerProvider.addPartner(
        partnerName: _partnerNameController.text.trim(),
        address1: _address1Controller.text.trim(),
        address2: _address2Controller.text.trim(),
        city: _cityController.text.trim(),
        postcode: _postcodeController.text.trim(),
        context: context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partner added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (error) {
      if (mounted) {
        GlobalMethods.errorDialog(
          subtitle: 'Error adding partner: $error',
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

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Add New Partner',
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
                    return 'Partner name is required';
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
                    return 'Address Line 1 is required';
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
                    return 'City is required';
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
                    return 'Postcode is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Add Partner Button
              ElevatedButton(
                onPressed: _isLoading ? null : _addPartner,
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
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : TextWidget(
                        text: 'Add Partner',
                        color: Colors.white,
                        textSize: 18,
                        fontWeight: FontWeight.bold,
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
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextWidget(
                        text: 'Fields marked with * are required. The partner will be created and enabled automatically.',
                        color: Colors.blue,
                        textSize: 12,
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
