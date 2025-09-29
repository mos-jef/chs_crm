// lib/taxes/oregon/oregon_county_tax_service.dart
import 'package:chs_crm/models/property_file.dart';
import 'package:chs_crm/providers/property_provider.dart';
import 'package:flutter/foundation.dart';
import 'base_county_parser.dart';
import 'multnomah_county_parser.dart';
import 'oregon_county_tax_record.dart';
import 'oregon_counties_config.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Master service for Oregon county tax record lookups
/// Routes requests to appropriate county-specific parsers
class OregonCountyTaxService {
  static final OregonCountyTaxService _instance =
      OregonCountyTaxService._internal();
  factory OregonCountyTaxService() => _instance;
  OregonCountyTaxService._internal();

  // Cache of county parsers (instantiated as needed)
  final Map<String, BaseCountyParser> _countyParsers = {};

  // Performance tracking
  final Map<String, int> _requestCounts = {};
  final Map<String, int> _successCounts = {};
  final Map<String, List<Duration>> _responseTimes = {};

  /// Main entry point - get tax records for any Oregon property
  ///
  /// [address] - Property address (e.g., "3519 SE MORRISON ST, PORTLAND, OR")
  /// [county] - County name (optional, will auto-detect if not provided)
  /// [useCache] - Whether to use cached results (default: true)
  Future<OregonCountyTaxRecord?> getTaxRecords({
    required String address,
    String? county,
    bool useCache = true,
  }) async {
    final startTime = DateTime.now();

    try {
      print('🏠 Oregon Tax Service: Looking up $address');

      // Step 1: Determine county if not provided
      final targetCounty = county?.toLowerCase() ?? _detectCounty(address);
      if (targetCounty == null) {
        print('❌ Could not determine county for address: $address');
        return null;
      }

      print('📍 Target county: ${targetCounty.toUpperCase()}');

      // Step 2: Check if county is supported
      if (!OregonCountiesConfig.isCountySupported(targetCounty)) {
        print('❌ County $targetCounty is not yet supported');
        _logUnsupportedCounty(targetCounty);
        return null;
      }

      // Step 3: Check if county is implemented
      final config = OregonCountiesConfig.getCountyConfig(targetCounty);
      if (config == null || !config.implemented) {
        print('⚠️ County $targetCounty is configured but not yet implemented');
        _logUnimplementedCounty(targetCounty);
        return null;
      }

      // Step 4: Get or create county parser
      final parser = _getCountyParser(targetCounty);
      if (parser == null) {
        print('❌ No parser available for county: $targetCounty');
        return null;
      }

      // Step 5: Perform the lookup
      _incrementRequestCount(targetCounty);

      final result = await parser.searchByAddress(address);

      // Step 6: Track performance and results
      final duration = DateTime.now().difference(startTime);
      _recordResponseTime(targetCounty, duration);

      if (result != null) {
        _incrementSuccessCount(targetCounty);
        print('✅ Successfully retrieved tax records for $address');
        print('⏱️ Lookup took ${duration.inMilliseconds}ms');

        // Log summary of retrieved data
        _logTaxRecordSummary(result);
      } else {
        print('❌ No tax records found for $address');
      }

      return result;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      print('❌ Error looking up tax records: $e');

      if (kDebugMode) {
        print('Stack trace: $stackTrace');
      }

      _recordResponseTime(county ?? 'unknown', duration);
      return null;
    }
  }

  /// Get tax records by property ID (faster if you already know the ID)
  Future<OregonCountyTaxRecord?> getTaxRecordsByPropertyId({
    required String propertyId,
    required String county,
  }) async {
    try {
      print(
          '🔍 Oregon Tax Service: Looking up property ID $propertyId in $county county');

      final parser = _getCountyParser(county.toLowerCase());
      if (parser == null) {
        print('❌ No parser available for county: $county');
        return null;
      }

      // For property ID lookups, we can skip the search step and go directly to details
      final detailsHtml = await parser.fetchPropertyDetails(propertyId);
      if (detailsHtml.isEmpty) {
        print('❌ Could not fetch property details for ID: $propertyId');
        return null;
      }

      final result =
          parser.parsePropertyDetails(detailsHtml, 'Property ID Lookup');

      if (result != null) {
        print(
            '✅ Successfully retrieved tax records for property ID $propertyId');
        _logTaxRecordSummary(result);
      }

      return result;
    } catch (e) {
      print('❌ Error looking up property ID $propertyId: $e');
      return null;
    }
  }

