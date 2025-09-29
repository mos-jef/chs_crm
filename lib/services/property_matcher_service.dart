// lib/services/property_matcher_service.dart
import '../models/property_file.dart';

class PropertyMatcherService {
  /// Find existing property by matching address
  static PropertyFile? findMatchingProperty(
    List<PropertyFile> existingProperties,
    String taxDocumentAddress,
  ) {
    final normalizedTaxAddress = _normalizeAddress(taxDocumentAddress);

    for (final property in existingProperties) {
      final normalizedPropertyAddress = _normalizeAddress(property.address);

      // Try exact match first
      if (normalizedPropertyAddress == normalizedTaxAddress) {
        return property;
      }

      // Try fuzzy matching for slight variations
      if (_addressesMatch(normalizedPropertyAddress, normalizedTaxAddress)) {
        return property;
      }
    }

    return null;
  }

  /// Normalize address for comparison
  static String _normalizeAddress(String address) {
    return address
        .toUpperCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .replaceAll(
            RegExp(
                r'\b(STREET|ST|AVENUE|AVE|ROAD|RD|DRIVE|DR|LANE|LN|COURT|CT|PLACE|PL|WAY)\b'),
            '') // Remove street suffixes
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single
        .trim();
  }

  /// Check if addresses match with some tolerance
  static bool _addressesMatch(String addr1, String addr2) {
    final parts1 = addr1.split(' ').where((p) => p.isNotEmpty).toList();
    final parts2 = addr2.split(' ').where((p) => p.isNotEmpty).toList();

    // Must have matching street number
    if (parts1.isNotEmpty && parts2.isNotEmpty) {
      if (parts1[0] != parts2[0]) return false;
    }

    // Check for common street name components
    int matchingParts = 0;
    for (final part1 in parts1) {
      if (part1.length > 2 && parts2.contains(part1)) {
        matchingParts++;
      }
    }

    // Require at least 2 matching significant parts (number + street name)
    return matchingParts >= 2;
  }

  /// Get similarity score between two addresses (0.0 to 1.0)
  static double getAddressSimilarity(String addr1, String addr2) {
    final norm1 = _normalizeAddress(addr1);
    final norm2 = _normalizeAddress(addr2);

    if (norm1 == norm2) return 1.0;

    final parts1 = norm1.split(' ').where((p) => p.isNotEmpty).toSet();
    final parts2 = norm2.split(' ').where((p) => p.isNotEmpty).toSet();

    final intersection = parts1.intersection(parts2);
    final union = parts1.union(parts2);

    return union.isEmpty ? 0.0 : intersection.length / union.length;
  }
}
