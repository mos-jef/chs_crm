// lib/main.dart
import 'package:chs_crm/screens/automation_dashboard.dart';
import 'package:chs_crm/screens/enhanced_automation_dashboard.dart'; // ADD THIS IMPORT
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_services.dart';
import 'providers/auth_provider.dart';
import 'providers/property_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/admin_dashboard.dart';
import 'utils/app_themes.dart';
import 'screens/pdf_upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Community Home Solutions',
            theme: AppThemes.getTheme(themeProvider.currentTheme),
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        if (authProvider.user == null) {
          return const LoginScreen();
        }

        if (!authProvider.isApproved) {
          return const PendingApprovalScreen();
        }

        return const MainScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Add PDF Upload as a separate tab
    final List<Widget> screens = [
      const HomeScreen(),
      const EnhancedAutomationDashboard(), // Auto Crawl
      const AutomationDashboard(), // Auto Dashboard
      const PdfUploadScreen(), // NEW: PDF Upload
      if (authProvider.isAdmin) const AdminDashboard(),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      
      // const BottomNavigationBarItem(
       // icon: Icon(Icons.auto_awesome),
         //label: 'Auto Crawl',
      //),
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_customize),
        label: 'Auto Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.upload_file),
        label: 'PDF Upload',
      ),
      if (authProvider.isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

