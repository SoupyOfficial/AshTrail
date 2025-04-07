import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/custom_app_bar.dart';

class ColorPickerThumbShape extends SliderComponentShape {
  final Color color;
  final double thumbRadius;
  final double borderWidth;
  final Color borderColor;

  const ColorPickerThumbShape({
    required this.color,
    this.thumbRadius = 10.0,
    this.borderWidth = 2.0,
    this.borderColor = Colors.white,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, thumbRadius + 2, shadowPaint);

    // Draw the colored thumb
    final fillPaint = Paint()..color = color;
    canvas.drawCircle(center, thumbRadius, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(center, thumbRadius, borderPaint);
  }
}

class AccentColorScreen extends StatefulWidget {
  const AccentColorScreen({super.key});

  @override
  State<AccentColorScreen> createState() => _AccentColorScreenState();
}

class _AccentColorScreenState extends State<AccentColorScreen> {
  final GlobalKey _pickerKey = GlobalKey();
  late Color pickerColor;
  late double hue = 0.0;
  late double saturation = 0.0;
  late double value = 0.0;
  late TextEditingController hexController;
  final List<Color> colorHistory = [];
  final maxHistoryItems = 5;

  @override
  void initState() {
    super.initState();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    pickerColor = themeProvider.accentColor;

    final HSVColor hsvColor = HSVColor.fromColor(pickerColor);
    hue = hsvColor.hue;
    saturation = hsvColor.saturation;
    value = hsvColor.value;

    hexController = TextEditingController(text: colorToHex(pickerColor));
    _addToHistory(pickerColor);
  }

  @override
  void dispose() {
    hexController.dispose();
    super.dispose();
  }

  void updateColor() {
    setState(() {
      pickerColor = HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
      hexController.text = colorToHex(pickerColor);
    });
  }

  void updateColorFromHex(String hex) {
    if (hex.length == 6) {
      try {
        final color = Color(int.parse('0xFF$hex'));
        setState(() {
          pickerColor = color;
          final HSVColor hsvColor = HSVColor.fromColor(color);
          hue = hsvColor.hue;
          saturation = hsvColor.saturation;
          value = hsvColor.value;
        });
      } catch (e) {
        // Invalid hex
      }
    }
  }

  String colorToHex(Color color) {
    return color.value.toRadixString(16).substring(2).toUpperCase();
  }

  void resetToDefaultBlue() {
    setState(() {
      pickerColor = Colors.blue;
      final HSVColor hsvColor = HSVColor.fromColor(pickerColor);
      hue = hsvColor.hue;
      saturation = hsvColor.saturation;
      value = hsvColor.value;
      hexController.text = colorToHex(pickerColor);
      _addToHistory(pickerColor);
    });
  }

  void _addToHistory(Color color) {
    setState(() {
      if (!colorHistory.contains(color)) {
        colorHistory.insert(0, color);
        if (colorHistory.length > maxHistoryItems) {
          colorHistory.removeLast();
        }
      }
    });
  }

