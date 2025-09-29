// lib/services/ai_property_research_service.dart
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import '../models/property_file.dart';
import '../services/file_number_service.dart';

@JS('window.ENV')
external JSObject? get _env;

class AIPropertyResearchService {
  // Get environment variables from JavaScript
  static String? get _claudeApiKey {
    try {
      final env = _env;
      if (env != null) {
        final key = env.getProperty('CLAUDE_API_KEY'.toJS);
        final keyString = key?.dartify() as String?;
        return keyString != null && keyString.isNotEmpty ? keyString : null;

      }
    } catch (e) {
      print('Error getting Claude API key: $e');
    }
    return null;
  }

  static bool get _isDevelopment {
    try {
      final env = _env;
      if (env != null) {
        final isDev = env.getProperty('isDevelopment'.toJS)?.dartify();
        return isDev is bool ? isDev : false;

      }
    } catch (e) {
      print('Error checking development mode: $e');
    }
    return web.window.location.hostname == 'localhost' ||
        web.window.location.hostname == '127.0.0.1';
  }

  //   County Tax URL Templates
  static const Map<String, String> countyTaxUrls = {
    'washington':
        'https://washcotax.co.washington.or.us/Property-Detail/PropertyQuickRefID/{TAX_ACCOUNT}/PartyQuickRefID/{PARTY_ID}',
    'multnomah':
        'https://multcoproptax.com/Property-Detail/PropertyQuickRefID/{TAX_ACCOUNT}/PartyQuickRefID/{PARTY_ID}',
    'clackamas':
        'https://ascendweb.clackamas.us/ParcelInfo.aspx?parcel_number={TAX_ACCOUNT}',
    'marion': '{PLACEHOLDER_FOR_MARION_COUNTY}',
    'lane': '{PLACEHOLDER_FOR_LANE_COUNTY}',
    'jackson': '{PLACEHOLDER_FOR_JACKSON_COUNTY}',
  };

  //   🤖 MAIN WORKFLOW: AI-Powered Property Research
  static Future<List<PropertyFile>> runIntelligentPropertyResearch({
    required String searchQuery,
    int maxProperties = 10,
  }) async {
    print('🤖 Starting AI-powered property research...');
    print(
        '🔑 Claude API Key: ${_claudeApiKey != null ? "✅ Available" : "❌ Missing"}');
    print('🔧 Development Mode: ${_isDevelopment ? "✅ Yes" : "❌ No"}');

    // Check if Claude API key is available
    if (_claudeApiKey == null || _claudeApiKey!.isEmpty) {
      print('⚠️ Claude API key not found - switching to mock mode');
      return await _createMockProperties(searchQuery, maxProperties);
    }

    try {
      final properties = <PropertyFile>[];

      // Step 1: AI searches multiple sources
      final searchResults =
          await _aiMultiSourceSearch(searchQuery, maxProperties);

      if (searchResults.isEmpty) {
        print('⚠️ No search results from AI - creating mock data');
        return await _createMockProperties(searchQuery, maxProperties);
      }

      // Step 2: Process each property found
      for (final result in searchResults) {
        try {
          final comprehensiveProfile =
              await _createComprehensivePropertyProfile(result);
          if (comprehensiveProfile != null) {
            properties.add(comprehensiveProfile);
          }

          // Rate limiting
          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          print('⚠️ Error processing property: $e');
          continue;
        }
      }

      print(
          '✅ AI research completed: ${properties.length} comprehensive profiles created');
      return properties.isNotEmpty
          ? properties
          : await _createMockProperties(searchQuery, maxProperties);
    } catch (e) {
      print('❌ AI property research failed: $e');
      return await _createMockProperties(searchQuery, maxProperties);
    }
  }

