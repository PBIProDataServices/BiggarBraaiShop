import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/stock_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/payout_provider.dart';
import '../../providers/partner_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/text_widget.dart';
import '../../services/utils.dart';
import 'add_sale_screen.dart';
import 'sales_history_screen.dart';
import 'payout_history_screen.dart';
import 'stock_alert_screen.dart';
import 'edit_partner_screen.dart';
import '../user/user_screen.dart';
import '../../services/stripe_service.dart';
import '../../services/biometric_service.dart';

class PartnerDashboardScreen extends StatefulWidget {
  static const routeName = '/PartnerDashboard';
  final String partnerId;
  
  const PartnerDashboardScreen({
    Key? key,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      // Fetch initial data
      Provider.of<StockProvider>(context, listen: false)
          .fetchPartnerStock(widget.partnerId);
      Provider.of<SaleProvider>(context, listen: false)
          .fetchSales(widget.partnerId);
      Provider.of<PayoutProvider>(context, listen: false)
          .fetchPayouts(widget.partnerId);
    }
  }

  // Helper method to check if current user can make payouts for this partner
  bool _canUserMakePayouts() {
    final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
    
    // Get current user ID from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    final currentUserId = user.uid;
    
    // Find the current partner
    final currentPartner = partnerProvider.getPartners
        .where((partner) => partner.partnerId == widget.partnerId)
        .firstOrNull;
    
    if (currentPartner == null) return false;
    
    if (currentPartner.userId == currentUserId) {
      // User is the owner of the partner
      return true;
    }
    else {
      return false;
    }
  }

  // Helper method to check if current user can edit this partner
  bool _canUserEditPartner() {
    final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    final currentPartner = partnerProvider.getPartners
        .where((partner) => partner.partnerId == widget.partnerId)
        .firstOrNull;
    
    if (currentPartner == null) return false;
    
    return currentPartner.canUserAccess(user.uid);
  }