  /// Batch lookup for multiple addresses
  Future<List<OregonCountyTaxRecord>> batchGetTaxRecords({
    required List<String> addresses,
    Duration? delayBetweenRequests,
  }) async {
    final results = <OregonCountyTaxRecord>[];
    final delay = delayBetweenRequests ?? const Duration(seconds: 2);

    print('📦 Starting batch lookup for ${addresses.length} addresses');

    for (int i = 0; i < addresses.length; i++) {
      final address = addresses[i];
      print('📍 Processing ${i + 1}/${addresses.length}: $address');

      try {
        final result = await getTaxRecords(address: address);
        if (result != null) {
          results.add(result);
        }
      } catch (e) {
        print('❌ Error processing $address: $e');
        // Continue with remaining addresses
      }

      // Rate limiting delay (except for last item)
      if (i < addresses.length - 1) {
        await Future.delayed(delay);
      }
    }

    print(
        '✅ Batch lookup completed: ${results.length}/${addresses.length} successful');
    return results;
  }

  /// Get service statistics and performance metrics
  Map<String, dynamic> getServiceStats() {
    final stats = <String, dynamic>{};

    // Implementation status
    final implementationStatus = OregonCountiesConfig.getImplementationStatus();
    stats['counties'] = implementationStatus;

    // Request statistics
    stats['requests'] = Map<String, dynamic>.from(_requestCounts);
    stats['successes'] = Map<String, dynamic>.from(_successCounts);

    // Success rates
    final successRates = <String, double>{};
    _requestCounts.forEach((county, requests) {
      final successes = _successCounts[county] ?? 0;
      successRates[county] = requests > 0 ? (successes / requests) * 100 : 0;
    });
    stats['success_rates'] = successRates;

    // Average response times
    final avgResponseTimes = <String, int>{};
    _responseTimes.forEach((county, times) {
      if (times.isNotEmpty) {
        final totalMs =
            times.map((t) => t.inMilliseconds).reduce((a, b) => a + b);
        avgResponseTimes[county] = (totalMs / times.length).round();
      }
    });
    stats['avg_response_times_ms'] = avgResponseTimes;

    // Supported counties
    stats['supported_counties'] = OregonCountiesConfig.getImplementedCounties();
    stats['all_counties'] = OregonCountiesConfig.getAllCountyNames();

    return stats;
  }

