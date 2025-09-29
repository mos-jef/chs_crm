// lib/models/property_tax_info.dart
class PropertyTaxInfo {
  final String? owner;
  final double? assessedValue;
  final double? marketValue;
  final String? accountNumber;
  final String? legalDescription;
  final String? propertyType;
  final String? yearBuilt;
  final String county;
  final String state;
  final String? zipCode;
  final double? taxAmount;
  final bool? taxDelinquent;
  final DateTime? lastUpdated;

  PropertyTaxInfo({
    this.owner,
    this.assessedValue,
    this.marketValue,
    this.accountNumber,
    this.legalDescription,
    this.propertyType,
    this.yearBuilt,
    required this.county,
    required this.state,
    this.zipCode,
    this.taxAmount,
    this.taxDelinquent,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'owner': owner,
      'assessedValue': assessedValue,
      'marketValue': marketValue,
      'accountNumber': accountNumber,
      'legalDescription': legalDescription,
      'propertyType': propertyType,
      'yearBuilt': yearBuilt,
      'county': county,
      'state': state,
      'zipCode': zipCode,
      'taxAmount': taxAmount,
      'taxDelinquent': taxDelinquent,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory PropertyTaxInfo.fromMap(Map<String, dynamic> map) {
    return PropertyTaxInfo(
      owner: map['owner'],
      assessedValue: map['assessedValue']?.toDouble(),
      marketValue: map['marketValue']?.toDouble(),
      accountNumber: map['accountNumber'],
      legalDescription: map['legalDescription'],
      propertyType: map['propertyType'],
      yearBuilt: map['yearBuilt'],
      county: map['county'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'],
      taxAmount: map['taxAmount']?.toDouble(),
      taxDelinquent: map['taxDelinquent'],
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : null,
    );
  }

  @override
  String toString() {
    return 'PropertyTaxInfo(owner: $owner, assessedValue: $assessedValue, accountNumber: $accountNumber, county: $county)';
  }
}
