import 'package:coui_flutter/coui_flutter.dart';

/// Status color tokens — Error / Success / Warning / Info.
///
/// Each token is shown doing the job it exists for. A fill and its
/// foreground come as a pair, so the fill is drawn as a fill with the
/// paired foreground on top.
///
/// Drawing all four as text on the page, which this example used to do,
/// put six of eight below 4.5:1 and two of them at 1.07:1 — a container
/// tint is a background, and on a page of nearly the same lightness it is
/// not faint text, it is no text.
class TextColorsStatusExample extends StatelessWidget {
  const TextColorsStatusExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          Text(
            '상태 색 — 채움마다 짝이 되는 전경색',
            style: theme.typography.titleSmall
                .toValue(theme: theme)
                .copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant.toValue(),
                ),
          ),
          _Pair(
            label: '오류',
            fill: cs.error,
            onFill: cs.onError,
            container: cs.errorContainer,
            onContainer: cs.onErrorContainer,
          ),
          _Pair(
            label: '성공',
            fill: cs.success,
            onFill: cs.onSuccess,
            container: cs.successContainer,
            onContainer: cs.onSuccessContainer,
          ),
          _Pair(
            label: '경고',
            fill: cs.warning,
            onFill: cs.onWarning,
            container: cs.warningContainer,
            onContainer: cs.onWarningContainer,
          ),
          _Pair(
            label: '정보',
            fill: cs.info,
            onFill: cs.onInfo,
            container: cs.infoContainer,
            onContainer: cs.onInfoContainer,
          ),
        ],
      ),
    );
  }
}

/// A role's two pairs, or nothing when the palette does not carry it.
///
/// Success, warning and info sit outside the core scheme, so a palette may
/// leave them unset. Rendering a row for an absent token would assert a
/// colour the theme never chose.
class _Pair extends StatelessWidget {
  const _Pair({
    required this.label,
    required this.fill,
    required this.onFill,
    required this.container,
    required this.onContainer,
  });

  final String label;
  final CoreColor? fill;
  final CoreColor? onFill;
  final CoreColor? container;
  final CoreColor? onContainer;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (fill != null && onFill != null) _Chip(label: '$label 채움', background: fill!, foreground: onFill!),
      if (container != null && onContainer != null)
        _Chip(
          label: '$label 컨테이너',
          background: container!,
          foreground: onContainer!,
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    // `min`: a `Row` fills its parent unless told otherwise, and inside a
    // `Column` that widens the whole block to the stage — so the preview
    // starts at the left edge while Web's block, as wide as its title, is
    // centred.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space8),
      children: chips,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final CoreColor background;
  final CoreColor foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background.toValue(),
        borderRadius: BorderRadius.circular(CoreRadius.radius8),
      ),
      child: Padding(
        padding: const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space12,
          vertical: CoreSpace.space4,
        ).toValue(geometry: Theme.of(context).geometry),
        child: Text(
          label,
          style: theme.typography.labelMedium.toValue(theme: theme).copyWith(color: foreground.toValue()),
        ),
      ),
    );
  }
}
