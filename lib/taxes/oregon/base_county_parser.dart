// lib/taxes/oregon/base_county_parser.dart
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html;
import 'oregon_county_tax_record.dart';
import '../../services/web_scraping_service.dart';

/// Abstract base class for all Oregon county tax record parsers
/// Provides common functionality and enforces consistent interface
abstract class BaseCountyParser {
  final String countyName;
  final String baseUrl;
  final Map<String, String> selectors;

  BaseCountyParser({
    required this.countyName,
    required this.baseUrl,
    required this.selectors,
  });

  /// Main entry point - search for property by address
  Future<OregonCountyTaxRecord?> searchByAddress(String address) async {
    try {
      print('🔍 Searching $countyName County for: $address');

      // Step 1: Search for property
      final searchResults = await performAddressSearch(address);
      if (searchResults.isEmpty) {
        print('❌ No search results found in $countyName County');
        return null;
      }

      // Step 2: Get the first/best match
      final propertyId = extractPropertyId(searchResults);
      if (propertyId == null) {
        print('❌ Could not extract property ID from search results');
        return null;
      }

      // Step 3: Fetch detailed property information
      final detailsPage = await fetchPropertyDetails(propertyId);
      if (detailsPage.isEmpty) {
        print('❌ Could not fetch property details for ID: $propertyId');
        return null;
      }

      // Step 4: Parse detailed tax information
      final taxRecord = parsePropertyDetails(detailsPage, address);
      if (taxRecord != null) {
        print('✅ Successfully retrieved $countyName County tax record');
      }

      return taxRecord;
    } catch (e) {
      print('❌ Error searching $countyName County: $e');
      return null;
    }
  }

  /// Search for property using address - must be implemented by each county
  Future<String> performAddressSearch(String address);

  /// Extract property ID from search results HTML - must be implemented by each county
  String? extractPropertyId(String searchResultsHtml);

  /// Fetch detailed property information using property ID - must be implemented by each county
  Future<String> fetchPropertyDetails(String propertyId);

  /// Parse detailed tax information from property details page - must be implemented by each county
  OregonCountyTaxRecord? parsePropertyDetails(
      String detailsHtml, String originalAddress);

  /// Common HTTP request method with proxy support and error handling
  Future<http.Response> makeHttpRequest(String url,
      {Map<String, String>? headers}) async {
    try {
      print('🌐 Making proxied HTTP request to: $url');

      // Use your existing WebScrapingService proxy system
      final response = await WebScrapingService.makeProxiedRequest(
        url,
        headers: headers,
        maxRetries: 3,
      );

      print('✅ Proxied HTTP request successful (${response.statusCode})');
      return response;
    } catch (e) {
      print('❌ Proxied HTTP request failed: $e');
      rethrow;
    }
  }

  /// Parse HTML document from response
  html.Document parseHtml(String htmlContent) {
    return html_parser.parse(htmlContent);
  }

  /// Extract text content from HTML element using CSS selector
  String? extractTextBySelector(html.Document doc, String selector) {
    final element = doc.querySelector(selector);
    return element?.text.trim();
  }

  /// Extract multiple text contents from HTML elements using CSS selector
  List<String> extractMultipleTextBySelector(
      html.Document doc, String selector) {
    final elements = doc.querySelectorAll(selector);
    return elements
        .map((e) => e.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  /// Parse currency/price strings to double
  double? parseCurrency(String? text) {
    if (text == null || text.isEmpty) return null;

    // Remove currency symbols, commas, and whitespace
    final cleanText = text.replaceAll(RegExp(r'[\$,\s]'), '');
    return double.tryParse(cleanText);
  }

  /// Parse date strings to DateTime
  DateTime? parseDate(String? dateText) {
    if (dateText == null || dateText.isEmpty) return null;

    try {
      // Handle various date formats
      final cleaned = dateText.replaceAll(RegExp(r'[^\d/\-\s]'), '').trim();
      return DateTime.tryParse(cleaned) ??
          DateTime.tryParse(cleaned.replaceAll('/', '-'));
    } catch (e) {
      print('⚠️ Could not parse date: $dateText');
      return null;
    }
  }

  /// Extract property ID from URL or HTML attribute
  String? extractIdFromUrl(String url, RegExp pattern) {
    final match = pattern.firstMatch(url);
    return match?.group(1);
  }

  /// Clean up address for search (remove extra whitespace, standardize format)
  String cleanAddress(String address) {
    return address
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single space
        .toUpperCase(); // Standardize case
  }

  /// Validate that required tax record fields are present
  bool validateTaxRecord(OregonCountyTaxRecord record) {
    if (record.propertyId.isEmpty) {
      print('⚠️ Tax record missing property ID');
      return false;
    }

    if (record.address.isEmpty) {
      print('⚠️ Tax record missing address');
      return false;
    }

    // At least one financial value should be present
    if (record.assessedValue == null &&
        record.marketValue == null &&
        record.landValue == null) {
      print('⚠️ Tax record missing all financial values');
      return false;
    }

    return true;
  }

  /// Generate debugging information for failed parsing attempts
  void logParsingDebugInfo(html.Document doc, String step) {
    print('🐛 DEBUG - $step:');
    print('   Document title: ${doc.querySelector('title')?.text ?? 'None'}');
    print('   Total elements: ${doc.querySelectorAll('*').length}');
    print('   Forms found: ${doc.querySelectorAll('form').length}');
    print('   Tables found: ${doc.querySelectorAll('table').length}');
    print('   Links found: ${doc.querySelectorAll('a').length}');
  }
}
