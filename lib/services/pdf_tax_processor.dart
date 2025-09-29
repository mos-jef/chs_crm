// lib/services/pdf_tax_processor.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property_file.dart';
import '../providers/property_provider.dart';
import 'package:http/http.dart' as http;

class PdfTaxProcessor {
  static const String _pdfTextExtractionUrl =
      'https://api.example.com/extract-pdf-text';

  /// Process batch upload of tax statement PDFs
  static Future<BatchProcessResult> processTaxStatementBatch({
    required BuildContext context,
    required List<TaxStatementUpload> uploads,
  }) async {
    final results = <String, ProcessingResult>{};
    final propertyProvider = context.read<PropertyProvider>();

    print('📁 Processing ${uploads.length} tax statement PDFs...');

    for (int i = 0; i < uploads.length; i++) {
      final upload = uploads[i];
      print('📄 Processing PDF ${i + 1}/${uploads.length}: ${upload.filename}');

      try {
        // Extract text from PDF
        final extractedText = await _extractPdfText(upload.fileData);

        // Parse tax data from extracted text
        final taxData = _parseTaxStatementData(extractedText);

        if (taxData == null) {
          results[upload.filename] =
              ProcessingResult.failed('Could not parse tax data from PDF');
          continue;
        }

        // Find matching property by address
        final matchingProperty =
            _findMatchingProperty(propertyProvider.properties, taxData.address);

        if (matchingProperty == null) {
          results[upload.filename] = ProcessingResult.failed(
              'No matching property found for address: ${taxData.address}');
          continue;
        }

        // Update property with tax data
        final updatedProperty =
            _mergePropertyWithTaxData(matchingProperty, taxData);

        // Save to database
        await propertyProvider.updatePropertySafe(updatedProperty);

        results[upload.filename] = ProcessingResult.success(
            'Updated property ${matchingProperty.fileNumber} with tax data');
      } catch (e) {
        results[upload.filename] =
            ProcessingResult.failed('Error processing PDF: $e');
      }
    }

    return BatchProcessResult(results);
  }

  /// Extract text content from PDF using external service or local processing
  static Future<String> _extractPdfText(Uint8List pdfData) async {
    // Option 1: Use a PDF processing service
    // This would call an external API that converts PDF to text

    // Option 2: Use a local PDF processing library
    // You'd need to add a PDF parsing package to your pubspec.yaml

    // For now, simulating with a service call:
    try {
      final response = await http.post(
        Uri.parse(_pdfTextExtractionUrl),
        headers: {'Content-Type': 'application/pdf'},
        body: pdfData,
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
            'PDF extraction service failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to extract PDF text: $e');
    }
  }

