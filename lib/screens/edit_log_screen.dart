import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log.dart';
import '../models/reason_option.dart';
import '../providers/dropdown_options_provider.dart';
import '../services/log_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/format_utils.dart';
import '../widgets/rating_slider.dart';
import '../widgets/custom_app_bar.dart';

class EditLogScreen extends ConsumerStatefulWidget {
  final Log log;

  const EditLogScreen({super.key, required this.log});

  @override
  ConsumerState<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends ConsumerState<EditLogScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late double _durationSeconds;
  late int _moodRating;
  late int _physicalRating;
  late double _potencyRating;
  late List<String> _selectedReasons;

  // Keep timestamp for reference but don't allow editing
  late DateTime _timestamp;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.log.notes ?? '');
    _durationSeconds = widget.log.durationSeconds;
    _moodRating = widget.log.moodRating;
    _physicalRating = widget.log.physicalRating;
    _potencyRating = widget.log.potencyRating != null
        ? (widget.log.potencyRating! / 5.0).clamp(0.25, 2.0)
        : 1.0;
    _timestamp = widget.log.timestamp;
    _selectedReasons = widget.log.reason?.toList() ?? [];
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateLog() async {
    if (_formKey.currentState!.validate()) {
      // Create updated log with all fields
      final updatedLog = widget.log.copyWith(
        notes: _notesController.text,
        reason: _selectedReasons,
        durationSeconds: _durationSeconds,
        moodRating: _moodRating,
        physicalRating: _physicalRating,
        potencyRating: (_potencyRating * 5)
            .round(), // Convert back to 0-10 scale for storage
        // Keep the original timestamp
        timestamp: widget.log.timestamp,
      );

      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final repository = LogRepository(userId);
        await repository.updateLog(updatedLog);
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Edit Log',
          showBackButton: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                // Duration field
                TextFormField(
                  initialValue: formatSecondsDisplay(_durationSeconds),
                  decoration: const InputDecoration(
                    labelText: 'Duration (seconds)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    double? parsed = double.tryParse(value);
                    if (parsed != null) {
                      _durationSeconds = parsed; // Store full precision
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Replace text field with chips
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
                        value: _physicalRating == -1 ? 5 : _physicalRating,
                        onChanged: (val) {
                          setState(() {
                            _physicalRating = val;
                          });
                        },
                        activeColor:
                            _physicalRating == -1 ? Colors.grey : Colors.blue,
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

                const SizedBox(height: 16),
                // Add keyboard dismiss button above TextField
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
                        onPressed: _updateLog,
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
