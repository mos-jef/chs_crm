// lib/widgets/overview_tab.dart - UPDATED with Owner & Contact Info
import 'package:chs_crm/providers/theme_provider.dart';
import 'package:chs_crm/utils/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        _buildOwnerContactSection(), // NEW SECTION
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
      _buildSelectableInfoRow('File Number', property.fileNumber),
      _buildSelectableInfoRow('Address', property.address),
      _buildSelectableInfoRow('City', property.city),
      _buildSelectableInfoRow('State', property.state),
      _buildSelectableInfoRow('ZIP Code', property.zipCode),
      _buildSelectableInfoRow('County', _getCountyFromNotes()),
    ]);
  }

  // NEW: Owner & Contact Information Section
  Widget _buildOwnerContactSection() {
    final ownerName = _getOwnerName();
    final ownerPhone = _getOwnerPhone();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Owner Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSelectableInfoRow(
              'Owner',
              ownerName,
              textColor: ownerName == 'TBD' ? Colors.grey : null,
            ),
            _buildSelectableInfoRow(
              'Contact',
              ownerPhone,
              textColor: ownerPhone == 'TBD' ? Colors.grey : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZillowSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Zillow Link',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (property.zillowUrl != null && property.zillowUrl!.isNotEmpty)
              InkWell(
                onTap: () {
                  web.window.open(property.zillowUrl!, '_blank');
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new,
                          color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          property.zillowUrl!,
                          style: TextStyle(
                            color: Colors.blue[700],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SelectableText(
                'No Zillow URL available',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfoSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return _buildInfoCard('Financial Information', Icons.attach_money, [
          _buildSelectableInfoRow(
            'Loan Amount',
            property.loanAmount != null
                ? '\$${NumberFormat('#,##0.00').format(property.loanAmount!)}'
                : 'Not specified',
            textColor: AppThemes.getLoanAmountColor(themeProvider.currentTheme),
          ),
          _buildSelectableInfoRow(
            'Amount Owed',
            property.amountOwed != null
                ? '\$${NumberFormat('#,##0.00').format(property.amountOwed!)}'
                : 'Not specified',
            textColor: AppThemes.getAmountOwedColor(themeProvider.currentTheme),
          ),
          _buildSelectableInfoRow(
            'Arrears',
            property.arrears != null
                ? '\$${NumberFormat('#,##0.00').format(property.arrears!)}'
                : 'Not specified',
            textColor: AppThemes.getArrearsColor(themeProvider.currentTheme),
          ),
          _buildSelectableInfoRow(
            'Estimated Sale Value',
            property.estimatedSaleValue != null
                ? '\$${NumberFormat('#,##0.00').format(property.estimatedSaleValue!)}'
                : 'Not specified',
            textColor: AppThemes.getAmountOwedColor(themeProvider.currentTheme),
          ),
          if (property.estimatedProfitMargin != null)
            if (property.estimatedProfitMargin != null)
              _buildSelectableInfoRow(
                'Estimated Profit Margin',
                '\$${NumberFormat('#,##0.00').format(property.estimatedProfitMargin!)}',
                highlight: true,
                textColor: AppThemes.getLoanAmountColor(themeProvider.currentTheme),
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
          ? [const SelectableText('No contacts added')]
          : property.contacts
              .map(
                (contact) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          contact.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SelectableText(contact.role),
                        if (contact.phone != null)
                          SelectableText('Phone: ${contact.phone}'),
                        if (contact.email != null)
                          SelectableText('Email: ${contact.email}'),
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
          ? [const SelectableText('No documents uploaded')]
          : property.documents
              .take(3)
              .map(
                (doc) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(_getDocumentIcon(doc.type)),
                    title: SelectableText(doc.name),
                    subtitle: SelectableText(
                      '${doc.type} - ${DateFormat('MMM d, yyyy').format(doc.uploadDate)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new, size: 20),

                      onPressed: () {
                        if (property.zillowUrl != null) {
                          web.window.open(property.zillowUrl!, '_blank');
                        }
                      },

                    ),
                  ),
                ),
              )
              .toList()
        ..add(
          property.documents.length > 3
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SelectableText(
                    '... and ${property.documents.length - 3} more documents',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
    );
  }

  Widget _buildJudgmentsSection() {
    return _buildInfoCard(
      'Judgments',
      Icons.gavel,
      property.judgments.isEmpty
          ? [const SelectableText('No judgments recorded')]
          : property.judgments
              .map(
                (judgment) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          'Case #${judgment.caseNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SelectableText('Status: ${judgment.status}'),
                        if (judgment.amount != null)
                          SelectableText(
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
    final noteWidgets = property.notes.isEmpty
        ? [const SelectableText('No notes added')]
        : [
            ...property.notes.take(3).map(
                  (note) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            note.subject,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SelectableText(
                            note.content,
                            maxLines: 3,
                            style: const TextStyle(
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            if (property.notes.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText(
                  '... and ${property.notes.length - 3} more notes',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ];

    return _buildInfoCard('Notes', Icons.note, noteWidgets);
  }

  Widget _buildTrusteesSection() {
    return _buildInfoCard(
      'Trustees',
      Icons.account_balance_wallet,
      property.trustees.isEmpty
          ? [const SelectableText('No trustees assigned')]
          : property.trustees
              .map(
                (trustee) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          trustee.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
          ? [const SelectableText('No auctions scheduled')]
          : property.auctions
              .map(
                (auction) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          '${auction.formattedDate} at ${auction.formattedTime}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SelectableText('Place: ${auction.place}'),
                        if (auction.openingBid != null)
                          SelectableText(
                            'Opening Bid: \$${NumberFormat('#,##0.00').format(auction.openingBid!)}',
                          ),
                        if (auction.auctionCompleted &&
                            auction.salesAmount != null)
                          SelectableText(
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
                            color: auction.auctionCompleted
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
          ? [const SelectableText('No vesting information')]
          : [
              SelectableText('Type: ${property.vesting!.vestingType}'),
              const SizedBox(height: 8),
              ...property.vesting!.owners.map(
                (owner) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: SelectableText(owner.name)),
                      SelectableText('${owner.percentage.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),
            ],
    );
  }

  Widget _buildRecordInfoSection() {
    return _buildInfoCard('Record Information', Icons.info, [
      _buildSelectableInfoRow('Created', _formatDateTime(property.createdAt)),
      _buildSelectableInfoRow(
          'Last Updated', _formatDateTime(property.updatedAt)),
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

  Widget _buildSelectableInfoRow(
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
            child: SelectableText(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
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
      case 'judgment':
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

  String _getCountyFromNotes() {
    final countyNote = property.notes.firstWhere(
      (note) => note.subject == 'County',
      orElse: () => Note(
          subject: '', content: 'Not available', createdAt: DateTime.now()),
    );
    return countyNote.content.replaceAll(' County, Oregon', '');
  }

  // Helper: Get owner name from vesting info
  String _getOwnerName() {
    if (property.vesting != null && property.vesting!.owners.isNotEmpty) {
      // If multiple owners, join their names
      final ownerNames = property.vesting!.owners.map((o) => o.name).join(', ');
      return ownerNames;
    }
    return 'TBD';
  }

  // Helper: Get owner phone from contacts
  String _getOwnerPhone() {
    // Look for a contact with role "Owner" or "Defendant/Borrower"
    final ownerContact = property.contacts
        .where((c) =>
            c.role.toLowerCase().contains('owner') ||
            c.role.toLowerCase().contains('defendant') ||
            c.role.toLowerCase().contains('borrower'))
        .firstOrNull;

    if (ownerContact?.phone != null && ownerContact!.phone!.isNotEmpty) {
      return ownerContact.phone!;
    }

    // Fallback: check if any contact has a phone number
    final anyContactWithPhone = property.contacts
        .where((c) => c.phone != null && c.phone!.isNotEmpty)
        .firstOrNull;

    return anyContactWithPhone?.phone ?? 'TBD';
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

    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'pm' : 'am';
    final timeStr = '$hour:$minute$period';

    return '$dateStr $timeStr';
  }
}
