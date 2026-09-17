import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/sale_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/stock_type_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/text_widget.dart';
import '../../services/utils.dart';
import '../../models/stock_model.dart';
import '../../models/stock_type_model.dart';

class AddSaleScreen extends StatefulWidget {
  final String partnerId;
  final String? stockType;

  const AddSaleScreen({
    Key? key,
    required this.partnerId,
    this.stockType,
  }) : super(key: key);

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStockType;
  final _weightController = TextEditingController();
  final _unitsController = TextEditingController();
  final _priceController = TextEditingController();
  final _customerNameController = TextEditingController();
  String _selectedSalesChannel = 'Store';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.stockType != null) {
      _selectedStockType = widget.stockType;
    }
    _unitsController.text = '1'; // Default to 1 unit
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure stock types are loaded
    final stockTypeProvider = Provider.of<StockTypeProvider>(context, listen: false);
    if (stockTypeProvider.getStockTypes.isEmpty) {
      stockTypeProvider.fetchStockTypes();
    }
    
    // Set price for pre-selected stock type after dependencies are available
    if (_selectedStockType != null) {
      _setPriceFromStockType();
    }
  }

  void _setPriceFromStockType() {
    if (_selectedStockType != null) {
      final stockTypeProvider = Provider.of<StockTypeProvider>(context, listen: false);
      final stockTypes = stockTypeProvider.getStockTypes;
      
      final stockType = stockTypes.values.firstWhere(
        (type) => type.name == _selectedStockType,
        orElse: () => StockTypeModel(
          id: '',
          name: _selectedStockType!,
          description: '',
          weightRequired: false,
          price: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      setState(() {
        _priceController.text = stockType.price.toStringAsFixed(2);
      });
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _unitsController.dispose();
    _priceController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  void _incrementUnits() {
    final currentUnits = int.tryParse(_unitsController.text) ?? 1;
    setState(() {
      _unitsController.text = (currentUnits + 1).toString();
    });
  }

  void _decrementUnits() {
    final currentUnits = int.tryParse(_unitsController.text) ?? 1;
    if (currentUnits > 1) {
      setState(() {
        _unitsController.text = (currentUnits - 1).toString();
      });
    }
  }

  // Check if units value is valid (1 or above)
  bool get _isUnitsValid {
    final units = int.tryParse(_unitsController.text);
    return units != null && units >= 1;
  }

  // Calculate total sales
  double get _totalSales {
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final units = int.tryParse(_unitsController.text) ?? 1;
    return price * units;
  }

  // Get the selected stock type model
  StockTypeModel? get _selectedStockTypeModel {
    if (_selectedStockType == null) return null;
    final stockTypeProvider = Provider.of<StockTypeProvider>(context, listen: false);
    return stockTypeProvider.getStockTypes.values.firstWhere(
      (type) => type.name == _selectedStockType,
      orElse: () => StockTypeModel(
        id: '',
        name: _selectedStockType!,
        description: '',
        weightRequired: false,
        price: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final saleProvider = Provider.of<SaleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final stockProvider = Provider.of<StockProvider>(context, listen: false);

      // Determine weight value based on weightRequired
      double weight = 0.0;
      if (_selectedStockTypeModel?.weightRequired == true) {
        weight = double.parse(_weightController.text);
      }

      // Create the sale
      await saleProvider.addSale(
        username: _customerNameController.text.trim().isNotEmpty 
            ? _customerNameController.text.trim() 
            : 'Unknown Customer',
        stockType: _selectedStockType!,
        weight: weight,
        units: int.parse(_unitsController.text),
        price: double.parse(_priceController.text),
        partnerId: widget.partnerId,
        salesChannel: _selectedSalesChannel,
      );

      // Update stock
      await stockProvider.allocateStock(
        context: context,
        batchId: DateTime.now().millisecondsSinceEpoch.toString(),
        productType: _selectedStockType!,
        quantity: -int.parse(_unitsController.text), // Subtract from stock
        partnerId: widget.partnerId,
        allocatedDate: Timestamp.now(),
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale recorded successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording sale: $error')),
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
    final stockProvider = Provider.of<StockProvider>(context);
    final stockTypeProvider = Provider.of<StockTypeProvider>(context);
    final stock = stockProvider.getStock;
    final stockTypes = stockTypeProvider.getStockTypes;
    final Color color = Utils(context).color;

    return Scaffold(
      appBar: AppBar(
        title: TextWidget(
          text: 'Add Sale',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedStockType,
                      decoration: InputDecoration(
                        labelText: 'Product Type',
                        labelStyle: TextStyle(color: color),
                        border: const OutlineInputBorder(),
                      ),
                      items: stockTypes.isNotEmpty 
                          ? stockTypes.values.map((item) {
                              return DropdownMenuItem(
                                value: item.name,
                                child: Text('${item.name} - £${item.price.toStringAsFixed(2)}'),
                              );
                            }).toList()
                          : [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Loading stock types...'),
                              ),
                            ],
                      onChanged: stockTypes.isNotEmpty ? (value) {
                        setState(() {
                          _selectedStockType = value;
                          // Clear weight field when stock type changes
                          _weightController.clear();
                        });
                        // Set default price from stock type
                        if (value != null) {
                          _setPriceFromStockType();
                        }
                      } : null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a product type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Conditionally show weight field
                    if (_selectedStockTypeModel?.weightRequired == true) ...[
                      TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          labelStyle: TextStyle(color: color),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter weight';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Weight must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Units with plus/minus buttons
                    Row(
                      children: [
                        // Units text field
                        Expanded(
                          child: TextFormField(
                            controller: _unitsController,
                            decoration: InputDecoration(
                              labelText: 'Units',
                              labelStyle: TextStyle(color: color),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _isUnitsValid ? Colors.grey : Colors.red,
                                  width: _isUnitsValid ? 1 : 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _isUnitsValid ? Colors.blue : Colors.red,
                                  width: _isUnitsValid ? 2 : 3,
                                ),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red, width: 2),
                              ),
                              focusedErrorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red, width: 3),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                // Trigger rebuild to update button states and border colors
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter units';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              final units = int.parse(value);
                              if (units < 1) {
                                return 'Units must be 1 or greater';
                              }
                              if (_selectedStockType != null) {
                                // Check stock availability using stock provider
                                final stockItem = stock.values.firstWhere(
                                  (item) => item.productType == _selectedStockType,
                                  orElse: () => StockModel(
                                    id: '',
                                    batchId: '',
                                    productType: _selectedStockType!,
                                    quantity: 0,
                                    partnerId: widget.partnerId,
                                    allocatedDate: Timestamp.now(),
                                    createdAt: Timestamp.now(),
                                    updatedAt: Timestamp.now(),
                                  ),
                                );
                                if (units > stockItem.quantity) {
                                  return 'Units exceed available stock';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Buttons column on the right
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Up button (increment)
                            SizedBox(
                              width: 48,
                              height: 24,
                              child: ElevatedButton(
                                onPressed: _incrementUnits,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Icon(Icons.keyboard_arrow_up, size: 16),
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Down button (decrement)
                            SizedBox(
                              width: 48,
                              height: 24,
                              child: ElevatedButton(
                                onPressed: (int.tryParse(_unitsController.text) ?? 1) <= 1 
                                    ? null 
                                    : _decrementUnits,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Icon(Icons.keyboard_arrow_down, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price per Unit (£)',
                        labelStyle: TextStyle(color: color),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          // Trigger rebuild to update total sales
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Price must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSalesChannel,
                      decoration: InputDecoration(
                        labelText: 'Sales Channel',
                        labelStyle: TextStyle(color: color),
                        border: const OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Store',
                          child: Text('Store'),
                        ),
                        DropdownMenuItem(
                          value: 'Online',
                          child: Text('Online'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSalesChannel = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a sales channel';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Customer Name field
                    TextFormField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        labelText: 'Customer Name',
                        labelStyle: TextStyle(color: color),
                        border: const OutlineInputBorder(),
                        hintText: 'Enter customer name',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Total Sales Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                            text: 'Total Sales:',
                            color: Colors.green,
                            textSize: 18,
                            isTitle: true,
                          ),
                          TextWidget(
                            text: '£${_totalSales.toStringAsFixed(2)}',
                            color: Colors.green,
                            textSize: 20,
                            isTitle: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Record Sale'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 