import 'package:flutter/material.dart';
import '../models/property_file.dart';
import '../screens/add_contact_screen.dart';

class ContactsTab extends StatelessWidget {
  final PropertyFile property;

  const ContactsTab({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          property.contacts.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.contacts, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No contacts added',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add contacts to keep track of borrowers, attorneys, and other parties',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: property.contacts.length,
                itemBuilder: (context, index) {
                  final contact = property.contacts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          contact.name.isNotEmpty
                              ? contact.name.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact.role),
                          if (contact.phone != null)
                            Text('Phone: ${contact.phone}'),
                          if (contact.email != null)
                            Text('Email: ${contact.email}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => AddContactScreen(property: property),
            ),
          );
          // You might want to refresh the parent screen here
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
