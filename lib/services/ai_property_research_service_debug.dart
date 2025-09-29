// lib/services/ai_property_research_service_debug.dart
// SIMPLIFIED VERSION - No problematic API calls
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/property_file.dart';
import '../services/file_number_service.dart';

class AIPropertyResearchServiceDebug {
  //   MAIN METHOD - Simplified without API calls
  static Future<List<PropertyFile>> runIntelligentPropertyResearch({
    required String searchQuery,
    int maxProperties = 10,
  }) async {
    print(' ¤– DEBUG: Starting AI research with query: $searchQuery');

    try {
      // Skip problematic API calls and go straight to mock creation
      print(' ” DEBUG: Creating realistic mock properties based on search...');
      final mockProperties =
          await _createRealisticMockProperties(searchQuery, maxProperties);

      print('  … DEBUG: Created ${mockProperties.length} mock properties');
      return mockProperties;
    } catch (e) {
      print('  DEBUG: Error in AI research: $e');

      // Fallback to simple mock
      return await _createSimpleMockProperty(searchQuery);
    }
  }

  //   Create realistic mock properties based on search query
  static Future<List<PropertyFile>> _createRealisticMockProperties(
      String searchQuery, int maxProperties) async {
    print(' ” DEBUG: Creating realistic mocks for: $searchQuery');

    final properties = <PropertyFile>[];

    // Determine which county/area based on search query
    String county = 'multnomah'; // default
    String city = 'Portland';
    List<Map<String, dynamic>> propertyData = [];

    if (searchQuery.toLowerCase().contains('multnomah')) {
      county = 'multnomah';
      city = 'Portland';
      propertyData = _getMultnomahCountyMockData();
    } else if (searchQuery.toLowerCase().contains('washington')) {
      county = 'washington';
      city = 'Beaverton';
      propertyData = _getWashingtonCountyMockData();
    } else if (searchQuery.toLowerCase().contains('clackamas')) {
      county = 'clackamas';
      city = 'Oregon City';
      propertyData = _getClackamasCountyMockData();
    } else if (searchQuery.toLowerCase().contains('portland')) {
      county = 'multnomah';
      city = 'Portland';
      propertyData = _getPortlandMockData();
    } else {
      // Default Oregon-wide search
      propertyData = _getOregonWideMockData();
    }

    final numToCreate = maxProperties > propertyData.length
        ? propertyData.length
        : maxProperties;

    for (int i = 0; i < numToCreate; i++) {
      try {
        final mockData = propertyData[i];
        print(' ” DEBUG: Creating property ${i + 1}: ${mockData['address']}');

        final fileNumber = await FileNumberService.reserveFileNumber();
        print('  … DEBUG: Got file number: $fileNumber');

        final property = PropertyFile(
          id: '',
          fileNumber: fileNumber,
          address: mockData['address'],
          city: mockData['city'] ?? city,
          state: 'OR',
          zipCode: mockData['zipCode'] ?? '97201',
          loanAmount: mockData['loanAmount']?.toDouble(),
          amountOwed: mockData['amountOwed']?.toDouble(),
          arrears: mockData['arrears']?.toDouble(),
          contacts: [
            Contact(
                name: mockData['plaintiff'] ?? 'Unknown Bank',
                role: 'Plaintiff/Lender'),
            Contact(
                name: mockData['defendant'] ?? 'Property Owner',
                role: 'Defendant/Borrower'),
          ],
          documents: [],
          judgments: [
            Judgment(
              caseNumber: mockData['caseNumber'] ??
                  'FC2024-${(i + 1).toString().padLeft(3, '0')}',
              status: 'Foreclosure',
              county: county,
              state: 'OR',
              debtor: mockData['defendant'] ?? 'Property Owner',
              grantee: mockData['plaintiff'] ?? 'Unknown Bank',
              amount: mockData['judgmentAmount']?.toDouble(),
            ),
          ],
          notes: [
            Note(
              id: DateTime.now().millisecondsSinceEpoch.toString() +
                  i.toString(),
              subject: ' ¤– AI Research Summary (Debug Mode)',
              content: '''
 ” AI-POWERED PROPERTY RESEARCH RESULTS
Search Query: "$searchQuery"
Research Date: ${DateTime.now().toString().substring(0, 19)}

 “ PROPERTY DETAILS:
Address: ${mockData['address']}, ${mockData['city'] ?? city}, OR ${mockData['zipCode'] ?? '97201'}
County: ${county.toUpperCase()} County
Tax Account: ${mockData['taxAccount'] ?? 'Pending lookup'}

 ’° FINANCIAL INFORMATION:
Original Loan: \$${(mockData['loanAmount'] ?? 0).toStringAsFixed(0)}
Amount Owed: \$${(mockData['amountOwed'] ?? 0).toStringAsFixed(0)}
Assessed Value: \$${(mockData['assessedValue'] ?? 0).toStringAsFixed(0)}
Opening Bid: \$${(mockData['openingBid'] ?? 0).toStringAsFixed(0)}

 ›ï¸ COURT CASE INFORMATION:
Case Number: ${mockData['caseNumber'] ?? 'FC2024-${(i + 1).toString().padLeft(3, '0')}'}
Plaintiff: ${mockData['plaintiff'] ?? 'Unknown Bank'}
Defendant: ${mockData['defendant'] ?? 'Property Owner'}
Filing Date: ${mockData['filingDate'] ?? '2024-01-15'}

 “… AUCTION INFORMATION:
Sale Date: ${mockData['auctionDate'] ?? '2024-03-15'}
Location: ${county.toUpperCase()} County Courthouse
Opening Bid: \$${(mockData['openingBid'] ?? 0).toStringAsFixed(0)}

   PROPERTY CHARACTERISTICS:
Property Type: ${mockData['propertyType'] ?? 'Single Family Residential'}
Year Built: ${mockData['yearBuilt'] ?? '1980'}
Square Footage: ${mockData['sqft'] ?? '1,500'} sq ft
Lot Size: ${mockData['lotSize'] ?? '0.25'} acres

 ” DATA SOURCES SIMULATED:
  Auction.com listings
  ${county.toUpperCase()} County tax records
  Oregon court case database
  Public foreclosure notices

âš ï¸  DEBUG MODE: This is realistic mock data for testing.
When AI integration is complete, this will contain live data from actual sources.
              ''',
              createdAt: DateTime.now(),
            ),
          ],
          trustees: [],
          auctions: [
            Auction(
              id: DateTime.now().millisecondsSinceEpoch.toString() +
                  i.toString(),
              auctionDate:
                  DateTime.tryParse(mockData['auctionDate'] ?? '2024-03-15') ??
                      DateTime.now().add(const Duration(days: 30)),
              place: '${county.toUpperCase()} County Courthouse',
              time: const TimeOfDay(hour: 10, minute: 0),
              openingBid: mockData['openingBid']?.toDouble(),
              createdAt: DateTime.now(),
            ),
          ],
          vesting: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        properties.add(property);
        print(
            '  … DEBUG: Successfully created mock property: ${property.fileNumber}');
      } catch (e) {
        print('  DEBUG: Error creating mock property $i: $e');
        continue;
      }
    }

    print(
        '  … DEBUG: Total realistic mock properties created: ${properties.length}');
    return properties;
  }

  //   Mock data for different counties/searches

  static List<Map<String, dynamic>> _getMultnomahCountyMockData() {
    return [
      {
        'address': '1234 SE Division St',
        'city': 'Portland',
        'zipCode': '97202',
        'taxAccount': 'R175445',
        'caseNumber': 'FC2024-1001',
        'plaintiff': 'Wells Fargo Bank',
        'defendant': 'John & Jane Smith',
        'loanAmount': 450000,
        'amountOwed': 420000,
        'arrears': 25000,
        'assessedValue': 475000,
        'openingBid': 350000,
        'judgmentAmount': 445000,
        'auctionDate': '2024-03-20',
        'filingDate': '2024-01-15',
        'propertyType': 'Single Family Residential',
        'yearBuilt': '1995',
        'sqft': '1,850',
        'lotSize': '0.15',
      },
      {
        'address': '5678 NE Alberta St',
        'city': 'Portland',
        'zipCode': '97211',
        'taxAccount': 'R158332',
        'caseNumber': 'FC2024-1002',
        'plaintiff': 'Bank of America',
        'defendant': 'Maria Rodriguez',
        'loanAmount': 325000,
        'amountOwed': 310000,
        'arrears': 18000,
        'assessedValue': 340000,
        'openingBid': 285000,
        'judgmentAmount': 328000,
        'auctionDate': '2024-03-25',
        'filingDate': '2024-01-22',
        'propertyType': 'Single Family Residential',
        'yearBuilt': '1978',
        'sqft': '1,450',
        'lotSize': '0.12',
      },
      {
        'address': '9012 SE Powell Blvd',
        'city': 'Portland',
        'zipCode': '97266',
        'taxAccount': 'R192847',
        'caseNumber': 'FC2024-1003',
        'plaintiff': 'Quicken Loans',
        'defendant': 'Robert Chen',
        'loanAmount': 285000,
        'amountOwed': 275000,
        'arrears': 22000,
        'assessedValue': 295000,
        'openingBid': 240000,
        'judgmentAmount': 297000,
        'auctionDate': '2024-04-01',
        'filingDate': '2024-01-28',
        'propertyType': 'Single Family Residential',
        'yearBuilt': '1985',
        'sqft': '1,320',
        'lotSize': '0.18',
      },
    ];
  }

  static List<Map<String, dynamic>> _getWashingtonCountyMockData() {
    return [
      {
        'address': '2468 SW Cedar Hills Blvd',
        'city': 'Beaverton',
        'zipCode': '97005',
        'taxAccount': 'R63781',
        'caseNumber': 'FC2024-2001',
        'plaintiff': 'US Bank',
        'defendant': 'David & Sarah Johnson',
        'loanAmount': 520000,
        'amountOwed': 485000,
        'arrears': 35000,
        'assessedValue': 545000,
        'openingBid': 425000,
        'judgmentAmount': 520000,
        'auctionDate': '2024-03-18',
        'filingDate': '2024-01-10',
        'propertyType': 'Single Family Residential',
        'yearBuilt': '2005',
        'sqft': '2,150',
        'lotSize': '0.22',
      },
      {
        'address': '1357 NW Cornell Rd',
        'city': 'Hillsboro',
        'zipCode': '97124',
        'taxAccount': 'R84592',
        'caseNumber': 'FC2024-2002',
        'plaintiff': 'Chase Bank',
        'defendant': 'Michael Brown',
        'loanAmount': 675000,
        'amountOwed': 640000,
        'arrears': 45000,
        'assessedValue': 685000,
        'openingBid': 550000,
        'judgmentAmount': 685000,
        'auctionDate': '2024-03-22',
        'filingDate': '2024-01-18',
        'propertyType': 'Single Family Residential',
        'yearBuilt': '2010',
        'sqft': '2,650',
        'lotSize': '0.35',
      },
    ];
  }

  static List<Map<String, dynamic>> _getClackamasCountyMockData() {
    return [
      {
        'address': '3691 Main St',
        'city': 'Oregon City',
        'zipCode': '97045',
        'taxAccount': '05017784',
        'caseNumber': 'FC2024-3001',
        'plaintiff': 'First National Bank',
        'defendant': 'Lisa & Tom Wilson',
        'loanAmount': 385000,
        'amountOwed': 365000,
        'arrears': 28000,
        'assessedValue': 395000,
        'openingBid': 315000,
        'judgmentAmount': 393000,
        'auctionDate': '2024-03-12',
        'filingDate': '2024-01-05',
        'propertyType': 'Single Family Residential',
        'yearBuilt': '1992',
        'sqft': '1,750',
        'lotSize': '0.28',
      },
    ];
  }

  static List<Map<String, dynamic>> _getPortlandMockData() {
    return _getMultnomahCountyMockData(); // Portland is in Multnomah County
  }

  static List<Map<String, dynamic>> _getOregonWideMockData() {
    // Combine all county data for statewide search
    return [
      ..._getMultnomahCountyMockData(),
      ..._getWashingtonCountyMockData(),
      ..._getClackamasCountyMockData(),
    ];
  }

  //   Simple fallback mock
  static Future<List<PropertyFile>> _createSimpleMockProperty(
      String searchQuery) async {
    print(' †˜ DEBUG: Creating simple fallback mock property...');

    try {
      final fileNumber = await FileNumberService.reserveFileNumber();

      final property = PropertyFile(
        id: '',
        fileNumber: fileNumber,
        address: 'DEBUG: Fallback Test Property',
        city: 'Portland',
        state: 'OR',
        zipCode: '97201',
        loanAmount: 250000.0,
        contacts: [
          Contact(name: 'DEBUG: Test Bank', role: 'Lender'),
        ],
        documents: [],
        judgments: [],
        notes: [
          Note(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            subject: ' †˜ DEBUG: Fallback Mock Property',
            content: '''
FALLBACK DEBUG MODE

This property was created as a fallback.
Search Query: "$searchQuery"

This means the main mock creation process encountered an issue.
However, the basic property creation workflow is working.

Status: System operational, using fallback data.
            ''',
            createdAt: DateTime.now(),
          ),
        ],
        trustees: [],
        auctions: [],
        vesting: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('  … DEBUG: Fallback property created: ${property.fileNumber}');
      return [property];
    } catch (e) {
      print('  DEBUG: Even fallback property creation failed: $e');
      return [];
    }
  }

  //   Test county sites (simplified - no problematic API calls)
  static Future<void> testCountyTaxSites() async {
    print(' ” DEBUG: Testing county tax sites (simplified)...');

    final testUrls = {
      'Washington County': 'https://washcotax.co.washington.or.us/',
      'Multnomah County': 'https://multcoproptax.com/',
      'Clackamas County': 'https://ascendweb.clackamas.us/',
    };

    for (final entry in testUrls.entries) {
      try {
        print(' ” DEBUG: Testing ${entry.key}...');

        final response = await http.get(
          Uri.parse(entry.value),
          headers: {
            'User-Agent': 'Mozilla/5.0 (compatible; PropertyResearch 1.0)'
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          print('  … DEBUG: ${entry.key} accessible (${response.statusCode})');
        } else {
          print('âš ï¸  DEBUG: ${entry.key} returned ${response.statusCode}');
        }
      } catch (e) {
        print('  DEBUG: ${entry.key} failed: $e');
      }
    }
  }

  //   Test Oregon Sheriff's Sales site
  static Future<void> testOregonSheriffsSales() async {
    print(' ” DEBUG: Testing Oregon Sheriff\'s Sales...');

    try {
      final response = await http.get(
        Uri.parse('https://oregonsheriffssales.org/counties/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; PropertyResearch 1.0)'
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('  … DEBUG: Oregon Sheriff\'s Sales accessible');

        final document = html_parser.parse(response.body);
        final countyLinks = document.querySelectorAll('a[href*="/county/"]');
        print('  … DEBUG: Found ${countyLinks.length} county links');

        if (countyLinks.isEmpty) {
          print(
              'âš ï¸  DEBUG: No county links found - website structure may have changed');
        }
      } else {
        print(
            '  DEBUG: Oregon Sheriff\'s Sales returned ${response.statusCode}');
      }
    } catch (e) {
      print('  DEBUG: Oregon Sheriff\'s Sales test failed: $e');
    }
  }
}
