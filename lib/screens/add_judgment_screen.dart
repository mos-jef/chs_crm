import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../models/property_file.dart';
import '../utils/validators.dart';

class AddJudgmentScreen extends StatefulWidget {
  final PropertyFile property;

  const AddJudgmentScreen({super.key, required this.property});

  @override
  State<AddJudgmentScreen> createState() => _AddJudgmentScreenState();
}

class _AddJudgmentScreenState extends State<AddJudgmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caseNumberController = TextEditingController();
  final _countyController = TextEditingController();
  final _debtorController = TextEditingController();
  final _granteeController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedStatus = 'Pending';
  String _selectedState = 'OR';
  DateTime? _dateOpened;
  DateTime? _judgmentDate;
  bool _isLoading = false;

  final List<String> _statuses = [
    'Pending',
    'Active',
    'Satisfied',
    'Dismissed',
  ];

  final List<String> _states = [
    'OR',
    'WA',
    'CA',
    'ID',
    'NV',
    'AZ',
    'UT',
    'CO',
    'NM',
    'TX',
    'OK',
    'KS',
    'NE',
    'WY',
    'MT',
    'ND',
    'SD',
    'MN',
    'IA',
    'MO',
    'AR',
    'LA',
    'MS',
    'AL',
    'TN',
    'KY',
    'IN',
    'IL',
    'WI',
    'MI',
    'OH',
    'WV',
    'VA',
    'NC',
    'SC',
    'GA',
    'FL',
    'DE',
    'MD',
    'PA',
    'NJ',
    'NY',
    'CT',
    'RI',
    'MA',
    'VT',
    'NH',
    'ME',
    'AK',
    'HI',
  ];

  @override
  void dispose() {
    _caseNumberController.dispose();
    _countyController.dispose();
    _debtorController.dispose();
    _granteeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveJudgment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newJudgment = Judgment(
        caseNumber: _caseNumberController.text.trim(),
        status: _selectedStatus,
        dateOpened: _dateOpened,
        judgmentDate: _judgmentDate,
        county: _countyController.text.trim(),
        state: _selectedState,
        debtor: _debtorController.text.trim(),
        grantee: _granteeController.text.trim(),
        amount: Validators.parseAmount(_amountController.text),
      );

      final updatedProperty = PropertyFile(
        id: widget.property.id,
        fileNumber: widget.property.fileNumber,
        address: widget.property.address,
        city: widget.property.city,
        state: widget.property.state,
        zipCode: widget.property.zipCode,
        loanAmount: widget.property.loanAmount,
        amountOwed: widget.property.amountOwed,
        arrears: widget.property.arrears,
        contacts: widget.property.contacts,
        documents: widget.property.documents,
        judgments: [...widget.property.judgments, newJudgment],
        vesting: widget.property.vesting,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
      );

      await context.read<PropertyProvider>().updateProperty(updatedProperty);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Judgment added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding judgment: $e')));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectDate(
    DateTime? currentDate,
    Function(DateTime?) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != currentDate) {
      setState(() {
        onDateSelected(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Judgment'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed:
              () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveJudgment,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _caseNumberController,
              decoration: const InputDecoration(
                labelText: 'Case Number *',
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) =>
                      Validators.validateRequired(value, 'a case number'),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status *',
                border: OutlineInputBorder(),
              ),
              items:
                  _statuses.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap:
                        () => _selectDate(
                          _dateOpened,
                          (date) => _dateOpened = date,
                        ),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Opened',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dateOpened != null
                            ? '${_dateOpened!.day}/${_dateOpened!.month}/${_dateOpened!.year}'
                            : 'Select Date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap:
                        () => _selectDate(
                          _judgmentDate,
                          (date) => _judgmentDate = date,
                        ),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Judgment Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _judgmentDate != null
                            ? '${_judgmentDate!.day}/${_judgmentDate!.month}/${_judgmentDate!.year}'
                            : 'Select Date',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _countyController,
                    decoration: const InputDecoration(
                      labelText: 'County *',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            Validators.validateRequired(value, 'a county'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _states.map((state) {
                          return DropdownMenuItem(
                            value: state,
                            child: Text(state),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _debtorController,
              decoration: const InputDecoration(
                labelText: 'Debtor *',
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) => Validators.validateRequired(value, 'a debtor'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _granteeController,
              decoration: const InputDecoration(
                labelText: 'Grantee *',
                border: OutlineInputBorder(),
              ),
              validator:
                  (value) => Validators.validateRequired(value, 'a grantee'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Judgment Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: Validators.validateAmount,
            ),
          ],
        ),
      ),
    );
  }
}
