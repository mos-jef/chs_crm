import 'package:chs_crm/providers/theme_provider.dart';
import 'package:chs_crm/screens/settings_screen.dart';
import 'package:chs_crm/utils/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../models/property_file.dart';
import '../widgets/advanced_search_dialog.dart';
import 'property_detail_screen.dart';
import 'add_property_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? _getNextAuctionDate(PropertyFile property) {
    if (property.auctions.isEmpty) return null;

    // Find the next upcoming auction (not completed) or the most recent one
    Auction? nextAuction;

    // First try to find an upcoming auction
    for (var auction in property.auctions) {
      if (!auction.auctionCompleted) {
        if (nextAuction == null ||
            auction.auctionDate.isBefore(nextAuction.auctionDate)) {
          nextAuction = auction;
        }
      }
    }

    // If no upcoming auctions, get the most recent completed one
    if (nextAuction == null) {
      for (var auction in property.auctions) {
        if (nextAuction == null ||
            auction.auctionDate.isAfter(nextAuction.auctionDate)) {
          nextAuction = auction;
        }
      }
    }

    if (nextAuction == null) return null;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[nextAuction.auctionDate.month - 1]} ${nextAuction.auctionDate.day}, ${nextAuction.auctionDate.year}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAdvancedSearch() {
    showDialog(
      context: context,
      builder:
          (context) => AdvancedSearchDialog(
            onSearch: (criteria) {
              context.read<PropertyProvider>().setAdvancedSearchCriteria(
                criteria,
              );
              _searchController.clear();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Home Solutions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PropertyProvider>().loadProperties();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by file number or address...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<PropertyProvider>()
                                      .setSearchQuery('');
                                },
                              )
                              : null,
                    ),
                    onChanged: (value) {
                      context.read<PropertyProvider>().setSearchQuery(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showAdvancedSearch,
                  icon: const Icon(Icons.tune),
                  tooltip: 'Advanced Search',
                ),
              ],
            ),
          ),

          // Active Search Indicator
          Consumer<PropertyProvider>(
            builder: (context, propertyProvider, child) {
              if (propertyProvider.advancedSearchCriteria.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Advanced search active (${propertyProvider.advancedSearchCriteria.length} criteria)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<PropertyProvider>().clearAllSearch();
                        },
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Properties List
          Expanded(
            child: Consumer<PropertyProvider>(
              builder: (context, propertyProvider, child) {
                if (propertyProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final properties = propertyProvider.properties;

                if (properties.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          propertyProvider.searchQuery.isNotEmpty ||
                                  propertyProvider
                                      .advancedSearchCriteria
                                      .isNotEmpty
                              ? 'No properties match your search'
                              : 'No properties found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        if (propertyProvider.searchQuery.isEmpty &&
                            propertyProvider
                                .advancedSearchCriteria
                                .isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Add your first property to get started',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            property.fileNumber.isNotEmpty
                                ? property.fileNumber
                                    .substring(0, 1)
                                    .toUpperCase()
                                : '#',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          property.fileNumber.isNotEmpty
                              ? '${property.fileNumber}'
                              : 'No File Number',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppThemes.getFileNumberColor(
                              context.watch<ThemeProvider>().currentTheme,
                            ),
                          ),
                        ),

                        subtitle: Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(property.address),
                                Text(
                                  '${property.city}, ${property.state} ${property.zipCode}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                  ),
                                ),
                                if (property.loanAmount != null)
                                  Text(
                                    'Loan: \$${NumberFormat('#,##0.00').format(property.loanAmount!)}',
                                    style: TextStyle(
                                      color: AppThemes.getLoanAmountColor(
                                        themeProvider.currentTheme,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (property.loanAmount != null ||
                                    property.amountOwed != null ||
                                    property.arrears != null)
                                  Text(
                                    'Total Owed: \$${NumberFormat('#,##0.00').format(property.totalOwed)}',
                                    style: TextStyle(
                                      color: AppThemes.getTotalOwedColor(
                                        themeProvider.currentTheme,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                // ADD THIS NEW SALE DATE LINE:
                                if (_getNextAuctionDate(property) != null)
                                  Text(
                                    'Sale Date: ${_getNextAuctionDate(property)}',
                                    style: TextStyle(
                                      color: AppThemes.getAmountOwedColor(
                                        themeProvider.currentTheme,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ), 
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PropertyDetailScreen(property: property),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
