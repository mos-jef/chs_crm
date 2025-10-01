// lib/services/auction_text_parser.dart - FIXED VERSION WITH ZILLOW URL SEPARATION
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

      // ✅ NEW: Extract Zillow URL (and DON'T treat it as an address!)
      if (_isZillowUrl(line)) {
        currentProperty = currentProperty.copyWith(
          zillowUrl: line.trim(),
          updatedAt: DateTime.now(),
        );
        continue;
      }

      // ✅ NEW: Extract "Total Required to Reinstate" → arrears
      if (_isReinstateAmountLine(line)) {
        final reinstateAmount = _extractMoneyAmount(line);
        if (reinstateAmount != null) {
          currentProperty = currentProperty.copyWith(
            arrears: reinstateAmount,
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // ✅ NEW: Extract "Total Required to Payoff" → amountOwed
      if (_isPayoffAmountLine(line)) {
        final payoffAmount = _extractMoneyAmount(line);
        if (payoffAmount != null) {
          currentProperty = currentProperty.copyWith(
            amountOwed: payoffAmount,
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // ✅ NEW: Extract Owner information
      if (_isOwnerLine(line)) {
        final ownerName = _extractOwnerName(line);
        if (ownerName != null) {
          currentProperty =
              _updatePropertyWithOwner(currentProperty, ownerName);
        }
        continue;
      }

      // ✅ NEW: Extract Parcel/APN information
      if (_isParcelLine(line)) {
        final parcelNumber = _extractParcelNumber(line);
        if (parcelNumber != null) {
          currentProperty = currentProperty.copyWith(
            taxAccountNumber: parcelNumber,
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // ✅ NEW: Extract County information
      if (_isCountyLine(line)) {
        final countyName = _extractCountyName(line);
        if (countyName != null) {
          final countyNote = Note(
            subject: 'County',
            content: countyName,
            createdAt: DateTime.now(),
          );
          currentProperty = currentProperty.copyWith(
            notes: [...currentProperty.notes, countyNote],
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // ✅ NEW: Extract Auction Date
      if (_isAuctionDateLine(line)) {
        final auctionDate = _extractAuctionDate(line);
        if (auctionDate != null) {
          // Store temporarily in notes, will be moved to proper auction object later
          final dateNote = Note(
            subject: 'Auction Date',
            content: line,
            createdAt: DateTime.now(),
          );
          currentProperty = currentProperty.copyWith(
            notes: [...currentProperty.notes, dateNote],
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // Store bid type information as note
      if (_isBidTypeLine(line)) {
        currentProperty = _updatePropertyWithBidType(currentProperty, line);
        continue;
      }

      // Address line (FIXED: Won't capture URLs anymore)
      if (_isAddressLine(line) && !_isZillowUrl(line)) {
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
      // DON'T auto-enhance if we already have a Zillow URL
      // Only enhance if missing Zillow URL or county
      if (PropertyEnhancementService.needsEnhancement(currentProperty)) {
        final enhancedProperty =
            PropertyEnhancementService.enhanceProperty(currentProperty);
        properties.add(enhancedProperty);
      } else {
        properties.add(currentProperty);
      }
    }

    debugPrint('✅ Parsed ${properties.length} properties');

    return properties;
  }

  // FIXED: Only dollar amounts trigger new properties
  static bool _isNewPropertyTrigger(String line) {
    // Only dollar amounts like $300,000 or TBD should start new properties
    return RegExp(r'^\$[0-9,]+$').hasMatch(line) || line.trim() == 'TBD';
  }

  // ✅ NEW: Detect Zillow URLs
  static bool _isZillowUrl(String line) {
    return line.toLowerCase().contains('zillow.com') ||
        line.toLowerCase().startsWith('http');
  }

  // ✅ NEW: Detect reinstate amount lines
  static bool _isReinstateAmountLine(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('reinstate') ||
        lowerLine.contains('to cure') ||
        lowerLine.contains('necessary to cure');
  }

  // ✅ NEW: Detect payoff amount lines
  static bool _isPayoffAmountLine(String line) {
    final lowerLine = line.toLowerCase();
    return (lowerLine.contains('payoff') ||
            lowerLine.contains('discharge this lien') ||
            lowerLine.contains('total owed')) &&
        !lowerLine.contains('reinstate');
  }

  // ✅ NEW: Detect owner information lines
  static bool _isOwnerLine(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.startsWith('owner:') || lowerLine.contains('owner:');
  }

  // ✅ NEW: Detect parcel/APN lines
  static bool _isParcelLine(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('parcel') ||
        lowerLine.contains('apn:') ||
        lowerLine.contains('tax id') ||
        lowerLine.contains('account number:');
  }

  // ✅ NEW: Detect county lines
  static bool _isCountyLine(String line) {
    final lowerLine = line.toLowerCase();
    // Must contain "county" but NOT be part of an address or auction location
    return lowerLine.contains('county') &&
        !lowerLine.contains('courthouse') &&
        !_isAddressLine(line) &&
        RegExp(r'^[A-Za-z\s]+County\s*$', caseSensitive: false).hasMatch(line);
  }

  // ✅ NEW: Detect auction date lines
  static bool _isAuctionDateLine(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.startsWith('auction date:') ||
        lowerLine.startsWith('date:');
  }

  // ✅ NEW: Extract dollar amount from line
  static double? _extractMoneyAmount(String line) {
    // Match patterns like: $17,043.78 or $189,419.05
    final moneyPattern = RegExp(r'\$([0-9,]+\.?\d*)');
    final match = moneyPattern.firstMatch(line);

    if (match != null) {
      final amountStr = match.group(1)!.replaceAll(',', '');
      return double.tryParse(amountStr);
    }

    return null;
  }

  // ✅ NEW: Extract owner name
  static String? _extractOwnerName(String line) {
    // Remove "Owner:" prefix and trim
    final ownerPattern = RegExp(r'owner:\s*(.+)', caseSensitive: false);
    final match = ownerPattern.firstMatch(line);

    if (match != null) {
      return match.group(1)!.trim();
    }

    return null;
  }

  // ✅ NEW: Extract parcel number
  static String? _extractParcelNumber(String line) {
    // Extract everything after "Parcel Number:", "APN:", etc.
    final parcelPatterns = [
      RegExp(r'parcel\s*(?:number)?:\s*(.+)', caseSensitive: false),
      RegExp(r'apn:\s*(.+)', caseSensitive: false),
      RegExp(r'tax\s*(?:id|account):\s*(.+)', caseSensitive: false),
    ];

    for (final pattern in parcelPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }

    return null;
  }

  // ✅ NEW: Extract county name
  static String? _extractCountyName(String line) {
    // Extract just the county name (e.g., "Lane County" → "Lane")
    final countyPattern =
        RegExp(r'^([A-Za-z\s]+)\s*County', caseSensitive: false);
    final match = countyPattern.firstMatch(line.trim());

    if (match != null) {
      return '${match.group(1)!.trim()} County';
    }

    return null;
  }

  // ✅ NEW: Extract auction date
  static DateTime? _extractAuctionDate(String line) {
    // Try to parse date from line
    // This is a simple implementation - you may want to enhance it
    final datePattern = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
    final match = datePattern.firstMatch(line);

    if (match != null) {
      final month = int.tryParse(match.group(1)!);
      final day = int.tryParse(match.group(2)!);
      var year = int.tryParse(match.group(3)!);

      if (year != null && year < 100) {
        year += 2000; // Convert 25 to 2025
      }

      if (month != null && day != null && year != null) {
        try {
          return DateTime(year, month, day);
        } catch (e) {
          return null;
        }
      }
    }

    return null;
  }

  // ✅ NEW: Update property with owner/vesting info
  static PropertyFile _updatePropertyWithOwner(
      PropertyFile property, String ownerName) {
    final vesting = VestingInfo(
      owners: [Owner(name: ownerName, percentage: 100.0)],
      vestingType: 'Unknown',
    );

    return property.copyWith(
      vesting: vesting,
      updatedAt: DateTime.now(),
    );
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
      zillowUrl: null, // ✅ Explicitly set to null
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
    // Parse full address like "1619 S BERTELSEN RD, EUGENE, OR 97402"
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
    // FIXED: Don't match URLs as addresses
    if (_isZillowUrl(line)) return false;

    return RegExp(r'\d+.+(St|Ave|Rd|Dr|Ln|Blvd|Way|Ct|Pl|Cir|Highway|Street)',
            caseSensitive: false)
        .hasMatch(line);
  }

  static bool _isCityStateLine(String line) {
    return RegExp(r'^[A-Za-z\s]+,\s*[A-Z]{2}\s+\d{5}').hasMatch(line);
  }

  static bool _isPropertyDetailsLine(String line) {
    return line.contains('bd') || line.contains('ba') || line.contains('sq');
  }
}
