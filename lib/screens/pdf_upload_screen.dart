// lib/screens/pdf_upload_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/pdf_processing_service.dart';
import '../services/tax_statement_parser.dart';
import '../providers/property_provider.dart';
import '../models/property_file.dart';

class PdfUploadScreen extends StatefulWidget {
  const PdfUploadScreen({Key? key}) : super(key: key);

  @override
  State<PdfUploadScreen> createState() => _PdfUploadScreenState();
}

class _PdfUploadScreenState extends State<PdfUploadScreen> {
  List<PlatformFile> _selectedFiles = [];
  bool _isProcessing = false;
  String _statusMessage = '';
  Map<String, FileProcessingResult> _fileStatuses = {};
  BatchResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Upload Tax Statements'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Tax Statement PDFs',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select multiple PDF files of Multnomah County tax statements. The system will:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Extract text from each PDF'),
                    const Text('• Match properties by address'),
                    const Text('• Update tax account numbers and amounts'),
                    const Text('• Add sales history and payment records'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // File Selection
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _selectFiles,
                    icon: const Icon(Icons.file_upload),
                    label: Text(_selectedFiles.isEmpty
                        ? 'Select PDF Files'
                        : '${_selectedFiles.length} Files Selected'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _selectedFiles.isEmpty || _isProcessing
                      ? null
                      : _processFiles,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Process Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Card(
                color:
                    _isProcessing ? Colors.blue.shade50 : Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (_isProcessing)
                        const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      if (_isProcessing) const SizedBox(width: 12),
                      Expanded(child: Text(_statusMessage)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Results Summary
            if (_lastResult != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch Processing Complete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Total Files: ${_lastResult!.totalFiles}'),
                      Text('Successful: ${_lastResult!.successCount}'),
                      Text('Failed: ${_lastResult!.errorCount}'),
                      Text(
                          'Success Rate: ${(_lastResult!.successRate * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // File List
            Expanded(
              child: _selectedFiles.isEmpty
                  ? const Center(
                      child: Text(
                        'No files selected.\nSelect PDF files to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        final status = _fileStatuses[file.name] ??
                            FileProcessingResult.pending();

                        return Card(
                          child: ListTile(
                            leading: _getStatusIcon(status),
                            title: Text(file.name),
                            subtitle: Text(
                                '${_formatFileSize(file.size)} • ${status.description}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: _isProcessing
                                  ? null
                                  : () => _removeFile(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Clear All Button
            if (_selectedFiles.isNotEmpty && !_isProcessing)
              TextButton(
                onPressed: _clearAllFiles,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear All Files'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: true, // Important: needed to get file bytes
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.files;
          _fileStatuses.clear();
          _lastResult = null;
          _statusMessage = '';
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting files: $e', isError: true);
    }
  }

  Future<void> _processFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Starting batch processing...';
      _fileStatuses.clear();
    });

    try {
      // Extract text from all PDFs
      final result = await PdfBatchProcessor.processTaxStatementBatch(
        context: context,
        pdfFiles: _selectedFiles,
        onProgress: (message) {
          setState(() {
            _statusMessage = message;
          });
        },
      );

      // Process each successfully extracted PDF
      final propertyProvider = context.read<PropertyProvider>();
      int propertiesUpdated = 0;

      for (final entry in result.extractedTexts.entries) {
        final filename = entry.key;
        final extractedText = entry.value;

        setState(() {
          _statusMessage = 'Processing tax data from $filename...';
        });

        try {
          // Parse tax statement data
          final taxData = TaxStatementParser.parseFromText(extractedText);

          if (taxData == null) {
            _fileStatuses[filename] =
                FileProcessingResult.failed('Could not parse tax data');
            continue;
          }

          // Find matching property
          final matchingProperty = _findMatchingProperty(
              propertyProvider.properties, taxData.address);

          if (matchingProperty == null) {
            _fileStatuses[filename] =
                FileProcessingResult.failed('No matching property found');
            continue;
          }

          // Update property with tax data
          final updatedProperty =
              _mergePropertyWithTaxData(matchingProperty, taxData);
          await propertyProvider.updatePropertySafe(updatedProperty);

          _fileStatuses[filename] = FileProcessingResult.success(
              'Updated property ${matchingProperty.fileNumber}');
          propertiesUpdated++;
        } catch (e) {
          _fileStatuses[filename] = FileProcessingResult.failed('Error: $e');
        }
      }

      // Handle extraction errors
      for (final entry in result.errors.entries) {
        _fileStatuses[entry.key] = FileProcessingResult.failed(
            'PDF extraction failed: ${entry.value}');
      }

      setState(() {
        _lastResult = result;
        _statusMessage =
            'Batch processing complete. Updated $propertiesUpdated properties.';
      });

      _showSnackBar(
          'Successfully processed ${result.successCount} files and updated $propertiesUpdated properties.');
    } catch (e) {
      setState(() {
        _statusMessage = 'Batch processing failed: $e';
      });
      _showSnackBar('Batch processing failed: $e', isError: true);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      if (_selectedFiles.isEmpty) {
        _fileStatuses.clear();
        _lastResult = null;
        _statusMessage = '';
      }
    });
  }

  void _clearAllFiles() {
    setState(() {
      _selectedFiles.clear();
      _fileStatuses.clear();
      _lastResult = null;
      _statusMessage = '';
    });
  }

  Widget _getStatusIcon(FileProcessingResult status) {
    switch (status.status) {
      case ProcessingStatusType.pending:
        return const Icon(Icons.pending, color: Colors.grey);
      case ProcessingStatusType.processing:
        return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2));
      case ProcessingStatusType.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case ProcessingStatusType.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  // Helper methods for property matching and merging
  PropertyFile? _findMatchingProperty(
      List<PropertyFile> properties, String address) {
    final normalizedPdfAddress = _normalizeAddress(address);

    for (final property in properties) {
      final normalizedPropertyAddress = _normalizeAddress(property.address);

      // Exact match
      if (normalizedPropertyAddress == normalizedPdfAddress) {
        return property;
      }

      // Fuzzy match (contains major components)
      if (_addressesMatch(normalizedPropertyAddress, normalizedPdfAddress)) {
        return property;
      }
    }

    return null;
  }

  String _normalizeAddress(String address) {
    return address
        .toUpperCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single
        .trim();
  }

  bool _addressesMatch(String addr1, String addr2) {
    final parts1 = addr1.split(' ');
    final parts2 = addr2.split(' ');

    // Must have matching street number
    if (parts1.isNotEmpty && parts2.isNotEmpty) {
      if (parts1[0] != parts2[0]) return false;
    }

    // Check for common street name components
    int matchingParts = 0;
    for (final part1 in parts1) {
      if (part1.length > 2 && parts2.contains(part1)) {
        matchingParts++;
      }
    }

    // Require at least 2 matching significant parts
    return matchingParts >= 2;
  }

  PropertyFile _mergePropertyWithTaxData(
      PropertyFile property, TaxStatementData taxData) {
    // Create comprehensive tax note
    final taxNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: 'Multnomah County Tax Data (Auto-Uploaded)',
      content: '''
TAX STATEMENT INFORMATION
Uploaded: ${taxData.extractedAt.toString().substring(0, 16)}

PROPERTY DETAILS:
Tax Account: ${taxData.propertyId}
Owner: ${taxData.ownerName ?? 'N/A'}
Legal Description: ${taxData.legalDescription ?? 'N/A'}

FINANCIAL INFORMATION:
2025 Assessed Value: \$${taxData.assessedValue?.toStringAsFixed(0) ?? 'N/A'}
Total Taxes Due: \$${taxData.totalDue?.toStringAsFixed(2) ?? '0.00'}

SOURCE:
${taxData.sourceUrl ?? 'Uploaded PDF'}

Note: Data extracted automatically from uploaded PDF
      ''',
      createdAt: DateTime.now(),
    );

    return PropertyFile(
      id: property.id,
      fileNumber: property.fileNumber,
      address: property.address,
      city: property.city,
      state: property.state,
      zipCode: property.zipCode,
      county: property.county ?? 'Multnomah',

      // UPDATE WITH TAX DATA
      taxAccountNumber: taxData.propertyId,
      loanAmount: property.loanAmount,
      amountOwed: taxData.totalDue ?? property.amountOwed,
      arrears: property.arrears,
      zillowUrl: property.zillowUrl,

      // PRESERVE EXISTING DATA AND ADD TAX NOTE
      contacts: property.contacts,
      documents: property.documents,
      judgments: property.judgments,
      notes: [...property.notes, taxNote],
      trustees: property.trustees,
      auctions: property.auctions,
      vesting: property.vesting,
      createdAt: property.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// Updated status tracking classes
enum ProcessingStatusType {
  pending,
  processing,
  success,
  failed,
}

class FileProcessingResult {
  final ProcessingStatusType status;
  final String message;

  FileProcessingResult._(this.status, this.message);

  factory FileProcessingResult.pending([String? message]) =>
      FileProcessingResult._(
          ProcessingStatusType.pending, message ?? 'Pending');

  factory FileProcessingResult.processing([String? message]) =>
      FileProcessingResult._(
          ProcessingStatusType.processing, message ?? 'Processing...');

  factory FileProcessingResult.success([String? message]) =>
      FileProcessingResult._(
          ProcessingStatusType.success, message ?? 'Success');

  factory FileProcessingResult.failed([String? message]) =>
      FileProcessingResult._(ProcessingStatusType.failed, message ?? 'Failed');

  String get description => message;
}
