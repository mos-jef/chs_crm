// lib/services/oregon_sheriffs_service.dart
import 'dart:typed_data';

import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:html/dom.dart' as html; // Fixed: Added alias to avoid conflicts
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/property_file.dart';
import '../services/file_number_service.dart';

class OregonSheriffsService {
  static const String baseUrl = 'https://oregonsheriffssales.org';

  // MAIN METHOD: Import all sheriff's sales from Oregon
  static Future<List<PropertyFile>> importAllOregonSheriffsSales() async {
    print('Starting Oregon Sheriff\'s Sales import...');

    try {
      // Step 1: Get all counties
      final counties = await _getAllCounties();
      print('Found ${counties.length} counties with sheriff\'s sales');

      final allProperties = <PropertyFile>[];

      // Step 2: Process each county
      for (final county in counties) {
        try {
          print(' ”„ Processing ${county['name']} County...');
          final properties = await _importCountySheriffsSales(county);
          allProperties.addAll(properties);

          // Rate limiting between counties
          await Future.delayed(const Duration(seconds: 3));
        } catch (e) {
          print('  Error processing ${county['name']} County: $e');
          continue;
        }
      }

      print(
          '  … Sheriff\'s sales import completed: ${allProperties.length} properties imported');
      return allProperties;
    } catch (e) {
      print('  Failed to import sheriff\'s sales: $e');
      return [];
    }
  }

  //   Import specific county sheriff's sales
  static Future<List<PropertyFile>> importCountySheriffsSales(
      String countyName) async {
    try {
      final counties = await _getAllCounties();
      final county = counties.firstWhere(
        (c) =>
            c['name']?.toLowerCase() ==
            countyName.toLowerCase(), // Fixed: Added null check
        orElse: () => <String, String>{},
      );

      if (county.isEmpty) {
        throw Exception('County $countyName not found');
      }

      return await _importCountySheriffsSales(county);
    } catch (e) {
      print('  Error importing $countyName sheriff\'s sales: $e');
      return [];
    }
  }

