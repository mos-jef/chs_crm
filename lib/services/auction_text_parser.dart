// lib/services/auction_text_parser.dart - FINAL UPDATED VERSION
import 'package:chs_crm/services/property_enhancement_service.dart';
import 'package:flutter/material.dart';
import '../models/property_file.dart';
import '../services/file_number_service.dart';

class AuctionTextParser {
  /// Parse copied text from auction.com into PropertyFile objects
  static Future<List<PropertyFile>> parseAuctionData(String copiedText) async {
    final properties = <PropertyFile>[];

    // Split text into lines, clean them up, and remove duplicate consecutive lines
    final rawLines = copiedText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Remove duplicate consecutive lines
    final lines = <String>[];
    String? previousLine;
    for (final line in rawLines) {
      if (line != previousLine) {
        lines.add(line);
      }
      previousLine = line;
    }

    PropertyFile? currentProperty;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // FIXED: Only detect new property on dollar amounts, NOT on bid types
      final isNewProperty = _isNewPropertyTrigger(line);

      if (isNewProperty) {
        // Save previous property
        if (currentProperty != null) {
          properties.add(currentProperty);
        }

        // Start new property
        currentProperty = await _createNewProperty();

        // Extract price from dollar line
        final bidMatch = RegExp(r'\$([0-9,]+)').firstMatch(line);
        if (bidMatch != null) {
          final bidAmount =
              double.tryParse(bidMatch.group(1)!.replaceAll(',', ''));
          currentProperty = _updatePropertyWithBid(currentProperty, bidAmount);
        }

        continue;
      }

      if (currentProperty == null) continue;

      // Store bid type information as note (Current Bid, Opening Bid, etc.)
      if (_isBidTypeLine(line)) {
        currentProperty = _updatePropertyWithBidType(currentProperty, line);
        continue;
      }

      // Address line (now parses full address including city/state/zip)
      if (_isAddressLine(line)) {
        currentProperty = _updatePropertyWithAddress(currentProperty, line);
        continue;
      }

      // Property details (beds, baths, sqft)
      if (_isPropertyDetailsLine(line)) {
        currentProperty = _updatePropertyWithDetails(currentProperty, line);
        continue;
      }

      // Auction info (Bank Owned, Foreclosure Sale)
      if (line.contains('Bank Owned') || line.contains('Foreclosure Sale')) {
        currentProperty = _updatePropertyWithAuctionInfo(currentProperty, line);
        continue;
      }

      // Special tags (Price Reduced, Hot, FCL Predict)
      if (_isSpecialTag(line)) {
        currentProperty = _updatePropertyWithSpecialTag(currentProperty, line);
        continue;
      }
    }

    // Save last property
    if (currentProperty != null) {
      // AUTO-ENHANCE before adding to list
      final enhancedProperty =
          PropertyEnhancementService.enhanceProperty(currentProperty);
      properties.add(enhancedProperty);
    }

    debugPrint('✅ Parsed ${properties.length} properties from Auction.com');
    debugPrint('🔗 Auto-enhanced with Zillow URLs and county data');

