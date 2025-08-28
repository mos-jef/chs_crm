import 'package:flutter/material.dart';
import '../models/property_file.dart';
import '../screens/add_trustee_screen.dart';

class TrusteesTab extends StatelessWidget {
  final PropertyFile property;

  const TrusteesTab({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          property.trustees.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No trustees added',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add trustee information for this property',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: property.trustees.length,
                itemBuilder: (context, index) {
                  final trustee = property.trustees[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        trustee.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Institution: ${trustee.institution}'),
                          if (trustee.phoneNumber != null)
                            Text('Phone: ${trustee.phoneNumber}'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => AddTrusteeScreen(
                                  property: property,
                                  existingTrustee: trustee,
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
              builder: (context) => AddTrusteeScreen(property: property),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
