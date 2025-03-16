import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/custom_app_bar.dart';

class AccentColorScreen extends StatefulWidget {
  const AccentColorScreen({super.key});

  @override
  State<AccentColorScreen> createState() => _AccentColorScreenState();
}

class _AccentColorScreenState extends State<AccentColorScreen> {
  late Color pickerColor;
  late double hue = 0.0;
  late double saturation = 0.0;
  late double value = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize with the current accent color
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    pickerColor = themeProvider.accentColor;

    // Convert RGB to HSV
    final HSVColor hsvColor = HSVColor.fromColor(pickerColor);
    hue = hsvColor.hue;
    saturation = hsvColor.saturation;
    value = hsvColor.value;
  }

  void updateColor() {
    setState(() {
      pickerColor = HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
    });
  }

  void resetToDefaultBlue() {
    setState(() {
      pickerColor = Colors.blue;
      final HSVColor hsvColor = HSVColor.fromColor(pickerColor);
      hue = hsvColor.hue;
      saturation = hsvColor.saturation;
      value = hsvColor.value;
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
        backgroundColor:
            pickerColor, // Use the current picker color for real-time preview
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose an accent color',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'This color will be used throughout the app for buttons, sliders, and other UI elements.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Color preview box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text('Preview'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Preview button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pickerColor,
                            foregroundColor: _contrastingColor(pickerColor),
                          ),
                          onPressed: () {},
                          child: const Text('Button'),
                        ),

                        // Preview circle
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: pickerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),

                    // // Add app bar preview
                    // const SizedBox(height: 16),
                    // Container(
                    //   width: double.infinity,
                    //   height: 48,
                    //   decoration: BoxDecoration(
                    //     color: pickerColor,
                    //     borderRadius: BorderRadius.circular(4),
                    //   ),
                    //   alignment: Alignment.centerLeft,
                    //   padding: const EdgeInsets.symmetric(horizontal: 16),
                    //   child: Text(
                    //     'App Bar Preview',
                    //     style: TextStyle(
                    //       color: _contrastingColor(pickerColor),
                    //       fontSize: 18,
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2D RGB Slider
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Color Picker',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Hue Slider
                      const Text('Hue'),
                      Slider(
                        min: 0,
                        max: 360,
                        value: hue,
                        onChanged: (newHue) {
                          setState(() {
                            hue = newHue;
                            updateColor();
                          });
                        },
                        activeColor:
                            HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
                      ),

                      const SizedBox(height: 16),

                      // 2D Saturation/Value picker
                      const Text('Saturation and Brightness'),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.black,
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onPanUpdate: (details) {
                                RenderBox renderBox =
                                    context.findRenderObject() as RenderBox;
                                final box = renderBox.size;

                                setState(() {
                                  saturation =
                                      (details.localPosition.dx / box.width)
                                          .clamp(0.0, 1.0);
                                  value = 1.0 -
                                      (details.localPosition.dy / 200)
                                          .clamp(0.0, 1.0);
                                  updateColor();
                                });
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: saturation * 200,
                                      top: (1.0 - value) * 200,
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
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reset to default button - update to show when using default color
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(pickerColor == Colors.blue
                      ? 'Using Default Blue'
                      : 'Reset to Default Blue'),
                  onPressed: pickerColor == Colors.blue
                      ? null // Disable button if already using default blue
                      : resetToDefaultBlue,
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pickerColor,
                    foregroundColor: _contrastingColor(pickerColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
        ),
      ),
    );
  }

  // Helper method to determine if we should use light or dark text
  Color _contrastingColor(Color backgroundColor) {
    if (ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.dark) {
      return Colors.white;
    }
    return Colors.black;
  }
}
