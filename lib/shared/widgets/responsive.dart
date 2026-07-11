import 'package:flutter/material.dart';

class ResponsiveRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double breakpoint;

  const ResponsiveRow({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 768,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > breakpoint) {
      return Row(children: [left, const SizedBox(height: 24), right]);
    }

    return Row(
      children: [
        Expanded(child: left),
        Expanded(child: right),
      ],
    );
  }
}
