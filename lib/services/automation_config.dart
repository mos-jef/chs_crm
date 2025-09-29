// lib/services/automation_config.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AutomationConfig {
  static const String _proxyUrlKey = 'proxy_server_url';
  static const String _enableAutoCrawlKey = 'enable_auto_crawl';
  static const String _crawlIntervalKey = 'crawl_interval_hours';
  static const String _maxPropertiesKey = 'max_properties_per_crawl';

  static AutomationConfig? _instance;
  static AutomationConfig get instance => _instance ??= AutomationConfig._();

  AutomationConfig._();

  // Default configuration values
  static const String DEFAULT_PROXY_URL =
      'https://your-proxy-server.onrender.com/proxy?url=';
  static const bool DEFAULT_AUTO_CRAWL = false;
  static const int DEFAULT_CRAWL_INTERVAL = 24; // hours
  static const int DEFAULT_MAX_PROPERTIES = 100;

  /// Get proxy server URL
  Future<String> getProxyUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_proxyUrlKey) ?? DEFAULT_PROXY_URL;
  }

  /// Set proxy server URL
  Future<void> setProxyUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_proxyUrlKey, url);
  }

  /// Get auto-crawl enabled status
  Future<bool> getAutoCrawlEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enableAutoCrawlKey) ?? DEFAULT_AUTO_CRAWL;
  }

  /// Set auto-crawl enabled status
  Future<void> setAutoCrawlEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableAutoCrawlKey, enabled);
  }

  /// Get crawl interval in hours
  Future<int> getCrawlInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_crawlIntervalKey) ?? DEFAULT_CRAWL_INTERVAL;
  }

  /// Set crawl interval in hours
  Future<void> setCrawlInterval(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_crawlIntervalKey, hours);
  }

  /// Get max properties per crawl
  Future<int> getMaxProperties() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxPropertiesKey) ?? DEFAULT_MAX_PROPERTIES;
  }

  /// Set max properties per crawl
  Future<void> setMaxProperties(int max) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxPropertiesKey, max);
  }

  /// Test proxy connectivity
  Future<bool> testProxyConnection() async {
    try {
      final proxyUrl = await getProxyUrl();
      final testUrl = 'https://httpbin.org/get';

      // Import http directly
      final response = await http.get(
        Uri.parse('$proxyUrl${Uri.encodeComponent(testUrl)}'),
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; CRM Test)'},
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Proxy test failed: $e');
      return false;
    }
  }

  /// Get all configuration as a map
  Future<Map<String, dynamic>> getAllConfig() async {
    return {
      'proxyUrl': await getProxyUrl(),
      'autoCrawlEnabled': await getAutoCrawlEnabled(),
      'crawlInterval': await getCrawlInterval(),
      'maxProperties': await getMaxProperties(),
    };
  }

  /// Validate configuration
  Future<Map<String, bool>> validateConfig() async {
    final config = await getAllConfig();

    return {
      'proxyUrlValid': Uri.tryParse(config['proxyUrl']) != null,
      'proxyConnected': await testProxyConnection(),
      'intervalValid': config['crawlInterval'] > 0 &&
          config['crawlInterval'] <= 168, // Max 1 week
      'maxPropertiesValid':
          config['maxProperties'] > 0 && config['maxProperties'] <= 1000,
    };
  }

  /// Reset to default configuration
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_proxyUrlKey);
    await prefs.remove(_enableAutoCrawlKey);
    await prefs.remove(_crawlIntervalKey);
    await prefs.remove(_maxPropertiesKey);
  }
}
