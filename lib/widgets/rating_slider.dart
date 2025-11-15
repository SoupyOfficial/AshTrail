import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class RatingSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int divisions;
  final Color? activeColor;
  final ValueChanged<int> onChanged;

  const RatingSlider({
    super.key,
    required this.label,
    required this.value,
    this.min = 1,
    this.max = 10,
    this.divisions = 9,
    this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Get the accent color from theme provider if no explicit color is provided
    final themeProvider = Provider.of<ThemeProvider>(context);
    final effectiveActiveColor = activeColor ?? themeProvider.accentColor;

    return Column(
      children: [
        Center(
          child: Text(
            '$label: $value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            label: '$value',
            activeColor: effectiveActiveColor,
            onChanged: (newValue) => onChanged(newValue.toInt()),
          ),
        ),
      ],
    );
  }
}
