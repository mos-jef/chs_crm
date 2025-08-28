import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/property_file.dart';

class PropertyInfoTab extends StatelessWidget {
  final PropertyFile property;

  const PropertyInfoTab({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('Property Information', [
          _buildInfoRow('File Number', property.fileNumber),
          _buildInfoRow('Address', property.address),
          _buildInfoRow('City', property.city),
          _buildInfoRow('State', property.state),
          _buildInfoRow('ZIP Code', property.zipCode),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Financial Information', [
          _buildInfoRow(
            'Loan Amount',
            property.loanAmount != null
                ? '\$${NumberFormat('#,##0.00').format(property.loanAmount!)}'
                : 'Not specified',
          ),
          _buildInfoRow(
            'Amount Owed',
            property.amountOwed != null
                ? '\$${NumberFormat('#,##0.00').format(property.amountOwed!)}'
                : 'Not specified',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Record Information', [
          _buildInfoRow(
            'Created',
            DateFormat('MMM d, yyyy h:mm a').format(property.createdAt),
          ),
          _buildInfoRow(
            'Last Updated',
            DateFormat('MMM d, yyyy h:mm a').format(property.updatedAt),
          ),
        ]),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
