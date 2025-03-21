import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/log.dart';
import '../models/reason_option.dart';
import '../providers/log_providers.dart';
import '../providers/dropdown_options_provider.dart';
import '../providers/log_transfer_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/user_account_selector.dart';
import '../widgets/rating_slider.dart';
import '../utils/format_utils.dart';

class EditLogScreen extends ConsumerStatefulWidget {
  final Log log;

  const EditLogScreen({
    super.key,
    required this.log,
  });

  @override
  ConsumerState<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends ConsumerState<EditLogScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _durationController;
  late TextEditingController _notesController;
  late DateTime _timestamp;
  late int _moodRating;
  late int _physicalRating;
  late double _potencyRating;
  late List<String> _selectedReasons;
  bool _showTransferOptions = false;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
        text: formatSecondsDisplay(widget.log.durationSeconds));
    _notesController = TextEditingController(text: widget.log.notes ?? '');
    // Set timestamp with fallback to current time if null
    _timestamp = widget.log.timestamp ?? DateTime.now();
    _moodRating = widget.log.moodRating ?? -1;
    _physicalRating = widget.log.physicalRating ?? -1;
    _potencyRating = widget.log.potencyRating != null
        ? (widget.log.potencyRating! / 5.0).clamp(0.25, 2.0)
        : 1.0;
    _selectedReasons = widget.log.reason?.toList() ?? [];
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final duration =
        double.tryParse(_durationController.text) ?? widget.log.durationSeconds;

    final updatedLog = widget.log.copyWith(
      timestamp: _timestamp,
      durationSeconds: duration,
      notes: _notesController.text,
      reason: _selectedReasons,
      moodRating: _moodRating,
      physicalRating: _physicalRating,
      potencyRating: (_potencyRating * 5).round(), // Convert back to 0-10 scale
    );

    try {
      await ref.read(logRepositoryProvider).updateLog(updatedLog);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating log: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _transferLog(String targetEmail) async {
    if (widget.log.id == null) return;

    setState(() {
      _isTransferring = true;
    });

    final success = await ref.read(logTransferProvider).transferLogToUser(
          widget.log.id!,
          targetEmail,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Log transferred to $targetEmail')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _isTransferring = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to transfer log')),
        );
      }
    }
  }

  Widget _buildReasonChips() {
    final optionsAsync = ref.watch(dropdownOptionsProvider);
    return optionsAsync.when(
      data: (options) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: options.map((ReasonOption option) {
                final isSelected = _selectedReasons.contains(option.option);
                return ChoiceChip(
                  label: Text(option.option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedReasons.add(option.option);
                      } else {
                        _selectedReasons.remove(option.option);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Log'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Transfer to another account',
              onPressed: () {
                setState(() {
                  _showTransferOptions = !_showTransferOptions;
                });
              },
            ),
          ],
        ),
        body: _isTransferring
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show transfer options if toggled
                      if (_showTransferOptions)
                        UserAccountSelector(
                          currentEmail: currentEmail,
                          onUserSelected: _transferLog,
                        ),

                      // Display timestamp (non-editable)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Timestamp: ${_timestamp.toLocal().toString().split('.')[0]}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Date & Time picker
                      ListTile(
                        title: const Text('Change Date & Time'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _timestamp,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );

                          if (date != null && mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_timestamp),
                            );

                            if (time != null) {
                              setState(() {
                                _timestamp = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Duration field
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (seconds)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter duration';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Reason selection chips
                      _buildReasonChips(),

                      const SizedBox(height: 16),

                      // Mood rating
                      Row(
                        children: [
                          Expanded(
                            child: RatingSlider(
                              label: 'Mood',
                              value: _moodRating == -1 ? 5 : _moodRating,
                              onChanged: (val) {
                                setState(() {
                                  _moodRating = val;
                                });
                              },
                              activeColor:
                                  _moodRating == -1 ? Colors.grey : Colors.blue,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              setState(() {
                                _moodRating = -1;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Physical rating
                      Row(
                        children: [
                          Expanded(
                            child: RatingSlider(
                              label: 'Physical',
                              value:
                                  _physicalRating == -1 ? 5 : _physicalRating,
                              onChanged: (val) {
                                setState(() {
                                  _physicalRating = val;
                                });
                              },
                              activeColor: _physicalRating == -1
                                  ? Colors.grey
                                  : Colors.blue,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              setState(() {
                                _physicalRating = -1;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Potency rating
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Potency strength: ${_potencyRating.toStringAsFixed(2)}'),
                          Slider(
                            value: _potencyRating,
                            min: 0.25,
                            max: 2.0,
                            divisions:
                                7, // Creates steps: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0
                            label: _potencyRating.toStringAsFixed(2),
                            onChanged: (value) {
                              setState(() {
                                _potencyRating = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes field with keyboard dismiss button
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_hide),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                            },
                            tooltip: 'Dismiss keyboard',
                          ),
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Save and Cancel buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
