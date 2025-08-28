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
      List<Note> updatedNotes = List.from(widget.property.notes);

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
        documents: widget.property.documents,
        judgments: widget.property.judgments,
        notes: updatedNotes,
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
        actions: [
          TextButton(
            onPressed: _cancelNote,
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: _isLoading ? null : _saveNote,
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
