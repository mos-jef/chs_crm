// lib/screens/enhance_properties_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/property_file.dart';
import '../providers/property_provider.dart';
import '../services/tax_data_enhancer.dart';
import '../widgets/custom_beam_button.dart';

class EnhancePropertiesScreen extends StatefulWidget {
  const EnhancePropertiesScreen({super.key});

  @override
  State<EnhancePropertiesScreen> createState() =>
      _EnhancePropertiesScreenState();
}

class _EnhancePropertiesScreenState extends State<EnhancePropertiesScreen> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  List<PropertyEnhancement> _enhancements = [];
  String _statusMessage = '';
  int _enhancedCount = 0;

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

  Future<void> _parseAndMatchTaxData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Parsing tax data and finding matching properties...';
      _enhancements.clear();
      _enhancedCount = 0;
    });

    try {
      final propertyProvider = context.read<PropertyProvider>();
      final existingProperties = propertyProvider.properties;

      final enhancements = TaxDataEnhancer.parseAndMatch(
        _textController.text,
        existingProperties,
      );

      setState(() {
        _enhancements = enhancements;
        _isProcessing = false;

        final matchedCount = enhancements.where((e) => e.hasMatch).length;
        final unmatchedCount = enhancements.length - matchedCount;

        if (enhancements.isEmpty) {
          _statusMessage = 'No valid tax data found. Please check the format.';
        } else {
          _statusMessage = 'Found ${enhancements.length} tax records. '
              '$matchedCount matched existing properties, '
              '$unmatchedCount had no matches.';
        }
      });

      if (enhancements.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tax data found. Please check the format.'),
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

  Future<void> _enhanceAllMatches() async {
    final matchedEnhancements = _enhancements.where((e) => e.hasMatch).toList();
    if (matchedEnhancements.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _enhancedCount = 0;
      _statusMessage = 'Enhancing properties with tax data...';
    });

    final propertyProvider = context.read<PropertyProvider>();
    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];

    for (int i = 0; i < matchedEnhancements.length; i++) {
      final enhancement = matchedEnhancements[i];

      setState(() {
        _statusMessage =
            'Enhancing property ${i + 1}/${matchedEnhancements.length}: '
            '${enhancement.existingProperty!.fileNumber}';
      });

      try {
        final enhancedProperty = TaxDataEnhancer.enhanceProperty(enhancement);
        await propertyProvider.updateProperty(enhancedProperty);

        successCount++;
        setState(() {
          _enhancedCount = successCount;
        });

        // Small delay to avoid overwhelming the database
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        failureCount++;
        errors.add('${enhancement.existingProperty!.fileNumber}: $e');
        print(
            'Error enhancing property ${enhancement.existingProperty!.fileNumber}: $e');
      }
    }

    setState(() {
      _isProcessing = false;
      _statusMessage =
          'Completed! Enhanced $successCount properties with tax data.';
      if (failureCount > 0) {
        _statusMessage += ' $failureCount failed to update.';
      }
    });

    // Show completion message
    final message = successCount > 0
        ? 'Successfully enhanced $successCount properties with tax data!'
        : 'No properties were enhanced. Please check for errors.';

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
      _enhancements.clear();
      _statusMessage = '';
      _enhancedCount = 0;
    });
  }

  void _removeEnhancement(int index) {
    setState(() {
      _enhancements.removeAt(index);
      if (_enhancements.isEmpty) {
        _statusMessage = 'All enhancements removed. Add more data to continue.';
      } else {
        final matchedCount = _enhancements.where((e) => e.hasMatch).length;
        _statusMessage = '$matchedCount properties ready to enhance.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhance Properties with Tax Data'),
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
                    if (_enhancements.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildEnhancementsPreview(),
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
                Icon(Icons.auto_fix_high,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Property Enhancement Instructions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Paste the formatted tax data provided by Claude\n'
              '2. System will find existing properties by matching addresses\n'
              '3. Tax data will be ADDED to existing properties (not create new ones)\n'
              '4. Review the matches and enhance selected properties\n'
              '5. Tax notes and documents will be added to matched properties',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Text(
                'Note: This will enhance your existing properties with tax information, preserving all loan amounts, sale dates, and other existing data.',
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
                  'Tax Data for Enhancement',
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
                  return 'Please enter tax data to process';
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
    final matchedCount = _enhancements.where((e) => e.hasMatch).length;

    return Row(
      children: [
        Expanded(
          child: CustomBeamButton(
            text: _isProcessing ? 'PROCESSING...' : 'FIND MATCHES',
            onPressed: _isProcessing ? null : _parseAndMatchTaxData,
            isLoading: _isProcessing,
            height: 50,
            buttonStyle: CustomButtonStyle.primary,
          ),
        ),
        if (matchedCount > 0) ...[
          const SizedBox(width: 16),
          Expanded(
            child: CustomBeamButton(
              text: _isProcessing
                  ? 'ENHANCING...'
                  : 'ENHANCE $matchedCount PROPERTIES',
              onPressed: _isProcessing ? null : _enhanceAllMatches,
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
              : _statusMessage.contains('Enhanced') ||
                      _statusMessage.contains('Successfully')
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
                  : _statusMessage.contains('Enhanced') ||
                          _statusMessage.contains('Successfully')
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
              color: _statusMessage.contains('Error') ||
                      _statusMessage.contains('failed')
                  ? Colors.red
                  : _statusMessage.contains('Enhanced') ||
                          _statusMessage.contains('Successfully')
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
            if (_enhancedCount > 0)
              Chip(
                label: Text('Enhanced: $_enhancedCount'),
                backgroundColor: Colors.green[100],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancementsPreview() {
    final matchedEnhancements = _enhancements.where((e) => e.hasMatch).toList();
    final unmatchedEnhancements =
        _enhancements.where((e) => !e.hasMatch).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Property Matches',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (matchedEnhancements.isNotEmpty)
                  Chip(
                    label: Text('${matchedEnhancements.length} matches'),
                    backgroundColor: Colors.green[100],
                  ),
                if (unmatchedEnhancements.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${unmatchedEnhancements.length} unmatched'),
                    backgroundColor: Colors.orange[100],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Matched Properties
            if (matchedEnhancements.isNotEmpty) ...[
              const Text(
                'Properties Ready to Enhance:',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matchedEnhancements.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final enhancement = matchedEnhancements[index];
                  final existing = enhancement.existingProperty!;
                  final taxData = enhancement.taxData;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                    title: Text(
                      existing.fileNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(existing.address),
                        Text(
                            '${existing.city}, ${existing.state} ${existing.zipCode}'),
                        Text(
                          'Will add: Tax ID ${taxData.propertyId}, Owner: ${taxData.owner ?? "N/A"}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Match confidence: ${(enhancement.matchConfidence * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.orange),
                      onPressed: () => _removeEnhancement(
                          _enhancements.indexOf(enhancement)),
                      tooltip: 'Remove Enhancement',
                    ),
                  );
                },
              ),
            ],

            // Unmatched Properties
            if (unmatchedEnhancements.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Tax Data with No Matching Properties:',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: unmatchedEnhancements.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final enhancement = unmatchedEnhancements[index];
                  final taxData = enhancement.taxData;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.warning, color: Colors.white, size: 16),
                    ),
                    title: Text(
                      'Tax ID: ${taxData.propertyId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(taxData.address),
                        if (taxData.owner != null)
                          Text('Owner: ${taxData.owner}'),
                        const Text(
                          'No existing property found with matching address',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () => _removeEnhancement(
                          _enhancements.indexOf(enhancement)),
                      tooltip: 'Remove Unmatched',
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
