import 'package:coui_web/coui_web.dart';

/// Surface / On-surface / Outline / Inverse tokens.
class TextColorsSurfaceExample extends StatelessComponent {
  const TextColorsSurfaceExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
      [
        _swatch(context, 'Surface', cs.surface?.toString()),
        _swatch(
          context,
          'Surface container',
          cs.surfaceContainer?.toString(),
        ),
        _swatch(context, 'Surface tint', cs.surfaceTint?.toString()),
        _swatch(
          context,
          'Inverse surface',
          cs.inverseSurface?.toString(),
          foreground: cs.inverseOnSurface?.toString(),
        ),
        Text('On surface').onSurface,
        Text('Outline').outline,
      ],
    );
  }

  Component _swatch(
    BuildContext context,
    String label,
    String? backgroundColor, {
    String? foreground,
  }) {
    final outlineVariant = context.colorScheme.outlineVariant ?? 'outline-variant';
    return div(
      classes:
          'inline-flex items-center self-start '
          'px-${CoreSpace.scale.space12} py-${CoreSpace.scale.space8} '
          'rounded-${CoreRadius.scale.radius4} '
          'border border-$outlineVariant '
          'bg-${backgroundColor ?? 'surface'}',
      [
        Text(label, style: TextStyle(color: foreground ?? 'on-surface')),
      ],
    );
  }
}