  Widget _buildStockTab() {
    final stockProvider = Provider.of<StockProvider>(context);
    final stock = stockProvider.getStock;
    final Color color = Utils(context).color;

    return Scaffold(
      body: ListView.builder(
        itemCount: stock.length,
        itemBuilder: (context, index) {
          final stockItem = stock.values.elementAt(index);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: TextWidget(
                text: stockItem.productType,
                color: color,
                textSize: 18,
              ),
              subtitle: TextWidget(
                text: 'Quantity: ${stockItem.quantity}',
                color: color,
                textSize: 16,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () {
                  // Navigate to add sale screen with pre-selected product
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddSaleScreen(
                        partnerId: widget.partnerId,
                        stockType: stockItem.productType,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesTab() {
    final saleProvider = Provider.of<SaleProvider>(context);
    final sales = saleProvider.getSales;
    final Color color = Utils(context).color;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddSaleScreen(
                partnerId: widget.partnerId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: sales.length,
        itemBuilder: (context, index) {
          final sale = sales.values.elementAt(index);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: TextWidget(
                text: sale.stockType,
                color: color,
                textSize: 18,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Units: ${sale.units}',
                    color: color,
                    textSize: 16,
                  ),
                  TextWidget(
                    text: 'Date: ${sale.saleDate.toDate().toString().split(' ')[0]} • ${sale.salesChannel} - ${sale.username}',
                    color: color,
                    textSize: 14,
                  ),
                ],
              ),
              trailing: TextWidget(
                text: '£${(sale.price * sale.units).toStringAsFixed(2)}',
                color: color,
                textSize: 18,
                isTitle: true,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPayoutsTab() {
    final payoutProvider = Provider.of<PayoutProvider>(context);
    final payouts = payoutProvider.getPayouts;
    final Color color = Utils(context).color;

    return Scaffold(
      body: ListView.builder(
        itemCount: payouts.length,
        itemBuilder: (context, index) {
          final payout = payouts.values.elementAt(index);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: TextWidget(
                text: 'Payout #${payout.id}',
                color: color,
                textSize: 18,
              ),
              subtitle: TextWidget(
                text: 'Date: ${payout.datetime.toDate().toString().split(' ')[0]}',
                color: color,
                textSize: 16,
              ),
              trailing: TextWidget(
                text: '£${payout.amount.toStringAsFixed(2)}',
                color: color,
                textSize: 18,
                isTitle: true,
              ),
            ),
          );
        },
      ),
      // Only show payout button if user has permission
      floatingActionButton: _canUserMakePayouts() 
          ? FloatingActionButton(
              onPressed: () => _showDirectPayoutDialog(context),
              backgroundColor: Colors.green,
              child: const Icon(Icons.payment, size: 28),
              tooltip: 'Create Payout',
            )
          : null,
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildStockTab();
      case 1:
        return _buildSalesTab();
      case 2:
        return _buildPayoutsTab();
      default:
        return _buildStockTab();
    }
  }

  Future<bool> _authenticateForPayout() async {
    try {
      // Check if biometric authentication is available
      final isBiometricAvailable = await BiometricService.isBiometricAvailable();
      
      if (!isBiometricAvailable) {
        throw Exception('Biometric authentication is not available on this device');
      }
      
      // Request biometric authentication
      final isAuthenticated = await BiometricService.authenticate(
        localizedReason: 'Please authenticate to confirm the payout',
      );
      
      if (!isAuthenticated) {
        throw Exception('Biometric authentication was cancelled or failed');
      }
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  void _showDirectPayoutDialog(BuildContext context) async {
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    final payoutProvider = Provider.of<PayoutProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final storeSalesRevenue = saleProvider.getStoreSalesRevenue(widget.partnerId);
    final totalPayouts = payoutProvider.getTotalPayouts();
    final difference = storeSalesRevenue - totalPayouts;
    
    // Get user email
    final userEmail = userProvider.currentUserEmail ?? await userProvider.getCurrentUserEmail();
    
    final TextEditingController amountController = TextEditingController(
      text: difference > 0 ? difference.toStringAsFixed(2) : '0.00'
    );
    
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const TextWidget(
                text: 'Create Payment',
                color: Colors.black,
                textSize: 20,
                isTitle: true,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: 'Store Sales: £${storeSalesRevenue.toStringAsFixed(2)}',
                    color: Colors.green,
                    textSize: 16,
                  ),
                  const SizedBox(height: 4),
                  TextWidget(
                    text: 'Total Payouts: £${totalPayouts.toStringAsFixed(2)}',
                    color: Colors.blue,
                    textSize: 16,
                  ),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'Available for Payment: £${difference.toStringAsFixed(2)}',
                    color: difference > 0 ? Colors.green : Colors.red,
                    textSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'Email: ${userEmail ?? 'Not available'}',
                    color: Colors.grey,
                    textSize: 12,
                  ),
                  const SizedBox(height: 8),
                  // Show biometric authentication status
                  Builder(
                    builder: (context) {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      final currentUser = userProvider.currentUser;
                      final biometricsEnabled = currentUser?.biometricsEnabled ?? false;
                      
                      return Row(
                        children: [
                          Icon(
                            biometricsEnabled ? Icons.fingerprint : Icons.fingerprint_outlined,
                            color: biometricsEnabled ? Colors.green : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          TextWidget(
                            text: biometricsEnabled 
                              ? 'Biometric authentication required'
                              : 'Biometric authentication disabled',
                            color: biometricsEnabled ? Colors.green : Colors.grey,
                            textSize: 12,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Payout Amount (£)',
                      prefixText: '£',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isProcessing || difference <= 0 ? null : () async {
                    final amountText = amountController.text.trim();
                    final amount = double.tryParse(amountText);
                    
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount')),
                      );
                      return;
                    }
                    
                    if (amount > difference) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Amount cannot exceed available amount (£${difference.toStringAsFixed(2)})')),
                      );
                      return;
                    }

                    setState(() => isProcessing = true);
                    
                    try {
                      // Check if biometric authentication is required
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      final currentUser = userProvider.currentUser;
                      
                      if (currentUser?.biometricsEnabled == true) {
                        try {
                          await _authenticateForPayout();
                        } catch (e) {
                          throw Exception('Biometric authentication required: ${e.toString()}');
                        }
                      }
                      
                      // Use the partnerId from the widget instead of currentPartner
                      final partnerId = widget.partnerId;
                      
                      if (partnerId.isEmpty) {
                        throw Exception('No partner found');
                      }

                      final result = await StripeService.createPayout(
                        partnerId: partnerId,
                        amount: (amount * 100).round(),
                        currency: 'gbp',
                        email: userEmail ?? '',
                      );
                      //final result = await StripeService.initPayment('gareth@pbiprodataservices.com', amount, 'gbp');

                      if (result['success'] == true) {
                        if (context.mounted) {
                          // Add the successful payout to the database
                          await payoutProvider.addPayout(
                            partnerId: widget.partnerId,
                            amount: amount,
                            note: 'Stripe payment - ${userEmail ?? 'Unknown email'}',
                          );
                          
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Payment created successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        throw Exception(result['error'] ?? 'Unknown error');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        String errorMessage = 'Error creating payment: $e';
                        
                        // Provide more specific error messages for biometric authentication
                        if (e.toString().contains('Biometric authentication required')) {
                          errorMessage = e.toString().replaceAll('Exception: Biometric authentication required: ', '');
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (context.mounted) {
                        setState(() => isProcessing = false);
                      }
                    }
                  },
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getCurrentTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Stock';
      case 1:
        return 'Sales';
      case 2:
        return 'Payouts';
      default:
        return 'Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    final userProvider = Provider.of<UserProvider>(context);
    final userEmail = userProvider.currentUserEmail;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: _getCurrentTitle(),
              color: color,
              textSize: 22,
              isTitle: true,
            ),
            if (userEmail != null)
              TextWidget(
                text: userEmail,
                color: Colors.grey,
                textSize: 12,
              ),
          ],
        ),
        actions: [
          // Settings button (only for users who can edit this partner)
          if (_canUserEditPartner())
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPartnerScreen(
                      partnerId: widget.partnerId,
                    ),
                  ),
                );
                
                // If partner was successfully updated, refresh the data
                if (result == true && mounted) {
                  final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
                  await partnerProvider.fetchPartners(context);
                }
              },
              tooltip: 'Partner Settings',
            ),
          // User Profile button (available on all tabs)
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserScreen(),
                ),
              );
            },
            tooltip: 'User Profile',
          ),
          if (_selectedIndex == 1) // Sales tab
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalesHistoryScreen(
                      partnerId: widget.partnerId,
                    ),
                  ),
                );
              },
            ),
          if (_selectedIndex == 2) // Payouts tab
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PayoutHistoryScreen(
                      partnerId: widget.partnerId,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _buildCurrentPage(),
      floatingActionButton: _selectedIndex == 2 
          ? null // Hide alerting button on payouts tab
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockAlertScreen(
                      partnerId: widget.partnerId,
                    ),
                  ),
                );
              },
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              child: const Icon(Icons.warning, size: 28),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: 'Payouts',
          ),
        ],
      ),
    );
  }
} 