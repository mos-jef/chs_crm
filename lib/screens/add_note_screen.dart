import 'package:chs_crm/widgets/custom_beam_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../models/property_file.dart';
import '../utils/validators.dart';

class AddNoteScreen extends StatefulWidget {
  final PropertyFile property;
  final Note? existingNote;

  const AddNoteScreen({super.key, required this.property, this.existingNote});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _isEditing = true;
      _subjectController.text = widget.existingNote!.subject;
      _contentController.text = widget.existingNote!.content;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // CRITICAL FIX: Get the latest property data before updating
      final propertyProvider = context.read<PropertyProvider>();
      final latestProperty = propertyProvider.getPropertyById(widget.property.id,);

      if (latestProperty == null) {
        throw Exception('Property not found in cache');
      }

      print('=== BEFORE NOTE UPDATE ===');
      print('Latest property trustees: ${latestProperty.trustees.length}');
      print('Latest property notes: ${latestProperty.notes.length}');
      print('Latest property auctions: ${latestProperty.auctions.length}');

      List<Note> updatedNotes = List.from(
        latestProperty.notes,
      ); // Use LATEST property

      if (_isEditing) {
        // Update existing note
        final updatedNote = Note(
          id: widget.existingNote!.id,
          subject: _subjectController.text.trim(),
          content: _contentController.text.trim(),
          createdAt: widget.existingNote!.createdAt,
          updatedAt: DateTime.now(),
        );

        final index = updatedNotes.indexWhere(
          (note) => note.id == widget.existingNote!.id,
        );
        if (index != -1) {
          updatedNotes[index] = updatedNote;
        }
      } else {
        // Create new note
        final newNote = Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          subject: _subjectController.text.trim(),
          content: _contentController.text.trim(),
          createdAt: DateTime.now(),
        );
        updatedNotes.add(newNote);
      }

      // CRITICAL: Use ALL data from the LATEST property
      final updatedProperty = PropertyFile(
        id: latestProperty.id,
        fileNumber: latestProperty.fileNumber,
        address: latestProperty.address,
        city: latestProperty.city,
        state: latestProperty.state,
        zipCode: latestProperty.zipCode,
        loanAmount: latestProperty.loanAmount,
        amountOwed: latestProperty.amountOwed,
        arrears: latestProperty.arrears,
        zillowUrl: latestProperty.zillowUrl,
        contacts: latestProperty.contacts, // From latest
        documents: latestProperty.documents, // From latest
        judgments: latestProperty.judgments, // From latest
        notes: updatedNotes, // Updated notes
        trustees: latestProperty.trustees, // CRITICAL: From latest
        auctions: latestProperty.auctions, // From latest
        vesting: latestProperty.vesting, // From latest
        createdAt: latestProperty.createdAt,
        updatedAt: DateTime.now(),
      );

      print('=== AFTER NOTE UPDATE (before save) ===');
      print('Updated property trustees: ${updatedProperty.trustees.length}');
      print('Updated property notes: ${updatedProperty.notes.length}');

      await propertyProvider.updateProperty(updatedProperty);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Note ${_isEditing ? 'updated' : 'added'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${_isEditing ? 'updating' : 'adding'} note: $e',
            ),
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _cancelNote() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'Add Note'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed:
              () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date/Time Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _isEditing
                          ? 'Created: ${_formatDateTime(widget.existingNote!.createdAt)}'
                          : 'Date/Time: ${_formatDateTime(DateTime.now())}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subject Field
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                ),
                validator:
                    (value) => Validators.validateRequired(value, 'a subject'),
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Content Field
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Note Content *',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator:
                      (value) =>
                          Validators.validateRequired(value, 'note content'),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomBeamButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                    width: 100,
                    height: 60,
                    buttonStyle: CustomButtonStyle.secondary,
                  ),
                  CustomBeamButton(
                    text: _isEditing ? 'Update' : 'Save',
                    onPressed: _isLoading ? null : _saveNote,
                    isLoading: _isLoading,
                    width: 100,
                    height: 60,
                    buttonStyle: CustomButtonStyle.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    // Month abbreviations
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // Format date as "Aug 27, 2025"
    final dateStr =
        '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';

    // Format time as "5:04pm"
    final hour =
        dateTime.hour == 0
            ? 12
            : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'pm' : 'am';
    final timeStr = '$hour:$minute$period';

    return '$dateStr $timeStr';
  }
}
