// lib/screens/enhanced_automation_dashboard.dart
import 'package:chs_crm/taxes/oregon/oregon_county_tax_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property_file.dart';
import '../providers/property_provider.dart';
import '../services/oregon_foreclosure_crawler.dart';
import '../screens/automation_settings_screen.dart';
import '../widgets/custom_beam_button.dart';

class EnhancedAutomationDashboard extends StatefulWidget {
  const EnhancedAutomationDashboard({super.key});

  @override
  State<EnhancedAutomationDashboard> createState() =>
      _EnhancedAutomationDashboardState();
}

class _EnhancedAutomationDashboardState
    extends State<EnhancedAutomationDashboard> {
  bool _isRunningCrawl = false;
  String _crawlStatus = '';
  List<PropertyFile> _crawledProperties = [];
  int _totalFound = 0;
  int _successfullySaved = 0;
  DateTime? _lastCrawlTime;

  // Configuration options
  int _maxProperties = 100;
  bool _includeREO = true;
  bool _autoSaveToCRM = true;
  final List<String> _selectedCounties = [];

  final List<String> _oregonCounties = [
    'Multnomah',
    'Washington',
    'Clackamas',
    'Marion',
    'Lane',
    'Jackson',
    'Douglas',
    'Yamhill',
    'Polk',
    'Linn',
    'Benton'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏠 Oregon Foreclosure Automation'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AutomationSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActionCard(),
            const SizedBox(height: 20),
            _buildConfigurationCard(),
            const SizedBox(height: 20),
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildResultsCard(),
            const SizedBox(height: 20),
            _buildSchedulingCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on,
                    color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Quick Start',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Automatically crawl all Oregon foreclosure listings and import them into your CRM.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunningCrawl ? null : _startFullCrawl,
                    icon: Icon(_isRunningCrawl
                        ? Icons.hourglass_empty
                        : Icons.play_arrow),
                    label: Text(
                        _isRunningCrawl ? 'Crawling...' : 'Start Full Crawl'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isRunningCrawl ? null : _startTestCrawl,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Test Run (10)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_lastCrawlTime != null)
              Text(
                'Last crawl: ${_formatDateTime(_lastCrawlTime!)} • Found $_totalFound properties • Saved $_successfullySaved',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crawl Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Max Properties Slider
            Row(
              children: [
                const Text('Max Properties: ',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Expanded(
                  child: Slider(
                    value: _maxProperties.toDouble(),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: '$_maxProperties',
                    onChanged: (value) =>
                        setState(() => _maxProperties = value.round()),
                  ),
                ),
                Text('$_maxProperties'),
              ],
            ),

            // Include REO Properties
            SwitchListTile(
              title: const Text('Include REO/Bank-Owned Properties'),
              subtitle: const Text('Include properties already owned by banks'),
              value: _includeREO,
              onChanged: (value) => setState(() => _includeREO = value),
              dense: true,
            ),

            // Auto-save to CRM
            SwitchListTile(
              title: const Text('Auto-save to CRM'),
              subtitle: const Text(
                  'Automatically add found properties to your database'),
              value: _autoSaveToCRM,
              onChanged: (value) => setState(() => _autoSaveToCRM = value),
              dense: true,
            ),

            const SizedBox(height: 12),

            // County Selection
            const Text('Target Counties:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _oregonCounties
                  .map((county) => FilterChip(
                        label: Text(county),
                        selected: _selectedCounties.contains(county),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCounties.add(county);
                            } else {
                              _selectedCounties.remove(county);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),

            if (_selectedCounties.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No counties selected - will search all Oregon counties',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
                  _isRunningCrawl ? Icons.sync : Icons.info_outline,
                  color: _isRunningCrawl
                      ? Colors.orange
                      : Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRunningCrawl ? 'Crawl Status' : 'System Status',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isRunningCrawl) ...[
              LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRunningCrawl ? Colors.orange[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isRunningCrawl ? Colors.orange : Colors.blue,
                  width: 1,
                ),
              ),
              child: Text(
                _crawlStatus.isNotEmpty
                    ? _crawlStatus
                    : 'Ready to crawl Oregon foreclosure listings. Click "Start Full Crawl" to begin.',
                style: TextStyle(
                  color:
                      _isRunningCrawl ? Colors.orange[800] : Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_isRunningCrawl) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _stopCrawl,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Crawl'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Crawl Results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_crawledProperties.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _viewCrawledProperties,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Properties'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_crawledProperties.isEmpty)
              const Text(
                'No properties crawled yet. Start a crawl to see results here.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              )
            else ...[
              Row(
                children: [
                  _buildStatCard('Found', _totalFound.toString(), Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatCard(
                      'Saved', _successfullySaved.toString(), Colors.green),
                  const SizedBox(width: 12),
                  _buildStatCard(
                      'Errors',
                      (_totalFound - _successfullySaved).toString(),
                      Colors.red),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Recent Properties:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ..._crawledProperties
                  .take(5)
                  .map((property) => Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.home,
                              color: Theme.of(context).primaryColor),
                          title: Text(property.address),
                          subtitle: Text(
                              '${property.city}, ${property.state} ${property.zipCode}'),
                          trailing: property.auctions.isNotEmpty
                              ? Text(
                                  '${property.auctions.first.auctionDate.toString().substring(0, 10)}')
                              : null,
                        ),
                      ))
                  .toList(),
              if (_crawledProperties.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${_crawledProperties.length - 5} more properties',
                    style: const TextStyle(
                        fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Automated Scheduling',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Set up automatic crawling to keep your foreclosure data current.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Daily Auto-Crawl'),
              subtitle: const Text('Run full crawl every day at 6 AM'),
              value: false, // TODO: Implement scheduling
              onChanged: null, // TODO: Implement
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Weekly Deep Scan'),
              subtitle: const Text('Comprehensive scan every Sunday'),
              value: false, // TODO: Implement scheduling
              onChanged: null, // TODO: Implement
              dense: true,
            ),
            const SizedBox(height: 8),
            Text(
              '⚙️ Automated scheduling coming soon!',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  // Action methods
  Future<void> _startFullCrawl() async {
    setState(() {
      _isRunningCrawl = true;
      _crawlStatus = 'Initializing Oregon foreclosure crawl...';
      _crawledProperties.clear();
      _totalFound = 0;
      _successfullySaved = 0;
    });

    try {
      // Update status
      setState(() {
        _crawlStatus =
            '🌐 Crawling Auction.com, RealtyTrac, and other sites...';
      });

      final results = await OregonForeclosureCrawler.crawlAllOregonForeclosures(
        context: context,
        maxProperties: _maxProperties,
        includeREO: _includeREO,
        specificCounties: _selectedCounties.isEmpty ? null : _selectedCounties,
      );

      setState(() {
        _crawledProperties = results;
        _totalFound = results.length;
        _successfullySaved = results.length; // All were saved if no exception
        _crawlStatus =
            '✅ Crawl completed! Found ${results.length} properties and ${_autoSaveToCRM ? 'saved to CRM' : 'ready for review'}.';
        _lastCrawlTime = DateTime.now();
        _isRunningCrawl = false;
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Crawl Complete'),
            content: Text(
                'Successfully found ${results.length} foreclosure properties!\n\n'
                '${_autoSaveToCRM ? 'All properties have been automatically added to your CRM.' : 'Properties are ready for manual review and import.'}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              if (results.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _viewCrawledProperties();
                  },
                  child: const Text('View Properties'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _crawlStatus = '❌ Crawl failed: ${e.toString()}';
        _isRunningCrawl = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crawl failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startTestCrawl() async {
    setState(() {
      _isRunningCrawl = true;
      _crawlStatus = 'Running test crawl (limited to 10 properties)...';
    });

    try {
      final results = await OregonForeclosureCrawler.crawlAllOregonForeclosures(
        context: context,
        maxProperties: 10,
        includeREO: _includeREO,
        specificCounties: _selectedCounties.isEmpty ? null : _selectedCounties,
      );

      setState(() {
        _crawledProperties = results;
        _totalFound = results.length;
        _successfullySaved = results.length;
        _crawlStatus =
            '✅ Test crawl completed! Found ${results.length} properties.';
        _lastCrawlTime = DateTime.now();
        _isRunningCrawl = false;
      });
    } catch (e) {
      setState(() {
        _crawlStatus = '❌ Test crawl failed: ${e.toString()}';
        _isRunningCrawl = false;
      });
    }
  }

  void _stopCrawl() {
    setState(() {
      _crawlStatus = 'Crawl stopped by user';
      _isRunningCrawl = false;
    });
  }

  void _viewCrawledProperties() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Crawled Properties'),
          ),
          body: ListView.builder(
            itemCount: _crawledProperties.length,
            itemBuilder: (context, index) {
              final property = _crawledProperties[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading:
                      Icon(Icons.home, color: Theme.of(context).primaryColor),
                  title: Text(property.address),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${property.city}, ${property.state} ${property.zipCode}'),
                      if (property.auctions.isNotEmpty)
                        Text(
                            'Auction: ${property.auctions.first.auctionDate.toString().substring(0, 10)}'),
                      if (property.taxAccountNumber?.isNotEmpty == true)
                        Text('APN: ${property.taxAccountNumber}'),
                    ],
                  ),
                  trailing: property.auctions.isNotEmpty &&
                          property.auctions.first.openingBid != null
                      ? Text(
                          '\${property.auctions.first.openingBid!.toStringAsFixed(0)}')
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
