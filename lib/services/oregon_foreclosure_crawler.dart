// lib/services/oregon_foreclosure_crawler.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html;
import '../models/property_file.dart';
import '../models/property_tax_info.dart';
import '../providers/property_provider.dart';
import '../services/file_number_service.dart';
import '../services/automation_config.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class OregonForeclosureCrawler {
  // Get proxy URL from configuration
  static Future<String> get proxyUrl => AutomationConfig.instance.getProxyUrl();

  // Core auction sites to crawl
  static const Map<String, String> auctionSites = {
    'auction_com':
        'https://www.auction.com/residential/search?foreclosure=all&state=OR',
    'realtytrac': 'https://www.realtytrac.com/foreclosures/oregon/',
    'foreclosure_com':
        'https://www.foreclosure.com/listing/search?state=Oregon',
  };

  // Oregon county property tax sites
  static const Map<String, String> countyTaxSites = {
    'washington': 'https://www.washingtonassessor.com/AdvancedSearch.aspx',
    'multnomah': 'https://multco.us/assessment-taxation/property-search',
    'clackamas':
        'https://ascendweb.clackamas.us/search/commonsearch.aspx?mode=realprop',
    'marion': 'https://apps.co.marion.or.us/AssessorPropertyInquiry/',
    'lane': 'https://apps.lanecounty.org/PropertyAccountInformation/',
    'jackson': 'https://jacksoncounty.org/services/Assessor/Property-Search',
    'yamhill': 'https://www.co.yamhill.or.us/content/property-search',
    'polk': 'https://polk.county-taxes.com/public/',
  };

  /// Main crawl function - Processes all Oregon foreclosure listings
  static Future<List<PropertyFile>> crawlAllOregonForeclosures({
    required BuildContext context,
    int maxProperties = 100,
    bool includeREO = true,
    List<String>? specificCounties,
  }) async {
    final results = <PropertyFile>[];
    print('Starting Oregon foreclosure crawl...');

    try {
      // Step 1: Crawl all auction sites
      for (final site in auctionSites.entries) {
        print('Crawling ${site.key}...');

        try {
          final siteProperties = await _crawlAuctionSite(
            site.key,
            site.value,
            maxProperties: maxProperties ~/ auctionSites.length,
            includeREO: includeREO,
            specificCounties: specificCounties,
          );

          // Step 2: For each property, enhance with county tax data
          for (final property in siteProperties) {
            try {
              final enhancedProperty = await _enhanceWithCountyData(property);
              if (enhancedProperty != null) {
                results.add(enhancedProperty);
              }

              // Rate limiting
              await Future.delayed(Duration(seconds: 2));
            } catch (e) {
              print('Error enhancing property ${property.address}: $e');
              // Still add the basic property data
              results.add(property);
            }
          }
        } catch (e) {
          print('Error crawling ${site.key}: $e');
          continue;
        }
      }

      // Step 3: Auto-save all properties to Firestore
      if (context.mounted) {
        await _savePropertiesToCRM(context, results);
      }

      print(
          'Oregon foreclosure crawl completed: ${results.length} properties found');
      return results;
    } catch (e) {
      print('Oregon foreclosure crawl failed: $e');
      rethrow;
    }
  }

  /// Crawl individual auction site
  static Future<List<PropertyFile>> _crawlAuctionSite(
    String siteName,
    String baseUrl, {
    int maxProperties = 50,
    bool includeREO = true,
    List<String>? specificCounties,
  }) async {
    switch (siteName) {
      case 'auction_com':
        return await _crawlAuctionDotCom(baseUrl, maxProperties: maxProperties);
      case 'realtytrac':
        return await _crawlRealtyTrac(baseUrl, maxProperties: maxProperties);
      case 'foreclosure_com':
        return await _crawlForeclosureDotCom(baseUrl,
            maxProperties: maxProperties);
      default:
        return [];
    }
  }

  /// Crawl Auction.com specifically
  static Future<List<PropertyFile>> _crawlAuctionDotCom(String searchUrl,
      {int maxProperties = 50}) async {
    final properties = <PropertyFile>[];

    try {
      // Get proxy URL from configuration
      final proxy = await proxyUrl;

      // Make request through your proxy
      final response = await http.get(
        Uri.parse('$proxy${Uri.encodeComponent(searchUrl)}'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load Auction.com: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);

      // Find property listings (adjust selectors based on actual HTML)
      final propertyCards = document.querySelectorAll(
          '.auction-item, .property-card, [data-testid="property-card"]');

      for (int i = 0;
          i < propertyCards.length && properties.length < maxProperties;
          i++) {
        final card = propertyCards[i];

        try {
          final property = await _parseAuctionComProperty(card);
          if (property != null) {
            properties.add(property);
          }
        } catch (e) {
          print('Error parsing Auction.com property $i: $e');
        }
      }
    } catch (e) {
      print('Error crawling Auction.com: $e');
    }

    return properties;
  }

  /// Parse individual Auction.com property
  static Future<PropertyFile?> _parseAuctionComProperty(
      html.Element card) async {
    try {
      // Extract basic info
      final addressEl = card.querySelector(
          '.address, .property-address, [data-testid="address"]');
      final priceEl =
          card.querySelector('.price, .opening-bid, [data-testid="price"]');
      final detailsEl = card.querySelector('.details, .property-details');
      final auctionDateEl = card.querySelector('.auction-date, .sale-date');

      if (addressEl == null) return null;

      final fullAddress = addressEl.text.trim();
      final addressParts = _parseAddress(fullAddress);

      // Extract price
      final priceText = priceEl?.text.replaceAll(RegExp(r'[^\d.]'), '') ?? '0';
      final openingBid = double.tryParse(priceText);

      // Extract property details
      final detailsText = detailsEl?.text ?? '';
      final beds = _extractNumber(detailsText, r'(\d+)\s*bed');
      final baths = _extractNumber(detailsText, r'(\d+)\s*bath');
      final sqft = _extractNumber(detailsText, r'(\d+,?\d*)\s*sq');

      // Extract APN if available
      final apnEl = card.querySelector('[data-apn], .tax-id, .parcel-id');
      final apn = apnEl?.text.trim() ?? apnEl?.attributes['data-apn'];

      // Extract auction date
      DateTime? auctionDate;
      if (auctionDateEl != null) {
        auctionDate = _parseDate(auctionDateEl.text.trim());
      }

      // Get file number
      final fileNumber = await FileNumberService.reserveFileNumber();

      return PropertyFile(
        id: '', // Will be set by Firestore
        fileNumber: fileNumber,
        address: addressParts['street'] ?? fullAddress,
        city: addressParts['city'] ?? 'Unknown',
        state: 'OR',
        zipCode: addressParts['zipCode'] ?? '',
        loanAmount: null, // Will be filled by county data
        amountOwed: null,
        arrears: null,
        taxAccountNumber: apn, // APN from auction site
        contacts: [],
        documents: [],
        judgments: [],
        notes: [
          Note(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            subject: 'Auction.com Listing Data',
            content: '''
Property discovered via automated auction crawl:

PROPERTY DETAILS:
Address: $fullAddress
Beds/Baths: ${beds ?? 'N/A'}/${baths ?? 'N/A'}
Square Footage: ${sqft != null ? '$sqft sq ft' : 'N/A'}
${apn != null ? 'APN/Tax ID: $apn' : ''}

AUCTION INFORMATION:
Opening Bid: \$${openingBid?.toStringAsFixed(0) ?? 'TBD'}
${auctionDate != null ? 'Auction Date: ${auctionDate.toString().substring(0, 10)}' : ''}
Source: Auction.com

AUTOMATION STATUS:
- Property automatically imported
- County tax data lookup pending
- Document collection in progress

Last updated: ${DateTime.now().toString().substring(0, 19)}
            ''',
            createdAt: DateTime.now(),
          ),
        ],
        trustees: [],
        auctions: auctionDate != null
            ? [
                Auction(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  auctionDate: auctionDate,
                  place: 'Online Auction',
                  time: TimeOfDay(hour: 10, minute: 0),
                  openingBid: openingBid,
                  auctionCompleted: auctionDate.isBefore(DateTime.now()),
                  createdAt: DateTime.now(),
                )
              ]
            : [],
        vesting: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Auction.com property: $e');
      return null;
    }
  }

  /// Enhance property with county tax data
  static Future<PropertyFile?> _enhanceWithCountyData(
      PropertyFile property) async {
    try {
      final county = _determineCounty(property.address, property.city);
      if (county == null) return property;

      print(
          'Looking up county tax data for ${property.address} in $county county...');

      final taxData = await _fetchCountyTaxData(county, property);
      if (taxData == null) return property;

      // Create enhanced property with tax data
      return PropertyFile(
        id: property.id,
        fileNumber: property.fileNumber,
        address: property.address,
        city: property.city,
        state: property.state,
        zipCode: property.zipCode,
        loanAmount:
            taxData.assessedValue, // Use assessed value as loan estimate
        amountOwed: property.amountOwed,
        arrears: property.arrears,
        taxAccountNumber: property.taxAccountNumber ?? taxData.accountNumber,
        contacts: property.contacts,
        documents: property.documents,
        judgments: property.judgments,
        notes: [
          ...property.notes,
          Note(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_tax',
            subject: 'County Tax Data',
            content: '''
Tax information automatically retrieved from ${county.toUpperCase()} County:

PROPERTY DETAILS:
Owner: ${taxData.owner ?? 'N/A'}
Legal Description: ${taxData.legalDescription ?? 'N/A'}
Property Type: ${taxData.propertyType ?? 'N/A'}
Year Built: ${taxData.yearBuilt ?? 'N/A'}

VALUATION:
Assessed Value: \$${taxData.assessedValue?.toStringAsFixed(0) ?? 'N/A'}
Market Value: \$${taxData.marketValue?.toStringAsFixed(0) ?? 'N/A'}
Tax Account: ${taxData.accountNumber ?? 'N/A'}

TAX STATUS:
Last Updated: ${DateTime.now().toString().substring(0, 10)}
Source: ${county.toUpperCase()} County Assessor

Automation Note: Data retrieved via web scraping
            ''',
            createdAt: DateTime.now(),
          ),
        ],
        trustees: property.trustees,
        auctions: property.auctions,
        vesting: VestingInfo(
          owners: [Owner(name: taxData.owner ?? 'Unknown', percentage: 100.0)],
          vestingType: 'Unknown',
        ),
        createdAt: property.createdAt,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error enhancing with county data: $e');
      return property;
    }
  }

  /// Fetch county tax data using APN
  static Future<PropertyTaxInfo?> _fetchCountyTaxData(
      String county, PropertyFile property) async {
    final baseUrl = countyTaxSites[county.toLowerCase()];
    if (baseUrl == null) {
      print('No tax site configured for $county county');
      return null;
    }

    try {
      // Use the APN if available, otherwise search by address
      String searchQuery;
      if (property.taxAccountNumber != null &&
          property.taxAccountNumber!.isNotEmpty) {
        searchQuery = property.taxAccountNumber!;
      } else {
        searchQuery = '${property.address}, ${property.city}';
      }

      print('Searching $county county for: $searchQuery');

      switch (county.toLowerCase()) {
        case 'washington':
          return await _searchWashingtonCounty(searchQuery);
        case 'multnomah':
          return await _searchMultnomahCounty(searchQuery);
        case 'clackamas':
          return await _searchClackamasCounty(searchQuery);
        default:
          print('Tax search not implemented for $county county yet');
          return null;
      }
    } catch (e) {
      print('Error fetching $county county tax data: $e');
      return null;
    }
  }

  /// Search Washington County tax records
  static Future<PropertyTaxInfo?> _searchWashingtonCounty(String query) async {
    try {
      const searchUrl =
          'https://www.washingtonassessor.com/AdvancedSearch.aspx';
      final proxy = await proxyUrl;

      final response = await http.get(
        Uri.parse('$proxy${Uri.encodeComponent(searchUrl)}'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
      );

      if (response.statusCode != 200) return null;

      // Parse the tax assessment page
      final document = html_parser.parse(response.body);

      // Extract tax information (adjust selectors based on actual HTML)
      final ownerEl = document.querySelector('#owner, .owner-name');
      final assessedEl =
          document.querySelector('#assessed-value, .assessed-value');
      final marketEl = document.querySelector('#market-value, .market-value');
      final accountEl =
          document.querySelector('#account-number, .account-number');

      return PropertyTaxInfo(
        owner: ownerEl?.text.trim(),
        assessedValue: _parsePrice(assessedEl?.text),
        marketValue: _parsePrice(marketEl?.text),
        accountNumber: accountEl?.text.trim(),
        county: 'Washington',
        state: 'OR',
      );
    } catch (e) {
      print('Error searching Washington County: $e');
      return null;
    }
  }

  /// Save all properties to CRM
  static Future<void> _savePropertiesToCRM(
      BuildContext context, List<PropertyFile> properties) async {
    try {
      final propertyProvider = context.read<PropertyProvider>();

      print('Saving ${properties.length} properties to CRM...');

      for (final property in properties) {
        try {
          await propertyProvider.addProperty(property);
          print('Saved: ${property.address}');

          // Small delay to avoid overwhelming Firestore
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          print('Error saving ${property.address}: $e');
        }
      }

      print('Bulk save completed');
    } catch (e) {
      print('Error in bulk save: $e');
      rethrow;
    }
  }

  // Helper methods for data extraction and parsing
  static String? _determineCounty(String address, String city) {
    final cityLower = city.toLowerCase();

    if (cityLower.contains('portland') ||
        cityLower.contains('gresham') ||
        cityLower.contains('fairview')) {
      return 'multnomah';
    }
    if (cityLower.contains('beaverton') ||
        cityLower.contains('tigard') ||
        cityLower.contains('hillsboro')) {
      return 'washington';
    }
    if (cityLower.contains('oregon city') ||
        cityLower.contains('milwaukie') ||
        cityLower.contains('clackamas')) {
      return 'clackamas';
    }

    // Default to multnomah for Portland metro
    return 'multnomah';
  }

  static Map<String, String> _parseAddress(String fullAddress) {
    final parts = fullAddress.split(',').map((s) => s.trim()).toList();

    if (parts.length >= 3) {
      final stateZip = parts.last.split(' ');
      return {
        'street': parts[0],
        'city': parts[1],
        'state': stateZip.isNotEmpty ? stateZip[0] : 'OR',
        'zipCode': stateZip.length > 1 ? stateZip[1] : '',
      };
    }

    return {
      'street': fullAddress,
      'city': 'Unknown',
      'state': 'OR',
      'zipCode': '',
    };
  }

  static int? _extractNumber(String text, String pattern) {
    final regex = RegExp(pattern, caseSensitive: false);
    final match = regex.firstMatch(text);
    return match != null
        ? int.tryParse(match.group(1)!.replaceAll(',', ''))
        : null;
  }

  static double? _parsePrice(String? text) {
    if (text == null) return null;
    final cleanText = text.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanText);
  }

  static DateTime? _parseDate(String dateText) {
    // Handle various date formats
    try {
      final cleaned = dateText.replaceAll(RegExp(r'[^\d/\-\s]'), '').trim();
      return DateTime.tryParse(cleaned) ??
          DateTime.tryParse(cleaned.replaceAll('/', '-'));
    } catch (e) {
      return null;
    }
  }

  // Placeholder methods for other sites
  static Future<List<PropertyFile>> _crawlRealtyTrac(String url,
      {int maxProperties = 50}) async {
    // Implementation for RealtyTrac crawling
    return [];
  }

  static Future<List<PropertyFile>> _crawlForeclosureDotCom(String url,
      {int maxProperties = 50}) async {
    // Implementation for Foreclosure.com crawling
    return [];
  }

  static Future<PropertyTaxInfo?> _searchMultnomahCounty(String query) async {
    // Implementation for Multnomah County tax search
    return null;
  }

  static Future<PropertyTaxInfo?> _searchClackamasCounty(String query) async {
    // Implementation for Clackamas County tax search
    return null;
  }
}
