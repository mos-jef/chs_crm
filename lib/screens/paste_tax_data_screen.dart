// lib/screens/paste_tax_data_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/property_file.dart';
import '../providers/property_provider.dart';
import '../services/tax_data_parser.dart';
import '../widgets/custom_beam_button.dart';

class PasteTaxDataScreen extends StatefulWidget {
  const PasteTaxDataScreen({super.key});

  @override
  State<PasteTaxDataScreen> createState() => _PasteTaxDataScreenState();
}

class _PasteTaxDataScreenState extends State<PasteTaxDataScreen> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  List<PropertyFile> _parsedProperties = [];
  String _statusMessage = '';
  int _savedCount = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text != null) {
        setState(() {
          _textController.text = clipboardData!.text!;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tax data pasted from clipboard')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No text found in clipboard')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing clipboard: $e')),
      );
    }
  }

  Future<void> _parseTaxData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Parsing tax data...';
      _parsedProperties.clear();
      _savedCount = 0;
    });

    try {
      final properties = TaxDataParser.parseTaxData(_textController.text);

      setState(() {
        _parsedProperties = properties;
        _isProcessing = false;

        if (properties.isEmpty) {
          _statusMessage =
              'No valid properties found in the pasted data. Please check the format.';
        } else {
          _statusMessage =
              'Successfully parsed ${properties.length} properties! Review and save below.';
        }
      });

      if (properties.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No properties found. Please check the data format.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error parsing tax data: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parsing failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAllProperties() async {
    if (_parsedProperties.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _savedCount = 0;
      _statusMessage = 'Saving properties to CRM...';
    });

    final propertyProvider = context.read<PropertyProvider>();
    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];

    for (int i = 0; i < _parsedProperties.length; i++) {
      final property = _parsedProperties[i];

      setState(() {
        _statusMessage =
            'Saving property ${i + 1}/${_parsedProperties.length}: ${property.fileNumber}';
      });

      try {
        await propertyProvider.addProperty(property);
        successCount++;

        setState(() {
          _savedCount = successCount;
        });

        // Small delay to avoid overwhelming the database
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        failureCount++;
        errors.add('${property.fileNumber}: $e');
        print('Error saving property ${property.fileNumber}: $e');
      }
    }

    setState(() {
      _isProcessing = false;
      _statusMessage =
          'Completed! Saved $successCount properties successfully.';
      if (failureCount > 0) {
        _statusMessage += ' $failureCount failed to save.';
      }
    });

    // Show completion message
    final message = successCount > 0
        ? 'Successfully saved $successCount properties to your CRM!'
        : 'No properties were saved. Please check for errors.';

    final backgroundColor = successCount > 0 ? Colors.green : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
      ),
    );

    // Clear the form if all succeeded
    if (failureCount == 0 && successCount > 0) {
      _clearForm();
    }
  }

  void _clearForm() {
    setState(() {
      _textController.clear();
      _parsedProperties.clear();
      _statusMessage = '';
      _savedCount = 0;
    });
  }

  void _removeProperty(int index) {
    setState(() {
      _parsedProperties.removeAt(index);
      if (_parsedProperties.isEmpty) {
        _statusMessage = 'All properties removed. Add more data to continue.';
      } else {
        _statusMessage =
            '${_parsedProperties.length} properties ready to save.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Tax Data'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_textController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearForm,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructionsCard(),
                    const SizedBox(height: 16),
                    _buildTextInputCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildStatusCard(),
                    ],
                    if (_parsedProperties.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPropertiesPreview(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Tax Data Import Instructions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Paste the formatted tax data provided by Claude\n'
              '2. Each property should start with "PROPERTY ID:" line\n'
              '3. Make sure Google Drive links are updated if needed\n'
              '4. Click "Parse Tax Data" to process the information\n'
              '5. Review the parsed properties and save to your CRM',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                'Tip: You can paste multiple properties at once for bulk import. Each property will be automatically separated and processed.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Tax Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste),
                  label: const Text('Paste from Clipboard'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _textController,
              maxLines: 20,
              decoration: const InputDecoration(
                hintText: 'Paste formatted tax data here...\n\n'
                    'Expected format:\n'
                    'PROPERTY ID: R155106\n'
                    'ADDRESS: 17724 SE MILL CT, GRESHAM, OR 97233\n'
                    'OWNER: WALKER,BRENT L\n'
                    '...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter tax data to parse';
                }
                if (!value.contains('PROPERTY ID:')) {
                  return 'Tax data must contain at least one property with "PROPERTY ID:" field';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Characters: ${_textController.text.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomBeamButton(
            text: _isProcessing ? 'PROCESSING...' : 'PARSE TAX DATA',
            onPressed: _isProcessing ? null : _parseTaxData,
            isLoading: _isProcessing,
            height: 50,
            buttonStyle: CustomButtonStyle.primary,
          ),
        ),
        if (_parsedProperties.isNotEmpty) ...[
          const SizedBox(width: 16),
          Expanded(
            child: CustomBeamButton(
              text: _isProcessing ? 'SAVING...' : 'SAVE ALL TO CRM',
              onPressed: _isProcessing ? null : _saveAllProperties,
              isLoading: _isProcessing,
              height: 50,
              buttonStyle: CustomButtonStyle.secondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color:
          _statusMessage.contains('Error') || _statusMessage.contains('failed')
              ? Colors.red[50]
              : _statusMessage.contains('Successfully')
                  ? Colors.green[50]
                  : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _statusMessage.contains('Error') ||
                      _statusMessage.contains('failed')
                  ? Icons.error_outline
                  : _statusMessage.contains('Successfully')
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
              color: _statusMessage.contains('Error') ||
                      _statusMessage.contains('failed')
                  ? Colors.red
                  : _statusMessage.contains('Successfully')
                      ? Colors.green
                      : Colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusMessage,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (_savedCount > 0)
              Chip(
                label: Text('Saved: $_savedCount'),
                backgroundColor: Colors.green[100],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Parsed Properties',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: Text('${_parsedProperties.length} properties'),
                  backgroundColor: Colors.blue[100],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _parsedProperties.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final property = _parsedProperties[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text(
                    property.fileNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.address),
                      Text(
                          '${property.city}, ${property.state} ${property.zipCode}'),
                      if (property.amountOwed != null)
                        Text(
                          'Taxes Due: \$${property.amountOwed!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: property.amountOwed! > 0
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeProperty(index),
                    tooltip: 'Remove Property',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
