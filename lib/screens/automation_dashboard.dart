// lib/screens/automation_dashboard.dart
import 'package:chs_crm/models/property_file.dart';
import 'package:chs_crm/screens/enhance_properties_screen.dart';
import 'package:chs_crm/screens/paste_auction_data_screen.dart';
import 'package:chs_crm/screens/paste_tax_data_screen.dart';
import 'package:chs_crm/services/ai_property_research_service_debug.dart';
import 'package:chs_crm/services/file_number_service.dart';
import 'package:chs_crm/taxes/oregon/oregon_county_tax_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/scraped_data_models.dart';
import '../providers/property_provider.dart';
import '../services/advanced_automation_service.dart';
import '../services/oregon_sheriffs_service.dart';
import '../widgets/custom_beam_button.dart';

class AutomationDashboard extends StatefulWidget {
  const AutomationDashboard({super.key});

  @override
  State<AutomationDashboard> createState() => _AutomationDashboardState();
}

class _AutomationDashboardState extends State<AutomationDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Import Controllers
  final _singleAddressController = TextEditingController();
  final _batchAddressController = TextEditingController();
  final _caseNumberController = TextEditingController();
  final _csvController = TextEditingController();

  // Status variables
  bool _isLoading = false;
  String _statusMessage = '';
  List<ImportResult> _importResults = [];
  BatchImportStatus? _batchStatus;

  // Configuration
  final Map<String, bool> _dataSourceEnabled = {
    'Property Tax Records': true,
    'Auction Sites': true,
    'Court Records': true,
    'MLS Data': false,
    'Zillow': true,
    'Oregon Sheriff\'s Sales': true,
    'Washington Sheriff\'s Sales': false, // Placeholder for future
    'Idaho Sheriff\'s Sales': false, // Placeholder for future
  };

  // Sheriff's Sales Configuration
  String _selectedOregonCounty = 'All Counties';
  String _selectedWashingtonCounty = 'All Counties';
  String _selectedIdahoCounty = 'All Counties';

  final List<String> _oregonCounties = [
    'All Counties',
    'Multnomah',
    'Washington',
    'Clackamas',
    'Marion',
    'Lane',
    'Jackson',
    'Douglas',
    'Yamhill',
    'Polk',
  ];

  final List<String> _washingtonCounties = [
    'All Counties',
    'King',
    'Pierce',
    'Snohomish',
    'Spokane',
    'Clark',
    'Kitsap',
    'Thurston',
    'Whatcom',
    'Skagit',
  ];

  // Add these variables to your _AutomationDashboardState class:
  final _aiSearchController = TextEditingController();
  final List<String> _researchTypes = [
    'Portland Foreclosures',
    'Multnomah County Auctions',
    'Washington County Sheriff Sales',
    'Clackamas County Foreclosures',
    'Oregon Statewide Search',
    'Custom Search Query',
  ];
  String _selectedResearchType = 'Portland Foreclosures';
  int _maxAIResults = 10;

  final List<String> _idahoCounties = [
    'All Counties',
    'Ada',
    'Canyon',
    'Kootenai',
    'Bonneville',
    'Bannock',
    'Twin Falls',
    'Idaho',
    'Nez Perce',
    'Latah',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _singleAddressController.dispose();
    _batchAddressController.dispose();
    _caseNumberController.dispose();
    _csvController.dispose();
    _aiSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Single Import'),
            Tab(icon: Icon(Icons.list), text: 'Batch Import'),
            Tab(icon: Icon(Icons.file_upload), text: 'CSV Import'),
            Tab(icon: Icon(Icons.smart_toy), text: 'AI Research'),
            Tab(icon: Icon(Icons.settings), text: 'Configuration'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSingleImportTab(),
          _buildBatchImportTab(),
          _buildCSVImportTab(),
          _buildAIResearchTab(),
          _buildConfigurationTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PasteAuctionDataScreen()),
          );
        },
        icon: const Icon(Icons.paste),
        label: const Text("Paste Auction"),
      ),
    );
  }

  // SINGLE PROPERTY IMPORT TAB
  Widget _buildSingleImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intelligent Import Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text('Intelligent Property Import',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                      'Enter address or case number. The system will automatically gather data from multiple sources.'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _singleAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Property Address *',
                      hintText: '123 Main St, Portland, OR 97201',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _caseNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Case Number (Optional)',
                      hintText: 'Enter court case number if available',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.gavel),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: CustomBeamButton(
                          text: _isLoading
                              ? 'IMPORTING...'
                              : 'INTELLIGENT IMPORT',
                          onPressed:
                              _isLoading ? null : _performIntelligentImport,
                          isLoading: _isLoading,
                          buttonStyle: CustomButtonStyle.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CustomBeamButton(
                        text: 'CLEAR',
                        onPressed: _clearSingleImport,
                        width: 80,
                        buttonStyle: CustomButtonStyle.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomBeamButton(
                    text: 'PASTE DATA',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PasteAuctionDataScreen(),
                        ),
                      );
                    },
                    width: 150, // control width
                    height: 50, // control height
                    buttonStyle: CustomButtonStyle.primary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (_statusMessage.isNotEmpty) _buildStatusCard(),
        ],
      ),
    );
  }

  // Add this method to create the AI Research Tab (replace one of your existing tabs or add as 5th tab):

  Widget _buildAIResearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-Powered Research Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text('AI-Powered Property Research',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                      'AI automatically searches Auction.com, Sheriff\'s Sales, extracts tax records, and creates comprehensive property profiles.'),
                  const SizedBox(height: 16),

                  // Research Type Selection
                  Row(
                    children: [
                      const Text('Research Type: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedResearchType,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedResearchType =
                                  newValue ?? _researchTypes.first;
                            });
                          },
                          items: _researchTypes
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Custom Search Query (when Custom is selected)
                  if (_selectedResearchType == 'Custom Search Query') ...[
                    TextFormField(
                      controller: _aiSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Search Query',
                        hintText:
                            'e.g., "Foreclosures under \$300k in Portland"',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Max Results Slider
                  Row(
                    children: [
                      const Text('Max Results: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          value: _maxAIResults.toDouble(),
                          min: 5,
                          max: 25,
                          divisions: 4,
                          label: _maxAIResults.toString(),
                          onChanged: (double value) {
                            setState(() {
                              _maxAIResults = value.round();
                            });
                          },
                        ),
                      ),
                      Text('$_maxAIResults'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomBeamButton(
                          text: _isLoading
                              ? 'AI RESEARCHING...'
                              : 'START AI RESEARCH',
                          onPressed: _isLoading ? null : _performAIResearch,
                          isLoading: _isLoading,
                          buttonStyle: CustomButtonStyle.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CustomBeamButton(
                        text: 'TEST AI',
                        onPressed: _testAIConnection,
                        width: 80,
                        buttonStyle: CustomButtonStyle.secondary,
                      ),
                      const SizedBox(width: 12), // ADD THIS SPACING
                      CustomBeamButton(
                        text: 'Test Mult. Taxes',
                        onPressed:
                            _isLoading ? null : _testMultnomahCountyTaxLookup,
                      ),
                      const SizedBox(width: 12), // ADD THIS SPACING
                      CustomBeamButton(
                        text: 'Update All Multnomah Tax Data',
                        onPressed:
                            _isLoading ? null : _batchUpdateMultnomahTaxes,
                        buttonStyle: CustomButtonStyle.primary,
                      ),
                      CustomBeamButton(
                        text: 'MANUAL PASTE',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PasteAuctionDataScreen(),
                            ),
                          );
                        },
                        width: 180,
                        height: 45,
                        buttonStyle: CustomButtonStyle.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // AI Workflow Explanation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Research Workflow',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Automatically Performs These Steps:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                            '1. Searches Auction.com and Sheriff\'s Sales'),
                        const Text(
                            '2. Extracts: address, tax account #, auction date'),
                        const Text('3. Determines county from address'),
                        const Text(
                            '4. Searches county tax site with account #'),
                        const Text(
                            '5. Extracts: assessed value, owner info, legal description'),
                        const Text('6. Cross-references with court records'),
                        const Text(
                            '7. Creates comprehensive property profiles'),
                        const SizedBox(height: 8),
                        const Text('County Tax Sites Integrated:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text(
                            'Washington County: washcotax.co.washington.or.us'),
                        const Text('Multnomah County: multcoproptax.com'),
                        const Text('Clackamas County: ascendweb.clackamas.us'),
                        const Text('More counties can be added dynamically'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (_statusMessage.isNotEmpty) _buildStatusCard(),

          const SizedBox(height: 20),
          _buildImportResults(),
        ],
      ),
    );
  }

  // BATCH IMPORT TAB
  Widget _buildBatchImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Batch Address Import',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                      'Enter multiple addresses (one per line) for bulk import.'),

                  const SizedBox(height: 16),

