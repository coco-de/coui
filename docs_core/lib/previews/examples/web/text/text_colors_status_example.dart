import 'package:coui_web/coui_web.dart';

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
class TextColorsStatusExample extends StatelessComponent {
  const TextColorsStatusExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return div(
      classes:
          'flex flex-col gap-${CoreSpace.scale.space8} '
          'p-${CoreSpace.scale.space16}',
      [
        Text('상태 색 — 채움마다 짝이 되는 전경색').titleSmall.semiBold.onSurfaceVariant,
        _pair('오류', cs.error, cs.onError, cs.errorContainer, cs.onErrorContainer),
        _pair('성공', cs.success, cs.onSuccess, cs.successContainer, cs.onSuccessContainer),
        _pair('경고', cs.warning, cs.onWarning, cs.warningContainer, cs.onWarningContainer),
        _pair('정보', cs.info, cs.onInfo, cs.infoContainer, cs.onInfoContainer),
      ],
    );
  }
}

/// A role's two pairs, or nothing when the palette does not carry it.
///
/// Success, warning and info sit outside the core scheme, so a palette may
/// leave them unset. Rendering a row for an absent token would assert a
/// colour the theme never chose.
Component _pair(
  String label,
  CoreColor? fill,
  CoreColor? onFill,
  CoreColor? container,
  CoreColor? onContainer,
) {
  final chips = <Component>[
    if (fill != null && onFill != null) _chip('$label 채움', fill, onFill),
    if (container != null && onContainer != null) _chip('$label 컨테이너', container, onContainer),
  ];
  if (chips.isEmpty) return const Component.empty();

  return div(classes: 'flex flex-row gap-${CoreSpace.scale.space8}', chips);
}

Component _chip(String label, CoreColor background, CoreColor foreground) {
  return div(
    classes:
        'flex px-${CoreSpace.scale.space12} py-${CoreSpace.scale.space4} '
        'rounded-${CoreRadius.scale.radius8} '
        'bg-$background text-$foreground',
    [Text(label).labelMedium],
  );
}
