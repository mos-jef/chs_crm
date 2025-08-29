import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../providers/property_provider.dart';
import '../models/property_file.dart';
import '../services/document_service.dart';
import '../utils/validators.dart';

// Add this debug service - you can create it as a separate file later
class QuickDebug {
  static Future<void> testFirebaseStorage() async {
    try {
      print('=== FIREBASE STORAGE DEBUG TEST ===');

      final storage = FirebaseStorage.instance;
      print('Storage bucket: ${storage.bucket}');

      // Test 1: Simple text upload - Fixed type issue
      final testString = 'Hello Firebase Storage Debug Test';
      final testData = Uint8List.fromList(testString.codeUnits);
      final ref = storage.ref().child(
        'debug_test/test_${DateTime.now().millisecondsSinceEpoch}.txt',
      );

      print('Uploading test data to: ${ref.fullPath}');
      print('Test data size: ${testData.length} bytes');

      final uploadTask = ref.putData(testData);

      // Monitor progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Debug upload progress: ${progress.toStringAsFixed(1)}%');
      });

      final snapshot = await uploadTask.timeout(const Duration(seconds: 15));

      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        print('✓ Upload successful: $url');

        // Clean up
        await ref.delete();
        print('✓ Test file deleted');
      } else {
        print('✗ Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      print('✗ Storage test failed: $e');
      rethrow;
    }
  }

  // Add document deletion helper
  static Future<bool> deleteDocumentFromStorage(String url) async {
    try {
      print('Deleting document from storage: $url');
      final storage = FirebaseStorage.instance;
      final ref = storage.refFromURL(url);
      await ref.delete();
      print('✓ Document deleted from storage successfully');
      return true;
    } catch (e) {
      print('✗ Failed to delete document from storage: $e');
      return false;
    }
  }
}

class AddDocumentScreen extends StatefulWidget {
  final PropertyFile property;
  final Document? existingDocument;

  const AddDocumentScreen({
    super.key,
    required this.property,
    this.existingDocument,
  });

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'Deed';
  bool _isLoading = false;
  PlatformFile? _selectedFile;
  bool _isEditing = false;
  String _uploadStatus = '';

  final List<String> _documentTypes = [
    'Deed',
    'Mortgage',
    'Title Insurance',
    'Appraisal',
    'Survey',
    'HOA Documents',
    'Property Tax Records',
    'Insurance Policy',
    'Lien Documents',
    'Court Documents',
    'Judgment', // NEW
    'Foreclosure', // NEW
    'Notice of Default', // NEW
    'Affidavit of Mailing', // NEW
    'Deed of Trust', // NEW
    'Assignment Deed of Trust', // NEW
    'Assignment', // NEW
    'Successor Trustee', // NEW
    'Trustees Sale', // NEW
    'Sheriffs Deed', // NEW
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingDocument != null) {
      _isEditing = true;
      _nameController.text = widget.existingDocument!.name;
      _selectedType = widget.existingDocument!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _testFirebaseConnection() async {
    if (!mounted) return;

    setState(() {
      _uploadStatus = 'Testing Firebase connection...';
    });

    try {
      // Test Firestore connection
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore
          .collection('test')
          .doc('connection-test')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Firestore timeout'),
          );

      if (mounted) {
        setState(() {
          _uploadStatus = 'Firestore connection: ✓ Working';
        });
      }

      // Test Firebase Storage connection
      final FirebaseStorage storage = FirebaseStorage.instance;
      try {
        await storage
            .ref()
            .child('test-connection')
            .getMetadata()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Storage timeout'),
            );

        if (mounted) {
          setState(() {
            _uploadStatus = 'Firestore: ✓ Working | Storage: ✓ Working';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _uploadStatus =
                'Firestore: ✓ Working | Storage: ⚠ ${e.toString().split(':').last.trim()}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadStatus =
              'Connection test failed: ${e.toString().split(':').last.trim()}';
        });
      }
    }
  }