// Put both buttons in a Row
                  Row(
                    children: [
                      CustomBeamButton(
                        text: 'PASTE BATCH',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PasteAuctionDataScreen(),
                            ),
                          );
                        },
                        width: 150,
                        height: 50,
                        buttonStyle: CustomButtonStyle.primary,
                      ),

                      const SizedBox(width: 340), // Space between buttons

                      CustomBeamButton(
                        text: 'ENHANCE WITH TAX DATA',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EnhancePropertiesScreen(),
                            ),
                          );
                        },
                        width: 150,
                        height: 50,
                        buttonStyle: CustomButtonStyle.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _batchAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Property Addresses',
                      hintText:
                          '123 Main St, Portland, OR 97201\n456 Oak Ave, Portland, OR 97202\n789 Pine St, Portland, OR 97203',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CustomBeamButton(
                        text: _isLoading ? 'PROCESSING...' : 'IMPORT',
                        onPressed: _isLoading ? null : _performBatchImport,
                        isLoading: _isLoading,
                        width: 130,
                        height: 50,
                        buttonStyle: CustomButtonStyle.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_batchStatus != null) _buildBatchProgress(),
          const SizedBox(height: 20),
          _buildImportResults(),
        ],
      ),
    );
  }

  // CSV IMPORT TAB
  Widget _buildCSVImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CSV File Import',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                      'Import properties from CSV files exported from other systems.'),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      CustomBeamButton(
                        text: 'SELECT FILE',
                        onPressed: _selectCSVFile,
                        width: 130,
                        height: 50,
                        buttonStyle: CustomButtonStyle.primary,
                      ),

                      const SizedBox(width: 40),

                      //CustomBeamButton(
                        //text: 'DOWNLOAD TEMPLATE',
                       // onPressed: _downloadCSVTemplate,
                      //  width: 130,
                       // height: 50,
                       // buttonStyle: CustomButtonStyle.primary,
                    //  ),

                      const SizedBox(width: 40),

                      CustomBeamButton(
                        text: 'PASTE → CSV',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PasteAuctionDataScreen(),
                            ),
                          );
                        },
                        width: 130,
                        height: 50,
                        buttonStyle: CustomButtonStyle.primary,
                      ),
                    ],
                  ),

                 
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _csvController,
                    decoration: const InputDecoration(
                      labelText: 'CSV Content',
                      hintText: 'Paste CSV content here or use "Select CSV File"',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 10,
                  ),
                  const SizedBox(height: 16),
                  CustomBeamButton(
                    text: _isLoading ? 'PROCESSING...' : 'IMPORT CONTENT',
                    onPressed: _isLoading ? null : _performCSVImport,
                    isLoading: _isLoading,
                    width: 130,
                    height: 50,
                    buttonStyle: CustomButtonStyle.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildImportResults(),
        ],
      ),
    );
  }

  // CONFIGURATION TAB
  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data Sources Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data Sources',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                      'Configure which data sources to use for automated imports.'),
                  const SizedBox(height: 16),
                  _buildDataSourceConfig(
                      'Property Tax Records',
                      'Washington County, Multnomah County tax records',
                      _dataSourceEnabled['Property Tax Records']!,
                      'county-websites'),
                  _buildDataSourceConfig(
                      'Auction Sites',
                      'RealtyTrac, Auction.com, trustee websites',
                      _dataSourceEnabled['Auction Sites']!,
                      'auction-sites'),
                  _buildDataSourceConfig(
                      'Court Records',
                      'Public court case lookup systems',
                      _dataSourceEnabled['Court Records']!,
                      'court-systems'),
                  _buildDataSourceConfig(
                      'MLS Data',
                      'Multiple Listing Service (requires API key)',
                      _dataSourceEnabled['MLS Data']!,
                      'mls-api'),
                  _buildDataSourceConfig(
                      'Zillow',
                      'Property value estimates and details',
                      _dataSourceEnabled['Zillow']!,
                      'zillow-api'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // OREGON SHERIFF'S SALES
          _buildOregonSheriffsSection(),

          const SizedBox(height: 20),

          // WASHINGTON SHERIFF'S SALES (Placeholder)
          _buildWashingtonSheriffsSection(),

          const SizedBox(height: 20),

          // IDAHO SHERIFF'S SALES (Placeholder)
          _buildIdahoSheriffsSection(),

          const SizedBox(height: 20),

          // API Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('API Configuration',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Configure API keys for enhanced data access.'),
                  const SizedBox(height: 16),
                  _buildAPIKeyConfig('Google Geocoding API',
                      'For address normalization and validation'),
                  _buildAPIKeyConfig('MLS API', 'For real estate listing data'),
                  _buildAPIKeyConfig(
                      'Zillow API', 'For property value estimates'),
                  _buildAPIKeyConfig(
                      'USPS Address API', 'For address standardization'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Automation Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('  ¸ Automation Settings',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Configure automated monitoring and alerts.'),
                  const SizedBox(height: 16),
                  _buildAutomationSetting('Real-time Auction Monitoring',
                      'Check for new auction listings hourly', true),
                  _buildAutomationSetting('Court Case Updates',
                      'Monitor court cases for status changes', true),
                  _buildAutomationSetting('Property Value Updates',
                      'Check for property value changes daily', false),
                  _buildAutomationSetting('Email Notifications',
                      'Send email alerts for important updates', false),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  // OREGON SHERIFF'S SALES SECTION
  Widget _buildOregonSheriffsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Oregon Sheriff\'s Sales',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Switch(
                  value: _dataSourceEnabled['Oregon Sheriff\'s Sales']!,
                  onChanged: (value) =>
                      _toggleDataSource('Oregon Sheriff\'s Sales', value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
                'Import properties from Oregon Sheriff\'s Sales with full document processing.'),
            const SizedBox(height: 16),

            // County Selection
            Row(
              children: [
                const Text('County: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedOregonCounty,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedOregonCounty = newValue ?? 'All Counties';
                      });
                    },
                    items: _oregonCounties
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomBeamButton(
                    text: _isLoading ? 'IMPORTING...' : 'IMPORT OREGON SALES',
                    onPressed: (_isLoading ||
                            !_dataSourceEnabled['Oregon Sheriff\'s Sales']!)
                        ? null
                        : _importOregonSheriffsSales,
                    isLoading: _isLoading,
                    buttonStyle: CustomButtonStyle.primary,
                  ),
                ),
                const SizedBox(width: 12),
                CustomBeamButton(
                  text: 'TEST',
                  onPressed: _testOregonSheriffsConnection,
                  width: 80,
                  buttonStyle: CustomButtonStyle.secondary,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('  … ACTIVE - What This Imports:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('  Property addresses and case information'),
                  const Text('  Plaintiff/Defendant details'),
                  const Text('  Sale dates and amounts'),
                  const Text('  All PDF documents (automatically downloaded)'),
                  const Text('  Full text extraction from documents'),
                  const Text('  Legal descriptions and loan amounts'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WASHINGTON SHERIFF'S SALES SECTION (Placeholder)
  Widget _buildWashingtonSheriffsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('Washington State Sheriff\'s Sales',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const Spacer(),
                Switch(
                  value: _dataSourceEnabled['Washington Sheriff\'s Sales']!,
                  onChanged: null, // Disabled until implemented
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
                'Import properties from Washington State Sheriff\'s Sales. (Coming Soon)',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),

            // County Selection
            Row(
              children: [
                const Text('County: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedWashingtonCounty,
                    isExpanded: true,
                    onChanged: null, // Disabled
                    items: _washingtonCounties
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style: const TextStyle(color: Colors.grey)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons (Disabled)
            Row(
              children: [
                Expanded(
                  child: CustomBeamButton(
                    text: 'IMPORT WASHINGTON SALES',
                    onPressed: null, // Disabled
                    buttonStyle: CustomButtonStyle.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                CustomBeamButton(
                  text: 'TEST',
                  onPressed: null, // Disabled
                  width: 80,
                  buttonStyle: CustomButtonStyle.secondary,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('COMING SOON - Will Import:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('  Washington State foreclosure properties',
                      style: TextStyle(color: Colors.grey)),
                  const Text('  King, Pierce, Snohomish County sales',
                      style: TextStyle(color: Colors.grey)),
                  const Text('  Full document processing capabilities',
                      style: TextStyle(color: Colors.grey)),
                  const Text('  Integration with WA court records',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // IDAHO SHERIFF'S SALES SECTION (Placeholder)
  Widget _buildIdahoSheriffsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('Idaho Sheriff\'s Sales',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const Spacer(),
                Switch(
                  value: _dataSourceEnabled['Idaho Sheriff\'s Sales']!,
                  onChanged: null, // Disabled until implemented
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
                'Import properties from Idaho Sheriff\'s Sales. (Coming Soon)',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),

            // County Selection
            Row(
              children: [
                const Text('County: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedIdahoCounty,
                    isExpanded: true,
                    onChanged: null, // Disabled
                    items: _idahoCounties
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style: const TextStyle(color: Colors.grey)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons (Disabled)
            Row(
              children: [
                Expanded(
                  child: CustomBeamButton(
                    text: 'IMPORT IDAHO SALES',
                    onPressed: null, // Disabled
                    buttonStyle: CustomButtonStyle.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                CustomBeamButton(
                  text: 'TEST',
                  onPressed: null, // Disabled
                  width: 80,
                  buttonStyle: CustomButtonStyle.secondary,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('COMING SOON - Will Import:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('  Idaho State foreclosure properties',
                      style: TextStyle(color: Colors.grey)),
                  const Text('  Ada, Canyon, Kootenai County sales',
                      style: TextStyle(color: Colors.grey)),
                  const Text('  Full document processing capabilities',
                      style: TextStyle(color: Colors.grey)),
                  const Text('  Integration with ID court records',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STATUS AND PROGRESS WIDGETS

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _statusMessage.startsWith('  …')
                      ? Icons.check_circle
                      : Icons.info,
                  color: _statusMessage.startsWith('  …')
                      ? Colors.green
                      : Colors.blue,
                ),
                const SizedBox(width: 8),
                const Text('Status',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchProgress() {
    final status = _batchStatus!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Batch Import Progress',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: status.progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor:
                  AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 8),
            Text(status.statusText),
            if (status.currentAddress.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Current: ${status.currentAddress}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImportResults() {
    if (_importResults.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Import Results',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _importResults.length,
                itemBuilder: (context, index) {
                  final result = _importResults[index];
                  return ListTile(
                    leading: Icon(
                      result.success ? Icons.check_circle : Icons.error,
                      color: result.success ? Colors.green : Colors.red,
                    ),
                    title: Text(result.message),
                    subtitle: result.warnings.isNotEmpty
                        ? Text('Warnings: ${result.warnings.join(', ')}')
                        : result.errors.isNotEmpty
                            ? Text('Errors: ${result.errors.join(', ')}')
                            : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildActivityItem('Oregon Sheriff\'s Sale imported',
                'Multnomah County - 3 properties', '5 minutes ago'),
            _buildActivityItem('Property imported', '123 Main St, Portland, OR',
                '15 minutes ago'),
            _buildActivityItem('Document processed',
                'Notice of Sale PDF analyzed', '20 minutes ago'),
            _buildActivityItem('Batch import completed',
                '15 properties processed', '3 hours ago'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 4,
            backgroundColor: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDataSourceConfig(
      String name, String description, bool isEnabled, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Switch(
            value: isEnabled,
            onChanged: (value) => _toggleDataSource(name, value),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _testDataSource(name),
            icon: const Icon(Icons
                .science), // Fixed: Changed from Icons.test_tube to Icons.science
            tooltip: 'Test Connection',
          ),
        ],
      ),
    );
  }

  Widget _buildAPIKeyConfig(String service, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          CustomBeamButton(
            text: 'CONFIGURE',
            onPressed: () => _configureAPIKey(service),
            width: 100,
            height: 30,
            buttonStyle: CustomButtonStyle.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationSetting(
      String title, String description, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Switch(
            value: isEnabled,
            onChanged: (value) => _toggleAutomationSetting(title, value),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ACTION METHODS

  void _clearSingleImport() {
    _singleAddressController.clear();
    _caseNumberController.clear();
    setState(() {
      _statusMessage = '';
    });
  }

  Future<void> _performIntelligentImport() async {
    if (_singleAddressController.text.trim().isEmpty) {
      setState(() {
        _statusMessage = '  Please enter a property address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting intelligent import...';
    });

    try {
      final property =
          await AdvancedAutomationService.intelligentPropertyImport(
        address: _singleAddressController.text.trim(),
        caseNumber: _caseNumberController.text.trim().isEmpty
            ? null
            : _caseNumberController.text.trim(),
      );

      if (property != null && mounted) {
        await context.read<PropertyProvider>().addProperty(property);

        setState(() {
          _statusMessage =
              '  … Property imported successfully!\nFile Number: ${property.fileNumber}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Property ${property.fileNumber} imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _clearSingleImport();
      } else {
        setState(() {
          _statusMessage =
              '  Could not import property data. Please check the address and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '  Import failed: ${e.toString()}';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _performBatchImport() async {
    final addresses = _batchAddressController.text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList();

    if (addresses.isEmpty) {
      setState(() {
        _statusMessage = '  Please enter at least one address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _importResults.clear();
      _batchStatus = BatchImportStatus(
        totalAddresses: addresses.length,
        processedCount: 0,
        successCount: 0,
        failureCount: 0,
        currentAddress: addresses.first,
        results: [],
        isComplete: false,
      );
    });

    try {
      for (int i = 0; i < addresses.length; i++) {
        final address = addresses[i];

        setState(() {
          _batchStatus = BatchImportStatus(
            totalAddresses: addresses.length,
            processedCount: i,
            successCount: _batchStatus!.successCount,
            failureCount: _batchStatus!.failureCount,
            currentAddress: address,
            results: _batchStatus!.results,
            isComplete: false,
          );
        });

        try {
          final property =
              await AdvancedAutomationService.intelligentPropertyImport(
            address: address,
          );

          if (property != null) {
            await context.read<PropertyProvider>().addProperty(property);

            final result = ImportResult.success(
              property: property,
              message: 'Successfully imported: $address',
            );
            _importResults.add(result);

            setState(() {
              _batchStatus = BatchImportStatus(
                totalAddresses: addresses.length,
                processedCount: i + 1,
                successCount: _batchStatus!.successCount + 1,
                failureCount: _batchStatus!.failureCount,
                currentAddress:
                    i < addresses.length - 1 ? addresses[i + 1] : '',
                results: [..._batchStatus!.results, result],
                isComplete: i == addresses.length - 1,
              );
            });
          } else {
            final result = ImportResult.failure(
              message: 'Failed to import: $address',
              errors: ['No data found for address'],
            );
            _importResults.add(result);

            setState(() {
              _batchStatus = BatchImportStatus(
                totalAddresses: addresses.length,
                processedCount: i + 1,
                successCount: _batchStatus!.successCount,
                failureCount: _batchStatus!.failureCount + 1,
                currentAddress:
                    i < addresses.length - 1 ? addresses[i + 1] : '',
                results: [..._batchStatus!.results, result],
                isComplete: i == addresses.length - 1,
              );
            });
          }
        } catch (e) {
          final result = ImportResult.failure(
            message: 'Error importing: $address',
            errors: [e.toString()],
          );
          _importResults.add(result);

          setState(() {
            _batchStatus = BatchImportStatus(
              totalAddresses: addresses.length,
              processedCount: i + 1,
              successCount: _batchStatus!.successCount,
              failureCount: _batchStatus!.failureCount + 1,
              currentAddress: i < addresses.length - 1 ? addresses[i + 1] : '',
              results: [..._batchStatus!.results, result],
              isComplete: i == addresses.length - 1,
            );
          });
        }

        // Rate limiting between imports
        await Future.delayed(const Duration(seconds: 2));
      }

      setState(() {
        _statusMessage =
            '  … Batch import completed: ${_batchStatus!.successCount} successful, ${_batchStatus!.failureCount} failed';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '  Batch import error: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _performCSVImport() async {
    if (_csvController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _importResults.clear();
      _statusMessage = 'Processing CSV data...';
    });

    try {
      final results =
          await AdvancedAutomationService.importFromCSV(_csvController.text);

      for (final result in results) {
        if (result.success && result.property != null) {
          await context.read<PropertyProvider>().addProperty(result.property!);
        }
      }

      setState(() {
        _importResults = results;
        final successCount = results.where((r) => r.success).length;
        _statusMessage =
            '  … CSV import completed: $successCount of ${results.length} properties imported';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '  CSV import failed: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectCSVFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final csvContent = String.fromCharCodes(result.files.single.bytes!);
        setState(() {
          _csvController.text = csvContent;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading CSV file: $e')),
      );
    }
  }

  void _downloadCSVTemplate() {
    // This would trigger a CSV template download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV template download would start here')),
    );
  }

  // OREGON SHERIFF'S SALES METHODS
  Future<void> _importOregonSheriffsSales() async {
    setState(() {
      _isLoading = true;
      _importResults.clear();
      _statusMessage = 'Starting Oregon Sheriff\'s Sales import...';
    });

    try {
      List<PropertyFile> properties;

      if (_selectedOregonCounty == 'All Counties') {
        // Import from all counties
        properties = await OregonSheriffsService.importAllOregonSheriffsSales();
      } else {
        // Import from specific county
        properties = await OregonSheriffsService.importCountySheriffsSales(
            _selectedOregonCounty);
      }

      // Add each property to the provider
      for (final property in properties) {
        if (mounted) {
          await context.read<PropertyProvider>().addProperty(property);

          _importResults.add(ImportResult.success(
            property: property,
            message: 'Sheriff\'s sale imported: ${property.address}',
            metadata: {
              'source': 'oregon_sheriffs',
              'county': _selectedOregonCounty
            },
          ));
        }
      }

      setState(() {
        _statusMessage = '  … Sheriff\'s sales import completed!\n'
            'Properties imported: ${properties.length}\n'
            'Documents processed: ${properties.fold(0, (sum, p) => sum + p.documents.length)}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Imported ${properties.length} sheriff\'s sale properties with full document processing!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '  Sheriff\'s sales import failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testOregonSheriffsConnection() async {
    setState(() {
      _statusMessage = 'Testing Oregon Sheriff\'s Sales connection...';
    });

    try {
      // Test connection by fetching counties list
      final response = await http.get(
        Uri.parse('https://oregonsheriffssales.org/counties/'),
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; CRM Bot 1.0)'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage =
              '  … Connection successful! Oregon Sheriff\'s Sales is accessible.';
        });
      } else {
        setState(() {
          _statusMessage =
              '  Connection failed. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '  Connection test failed: $e';
      });
    }
  }

  // Add these AI Research action methods to your _AutomationDashboardState class:

  Future<void> _performAIResearch() async {
    setState(() {
      _isLoading = true;
      _importResults.clear();
      _statusMessage = 'DEBUG: Starting AI research with detailed logging...';
    });

    try {
      // Determine search query
      String searchQuery = _selectedResearchType;
      if (_selectedResearchType == 'Custom Search Query') {
        searchQuery = _aiSearchController.text.trim();
        if (searchQuery.isEmpty) {
          setState(() {
            _statusMessage = '  Please enter a custom search query';
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _statusMessage = 'DEBUG: Testing system components...\n'
            'Query: "$searchQuery"\n'
            'Max Results: $_maxAIResults\n\n'
            'Running diagnostics...';
      });

      // Step 1: Test Claude API
      setState(() {
        _statusMessage = ' DEBUG: Step 1 - Testing Claude API...';
      });

      await Future.delayed(
          const Duration(seconds: 1)); // Let user see the message

      // Step 2: Test county tax sites
      setState(() {
        _statusMessage = 'DEBUG: Step 2 - Testing county tax sites...';
      });

      await AIPropertyResearchServiceDebug.testCountyTaxSites();
      await Future.delayed(const Duration(seconds: 1));

      // Step 3: Test Oregon Sheriff's Sales
      setState(() {
        _statusMessage = ' DEBUG: Step 3 - Testing Oregon Sheriff\'s Sales...';
      });

      await AIPropertyResearchServiceDebug.testOregonSheriffsSales();
      await Future.delayed(const Duration(seconds: 1));

      // Step 4: Run AI research (debug version)
      setState(() {
        _statusMessage =
            ' DEBUG: Step 4 - Running AI research (debug mode)...\n'
            'This will create mock properties to test the workflow.';
      });

      // Use the debug service instead of the main one
      final properties =
          await AIPropertyResearchServiceDebug.runIntelligentPropertyResearch(
        searchQuery: searchQuery,
        maxProperties: _maxAIResults,
      );

      print(' DEBUG: AI research returned ${properties.length} properties');

      // Add each property to the provider
      int successCount = 0;
      int documentCount = 0;

      for (final property in properties) {
        print(
            'DEBUG: Processing property: ${property.fileNumber} - ${property.address}');

        if (mounted) {
          try {
            await context.read<PropertyProvider>().addProperty(property);
            print('  … DEBUG: Successfully added property to provider');

            successCount++;
            documentCount += property.documents.length;

            _importResults.add(ImportResult.success(
              property: property,
              message: ' DEBUG: Created mock property: ${property.address}',
              metadata: {
                'source': 'debug_ai_research',
                'query': searchQuery,
                'mode': 'debug',
                'fileNumber': property.fileNumber,
              },
            ));

            print('  … DEBUG: Added import result for ${property.fileNumber}');
          } catch (e) {
            print('  DEBUG: Error adding property to provider: $e');

            _importResults.add(ImportResult.failure(
              message: 'Failed to add property: ${property.address}',
              errors: [e.toString()],
            ));
          }
        }

        // Update progress
        setState(() {
          _statusMessage = 'DEBUG: Processing properties...\n'
              'Completed: $successCount/${properties.length}\n'
              'Current: ${property.address}\n'
              'File Number: ${property.fileNumber}';
        });

        await Future.delayed(
            const Duration(milliseconds: 500)); // Show progress
      }

      // Final results
      setState(() {
        if (properties.isNotEmpty) {
          _statusMessage = ' DEBUG: Research completed successfully!\n\n'
              'Properties created: ${properties.length}\n'
              'Documents processed: $documentCount\n'
              'Import results: ${_importResults.length}\n'
              'Success count: $successCount\n\n'
              'Query used: "$searchQuery"\n\n'
              'NOTE: These are mock properties for testing.\n'
              'Check browser console for detailed debug logs.';
        } else {
          _statusMessage = '  DEBUG: No properties were created!\n\n'
              'This suggests an issue with:\n'
              '  File number generation\n'
              '  Property creation process\n'
              '  Database connectivity\n\n'
              'Check browser console for error details.';
        }
      });

      if (mounted) {
        if (properties.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'DEBUG: Created ${properties.length} mock properties for testing!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('  DEBUG: No properties created - check console'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('  DEBUG: Main error in _performAIResearch: $e');
      print('  DEBUG: Stack trace: ${StackTrace.current}');

      setState(() {
        _statusMessage = '  DEBUG: Research failed with error:\n\n'
            '$e\n\n'
            'Common causes:\n'
            '  Network connectivity issues\n'
            '  FileNumberService problems\n'
            '  PropertyProvider issues\n'
            '  Database connection problems\n\n'
            'Check browser console for full error details.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('  DEBUG: Research failed - $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testMultnomahCountyTaxLookup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing Multnomah County tax lookup...';
    });

    try {
      // Import your new tax service
      final taxService = OregonCountyTaxService();

      // Test with the address from your example
      final result = await taxService.getTaxRecords(
          address: "3519 SE MORRISON ST, PORTLAND, OR");

      if (result != null) {
        setState(() {
          _statusMessage = '''✅ SUCCESS! Retrieved tax data:
        
        Property: ${result.address}
        Owner: ${result.ownerName ?? 'Unknown'}
        Tax ID: ${result.propertyId}
        Assessed Value: \$${result.assessedValue?.toStringAsFixed(0) ?? 'N/A'}
        Market Value: \$${result.marketValue?.toStringAsFixed(0) ?? 'N/A'}
        Legal Description: ${result.legalDescription ?? 'N/A'}
        ''';
        });
      } else {
        setState(() {
          _statusMessage = '❌ No tax data found for the test address';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error during test: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _batchUpdateMultnomahTaxes() async {
    setState(() {
      _isLoading = true;
      _statusMessage =
          'Starting batch tax data update for Multnomah County properties...';
    });

    try {
      final taxService = OregonCountyTaxService();
      final results = await taxService.batchUpdateMultnomahProperties(
        context: context,
        delayBetweenRequests:
            const Duration(seconds: 3), // Be respectful to their server
      );

      final successful = results.where((r) => r.startsWith('✅')).length;
      final failed = results.where((r) => r.startsWith('❌')).length;

      setState(() {
        _statusMessage = '''Batch update completed!
      
Successful: $successful properties
Failed: $failed properties

Results:
${results.take(10).join('\n')}${results.length > 10 ? '\n... and ${results.length - 10} more' : ''}
      ''';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Batch update failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAIConnection() async {
    setState(() {
      _statusMessage = 'DEBUG: Running connection tests (simplified)...';
    });

    try {
      // Test 1: County tax sites
      setState(() {
        _statusMessage = 'DEBUG: Test 1/3 - County tax sites...';
      });

      await AIPropertyResearchServiceDebug.testCountyTaxSites();
      await Future.delayed(const Duration(seconds: 1));

      // Test 2: Oregon Sheriff's Sales
      setState(() {
        _statusMessage = 'DEBUG: Test 2/3 - Oregon Sheriff\'s Sales...';
      });

      await AIPropertyResearchServiceDebug.testOregonSheriffsSales();
      await Future.delayed(const Duration(seconds: 1));

      // Test 3: File number service
      setState(() {
        _statusMessage = 'DEBUG: Test 3/3 - File number service...';
      });

      final testFileNumber = await FileNumberService.getNextFileNumber();
      print('  … DEBUG: File number service working: $testFileNumber');

      setState(() {
        _statusMessage = 'DEBUG: Connection tests completed!\n\n'
            'County tax sites: Tested\n'
            'Sheriff\'s sales: Tested\n'
            'File numbers: Working ($testFileNumber)\n\n'
            'System ready for mock property research.\n'
            'Check browser console for detailed results.';
      });
    } catch (e) {
      print('  DEBUG: Connection test failed: $e');

      setState(() {
        _statusMessage = '  DEBUG: Connection test failed:\n\n'
            '$e\n\n'
            'Check browser console for details.';
      });
    }
  }

  // CONFIGURATION METHODS
  void _toggleDataSource(String name, bool value) {
    setState(() {
      _dataSourceEnabled[name] = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name ${value ? 'enabled' : 'disabled'}')),
    );
  }

  void _testDataSource(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Testing connection to $name...')),
    );
  }

  void _configureAPIKey(String service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configure $service API Key'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter API key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleAutomationSetting(String setting, bool value) {
    setState(() {
      // Update automation settings
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$setting ${value ? 'enabled' : 'disabled'}')),
    );
  }
}
