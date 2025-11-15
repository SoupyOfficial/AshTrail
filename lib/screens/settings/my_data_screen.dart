import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/user_profile_provider.dart';

class MyDataScreen extends ConsumerStatefulWidget {
  const MyDataScreen({super.key});

  @override
  ConsumerState<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends ConsumerState<MyDataScreen> {
  bool _isLoading = false;
  String? _exportData;
  bool _isRefreshing = false;

  Future<void> _refreshStatistics() async {
    setState(() {
      _isRefreshing = true;
    });

    // Force refresh the statistics provider
    ref.refresh(userStatisticsProvider);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _exportUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final exportData = await userProfileService.exportUserData();

      setState(() {
        _exportData = exportData;
      });

      // Success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Data exported successfully. You can copy it from below.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export data: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_exportData == null) return;

    Clipboard.setData(ClipboardData(text: _exportData!));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data copied to clipboard')),
    );
  }

  Future<void> _deleteUserData() async {
    // First confirmation dialog
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'Are you sure you want to delete all your data from the server?\n\n'
          'WARNING: This action is PERMANENT and CANNOT be undone. All your logs '
          'and tracking history will be permanently erased.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    // Second confirmation dialog with "DELETE" text to type
    final TextEditingController confirmController = TextEditingController();
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will PERMANENTLY delete all your data. '
              'This action is IRREVERSIBLE and all your tracking history will be lost forever.\n\n'
              'To confirm, please type "DELETE" below:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(
              confirmController.text == 'DELETE',
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    confirmController.dispose();

    if (confirm2 != true) return;

    // Third and final confirmation dialog
    final confirm3 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Warning'),
        content: const Text(
          'You are about to PERMANENTLY ERASE all your data.\n\n'
          'This is your FINAL WARNING.\n\n'
          'Once confirmed, you CANNOT recover your data.',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Go Back'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm3 != true) return;

    // Perform the deletion
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfileService = ref.read(userProfileServiceProvider);

      // Export the data first as a backup
      final exportData = await userProfileService.exportUserData();
      setState(() {
        _exportData = exportData;
      });

      // Delete all user data but keep the account
      // Updated to call the public method instead of the private one
      await userProfileService.deleteAllUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All your data has been deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete data: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statisticsAsync = ref.watch(userStatisticsProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'My Data',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Statistics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pull down to refresh'),
                  if (_isRefreshing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Statistics with improved error handling
              statisticsAsync.when(
                data: (stats) {
                  final logCount = stats['logCount'] ?? 0;
                  final firstLogDate = stats['firstLogDate'] as DateTime?;
                  final totalDuration =
                      stats['totalDuration'] as double? ?? 0.0;

                  // Format information with null safety
                  final formattedFirstLog = firstLogDate != null
                      ? DateFormat('MMM d, y').format(firstLogDate)
                      : 'No logs yet';

                  // Format duration as hours:minutes:seconds
                  final durationHours = (totalDuration / 3600).floor();
                  final durationMinutes = ((totalDuration % 3600) / 60).floor();
                  final durationSeconds = (totalDuration % 60).floor();

                  final formattedDuration = totalDuration <= 0
                      ? '0s'
                      : durationHours > 0
                          ? '${durationHours}h ${durationMinutes}m ${durationSeconds}s'
                          : durationMinutes > 0
                              ? '${durationMinutes}m ${durationSeconds}s'
                              : '${durationSeconds}s';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.analytics_outlined),
                            title: const Text('Total logs'),
                            trailing: Text(
                              '$logCount',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.calendar_month),
                            title: const Text('First log date'),
                            trailing: Text(formattedFirstLog),
                          ),
                          ListTile(
                            leading: const Icon(Icons.timer_outlined),
                            title: const Text('Total duration'),
                            trailing: Text(formattedDuration),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading statistics',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          error.toString(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.refresh(userStatisticsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Data Management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Export data button
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Export My Data'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _exportUserData,
              ),

              const SizedBox(height: 16),

              // Delete data button
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete All My Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _deleteUserData,
              ),

              // Show exported data if available
              if (_exportData != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Exported Data',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy to Clipboard'),
                      onPressed: _copyToClipboard,
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  height: 200,
                  child: SingleChildScrollView(
                    child: Text(_exportData!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
