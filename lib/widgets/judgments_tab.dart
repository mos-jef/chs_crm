import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/property_file.dart';
import '../screens/add_judgment_screen.dart';

class JudgmentsTab extends StatelessWidget {
  final PropertyFile property;

  const JudgmentsTab({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          property.judgments.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gavel, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No judgments recorded',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add judgment information for legal proceedings',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: property.judgments.length,
                itemBuilder: (context, index) {
                  final judgment = property.judgments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.gavel,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Case No: ${judgment.caseNumber}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(judgment.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  judgment.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildJudgmentRow(
                            'County',
                            '${judgment.county}, ${judgment.state}',
                          ),
                          _buildJudgmentRow('Debtor', judgment.debtor),
                          _buildJudgmentRow('Grantee', judgment.grantee),
                          if (judgment.dateOpened != null)
                            _buildJudgmentRow(
                              'Date Opened',
                              DateFormat(
                                'MMM d, yyyy',
                              ).format(judgment.dateOpened!),
                            ),
                          if (judgment.judgmentDate != null)
                            _buildJudgmentRow(
                              'Judgment Date',
                              DateFormat(
                                'MMM d, yyyy',
                              ).format(judgment.judgmentDate!),
                            ),
                          if (judgment.amount != null)
                            _buildJudgmentRow(
                              'Amount',
                              '\$${NumberFormat('#,##0.00').format(judgment.amount!)}',
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddJudgmentScreen(property: property),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildJudgmentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'satisfied':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
