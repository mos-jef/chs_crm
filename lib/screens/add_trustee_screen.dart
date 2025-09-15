import 'package:chs_crm/widgets/custom_beam_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/property_file.dart';
import '../providers/property_provider.dart';
import '../utils/validators.dart';

class AddTrusteeScreen extends StatefulWidget {
  final PropertyFile property;
  final Trustee? existingTrustee;

  const AddTrusteeScreen({
    super.key,
    required this.property,
    this.existingTrustee,
  });

  @override
  State<AddTrusteeScreen> createState() => _AddTrusteeScreenState();
}

class _AddTrusteeScreenState extends State<AddTrusteeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTrustee != null) {
      _isEditing = true;
      _nameController.text = widget.existingTrustee!.name;
      _institutionController.text = widget.existingTrustee!.institution;
      _phoneController.text = widget.existingTrustee!.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveTrustee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Trustee> updatedTrustees = List.from(widget.property.trustees);

      if (_isEditing) {
        final updatedTrustee = Trustee(
          id: widget.existingTrustee!.id,
          name: _nameController.text.trim(),
          institution: _institutionController.text.trim(),
          phoneNumber: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          createdAt: widget.existingTrustee!.createdAt,
          updatedAt: DateTime.now(),
        );

        final index = updatedTrustees.indexWhere(
          (t) => t.id == widget.existingTrustee!.id,
        );
        if (index != -1) {
          updatedTrustees[index] = updatedTrustee;
        }
      } else {
        final newTrustee = Trustee(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          institution: _institutionController.text.trim(),
          phoneNumber: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          createdAt: DateTime.now(),
        );
        updatedTrustees.add(newTrustee);
      }

      final updatedProperty = PropertyFile(
        id: widget.property.id,
        fileNumber: widget.property.fileNumber,
        address: widget.property.address,
        city: widget.property.city,
        state: widget.property.state,
        zipCode: widget.property.zipCode,
        loanAmount: widget.property.loanAmount,
        amountOwed: widget.property.amountOwed,
        arrears: widget.property.arrears, // ✅ Already present
        zillowUrl: widget.property.zillowUrl, // ✅ Already present
        contacts: widget.property.contacts,
        documents: widget.property.documents,
        judgments: widget.property.judgments,
        notes: widget.property.notes,
        trustees: updatedTrustees, // ✅ This is correct
        auctions: widget.property.auctions,
        vesting: widget.property.vesting,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
      );

      await context.read<PropertyProvider>().updateProperty(updatedProperty);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Trustee ${_isEditing ? 'updated' : 'added'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${_isEditing ? 'updating' : 'adding'} trustee: $e',
            ),
          ),
        );
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
        title: Text(_isEditing ? 'Edit Trustee' : 'Add Trustee'),
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) =>
                  Validators.validateRequired(value, 'a name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _institutionController,
              decoration: const InputDecoration(
                labelText: 'Institution *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) =>
                  Validators.validateRequired(value, 'an institution'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
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
                  text: _isEditing ? 'Update' : 'Save',
                  onPressed: _isLoading ? null : _saveTrustee,
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
