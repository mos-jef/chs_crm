// lib/services/web_scraping_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/property_file.dart';
import '../models/scraped_data_models.dart';
import '../providers/property_provider.dart';

class WebScrapingService {
  // 🔧 UPDATED: Multiple CORS proxy options for better reliability
  static const List<String> _corsProxies = [
    'https://corsproxy.io/?', // Primary: Free, reliable
    'https://api.codetabs.com/v1/proxy?quest=', // Secondary: Backup
    'https://cors-anywhere.herokuapp.com/', // Tertiary: Original (requires request access)
  ];

  static int _currentProxyIndex = 0;

  // Helper method to get current CORS proxy URL
  static String get _currentCorsProxy => _corsProxies[_currentProxyIndex];

  // Method to rotate to next proxy if current fails
  static void _rotateProxy() {
    _currentProxyIndex = (_currentProxyIndex + 1) % _corsProxies.length;
    print('🔄 Rotated to proxy: ${_currentCorsProxy}');
  }

  static Future<http.Response> makeRequest(String url,
      {Map<String, String>? headers, int maxRetries = 3}) async {
    return await makeProxiedRequest(url,
        headers: headers, maxRetries: maxRetries);
  }

  // Enhanced HTTP request with proxy rotation
  static Future<http.Response> makeProxiedRequest(
    String url, {
    Map<String, String>? headers,
    int maxRetries = 3,
  }) async {
    headers ??= {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    };

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final proxiedUrl = '${_currentCorsProxy}$url';
        print('🌐 Attempting request via ${_currentCorsProxy}');
        print('📍 Target URL: $url');

        final response = await http
            .get(
              Uri.parse(proxiedUrl),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          print('✅ Request successful via ${_currentCorsProxy}');
          return response;
        } else if (response.statusCode == 429) {
          print('⚠️ Rate limited by ${_currentCorsProxy}, rotating...');
          _rotateProxy();
        } else {
          print('❌ HTTP ${response.statusCode} from ${_currentCorsProxy}');
          if (attempt < maxRetries - 1) _rotateProxy();
        }
      } catch (e) {
        print('❌ Error with ${_currentCorsProxy}: $e');
        if (attempt < maxRetries - 1) {
          _rotateProxy();
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
    }

    throw Exception('All CORS proxies failed after $maxRetries attempts');
  }

  //   EXAMPLE 1: Property Tax Records (Many counties have APIs)
  static Future<PropertyTaxInfo?> fetchPropertyTaxInfo({
    required String address,
    required String county,
    required String state,
  }) async {
    try {
      // Example: Washington County, Oregon property search
      if (county.toLowerCase() == 'washington' && state.toUpperCase() == 'OR') {
        final searchUrl =
            'https://www.co.washington.or.us/AssessmentTaxation/PropertyInformation/PropertySearch.cfm';

        // Use enhanced proxied request
        final response = await makeProxiedRequest(searchUrl);
        return _parsePropertyTaxData(response.body, address);
      }

      // Add more counties here...
      if (county.toLowerCase() == 'multnomah' && state.toUpperCase() == 'OR') {
        final searchUrl =
            'https://multco.us/assessment-taxation/property-information';
        final response = await makeProxiedRequest(searchUrl);
        return _parsePropertyTaxData(response.body, address);
      }
    } catch (e) {
      print('Error fetching property tax info: $e');
    }
    return null;
  }

  //   EXAMPLE 2: Foreclosure Auction Sites
  static Future<List<AuctionInfo>> fetchAuctionListings({
    required String zipCode,
    required String state,
  }) async {
    try {
      // Example: RealtyTrac, Auction.com, or local trustee websites
      final auctionSites = [
        'https://www.realtytrac.com/foreclosures/',
        'https://www.auction.com/real-estate/',
        // Add more auction sites
      ];

      List<AuctionInfo> allListings = [];

      for (String site in auctionSites) {
        try {
          final listings = await _scrapeAuctionSite(site, zipCode, state);
          allListings.addAll(listings);
        } catch (e) {
          print('⚠️ Failed to scrape $site: $e');
          // Continue with other sites
        }
      }

      return allListings;
    } catch (e) {
      print('Error fetching auction listings: $e');
      return [];
    }
  }

