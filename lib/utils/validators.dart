class Validators {
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Allow empty values
    }

    // Remove dollar signs and commas for validation
    final cleanValue = value.replaceAll(RegExp(r'[\$,]'), '');

    if (cleanValue.isEmpty) {
      return null;
    }

    // Check if it's a valid number
    final number = double.tryParse(cleanValue);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number < 0) {
      return 'Amount cannot be negative';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  static double? parseAmount(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleanValue = value.replaceAll(RegExp(r'[\$,]'), '');
    return double.tryParse(cleanValue);
  }

  static String formatAmount(double? amount) {
    if (amount == null) return '';
    return amount.toStringAsFixed(2);
  }
}
