import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Selection',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Column(
                        children: [
                          // Theme Style Selection - Updated RadioGroup pattern
                          Text(
                            'Theme Style',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          RadioListTile<String>(
                            title: const Text('Athlete Theme'),
                            subtitle: const Text(
                              'Warm colors with orange/red accents',
                            ),
                            value: 'athlete',
                            groupValue: themeProvider.isAthleteTheme
                                ? 'athlete'
                                : 'ninja',
                            onChanged: (value) {
                              if (value == 'athlete') {
                                themeProvider.switchToAthlete();
                              }
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Ninja Theme'),
                            subtitle: const Text(
                              'Cool colors with teal/green accents',
                            ),
                            value: 'ninja',
                            groupValue: themeProvider.isAthleteTheme
                                ? 'athlete'
                                : 'ninja',
                            onChanged: (value) {
                              if (value == 'ninja') {
                                themeProvider.switchToNinja();
                              }
                            },
                          ),
                          const Divider(),
                          // Light/Dark Mode Selection
                          Text(
                            'Brightness',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SwitchListTile(
                            title: const Text('Dark Mode'),
                            subtitle: Text(
                              'Currently: ${themeProvider.themeDisplayName}',
                            ),
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.toggleLightDark();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () {
                      context.read<AuthProvider>().signOut();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