  /// Parse tax statement data from extracted PDF text
  static TaxStatementData? _parseTaxStatementData(String pdfText) {
    try {
      print('🔍 Parsing tax statement data...');

      // Extract property ID (R-number)
      final propertyIdMatch = RegExp(r'R\d{6,}').firstMatch(pdfText);
      if (propertyIdMatch == null) {
        print('❌ Could not find property ID in PDF');
        return null;
      }
      final propertyId = propertyIdMatch.group(0)!;

      // Extract address
      final addressMatch =
          RegExp(r'Property Address\s+(.+?)(?=\s+\$|\n|$)', multiLine: true)
              .firstMatch(pdfText);
      if (addressMatch == null) {
        print('❌ Could not find property address in PDF');
        return null;
      }
      final address = addressMatch.group(1)!.trim();

      // Extract owner name
      final ownerMatch = RegExp(r'Owner Name\s+(.+?)(?=\n|$)', multiLine: true)
          .firstMatch(pdfText);
      final ownerName = ownerMatch?.group(1)?.trim();

      // Extract assessed value (current year)
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
          RegExp(r'Legal Description\s+(.+?)(?=\n|Alternate)', multiLine: true)
              .firstMatch(pdfText);
      final legalDescription = legalDescMatch?.group(1)?.trim();

      // Extract source URL from bottom of pages
      final urlMatch =
          RegExp(r'https://multcoproptax\.com/Property-Detail/[^\s]+')
              .firstMatch(pdfText);
      final sourceUrl = urlMatch?.group(0);

      // Extract sales history
      final salesHistory = _extractSalesHistory(pdfText);

      // Extract tax payment history
      final paymentHistory = _extractPaymentHistory(pdfText);

      return TaxStatementData(
        propertyId: propertyId,
        address: address,
        ownerName: ownerName,
        assessedValue: assessedValue,
        totalDue: totalDue,
        legalDescription: legalDescription,
        sourceUrl: sourceUrl,
        salesHistory: salesHistory,
        paymentHistory: paymentHistory,
        extractedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error parsing tax statement: $e');
      return null;
    }
  }

  /// Extract sales history from PDF text
  static List<SaleRecord> _extractSalesHistory(String pdfText) {
    final sales = <SaleRecord>[];

    // Look for sales history section
    final salesSection = RegExp(r'SALES HISTORY(.*?)(?=TAX SUMMARY|$)',
            multiLine: true, dotAll: true)
        .firstMatch(pdfText);

    if (salesSection != null) {
      final salesText = salesSection.group(1)!;

      // Parse each sale line (format: DEED SELLER BUYER INSTR# DATE AMOUNT)
      final saleLines = RegExp(
              r'(WD|QCD|BSD)\s+(.+?)\s+(.+?)\s+(\d+)\s+(\d+/\d+/\d+)\s+\$?([0-9,]+)',
              multiLine: true)
          .allMatches(salesText);

      for (final match in saleLines) {
        final deedType = match.group(1)!;
        final seller = match.group(2)!.trim();
        final buyer = match.group(3)!.trim();
        final instrumentNumber = match.group(4)!;
        final dateStr = match.group(5)!;
        final amountStr = match.group(6)!;

        final saleDate = _parseDate(dateStr);
        final amount = _parseMoneyAmount(amountStr);

        if (saleDate != null) {
          sales.add(SaleRecord(
            deedType: deedType,
            seller: seller,
            buyer: buyer,
            instrumentNumber: instrumentNumber,
            saleDate: saleDate,
            amount: amount,
          ));
        }
      }
    }

    return sales;
  }

  /// Extract tax payment history
  static List<TaxPaymentRecord> _extractPaymentHistory(String pdfText) {
    final payments = <TaxPaymentRecord>[];

    // Look for payment history section with receipt numbers
    final paymentLines = RegExp(
            r'(\d{4})\s+(MULT-\d+|\d+)\s+(\d+-\d+-\d+)\s+\$([0-9,]+\.\d+)',
            multiLine: true)
        .allMatches(pdfText);

    for (final match in paymentLines) {
      final year = int.tryParse(match.group(1)!);
      final receiptNumber = match.group(2)!;
      final dateStr = match.group(3)!;
      final amountStr = match.group(4)!;

      final paymentDate = _parseDate(dateStr);
      final amount = _parseMoneyAmount(amountStr);

      if (year != null && paymentDate != null && amount != null) {
        payments.add(TaxPaymentRecord(
          taxYear: year,
          receiptNumber: receiptNumber,
          paymentDate: paymentDate,
          amount: amount,
        ));
      }
    }

    return payments;
  }

  /// Find matching property by address
  static PropertyFile? _findMatchingProperty(
      List<PropertyFile> properties, String pdfAddress) {
    final normalizedPdfAddress = _normalizeAddress(pdfAddress);

    for (final property in properties) {
      final normalizedPropertyAddress = _normalizeAddress(property.address);

      // Exact match
      if (normalizedPropertyAddress == normalizedPdfAddress) {
        return property;
      }

      // Fuzzy match (contains major components)
      if (_addressesMatch(normalizedPropertyAddress, normalizedPdfAddress)) {
        return property;
      }
    }

    return null;
  }

  /// Normalize address for comparison
  static String _normalizeAddress(String address) {
    return address
        .toUpperCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single
        .trim();
  }

  /// Check if addresses match with some tolerance
  static bool _addressesMatch(String addr1, String addr2) {
    final parts1 = addr1.split(' ');
    final parts2 = addr2.split(' ');

    // Must have matching street number
    if (parts1.isNotEmpty && parts2.isNotEmpty) {
      if (parts1[0] != parts2[0]) return false;
    }

    // Check for common street name components
    int matchingParts = 0;
    for (final part1 in parts1) {
      if (part1.length > 2 && parts2.contains(part1)) {
        matchingParts++;
      }
    }

    // Require at least 2 matching significant parts
    return matchingParts >= 2;
  }

  /// Merge property with tax data
  static PropertyFile _mergePropertyWithTaxData(
      PropertyFile property, TaxStatementData taxData) {
    // Create comprehensive tax note
    final taxNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: 'Multnomah County Tax Data (Auto-Uploaded)',
      content: '''
TAX STATEMENT INFORMATION
Uploaded: ${taxData.extractedAt.toString().substring(0, 16)}

PROPERTY DETAILS:
Tax Account: ${taxData.propertyId}
Owner: ${taxData.ownerName ?? 'N/A'}
Legal Description: ${taxData.legalDescription ?? 'N/A'}

FINANCIAL INFORMATION:
2025 Assessed Value: \$${taxData.assessedValue?.toStringAsFixed(0) ?? 'N/A'}
Total Taxes Due: \$${taxData.totalDue?.toStringAsFixed(2) ?? '0.00'}

SALES HISTORY:
${taxData.salesHistory.map((sale) => '${sale.saleDate.toString().substring(0, 10)}: ${sale.seller} → ${sale.buyer} (\$${sale.amount?.toStringAsFixed(0) ?? 'N/A'})').join('\n')}

RECENT TAX PAYMENTS:
${taxData.paymentHistory.take(5).map((payment) => '${payment.taxYear}: \$${payment.amount.toStringAsFixed(2)} (${payment.receiptNumber})').join('\n')}

SOURCE:
${taxData.sourceUrl ?? 'Uploaded PDF'}

Note: Data extracted automatically from uploaded PDF
      ''',
      createdAt: DateTime.now(),
    );

    return PropertyFile(
      id: property.id,
      fileNumber: property.fileNumber,
      address: property.address,
      city: property.city,
      state: property.state,
      zipCode: property.zipCode,
      county: property.county ?? 'Multnomah',

      // UPDATE WITH TAX DATA
      taxAccountNumber: taxData.propertyId,
      loanAmount: property.loanAmount,
      amountOwed: taxData.totalDue ?? property.amountOwed,
      arrears: property.arrears,
      zillowUrl: property.zillowUrl,

      // PRESERVE EXISTING DATA AND ADD TAX NOTE
      contacts: property.contacts,
      documents: property.documents,
      judgments: property.judgments,
      notes: [...property.notes, taxNote],
      trustees: property.trustees,
      auctions: property.auctions,
      vesting: property.vesting,
      createdAt: property.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods
  static double? _parseMoneyAmount(String amount) {
    final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanAmount);
  }

  static DateTime? _parseDate(String dateStr) {
    // Handle various date formats
    try {
      final parts = dateStr.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Failed to parse
    }
    return null;
  }
}

// Data models for tax processing
class TaxStatementUpload {
  final String filename;
  final Uint8List fileData;

