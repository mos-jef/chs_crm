// lib/taxes/oregon/oregon_counties_config.dart
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html;

/// Configuration for all 36 Oregon counties
/// Centralizes URLs, selectors, and parsing patterns
class OregonCountiesConfig {
  /// County configuration data
  static const Map<String, CountyConfig> counties = {
    // TIER 1: High Priority Counties (Metro Portland)
    'multnomah': CountyConfig(
      name: 'Multnomah',
      baseUrl: 'https://multcoproptax.com',
      searchUrl: 'https://multcoproptax.com/Property-Search-Subscribed',
      detailUrlPattern:
          'https://multcoproptax.com/Property-Detail/PropertyQuickRefID/{PROPERTY_ID}/PartyQuickRefID/{PARTY_ID}',
      priority: CountyPriority.high,
      implemented: true,
      selectors: {
        // Search results page selectors
        'search_result_row': 'table tbody tr',
        'property_id_link': 'td:first-child a',
        'property_id_text': 'td:first-child',
        'address_cell': 'td:nth-child(4)',
        'owner_cell': 'td:nth-child(3)',

        // Property details page selectors
        'owner_name': '.property-owner, #owner-name',
        'mailing_address': '.mailing-address',
        'assessed_value': '.assessed-value, [data-field="assessed-value"]',
        'market_value': '.market-value, [data-field="market-value"]',
        'land_value': '.land-value',
        'improvement_value': '.improvement-value',
        'property_type': '.property-type',
        'legal_description': '.legal-description',
        'neighborhood': '.neighborhood',
        'map_number': '.map-number',
        'year_built': '.year-built',
        'square_footage': '.square-footage',
        'lot_size': '.lot-size',
        'current_taxes': '.current-taxes',
        'tax_status': '.tax-status',

        // Historical data tables
        'assessment_table':
            'table.assessment-history, table[data-table="assessments"]',
        'sales_table': 'table.sales-history, table[data-table="sales"]',
        'tax_payment_table': 'table.tax-payments, table[data-table="payments"]',
      },
      searchParams: {
        'searchtext': '{ADDRESS}',
      },
    ),

    'washington': CountyConfig(
      name: 'Washington',
      baseUrl: 'https://washcotax.co.washington.or.us',
      searchUrl: 'https://washcotax.co.washington.or.us/Property-Search',
      detailUrlPattern:
          'https://washcotax.co.washington.or.us/Property-Detail/PropertyQuickRefID/{PROPERTY_ID}',
      priority: CountyPriority.high,
      implemented: false, // TODO: Implement next
      selectors: {
        'search_result_row': 'table tbody tr',
        'property_id_link': 'td:first-child a',
        'address_cell': 'td:nth-child(3)',
        'owner_name': '.owner-info .name',
        'assessed_value': '.assessed-value',
        'market_value': '.market-value',
      },
      searchParams: {
        'searchtext': '{ADDRESS}',
      },
    ),

    'clackamas': CountyConfig(
      name: 'Clackamas',
      baseUrl: 'https://ascendweb.clackamas.us',
      searchUrl: 'https://ascendweb.clackamas.us/search/commonsearch.aspx',
      detailUrlPattern:
          'https://ascendweb.clackamas.us/ParcelInfo.aspx?parcel_number={PROPERTY_ID}',
      priority: CountyPriority.high,
      implemented: false,
      selectors: {
        'search_result_row': '.search-results tr',
        'property_id_link': 'a[href*="ParcelInfo"]',
        'address_cell': '.address-cell',
      },
      searchParams: {
        'mode': 'realprop',
        'searchtext': '{ADDRESS}',
      },
    ),

    // TIER 2: Medium Priority Counties
    'marion': CountyConfig(
      name: 'Marion',
      baseUrl: 'https://apps.co.marion.or.us',
      searchUrl: 'https://apps.co.marion.or.us/AssessorPropertyInquiry/',
      detailUrlPattern:
          'https://apps.co.marion.or.us/AssessorPropertyInquiry/Detail/{PROPERTY_ID}',
      priority: CountyPriority.medium,
      implemented: false,
      selectors: {},
      searchParams: {'address': '{ADDRESS}'},
    ),

    'lane': CountyConfig(
      name: 'Lane',
      baseUrl: 'https://apps.lanecounty.org',
      searchUrl: 'https://apps.lanecounty.org/PropertyAccountInformation/',
      detailUrlPattern:
          'https://apps.lanecounty.org/PropertyAccountInformation/Detail/{PROPERTY_ID}',
      priority: CountyPriority.medium,
      implemented: false,
      selectors: {},
      searchParams: {'address': '{ADDRESS}'},
    ),

    'jackson': CountyConfig(
      name: 'Jackson',
      baseUrl: 'https://jacksoncounty.org',
      searchUrl: 'https://jacksoncounty.org/services/Assessor/Property-Search',
      detailUrlPattern:
          'https://jacksoncounty.org/services/Assessor/Property-Detail/{PROPERTY_ID}',
      priority: CountyPriority.medium,
      implemented: false,
      selectors: {},
      searchParams: {'search': '{ADDRESS}'},
    ),

    'yamhill': CountyConfig(
      name: 'Yamhill',
      baseUrl: 'https://www.co.yamhill.or.us',
      searchUrl: 'https://www.co.yamhill.or.us/content/property-search',
      detailUrlPattern:
          'https://www.co.yamhill.or.us/content/property-detail/{PROPERTY_ID}',
      priority: CountyPriority.medium,
      implemented: false,
      selectors: {},
      searchParams: {'q': '{ADDRESS}'},
    ),

    'polk': CountyConfig(
      name: 'Polk',
      baseUrl: 'https://polk.county-taxes.com',
      searchUrl: 'https://polk.county-taxes.com/public/',
      detailUrlPattern:
          'https://polk.county-taxes.com/public/property/{PROPERTY_ID}',
      priority: CountyPriority.medium,
      implemented: false,
      selectors: {},
      searchParams: {'search': '{ADDRESS}'},
    ),

    // TIER 3: Lower Priority Counties (Implement as needed)
    'douglas': CountyConfig(
      name: 'Douglas',
      baseUrl: 'https://douglas.county-taxes.com',
      searchUrl: 'https://douglas.county-taxes.com/public/search',
      detailUrlPattern:
          'https://douglas.county-taxes.com/public/property/{PROPERTY_ID}',
      priority: CountyPriority.low,
      implemented: false,
      selectors: {},
      searchParams: {'address': '{ADDRESS}'},
    ),

    'deschutes': CountyConfig(
      name: 'Deschutes',
      baseUrl: 'https://deschutes.county-taxes.com',
      searchUrl: 'https://deschutes.county-taxes.com/public/search',
      detailUrlPattern:
          'https://deschutes.county-taxes.com/public/property/{PROPERTY_ID}',
      priority: CountyPriority.low,
      implemented: false,
      selectors: {},
      searchParams: {'address': '{ADDRESS}'},
    ),

    'benton': CountyConfig(
      name: 'Benton',
      baseUrl: 'https://benton.county-taxes.com',
      searchUrl: 'https://benton.county-taxes.com/public/search',
      detailUrlPattern:
          'https://benton.county-taxes.com/public/property/{PROPERTY_ID}',
      priority: CountyPriority.low,
      implemented: false,
      selectors: {},
      searchParams: {'address': '{ADDRESS}'},
    ),

    // Additional counties can be added here as needed...
    // Complete list of all 36 Oregon counties would go here
  };

