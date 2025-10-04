// lib/services/auction_text_parser.dart - FIXED: Address AND Dollar Amount Trigger
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

      // ✅ FIXED: Trigger new property on BOTH address lines AND dollar amounts
      final isNewProperty =
          _isNewPropertyTrigger(line, i > 0 ? lines[i - 1] : null);

      if (isNewProperty) {
        // Save previous property
        if (currentProperty != null) {
          properties.add(currentProperty);
        }

        // Start new property
        currentProperty = await _createNewProperty();

        // If this is an address line, extract it immediately
        if (_isAddressLine(line)) {
          final addressParts = _parseFullAddress(line);
          currentProperty = currentProperty.copyWith(
            address: addressParts['streetAddress']!,
            city: addressParts['city']!,
            state: addressParts['state']!,
            zipCode: addressParts['zipCode']!,
            updatedAt: DateTime.now(),
          );
        }

        // If it's a dollar line, extract the bid
        else if (RegExp(r'^\$[0-9,]+').hasMatch(line)) {
          final bidMatch = RegExp(r'\$([0-9,]+)').firstMatch(line);
          if (bidMatch != null) {
            final bidAmount =
                double.tryParse(bidMatch.group(1)!.replaceAll(',', ''));
            currentProperty =
                _updatePropertyWithBid(currentProperty, bidAmount);
          }
        }

        continue;
      }

      if (currentProperty == null) continue;

      // Extract Zillow URL
      if (_isZillowUrl(line)) {
        currentProperty = currentProperty.copyWith(
          zillowUrl: line.trim(),
          updatedAt: DateTime.now(),
        );
        continue;
      }

      // Extract City, State, ZIP
      if (_isCityStateLine(line)) {
        // Parse just the city/state/zip from a line like "WOODBURN, OR 97071"
        final cityStatePattern =
            RegExp(r'^([A-Za-z\s]+),\s*([A-Z]{2})\s+(\d{5})');
        final match = cityStatePattern.firstMatch(line);

        if (match != null) {
          currentProperty = currentProperty.copyWith(
            city: match.group(1)!.trim(),
            state: match.group(2)!,
            zipCode: match.group(3)!,
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // Extract County
      if (_isCountyLine(line)) {
        final county = _extractCountyName(line);
        if (county != null) {
          currentProperty = currentProperty.copyWith(
            county: county,
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // Extract Estimated Value / Resale
      if (_isEstimatedValueLine(line)) {
        final estimatedValue = _extractMoneyAmount(line);
        if (estimatedValue != null) {
          currentProperty = currentProperty.copyWith(
            estimatedSaleValue: estimatedValue,
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // Extract "Arrears" amount
      if (line.toLowerCase().contains('arrears:')) {
        final arrearsAmount = _extractMoneyAmount(line);
        if (arrearsAmount != null) {
          currentProperty = currentProperty.copyWith(
            arrears: arrearsAmount,
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // Extract "Full Payoff" amount
      if (line.toLowerCase().contains('full payoff:') ||
          line.toLowerCase().contains('payoff:')) {
        final payoffAmount = _extractMoneyAmount(line);
        if (payoffAmount != null) {
          currentProperty = currentProperty.copyWith(
            amountOwed: payoffAmount,
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // Extract Owner information
      if (_isOwnerLine(line)) {
        final ownerName = _extractOwnerName(line);
        if (ownerName != null) {
          currentProperty =
              _updatePropertyWithOwner(currentProperty, ownerName);
        }
        continue;
      }

      // Extract Tax Account Number
      if (line.toLowerCase().contains('tax no.:') ||
          line.toLowerCase().contains('tax account')) {
        final taxNumber = _extractTaxNumber(line);
        if (taxNumber != null) {
          currentProperty = currentProperty.copyWith(
            taxAccountNumber: taxNumber,
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // Extract Auction Date
      if (line.toLowerCase().startsWith('auction date:') ||
          line.toLowerCase().startsWith('auction:')) {
        final auctionDate = _extractAuctionDate(line);
        if (auctionDate != null) {
          // Look ahead for time and place
          String? time;
          String? place;

          if (i + 1 < lines.length &&
              lines[i + 1].toLowerCase().startsWith('time:')) {
            time = lines[i + 1]
                .replaceFirst(RegExp(r'time:\s*', caseSensitive: false), '')
                .trim();
          }

          if (i + 2 < lines.length &&
              (lines[i + 2].toLowerCase().startsWith('place:') ||
                  lines[i + 2].toLowerCase().startsWith('location:'))) {
            place = lines[i + 2]
                .replaceFirst(
                    RegExp(r'(place|location):\s*', caseSensitive: false), '')
                .trim();
          }

          currentProperty =
              _addAuctionToProperty(currentProperty, auctionDate, time, place);
        }
        continue;
      }

      // Capture Legal Description (multi-line)
      if (line.toLowerCase().contains('legal description:')) {
        final legalDescLines = <String>[];
        // Look ahead for the next few lines
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          if (_isNewPropertyTrigger(lines[j], lines[j - 1]) ||
              _isZillowUrl(lines[j]) ||
              lines[j].toLowerCase().contains('arrears:') ||
              lines[j].toLowerCase().contains('auction')) {
            break;
          }
          legalDescLines.add(lines[j]);
        }

        if (legalDescLines.isNotEmpty) {
          final legalDesc = legalDescLines.join('\n');
          final note = Note(
            subject: 'Legal Description',
            content: legalDesc,
            createdAt: DateTime.now(),
          );
          currentProperty = currentProperty.copyWith(
            notes: [...currentProperty.notes, note],
            updatedAt: DateTime.now(),
          );
        }
        continue;
      }

      // Property details (beds, baths, sqft)
      if (_isPropertyDetailsLine(line)) {
        currentProperty = _updatePropertyWithDetails(currentProperty, line);
        continue;
      }
    }

    // Save last property
    if (currentProperty != null) {
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

  // ✅ FIXED: Trigger on BOTH address lines AND dollar amounts
  static bool _isNewPropertyTrigger(String line, String? previousLine) {
    // Trigger 1: Dollar amounts (standalone)
    if (RegExp(r'^\$[0-9,]+$').hasMatch(line) || line.trim() == 'TBD') {
      return true;
    }

    // Trigger 2: Address lines (street addresses with numbers)
    // But NOT if the previous line was also an address (prevents double-triggering)
    if (_isAddressLine(line)) {
      if (previousLine == null || !_isAddressLine(previousLine)) {
        return true;
      }
    }

    return false;
  }

  static bool _isZillowUrl(String line) {
    return line.toLowerCase().contains('zillow.com') ||
        (line.toLowerCase().startsWith('http') && line.contains('zillow'));
  }

  static bool _isEstimatedValueLine(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('estimated value') ||
        lowerLine.contains('est. resale') ||
        lowerLine.contains('est. value');
  }

  static bool _isOwnerLine(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.startsWith('owner:') || lowerLine.startsWith('owners:');
  }

  static bool _isCountyLine(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('county') &&
        !lowerLine.contains('courthouse') &&
        !_isAddressLine(line) &&
        RegExp(r'^[A-Za-z\s]+County\s*$', caseSensitive: false).hasMatch(line);
  }

  static bool _isAddressLine(String line) {
    if (_isZillowUrl(line)) return false;

    // Don't match property details like "2 bedrooms"
    if (line.toLowerCase().contains('bedroom') ||
        line.toLowerCase().contains('bath') ||
        line.toLowerCase().contains('sq')) {
      return false;
    }

    return RegExp(r'\d+.+(St|Ave|Rd|Dr|Ln|Blvd|Way|Ct|Pl|Cir|Highway|Street)',
            caseSensitive: false)
        .hasMatch(line);
  }

  static bool _isCityStateLine(String line) {
    return RegExp(r'^[A-Za-z\s]+,\s*[A-Z]{2}\s+\d{5}').hasMatch(line);
  }

  static bool _isPropertyDetailsLine(String line) {
    return line.contains('bd') ||
        line.contains('ba') ||
        line.contains('sq') ||
        line.contains('bedroom') ||
        line.contains('bath');
  }

  // Helper: Extract dollar amount
  static double? _extractMoneyAmount(String line) {
    final moneyPattern = RegExp(r'\$([0-9,]+\.?\d*)');
    final match = moneyPattern.firstMatch(line);
    if (match != null) {
      final amountStr = match.group(1)!.replaceAll(',', '');
      return double.tryParse(amountStr);
    }
    return null;
  }

  // Helper: Extract owner name
  static String? _extractOwnerName(String line) {
    final ownerPattern = RegExp(r'owners?:\s*(.+)', caseSensitive: false);
    final match = ownerPattern.firstMatch(line);
    return match?.group(1)?.trim();
  }

  // Helper: Extract county name
  static String? _extractCountyName(String line) {
    final countyPattern =
        RegExp(r'^([A-Za-z\s]+)\s*County', caseSensitive: false);
    final match = countyPattern.firstMatch(line.trim());
    return match != null ? '${match.group(1)!.trim()} County' : null;
  }

  // Helper: Extract tax number
  static String? _extractTaxNumber(String line) {
    final taxPattern =
        RegExp(r'tax\s*(?:no\.|account\s*no\.):\s*(.+)', caseSensitive: false);
    final match = taxPattern.firstMatch(line);
    return match?.group(1)?.trim();
  }

  // Helper: Extract auction date
  static DateTime? _extractAuctionDate(String line) {
    final datePattern = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
    final match = datePattern.firstMatch(line);

    if (match != null) {
      final month = int.tryParse(match.group(1)!);
      final day = int.tryParse(match.group(2)!);
      var year = int.tryParse(match.group(3)!);

      if (year != null && year < 100) {
        year += 2000;
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

  // Helper: Parse full address
  static Map<String, String> _parseFullAddress(String fullAddress) {
    try {
      final cleanAddress = fullAddress.trim();
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
      return {
        'streetAddress': fullAddress,
        'city': '',
        'state': 'OR',
        'zipCode': '',
      };
    }
  }

  // Helper: Create new property
  static Future<PropertyFile> _createNewProperty() async {
    final fileNumber = await FileNumberService.reserveFileNumber();

    return PropertyFile(
      id: '',
      fileNumber: fileNumber,
      address: '',
      city: '',
      state: 'OR',
      zipCode: '',
      contacts: [],
      documents: [],
      judgments: [],
      notes: [],
      trustees: [],
      auctions: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper: Update with bid amount
  static PropertyFile _updatePropertyWithBid(
      PropertyFile property, double? bidAmount) {
    return property.copyWith(
      loanAmount: bidAmount,
      updatedAt: DateTime.now(),
    );
  }

  // Helper: Update with owner info
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

  // Helper: Add auction info
  static PropertyFile _addAuctionToProperty(PropertyFile property,
      DateTime auctionDate, String? timeStr, String? place) {
    TimeOfDay time = TimeOfDay(hour: 10, minute: 0);

    if (timeStr != null) {
      final timeMatch =
          RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?', caseSensitive: false)
              .firstMatch(timeStr);
      if (timeMatch != null) {
        int hour = int.parse(timeMatch.group(1)!);
        final minute = int.parse(timeMatch.group(2)!);
        final ampm = timeMatch.group(3)?.toLowerCase();

        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;

        time = TimeOfDay(hour: hour, minute: minute);
      }
    }

    final auction = Auction(
      id: 'auction_${DateTime.now().millisecondsSinceEpoch}',
      auctionDate: auctionDate,
      place: place ?? 'County Courthouse',
      time: time,
      openingBid: property.loanAmount,
      auctionCompleted: false,
      createdAt: DateTime.now(),
    );

    return property.copyWith(
      auctions: [...property.auctions, auction],
      updatedAt: DateTime.now(),
    );
  }

  // Helper: Update with property details
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
}
