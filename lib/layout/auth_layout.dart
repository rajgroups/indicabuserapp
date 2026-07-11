import 'package:flutter/material.dart';

import '../core/constants/Colors.dart';
import 'app.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AuthLayout({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
  });

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      backgroundColor: AppColors.authBackground,
      scrollable: true,
      padding: padding,
      child: child,
    );
  }
}