  TaxStatementUpload({required this.filename, required this.fileData});
}

class TaxStatementData {
  final String propertyId;
  final String address;
  final String? ownerName;
  final double? assessedValue;
  final double? totalDue;
  final String? legalDescription;
  final String? sourceUrl;
  final List<SaleRecord> salesHistory;
  final List<TaxPaymentRecord> paymentHistory;
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

class SaleRecord {
  final String deedType;
  final String seller;
  final String buyer;
  final String instrumentNumber;
  final DateTime saleDate;
  final double? amount;

  SaleRecord({
    required this.deedType,
    required this.seller,
    required this.buyer,
    required this.instrumentNumber,
    required this.saleDate,
    this.amount,
  });
}

class TaxPaymentRecord {
  final int taxYear;
  final String receiptNumber;
  final DateTime paymentDate;
  final double amount;

  TaxPaymentRecord({
    required this.taxYear,
    required this.receiptNumber,
    required this.paymentDate,
    required this.amount,
  });
}

class ProcessingResult {
  final bool success;
  final String message;

  ProcessingResult._(this.success, this.message);

  factory ProcessingResult.success(String message) =>
      ProcessingResult._(true, message);
  factory ProcessingResult.failed(String message) =>
      ProcessingResult._(false, message);
}

class BatchProcessResult {
  final Map<String, ProcessingResult> results;

  BatchProcessResult(this.results);

  int get successCount => results.values.where((r) => r.success).length;
  int get failureCount => results.values.where((r) => !r.success).length;
  int get totalCount => results.length;
}
