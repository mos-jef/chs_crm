// lib/screens/paste_auction_data_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/property_file.dart';
import '../providers/property_provider.dart';
import '../services/auction_text_parser.dart';

class PasteAuctionDataScreen extends StatefulWidget {
  const PasteAuctionDataScreen({super.key});

  @override
  State<PasteAuctionDataScreen> createState() => _PasteAuctionDataScreenState();
}

class _PasteAuctionDataScreenState extends State<PasteAuctionDataScreen> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  List<PropertyFile> _parsedProperties = [];
  String _statusMessage = '';

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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing clipboard: $e')),
      );
    }
  }

  Future<void> _parseAuctionData() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or paste auction data first')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Parsing auction data...';
      _parsedProperties.clear();
    });

    try {
      final properties = await AuctionTextParser.parseAuctionData(_textController.text);
      
      setState(() {
        _parsedProperties = properties;
        _statusMessage = 'Parsed ${properties.length} properties successfully!';
        _isProcessing = false;
      });

      if (properties.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No properties found in the pasted data. Please check the format.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error parsing data: $e';
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parsing failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePropertiesToCRM() async {
    if (_parsedProperties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No properties to save')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Saving ${_parsedProperties.length} properties to CRM...';
    });

    try {
      final propertyProvider = context.read<PropertyProvider>();
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < _parsedProperties.length; i++) {
        try {
          await propertyProvider.addProperty(_parsedProperties[i]);
          successCount++;
          
          setState(() {
            _statusMessage = 'Saving progress: ${i + 1}/${_parsedProperties.length} properties...';
          });
          
          // Small delay to avoid overwhelming Firestore
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          errorCount++;
          print('Error saving property ${_parsedProperties[i].address}: $e');
        }
      }

      setState(() {
        _statusMessage = 'Save completed! Success: $successCount, Errors: $errorCount';
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $successCount properties to CRM!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Properties',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ),
      );

      // Clear data after successful save
      setState(() {
        _textController.clear();
        _parsedProperties.clear();
      });

    } catch (e) {
      setState(() {
        _statusMessage = 'Save failed: $e';
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Auction Data'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionsCard(),
              const SizedBox(height: 20),
              _buildTextInputCard(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 20),
              if (_statusMessage.isNotEmpty) _buildStatusCard(),
              const SizedBox(height: 20),
              if (_parsedProperties.isNotEmpty) _buildPreviewCard(),
            ],
          ),
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
                Icon(Icons.info, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'How to Import Auction Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Visit auction.com and search for Oregon foreclosures\n'
              '2. Select and copy property listings (Ctrl+C or Cmd+C)\n'
              '3. Paste the text below or tap "Paste from Clipboard"\n'
              '4. Tap "Parse Data" to process the information\n'
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
                'Tip: Copy multiple properties at once for bulk import. The parser will automatically separate them.',
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
                  'Auction Data',
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
              maxLines: 15,
              decoration: const InputDecoration(
                hintText: 'Paste copied auction.com property data here...\n\n',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter auction data to parse';
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
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _parseAuctionData,
            icon: Icon(_isProcessing ? Icons.hourglass_empty : Icons.analytics),
            label: Text(_isProcessing ? 'Processing...' : 'Parse Data'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_parsedProperties.isEmpty || _isProcessing) ? null : _savePropertiesToCRM,
            icon: const Icon(Icons.save),
            label: Text('Save to CRM (${_parsedProperties.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_isProcessing) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _statusMessage.contains('Error') || _statusMessage.contains('failed') 
                    ? Colors.red 
                    : _statusMessage.contains('Success') || _statusMessage.contains('completed')
                      ? Colors.green 
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parsed Properties (${_parsedProperties.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _parsedProperties.length > 5 ? 5 : _parsedProperties.length,
              itemBuilder: (context, index) {
                final property = _parsedProperties[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.home, color: Theme.of(context).primaryColor),
                    title: Text(property.address.isNotEmpty ? property.address : 'Address not parsed'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${property.city}, ${property.state} ${property.zipCode}'),
                        Text('Opening Bid: \$${property.loanAmount?.toStringAsFixed(0) ?? 'N/A'}'),
                        if (property.auctions.isNotEmpty)
                          Text('Auction: ${property.auctions.first.formattedDate}'),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_parsedProperties.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... and ${_parsedProperties.length - 5} more properties',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                'Ready to save ${_parsedProperties.length} properties to your CRM. '
                'Each property will get a unique file number and detailed notes with all parsed information.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}