  /// Batch update all Multnomah County properties with tax data
  /// Batch update all Multnomah County properties with tax data
  Future<List<String>> batchUpdateMultnomahProperties({
    required BuildContext context,
    Duration delayBetweenRequests = const Duration(seconds: 3),
  }) async {
    final propertyProvider = context.read<PropertyProvider>();
    final allProperties = propertyProvider.properties;

    // Filter for Multnomah County properties that need tax data
    final multnomahProperties = allProperties
        .where((property) =>
            _detectCounty(property.address)?.toLowerCase() == 'multnomah' &&
            (property.taxAccountNumber == null ||
                property.taxAccountNumber!.isEmpty))
        .toList();

    print(
        'Found ${multnomahProperties.length} Multnomah County properties needing tax data');

    final results = <String>[];

    for (int i = 0; i < multnomahProperties.length; i++) {
      final property = multnomahProperties[i];
      print(
          'Processing ${i + 1}/${multnomahProperties.length}: ${property.address}');

      try {
        final taxRecord = await getTaxRecords(address: property.address);

        if (taxRecord != null) {
          // Create complete updated property with all existing data preserved
          final updatedProperty = PropertyFile(
            id: property.id,
            fileNumber: property.fileNumber,
            address: property.address,
            city: property.city,
            state: property.state,
            zipCode: property.zipCode,
            county: property.county ?? 'Multnomah', // Set county if not present

            // UPDATE WITH TAX DATA
            taxAccountNumber: taxRecord.propertyId,
            loanAmount: property.loanAmount ?? taxRecord.assessedValue,
            amountOwed: property.amountOwed,
            arrears: property.arrears,
            zillowUrl: property.zillowUrl,

            // PRESERVE ALL EXISTING DATA
            contacts: property.contacts,
            documents: property.documents,
            judgments: property.judgments,
            notes: [
              ...property.notes,
              // Add tax data note
              Note(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                subject: 'Multnomah County Tax Data',
                content: '''
TAX RECORD INFORMATION
Retrieved from Multnomah County Assessor (multcoproptax.com)

PROPERTY DETAILS:
Owner: ${taxRecord.ownerName ?? 'N/A'}
Tax Account: ${taxRecord.propertyId}
Alternate Account: ${taxRecord.alternateAccountNumber ?? 'N/A'}
Legal Description: ${taxRecord.legalDescription ?? 'N/A'}

VALUATION:
Assessed Value: \$${taxRecord.assessedValue?.toStringAsFixed(0) ?? 'N/A'}
Market Value: \$${taxRecord.marketValue?.toStringAsFixed(0) ?? 'N/A'}
Land Value: \$${taxRecord.landValue?.toStringAsFixed(0) ?? 'N/A'}
Improvement Value: \$${taxRecord.improvementValue?.toStringAsFixed(0) ?? 'N/A'}

TAX INFORMATION:
Current Year Taxes: \$${taxRecord.currentYearTaxes?.toStringAsFixed(0) ?? 'N/A'}
Tax Status: ${taxRecord.taxStatus ?? 'N/A'}

PROPERTY CHARACTERISTICS:
Property Type: ${taxRecord.propertyType ?? 'N/A'}
Year Built: ${taxRecord.yearBuilt ?? 'N/A'}
Square Footage: ${taxRecord.squareFootage ?? 'N/A'}
Lot Size: ${taxRecord.lotSizeAcres != null ? '${taxRecord.lotSizeAcres} acres' : 'N/A'}

Last Updated: ${DateTime.now().toString().substring(0, 10)}
Source: Multnomah County Assessor
URL: ${taxRecord.sourceUrl}

Automation Note: Data retrieved via web scraping from multcoproptax.com
              ''',
                createdAt: DateTime.now(),
              ),
            ],
            trustees: property.trustees,
            auctions: property.auctions,
            vesting: property.vesting,
            createdAt: property.createdAt,
            updatedAt: DateTime.now(),
          );

          // CRITICAL FIX: Actually save the updated property to database
          await propertyProvider.updatePropertySafe(updatedProperty);

          results.add(
              '✅ ${property.fileNumber} - ${property.address}: Tax ID ${taxRecord.propertyId}');
          print('✅ Successfully updated ${property.fileNumber} with tax data');
        } else {
          results.add(
              '❌ ${property.fileNumber} - ${property.address}: No tax data found');
          print('❌ No tax data found for ${property.address}');
        }

        // Add delay to be respectful to the server
        if (i < multnomahProperties.length - 1) {
          await Future.delayed(delayBetweenRequests);
        }
      } catch (e) {
        results
            .add('❌ ${property.fileNumber} - ${property.address}: Error - $e');
        print('❌ Error processing ${property.address}: $e');
      }
    }

    print(
        '✅ Batch update complete. Processed ${multnomahProperties.length} properties');
    return results;
  }

