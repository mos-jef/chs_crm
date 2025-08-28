import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/property_file.dart';
import '../screens/add_document_screen.dart';
import '../providers/property_provider.dart';
import '../services/document_service.dart';
import 'dart:html' as html show window;

class DocumentsTab extends StatelessWidget {
  final PropertyFile property;

  const DocumentsTab({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          property.documents.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No documents uploaded',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload deeds, mortgages, and other important documents',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: property.documents.length,
                itemBuilder: (context, index) {
                  final document = property.documents[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        _getDocumentIcon(document.type),
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                      title: Text(
                        document.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(document.type),
                          Text(
                            'Added: ${DateFormat('MMM d, yyyy').format(document.uploadDate)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      onTap: () {
                        if (document.url != null) {
                          html.window.open(document.url!, '_blank');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Document file not available'),
                            ),
                          );
                        }
                      },
                      trailing: PopupMenuButton(
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility),
                                    SizedBox(width: 8),
                                    Text('View'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        onSelected: (value) async {
                          if (value == 'view') {
                            if (document.url != null) {
                              html.window.open(document.url!, '_blank');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Document file not available'),
                                ),
                              );
                            }
                          } else if (value == 'edit') {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => AddDocumentScreen(
                                      property: property,
                                      existingDocument: document,
                                    ),
                              ),
                            );
                          } else if (value == 'delete') {
                            await _showDeleteDialog(context, document, index);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddDocumentScreen(property: property),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    Document document,
    int index,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this document?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Type: ${document.type}'),
                    Text(
                      'Added: ${DateFormat('MMM d, yyyy').format(document.uploadDate)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This action cannot be undone. The file will be permanently deleted from both the database and storage.',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await _deleteDocument(context, document, index);
    }
  }

  Future<void> _deleteDocument(
    BuildContext context,
    Document document,
    int index,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting document...'),
              ],
            ),
          );
        },
      );

      // Delete from Firebase Storage first
      bool storageDeleted = false;
      if (document.url != null) {
        try {
          await DocumentService.deleteDocument(document.url!);
          storageDeleted = true;
          print('Document deleted from storage: ${document.url}');
        } catch (e) {
          print('Warning: Could not delete from storage: $e');
          // Continue with database deletion even if storage fails
          storageDeleted = false;
        }
      }

      // Remove from documents list
      List<Document> updatedDocuments = List.from(property.documents);
      updatedDocuments.removeAt(index);

      // Create updated property
      final updatedProperty = PropertyFile(
        id: property.id,
        fileNumber: property.fileNumber,
        address: property.address,
        city: property.city,
        state: property.state,
        zipCode: property.zipCode,
        loanAmount: property.loanAmount,
        amountOwed: property.amountOwed,
        arrears: property.arrears,
        contacts: property.contacts,
        documents: updatedDocuments,
        judgments: property.judgments,
        notes: property.notes,
        trustees: property.trustees,
        auctions: property.auctions,
        vesting: property.vesting,
        createdAt: property.createdAt,
        updatedAt: DateTime.now(),
      );

      // Update Firestore
      await context.read<PropertyProvider>().updateProperty(updatedProperty);

      // Force refresh to ensure UI updates
      await context.read<PropertyProvider>().loadProperties();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              storageDeleted
                  ? 'Document deleted successfully'
                  : 'Document removed from database (storage file may still exist)',
            ),
            backgroundColor: storageDeleted ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error deleting document: $e');
    }
  }

  IconData _getDocumentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'deed':
        return Icons.description;
      case 'mortgage':
        return Icons.account_balance;
      case 'title insurance':
        return Icons.security;
      case 'appraisal':
        return Icons.assessment;
      case 'survey':
        return Icons.map;
      case 'hoa documents':
        return Icons.home_work;
      case 'property tax records':
        return Icons.receipt_long;
      case 'insurance policy':
        return Icons.shield;
      case 'lien documents':
        return Icons.gavel;
      case 'court documents':
        return Icons.balance;
      default:
        return Icons.insert_drive_file;
    }
  }
}
