import 'package:flutter/material.dart';

class AdvancedSearchDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSearch;

  const AdvancedSearchDialog({super.key, required this.onSearch});

  @override
  State<AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends State<AdvancedSearchDialog> {
  final _fileNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _minLoanController = TextEditingController();
  final _maxLoanController = TextEditingController();

  @override
  void dispose() {
    _fileNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _minLoanController.dispose();
    _maxLoanController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final searchCriteria = <String, dynamic>{};

    if (_fileNumberController.text.isNotEmpty) {
      searchCriteria['fileNumber'] = _fileNumberController.text;
    }
    if (_addressController.text.isNotEmpty) {
      searchCriteria['address'] = _addressController.text;
    }
    if (_cityController.text.isNotEmpty) {
      searchCriteria['city'] = _cityController.text;
    }
    if (_stateController.text.isNotEmpty) {
      searchCriteria['state'] = _stateController.text;
    }
    if (_zipController.text.isNotEmpty) {
      searchCriteria['zipCode'] = _zipController.text;
    }
    if (_minLoanController.text.isNotEmpty) {
      searchCriteria['minLoan'] = double.tryParse(_minLoanController.text);
    }
    if (_maxLoanController.text.isNotEmpty) {
      searchCriteria['maxLoan'] = double.tryParse(_maxLoanController.text);
    }

    Navigator.of(context).pop();
    widget.onSearch(searchCriteria);
  }

  void _clearSearch() {
    _fileNumberController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _zipController.clear();
    _minLoanController.clear();
    _maxLoanController.clear();

    Navigator.of(context).pop();
    widget.onSearch({});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Advanced Search'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _fileNumberController,
                decoration: const InputDecoration(
                  labelText: 'File Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _zipController,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Loan Amount Range',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minLoanController,
                      decoration: const InputDecoration(
                        labelText: 'Min Amount',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _maxLoanController,
                      decoration: const InputDecoration(
                        labelText: 'Max Amount',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _clearSearch, child: const Text('Clear')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _performSearch, child: const Text('Search')),
      ],
    );
  }
}
