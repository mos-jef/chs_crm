import 'package:chs_crm/providers/theme_provider.dart';
import 'package:chs_crm/utils/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/property_file.dart';
import 'package:web/web.dart' as web;

class OverviewTab extends StatelessWidget {
  final PropertyFile property;

  const OverviewTab({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPropertyInfoSection(),
        const SizedBox(height: 16),
        _buildZillowSection(context), 
        const SizedBox(height: 16),
        _buildFinancialInfoSection(),
        const SizedBox(height: 16),
        _buildContactsSection(),
        const SizedBox(height: 16),
        _buildDocumentsSection(context),
        const SizedBox(height: 16),
        _buildJudgmentsSection(),
        const SizedBox(height: 16),
        _buildNotesSection(),
        const SizedBox(height: 16),
        _buildTrusteesSection(),
        const SizedBox(height: 16),
        _buildAuctionsSection(),
        const SizedBox(height: 16),
        _buildVestingSection(),
        const SizedBox(height: 16),
        _buildRecordInfoSection(),
      ],
    );
  }

  Widget _buildPropertyInfoSection() {
    return _buildInfoCard('Property Information', Icons.home, [
      _buildInfoRow('File Number', property.fileNumber),
      _buildInfoRow('Address', property.address),
      _buildInfoRow('City', property.city),
      _buildInfoRow('State', property.state),
      _buildInfoRow('ZIP Code', property.zipCode),
      _buildInfoRow('County', _getCountyFromNotes()),
    ]);
  }

  Widget _buildFinancialInfoSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return _buildInfoCard('Financial Information', Icons.attach_money, [
          _buildInfoRow(
            'Loan Amount',
            property.loanAmount != null
                ? '\$${NumberFormat('#,##0.00').format(property.loanAmount!)}'
                : 'Not specified',
            textColor: AppThemes.getLoanAmountColor(themeProvider.currentTheme),
          ),
          _buildInfoRow(
            'Amount Owed',
            property.amountOwed != null
                ? '\$${NumberFormat('#,##0.00').format(property.amountOwed!)}'
                : 'Not specified',
            textColor: AppThemes.getAmountOwedColor(themeProvider.currentTheme),
          ),
          _buildInfoRow(
            'Arrears',
            property.arrears != null
                ? '\$${NumberFormat('#,##0.00').format(property.arrears!)}'
                : 'Not specified',
            textColor: AppThemes.getArrearsColor(themeProvider.currentTheme),
          ),
          if (property.loanAmount != null ||
              property.amountOwed != null ||
              property.arrears != null)
            _buildInfoRow(
              'Total Owed',
              '\$${NumberFormat('#,##0.00').format(property.totalOwed)}',
              highlight: true,
              textColor: AppThemes.getTotalOwedColor(
                themeProvider.currentTheme,
              ),
            ),
        ]);
      },
    );
  }

  Widget _buildContactsSection() {
    return _buildInfoCard(
      'Contacts',
      Icons.contacts,
      property.contacts.isEmpty
          ? [const Text('No contacts added')]
          : property.contacts
              .map(
                (contact) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(contact.role),
                        if (contact.phone != null)
                          Text('Phone: ${contact.phone}'),
                        if (contact.email != null)
                          Text('Email: ${contact.email}'),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    return _buildInfoCard(
      'Documents',
      Icons.folder,
      property.documents.isEmpty
          ? [const Text('No documents uploaded')]
          : property.documents
              .map(
                (document) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () {
                      if (document.url != null) {
                        web.window.open(document.url!, '_blank');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document file not available'),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(
                            _getDocumentIcon(document.type),
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  document.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(document.type),
                                Text(
                                  'Added: ${DateFormat('MMM d, yyyy').format(document.uploadDate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildZillowSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return _buildInfoCard(
          'Zillow Property Link',
          Icons.link,
          property.zillowUrl == null || property.zillowUrl!.isEmpty
              ? [const Text('No Zillow URL added')]
              : [
                InkWell(
                  onTap: () {
                    web.window.open(property.zillowUrl!, '_blank');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      property.zillowUrl!,
                      style: TextStyle(
                        color: AppThemes.getTotalOwedColor(
                          themeProvider.currentTheme,
                        ),
                        fontWeight: FontWeight.bold, // Bold as requested
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
        );
      },
    );
  }

  Widget _buildJudgmentsSection() {
    return _buildInfoCard(
      'Judgments',
      Icons.gavel,
      property.judgments.isEmpty
          ? [const Text('No judgments recorded')]
          : property.judgments
              .map(
                (judgment) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Case: ${judgment.caseNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Status: ${judgment.status}'),
                        Text('County: ${judgment.county}, ${judgment.state}'),
                        Text('Debtor: ${judgment.debtor}'),
                        Text('Grantee: ${judgment.grantee}'),
                        if (judgment.amount != null)
                          Text(
                            'Amount: \$${NumberFormat('#,##0.00').format(judgment.amount!)}',
                          ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildNotesSection() {
    return _buildInfoCard(
      'Notes',
      Icons.note,
      property.notes.isEmpty
          ? [const Text('No notes added')]
          : property.notes
              .take(3)
              .map(
                (note) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat(
                            'MMM d, yyyy h:mm a',
                          ).format(note.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(note.preview),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildTrusteesSection() {
    return _buildInfoCard(
      'Trustees',
      Icons.account_balance_wallet,
      property.trustees.isEmpty
          ? [const Text('No trustees added')]
          : property.trustees
              .map(
                (trustee) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trustee.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Institution: ${trustee.institution}'),
                        if (trustee.phoneNumber != null)
                          Text('Phone: ${trustee.phoneNumber}'),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildAuctionsSection() {
    return _buildInfoCard(
      'Auctions',
      Icons.event,
      property.auctions.isEmpty
          ? [const Text('No auctions scheduled')]
          : property.auctions
              .map(
                (auction) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${auction.formattedDate} at ${auction.formattedTime}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Place: ${auction.place}'),
                        if (auction.openingBid != null)
                          Text(
                            'Opening Bid: \$${NumberFormat('#,##0.00').format(auction.openingBid!)}',
                          ),
                        if (auction.auctionCompleted &&
                            auction.salesAmount != null)
                          Text(
                            'Sales Amount: \$${NumberFormat('#,##0.00').format(auction.salesAmount!)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                auction.auctionCompleted
                                    ? Colors.green
                                    : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            auction.auctionCompleted
                                ? 'Completed'
                                : 'Scheduled',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildVestingSection() {
    return _buildInfoCard(
      'Vesting Information',
      Icons.account_balance,
      property.vesting == null || property.vesting!.owners.isEmpty
          ? [const Text('No vesting information')]
          : [
            Text('Type: ${property.vesting!.vestingType}'),
            const SizedBox(height: 8),
            ...property.vesting!.owners.map(
              (owner) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(owner.name),
                    Text('${owner.percentage.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
          ],
    );
  }

  Widget _buildRecordInfoSection() {
    return _buildInfoCard('Record Information', Icons.info, [
      _buildInfoRow('Created', _formatDateTime(property.createdAt)),
      _buildInfoRow('Last Updated', _formatDateTime(property.updatedAt)),
    ]);
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool highlight = false,
    Color? textColor,
  }) {
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
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: textColor ?? (highlight ? Colors.green[700] : null),
              ),
            ),
          ),
        ],
      ),
    );
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
      case 'judgment': // ADD THESE
        return Icons.gavel;
      case 'foreclosure':
        return Icons.warning;
      case 'notice of default':
        return Icons.error_outline;
      case 'affidavit of mailing':
        return Icons.mail_outline;
      case 'deed of trust':
        return Icons.account_balance_wallet;
      case 'assignment deed of trust':
        return Icons.assignment;
      case 'assignment':
        return Icons.assignment_turned_in;
      case 'successor trustee':
        return Icons.person_outline;
      case 'trustees sale':
        return Icons.storefront;
      case 'sheriffs deed':
        return Icons.local_police;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Helper method for pulling in county from "notes" and displaying in property info on overview tab
  String _getCountyFromNotes() {
    final countyNote = property.notes.firstWhere(
      (note) => note.subject == 'County',
      orElse: () => Note(
          subject: '', content: 'Not available', createdAt: DateTime.now()),
    );
    return countyNote.content.replaceAll(' County, Oregon', '');
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
