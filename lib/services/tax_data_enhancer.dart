// lib/services/tax_data_enhancer.dart
import '../models/property_file.dart';
import 'property_matcher_service.dart';

class TaxDataEnhancer {
  /// Parse tax data and find matching existing properties to enhance
  static List<PropertyEnhancement> parseAndMatch(
    String taxDataText,
    List<PropertyFile> existingProperties,
  ) {
    final enhancements = <PropertyEnhancement>[];

    // Split by property blocks (each property starts with PROPERTY ID:)
    final propertyBlocks = taxDataText
        .split(RegExp(r'PROPERTY ID:'))
        .where((block) => block.trim().isNotEmpty);

    for (final block in propertyBlocks) {
      try {
        final taxData = _parsePropertyBlock('PROPERTY ID:$block');
        if (taxData == null) continue;

        // Find matching existing property
        final matchingProperty = PropertyMatcherService.findMatchingProperty(
          existingProperties,
          taxData.address,
        );

        if (matchingProperty != null) {
          // Create enhancement for existing property
          final enhancement = PropertyEnhancement(
            existingProperty: matchingProperty,
            taxData: taxData,
            matchConfidence: PropertyMatcherService.getAddressSimilarity(
              matchingProperty.address,
              taxData.address,
            ),
          );
          enhancements.add(enhancement);
        } else {
          // No match found - create unmatched enhancement
          final enhancement = PropertyEnhancement(
            existingProperty: null,
            taxData: taxData,
            matchConfidence: 0.0,
          );
          enhancements.add(enhancement);
        }
      } catch (e) {
        print('Error parsing property block: $e');
        continue;
      }
    }

    return enhancements;
  }

