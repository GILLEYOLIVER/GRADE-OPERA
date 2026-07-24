import 'package:flutter/material.dart';

class HorizontalScrollArea extends StatefulWidget {
  const HorizontalScrollArea({required this.child, super.key});

  final Widget child;

  @override
  State<HorizontalScrollArea> createState() => _HorizontalScrollAreaState();
}

class _HorizontalScrollAreaState extends State<HorizontalScrollArea> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _controller,
    thumbVisibility: true,
    child: SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      child: widget.child,
    ),
  );
}
