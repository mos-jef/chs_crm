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

  // ADD THIS METHOD TO YOUR _HomeScreenState CLASS:
  // (Place it anywhere in the class, maybe after the _getNextAuctionDate method)

  void _fixAllAddresses(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fix Address Parsing'),
          content: const Text(
            'This will re-parse all property addresses to properly separate street address, city, state, and ZIP code, then generate Zillow URLs and add county information. This may take several minutes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Fix All'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Fixing addresses and enhancing properties...'),
              SizedBox(height: 8),
              Text(
                'This may take several minutes',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );

    try {
      final fixedCount =
          await context.read<PropertyProvider>().fixAllPropertyAddresses();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Successfully fixed and enhanced $fixedCount properties'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fix addresses: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _enhanceAllProperties(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enhance All Properties'),
          content: const Text(
            'This will add Zillow URLs and county information to all properties that don\'t have them yet. This may take a few moments.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enhance'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Enhancing properties...'),
            ],
          ),
        );
      },
    );

    try {
      final enhancedCount =
          await context.read<PropertyProvider>().enhanceAllProperties();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Enhanced $enhancedCount properties with Zillow URLs and county data'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enhance properties: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, PropertyFile property) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Property'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this property?'),
              const SizedBox(height: 8),
              Text(
                'File Number: ${property.fileNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Address: ${property.address}'),
              const SizedBox(height: 8),
              const Text(
                'This will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text('• Property information'),
              Text('• ${property.documents.length} documents'),
              Text('• ${property.notes.length} notes'),
              Text('• ${property.contacts.length} contacts'),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _performDelete(context, property),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }


  // REPLACE the current _performDelete method in home_screen.dart with this:

  void _performDelete(BuildContext context, PropertyFile property) async {
    // Close confirmation dialog first
    Navigator.of(context).pop();

    bool isDialogOpen = false;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        isDialogOpen = true;
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('Deleting ${property.fileNumber}...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      print('🗑️ Starting delete for property: ${property.id}');
      await context.read<PropertyProvider>().deleteProperty(property.id);
      print('✅ Delete completed successfully');
    } catch (e) {
      print('❌ Delete failed: $e');
    } finally {
      // Always ensure dialog is closed
      if (isDialogOpen && mounted) {
        print('🔄 Force closing dialog...');
        Navigator.of(context).pop(); // This will close the loading dialog
        isDialogOpen = false;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Property ${property.fileNumber} deleted'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ALSO ADD THIS ALTERNATIVE METHOD - More robust dialog handling:

  void _performDeleteRobust(BuildContext context, PropertyFile property) async {
    // Close confirmation dialog first
    Navigator.of(context).pop();

    // Create a completer to track dialog state
    bool isDialogOpen = false;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        isDialogOpen = true;
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('Deleting ${property.fileNumber}...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      print('🗑️ Starting delete for property: ${property.id}');

      // Perform the delete
      await context.read<PropertyProvider>().deleteProperty(property.id);

      print('✅ Delete completed - closing dialog');
    } catch (e) {
      print('❌ Delete failed: $e');
    } finally {
      // Always ensure dialog is closed
      if (isDialogOpen && mounted) {
        print('🔄 Force closing dialog...');
        Navigator.of(context).pop();
        isDialogOpen = false;

        // Small delay for UI to update
        await Future.delayed(const Duration(milliseconds: 200));

        // Show result message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Property ${property.fileNumber} deleted'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
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
        title: Consumer<PropertyProvider>(
          builder: (context, propertyProvider, child) {
            final totalProperties = propertyProvider.properties.length;
            final filteredCount = propertyProvider.properties.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Community Home Solutions'),
                Text(
                  '$filteredCount properties', // Shows filtered count
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [

          // property counter badge

          Consumer<PropertyProvider>(
            builder: (context, propertyProvider, child) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${propertyProvider.properties.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),

          // Fix Addresses Button
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            tooltip: 'Fix Address Parsing',
            onPressed: () => _fixAllAddresses(context),
          ),

          // ENHANCEMENT BUTTON
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Enhance Properties',
            onPressed: () => _enhanceAllProperties(context),
          ),


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

          /*
          // 🟢 ADD THE QUICK FILTER CHIPS HERE 🟢
          // Quick Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<PropertyProvider>(
              builder: (context, propertyProvider, child) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Bank Owned Filter
                      FilterChip(
                        label: const Text('Bank Owned'),
                        selected: propertyProvider.advancedSearchCriteria.containsKey('bankOwned'),
                        onSelected: (selected) {
                          if (selected) {
                            propertyProvider.setAdvancedSearchCriteria({
                              ...propertyProvider.advancedSearchCriteria,
                              'bankOwned': true,
                            });
                          } else {
                            final newCriteria = Map<String, dynamic>.from(
                              propertyProvider.advancedSearchCriteria,
                            );
                            newCriteria.remove('bankOwned');
                            propertyProvider.setAdvancedSearchCriteria(newCriteria);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      
                      FilterChip(
                        label: const Text('Under \$200K'),
                        selected: propertyProvider.advancedSearchCriteria.containsKey('under200k'),
                        onSelected: (selected) {
                          if (selected) {
                            propertyProvider.setAdvancedSearchCriteria({
                              ...propertyProvider.advancedSearchCriteria,
                              'maxLoan': 200000,
                              'under200k': true,
                            });
                          } else {
                            final newCriteria = Map<String, dynamic>.from(
                              propertyProvider.advancedSearchCriteria,
                            );
                            newCriteria.remove('maxLoan');
                            newCriteria.remove('under200k');
                            propertyProvider.setAdvancedSearchCriteria(newCriteria);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      
                      FilterChip(
                        label: const Text('Portland'),
                        selected: propertyProvider.advancedSearchCriteria['city'] == 'Portland',
                        onSelected: (selected) {
                          if (selected) {
                            propertyProvider.setAdvancedSearchCriteria({
                              ...propertyProvider.advancedSearchCriteria,
                              'city': 'Portland',
                            });
                          } else {
                            final newCriteria = Map<String, dynamic>.from(
                              propertyProvider.advancedSearchCriteria,
                            );
                            newCriteria.remove('city');
                            propertyProvider.setAdvancedSearchCriteria(newCriteria);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          */

          // Sorting Options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.sort, size: 20),
                const SizedBox(width: 8),
                const Text('Sort by:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Expanded(
                  child: Consumer<PropertyProvider>(
                    builder: (context, propertyProvider, child) {
                      return DropdownButton<String>(
                        isExpanded: true,
                        value: propertyProvider.currentSortOption,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            propertyProvider.setSortOption(newValue);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'fileNumber_asc',
                            child: Text('File Number (Oldest First)'),
                          ),
                          DropdownMenuItem(
                            value: 'fileNumber_desc',
                            child: Text('File Number (Newest First)'),
                          ),
                          DropdownMenuItem(
                            value: 'saleDate_asc',
                            child: Text('Sale Date (Earliest First)'),
                          ),
                          DropdownMenuItem(
                            value: 'saleDate_desc',
                            child: Text('Sale Date (Latest First)'),
                          ),
                          DropdownMenuItem(
                            value: 'totalOwed_asc',
                            child: Text('Total Owed (Low to High)'),
                          ),
                          DropdownMenuItem(
                            value: 'totalOwed_desc',
                            child: Text('Total Owed (High to Low)'),
                          ),
                          DropdownMenuItem(
                            value: 'loanAmount_asc',
                            child: Text('Loan Amount (Low to High)'),
                          ),
                          DropdownMenuItem(
                            value: 'loanAmount_desc',
                            child: Text('Loan Amount (High to Low)'),
                          ),
                          DropdownMenuItem(
                            value: 'address_asc',
                            child: Text('Address (A-Z)'),
                          ),
                          DropdownMenuItem(
                            value: 'city_asc',
                            child: Text('City (A-Z)'),
                          ),
                        ],
                      );
                    },
                  ),
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

                                if (property.amountOwed != null)
                                  Text(
                                    'Amount Owed: \$${NumberFormat('#,##0.00').format(property.amountOwed!)}',
                                    style: TextStyle(
                                      color: AppThemes.getAmountOwedColor(
                                        themeProvider.currentTheme,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (property.arrears != null)
                                  Text(
                                    'Arrears: \$${NumberFormat('#,##0.00').format(property.arrears!)}',
                                    style: TextStyle(
                                      color: AppThemes.getArrearsColor(
                                        themeProvider.currentTheme,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                // Estimated Profit Line

                                if (property.estimatedProfitMargin != null)
                                  Text(
                                    'Est. Profit: \$${NumberFormat('#,##0.00').format(property.estimatedProfitMargin!)}',
                                    style: TextStyle(
                                      color: AppThemes.getLoanAmountColor(
                                        themeProvider.currentTheme,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                // SALE DATE LINE:

                                if (_getNextAuctionDate(property) != null)
                                  Text(
                                    'Sale Date: ${_getNextAuctionDate(property)}',
                                    style: TextStyle(
                                      color: AppThemes.getTotalOwedColor(
                                        themeProvider.currentTheme,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ), 


                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Delete button
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[600],
                                size: 20,
                              ),
                              onPressed: () =>
                                  _showDeleteConfirmation(context, property),
                              tooltip: 'Delete Property',
                            ),
                            // Navigate button
                            Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
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
