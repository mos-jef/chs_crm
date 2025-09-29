// lib/services/tax_data_parser.dart
import '../models/property_file.dart';

class TaxDataParser {
  /// Parse the formatted tax data text and return PropertyFile objects
  static List<PropertyFile> parseTaxData(String taxDataText) {
    final properties = <PropertyFile>[];

    // Split by property blocks (each property starts with PROPERTY ID:)
    final propertyBlocks = taxDataText
        .split(RegExp(r'PROPERTY ID:'))
        .where((block) => block.trim().isNotEmpty);

    for (final block in propertyBlocks) {
      try {
        final property = _parsePropertyBlock('PROPERTY ID:$block');
        if (property != null) {
          properties.add(property);
        }
      } catch (e) {
        print('Error parsing property block: $e');
        continue;
      }
    }

    return properties;
  }

  /// Parse a single property block
  static PropertyFile? _parsePropertyBlock(String block) {
    try {
      // Extract each field using regex patterns
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
        print(
            'Missing required fields: propertyId=$propertyId, address=$address');
        return null;
      }

      // Parse address components
      final addressParts = _parseAddress(address);

      // Parse financial values
      final assessedValue = _parseMoneyAmount(assessedValueStr);
      final totalDue = _parseMoneyAmount(totalDueStr);

      // Generate file number from property ID
      final fileNumber = _generateFileNumber(propertyId);

      // Create comprehensive note with tax information
      final taxNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subject: 'Multnomah County Tax Data (Imported)',
        content: _buildTaxNoteContent(
          propertyId: propertyId,
          owner: owner,
          taxAccount: taxAccount,
          alternateAccount: alternateAccount,
          assessedValue: assessedValue,
          totalDue: totalDue,
          legalDescription: legalDescription,
          propertyType: propertyType,
          landSize: landSize,
          sourceUrl: sourceUrl,
        ),
        createdAt: DateTime.now(),
      );

      // Create document if Google Drive link exists
      final documents = <Document>[];
      if (googleDriveLink != null &&
          googleDriveLink.trim().isNotEmpty &&
          !googleDriveLink.contains('[You\'ll need to get')) {
        documents.add(Document(
          name: 'Multnomah County Tax Statement - $propertyId.pdf',
          type: 'Tax Document',
          url: googleDriveLink.trim(),
          uploadDate: DateTime.now(),
        ));
      }

      return PropertyFile(
        id: '', // Will be set by Firebase
        fileNumber: fileNumber,
        address: addressParts['street'] ?? address,
        city: addressParts['city'] ?? 'Portland',
        state: addressParts['state'] ?? 'OR',
        zipCode: addressParts['zip'] ?? '',
        loanAmount: null, // Tax documents don't contain loan info
        amountOwed: totalDue,
        arrears: null,
        zillowUrl: null, // Add this field
        county: 'Multnomah', // Add this field
        taxAccountNumber: propertyId, // Add this field if it exists
        notes: [taxNote],
        documents: documents,
        contacts: [],
        judgments: [],
        trustees: [],
        auctions: [],
        vesting: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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

    // Remove commas and parse
    final cleanAmount = amountStr.replaceAll(',', '');
    return double.tryParse(cleanAmount);
  }

  /// Parse address into components
  static Map<String, String> _parseAddress(String address) {
    final parts = <String, String>{};

    // Basic regex for "STREET, CITY, STATE ZIP"
    final addressRegex =
        RegExp(r'^(.+?),\s*([^,]+),\s*([A-Z]{2})\s+(\d{5}(?:-\d{4})?)$');
    final match = addressRegex.firstMatch(address.trim());

    if (match != null) {
      parts['street'] = match.group(1)?.trim() ?? '';
      parts['city'] = match.group(2)?.trim() ?? '';
      parts['state'] = match.group(3)?.trim() ?? '';
      parts['zip'] = match.group(4)?.trim() ?? '';
    } else {
      // Fallback parsing
      final addressParts = address.split(',').map((p) => p.trim()).toList();
      if (addressParts.length >= 2) {
        parts['street'] = addressParts[0];

        // Try to extract state and zip from last part
        final lastPart = addressParts.last;
        final stateZipMatch =
            RegExp(r'([A-Z]{2})\s+(\d{5}(?:-\d{4})?)$').firstMatch(lastPart);
        if (stateZipMatch != null) {
          parts['state'] = stateZipMatch.group(1) ?? '';
          parts['zip'] = stateZipMatch.group(2) ?? '';

          // City is everything before state/zip
          final cityPart =
              lastPart.replaceAll(stateZipMatch.group(0)!, '').trim();
          if (cityPart.isNotEmpty) {
            parts['city'] = cityPart;
          } else if (addressParts.length >= 3) {
            parts['city'] = addressParts[addressParts.length - 2];
          }
        }
      }
    }

    return parts;
  }

  /// Generate file number from property ID
  static String _generateFileNumber(String propertyId) {
    // Use timestamp + property ID for uniqueness
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return 'MC-$propertyId-$timestamp';
  }

  /// Build comprehensive tax note content
  static String _buildTaxNoteContent({
    required String propertyId,
    String? owner,
    String? taxAccount,
    String? alternateAccount,
    double? assessedValue,
    double? totalDue,
    String? legalDescription,
    String? propertyType,
    String? landSize,
    String? sourceUrl,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('MULTNOMAH COUNTY TAX INFORMATION');
    buffer.writeln('Imported: ${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('');

    buffer.writeln('PROPERTY DETAILS:');
    buffer.writeln('Property ID: $propertyId');
    if (owner != null) buffer.writeln('Owner: $owner');
    if (taxAccount != null) buffer.writeln('Tax Account: $taxAccount');
    if (alternateAccount != null)
      buffer.writeln('Alternate Account: $alternateAccount');
    if (propertyType != null) buffer.writeln('Property Type: $propertyType');
    if (landSize != null) buffer.writeln('Land Size: $landSize');
    if (legalDescription != null)
      buffer.writeln('Legal Description: $legalDescription');
    buffer.writeln('');

    buffer.writeln('FINANCIAL INFORMATION:');
    if (assessedValue != null) {
      buffer.writeln(
          '2025 Assessed Value: \$${assessedValue.toStringAsFixed(0)}');
    }
    if (totalDue != null) {
      buffer.writeln('Total Taxes Due: \$${totalDue.toStringAsFixed(2)}');
    }
    buffer.writeln('');

    if (sourceUrl != null) {
      buffer.writeln('SOURCE:');
      buffer.writeln(sourceUrl);
    }

    return buffer.toString();
  }

  /// Validate parsed property data
  static bool validateProperty(PropertyFile property) {
    if (property.fileNumber.isEmpty) return false;
    if (property.address.isEmpty) return false;
    if (property.city.isEmpty) return false;
    if (property.state.isEmpty) return false;

    return true;
  }
}
