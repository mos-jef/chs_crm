// lib/screens/automation_settings_screen.dart
import 'package:flutter/material.dart';
import '../services/automation_config.dart';
import '../widgets/custom_beam_button.dart';

class AutomationSettingsScreen extends StatefulWidget {
  const AutomationSettingsScreen({super.key});

  @override
  State<AutomationSettingsScreen> createState() =>
      _AutomationSettingsScreenState();
}

class _AutomationSettingsScreenState extends State<AutomationSettingsScreen> {
  final _proxyUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _autoCrawlEnabled = false;
  int _crawlInterval = 24;
  int _maxProperties = 100;
  bool _isTestingProxy = false;
  String _proxyTestResult = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _proxyUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    final config = AutomationConfig.instance;

    final proxyUrl = await config.getProxyUrl();
    final autoCrawl = await config.getAutoCrawlEnabled();
    final interval = await config.getCrawlInterval();
    final maxProps = await config.getMaxProperties();

    setState(() {
      _proxyUrlController.text = proxyUrl;
      _autoCrawlEnabled = autoCrawl;
      _crawlInterval = interval;
      _maxProperties = maxProps;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final config = AutomationConfig.instance;

    try {
      await config.setProxyUrl(_proxyUrlController.text.trim());
      await config.setAutoCrawlEnabled(_autoCrawlEnabled);
      await config.setCrawlInterval(_crawlInterval);
      await config.setMaxProperties(_maxProperties);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testProxyConnection() async {
    setState(() {
      _isTestingProxy = true;
      _proxyTestResult = 'Testing proxy connection...';
    });

    // Save the current proxy URL first
    await AutomationConfig.instance
        .setProxyUrl(_proxyUrlController.text.trim());

    try {
      final isWorking = await AutomationConfig.instance.testProxyConnection();

      setState(() {
        _proxyTestResult = isWorking
            ? '✅ Proxy connection successful!'
            : '❌ Proxy connection failed - please check the URL';
        _isTestingProxy = false;
      });
    } catch (e) {
      setState(() {
        _proxyTestResult = '❌ Proxy test error: ${e.toString()}';
        _isTestingProxy = false;
      });
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
            'Are you sure you want to reset all automation settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AutomationConfig.instance.resetToDefaults();
      await _loadCurrentSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Settings reset to defaults'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Automation Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Automation Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProxyConfigCard(),
              const SizedBox(height: 20),
              _buildAutoCrawlCard(),
              const SizedBox(height: 20),
              _buildPerformanceCard(),
              const SizedBox(height: 20),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProxyConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vpn_lock, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Proxy Server Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Your proxy server handles CORS issues when scraping auction sites. '
              'Make sure your Render deployment is running before testing.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _proxyUrlController,
              decoration: const InputDecoration(
                labelText: 'Proxy Server URL',
                hintText: 'https://your-proxy-server.onrender.com/proxy?url=',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your proxy server URL';
                }
                if (!Uri.tryParse(value)!.isAbsolute) {
                  return 'Please enter a valid URL';
                }
                if (!value.contains('proxy') || !value.endsWith('url=')) {
                  return 'URL should end with "proxy?url=" or similar';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isTestingProxy ? null : _testProxyConnection,
                  icon: Icon(_isTestingProxy
                      ? Icons.hourglass_empty
                      : Icons.wifi_protected_setup),
                  label:
                      Text(_isTestingProxy ? 'Testing...' : 'Test Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),

            if (_proxyTestResult.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _proxyTestResult.startsWith('✅')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _proxyTestResult.startsWith('✅')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _proxyTestResult,
                  style: TextStyle(
                    color: _proxyTestResult.startsWith('✅')
                        ? Colors.green[800]
                        : Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAutoCrawlCard() {
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
                  'Automatic Crawling',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable Auto-Crawl'),
              subtitle: const Text(
                  'Automatically crawl foreclosure sites at regular intervals'),
              value: _autoCrawlEnabled,
              onChanged: (value) => setState(() => _autoCrawlEnabled = value),
              dense: true,
            ),
            if (_autoCrawlEnabled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Crawl Every: ',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  Expanded(
                    child: Slider(
                      value: _crawlInterval.toDouble(),
                      min: 1,
                      max: 168, // 1 week
                      divisions: 23,
                      label: '${_crawlInterval}h',
                      onChanged: (value) =>
                          setState(() => _crawlInterval = value.round()),
                    ),
                  ),
                  Text('${_crawlInterval}h'),
                ],
              ),
              Text(
                _crawlInterval < 12
                    ? '⚠️ Frequent crawling may trigger rate limits'
                    : _crawlInterval > 72
                        ? '💡 Consider more frequent crawls for active markets'
                        : '✅ Good balance of freshness and server load',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: _crawlInterval < 12 ? Colors.orange : Colors.grey[600],
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '⚙️ Auto-crawl is disabled. You can still run manual crawls from the dashboard.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Performance Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Max Properties Per Crawl: ',
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
            Text(
              _maxProperties < 50
                  ? '💡 Lower limits = faster crawls, less server load'
                  : _maxProperties > 200
                      ? '⚠️ High limits may take longer and use more resources'
                      : '✅ Balanced setting for comprehensive coverage',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveSettings,
        icon: const Icon(Icons.save),
        label: const Text('Save Settings'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
