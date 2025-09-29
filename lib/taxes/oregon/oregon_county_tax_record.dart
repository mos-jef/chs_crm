// lib/taxes/oregon/oregon_county_tax_record.dart
import 'package:chs_crm/models/property_file.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html;

/// Comprehensive tax record model for Oregon county property data
/// Designed to accommodate varying data availability across all 36 Oregon counties
class OregonCountyTaxRecord {
  // Basic Property Information
  final String propertyId; // Tax account number (e.g., "R143089")
  final String alternateAccountNumber; // Secondary ID if available
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String county;

  // Owner Information
  final String? ownerName;
  final String? mailingAddress;
  final String? mailingCity;
  final String? mailingState;
  final String? mailingZipCode;

  // Property Details
  final String? legalDescription;
  final String? neighborhood;
  final String? mapNumber;
  final String? propertyType;
  final String? propertyUse;
  final String? propertyStatus;
  final int? yearBuilt;
  final double? lotSizeAcres;
  final double? lotSizeSquareFeet;
  final int? bedrooms;
  final int? bathrooms;
  final int? squareFootage;

  // Current Tax Values (2024)
  final double? assessedValue; // Current assessed value
  final double? marketValue; // Real market value (RMV)
  final double? landValue; // Land portion only
  final double? improvementValue; // Buildings/improvements only
  final double? exemptions; // Total exemptions
  final double? specialAssessments; // Special assessments

  // Tax Information
  final double? currentYearTaxes; // Current year tax amount
  final double? totalTaxesDue; // Any unpaid taxes
  final bool? taxesCurrent; // Are taxes up to date?
  final DateTime? lastPaymentDate;
  final String? taxStatus;

  // Historical Assessment Data (last 5 years)
  final List<AssessmentYear>? historicalAssessments;

  // Sales History
  final List<PropertySale>? salesHistory;

  // Tax Payment History
  final List<TaxPayment>? paymentHistory;

  // Building/Improvement Details
  final List<BuildingInfo>? buildings;

  // Land Segments
  final List<LandSegment>? landSegments;

  // Source and Metadata
  final String sourceCounty;
  final String sourceUrl;
  final DateTime retrievedAt;
  final Map<String, dynamic>? rawData; // Store original parsed data

  OregonCountyTaxRecord({
    required this.propertyId,
    this.alternateAccountNumber = '',
    required this.address,
    this.city = '',
    this.state = 'OR',
    this.zipCode = '',
    required this.county,
    this.ownerName,
    this.mailingAddress,
    this.mailingCity,
    this.mailingState,
    this.mailingZipCode,
    this.legalDescription,
    this.neighborhood,
    this.mapNumber,
    this.propertyType,
    this.propertyUse,
    this.propertyStatus,
    this.yearBuilt,
    this.lotSizeAcres,
    this.lotSizeSquareFeet,
    this.bedrooms,
    this.bathrooms,
    this.squareFootage,
    this.assessedValue,
    this.marketValue,
    this.landValue,
    this.improvementValue,
    this.exemptions,
    this.specialAssessments,
    this.currentYearTaxes,
    this.totalTaxesDue,
    this.taxesCurrent,
    this.lastPaymentDate,
    this.taxStatus,
    this.historicalAssessments,
    this.salesHistory,
    this.paymentHistory,
    this.buildings,
    this.landSegments,
    required this.sourceCounty,
    required this.sourceUrl,
    required this.retrievedAt,
    this.rawData,
  });

