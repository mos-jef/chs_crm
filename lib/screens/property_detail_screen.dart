import 'package:flutter/material.dart';
import '../models/property_file.dart';
import '../widgets/overview_tab.dart';
import '../widgets/property_info_tab.dart';
import '../widgets/contacts_tab.dart';
import '../widgets/documents_tab.dart';
import '../widgets/judgments_tab.dart';
import '../widgets/notes_tab.dart';
import '../widgets/trustees_tab.dart';
import '../widgets/auctions_tab.dart';
import '../widgets/vesting_tab.dart';
import 'edit_property_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyFile property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late PropertyFile _currentProperty;

  @override
  void initState() {
    super.initState();
    _currentProperty = widget.property;
  }

  Future<void> _editProperty() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditPropertyScreen(property: _currentProperty),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 9,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_currentProperty.fileNumber}'),
          leading: IconButton(
            icon: const Icon(Icons.home),
            onPressed:
                () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.edit), onPressed: _editProperty),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.info), text: 'Property'),
              Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
              Tab(icon: Icon(Icons.folder), text: 'Documents'),
              Tab(icon: Icon(Icons.gavel), text: 'Judgments'),
              Tab(icon: Icon(Icons.note), text: 'Notes'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Trustees'),
              Tab(icon: Icon(Icons.event), text: 'Auctions'),
              Tab(icon: Icon(Icons.account_balance), text: 'Vesting'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OverviewTab(property: _currentProperty),
            PropertyInfoTab(property: _currentProperty),
            ContactsTab(property: _currentProperty),
            DocumentsTab(property: _currentProperty),
            JudgmentsTab(property: _currentProperty),
            NotesTab(property: _currentProperty),
            TrusteesTab(property: _currentProperty),
            AuctionsTab(property: _currentProperty),
            VestingTab(property: _currentProperty),
          ],
        ),
      ),
    );
  }
}
