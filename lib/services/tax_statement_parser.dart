// lib/services/tax_statement_parser.dart
class TaxStatementParser {
  static TaxStatementData? parseFromText(String pdfText) {
    try {
      print('🔍 Parsing tax statement from ${pdfText.length} characters of text');

      print('📄 First 1000 characters of extracted text:\n${pdfText.substring(0, pdfText.length > 1000 ? 1000 : pdfText.length)}');

      // Extract property ID (R-number)
      final propertyIdMatch = RegExp(r'R\d{6,}').firstMatch(pdfText);
      if (propertyIdMatch == null) {
        print('❌ Could not find property ID in PDF text');
        return null;
      }
      final propertyId = propertyIdMatch.group(0)!;

      // Extract address - look for the pattern in your PDF
      final addressMatch =
          RegExp(r'Property Address[^\n]*\n\s*([^\n$]+)', multiLine: true)
              .firstMatch(pdfText);
      if (addressMatch == null) {
        print('❌ Could not find property address in PDF text');
        return null;
      }
      final address = addressMatch.group(1)!.trim();

      // Extract owner name
      final ownerMatch =
          RegExp(r'Owner Name\s+([^\n]+)', multiLine: true).firstMatch(pdfText);
      final ownerName = ownerMatch?.group(1)?.trim();

      // Extract assessed value (2025)
      final assessedValueMatch =
          RegExp(r'2025[^$]*\$([0-9,]+)').firstMatch(pdfText);
      final assessedValue = assessedValueMatch != null
          ? _parseMoneyAmount(assessedValueMatch.group(1)!)
          : null;

      // Extract total due
      final totalDueMatch =
          RegExp(r'Total Due\s+\$([0-9,]+\.?\d*)').firstMatch(pdfText);
      final totalDue = totalDueMatch != null
          ? _parseMoneyAmount(totalDueMatch.group(1)!)
          : 0.0;

      // Extract legal description
      final legalDescMatch =
          RegExp(r'Legal Description\s+([^\n]+)', multiLine: true)
              .firstMatch(pdfText);
      final legalDescription = legalDescMatch?.group(1)?.trim();

      // Extract source URL
      final urlMatch =
          RegExp(r'https://multcoproptax\.com/Property-Detail/[^\s]+')
              .firstMatch(pdfText);
      final sourceUrl = urlMatch?.group(0);

      return TaxStatementData(
        propertyId: propertyId,
        address: address,
        ownerName: ownerName,
        assessedValue: assessedValue,
        totalDue: totalDue,
        legalDescription: legalDescription,
        sourceUrl: sourceUrl,
        salesHistory: [], // TODO: Implement sales history parsing
        paymentHistory: [], // TODO: Implement payment history parsing
        extractedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error parsing tax statement: $e');
      return null;
    }
  }

  static double? _parseMoneyAmount(String amount) {
    final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanAmount);
  }
}

// Data model for extracted tax information
class TaxStatementData {
  final String propertyId;
  final String address;
  final String? ownerName;
  final double? assessedValue;
  final double? totalDue;
  final String? legalDescription;
  final String? sourceUrl;
  final List<dynamic> salesHistory; // Simplified for now
  final List<dynamic> paymentHistory; // Simplified for now
  final DateTime extractedAt;

  TaxStatementData({
    required this.propertyId,
    required this.address,
    this.ownerName,
    this.assessedValue,
    this.totalDue,
    this.legalDescription,
    this.sourceUrl,
    required this.salesHistory,
    required this.paymentHistory,
    required this.extractedAt,
  });
}
