import 'package:chs_crm/widgets/custom_beam_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../models/property_file.dart';
import '../services/file_number_service.dart';
import '../utils/validators.dart';

// Import the enum separately to ensure it's available
// (This is already included in the custom_beam_button.dart import above)

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _amountOwedController = TextEditingController();
  final _arrearsController = TextEditingController();

  bool _isLoading = false;
  String _previewFileNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPreviewFileNumber();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _loanAmountController.dispose();
    _amountOwedController.dispose();
    _arrearsController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviewFileNumber() async {
    try {
      final fileNumber = await FileNumberService.getNextFileNumber();
      if (mounted) {
        setState(() {
          _previewFileNumber = fileNumber;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading file number preview: $e')),
        );
      }
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Reserve the file number only when saving
      final actualFileNumber = await FileNumberService.reserveFileNumber();

      final property = PropertyFile(
        id: '',
        fileNumber: actualFileNumber,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipController.text.trim(),
        loanAmount: Validators.parseAmount(_loanAmountController.text),
        amountOwed: Validators.parseAmount(_amountOwedController.text),
        arrears: Validators.parseAmount(_arrearsController.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await context.read<PropertyProvider>().addProperty(property);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Property added successfully as File #$actualFileNumber',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding property: $e')));
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _cancelAdd() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Adding Property'),
          content: const Text(
            'Are you sure you want to cancel? All entered information will be lost.',
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomBeamButton(
                  text: 'Continue',
                  onPressed: () => Navigator.of(context).pop(),
                  width: 100,
                  height: 60,
                  buttonStyle: CustomButtonStyle.secondary,
                ),
                CustomBeamButton(
                  text: 'Discard',
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close add property screen
                  },
                  width: 100,
                  height: 60,
                  buttonStyle: CustomButtonStyle.primary,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Property'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preview File Number Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.preview, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview File Number: $_previewFileNumber',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                        Text(
                          'Final number assigned on save',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  Validators.validateRequired(value, 'an address'),
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
                    validator: (value) =>
                        Validators.validateRequired(value, 'a city'),
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
                    validator: (value) =>
                        Validators.validateRequired(value, 'a state'),
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
                    validator: (value) =>
                        Validators.validateRequired(value, 'a ZIP code'),
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
              validator: Validators.validateAmount,
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
              validator: Validators.validateAmount,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _arrearsController,
              decoration: const InputDecoration(
                labelText: 'Arrears',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: Validators.validateAmount,
            ),

            const SizedBox(height: 32),

            // Action buttons at bottom center
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomBeamButton(
                  text: 'Cancel',
                  onPressed: _cancelAdd,
                  width: 100,
                  height: 60,
                  buttonStyle: CustomButtonStyle.secondary,
                ),
                CustomBeamButton(
                  text: 'Save',
                  onPressed: _isLoading ? null : _saveProperty,
                  isLoading: _isLoading,
                  width: 100,
                  height: 60,
                  buttonStyle: CustomButtonStyle.primary,
                ),
              ],
            ),

            const SizedBox(height: 16), // Bottom padding
          ],
        ),
      ),
    );
  }
}