  /// Get county configuration by name
  static CountyConfig? getCountyConfig(String countyName) {
    return counties[countyName.toLowerCase()];
  }

  /// Get all implemented counties
  static List<String> getImplementedCounties() {
    return counties.entries
        .where((entry) => entry.value.implemented)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get counties by priority level
  static List<String> getCountiesByPriority(CountyPriority priority) {
    return counties.entries
        .where((entry) => entry.value.priority == priority)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get all county names (for UI dropdowns, etc.)
  static List<String> getAllCountyNames() {
    return counties.values.map((config) => config.name).toList()..sort();
  }

  /// Check if a county is supported
  static bool isCountySupported(String countyName) {
    return counties.containsKey(countyName.toLowerCase());
  }

  /// Get implementation status summary
  static Map<String, int> getImplementationStatus() {
    int implemented = 0;
    int high = 0;
    int medium = 0;
    int low = 0;

    for (final config in counties.values) {
      if (config.implemented) implemented++;

      switch (config.priority) {
        case CountyPriority.high:
          high++;
          break;
        case CountyPriority.medium:
          medium++;
          break;
        case CountyPriority.low:
          low++;
          break;
      }
    }

    return {
      'total': counties.length,
      'implemented': implemented,
      'high_priority': high,
      'medium_priority': medium,
      'low_priority': low,
    };
  }
}

/// Configuration for a specific county's tax system
class CountyConfig {
  final String name;
  final String baseUrl;
  final String searchUrl;
  final String detailUrlPattern;
  final CountyPriority priority;
  final bool implemented;
  final Map<String, String> selectors;
  final Map<String, String> searchParams;
  final String? notes;

  const CountyConfig({
    required this.name,
    required this.baseUrl,
    required this.searchUrl,
    required this.detailUrlPattern,
    required this.priority,
    required this.implemented,
    required this.selectors,
    required this.searchParams,
    this.notes,
  });

  /// Build search URL with address parameter
  String buildSearchUrl(String address) {
    String url = searchUrl;
    final params = <String>[];

    searchParams.forEach((key, value) {
      final paramValue =
          value.replaceAll('{ADDRESS}', Uri.encodeComponent(address));
      params.add('$key=$paramValue');
    });

    if (params.isNotEmpty) {
      url += (searchUrl.contains('?') ? '&' : '?') + params.join('&');
    }

    return url;
  }

  /// Build property detail URL with property ID
  String buildDetailUrl(String propertyId, [String? partyId]) {
    return detailUrlPattern
        .replaceAll('{PROPERTY_ID}', propertyId)
        .replaceAll('{PARTY_ID}', partyId ?? '');
  }

  /// Get CSS selector for a specific field
  String? getSelector(String field) {
    return selectors[field];
  }

  /// Check if this county has a specific selector defined
  bool hasSelector(String field) {
    return selectors.containsKey(field);
  }

  @override
  String toString() {
    return 'CountyConfig($name, implemented: $implemented, priority: $priority)';
  }
}

/// Priority levels for county implementation
enum CountyPriority {
  high, // Metro Portland area - implement first
  medium, // Major cities - implement second
  low, // Rural/smaller counties - implement as needed
}

/// Extension to get readable priority names
extension CountyPriorityExtension on CountyPriority {
  String get displayName {
    switch (this) {
      case CountyPriority.high:
        return 'High Priority';
      case CountyPriority.medium:
        return 'Medium Priority';
      case CountyPriority.low:
        return 'Low Priority';
    }
  }

  String get emoji {
    switch (this) {
      case CountyPriority.high:
        return '🔥';
      case CountyPriority.medium:
        return '⚡';
      case CountyPriority.low:
        return '💤';
    }
  }
}
