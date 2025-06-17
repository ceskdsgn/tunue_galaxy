import 'package:flutter/material.dart';

enum SlideDirection { left, right }

class DragableWidget extends StatefulWidget {
  const DragableWidget({
    super.key,
    required this.child,
    required this.onSlideOut,
    this.isEnableDrag = true,
  });

  final Widget child;
  final Function(SlideDirection) onSlideOut;
  final bool isEnableDrag;

  @override
  State<DragableWidget> createState() => _DragableWidgetState();
}

class _DragableWidgetState extends State<DragableWidget> {
  Offset position = Offset.zero;
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        if (!widget.isEnableDrag) return;
        setState(() {
          isDragging = true;
        });
      },
      onPanUpdate: (details) {
        if (!widget.isEnableDrag) return;
        setState(() {
          position += details.delta;
        });
      },
      onPanEnd: (details) {
        if (!widget.isEnableDrag) return;
        setState(() {
          isDragging = false;
        });

        final velocity = details.velocity.pixelsPerSecond.dx;
        final isSwipe = position.dx.abs() > 100 || velocity.abs() > 800;

        if (isSwipe) {
          final direction = position.dx > 0 || velocity > 0
              ? SlideDirection.right
              : SlideDirection.left;
          widget.onSlideOut(direction);
        }

        setState(() {
          position = Offset.zero;
        });
      },
      child: Transform.translate(
        offset: position,
        child: widget.child,
      ),
    );
  }
}
