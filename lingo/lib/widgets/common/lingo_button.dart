import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// LINGO's primary action button with a soft press-down animation.
class LingoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool fullWidth;
  final bool loading;
  final bool outlined;

  const LingoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.loading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        else if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        if (!loading) Text(label),
      ],
    );

    final button = _resolveButton(context, child);

    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 100),
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: 52,
        child: button,
      ),
    );
  }

  Widget _resolveButton(BuildContext context, Widget child) {
    final style = outlined
        ? ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: LingoColors.primary,
            side: const BorderSide(color: LingoColors.primary),
            elevation: 0,
            minimumSize: const Size(64, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LingoRadius.md),
            ),
          )
        : null;

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: style,
      child: child,
    );
  }
}

/// A tappable pill-shaped action used in onboarding flows.
class PillOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const PillOption({
    super.key,
    required this.emoji,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        selected ? LingoColors.primary : LingoColors.divider;

    return Material(
      color: selected
          ? LingoColors.primary.withValues(alpha: 0.08)
          : theme.cardTheme.color ?? LingoColors.surface,
      borderRadius: BorderRadius.circular(LingoRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LingoRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(LingoSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LingoRadius.lg),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: LingoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: LingoColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}