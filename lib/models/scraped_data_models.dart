// lib/models/scraped_data_models.dart
import 'package:chs_crm/models/property_file.dart';
import 'package:flutter/material.dart';

// 🎯 Property Tax Information Model
class PropertyTaxInfo {
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String parcelNumber;
  final double? assessedValue;
  final double? marketValue;
  final double? annualTaxes;
  final String owner;
  final DateTime? lastSaleDate;
  final double? lastSalePrice;
  final String propertyType;
  final int? yearBuilt;
  final double? sqft;
  final double? lotSize;

  PropertyTaxInfo({
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.parcelNumber,
    this.assessedValue,
    this.marketValue,
    this.annualTaxes,
    required this.owner,
    this.lastSaleDate,
    this.lastSalePrice,
    required this.propertyType,
    this.yearBuilt,
    this.sqft,
    this.lotSize,
  });

  factory PropertyTaxInfo.fromJson(Map<String, dynamic> json) {
    return PropertyTaxInfo(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      parcelNumber: json['parcelNumber'] ?? '',
      assessedValue: json['assessedValue']?.toDouble(),
      marketValue: json['marketValue']?.toDouble(),
      annualTaxes: json['annualTaxes']?.toDouble(),
      owner: json['owner'] ?? '',
      lastSaleDate: json['lastSaleDate'] != null
          ? DateTime.tryParse(json['lastSaleDate'])
          : null,
      lastSalePrice: json['lastSalePrice']?.toDouble(),
      propertyType: json['propertyType'] ?? '',
      yearBuilt: json['yearBuilt']?.toInt(),
      sqft: json['sqft']?.toDouble(),
      lotSize: json['lotSize']?.toDouble(),
    );
  }
}

// 🎯 Auction Information Model
class AuctionInfo {
  final String address;
  final DateTime auctionDate;
  final TimeOfDay time;
  final String location;
  final double? openingBid;
  final double? estimatedValue;
  final String trustee;
  final String auctionType; // foreclosure, tax sale, etc.
  final String status;
  final String? loanNumber;
  final String? borrowerName;

  AuctionInfo({
    required this.address,
    required this.auctionDate,
    required this.time,
    required this.location,
    this.openingBid,
    this.estimatedValue,
    required this.trustee,
    required this.auctionType,
    required this.status,
    this.loanNumber,
    this.borrowerName,
  });

  factory AuctionInfo.fromJson(Map<String, dynamic> json) {
    return AuctionInfo(
      address: json['address'] ?? '',
      auctionDate: DateTime.parse(json['auctionDate']),
      time: TimeOfDay(
        hour: json['hour'] ?? 10,
        minute: json['minute'] ?? 0,
      ),
      location: json['location'] ?? '',
      openingBid: json['openingBid']?.toDouble(),
      estimatedValue: json['estimatedValue']?.toDouble(),
      trustee: json['trustee'] ?? '',
      auctionType: json['auctionType'] ?? 'foreclosure',
      status: json['status'] ?? 'scheduled',
      loanNumber: json['loanNumber'],
      borrowerName: json['borrowerName'],
    );
  }
}

// 🎯 Court Record Model
class CourtRecord {
  final String caseNumber;
  final String caseType;
  final String court;
  final DateTime filingDate;
  final String plaintiff;
  final String defendant;
  final String status;
  final List<CourtDocument> documents;
  final DateTime? judgmentDate;
  final double? judgmentAmount;

  CourtRecord({
    required this.caseNumber,
    required this.caseType,
    required this.court,
    required this.filingDate,
    required this.plaintiff,
    required this.defendant,
    required this.status,
    this.documents = const [],
    this.judgmentDate,
    this.judgmentAmount,
  });

  factory CourtRecord.fromJson(Map<String, dynamic> json) {
    return CourtRecord(
      caseNumber: json['caseNumber'] ?? '',
      caseType: json['caseType'] ?? '',
      court: json['court'] ?? '',
      filingDate: DateTime.parse(json['filingDate']),
      plaintiff: json['plaintiff'] ?? '',
      defendant: json['defendant'] ?? '',
      status: json['status'] ?? '',
      documents: (json['documents'] as List<dynamic>?)
              ?.map((doc) => CourtDocument.fromJson(doc))
              .toList() ??
          [],
      judgmentDate: json['judgmentDate'] != null
          ? DateTime.tryParse(json['judgmentDate'])
          : null,
      judgmentAmount: json['judgmentAmount']?.toDouble(),
    );
  }
}

// 🎯 Court Document Model
class CourtDocument {
  final String title;
  final DateTime filedDate;
  final String documentType;
  final String? url;

  CourtDocument({
    required this.title,
    required this.filedDate,
    required this.documentType,
    this.url,
  });