  /// Convert to JSON for storage/serialization
  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'alternateAccountNumber': alternateAccountNumber,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'county': county,
      'ownerName': ownerName,
      'mailingAddress': mailingAddress,
      'mailingCity': mailingCity,
      'mailingState': mailingState,
      'mailingZipCode': mailingZipCode,
      'legalDescription': legalDescription,
      'neighborhood': neighborhood,
      'mapNumber': mapNumber,
      'propertyType': propertyType,
      'propertyUse': propertyUse,
      'propertyStatus': propertyStatus,
      'yearBuilt': yearBuilt,
      'lotSizeAcres': lotSizeAcres,
      'lotSizeSquareFeet': lotSizeSquareFeet,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFootage': squareFootage,
      'assessedValue': assessedValue,
      'marketValue': marketValue,
      'landValue': landValue,
      'improvementValue': improvementValue,
      'exemptions': exemptions,
      'specialAssessments': specialAssessments,
      'currentYearTaxes': currentYearTaxes,
      'totalTaxesDue': totalTaxesDue,
      'taxesCurrent': taxesCurrent,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'taxStatus': taxStatus,
      'historicalAssessments':
          historicalAssessments?.map((a) => a.toJson()).toList(),
      'salesHistory': salesHistory?.map((s) => s.toJson()).toList(),
      'paymentHistory': paymentHistory?.map((p) => p.toJson()).toList(),
      'buildings': buildings?.map((b) => b.toJson()).toList(),
      'landSegments': landSegments?.map((l) => l.toJson()).toList(),
      'sourceCounty': sourceCounty,
      'sourceUrl': sourceUrl,
      'retrievedAt': retrievedAt.toIso8601String(),
      'rawData': rawData,
    };
  }

  /// Create from JSON
  factory OregonCountyTaxRecord.fromJson(Map<String, dynamic> json) {
    return OregonCountyTaxRecord(
      propertyId: json['propertyId'] ?? '',
      alternateAccountNumber: json['alternateAccountNumber'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? 'OR',
      zipCode: json['zipCode'] ?? '',
      county: json['county'] ?? '',
      ownerName: json['ownerName'],
      mailingAddress: json['mailingAddress'],
      mailingCity: json['mailingCity'],
      mailingState: json['mailingState'],
      mailingZipCode: json['mailingZipCode'],
      legalDescription: json['legalDescription'],
      neighborhood: json['neighborhood'],
      mapNumber: json['mapNumber'],
      propertyType: json['propertyType'],
      propertyUse: json['propertyUse'],
      propertyStatus: json['propertyStatus'],
      yearBuilt: json['yearBuilt'],
      lotSizeAcres: json['lotSizeAcres']?.toDouble(),
      lotSizeSquareFeet: json['lotSizeSquareFeet']?.toDouble(),
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      squareFootage: json['squareFootage'],
      assessedValue: json['assessedValue']?.toDouble(),
      marketValue: json['marketValue']?.toDouble(),
      landValue: json['landValue']?.toDouble(),
      improvementValue: json['improvementValue']?.toDouble(),
      exemptions: json['exemptions']?.toDouble(),
      specialAssessments: json['specialAssessments']?.toDouble(),
      currentYearTaxes: json['currentYearTaxes']?.toDouble(),
      totalTaxesDue: json['totalTaxesDue']?.toDouble(),
      taxesCurrent: json['taxesCurrent'],
      lastPaymentDate: json['lastPaymentDate'] != null
          ? DateTime.parse(json['lastPaymentDate'])
          : null,
      taxStatus: json['taxStatus'],
      historicalAssessments: (json['historicalAssessments'] as List?)
          ?.map((a) => AssessmentYear.fromJson(a))
          .toList(),
      salesHistory: (json['salesHistory'] as List?)
          ?.map((s) => PropertySale.fromJson(s))
          .toList(),
      paymentHistory: (json['paymentHistory'] as List?)
          ?.map((p) => TaxPayment.fromJson(p))
          .toList(),
      buildings: (json['buildings'] as List?)
          ?.map((b) => BuildingInfo.fromJson(b))
          .toList(),
      landSegments: (json['landSegments'] as List?)
          ?.map((l) => LandSegment.fromJson(l))
          .toList(),
      sourceCounty: json['sourceCounty'] ?? '',
      sourceUrl: json['sourceUrl'] ?? '',
      retrievedAt: DateTime.parse(json['retrievedAt']),
      rawData: json['rawData'],
    );
  }

  /// Generate summary string for display
  String getSummary() {
    final buffer = StringBuffer();
    buffer.writeln('🏠 Property: $address, $city');
    buffer.writeln('👤 Owner: ${ownerName ?? 'Unknown'}');
    buffer.writeln('🏷️ Tax ID: $propertyId');

    if (assessedValue != null) {
      buffer
          .writeln('💰 Assessed Value: \${assessedValue!.toStringAsFixed(0)}');
    }

    if (marketValue != null) {
      buffer.writeln('🏪 Market Value: \${marketValue!.toStringAsFixed(0)}');
    }

    if (currentYearTaxes != null) {
      buffer.writeln(
          '📋 Current Taxes: \${currentYearTaxes!.toStringAsFixed(0)}');
    }

    buffer.writeln('📅 Retrieved: ${retrievedAt.toString().substring(0, 19)}');
    buffer.writeln('🗺️ Source: ${county.toUpperCase()} County');

    return buffer.toString();
  }

  // Add these methods to the OregonCountyTaxRecord class itself:
  Note toNote() {
    return Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: 'Tax Record Data - $sourceCounty County',
      content: '''
Property Tax Information Retrieved: ${retrievedAt.toString().substring(0, 19)}

PROPERTY DETAILS:
Address: $address
Tax Account: $propertyId
${alternateAccountNumber.isNotEmpty ? 'Alternate Account: $alternateAccountNumber' : ''}
Legal Description: ${legalDescription ?? 'N/A'}

OWNER INFORMATION:
Owner: ${ownerName ?? 'N/A'}
${mailingAddress != null ? 'Mailing Address: $mailingAddress' : ''}

VALUATION:
${assessedValue != null ? 'Assessed Value: \$${assessedValue!.toStringAsFixed(0)}' : ''}
${marketValue != null ? 'Market Value: \$${marketValue!.toStringAsFixed(0)}' : ''}

Source: $sourceUrl
    ''',
      createdAt: DateTime.now(),
    );
  }

  List<Document> toDocuments() {
    return []; // Empty for now
  }
}