  Future<void> _runQuickStorageTest() async {
    if (!mounted) return;

    setState(() {
      _uploadStatus = 'Running Firebase Storage debug test...';
    });

    try {
      await QuickDebug.testFirebaseStorage();
      if (mounted) {
        setState(() {
          _uploadStatus =
              '✓ Debug test completed - check terminal/console for details';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadStatus = '✗ Debug test failed: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _debugFirestoreDocuments() async {
    if (!mounted) return;

    setState(() {
      _uploadStatus = 'Checking Firestore for documents...';
    });

    try {
      // Check what's actually stored in Firestore for this property
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final doc =
          await firestore
              .collection('properties')
              .doc(widget.property.id)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        final documents = data['documents'] as List<dynamic>? ?? [];

        print('=== FIRESTORE DOCUMENT DEBUG ===');
        print('Property ID: ${widget.property.id}');
        print('Documents in Firestore: ${documents.length}');

        documents.forEach((docData) {
          print('Firestore Document: ${docData['name']} (${docData['type']})');
          print('  URL: ${docData['url']}');
          print('  Upload Date: ${docData['uploadDate']}');
        });
        print('=== END FIRESTORE DEBUG ===');

        if (mounted) {
          setState(() {
            _uploadStatus =
                '✓ Found ${documents.length} documents in Firestore - check terminal for details';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _uploadStatus = '✗ Property not found in Firestore!';
          });
        }
        print(
          'Property document not found in Firestore: ${widget.property.id}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadStatus = '✗ Firestore debug failed: $e';
        });
      }
      print('Firestore debug error: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _uploadStatus = 'Selecting file...';
      });

      final file = await DocumentService.pickFile();
      if (file != null && mounted) {
        setState(() {
          _selectedFile = file;
          _uploadStatus = 'File selected: ${file.name}';
          // Auto-populate name if empty
          if (_nameController.text.isEmpty) {
            _nameController.text = file.name.split('.').first;
          }
        });
      } else if (mounted) {
        setState(() {
          _uploadStatus = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadStatus = 'Error selecting file: $e';
        });
      }
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEditing && _selectedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file to upload')),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      String? documentUrl = widget.existingDocument?.url;

      // Upload new file if selected
      if (_selectedFile != null) {
        if (mounted) {
          setState(() {
            _uploadStatus = 'Uploading file... This may take a moment.';
          });
        }

        // Add timeout and retry logic
        documentUrl = await _uploadWithRetry(
          file: _selectedFile!,
          propertyId: widget.property.id,
          documentType: _selectedType,
          maxRetries: 2,
        );

        if (documentUrl == null) {
          throw Exception('Failed to upload document after multiple attempts');
        }

        if (mounted) {
          setState(() {
            _uploadStatus = 'File uploaded successfully!';
          });
        }
      }

      if (!mounted) return;

      setState(() {
        _uploadStatus = 'Saving document information...';
      });

      List<Document> updatedDocuments = List.from(widget.property.documents);

      if (_isEditing) {
        // Update existing document
        final updatedDocument = Document(
          name: _nameController.text.trim(),
          type: _selectedType,
          url: documentUrl,
          uploadDate: widget.existingDocument!.uploadDate,
        );

        final index = updatedDocuments.indexWhere(
          (doc) =>
              doc.name == widget.existingDocument!.name &&
              doc.uploadDate == widget.existingDocument!.uploadDate,
        );

        if (index != -1) {
          updatedDocuments[index] = updatedDocument;
        }
      } else {
        // Create new document
        final newDocument = Document(
          name: _nameController.text.trim(),
          type: _selectedType,
          url: documentUrl,
          uploadDate: DateTime.now(),
        );
        updatedDocuments.add(newDocument);
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
        arrears: widget.property.arrears,
        contacts: widget.property.contacts,
        documents: updatedDocuments,
        judgments: widget.property.judgments,
        notes: widget.property.notes,
        trustees: widget.property.trustees,
        auctions: widget.property.auctions,
        vesting: widget.property.vesting,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
      );

      await context.read<PropertyProvider>().updateProperty(updatedProperty);

      // Debug: Let's verify what we're trying to save
      print('=== DOCUMENT SAVE DEBUG ===');
      print('Property ID: ${updatedProperty.id}');
      print('Total documents: ${updatedProperty.documents.length}');
      updatedProperty.documents.forEach((doc) {
        print('Document: ${doc.name} (${doc.type}) - URL: ${doc.url}');
      });
      print('=== END DEBUG ===');

      if (mounted) {
        // Force refresh the property provider to show new documents
        await context.read<PropertyProvider>().loadProperties();

        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Document ${_isEditing ? 'updated' : 'added'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadStatus = 'Error: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${_isEditing ? 'updating' : 'adding'} document: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _uploadWithRetry({
    required PlatformFile file,
    required String propertyId,
    required String documentType,
    int maxRetries = 2, // Reduce retries since each attempt takes longer
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (mounted) {
          setState(() {
            _uploadStatus =
                'Upload attempt $attempt of $maxRetries... (File: ${(file.size / 1024 / 1024).toStringAsFixed(1)}MB)';
          });
        }

        final url = await DocumentService.uploadDocument(
          file: file,
          propertyId: propertyId,
          documentType: documentType,
        );

        if (url != null) {
          return url;
        }
      } catch (e) {
        print('Upload attempt $attempt failed: $e');

        if (mounted) {
          setState(() {
            _uploadStatus =
                'Attempt $attempt failed: ${e.toString().split(':').last.trim()}';
          });
        }

        if (attempt == maxRetries) {
          rethrow;
        }

        // Shorter delay between retries
        const delay = Duration(seconds: 3);
        if (mounted) {
          setState(() {
            _uploadStatus = 'Waiting 3 seconds before retry ${attempt + 1}...';
          });
        }
        await Future.delayed(delay);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Document' : 'Add Document'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed:
              () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: _isLoading ? null : _saveDocument,
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
                    : Text(
                      _isEditing ? 'Update' : 'Save',
                      style: const TextStyle(color: Colors.white),
                    ),
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
                labelText: 'Document Name *',
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) =>
                      Validators.validateRequired(value, 'a document name'),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Document Type *',
                border: OutlineInputBorder(),
              ),
              items:
                  _documentTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // File Upload Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (_selectedFile != null) ...[
                    Icon(Icons.check_circle, size: 48, color: Colors.green),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFile!.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_isEditing &&
                      widget.existingDocument?.url != null) ...[
                    Icon(Icons.description, size: 48, color: Colors.blue[600]),
                    const SizedBox(height: 8),
                    Text(
                      'Current file uploaded',
                      style: TextStyle(fontSize: 16, color: Colors.blue[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select new file to replace',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Icon(Icons.cloud_upload, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      'Select Document File',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, DOC, DOCX, JPG, PNG, TXT',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.file_upload),
                    label: Text(
                      _selectedFile != null ? 'Change File' : 'Select File',
                    ),
                  ),

                  // Upload Status Display
                  if (_uploadStatus.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _uploadStatus.contains('Error')
                                ? Colors.red[50]
                                : _uploadStatus.contains('successfully')
                                ? Colors.green[50]
                                : Colors.blue[50],
                        border: Border.all(
                          color:
                              _uploadStatus.contains('Error')
                                  ? Colors.red[300]!
                                  : _uploadStatus.contains('successfully')
                                  ? Colors.green[300]!
                                  : Colors.blue[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          if (_isLoading && !_uploadStatus.contains('Error'))
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue[700],
                              ),
                            ),
                          if (_isLoading && !_uploadStatus.contains('Error'))
                            const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _uploadStatus,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    _uploadStatus.contains('Error')
                                        ? Colors.red[700]
                                        : _uploadStatus.contains('successfully')
                                        ? Colors.green[700]
                                        : Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Troubleshooting Section
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Upload Tips & Troubleshooting',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Keep file sizes under 5MB for best results\n'
                    '• Ensure stable internet connection\n'
                    '• Try again if upload fails - timeout reduced to 1 minute\n'
                    '• Supported formats: PDF, DOC, DOCX, JPG, PNG, TXT\n'
                    '• Try uploading a smaller test file first',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoading ? null : _testFirebaseConnection,
                          icon: const Icon(Icons.network_check),
                          label: const Text('Test Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _runQuickStorageTest,
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Debug Storage'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _debugFirestoreDocuments,
                    icon: const Icon(Icons.storage),
                    label: const Text('Debug Firestore Documents'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
