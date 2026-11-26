import 'package:coui_flutter/coui_flutter.dart';

/// Surface / On-surface / Outline / Inverse tokens. Surface variants
/// are background colors so they are visualised as filled swatches.
class TextColorsSurfaceExample extends StatelessWidget {
  const TextColorsSurfaceExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: theme.geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          _swatch(theme, 'Surface', cs.surface.toValue()),
          _swatch(theme, 'Surface container', cs.surfaceContainer.toValue()),
          _swatch(theme, 'Surface tint', cs.surfaceTint.toValue()),
          _swatch(theme, 'Inverse surface', cs.inverseSurface.toValue(), foreground: cs.inverseOnSurface.toValue()),
          const Text('On surface').onSurface,
          const Text('Outline').outline,
        ],
      ),
    );
  }

  Widget _swatch(
    ThemeData theme,
    String label,
    Color? background, {
    Color? foreground,
  }) {
    final cs = theme.colorScheme;
    return Container(
      padding: const CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space12,
        vertical: CoreSpace.space8,
      ).toValue(geometry: theme.geometry),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(CoreRadius.radius4),
        border: Border.all(color: cs.outlineVariant.toValue()),
      ),
      // chain `.bodyMedium` 으로 base 명시 — SDK Text 는 inherited
      // DefaultTextStyle 만 보기 때문에 Container subtree 의 잘못된
      // base (system 14 px) 가 새는 것을 차단.
      child: foreground != null ? Text(label, style: TextStyle(color: foreground)).bodyMedium : Text(label).bodyMedium,
    );
  }
}