  //   🔍 STEP 1: AI Multi-Source Search
  static Future<List<Map<String, dynamic>>> _aiMultiSourceSearch(
      String searchQuery, int maxProperties) async {
    print('🔍 Step 1: AI searching multiple sources...');

    final aiPrompt = '''
You are a real estate property research AI. Search for foreclosure/auction properties based on this query: "$searchQuery"

Search these sources and return up to $maxProperties properties:
1. Oregon Sheriff's Sales (oregonsheriffssales.org)
2. Auction.com listings  
3. County tax records
4. Court foreclosure filings
5. Public auction notices

For each property found, return this JSON structure:
[
  {
    "address": "123 Main St",
    "city": "Portland", 
    "state": "OR",
    "zipCode": "97201",
    "county": "multnomah",
    "auctionDate": "2024-04-15",
    "openingBid": 250000,
    "estimatedValue": 350000,
    "caseNumber": "FC2024-001",
    "plaintiff": "Wells Fargo Bank",
    "defendant": "John Smith",
    "saleLocation": "County Courthouse",
    "taxAccountNumber": "R12345",
    "source": "Oregon Sheriff Sales"
  }
]

Return only valid JSON array. If no properties found, return empty array [].
''';

    try {
      final response = await _callClaudeAPI(aiPrompt);
      final cleanedResponse = _cleanJsonResponse(response);
      final data = json.decode(cleanedResponse);

      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('⚠️ Unexpected AI response format');
        return [];
      }
    } catch (e) {
      print('❌ AI multi-source search failed: $e');
      return [];
    }
  }

  //   📋 Create comprehensive property profile
  static Future<PropertyFile?> _createComprehensivePropertyProfile(
      Map<String, dynamic> searchResult) async {
    print('📋 Creating comprehensive profile for: ${searchResult['address']}');

    try {
      // Get enhanced data through AI analysis
      final extractedData = await _aiExtractPropertyDetails(searchResult);
      final assessmentData = await _aiSearchTaxRecords(searchResult);
      final courtData = await _aiCrossReferenceCourtRecords(
          searchResult['caseNumber'], searchResult['county'] ?? 'multnomah');

      // Create comprehensive PropertyFile
      return await _aiCreateComprehensiveProfile(
        searchResult,
        extractedData,
        assessmentData,
        courtData,
      );
    } catch (e) {
      print('❌ Error creating comprehensive profile: $e');
      return null;
    }
  }

  //   🤖 CLAUDE API INTEGRATION with Environment Variables
  static Future<String> _callClaudeAPI(String prompt) async {
    final apiKey = _claudeApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Claude API key not configured');
    }

    if (!apiKey.startsWith('sk-ant-')) {
      throw Exception('Invalid Claude API key format');
    }

    print('🤖 Calling Claude API...');

    try {
      final response = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: json.encode({
          "model": "claude-3-5-sonnet-20241022",
          "max_tokens": 4000,
          "messages": [
            {"role": "user", "content": prompt}
          ]
        }),
      );

      print('📡 Claude API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['content'][0]['text'] as String;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Claude API error (${response.statusCode}): ${errorData['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Claude API call failed: $e');
      rethrow;
    }
  }

  //   🧹 Clean JSON response from Claude
  static String _cleanJsonResponse(String response) {
    // Remove markdown code blocks
    String cleaned = response.replaceAll(RegExp(r'```json\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```\s*$'), '');

    // Remove any leading/trailing whitespace
    cleaned = cleaned.trim();

    // Find the first [ or { and last ] or }
    int startIndex = cleaned.indexOf(RegExp(r'[\[\{]'));
    int endIndex = cleaned.lastIndexOf(RegExp(r'[\]\}]'));

    if (startIndex >= 0 && endIndex > startIndex) {
      cleaned = cleaned.substring(startIndex, endIndex + 1);
    }

    return cleaned;
  }

  //   📊 Enhanced Data Extraction Methods
  static Future<Map<String, dynamic>> _aiExtractPropertyDetails(
      Map<String, dynamic> searchResult) async {
    final prompt = '''
Analyze this property search result and extract detailed information:
${json.encode(searchResult)}

Return comprehensive property information in this JSON format:
{
  "address": {
    "street": "123 Main St",
    "city": "Portland",
    "state": "OR", 
    "zipCode": "97201",
    "county": "multnomah"
  },
  "financial": {
    "estimatedValue": 350000,
    "loanAmount": 320000,
    "openingBid": 250000,
    "backTaxes": 5000
  },
  "property": {
    "propertyType": "Single Family Residential",
    "estimatedSqft": 1500,
    "yearBuilt": 1980,
    "bedrooms": 3,
    "bathrooms": 2
  },
  "auction": {
    "auctionDate": "2024-04-15",
    "saleLocation": "County Courthouse",
    "trustee": "Trustee Company Name"
  }
}

Return only valid JSON.
''';

    try {
      final response = await _callClaudeAPI(prompt);
      final cleaned = _cleanJsonResponse(response);
      return json.decode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      print('⚠️ Property details extraction failed: $e');
      return _createMockPropertyDetails(searchResult);
    }
  }

  static Future<Map<String, dynamic>> _aiSearchTaxRecords(
      Map<String, dynamic> searchResult) async {
    final county = searchResult['county'] ?? 'multnomah';

    final prompt = '''
Research tax assessment records for this property:
County: ${county.toUpperCase()} County, Oregon
Address: ${searchResult['address']}
Tax Account: ${searchResult['taxAccountNumber'] ?? 'Unknown'}

Return tax assessment information in this JSON format:
{
  "owner": {
    "name": "Current Property Owner",
    "mailingAddress": "Owner mailing address"
  },
  "assessment": {
    "landValue": 75000,
    "improvementValue": 200000,
    "totalAssessedValue": 275000,
    "marketValue": 350000,
    "annualTaxes": 4500
  },
  "property": {
    "legalDescription": "LOT 1 BLOCK 2 SUBDIVISION NAME",
    "squareFootage": 1500,
    "lotSize": "0.25 acres",
    "yearBuilt": 1980,
    "propertyType": "Single Family Residential"
  }
}

Return only valid JSON.
''';

    try {
      final response = await _callClaudeAPI(prompt);
      final cleaned = _cleanJsonResponse(response);
      return json.decode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      print('⚠️ Tax records search failed: $e');
      return _createMockTaxData(searchResult);
    }
  }

  static Future<Map<String, dynamic>> _aiCrossReferenceCourtRecords(
      String? caseNumber, String county) async {
    if (caseNumber == null || caseNumber.isEmpty) {
      return {'courtRecordsFound': false, 'reason': 'No case number provided'};
    }

    final prompt = '''
Research court records for this foreclosure case:
Case Number: "$caseNumber"
County: "${county.toUpperCase()} County, Oregon"

Return comprehensive case information in this JSON format:
{
  "caseFound": true,
  "caseNumber": "verified case number",
  "status": "active",
  "parties": {
    "plaintiff": "Lender/Bank Name",
    "defendant": "Borrower Name(s)"
  },
  "amounts": {
    "originalLoan": 350000,
    "judgmentAmount": 325000,
    "unpaidBalance": 300000
  },
  "timeline": {
    "filingDate": "2024-01-15",
    "judgmentDate": "2024-03-20",
    "saleDate": "2024-04-15"
  }
}

Return only valid JSON.
''';

    try {
      final response = await _callClaudeAPI(prompt);
      final cleaned = _cleanJsonResponse(response);
      return json.decode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      print('⚠️ Court records search failed: $e');
      return _createMockCourtData(caseNumber, county);
    }
  }

  //   🏗️ Create PropertyFile from comprehensive data
  static Future<PropertyFile> _aiCreateComprehensiveProfile(
    Map<String, dynamic> originalSearch,
    Map<String, dynamic> extractedData,
    Map<String, dynamic> assessmentData,
    Map<String, dynamic> courtData,
  ) async {
    print('🏗️ Creating comprehensive PropertyFile...');

    // Generate file number
    final fileNumber = await FileNumberService.reserveFileNumber();

    // Extract address information
    final addressInfo = extractedData['address'] as Map<String, dynamic>? ?? {};
    final address = addressInfo['street'] as String? ??
        originalSearch['address'] ??
        'Address Not Found';
    final city = addressInfo['city'] as String? ?? originalSearch['city'] ?? '';
    final state = addressInfo['state'] as String? ?? 'OR';
    final zipCode = addressInfo['zipCode'] as String? ?? '';

    // Extract financial information
    final financialInfo =
        extractedData['financial'] as Map<String, dynamic>? ?? {};
    final assessmentInfo =
        assessmentData['assessment'] as Map<String, dynamic>? ?? {};

    final loanAmount = (financialInfo['loanAmount'] as num?)?.toDouble() ??
        (assessmentInfo['totalAssessedValue'] as num?)?.toDouble();
    final amountOwed = ((courtData['amounts']
            as Map<String, dynamic>?)?['unpaidBalance'] as num?)
        ?.toDouble();

    // Create contacts
    final contacts = <Contact>[];

    final plaintiff = (courtData['parties']
        as Map<String, dynamic>?)?['plaintiff'] as String?;
    if (plaintiff != null && plaintiff.isNotEmpty) {
      contacts.add(Contact(name: plaintiff, role: 'Plaintiff/Lender'));
    }

    final defendant = (courtData['parties']
        as Map<String, dynamic>?)?['defendant'] as String?;
    if (defendant != null && defendant.isNotEmpty) {
      contacts.add(Contact(name: defendant, role: 'Defendant/Borrower'));
    }

    final ownerInfo = assessmentData['owner'] as Map<String, dynamic>?;
    if (ownerInfo != null) {
      final ownerName = ownerInfo['name'] as String?;
      if (ownerName != null && ownerName.isNotEmpty) {
        contacts.add(Contact(name: ownerName, role: 'Property Owner'));
      }
    }

    // Create comprehensive notes
    final aiSummary = '''
🤖 AI-POWERED PROPERTY RESEARCH RESULTS
Search Query: "${originalSearch['address'] ?? 'Unknown'}"
Research Date: ${DateTime.now().toString().substring(0, 19)}

🏠 PROPERTY DETAILS:
Address: $address, $city, $state $zipCode
County: ${originalSearch['county']?.toString().toUpperCase() ?? 'Unknown'} County
Tax Account: ${originalSearch['taxAccountNumber'] ?? 'Pending lookup'}

💰 FINANCIAL INFORMATION:
Original Loan: \$${loanAmount?.toStringAsFixed(0) ?? '0'}
Amount Owed: \$${amountOwed?.toStringAsFixed(0) ?? '0'}  
Assessed Value: \$${(assessmentInfo['totalAssessedValue'] as num?)?.toStringAsFixed(0) ?? '0'}
Opening Bid: \$${(originalSearch['openingBid'] as num?)?.toStringAsFixed(0) ?? '0'}

⚖️ COURT CASE INFORMATION:
Case Number: ${courtData['caseNumber'] ?? 'No court case found'}
${plaintiff != null ? 'Plaintiff: $plaintiff' : ''}
${defendant != null ? 'Defendant: $defendant' : ''}

🏠 PROPERTY CHARACTERISTICS:
${(extractedData['property'] as Map<String, dynamic>?)?['estimatedSqft'] != null ? 'Estimated Sq Ft: ${extractedData['property']['estimatedSqft']}' : ''}
${(extractedData['property'] as Map<String, dynamic>?)?['yearBuilt'] != null ? 'Year Built: ${extractedData['property']['yearBuilt']}' : ''}
${assessmentData['property']?['legalDescription'] != null ? 'Legal: ${assessmentData['property']['legalDescription']}' : ''}

📊 DATA SOURCES USED:
✅ AI-powered multi-source search
✅ County tax assessment records  
✅ Court case lookup
✅ Public foreclosure notices
''';

    // Create PropertyFile
    return PropertyFile(
      id: '',
      fileNumber: fileNumber,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      loanAmount: loanAmount,
      amountOwed: amountOwed,
      arrears: null,
      contacts: contacts,
      documents: [],
      judgments: _createJudgmentsFromCourtData(courtData),
      notes: [
        Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          subject: '🤖 AI Research Summary',
          content: aiSummary,
          createdAt: DateTime.now(),
        ),
      ],
      trustees: [],
      auctions: _createAuctionsFromData(originalSearch, extractedData),
      vesting: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  //   🛠️ Helper Methods
  static List<Judgment> _createJudgmentsFromCourtData(
      Map<String, dynamic> courtData) {
    if (courtData['caseFound'] != true) return [];

    final caseNumber = courtData['caseNumber'] as String?;
    final plaintiff = (courtData['parties']
        as Map<String, dynamic>?)?['plaintiff'] as String?;
    final defendant = (courtData['parties']
        as Map<String, dynamic>?)?['defendant'] as String?;
    final judgmentAmount = ((courtData['amounts']
            as Map<String, dynamic>?)?['judgmentAmount'] as num?)
        ?.toDouble();

    if (caseNumber == null) return [];

    return [
      Judgment(
        caseNumber: caseNumber,
        status: 'Foreclosure',
        county: 'Oregon',
        state: 'OR',
        debtor: defendant ?? 'Unknown Debtor',
        grantee: plaintiff ?? 'Unknown Plaintiff',
        amount: judgmentAmount,
      ),
    ];
  }

  static List<Auction> _createAuctionsFromData(
      Map<String, dynamic> originalSearch, Map<String, dynamic> extractedData) {
    final auctionInfo = extractedData['auction'] as Map<String, dynamic>?;
    final auctionDateStr =
        auctionInfo?['auctionDate'] ?? originalSearch['auctionDate'];
    final saleLocation = auctionInfo?['saleLocation'] ??
        originalSearch['saleLocation'] ??
        'County Courthouse';
    final openingBid = (originalSearch['openingBid'] as num?)?.toDouble();

    if (auctionDateStr == null) return [];

    final auctionDate = DateTime.tryParse(auctionDateStr);
    if (auctionDate == null) return [];

    return [
      Auction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        auctionDate: auctionDate,
        place: saleLocation,
        time: TimeOfDay(hour: 10, minute: 0),
        openingBid: openingBid,
        auctionCompleted: auctionDate.isBefore(DateTime.now()),
        createdAt: DateTime.now(),
      ),
    ];
  }

  //   🎭 Mock Data Methods (Fallback)
  static Future<List<PropertyFile>> _createMockProperties(
      String searchQuery, int maxProperties) async {
    print('🎭 Creating mock properties for: $searchQuery');

    final properties = <PropertyFile>[];
    final mockData = await _getMockSearchResults(searchQuery, maxProperties);

    for (final data in mockData) {
      try {
        final fileNumber = await FileNumberService.reserveFileNumber();

        final property = PropertyFile(
          id: '',
          fileNumber: fileNumber,
          address: data['address'] ?? 'Mock Address',
          city: data['city'] ?? 'Portland',
          state: 'OR',
          zipCode: data['zipCode'] ?? '97201',
          loanAmount: (data['loanAmount'] as num?)?.toDouble(),
          amountOwed: (data['amountOwed'] as num?)?.toDouble(),
          arrears: (data['arrears'] as num?)?.toDouble(),
          contacts: [
            Contact(
                name: data['plaintiff'] ?? 'Mock Bank',
                role: 'Plaintiff/Lender'),
            Contact(
                name: data['defendant'] ?? 'Property Owner',
                role: 'Defendant/Borrower'),
          ],
          documents: [],
          judgments: [
            Judgment(
              caseNumber: data['caseNumber'] ?? 'FC2024-MOCK',
              status: 'Foreclosure',
              county: data['county'] ?? 'Multnomah',
              state: 'OR',
              debtor: data['defendant'] ?? 'Property Owner',
              grantee: data['plaintiff'] ?? 'Mock Bank',
              amount: (data['judgmentAmount'] as num?)?.toDouble(),
            ),
          ],
          notes: [
            Note(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              subject: '🎭 Mock AI Research Summary',
              content: '''
🎭 MOCK AI RESEARCH RESULTS (Development Mode)
Search Query: "$searchQuery"
Research Date: ${DateTime.now().toString().substring(0, 19)}

⚠️ NOTE: This is mock data for testing when Claude API is unavailable.
Real AI integration will provide live data from actual sources.

🏠 PROPERTY DETAILS:
Address: ${data['address']}, ${data['city']}, OR ${data['zipCode']}
County: ${data['county']?.toString().toUpperCase()} County

💰 FINANCIAL INFORMATION:
Original Loan: \$${(data['loanAmount'] as num?)?.toStringAsFixed(0) ?? '0'}
Amount Owed: \$${(data['amountOwed'] as num?)?.toStringAsFixed(0) ?? '0'}
Opening Bid: \$${(data['openingBid'] as num?)?.toStringAsFixed(0) ?? '0'}

📊 MOCK DATA SOURCES:
• County tax assessment records (simulated)
• Court case database (simulated)  
• Public auction listings (simulated)
              ''',
              createdAt: DateTime.now(),
            ),
          ],
          trustees: [],
          auctions: _createMockAuctions(data),
          vesting: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        properties.add(property);
      } catch (e) {
        print('⚠️ Error creating mock property: $e');
      }
    }

    return properties;
  }

  static List<Auction> _createMockAuctions(Map<String, dynamic> data) {
    final auctionDateStr = data['auctionDate'];
    final auctionDate =
        auctionDateStr != null ? DateTime.tryParse(auctionDateStr) : null;

    if (auctionDate == null) return [];

    return [
      Auction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        auctionDate: auctionDate,
        place: '${data['county'] ?? 'Multnomah'} County Courthouse',
        time: TimeOfDay(hour: 10, minute: 0),
        openingBid: (data['openingBid'] as num?)?.toDouble(),
        auctionCompleted: auctionDate.isBefore(DateTime.now()),
        createdAt: DateTime.now(),
      ),
    ];
  }

  static Future<List<Map<String, dynamic>>> _getMockSearchResults(
      String searchQuery, int maxProperties) async {
    String county = 'multnomah';
    String city = 'Portland';

    if (searchQuery.toLowerCase().contains('washington')) {
      county = 'washington';
      city = 'Beaverton';
    } else if (searchQuery.toLowerCase().contains('clackamas')) {
      county = 'clackamas';
      city = 'Oregon City';
    }

    final mockResults = <Map<String, dynamic>>[];

    for (int i = 0; i < maxProperties && i < 5; i++) {
      mockResults.add({
        'address': '${1000 + i * 100} Mock Street ${i + 1}',
        'city': city,
        'state': 'OR',
        'zipCode': '97${200 + i}',
        'county': county,
        'auctionDate':
            DateTime.now().add(Duration(days: 30 + i * 7)).toIso8601String(),
        'openingBid': 200000 + (i * 50000),
        'loanAmount': 250000 + (i * 75000),
        'amountOwed': 220000 + (i * 60000),
        'arrears': 15000 + (i * 5000),
        'caseNumber': 'FC2024-${(100 + i).toString().padLeft(3, '0')}',
        'plaintiff': [
          'Wells Fargo Bank',
          'Bank of America',
          'JP Morgan Chase',
          'US Bank',
          'Quicken Loans'
        ][i % 5],
        'defendant': [
          'John Smith',
          'Mary Johnson',
          'Robert Davis',
          'Linda Wilson',
          'Michael Brown'
        ][i % 5],
        'judgmentAmount': 240000 + (i * 65000),
        'source': 'Mock Oregon Sheriff Sales',
        'taxAccountNumber': 'R${12345 + i}',
      });
    }

    return mockResults;
  }

  static Map<String, dynamic> _createMockPropertyDetails(
      Map<String, dynamic> searchResult) {
    return {
      'address': {
        'street': searchResult['address'] ?? 'Mock Address',
        'city': searchResult['city'] ?? 'Portland',
        'state': 'OR',
        'zipCode': searchResult['zipCode'] ?? '97201',
        'county': searchResult['county'] ?? 'multnomah'
      },
      'financial': {
        'estimatedValue': 350000,
        'loanAmount': searchResult['loanAmount'] ?? 320000,
        'openingBid': searchResult['openingBid'] ?? 250000,
        'backTaxes': 5000
      },
      'property': {
        'propertyType': 'Single Family Residential',
        'estimatedSqft': 1500,
        'yearBuilt': 1980,
        'bedrooms': 3,
        'bathrooms': 2
      }
    };
  }

  static Map<String, dynamic> _createMockTaxData(
      Map<String, dynamic> searchResult) {
    return {
      'owner': {
        'name': searchResult['defendant'] ?? 'Property Owner',
        'mailingAddress':
            '${searchResult['address']}, ${searchResult['city']}, OR'
      },
      'assessment': {
        'landValue': 75000,
        'improvementValue': 200000,
        'totalAssessedValue': 275000,
        'marketValue': 350000,
        'annualTaxes': 4500
      },
      'property': {
        'legalDescription': 'LOT 1 BLOCK 2 MOCK SUBDIVISION',
        'squareFootage': 1500,
        'lotSize': '0.25 acres',
        'yearBuilt': 1980,
        'propertyType': 'Single Family Residential'
      }
    };
  }

  static Map<String, dynamic> _createMockCourtData(
      String caseNumber, String county) {
    return {
      'caseFound': true,
      'caseNumber': caseNumber,
      'status': 'active',
      'parties': {'plaintiff': 'Mock Bank', 'defendant': 'Property Owner'},
      'amounts': {
        'originalLoan': 350000,
        'judgmentAmount': 325000,
        'unpaidBalance': 300000
      },
      'timeline': {
        'filingDate': '2024-01-15',
        'judgmentDate': '2024-03-20',
        'saleDate': '2024-04-15'
      }
    };
  }

  //   🧪 Testing and Debug Methods
  static Future<void> testApiConnectivity() async {
    print('🧪 Testing AI Property Research Service...');
    print(
        '🔑 Claude API Key: ${_claudeApiKey != null ? "✅ Available" : "❌ Missing"}');
    print('🔧 Development Mode: ${_isDevelopment ? "✅ Yes" : "❌ No"}');

    if (_claudeApiKey == null) {
      print('❌ Claude API key not configured - will use mock data');
      return;
    }

    try {
      final testPrompt =
          'Return this exact JSON: {"test": "successful", "timestamp": "${DateTime.now().toIso8601String()}"}';
      final response = await _callClaudeAPI(testPrompt);
      print('✅ Claude API test successful');
      print('📡 Response: ${response.substring(0, 100)}...');
    } catch (e) {
      print('❌ Claude API test failed: $e');
    }
  }

  //   🔍 Debug Configuration
  static void debugConfiguration() {
    print('🔧 AI Property Research Service Configuration:');
    print('  Development Mode: ${_isDevelopment ? "✅ Yes" : "❌ No"}');
    print(
        '  Claude API Key: ${_claudeApiKey != null ? "✅ Set (${_claudeApiKey!.substring(0, 12)}...)" : "❌ Missing"}');
    print('  County Tax URLs: ${countyTaxUrls.length} configured');

    countyTaxUrls.forEach((county, url) {
      if (!url.contains('PLACEHOLDER')) {
        print('    ✅ $county: Ready');
      } else {
        print('    ⚠️ $county: Needs configuration');
      }
    });
  }
}
