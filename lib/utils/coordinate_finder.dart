import 'package:flutter/material.dart';

class CoordinateFinder extends StatefulWidget {
  final Widget child;

  const CoordinateFinder({super.key, required this.child});

  @override
  State<CoordinateFinder> createState() => _CoordinateFinderState();
}

class _CoordinateFinderState extends State<CoordinateFinder> {
  Offset? _tapPosition;
  Size? _screenSize;

  @override
  Widget build(BuildContext context) {
    // Get screen size only once when the widget is first built
    _screenSize ??= MediaQuery.of(context).size;

    return Stack(
      children: [
        // The original app
        GestureDetector(
          onTapDown: (details) {
            setState(() {
              _tapPosition = details.globalPosition;
            });
          },
          child: widget.child,
        ),

        // Coordinate display
        if (_tapPosition != null && _screenSize != null)
          Positioned(
            top: 100,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap Position: (${_tapPosition!.dx.toStringAsFixed(1)}, ${_tapPosition!.dy.toStringAsFixed(1)})',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Normalized: (${(_tapPosition!.dx / _screenSize!.width).toStringAsFixed(2)}, ${(_tapPosition!.dy / _screenSize!.height).toStringAsFixed(2)})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