  /// Apply tax data enhancement to existing property
  static PropertyFile enhanceProperty(PropertyEnhancement enhancement) {
    if (enhancement.existingProperty == null) {
      throw Exception('Cannot enhance property: no existing property found');
    }

    final existing = enhancement.existingProperty!;
    final taxData = enhancement.taxData;

    // Create tax note with all the information
    final taxNote = Note(
      subject:
          'Multnomah County Tax Data (Added ${DateTime.now().toString().substring(0, 10)})',
      content: _buildTaxNoteContent(taxData),
      createdAt: DateTime.now(),
    );

    // Create document if Google Drive link exists
    final updatedDocuments = List<Document>.from(existing.documents);
    if (taxData.googleDriveLink != null &&
        taxData.googleDriveLink!.trim().isNotEmpty &&
        !taxData.googleDriveLink!.contains('[You\'ll need to get')) {
      updatedDocuments.add(Document(
        name: 'Multnomah County Tax Statement - ${taxData.propertyId}.pdf',
        type: 'Tax Document',
        url: taxData.googleDriveLink!.trim(),
        uploadDate: DateTime.now(),
      ));
    }

    // Update the existing property with tax information
    return PropertyFile(
      id: existing.id,
      fileNumber: existing.fileNumber, // Keep existing file number
      address: existing.address, // Keep existing address
      city: existing.city,
      state: existing.state,
      zipCode: existing.zipCode,
      loanAmount: existing.loanAmount, // Preserve loan info
      amountOwed: existing.amountOwed, // Preserve amount owed
      arrears: existing.arrears, // Preserve arrears
      zillowUrl: existing.zillowUrl,
      county: existing.county ?? 'Multnomah',
      taxAccountNumber: taxData.propertyId, // ADD tax account number
      notes: [...existing.notes, taxNote], // ADD tax note
      documents: updatedDocuments, // ADD tax document
      contacts: existing.contacts,
      judgments: existing.judgments,
      trustees: existing.trustees,
      auctions: existing.auctions,
      vesting: existing.vesting,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Parse a single property block into TaxPropertyData
  static TaxPropertyData? _parsePropertyBlock(String block) {
    try {
      final propertyId = _extractField(block, r'PROPERTY ID:\s*(\S+)');
      final address = _extractField(block, r'ADDRESS:\s*(.+?)(?=\s+OWNER:|$)',
          multiline: true);
      final owner = _extractField(block, r'OWNER:\s*(.+?)(?=\s+TAX ACCOUNT:|$)',
          multiline: true);
      final taxAccount = _extractField(block, r'TAX ACCOUNT:\s*(\S+)');
      final alternateAccount =
          _extractField(block, r'ALTERNATE ACCOUNT:\s*(\S+)');
      final assessedValueStr =
          _extractField(block, r'2025 ASSESSED VALUE:\s*\$([0-9,]+)');
      final totalDueStr =
          _extractField(block, r'TOTAL TAXES DUE:\s*\$([0-9,]+\.?\d*)');
      final legalDescription = _extractField(block,
          r'LEGAL DESCRIPTION:\s*(.+?)(?=\s+GOOGLE DRIVE LINK:|SOURCE URL:|$)',
          multiline: true);
      final googleDriveLink = _extractField(
          block, r'GOOGLE DRIVE LINK:\s*(.+?)(?=\s+SOURCE URL:|$)',
          multiline: true);
      final sourceUrl = _extractField(
          block, r'SOURCE URL:\s*(.+?)(?=\s+PROPERTY TYPE:|$)',
          multiline: true);
      final propertyType = _extractField(
          block, r'PROPERTY TYPE:\s*(.+?)(?=\s+LAND SIZE:|$)',
          multiline: true);
      final landSize =
          _extractField(block, r'LAND SIZE:\s*(.+?)(?=\s*$)', multiline: true);

      if (propertyId == null || address == null) {
        return null;
      }

      return TaxPropertyData(
        propertyId: propertyId,
        address: address,
        owner: owner,
        taxAccount: taxAccount,
        alternateAccount: alternateAccount,
        assessedValue: _parseMoneyAmount(assessedValueStr),
        totalDue: _parseMoneyAmount(totalDueStr),
        legalDescription: legalDescription,
        googleDriveLink: googleDriveLink,
        sourceUrl: sourceUrl,
        propertyType: propertyType,
        landSize: landSize,
      );
    } catch (e) {
      print('Error parsing property block: $e');
      return null;
    }
  }

  /// Extract field value using regex
  static String? _extractField(String text, String pattern,
      {bool multiline = false}) {
    final regex = RegExp(pattern, multiLine: multiline, dotAll: true);
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim();
  }

  /// Parse money amount from string
  static double? _parseMoneyAmount(String? amountStr) {
    if (amountStr == null || amountStr.isEmpty) return null;
    final cleanAmount = amountStr.replaceAll(',', '');
    return double.tryParse(cleanAmount);
  }

  /// Build comprehensive tax note content
  static String _buildTaxNoteContent(TaxPropertyData taxData) {
    final buffer = StringBuffer();

    buffer.writeln('MULTNOMAH COUNTY TAX INFORMATION');
    buffer.writeln('Added: ${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('');

    buffer.writeln('PROPERTY DETAILS:');
    buffer.writeln('Property ID: ${taxData.propertyId}');
    if (taxData.owner != null) buffer.writeln('Owner: ${taxData.owner}');
    if (taxData.taxAccount != null)
      buffer.writeln('Tax Account: ${taxData.taxAccount}');
    if (taxData.alternateAccount != null)
      buffer.writeln('Alternate Account: ${taxData.alternateAccount}');
    if (taxData.propertyType != null)
      buffer.writeln('Property Type: ${taxData.propertyType}');
    if (taxData.landSize != null)
      buffer.writeln('Land Size: ${taxData.landSize}');
    if (taxData.legalDescription != null)
      buffer.writeln('Legal Description: ${taxData.legalDescription}');
    buffer.writeln('');

    buffer.writeln('FINANCIAL INFORMATION:');
    if (taxData.assessedValue != null) {
      buffer.writeln(
          '2025 Assessed Value: \$${taxData.assessedValue!.toStringAsFixed(0)}');
    }
    if (taxData.totalDue != null) {
      buffer.writeln(
          'Total Taxes Due: \$${taxData.totalDue!.toStringAsFixed(2)}');
    }
    buffer.writeln('');

    if (taxData.sourceUrl != null) {
      buffer.writeln('SOURCE:');
      buffer.writeln(taxData.sourceUrl);
    }

    return buffer.toString();
  }
}

/// Data class for parsed tax information
class TaxPropertyData {
  final String propertyId;
  final String address;
  final String? owner;
  final String? taxAccount;
  final String? alternateAccount;
  final double? assessedValue;
  final double? totalDue;
  final String? legalDescription;
  final String? googleDriveLink;
  final String? sourceUrl;
  final String? propertyType;
  final String? landSize;

  TaxPropertyData({
    required this.propertyId,
    required this.address,
    this.owner,
    this.taxAccount,
    this.alternateAccount,
    this.assessedValue,
    this.totalDue,
    this.legalDescription,
    this.googleDriveLink,
    this.sourceUrl,
    this.propertyType,
    this.landSize,
  });
}

/// Enhancement result for a property
class PropertyEnhancement {
  final PropertyFile? existingProperty;
  final TaxPropertyData taxData;
  final double matchConfidence;

  PropertyEnhancement({
    required this.existingProperty,
    required this.taxData,
    required this.matchConfidence,
  });

  bool get hasMatch => existingProperty != null;
  String get statusText => hasMatch ? 'Match Found' : 'No Match';
}
