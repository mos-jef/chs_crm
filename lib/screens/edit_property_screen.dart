import 'package:chs_crm/widgets/custom_beam_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/property_file.dart';
import '../providers/property_provider.dart';

class EditPropertyScreen extends StatefulWidget {
  final PropertyFile property;

  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fileNumberController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _loanAmountController;
  late TextEditingController _amountOwedController;
  late TextEditingController _arrearsController;
  late TextEditingController _estimatedSaleValueController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fileNumberController = TextEditingController(
      text: widget.property.fileNumber,
    );
    _addressController = TextEditingController(text: widget.property.address);
    _cityController = TextEditingController(text: widget.property.city);
    _stateController = TextEditingController(text: widget.property.state);
    _zipController = TextEditingController(text: widget.property.zipCode);
    _loanAmountController = TextEditingController(
      text: widget.property.loanAmount?.toString() ?? '',
    );
    _amountOwedController = TextEditingController(
      text: widget.property.amountOwed?.toString() ?? '',
    );
    _arrearsController = TextEditingController(
      text: widget.property.arrears?.toString() ?? '',
    );
    _estimatedSaleValueController = TextEditingController(
      text: widget.property.estimatedSaleValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _fileNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _loanAmountController.dispose();
    _amountOwedController.dispose();
    _arrearsController.dispose();
    _estimatedSaleValueController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get latest property data to avoid overwriting other fields
      final propertyProvider = context.read<PropertyProvider>();
      final latestProperty = propertyProvider.getPropertyById(
        widget.property.id,
      );

      if (latestProperty == null) {
        throw Exception('Property not found in cache');
      }

      final updatedProperty = PropertyFile(
        id: latestProperty.id,
        fileNumber: _fileNumberController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipController.text.trim(),
        loanAmount: _loanAmountController.text.isNotEmpty
            ? double.tryParse(_loanAmountController.text)
            : null,
        amountOwed: _amountOwedController.text.isNotEmpty
            ? double.tryParse(_amountOwedController.text)
            : null,
        arrears: _arrearsController.text.isNotEmpty // ADD THIS BLOCK
            ? double.tryParse(_arrearsController.text)
            : null,
        estimatedSaleValue:
          _estimatedSaleValueController.text.isNotEmpty 
              ? double.tryParse(_estimatedSaleValueController.text)
              : null,  
        zillowUrl: latestProperty.zillowUrl, // From latest
        contacts: latestProperty.contacts, // From latest
        documents: latestProperty.documents, // From latest
        judgments: latestProperty.judgments, // From latest
        notes: latestProperty.notes, // From latest
        trustees: latestProperty.trustees, // From latest
        auctions: latestProperty.auctions, // From latest
        vesting: latestProperty.vesting, // From latest
        createdAt: latestProperty.createdAt,
        updatedAt: DateTime.now(),
      );

      await propertyProvider.updateProperty(updatedProperty);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating property: $e')));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit File #${widget.property.fileNumber}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fileNumberController,
              decoration: const InputDecoration(
                labelText: 'File Number *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a file number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _zipController,
                    decoration: const InputDecoration(
                      labelText: 'ZIP *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loanAmountController,
              decoration: const InputDecoration(
                labelText: 'Loan Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amountOwedController,
              decoration: const InputDecoration(
                labelText: 'Amount Owed',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // ADD THIS NEW FIELD:
            TextFormField(
              controller: _arrearsController,
              decoration: const InputDecoration(
                labelText: 'Arrears',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final number = double.tryParse(value);
                  if (number == null) {
                    return 'Please enter a valid number';
                  }
                  if (number < 0) {
                    return 'Amount cannot be negative';
                  }
                }
                return null;
              },
            ),

            TextFormField(
              controller: _estimatedSaleValueController,
              decoration: const InputDecoration(
                labelText: 'Estimated Sale Value',
                helperText: 'Enter Zillow Zestimate or your estimate',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomBeamButton(
                  text: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                  width: 100,
                  height: 45,
                  buttonStyle: CustomButtonStyle.secondary,
                ),
                CustomBeamButton(
                  text: 'Save',
                  onPressed: _isLoading ? null : _saveChanges,
                  isLoading: _isLoading,
                  width: 100,
                  height: 45,
                  buttonStyle: CustomButtonStyle.primary,
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
