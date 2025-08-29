import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../models/property_file.dart';

class AddContactScreen extends StatefulWidget {
  final PropertyFile property;

  const AddContactScreen({super.key, required this.property});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newContact = Contact(
        name: _nameController.text.trim(),
        phone:
            _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
        email:
            _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
        role: _roleController.text.trim(),
      );

      final updatedProperty = PropertyFile(
        id: widget.property.id,
        fileNumber: widget.property.fileNumber,
        address: widget.property.address,
        city: widget.property.city,
        state: widget.property.state,
        zipCode: widget.property.zipCode,
        loanAmount: widget.property.loanAmount,
        amountOwed: widget.property.amountOwed,
        arrears: widget.property.arrears, // ADD THIS
        zillowUrl: widget.property.zillowUrl, // ADD THIS
        contacts: [...widget.property.contacts, newContact],
        documents: widget.property.documents,
        judgments: widget.property.judgments, // ADD THIS
        notes: widget.property.notes, // ADD THIS
        trustees: widget.property.trustees, // ADD THIS
        auctions: widget.property.auctions, // ADD THIS
        vesting: widget.property.vesting,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
      );

      await context.read<PropertyProvider>().updateProperty(updatedProperty);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding contact: $e')));
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
        title: const Text('Add Contact'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveContact,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
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
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role *',
                hintText: 'e.g., Borrower, Attorney, Agent',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a role';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }
}
