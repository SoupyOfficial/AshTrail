import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/log_providers.dart';
import '../widgets/add_log_form.dart';
import '../widgets/info_display.dart';
import '../widgets/rating_slider.dart';
import 'log_list_screen.dart';
import '../providers/thc_content_provider.dart';
import '../models/log.dart';
import '../providers/dropdown_options_provider.dart';
import '../models/reason_option.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _updateTimer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _deleteLog(String logId) async {
    try {
      final logRepository = ref.read(logRepositoryProvider);
      await logRepository.deleteLog(logId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete log')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _showAddLogDialog() {
    // Controllers and state variables for the form
    final durationController = TextEditingController();
    final notesController = TextEditingController();
    List<String> selectedReasons = [];
    int moodRating = -1; // Change from 5 to -1
    int physicalRating = -1; // Change from 5 to -1

    // For error handling
    bool showError = false;
    String errorMessage = '';

    // Default to current date/time
    DateTime selectedDateTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        // Get the screen width
        final screenWidth = MediaQuery.of(context).size.width;

        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: screenWidth > 700 ? 100 : 20,
              vertical: 24,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog title
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Add Log Manually',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Error message display (visible only when there's an error)
                  if (showError)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                showError = false;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                  // Rest of dialog content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date & Time selection - visually highlighted as important
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: StatefulBuilder(
                              builder: (context, setState) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date & Time (required):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(
                                                Icons.calendar_today),
                                            onPressed: () async {
                                              final date = await showDatePicker(
                                                context: context,
                                                initialDate: selectedDateTime,
                                                firstDate: DateTime(2020),
                                                lastDate: DateTime.now().add(
                                                    const Duration(days: 1)),
                                              );
                                              if (date != null) {
                                                setState(() {
                                                  selectedDateTime = DateTime(
                                                    date.year,
                                                    date.month,
                                                    date.day,
                                                    selectedDateTime.hour,
                                                    selectedDateTime.minute,
                                                  );
                                                });
                                              }
                                            },
                                            label: Text(
                                              '${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')}',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.access_time),
                                            onPressed: () async {
                                              final time = await showTimePicker(
                                                context: context,
                                                initialTime: TimeOfDay(
                                                  hour: selectedDateTime.hour,
                                                  minute:
                                                      selectedDateTime.minute,
                                                ),
                                              );
                                              if (time != null) {
                                                setState(() {
                                                  selectedDateTime = DateTime(
                                                    selectedDateTime.year,
                                                    selectedDateTime.month,
                                                    selectedDateTime.day,
                                                    time.hour,
                                                    time.minute,
                                                  );
                                                });
                                              }
                                            },
                                            label: Text(
                                              '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Duration input field
                          StatefulBuilder(builder: (context, setStateField) {
                            String? errorText;
                            return TextField(
                              controller: durationController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Duration (seconds)',
                                hintText: 'Enter a decimal value (e.g. 5.5)',
                                border: const OutlineInputBorder(),
                                errorText: errorText,
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  final durationValue = double.tryParse(value);
                                  setStateField(() {
                                    errorText = durationValue == null
                                        ? 'Please enter a valid number'
                                        : null;
                                  });
                                } else {
                                  setStateField(() {
                                    errorText = null;
                                  });
                                }
                              },
                            );
                          }),

                          const SizedBox(height: 16),

                          // Reason selection - FIXED: single StatefulBuilder for all chips
                          Consumer(
                            builder: (context, ref, _) {
                              final optionsAsync =
                                  ref.watch(dropdownOptionsProvider);
                              return optionsAsync.when(
                                data: (options) {
                                  // Wrap the entire column in a StatefulBuilder
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Reasons:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8.0,
                                            children: options.map((option) {
                                              return ChoiceChip(
                                                label: Text(option.option),
                                                selected: selectedReasons
                                                    .contains(option.option),
                                                onSelected: (selected) {
                                                  setState(() {
                                                    if (selected) {
                                                      selectedReasons
                                                          .add(option.option);
                                                    } else {
                                                      selectedReasons.remove(
                                                          option.option);
                                                    }
                                                  });
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                loading: () =>
                                    const CircularProgressIndicator(),
                                error: (_, __) =>
                                    const Text('Failed to load reasons'),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Mood rating
                          StatefulBuilder(builder: (context, setState) {
                            return Row(
                              children: [
                                Expanded(
                                  child: RatingSlider(
                                    label: 'Mood',
                                    value: moodRating == -1 ? 5 : moodRating,
                                    onChanged: (val) {
                                      setState(() {
                                        moodRating = val;
                                      });
                                    },
                                    activeColor: moodRating == -1
                                        ? Colors.grey
                                        : Colors.blue,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () {
                                    setState(() {
                                      moodRating = -1;
                                    });
                                  },
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 16),

                          // Physical rating
                          StatefulBuilder(builder: (context, setState) {
                            return Row(
                              children: [
                                Expanded(
                                  child: RatingSlider(
                                    label: 'Physical',
                                    value: physicalRating == -1
                                        ? 5
                                        : physicalRating,
                                    onChanged: (val) {
                                      setState(() {
                                        physicalRating = val;
                                      });
                                    },
                                    activeColor: physicalRating == -1
                                        ? Colors.grey
                                        : Colors.blue,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () {
                                    setState(() {
                                      physicalRating = -1;
                                    });
                                  },
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 16),

                          // Notes field
                          TextField(
                            controller: notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Validate duration field
                            if (durationController.text.isEmpty) {
                              setState(() {
                                showError = true;
                                errorMessage = 'Please enter a duration';
                              });
                              return;
                            }

                            double? durationSeconds =
                                double.tryParse(durationController.text);
                            if (durationSeconds == null) {
                              setState(() {
                                showError = true;
                                errorMessage =
                                    'Please enter a valid number for duration';
                              });
                              return;
                            }

                            // Create and save the log with the selected timestamp
                            final log = Log(
                              timestamp: selectedDateTime,
                              durationSeconds: durationSeconds,
                              reason: selectedReasons,
                              moodRating: moodRating,
                              physicalRating: physicalRating,
                              potencyRating: 0,
                              notes: notesController.text.isEmpty
                                  ? null
                                  : notesController.text,
                            );

                            // Save the log, but pop the dialog first before showing any SnackBar
                            final logRepository =
                                ref.read(logRepositoryProvider);
                            Navigator.of(context).pop(); // Close dialog first

                            // Then handle the async operation after dialog is closed
                            logRepository.addLog(log).then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Log added successfully')),
                              );
                            }).catchError((e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Failed to add log')),
                              );
                            });
                          },
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    ).then((_) {
      // Clean up the controllers
      durationController.dispose();
      notesController.dispose();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomePage(BuildContext context) {
    final logsAsyncValue = ref.watch(logsStreamProvider);

    return logsAsyncValue.when(
      data: (logs) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  final liveThcAsync = ref.watch(liveThcContentProvider);
                  final basicThcAsync = ref.watch(basicThcContentProvider);

                  return liveThcAsync.when(
                    data: (liveThc) => basicThcAsync.when(
                      data: (basicThc) => Column(
                        children: [
                          InfoDisplay(
                            logs: logs,
                            liveThcContent: liveThc,
                            liveBasicThcContent: basicThc,
                          ),
                          const AddLogForm(),
                        ],
                      ),
                      loading: () => Column(
                        children: [
                          InfoDisplay(logs: logs, liveThcContent: liveThc),
                          const AddLogForm(),
                        ],
                      ),
                      error: (error, stack) => Column(
                        children: [
                          InfoDisplay(logs: logs, liveThcContent: liveThc),
                          Text('Basic THC Error: $error'),
                          const AddLogForm(),
                        ],
                      ),
                    ),
                    loading: () => Column(
                      children: [
                        InfoDisplay(logs: logs),
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                        const AddLogForm(),
                      ],
                    ),
                    error: (error, stack) => Column(
                      children: [
                        InfoDisplay(logs: logs),
                        Text('Advanced THC Error: $error'),
                        const AddLogForm(),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _buildHomePage(context),
      const LogListScreen(),
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'AshTrail'),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Logs',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddLogDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
