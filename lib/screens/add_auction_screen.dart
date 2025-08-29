import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../models/property_file.dart';
import '../utils/validators.dart';

class AddAuctionScreen extends StatefulWidget {
  final PropertyFile property;
  final Auction? existingAuction;

  const AddAuctionScreen({
    super.key,
    required this.property,
    this.existingAuction,
  });

  @override
  State<AddAuctionScreen> createState() => _AddAuctionScreenState();
}

class _AddAuctionScreenState extends State<AddAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placeController = TextEditingController();
  final _openingBidController = TextEditingController();
  final _salesAmountController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _auctionCompleted = false;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAuction != null) {
      _isEditing = true;
      final auction = widget.existingAuction!;
      _placeController.text = auction.place;
      _selectedDate = auction.auctionDate;
      _selectedTime = auction.time;
      _auctionCompleted = auction.auctionCompleted;
      if (auction.openingBid != null) {
        _openingBidController.text = auction.openingBid!.toString();
      }
      if (auction.salesAmount != null) {
        _salesAmountController.text = auction.salesAmount!.toString();
      }
    }
  }

  @override
  void dispose() {
    _placeController.dispose();
    _openingBidController.dispose();
    _salesAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _saveAuction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a time')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Auction> updatedAuctions = List.from(widget.property.auctions);

      if (_isEditing) {
        final updatedAuction = Auction(
          id: widget.existingAuction!.id,
          auctionDate: _selectedDate!,
          place: _placeController.text.trim(),
          time: _selectedTime!,
          openingBid: Validators.parseAmount(_openingBidController.text),
          auctionCompleted: _auctionCompleted,
          salesAmount:
              _auctionCompleted
                  ? Validators.parseAmount(_salesAmountController.text)
                  : null,
          createdAt: widget.existingAuction!.createdAt,
          updatedAt: DateTime.now(),
        );

        final index = updatedAuctions.indexWhere(
          (a) => a.id == widget.existingAuction!.id,
        );
        if (index != -1) {
          updatedAuctions[index] = updatedAuction;
        }
      } else {
        final newAuction = Auction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          auctionDate: _selectedDate!,
          place: _placeController.text.trim(),
          time: _selectedTime!,
          openingBid: Validators.parseAmount(_openingBidController.text),
          auctionCompleted: _auctionCompleted,
          salesAmount:
              _auctionCompleted
                  ? Validators.parseAmount(_salesAmountController.text)
                  : null,
          createdAt: DateTime.now(),
        );
        updatedAuctions.add(newAuction);
      }

      final updatedProperty = PropertyFile(
        id: widget.property.id,
        fileNumber: widget.property.fileNumber,
        address: widget.property.address,
        city: widget.property.city,
        state: widget.property.state,
        zipCode: widget.property.zipCode,
        loanAmount: widget.property.loanAmount,
        amountOwed: widget.property.amountOwed,
        arrears: widget.property.arrears, // ADD THIS
        zillowUrl: widget.property.zillowUrl, // ADD THIS
        contacts: widget.property.contacts,
        documents: widget.property.documents,
        judgments: widget.property.judgments,
        notes: widget.property.notes,
        trustees: widget.property.trustees,
        auctions: updatedAuctions,
        vesting: widget.property.vesting,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
      );

      await context.read<PropertyProvider>().updateProperty(updatedProperty);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Auction ${_isEditing ? 'updated' : 'added'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${_isEditing ? 'updating' : 'adding'} auction: $e',
            ),
          ),
        );
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
        title: Text(_isEditing ? 'Edit Auction' : 'Add Auction'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed:
              () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: _isLoading ? null : _saveAuction,
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
                    : Text(
                      _isEditing ? 'Update' : 'Save',
                      style: const TextStyle(color: Colors.white),
                    ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? _formatDate(_selectedDate!)
                            : 'Select Date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _selectedTime != null
                            ? _formatTime(_selectedTime!)
                            : 'Select Time',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _placeController,
              decoration: const InputDecoration(
                labelText: 'Place *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator:
                  (value) => Validators.validateRequired(value, 'a place'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _openingBidController,
              decoration: const InputDecoration(
                labelText: 'Opening Bid',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: Validators.validateAmount,
            ),
            const SizedBox(height: 16),

            CheckboxListTile(
              title: const Text('Auction Completed'),
              value: _auctionCompleted,
              onChanged: (value) {
                setState(() {
                  _auctionCompleted = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),

            if (_auctionCompleted)
              TextFormField(
                controller: _salesAmountController,
                decoration: const InputDecoration(
                  labelText: 'Sales Amount',
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
