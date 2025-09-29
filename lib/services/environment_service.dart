// lib/services/environment_service.dart
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

@JS('window.ENV')
external JSObject? get _env;

class EnvironmentService {
  static EnvironmentService? _instance;
  static EnvironmentService get instance =>
      _instance ??= EnvironmentService._();

  EnvironmentService._();

  // 🔑 Claude API Key (private getter)
  static String? get _claudeApiKey {
    try {
      final env = _env;
      if (env != null) {
        final key = env.getProperty('CLAUDE_API_KEY'.toJS);
        final keyString = key?.dartify() as String?;
        return (keyString != null && keyString.isNotEmpty) ? keyString : null;
      }
    } catch (e) {
      print('Error getting Claude API key: $e');
    }
    return null;
  }

  // ✅ Public getter to use in validateConfiguration or outside the class
  String? get claudeApiKey => _claudeApiKey;

  // 🌐 CORS Proxies
  List<String> get corsProxies {
    try {
      final env = _env;
      if (env != null) {
        final proxies = env.getProperty('CORS_PROXIES'.toJS);
        if (proxies is JSArray) {
          final list = proxies.dartify() as List;
          return List<String>.from(list);
        }
      }
    } catch (e) {
      print('⚠️ Error getting CORS proxies: $e');
    }

    // Fallback to default proxies
    return [
      'https://corsproxy.io/?',
      'https://api.codetabs.com/v1/proxy?quest=',
      'https://cors-anywhere.herokuapp.com/',
    ];
  }


  // 🔧 Development Mode Check
  bool get isDevelopment {
    try {
      final env = _env;
      if (env != null) {
        final isDev = env.getProperty('isDevelopment'.toJS)?.dartify();
        return isDev is bool ? isDev : false;

      }
    } catch (e) {
      print('⚠️ Error checking development mode: $e');
    }

    // Fallback check
    return web.window.location.hostname == 'localhost' ||
        web.window.location.hostname == '127.0.0.1';
  }

  // 🧪 Debug Methods
  void debugConfiguration() {
    print('🔧 Environment Configuration:');
    print('  Development Mode: $isDevelopment');
    print('  Claude API Key: ${_claudeApiKey != null ? "✅ Set (${_claudeApiKey!.substring(0, 12)}...)" : "❌ Missing"}');
    print('  CORS Proxies Available: ${corsProxies.length}');

    for (int i = 0; i < corsProxies.length; i++) {
      print('    ${i + 1}. ${corsProxies[i]}');
    }
  }

  // 🌐 Test CORS Proxy
  Future<bool> testCorsProxy(int proxyIndex) async {
    if (proxyIndex < 0 || proxyIndex >= corsProxies.length) {
      print('❌ Invalid proxy index: $proxyIndex');
      return false;
    }

    final proxy = corsProxies[proxyIndex];
    final testUrl = 'https://httpbin.org/get';

    print('🧪 Testing CORS proxy: $proxy');

    try {
      final responsePromise = web.window.fetch(
        '${proxy}$testUrl'.toJS,
        web.RequestInit(
          method: 'GET',
          headers: {'User-Agent': 'Mozilla/5.0 ...'}.jsify() as JSObject,
        ),
      );

      final response =
          await responsePromise.toDart; // Convert to Dart Future<Response>


      if (response.ok) {
        print('✅ Proxy ${proxyIndex + 1} working');
        return true;
      } else {
        print('❌ Proxy ${proxyIndex + 1} failed: HTTP ${response.status}');
        return false;
      }
    } catch (e) {
      print('❌ Proxy ${proxyIndex + 1} error: $e');
      return false;
    }
  }

  // 🔍 Test All CORS Proxies
  Future<List<bool>> testAllCorsProxies() async {
    print('🧪 Testing all CORS proxies...');
    final results = <bool>[];

    for (int i = 0; i < corsProxies.length; i++) {
      final result = await testCorsProxy(i);
      results.add(result);

      // Rate limit between tests
      await Future.delayed(const Duration(seconds: 1));
    }

    final workingCount = results.where((r) => r).length;
    print(
        '📊 Test Results: $workingCount/${corsProxies.length} proxies working');

    return results;
  }

  // 🌐 Get Best Working Proxy
  Future<String?> getBestWorkingProxy() async {
    for (int i = 0; i < corsProxies.length; i++) {
      if (await testCorsProxy(i)) {
        print('🎯 Best working proxy: ${corsProxies[i]}');
        return corsProxies[i];
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print('❌ No working CORS proxies found');
    return null;
  }

  // 🔧 Validate Configuration
  Map<String, dynamic> validateConfiguration() {
    final apiKey = EnvironmentService.instance.claudeApiKey;

    return {
      'isDevelopment': isDevelopment,
      'claudeApiKey': {
        'present': apiKey != null,
        'length': apiKey?.length ?? 0,
        'valid': apiKey != null && apiKey.startsWith('sk-ant-'),
      },
      'corsProxies': {
        'count': corsProxies.length,
        'proxies': corsProxies,
      },
      'browser': {
        'hostname': web.window.location.hostname,
        'protocol': web.window.location.protocol,
      }
    };
  }
}
