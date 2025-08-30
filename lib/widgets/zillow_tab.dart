import 'dart:js_interop';
import 'package:web/web.dart' as web;

import 'package:chs_crm/providers/theme_provider.dart';
import 'package:chs_crm/utils/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/property_file.dart';
import '../providers/property_provider.dart';

class ZillowTab extends StatefulWidget {
  final PropertyFile property;

  const ZillowTab({super.key, required this.property});

  @override
  State<ZillowTab> createState() => _ZillowTabState();
}

class _ZillowTabState extends State<ZillowTab> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.property.zillowUrl ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveZillowUrl() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProperty = PropertyFile(
        id: widget.property.id,
        fileNumber: widget.property.fileNumber,
        address: widget.property.address,
        city: widget.property.city,
        state: widget.property.state,
        zipCode: widget.property.zipCode,
        loanAmount: widget.property.loanAmount,
        amountOwed: widget.property.amountOwed,
        arrears: widget.property.arrears,
        zillowUrl:
            _urlController.text.trim().isNotEmpty
                ? _urlController.text.trim()
                : null,
        contacts: widget.property.contacts,
        documents: widget.property.documents,
        judgments: widget.property.judgments,
        notes: widget.property.notes,
        trustees: widget.property.trustees,
        auctions: widget.property.auctions,
        vesting: widget.property.vesting,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
      );

      await context.read<PropertyProvider>().updateProperty(updatedProperty);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zillow URL saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving Zillow URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _openZillowUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      web.window.open(url, '_blank');
    }
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final url = value.trim().toLowerCase();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }

    // Basic URL validation
    try {
      Uri.parse(value.trim());
    } catch (e) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.link,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Zillow Property Link',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add the Zillow URL for this property to quickly access property details, photos, and market information.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Zillow URL',
                      hintText: 'https://www.zillow.com/homedetails/...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link),
                      suffixIcon:
                          _urlController.text.trim().isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: _openZillowUrl,
                                tooltip: 'Open in new tab',
                              )
                              : null,
                    ),
                    validator: _validateUrl,
                    onChanged: (value) {
                      setState(() {}); // Refresh to show/hide open button
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveZillowUrl,
                        icon:
                            _isLoading
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.save),
                        label: Text(_isLoading ? 'Saving...' : 'Save'),
                      ),
                      const SizedBox(width: 12),
                      if (_urlController.text.trim().isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: _openZillowUrl,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open Zillow'),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current URL Display
            if (widget.property.zillowUrl != null &&
                widget.property.zillowUrl!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current Zillow URL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return InkWell(
                            onTap:
                                () => web.window.open(
                                  widget.property.zillowUrl!,
                                  '_blank',
                                ),
                            child: Text(
                              widget.property.zillowUrl!,
                              style: TextStyle(
                                color: AppThemes.getTotalOwedColor(
                                  themeProvider.currentTheme,
                                ),
                                fontWeight:
                                    FontWeight.bold, // Bold as requested
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