  factory CourtDocument.fromJson(Map<String, dynamic> json) {
    return CourtDocument(
      title: json['title'] ?? '',
      filedDate: DateTime.parse(json['filedDate']),
      documentType: json['documentType'] ?? '',
      url: json['url'],
    );
  }
}

// 🎯 MLS Property Information Model
class MLSPropertyInfo {
  final String mlsNumber;
  final String address;
  final double? listPrice;
  final double? soldPrice;
  final DateTime? listDate;
  final DateTime? soldDate;
  final String status;
  final int? bedrooms;
  final double? bathrooms;
  final double? sqft;
  final double? lotSize;
  final int? yearBuilt;
  final String propertyType;
  final List<String> features;
  final String? description;
  final String? listingAgent;
  final String? sellingAgent;

  MLSPropertyInfo({
    required this.mlsNumber,
    required this.address,
    this.listPrice,
    this.soldPrice,
    this.listDate,
    this.soldDate,
    required this.status,
    this.bedrooms,
    this.bathrooms,
    this.sqft,
    this.lotSize,
    this.yearBuilt,
    required this.propertyType,
    this.features = const [],
    this.description,
    this.listingAgent,
    this.sellingAgent,
  });

  factory MLSPropertyInfo.fromJson(Map<String, dynamic> json) {
    return MLSPropertyInfo(
      mlsNumber: json['mlsNumber'] ?? '',
      address: json['address'] ?? '',
      listPrice: json['listPrice']?.toDouble(),
      soldPrice: json['soldPrice']?.toDouble(),
      listDate:
          json['listDate'] != null ? DateTime.tryParse(json['listDate']) : null,
      soldDate:
          json['soldDate'] != null ? DateTime.tryParse(json['soldDate']) : null,
      status: json['status'] ?? '',
      bedrooms: json['bedrooms']?.toInt(),
      bathrooms: json['bathrooms']?.toDouble(),
      sqft: json['sqft']?.toDouble(),
      lotSize: json['lotSize']?.toDouble(),
      yearBuilt: json['yearBuilt']?.toInt(),
      propertyType: json['propertyType'] ?? '',
      features: (json['features'] as List<dynamic>?)
              ?.map((f) => f.toString())
              .toList() ??
          [],
      description: json['description'],
      listingAgent: json['listingAgent'],
      sellingAgent: json['sellingAgent'],
    );
  }
}

// 🎯 Data Source Configuration Model
class DataSourceConfig {
  final String name;
  final String baseUrl;
  final Map<String, String> headers;
  final bool requiresAuth;
  final String? apiKey;
  final bool isActive;

  DataSourceConfig({
    required this.name,
    required this.baseUrl,
    this.headers = const {},
    this.requiresAuth = false,
    this.apiKey,
    this.isActive = true,
  });

  factory DataSourceConfig.fromJson(Map<String, dynamic> json) {
    return DataSourceConfig(
      name: json['name'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      requiresAuth: json['requiresAuth'] ?? false,
      apiKey: json['apiKey'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'baseUrl': baseUrl,
      'headers': headers,
      'requiresAuth': requiresAuth,
      'apiKey': apiKey,
      'isActive': isActive,
    };
  }
}

// 🎯 Import Result Model
class ImportResult {
  final bool success;
  final String message;
  final PropertyFile? property;
  final List<String> warnings;
  final List<String> errors;
  final Map<String, dynamic> metadata;

  ImportResult({
    required this.success,
    required this.message,
    this.property,
    this.warnings = const [],
    this.errors = const [],
    this.metadata = const {},
  });

  factory ImportResult.success({
    required PropertyFile property,
    String message = 'Import successful',
    List<String> warnings = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    return ImportResult(
      success: true,
      message: message,
      property: property,
      warnings: warnings,
      metadata: metadata,
    );
  }

  factory ImportResult.failure({
    required String message,
    List<String> errors = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    return ImportResult(
      success: false,
      message: message,
      errors: errors,
      metadata: metadata,
    );
  }
}

// 🎯 Batch Import Status Model
class BatchImportStatus {
  final int totalAddresses;
  final int processedCount;
  final int successCount;
  final int failureCount;
  final String currentAddress;
  final List<ImportResult> results;
  final bool isComplete;

  BatchImportStatus({
    required this.totalAddresses,
    required this.processedCount,
    required this.successCount,
    required this.failureCount,
    required this.currentAddress,
    required this.results,
    required this.isComplete,
  });

  double get progressPercentage =>
      totalAddresses > 0 ? processedCount / totalAddresses : 0.0;

  String get statusText =>
      'Processing $processedCount of $totalAddresses ($successCount successful, $failureCount failed)';
}