  /// Test connectivity to all implemented county sites
  Future<Map<String, bool>> testCountyConnectivity() async {
    final results = <String, bool>{};
    final implementedCounties = OregonCountiesConfig.getImplementedCounties();

    print(
        '🧪 Testing connectivity to ${implementedCounties.length} implemented counties...');

    for (final county in implementedCounties) {
      try {
        print('Testing $county county...');

        final parser = _getCountyParser(county);
        if (parser == null) {
          results[county] = false;
          continue;
        }

        // Try to access the county's search page
        final config = OregonCountiesConfig.getCountyConfig(county)!;
        final response = await parser.makeHttpRequest(config.searchUrl);

        results[county] = response.statusCode == 200;

        if (results[county]!) {
          print('✅ $county county: Connected');
        } else {
          print('❌ $county county: Failed (${response.statusCode})');
        }
      } catch (e) {
        results[county] = false;
        print('❌ $county county: Error - $e');
      }

      // Small delay between tests
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final successful = results.values.where((v) => v).length;
    print(
        '🏁 Connectivity test completed: $successful/${results.length} counties accessible');

    return results;
  }

  /// Clear all cached parsers and statistics (for testing/debugging)
  void clearCache() {
    _countyParsers.clear();
    _requestCounts.clear();
    _successCounts.clear();
    _responseTimes.clear();
    print('🧹 Cleared all cached data');
  }

  // Private helper methods

  /// Auto-detect county from address
  String? _detectCounty(String address) {
    final addressUpper = address.toUpperCase();

    // Look for city names that clearly indicate county
    if (addressUpper.contains('PORTLAND') ||
        addressUpper.contains('GRESHAM') ||
        addressUpper.contains('FAIRVIEW') ||
        addressUpper.contains('WOOD VILLAGE')) {
      return 'multnomah';
    }

    if (addressUpper.contains('BEAVERTON') ||
        addressUpper.contains('TIGARD') ||
        addressUpper.contains('HILLSBORO') ||
        addressUpper.contains('LAKE OSWEGO') ||
        addressUpper.contains('TUALATIN')) {
      return 'washington';
    }

    if (addressUpper.contains('OREGON CITY') ||
        addressUpper.contains('MILWAUKIE') ||
        addressUpper.contains('CLACKAMAS') ||
        addressUpper.contains('HAPPY VALLEY')) {
      return 'clackamas';
    }

    if (addressUpper.contains('SALEM') || addressUpper.contains('KEIZER')) {
      return 'marion';
    }

    if (addressUpper.contains('EUGENE') ||
        addressUpper.contains('SPRINGFIELD')) {
      return 'lane';
    }

    // Try to detect by ZIP code patterns
    final zipMatch = RegExp(r'\b\d{5}\b').firstMatch(address);
    if (zipMatch != null) {
      final zip = zipMatch.group(0)!;
      return _detectCountyByZip(zip);
    }

    // Default fallback for Portland metro area
    return 'multnomah';
  }

  String? _detectCountyByZip(String zip) {
    // Common Oregon ZIP code patterns
    if (zip.startsWith('972')) {
      // 972xx is typically Portland/Multnomah
      return 'multnomah';
    }

    if (zip.startsWith('970')) {
      // 970xx is typically Washington County
      return 'washington';
    }

    // Could expand this with more ZIP code mappings
    return null;
  }

  /// Get or create county parser
  BaseCountyParser? _getCountyParser(String county) {
    // Return cached parser if available
    if (_countyParsers.containsKey(county)) {
      return _countyParsers[county];
    }

    // Create new parser based on county
    BaseCountyParser? parser;

    switch (county.toLowerCase()) {
      case 'multnomah':
        parser = MultnomahCountyParser();
        break;

      // TODO: Add more county parsers as they're implemented
      // case 'washington':
      //   parser = WashingtonCountyParser();
      //   break;
      // case 'clackamas':
      //   parser = ClackamasCountyParser();
      //   break;

      default:
        print('⚠️ No parser implemented for county: $county');
        return null;
    }

    if (parser != null) {
      _countyParsers[county] = parser;
      print('🔧 Created new parser for $county county');
    }

    return parser;
  }

  // Performance tracking methods

  void _incrementRequestCount(String county) {
    _requestCounts[county] = (_requestCounts[county] ?? 0) + 1;
  }

  void _incrementSuccessCount(String county) {
    _successCounts[county] = (_successCounts[county] ?? 0) + 1;
  }

  void _recordResponseTime(String county, Duration duration) {
    _responseTimes[county] ??= <Duration>[];
    _responseTimes[county]!.add(duration);

    // Keep only last 100 response times per county to manage memory
    if (_responseTimes[county]!.length > 100) {
      _responseTimes[county]!.removeAt(0);
    }
  }

  void _logTaxRecordSummary(OregonCountyTaxRecord record) {
    print('📋 Tax Record Summary:');
    print('   Property: ${record.address}');
    print('   Owner: ${record.ownerName ?? 'Unknown'}');
    print('   Tax ID: ${record.propertyId}');

    if (record.assessedValue != null) {
      print('   Assessed Value: \$${record.assessedValue!.toStringAsFixed(0)}');
    }

    if (record.currentYearTaxes != null) {
      print(
          '   Current Taxes: \$${record.currentYearTaxes!.toStringAsFixed(0)}');
    }
  }

  void _logUnimplementedCounty(String county) {
    print('💡 To implement $county county:');
    print('   1. Create ${county}_county_parser.dart');
    print('   2. Update oregon_counties_config.dart');
    print('   3. Add case in _getCountyParser() method');
  }

  void _logUnsupportedCounty(String county) {
    print('💡 To support $county county:');
    print('   1. Add configuration to oregon_counties_config.dart');
    print('   2. Research county tax website structure');
    print('   3. Create parser implementation');
  }

  /// Get list of counties that need implementation
  List<String> getCountiesNeedingImplementation() {
    return OregonCountiesConfig.counties.entries
        .where((entry) => !entry.value.implemented)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get next highest priority county to implement
  String? getNextPriorityCounty() {
    final unimplemented = getCountiesNeedingImplementation();

    // Find highest priority unimplemented county
    for (final priority in [
      CountyPriority.high,
      CountyPriority.medium,
      CountyPriority.low
    ]) {
      final priorityCounties =
          OregonCountiesConfig.getCountiesByPriority(priority);

      for (final county in priorityCounties) {
        if (unimplemented.contains(county)) {
          return county;
        }
      }
    }

    return null;
  }
}