  //   EXAMPLE 3: Public Records (Court Documents)
  static Future<List<CourtRecord>> fetchCourtRecords({
    required String caseNumber,
    required String county,
    required String state,
  }) async {
    try {
      // Many courts have online case lookup systems
      final courtUrl = _getCourtUrl(county, state);
      if (courtUrl == null) return [];

      // For POST requests, we need to handle CORS differently
      // Most CORS proxies don't support POST, so we'd need our own backend
      print(
          '⚠️ Court records require POST requests - CORS proxy limitations apply');

      // For now, return empty - implement with backend proxy later
      return [];
    } catch (e) {
      print('Error fetching court records: $e');
    }
    return [];
  }

  //   EXAMPLE 4: MLS Data (if you have access)
  static Future<MLSPropertyInfo?> fetchMLSData({
    required String mlsNumber,
  }) async {
    try {
      // This would require MLS API access
      // Many areas have RETS feeds or APIs available to licensed agents
      final mlsApiUrl = 'https://api.mlsservice.com/Property/$mlsNumber';

      // MLS APIs typically require authentication, so CORS proxy won't help
      print('⚠️ MLS API requires authentication - implement server-side');
      return null;
    } catch (e) {
      print('Error fetching MLS data: $e');
    }
    return null;
  }

  //   EXAMPLE 5: Automated Property Creation from Address
  static Future<PropertyFile?> autoCreatePropertyFromAddress(
      String address, BuildContext context) async {
    try {
      print('🏠 Auto-creating property from address: $address');

      // Parse address components
      final addressParts = _parseAddress(address);

      // Fetch data from multiple sources with better error handling
      List<dynamic> results = [];

      try {
        final taxInfo = await fetchPropertyTaxInfo(
          address: address,
          county: addressParts['county'] ?? 'washington',
          state: addressParts['state'] ?? 'OR',
        );
        results.add(taxInfo);
      } catch (e) {
        print('⚠️ Tax info fetch failed: $e');
        results.add(null);
      }

      try {
        final auctions = await fetchAuctionListings(
          zipCode: addressParts['zipCode'] ?? '',
          state: addressParts['state'] ?? 'OR',
        );
        results.add(auctions);
      } catch (e) {
        print('⚠️ Auction fetch failed: $e');
        results.add(<AuctionInfo>[]);
      }

      final taxInfo = results[0] as PropertyTaxInfo?;
      final auctions = results[1] as List<AuctionInfo>;

      // Create property with scraped data
      final property = PropertyFile(
        id: '', // Will be set by Firestore
        fileNumber: '', // Will be set by FileNumberService
        address: addressParts['address'] ?? address,
        city: addressParts['city'] ?? taxInfo?.city ?? '',
        state: addressParts['state'] ?? taxInfo?.state ?? 'OR',
        zipCode: addressParts['zipCode'] ?? taxInfo?.zipCode ?? '',
        loanAmount:
            taxInfo?.assessedValue, // Use assessed value as starting point
        amountOwed: null, // To be filled in manually
        arrears: null, // To be filled in manually
        zillowUrl: await _findZillowUrl(address),
        contacts: [], // To be added manually
        documents: [], // To be added manually
        judgments: [], // Could be populated from court records
        notes: [
          Note(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            subject: '🤖 Auto-imported property data',
            content:
                'Property data automatically imported from:\n${taxInfo != null ? '✅ Property Tax Records\n' : '⚠️ Property Tax Records\n'}${auctions.isNotEmpty ? '✅ Auction Listings\n' : '⚠️ No Auction Listings\n'}Last updated: ${DateTime.now()}',
            createdAt: DateTime.now(),
          ),
        ],
        trustees: [], // To be added manually or from court records
        auctions: auctions
            .map((auction) => Auction(
                  id: DateTime.now().millisecondsSinceEpoch.toString() +
                      auction.hashCode.toString(),
                  auctionDate: auction.auctionDate,
                  place: auction.location,
                  time: auction.time,
                  openingBid: auction.openingBid,
                  auctionCompleted: auction.status == 'completed',
                  createdAt: DateTime.now(),
                ))
            .toList(),
        vesting: null, // To be filled in manually or from public records
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to provider
      if (context.mounted) {
        context.read<PropertyProvider>().addProperty(property);
      }

      return property;
    } catch (e) {
      print('Error auto-creating property: $e');
      return null;
    }
  }

  //   EXAMPLE 6: Bulk Data Import from Public Sources
  static Future<List<PropertyFile>> importPropertiesFromTrusteeWebsite({
    required String trusteeUrl,
    required BuildContext context,
  }) async {
    try {
      final response = await makeProxiedRequest(trusteeUrl);

      // Parse trustee website for auction listings
      final auctions = await _scrapeTrusteeWebsite(response.body);

      List<PropertyFile> properties = [];

      for (AuctionInfo auction in auctions) {
        try {
          final property =
              await autoCreatePropertyFromAddress(auction.address, context);
          if (property != null) {
            properties.add(property);
          }
        } catch (e) {
          print('⚠️ Failed to create property for ${auction.address}: $e');
        }

        // Rate limiting
        await Future.delayed(const Duration(seconds: 2));
      }

      return properties;
    } catch (e) {
      print('Error importing from trustee website: $e');
    }
    return [];
  }

  //   HELPER METHODS

  static PropertyTaxInfo? _parsePropertyTaxData(String html, String address) {
    // This would use the 'html' package to parse the DOM
    // Extract property details from the HTML response
    return null; // Placeholder - implement actual parsing
  }

  static Future<List<AuctionInfo>> _scrapeAuctionSite(
      String baseUrl, String zipCode, String state) async {
    // Implement auction site scraping
    return []; // Placeholder
  }

  static List<CourtRecord> _parseCourtRecords(String response) {
    // Parse court records from response
    return []; // Placeholder
  }

  static String? _getCourtUrl(String county, String state) {
    // Return court system URLs based on county/state
    if (state.toUpperCase() == 'OR') {
      switch (county.toLowerCase()) {
        case 'washington':
          return 'https://www.courts.oregon.gov/washington';
        case 'multnomah':
          return 'https://www.mcso.us/MCSO/CriminalRecords';
        default:
          return null;
      }
    }
    return null;
  }

  static Map<String, String> _parseAddress(String address) {
    // Simple address parsing - in production, use a geocoding service
    final parts = address.split(',').map((s) => s.trim()).toList();

    if (parts.length >= 3) {
      return {
        'address': parts[0],
        'city': parts[1],
        'state': parts[2].split(' ')[0],
        'zipCode': parts[2].split(' ').length > 1 ? parts[2].split(' ')[1] : '',
        'county': 'washington', // Default for Oregon
      };
    }

    return {
      'address': address,
      'city': '',
      'state': 'OR',
      'zipCode': '',
      'county': 'washington',
    };
  }

  static Future<String?> _findZillowUrl(String address) async {
    try {
      final searchUrl =
          'https://www.zillow.com/homes/${Uri.encodeComponent(address)}_rb/';
      return searchUrl;
    } catch (e) {
      return null;
    }
  }

  static Future<List<AuctionInfo>> _scrapeTrusteeWebsite(String html) async {
    // Parse trustee website HTML for auction listings
    return []; // Placeholder
  }

  // 🆕 Method to test CORS proxy connectivity
  static Future<void> testCorsProxies() async {
    print('🧪 Testing all CORS proxies...');

    for (int i = 0; i < _corsProxies.length; i++) {
      try {
        _currentProxyIndex = i;
        final testUrl = 'https://httpbin.org/get';
        final response = await makeProxiedRequest(testUrl, maxRetries: 1);
        print('✅ Proxy ${i + 1} (${_corsProxies[i]}) - Working');
      } catch (e) {
        print('❌ Proxy ${i + 1} (${_corsProxies[i]}) - Failed: $e');
      }
    }

    // Reset to first proxy
    _currentProxyIndex = 0;
  }
}
