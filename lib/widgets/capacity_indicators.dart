import 'package:flutter/material.dart';

class CapacityIndicator extends StatefulWidget {
  /// Creates a capacity indicator.
  ///
  /// [initialValue] must be in range of min to max.
  const CapacityIndicator({
    Key? key,
    required this.initialValue,
    this.bufferedValue = 0,
    this.min = 0.0,
    this.max = 1.0,
    this.color = Colors.green,
    this.bufferedColor = Colors.greenAccent,
    this.onChanged,
  })  : assert(initialValue >= min && initialValue <= max),
        super(key: key);

  /// The current initial value of the indicator. Must be in the range of min to max.
  final double initialValue;

  /// The current buffered value of the indicator. Must be in the range of min to max.
  final double bufferedValue;

  final double min;
  final double max;

  /// Called when the current value of the indicator changes.
  final ValueChanged<double>? onChanged;

  final Color color;
  final Color bufferedColor;

  @override
  State<CapacityIndicator> createState() => _CapacityIndicatorState();
}

class _CapacityIndicatorState extends State<CapacityIndicator> {
  bool _showBall = false;

  // Returns a number between min and max, proportional to value, which must
  // be between 0.0 and 1.0.
  double _lerp(double value) {
    assert(value >= 0.0);
    assert(value <= 1.0);
    return value * (widget.max - widget.min) + widget.min;
  }

  void _handleUpdate(Offset lp, double width) {
    double value = (lp.dx / width);
    value = value.clamp(0.0, 1.0);
    widget.onChanged?.call(_lerp(value));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return SizedBox(
        width: width,
        height: 4,
        child: GestureDetector(
          onPanStart: (event) => _handleUpdate(event.localPosition, width),
          onPanUpdate: (event) => _handleUpdate(event.localPosition, width),
          onPanDown: (event) => _handleUpdate(event.localPosition, width),
          child: MouseRegion(
            onEnter: (_) => setState(() {
              _showBall = true;
            }),
            onExit: (_) => setState(() {
              _showBall = false;
            }),
            child: CustomPaint(
              painter: _CapacityCellPainter(
                color: widget.color,
                bufferedColor: widget.bufferedColor,
                value: widget.initialValue / widget.max,
                bufferedValue: widget.bufferedValue / widget.max,
                showBall: _showBall,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _CapacityCellPainter extends CustomPainter {
  const _CapacityCellPainter({
    required this.color,
    required this.value,
    required this.bufferedColor,
    required this.bufferedValue,
    this.showBall = true,
  });

  final Color color;
  final Color bufferedColor;
  final double value;
  final double bufferedValue;
  final bool showBall;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 2.0;

    /// Draw buffered
    canvas.drawRRect(
      BorderRadius.horizontal(
              left: const Radius.circular(radius),
              right: bufferedValue == 1
                  ? const Radius.circular(radius)
                  : Radius.zero)
          .toRRect(Offset.zero &
              Size(size.width * bufferedValue.clamp(0.0, 1.0), size.height)),
      Paint()..color = bufferedColor,
    );

    /// Draw inside
    canvas.drawRRect(
      BorderRadius.horizontal(
        left: const Radius.circular(radius),
        right: value == 1 ? const Radius.circular(radius) : Radius.zero,
      ).toRRect(
        Offset.zero & Size(size.width * value.clamp(0.0, 1.0), size.height),
      ),
      Paint()..color = color,
    );

    /// Draw ball
    if (showBall) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(
                      size.width * value.clamp(0.0, 1.0), size.height * 0.5),
                  width: 20,
                  height: 20),
              const Radius.circular(10)),
          Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_CapacityCellPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(_CapacityCellPainter oldDelegate) => false;
}
