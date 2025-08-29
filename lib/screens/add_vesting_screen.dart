import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../models/property_file.dart';

class AddVestingScreen extends StatefulWidget {
  final PropertyFile property;

  const AddVestingScreen({super.key, required this.property});

  @override
  State<AddVestingScreen> createState() => _AddVestingScreenState();
}

class _AddVestingScreenState extends State<AddVestingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedVestingType = 'Joint Tenants';
  List<Owner> _owners = [Owner(name: '', percentage: 100.0)];
  bool _isLoading = false;

  final List<String> _vestingTypes = [
    'Joint Tenants',
    'Tenants in Common',
    'Community Property',
    'Sole Ownership',
    'Trust',
    'Corporation',
    'LLC',
    'Partnership',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.property.vesting != null) {
      _selectedVestingType = widget.property.vesting!.vestingType;
      _owners = List.from(widget.property.vesting!.owners);
    }
  }

  void _addOwner() {
    setState(() {
      _owners.add(Owner(name: '', percentage: 0.0));
    });
  }

  void _removeOwner(int index) {
    if (_owners.length > 1) {
      setState(() {
        _owners.removeAt(index);
      });
    }
  }

  double get _totalPercentage {
    return _owners.fold(0.0, (sum, owner) => sum + owner.percentage);
  }

  Future<void> _saveVesting() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if total percentage equals 100%
    if ((_totalPercentage - 100.0).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total ownership percentage must equal 100%'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vesting = VestingInfo(
        owners: _owners.where((owner) => owner.name.isNotEmpty).toList(),
        vestingType: _selectedVestingType,
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
        zillowUrl: widget.property.zillowUrl, 
        contacts: widget.property.contacts,
        documents: widget.property.documents,
        judgments: widget.property.judgments, 
        notes: widget.property.notes, 
        trustees: widget.property.trustees, 
        auctions: widget.property.auctions, 
        vesting: vesting,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
      );

      await context.read<PropertyProvider>().updateProperty(updatedProperty);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vesting information saved successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving vesting: $e')));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vesting Information'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveVesting,
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
            DropdownButtonFormField<String>(
              initialValue: _selectedVestingType,
              decoration: const InputDecoration(
                labelText: 'Vesting Type *',
                border: OutlineInputBorder(),
              ),
              items:
                  _vestingTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVestingType = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Owners',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addOwner,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Owner'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._owners.asMap().entries.map((entry) {
              final index = entry.key;
              final owner = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: owner.name,
                              decoration: const InputDecoration(
                                labelText: 'Owner Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _owners[index] = Owner(
                                  name: value,
                                  percentage: owner.percentage,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: owner.percentage.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Percentage',
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final percentage = double.tryParse(value);
                                if (percentage == null ||
                                    percentage < 0 ||
                                    percentage > 100) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                final percentage =
                                    double.tryParse(value) ?? 0.0;
                                _owners[index] = Owner(
                                  name: owner.name,
                                  percentage: percentage,
                                );
                                setState(
                                  () {},
                                ); // Refresh total percentage display
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_owners.length > 1)
                            IconButton(
                              onPressed: () => _removeOwner(index),
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _totalPercentage == 100.0
                        ? Colors.green[50]
                        : Colors.red[50],
                border: Border.all(
                  color: _totalPercentage == 100.0 ? Colors.green : Colors.red,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Ownership:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_totalPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          _totalPercentage == 100.0
                              ? Colors.green[700]
                              : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