  void _selectColor(Color color) {
    setState(() {
      pickerColor = color;
      final HSVColor hsvColor = HSVColor.fromColor(color);
      hue = hsvColor.hue;
      saturation = hsvColor.saturation;
      value = hsvColor.value;
      hexController.text = colorToHex(color);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Accent Color',
        showBackButton: true,
        backgroundColor: pickerColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact preview with color values
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Color swatch
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: pickerColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Color values in column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hex input
                        Row(
                          children: [
                            Text('#'),
                            Expanded(
                              child: TextField(
                                controller: hexController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  border: OutlineInputBorder(),
                                ),
                                maxLength: 6,
                                buildCounter: (_,
                                        {required currentLength,
                                        required isFocused,
                                        maxLength}) =>
                                    null,
                                textCapitalization:
                                    TextCapitalization.characters,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9a-fA-F]')),
                                ],
                                onChanged: updateColorFromHex,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // RGB values
                        Text(
                          'R: ${pickerColor.red}, G: ${pickerColor.green}, B: ${pickerColor.blue}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Compact UI preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Button preview
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pickerColor,
                      foregroundColor: _contrastingColor(pickerColor),
                    ),
                    onPressed: () {},
                    child: const Text('Button'),
                  ),

                  // Switch preview
                  Switch(
                    value: true,
                    onChanged: (_) {},
                    activeColor: pickerColor,
                  ),

                  // Circle preview
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: pickerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Recently used colors in a compact row
              if (colorHistory.isNotEmpty) ...[
                Row(
                  children: [
                    Text('Recent: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black54,
                        )),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: colorHistory.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final color = colorHistory[index];
                            return InkWell(
                              onTap: () => _selectColor(color),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: color == pickerColor
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.withOpacity(0.3),
                                    width: color == pickerColor ? 2 : 1,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Integrated hue slider with gradient as track
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Hue',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          Text('${hue.round()}°',
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Custom slider with gradient background
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Gradient background for the slider
                          Container(
                            height: 8,
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF0000), // Red
                                  Color(0xFFFFFF00), // Yellow
                                  Color(0xFF00FF00), // Green
                                  Color(0xFF00FFFF), // Cyan
                                  Color(0xFF0000FF), // Blue
                                  Color(0xFFFF00FF), // Magenta
                                  Color(0xFFFF0000), // Red again
                                ],
                              ),
                            ),
                          ),
                          // Slider with transparent track
                          SliderTheme(
                            data: SliderThemeData(
                              thumbShape: ColorPickerThumbShape(
                                color: pickerColor,
                              ),
                              overlayShape:
                                  RoundSliderOverlayShape(overlayRadius: 16),
                              trackHeight: 8,
                              trackShape: const RoundedRectSliderTrackShape(),
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                            ),
                            child: Slider(
                              min: 0,
                              max: 360,
                              value: hue,
                              onChanged: (newHue) {
                                setState(() {
                                  hue = newHue;
                                  updateColor();
                                });
                              },
                              onChangeEnd: (_) => _addToHistory(pickerColor),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 2D Saturation/Value picker - more compact
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Saturation & Brightness',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          Text(
                              'S: ${(saturation * 100).round()}%, B: ${(value * 100).round()}%',
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // This container defines the saturation/value picker with reduced height
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final pickerWidth = constraints.maxWidth;
                          // Use a smaller aspect ratio to reduce height while maintaining usability
                          final pickerHeight = pickerWidth * 0.5;

                          return SizedBox(
                            key: _pickerKey,
                            width: pickerWidth,
                            height: pickerHeight,
                            child: Stack(
                              children: [
                                // Color gradient background (first layer)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    // Solid color of the current hue at full saturation and value
                                    color: HSVColor.fromAHSV(1.0, hue, 1.0, 1.0)
                                        .toColor(),
                                  ),
                                ),
                                // White gradient for saturation (third layer - but with mask to preserve black bottom)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white,
                                        Colors
                                            .transparent, // Transparent at right
                                      ],
                                      stops: const [
                                        0.0,
                                        0.9
                                      ], // Adjust gradient stop
                                    ),
                                    // Create a mask that preserves the black bottom
                                    backgroundBlendMode: BlendMode.srcOver,
                                  ),
                                ),
                                // Black gradient for value (second layer)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: const LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors
                                            .black, // Black at bottom (value = 0)
                                        Colors
                                            .transparent, // Transparent at top (value = 1)
                                      ],
                                    ),
                                  ),
                                ),
                                // Touch detector
                                GestureDetector(
                                  onPanDown: (details) {
                                    final RenderBox box = _pickerKey
                                        .currentContext!
                                        .findRenderObject() as RenderBox;
                                    final localPosition = box
                                        .globalToLocal(details.globalPosition);
                                    _updateSaturationValue(localPosition,
                                        pickerWidth, pickerHeight);
                                  },
                                  onPanUpdate: (details) {
                                    final RenderBox box = _pickerKey
                                        .currentContext!
                                        .findRenderObject() as RenderBox;
                                    final localPosition = box
                                        .globalToLocal(details.globalPosition);
                                    _updateSaturationValue(localPosition,
                                        pickerWidth, pickerHeight);
                                  },
                                  onPanEnd: (_) => _addToHistory(pickerColor),
                                  child: Container(
                                    color: Colors.transparent,
                                  ),
                                ),
                                // Picker indicator - smaller
                                Positioned(
                                  left: saturation * pickerWidth,
                                  top: (1.0 - value) * pickerHeight,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: pickerColor,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 3,
                                          spreadRadius: 0.5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Action buttons in a row to save space
              Row(
                children: [
                  // Reset button
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset to Default'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Colors.blue, // Use the default accent color
                      ),
                      onPressed: pickerColor == Colors.blue
                          ? null
                          : resetToDefaultBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Save button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pickerColor,
                        foregroundColor: _contrastingColor(pickerColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        themeProvider.setAccentColor(pickerColor);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accent color saved')),
                        );
                      },
                      child: const Text('Save Color'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateSaturationValue(
      Offset localPosition, double width, double height) {
    setState(() {
      saturation = (localPosition.dx / width).clamp(0.0, 1.0);
      value = 1.0 - (localPosition.dy / height).clamp(0.0, 1.0);
      updateColor();
    });
  }

  Color _contrastingColor(Color backgroundColor) {
    if (ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.dark) {
      return Colors.white;
    }
    return Colors.black;
  }
}
