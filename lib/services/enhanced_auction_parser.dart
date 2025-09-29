// lib/services/enhanced_auction_parser.dart
import '../models/property_file.dart';
import '../models/property_tax_info.dart';
import '../services/file_number_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class EnhancedAuctionParser {
  /// Parse detailed property data and match to existing properties
  static Future<PropertyFile?> parseDetailedPropertyData(
      String copiedText, List<PropertyFile> existingProperties) async {
    // Extract key information from detailed property text
    final parsedData = _extractDetailedData(copiedText);

    if (parsedData['address'] == null) {
      throw Exception('Could not find address in pasted data');
    }

    // Try to find existing property by address
    PropertyFile? existingProperty =
        _findMatchingProperty(parsedData['address']!, existingProperties);

    if (existingProperty != null) {
      // Enhance existing property with detailed data
      return await _enhanceExistingProperty(existingProperty, parsedData);
    } else {
      // Create new property from detailed data
      return await _createPropertyFromDetailed(parsedData);
    }
  }

  /// Extract structured data from detailed property text
  static Map<String, dynamic> _extractDetailedData(String text) {
    final data = <String, dynamic>{};
    final lines =
        text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Extract address (line after "Bank Owned")
      if (line.contains('Bank Owned') && i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim();
        if (_isAddressLine(nextLine)) {
          data['address'] = nextLine;
        }
      }

      // Extract city/state/county
      if (_isCityStateLine(line)) {
        final locationData = _parseLocation(line);
        data.addAll(locationData);
      }

      // Extract property details
      if (line.contains('Beds') && i + 1 < lines.length) {
        data['beds'] = _extractNumber(lines[i + 1]);
      }
      if (line.contains('Baths') && i + 1 < lines.length) {
        data['baths'] = _extractNumber(lines[i + 1]);
      }
      if (line.contains('Square Footage') && i + 1 < lines.length) {
        data['sqft'] = _extractNumber(lines[i + 1]);
      }
      if (line.contains('Lot Size') && i + 1 < lines.length) {
        data['lotSize'] = _extractDecimalNumber(lines[i + 1]);
      }
      if (line.contains('Year Built') && i + 1 < lines.length) {
        data['yearBuilt'] = _extractNumber(lines[i + 1]);
      }

      // Extract APN (Tax Account Number)
      if (line.contains('APN') && i + 1 < lines.length) {
        data['apn'] = lines[i + 1].trim();
      }

      // Extract opening bid
      if (line.contains('Opening Bid') && i + 1 < lines.length) {
        final bidText = lines[i + 1].replaceAll(RegExp(r'[^\d.]'), '');
        data['openingBid'] = double.tryParse(bidText);
      }

      // Extract estimated value
      if (line.contains('Est. Resale Value') && i + 1 < lines.length) {
        final valueText = lines[i + 1].replaceAll(RegExp(r'[^\d.]'), '');
        data['estValue'] = double.tryParse(valueText);
      }

      // Extract auction duration
      if (line.contains('Duration')) {
        data['auctionDuration'] = line;
      }

      // Extract vacancy status
      if (line.contains('Vacant:')) {
        data['vacant'] = true;
        data['vacancyNote'] = line;
      }

      // Collect documents
      if (line.contains('Additional Documents')) {
        data['documents'] = _extractDocuments(lines, i);
      }
    }

    return data;
  }

  /// Find matching property by address
  static PropertyFile? _findMatchingProperty(
      String address, List<PropertyFile> properties) {
    final normalizedAddress =
        address.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    for (final property in properties) {
      final propertyAddress =
          property.address.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

      // Check for exact match or close match
      if (propertyAddress == normalizedAddress ||
          propertyAddress.contains(normalizedAddress.split(' ').first) ||
          normalizedAddress.contains(propertyAddress.split(' ').first)) {
        return property;
      }
    }

    return null;
  }

  /// Enhance existing property with detailed data
  static Future<PropertyFile> _enhanceExistingProperty(
      PropertyFile existing, Map<String, dynamic> detailedData) async {
    // Create enhanced notes with all the new detailed information
    final detailedNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString() + '_detailed',
      subject: 'Detailed Property Information',
      content: _buildDetailedNoteContent(detailedData),
      createdAt: DateTime.now(),
    );

    // Create documents list from parsed document names
    final documents =
        _createDocumentsList(detailedData['documents'] as List<String>? ?? []);

    return PropertyFile(
      id: existing.id,
      fileNumber: existing.fileNumber,
      address: existing.address,
      city: existing.city,
      state: existing.state,
      zipCode: existing.zipCode,
      taxAccountNumber:
          detailedData['apn'] ?? existing.taxAccountNumber, // Update APN
      loanAmount: detailedData['openingBid'] ?? existing.loanAmount,
      amountOwed: existing.amountOwed,
      arrears: existing.arrears,
      contacts: existing.contacts,
      documents: [...existing.documents, ...documents], // Merge documents
      judgments: existing.judgments,
      notes: [...existing.notes, detailedNote], // Add detailed note
      trustees: existing.trustees,
      auctions: existing.auctions, // Keep existing auction info
      vesting: existing.vesting,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Create new property from detailed data
  static Future<PropertyFile> _createPropertyFromDetailed(
      Map<String, dynamic> data) async {
    final fileNumber = await FileNumberService.reserveFileNumber();

    final documents =
        _createDocumentsList(data['documents'] as List<String>? ?? []);

    // Create auction if we have duration info
    final auctions = <Auction>[];
    if (data['auctionDuration'] != null) {
      final auction = _parseAuctionDuration(data['auctionDuration']);
      if (auction != null) auctions.add(auction);
    }

    return PropertyFile(
      id: '',
      fileNumber: fileNumber,
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? 'OR',
      zipCode: data['zipCode'] ?? '',
      taxAccountNumber: data['apn'],
      loanAmount: data['openingBid'],
      amountOwed: null,
      arrears: null,
      contacts: [],
      documents: documents,
      judgments: [],
      notes: [
        Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          subject: 'Property Created from Detailed Data',
          content: _buildDetailedNoteContent(data),
          createdAt: DateTime.now(),
        ),
      ],
      trustees: [],
      auctions: auctions,
      vesting: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Fetch county tax data using APN
  static Future<PropertyFile> enhanceWithTaxData(
      PropertyFile property, String proxyUrl) async {
    if (property.taxAccountNumber == null ||
        property.taxAccountNumber!.isEmpty) {
      throw Exception(
          'Property must have APN/Tax Account Number to fetch tax data');
    }

    final county = _determineCountyFromAddress(property.city);
    if (county == null) {
      throw Exception('Could not determine county from city: ${property.city}');
    }

    try {
      final taxData = await _fetchCountyTaxData(
          county, property.taxAccountNumber!, proxyUrl);

      if (taxData == null) {
        throw Exception(
            'Could not fetch tax data for APN: ${property.taxAccountNumber}');
      }

      // Create tax information note
      final taxNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_tax',
        subject: 'County Tax Records',
        content: '''
TAX RECORD INFORMATION
Retrieved from $county County Assessor

PROPERTY DETAILS:
Owner: ${taxData.owner ?? 'N/A'}
APN: ${taxData.accountNumber ?? property.taxAccountNumber}
Legal Description: ${taxData.legalDescription ?? 'N/A'}

VALUATION:
Assessed Value: \$${taxData.assessedValue?.toStringAsFixed(0) ?? 'N/A'}
Market Value: \$${taxData.marketValue?.toStringAsFixed(0) ?? 'N/A'}

TAX INFORMATION:
Annual Tax: \$${taxData.taxAmount?.toStringAsFixed(0) ?? 'N/A'}
Tax Status: ${taxData.taxDelinquent == true ? 'DELINQUENT' : 'Current'}

PROPERTY CHARACTERISTICS:
Property Type: ${taxData.propertyType ?? 'N/A'}
Year Built: ${taxData.yearBuilt ?? 'N/A'}

DATA SOURCE: ${county.toUpperCase()} County Assessor
Retrieved: ${DateTime.now().toString().substring(0, 19)}
        ''',
        createdAt: DateTime.now(),
      );

      // Update vesting with owner information
      final vesting = VestingInfo(
        owners: [
          Owner(name: taxData.owner ?? 'Unknown Owner', percentage: 100.0)
        ],
        vestingType: 'Unknown',
      );

      return PropertyFile(
        id: property.id,
        fileNumber: property.fileNumber,
        address: property.address,
        city: property.city,
        state: property.state,
        zipCode: property.zipCode,
        taxAccountNumber: property.taxAccountNumber,
        loanAmount: property.loanAmount,
        amountOwed: property.amountOwed,
        arrears: property.arrears,
        contacts: property.contacts,
        documents: property.documents,
        judgments: property.judgments,
        notes: [...property.notes, taxNote],
        trustees: property.trustees,
        auctions: property.auctions,
        vesting: vesting,
        createdAt: property.createdAt,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Tax data fetch failed: $e');
    }
  }

  // Helper methods
  static String _buildDetailedNoteContent(Map<String, dynamic> data) {
    return '''
DETAILED PROPERTY INFORMATION
Enhanced with auction.com detailed data

PHYSICAL CHARACTERISTICS:
Bedrooms: ${data['beds'] ?? 'N/A'}
Bathrooms: ${data['baths'] ?? 'N/A'}
Square Footage: ${data['sqft'] ?? 'N/A'} sq ft
Lot Size: ${data['lotSize'] ?? 'N/A'} acres
Year Built: ${data['yearBuilt'] ?? 'N/A'}

FINANCIAL INFORMATION:
Opening Bid: \$${data['openingBid']?.toStringAsFixed(0) ?? 'N/A'}
Est. Resale Value: \$${data['estValue']?.toStringAsFixed(0) ?? 'N/A'}
${data['estValue'] != null && data['openingBid'] != null ? 'Potential Equity: \$${(data['estValue'] - data['openingBid']).toStringAsFixed(0)}' : ''}

TAX INFORMATION:
APN: ${data['apn'] ?? 'N/A'}

PROPERTY STATUS:
${data['vacant'] == true ? 'VACANT PROPERTY' : 'Occupancy Status: Unknown'}
${data['vacancyNote'] ?? ''}

AUCTION DETAILS:
${data['auctionDuration'] ?? 'Duration information not available'}

DOCUMENTS AVAILABLE:
${(data['documents'] as List<String>?)?.join('\n') ?? 'No documents listed'}

Last Updated: ${DateTime.now().toString().substring(0, 19)}
Source: Auction.com detailed property page
    ''';
  }

  static List<Document> _createDocumentsList(List<String> documentNames) {
    return documentNames
        .map((name) => Document(
              name: name,
              type: 'Auction Document',
              url: null, // Would need to be populated separately
              uploadDate: DateTime.now(),
            ))
        .toList();
  }

  static List<String> _extractDocuments(List<String> lines, int startIndex) {
    final documents = <String>[];
    for (int i = startIndex + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty ||
          line.contains('Property Details') ||
          line.contains('Auction')) {
        break;
      }
      if (line.isNotEmpty && !line.contains('\$') && !line.contains('Bed')) {
        documents.add(line);
      }
    }
    return documents;
  }

  static Auction? _parseAuctionDuration(String durationText) {
    // Parse "Sep 22, 2025 5:00 AM - Sep 24, 2025 PDT"
    final dateRegex =
        RegExp(r'([A-Za-z]{3}\s+\d+,\s+\d{4})\s+(\d+):(\d+)\s+([AP]M)');
    final match = dateRegex.firstMatch(durationText);

    if (match == null) return null;

    // This is a simplified parser - you'd want more robust date parsing
    return Auction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      auctionDate: DateTime.now().add(Duration(days: 1)), // Placeholder
      place: 'Online Auction',
      time: TimeOfDay(hour: 10, minute: 0),
      openingBid: null,
      auctionCompleted: false,
      createdAt: DateTime.now(),
    );
  }

  // Copy helper methods from original parser
  static bool _isAddressLine(String line) {
    return RegExp(r'^\d+\s+[A-Za-z\s]+(?:St|Ave|Rd|Dr|Ln|Blvd|Way|Ct)(?:\s|$)',
            caseSensitive: false)
        .hasMatch(line);
  }

  static bool _isCityStateLine(String line) {
    return RegExp(r'^[A-Za-z\s]+,\s*OR\s+\d{5}').hasMatch(line);
  }

  static Map<String, String> _parseLocation(String locationLine) {
    final parts = locationLine.split(',').map((s) => s.trim()).toList();
    final result = <String, String>{};

    if (parts.isNotEmpty) result['city'] = parts[0];
    if (parts.length > 1) {
      final stateZip = parts[1].split(' ');
      result['state'] = stateZip[0];
      if (stateZip.length > 1) result['zipCode'] = stateZip[1];
    }

    return result;
  }

  static int? _extractNumber(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text.replaceAll(',', ''));
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  static double? _extractDecimalNumber(String text) {
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(text.replaceAll(',', ''));
    return match != null ? double.tryParse(match.group(1)!) : null;
  }

  static String? _determineCountyFromAddress(String city) {
    final cityLower = city.toLowerCase();

    if (cityLower.contains('portland') || cityLower.contains('gresham'))
      return 'multnomah';
    if (cityLower.contains('beaverton') || cityLower.contains('tigard'))
      return 'washington';
    if (cityLower.contains('oregon city') || cityLower.contains('milwaukie'))
      return 'clackamas';

    return 'multnomah'; // Default for Portland metro
  }

  static Future<PropertyTaxInfo?> _fetchCountyTaxData(
      String county, String apn, String proxyUrl) async {
    // This would implement actual tax record fetching using the APN
    // For now, return null - you'd implement the specific county APIs
    return null;
  }
}
