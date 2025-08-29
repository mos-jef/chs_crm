import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/property_file.dart';
import '../screens/add_note_screen.dart';

class NotesTab extends StatelessWidget {
  final PropertyFile property;

  const NotesTab({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          property.notes.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No notes added',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add notes to keep track of important information and updates',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: property.notes.length,
                itemBuilder: (context, index) {
                  final note = property.notes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(
                          Icons.note,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        note.subject,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateTime(note.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note.preview,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (note.updatedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Updated: ${_formatDateTime(note.updatedAt!)}',
                              style: TextStyle(
                                color: Colors.orange[600],
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => AddNoteScreen(
                                  property: property,
                                  existingNote: note,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddNoteScreen(property: property),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
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

    final dateStr =
        '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';

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