    return properties;
  }

  // FIXED: Only dollar amounts trigger new properties
  static bool _isNewPropertyTrigger(String line) {
    // Only dollar amounts like $300,000 or TBD should start new properties
    return RegExp(r'^\$[0-9,]+$').hasMatch(line) || line.trim() == 'TBD';
  }

  // Detect bid type lines
  static bool _isBidTypeLine(String line) {
    return line.contains('Current Bid') ||
        line.contains('Opening Bid') ||
        line.contains('Est. Resale Value');
  }

  // Detect special tags
  static bool _isSpecialTag(String line) {
    return line.contains('Price Reduced') ||
        line.contains('Hot') ||
        line.contains('FCL Predict');
  }

  // --- Helper methods ---

  static Future<PropertyFile> _createNewProperty() async {
    final fileNumber = await FileNumberService.reserveFileNumber();
    return PropertyFile(
      id: '',
      fileNumber: fileNumber,
      address: '',
      city: '',
      state: 'OR',
      zipCode: '',
      taxAccountNumber: null,
      loanAmount: null,
      amountOwed: null,
      arrears: null,
      contacts: [],
      documents: [],
      judgments: [],
      notes: [],
      trustees: [],
      auctions: [],
      vesting: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static PropertyFile _updatePropertyWithBid(
      PropertyFile property, double? bidAmount) {
    return property.copyWith(
      loanAmount: bidAmount,
      updatedAt: DateTime.now(),
    );
  }

  static PropertyFile _updatePropertyWithBidType(
      PropertyFile property, String bidType) {
    final bidNote = Note(
      subject: 'Bid Type',
      content: bidType,
      createdAt: DateTime.now(),
    );

    return property.copyWith(
      notes: [...property.notes, bidNote],
      updatedAt: DateTime.now(),
    );
  }

  static PropertyFile _updatePropertyWithAddress(
      PropertyFile property, String fullAddressLine) {
    // Parse full address like "3774 Homestead Ct NE, Keizer, OR 97303"
    final addressComponents = _parseFullAddress(fullAddressLine);

    return property.copyWith(
      address: addressComponents['streetAddress'] ?? fullAddressLine,
      city: addressComponents['city'] ?? '',
      state: addressComponents['state'] ?? 'OR',
      zipCode: addressComponents['zipCode'] ?? '',
      updatedAt: DateTime.now(),
    );
  }

  static Map<String, String> _parseFullAddress(String fullAddress) {
    try {
      final cleanAddress = fullAddress.trim();

      // Split by commas first
      final commaParts = cleanAddress.split(',');

      if (commaParts.length >= 3) {
        // Format: Street, City, State Zip
        final streetAddress = commaParts[0].trim();
        final city = commaParts[1].trim();
        final stateZipPart = commaParts[2].trim();

        final stateZipMatch = RegExp(r'^([A-Z]{2})\s+(\d{5}(?:-\d{4})?)$')
            .firstMatch(stateZipPart);

        if (stateZipMatch != null) {
          return {
            'streetAddress': streetAddress,
            'city': city,
            'state': stateZipMatch.group(1)!,
            'zipCode': stateZipMatch.group(2)!,
          };
        }
      } else if (commaParts.length == 2) {
        final firstPart = commaParts[0].trim();
        final secondPart = commaParts[1].trim();

        final stateZipMatch =
            RegExp(r'^([A-Z]{2})\s+(\d{5}(?:-\d{4})?)$').firstMatch(secondPart);

        if (stateZipMatch != null) {
          final firstWords = firstPart.split(' ');
          if (firstWords.length > 3) {
            final city = firstWords.last;
            final streetAddress =
                firstWords.sublist(0, firstWords.length - 1).join(' ');

            return {
              'streetAddress': streetAddress,
              'city': city,
              'state': stateZipMatch.group(1)!,
              'zipCode': stateZipMatch.group(2)!,
            };
          }
        }
      }

      // If parsing fails, try alternative approach
      final stateZipPattern = RegExp(r',\s*([A-Z]{2})\s+(\d{5}(?:-\d{4})?)$');
      final stateZipMatch = stateZipPattern.firstMatch(cleanAddress);

      if (stateZipMatch != null) {
        final state = stateZipMatch.group(1)!;
        final zipCode = stateZipMatch.group(2)!;

        final beforeStateZip =
            cleanAddress.substring(0, stateZipMatch.start).trim();
        final lastCommaIndex = beforeStateZip.lastIndexOf(',');

        if (lastCommaIndex > 0) {
          final streetAddress =
              beforeStateZip.substring(0, lastCommaIndex).trim();
          final city = beforeStateZip.substring(lastCommaIndex + 1).trim();

          return {
            'streetAddress': streetAddress,
            'city': city,
            'state': state,
            'zipCode': zipCode,
          };
        }
      }

      return {
        'streetAddress': cleanAddress,
        'city': '',
        'state': 'OR',
        'zipCode': '',
      };
    } catch (e) {
      print('Error parsing address: $fullAddress - $e');
      return {
        'streetAddress': fullAddress,
        'city': '',
        'state': 'OR',
        'zipCode': '',
      };
    }
  }

  static PropertyFile _updatePropertyWithDetails(
      PropertyFile property, String detailsLine) {
    final detailsNote = Note(
      subject: 'Property Details',
      content: detailsLine,
      createdAt: DateTime.now(),
    );

    return property.copyWith(
      notes: [...property.notes, detailsNote],
      updatedAt: DateTime.now(),
    );
  }

  static PropertyFile _updatePropertyWithAuctionInfo(
      PropertyFile property, String auctionLine) {
    final auction = Auction(
      id: 'auction_${DateTime.now().millisecondsSinceEpoch}',
      auctionDate: DateTime.now().add(Duration(days: 30)),
      place: auctionLine.contains('Foreclosure Sale')
          ? 'Foreclosure Sale'
          : 'Bank Owned',
      time: const TimeOfDay(hour: 10, minute: 0),
      openingBid: property.loanAmount,
      auctionCompleted: false,
      createdAt: DateTime.now(),
    );

    return property.copyWith(
      auctions: [...property.auctions, auction],
      updatedAt: DateTime.now(),
    );
  }

  static PropertyFile _updatePropertyWithSpecialTag(
      PropertyFile property, String tagLine) {
    final tagNote = Note(
      subject: 'Special Tag',
      content: tagLine,
      createdAt: DateTime.now(),
    );

    return property.copyWith(
      notes: [...property.notes, tagNote],
      updatedAt: DateTime.now(),
    );
  }

  // Pattern detection helpers
  static bool _isAddressLine(String line) {
    return RegExp(r'\d+.+(St|Ave|Rd|Dr|Ln|Blvd|Way|Ct|Pl|Cir|Highway)',
            caseSensitive: false)
        .hasMatch(line);
  }

  static bool _isCityStateLine(String line) {
    // No longer used, but kept for potential legacy fallback
    return RegExp(r'^[A-Za-z\s]+,\s*[A-Z]{2}\s+\d{5}').hasMatch(line);
  }

  static bool _isPropertyDetailsLine(String line) {
    return line.contains('bd') || line.contains('ba') || line.contains('sq');
  }
}
