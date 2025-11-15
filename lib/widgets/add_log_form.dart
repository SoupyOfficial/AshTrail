import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../models/log.dart';
import '../presentation/providers/log_providers.dart';
import '../providers/dropdown_options_provider.dart';
import '../models/reason_option.dart';
import '../theme/theme_provider.dart';
import 'rating_slider.dart';
import '../utils/format_utils.dart';

class AddLogForm extends ConsumerStatefulWidget {
  const AddLogForm({super.key});

  @override
  ConsumerState<AddLogForm> createState() => _AddLogFormState();
}

class _AddLogFormState extends ConsumerState<AddLogForm> {
  DateTime? _startTime;
  double _durationSeconds = 0.0; // Change to double
  Timer? _timer;
  static const int _longPressDelay = 500; // milliseconds
  final _notesController = TextEditingController();
  List<String> _selectedReasons = [];
  int _moodRating = -1;
  int _physicalRating = -1;

  void _startTimer() {
    setState(() {
      // Adjust start time to account for long press delay
      _startTime = DateTime.now()
          .subtract(const Duration(milliseconds: _longPressDelay));
      _durationSeconds = 0.0;
    });

    // Create a periodic timer to update the duration display
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // ~60fps
      if (_startTime != null) {
        setState(() {
          _durationSeconds =
              DateTime.now().difference(_startTime!).inMilliseconds /
                  1000; // Convert to seconds with decimals
        });
      }
    });
  }

  void _stopTimerAndSave() async {
    _timer?.cancel();
    if (_startTime != null) {
      final endTime = DateTime.now();
      setState(() {
        _durationSeconds =
            endTime.difference(_startTime!).inMilliseconds / 1000;
        _startTime = null;
      });

      if (_durationSeconds > 0) {
        final log = Log(
          timestamp: DateTime.now(),
          durationSeconds: _durationSeconds,
          reason: _selectedReasons,
          moodRating: _moodRating,
          physicalRating: _physicalRating,
          potencyRating: 0,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        try {
          final logRepository = ref.read(logRepositoryProvider);
          await logRepository.addLog(log);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Log added successfully')),
            );
            _resetForm();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add log')),
            );
          }
        }
      }
    }
  }

  void _resetForm() {
    setState(() {
      _durationSeconds = 0;
      _notesController.clear();
      _selectedReasons = [];
      _moodRating = -1;
      _physicalRating = -1;
    });
  }

  Widget _buildDropdownOptions() {
    final optionsAsync = ref.watch(dropdownOptionsProvider);
    return optionsAsync.when(
      data: (options) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
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
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = provider_pkg.Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _startTime != null
                  ? 'Duration: ${formatSecondsDisplay(_durationSeconds)}s'
                  : 'Hold to Track',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onLongPressStart: (_) => _startTimer(),
              onLongPressEnd: (_) => _stopTimerAndSave(),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _startTime != null
                      ? Colors.red
                      : accentColor, // Use accent color
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _startTime != null ? Icons.stop : Icons.touch_app,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _startTime != null
                  ? 'Release to save'
                  : 'Press and hold to start tracking',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _buildDropdownOptions(),
            const SizedBox(height: 16),
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
                    activeColor: _moodRating == -1
                        ? Colors.grey
                        : accentColor, // Use accent color
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
                    activeColor: _physicalRating == -1
                        ? Colors.grey
                        : accentColor, // Use accent color
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
                  maxLines: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }
}
