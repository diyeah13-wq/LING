import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Rounded card used across LINGO screens.
class LingoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const LingoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LingoSpacing.md),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).cardTheme.color;
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(LingoRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}