/// Historical assessment data for a specific year
class AssessmentYear {
  final int year;
  final double? landValue;
  final double? improvementValue;
  final double? totalAssessedValue;
  final double? marketValue;
  final double? exemptions;

  AssessmentYear({
    required this.year,
    this.landValue,
    this.improvementValue,
    this.totalAssessedValue,
    this.marketValue,
    this.exemptions,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'landValue': landValue,
      'improvementValue': improvementValue,
      'totalAssessedValue': totalAssessedValue,
      'marketValue': marketValue,
      'exemptions': exemptions,
    };
  }

  factory AssessmentYear.fromJson(Map<String, dynamic> json) {
    return AssessmentYear(
      year: json['year'],
      landValue: json['landValue']?.toDouble(),
      improvementValue: json['improvementValue']?.toDouble(),
      totalAssessedValue: json['totalAssessedValue']?.toDouble(),
      marketValue: json['marketValue']?.toDouble(),
      exemptions: json['exemptions']?.toDouble(),
    );
  }
}

/// Property sale record
class PropertySale {
  final DateTime? saleDate;
  final double? salePrice;
  final String? seller;
  final String? buyer;
  final String? instrumentNumber;
  final String? deedType;

  PropertySale({
    this.saleDate,
    this.salePrice,
    this.seller,
    this.buyer,
    this.instrumentNumber,
    this.deedType,
  });

  Map<String, dynamic> toJson() {
    return {
      'saleDate': saleDate?.toIso8601String(),
      'salePrice': salePrice,
      'seller': seller,
      'buyer': buyer,
      'instrumentNumber': instrumentNumber,
      'deedType': deedType,
    };
  }

  factory PropertySale.fromJson(Map<String, dynamic> json) {
    return PropertySale(
      saleDate:
          json['saleDate'] != null ? DateTime.parse(json['saleDate']) : null,
      salePrice: json['salePrice']?.toDouble(),
      seller: json['seller'],
      buyer: json['buyer'],
      instrumentNumber: json['instrumentNumber'],
      deedType: json['deedType'],
    );
  }
}

/// Tax payment record
class TaxPayment {
  final int taxYear;
  final DateTime? paymentDate;
  final double? amount;
  final String? receiptNumber;

  TaxPayment({
    required this.taxYear,
    this.paymentDate,
    this.amount,
    this.receiptNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'taxYear': taxYear,
      'paymentDate': paymentDate?.toIso8601String(),
      'amount': amount,
      'receiptNumber': receiptNumber,
    };
  }

  factory TaxPayment.fromJson(Map<String, dynamic> json) {
    return TaxPayment(
      taxYear: json['taxYear'],
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : null,
      amount: json['amount']?.toDouble(),
      receiptNumber: json['receiptNumber'],
    );
  }
}

/// Building/improvement information
class BuildingInfo {
  final String? buildingType;
  final String? constructionClass;
  final int? yearBuilt;
  final double? squareFootage;
  final int? stories;
  final String? condition;

  BuildingInfo({
    this.buildingType,
    this.constructionClass,
    this.yearBuilt,
    this.squareFootage,
    this.stories,
    this.condition,
  });

  Map<String, dynamic> toJson() {
    return {
      'buildingType': buildingType,
      'constructionClass': constructionClass,
      'yearBuilt': yearBuilt,
      'squareFootage': squareFootage,
      'stories': stories,
      'condition': condition,
    };
  }

  factory BuildingInfo.fromJson(Map<String, dynamic> json) {
    return BuildingInfo(
      buildingType: json['buildingType'],
      constructionClass: json['constructionClass'],
      yearBuilt: json['yearBuilt'],
      squareFootage: json['squareFootage']?.toDouble(),
      stories: json['stories'],
      condition: json['condition'],
    );
  }
}

/// Land segment information
class LandSegment {
  final String? segmentId;
  final String? landType;
  final double? sizeSquareFeet;
  final double? sizeAcres;
  final double? value;

  LandSegment({
    this.segmentId,
    this.landType,
    this.sizeSquareFeet,
    this.sizeAcres,
    this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'segmentId': segmentId,
      'landType': landType,
      'sizeSquareFeet': sizeSquareFeet,
      'sizeAcres': sizeAcres,
      'value': value,
    };
  }

  factory LandSegment.fromJson(Map<String, dynamic> json) {
    return LandSegment(
      segmentId: json['segmentId'],
      landType: json['landType'],
      sizeSquareFeet: json['sizeSquareFeet']?.toDouble(),
      sizeAcres: json['sizeAcres']?.toDouble(),
      value: json['value']?.toDouble(),
    );
  }
}