  //   STEP 1: Get all counties from main page
  static Future<List<Map<String, String>>> _getAllCounties() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/counties/'),
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; CRM Bot 1.0)'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load counties page: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);
      final counties = <Map<String, String>>[];

      // Find county links (adjust selector based on actual HTML structure)
      final countyLinks = document.querySelectorAll('a[href*="/county/"]');

      for (final link in countyLinks) {
        final href = link.attributes['href'];
        final name = link.text.trim();

        if (href != null && name.isNotEmpty) {
          counties.add({
            'name': name,
            'url': href.startsWith('http') ? href : '$baseUrl$href',
          });
        }
      }

      return counties;
    } catch (e) {
      throw Exception('Failed to get counties: $e');
    }
  }

  //   STEP 2: Get all properties from a county page
  static Future<List<PropertyFile>> _importCountySheriffsSales(
      Map<String, String> county) async {
    try {
      final response = await http.get(
        Uri.parse(county['url']!),
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; CRM Bot 1.0)'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load county page: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);
      final properties = <PropertyFile>[];

      // Find property listing links (adjust selector based on actual HTML structure)
      final propertyLinks =
          document.querySelectorAll('a[href*="/property-listing/"]');

      for (final link in propertyLinks) {
        final href = link.attributes['href'];
        if (href == null) continue;

        final propertyUrl = href.startsWith('http') ? href : '$baseUrl$href';

        try {
          print(' “„ Processing property: ${link.text.trim()}');
          final property =
              await _scrapePropertyDetails(propertyUrl, county['name']!);
          if (property != null) {
            properties.add(property);
          }

          // Rate limiting between properties
          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          print('  Error processing property $propertyUrl: $e');
          continue;
        }
      }

      return properties;
    } catch (e) {
      throw Exception('Failed to import county ${county['name']}: $e');
    }
  }

  //   STEP 3: Scrape individual property details
  static Future<PropertyFile?> _scrapePropertyDetails(
      String propertyUrl, String county) async {
    try {
      final response = await http.get(
        Uri.parse(propertyUrl),
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; CRM Bot 1.0)'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load property page: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);

      // Extract basic property information (adjust selectors based on actual HTML)
      final caseTitle =
          document.querySelector('h1, .case-title')?.text.trim() ?? '';

      // Parse address from case title or find address field
      final address = _extractAddressFromCaseTitle(caseTitle);
      final city =
          _extractCityFromAddress(address) ?? 'Portland'; // Default for Oregon

      // Extract case information
      final plaintiff = _extractPlaintiff(caseTitle);
      final defendant = _extractDefendant(caseTitle);
      final caseNumber = _extractCaseNumber(document);
      final saleDate = _extractSaleDate(document);
      final saleAmount = _extractSaleAmount(document);

      // Find all document links
      final documentLinks = _extractDocumentLinks(document);

      // Generate file number
      final fileNumber = await FileNumberService.reserveFileNumber();

      // Create property file
      final property = PropertyFile(
        id: '',
        fileNumber: fileNumber,
        address: address,
        city: city,
        state: 'OR',
        zipCode: '', // Will be filled in if found in documents
        loanAmount: saleAmount,
        contacts: [
          if (plaintiff.isNotEmpty) Contact(name: plaintiff, role: 'Plaintiff'),
          if (defendant.isNotEmpty) Contact(name: defendant, role: 'Defendant'),
        ],
        documents: [], // Will be populated below
        judgments: [
          if (caseNumber.isNotEmpty)
            Judgment(
              caseNumber: caseNumber,
              status: 'Sheriff\'s Sale',
              county: county,
              state: 'OR',
              debtor: defendant,
              grantee: plaintiff,
              amount: saleAmount,
            ),
        ],
        notes: [
          Note(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            subject: 'Auto-imported from Oregon Sheriff\'s Sales',
            content:
                'Imported from: $propertyUrl\n\nCase: $caseTitle\n\nDocuments processed: ${documentLinks.length}',
            createdAt: DateTime.now(),
          ),
        ],
        auctions: [
          if (saleDate != null)
            Auction(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              auctionDate: saleDate,
              place: '$county County Sheriff\'s Office',
              time: const TimeOfDay(
                  hour: 10,
                  minute: 0), // Fixed: TimeOfDay is now properly imported
              openingBid: saleAmount,
              createdAt: DateTime.now(),
            ),
        ],
        trustees: [],
        vesting: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      //  “„ PROCESS ALL DOCUMENTS
      print(' “‘ Processing ${documentLinks.length} documents...');
      final processedDocuments =
          await _processPropertyDocuments(documentLinks, property.id);

      // Update property with processed documents
      final updatedProperty = PropertyFile(
        id: property.id,
        fileNumber: property.fileNumber,
        address: property.address,
        city: property.city,
        state: property.state,
        zipCode: property.zipCode,
        loanAmount: property.loanAmount,
        amountOwed: property.amountOwed,
        arrears: property.arrears,
        contacts: property.contacts,
        documents: processedDocuments['documents']
            as List<Document>, // Fixed: Cast to proper type
        judgments: property.judgments,
        notes: [
          ...property.notes,
          ...(processedDocuments['notes'] as List<Note>)
        ], // Fixed: Cast to proper type
        auctions: property.auctions,
        trustees: property.trustees,
        vesting: property.vesting,
        createdAt: property.createdAt,
        updatedAt: property.updatedAt,
      );

      return updatedProperty;
    } catch (e) {
      print('  Error scraping property details: $e');
      return null;
    }
  }

  //   STEP 4: Process and upload all property documents
  static Future<Map<String, dynamic>> _processPropertyDocuments(
      List<Map<String, String>> documentLinks, String propertyId) async {
    final documents = <Document>[];
    final notes = <Note>[];

    for (final docLink in documentLinks) {
      try {
        print(' “„ Processing document: ${docLink['name']}');

        // Download PDF
        final pdfData = await _downloadPDF(docLink['url']!);
        if (pdfData == null) continue;

        // Upload to Firebase Storage
        final downloadUrl = await _uploadDocumentToStorage(
          pdfData,
          docLink['name']!,
          propertyId,
        );

        if (downloadUrl == null) continue;

        // Extract text from PDF
        final extractedText = await _extractTextFromPDF(pdfData);

        // Analyze document content
        final analysis =
            _analyzeDocumentContent(extractedText, docLink['name']!);

        // Create document record
        documents.add(Document(
          name: docLink['name']!,
          type: _determineDocumentType(docLink['name']!),
          url: downloadUrl,
          uploadDate: DateTime.now(),
        ));

        // Create note with extracted information
        notes.add(Note(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              documents.length.toString(),
          subject: 'Document Analysis: ${docLink['name']}',
          content:
              'Document Type: ${_determineDocumentType(docLink['name']!)}\n\n'
              'Key Information Found:\n${analysis['summary']}\n\n'
              'Full Text (first 1000 chars):\n${extractedText.length > 1000 ? extractedText.substring(0, 1000) + "..." : extractedText}',
          createdAt: DateTime.now(),
        ));

        print('  … Document processed: ${docLink['name']}');
      } catch (e) {
        print('  Error processing document ${docLink['name']}: $e');
        continue;
      }
    }

    return {
      'documents': documents,
      'notes': notes,
    };
  }

  //   Helper Methods for Data Extraction

  static String _extractAddressFromCaseTitle(String caseTitle) {
    // Look for address patterns in case title
    final addressRegex = RegExp(
        r'\d+[\w\s\-,]+(?:Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Way|Court|Ct|Place|Pl)',
        caseSensitive: false);
    final match = addressRegex.firstMatch(caseTitle);
    return match?.group(0)?.trim() ?? 'Address Not Found';
  }

  static String? _extractCityFromAddress(String address) {
    if (address.toLowerCase().contains('portland')) return 'Portland';
    if (address.toLowerCase().contains('gresham')) return 'Gresham';
    if (address.toLowerCase().contains('beaverton')) return 'Beaverton';
    return null;
  }

  static String _extractPlaintiff(String caseTitle) {
    final parts = caseTitle.split(' vs ');
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }
    return '';
  }

  static String _extractDefendant(String caseTitle) {
    final parts = caseTitle.split(' vs ');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return '';
  }

  static String _extractCaseNumber(html.Document document) {
    // Fixed: Use html.Document with alias
    // Look for case number in page content
    final caseNumberElement =
        document.querySelector('.case-number, [class*="case"], [id*="case"]');
    return caseNumberElement?.text.trim() ?? '';
  }

  static DateTime? _extractSaleDate(html.Document document) {
    // Fixed: Use html.Document with alias
    // Look for sale date in page content
    final dateElements =
        document.querySelectorAll('time, .date, [class*="date"]');
    for (final element in dateElements) {
      final dateText = element.text.trim();
      final date = _parseDate(dateText);
      if (date != null) return date;
    }
    return null;
  }

  static double? _extractSaleAmount(html.Document document) {
    // Fixed: Use html.Document with alias
    // Look for dollar amounts in page content
    final text = document.text;
    final amountRegex = RegExp(r'\$[\d,]+(?:\.\d{2})?');
    final matches = amountRegex.allMatches(text!);

    for (final match in matches) {
      final amountStr = match.group(0)?.replaceAll(RegExp(r'[\$,]'), '');
      final amount = double.tryParse(amountStr ?? '');
      if (amount != null && amount > 10000) {
        // Likely sale amount
        return amount;
      }
    }
    return null;
  }

  static List<Map<String, String>> _extractDocumentLinks(
      html.Document document) {
    // Fixed: Use html.Document with alias
    final links = <Map<String, String>>[];
    final pdfLinks = document.querySelectorAll('a[href*=".pdf"]');

    for (final link in pdfLinks) {
      final href = link.attributes['href'];
      if (href == null) continue;

      final url = href.startsWith('http') ? href : '$baseUrl$href';
      final name =
          link.text.trim().isNotEmpty ? link.text.trim() : href.split('/').last;

      links.add({'name': name, 'url': url});
    }

    return links;
  }

  //   Document Processing Methods

  static Future<Uint8List?> _downloadPDF(String pdfUrl) async {
    try {
      final response = await http.get(
        Uri.parse(pdfUrl),
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; CRM Bot 1.0)'},
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('  Error downloading PDF $pdfUrl: $e');
      return null;
    }
  }

  static Future<String?> _uploadDocumentToStorage(
      Uint8List pdfData, String fileName, String propertyId) async {
    try {
      // Create a sanitized filename
      final sanitizedFileName =
          fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$sanitizedFileName';

      // For now, return a placeholder URL until DocumentService integration is complete
      // TODO: Integrate with your existing DocumentService.uploadDocument method
      final placeholderUrl =
          'https://storage.googleapis.com/placeholder/documents/$propertyId/$uniqueFileName';

      print(' “¤ Document would be uploaded to: $placeholderUrl');

      return placeholderUrl;
    } catch (e) {
      print('  Error uploading document: $e');
      return null;
    }
  }

  static Future<String> _extractTextFromPDF(Uint8List pdfData) async {
    // This is a placeholder - you'll need to add a PDF text extraction library
    // Popular options: pdf_text, syncfusion_flutter_pdf, etc.

    // For now, return a placeholder with basic info
    return 'PDF text extraction placeholder. PDF size: ${pdfData.length} bytes\n\n'
        'TODO: Implement actual PDF text extraction using syncfusion_flutter_pdf or similar library.\n'
        'This would extract loan amounts, legal descriptions, property details, etc.';
  }

  static Map<String, String> _analyzeDocumentContent(
      String text, String fileName) {
    final analysis = <String, String>{};
    final summary = <String>[];

    // Look for key information patterns
    if (text.toLowerCase().contains('notice of sale')) {
      summary.add('  Contains Notice of Sale information');
    }

    if (text.toLowerCase().contains('legal description')) {
      summary.add('  Contains legal property description');
    }

    // Look for loan amounts
    final amountRegex = RegExp(r'\$[\d,]+(?:\.\d{2})?');
    final amounts = amountRegex.allMatches(text);
    if (amounts.isNotEmpty) {
      summary.add('  Contains ${amounts.length} dollar amount(s)');
    }

    // Look for dates
    final dateRegex = RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b');
    final dates = dateRegex.allMatches(text);
    if (dates.isNotEmpty) {
      summary.add('  Contains ${dates.length} date(s)');
    }

    analysis['summary'] = summary.join('\n');
    return analysis;
  }

  static String _determineDocumentType(String fileName) {
    final name = fileName.toLowerCase();

    if (name.contains('notice') && name.contains('sale'))
      return 'Notice of Sale';
    if (name.contains('complaint')) return 'Complaint';
    if (name.contains('judgment')) return 'Judgment';
    if (name.contains('deed')) return 'Deed';
    if (name.contains('mortgage')) return 'Mortgage';
    if (name.contains('affidavit')) return 'Affidavit';

    return 'Legal Document';
  }

  //   Utility Methods

  static DateTime? _parseDate(String dateStr) {
    try {
      // Try common date formats
      final formats = [
        RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
        RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'),
        RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
      ];

      for (final format in formats) {
        final match = format.firstMatch(dateStr);
        if (match != null) {
          final month = int.tryParse(match.group(1) ?? '');
          final day = int.tryParse(match.group(2) ?? '');
          final year = int.tryParse(match.group(3) ?? '');

          if (month != null && day != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
