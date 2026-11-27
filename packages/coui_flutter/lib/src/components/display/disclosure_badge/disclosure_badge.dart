import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

/// A static marker stating whether one piece of evidence can be opened
/// right now.
///
/// ```dart
/// DisclosureBadge(
///   kind: CoreDisclosureKind.private,
///   label: '비공개 · NDA',
/// )
/// ```
///
/// ### Why this is not a `Chip`, a `Badge`, or a `ValidationBadge`
///
/// * `ValidationBadge` is form-validation vocabulary and is filled by
///   default — wrong domain, wrong emphasis.
/// * A `Chip` brings a fill and hover feedback with it, so a reader reads
///   it as something to press. This badge is never pressable, and a
///   reader who taps a "비공개" chip and gets nothing has been lied to by
///   the styling.
/// * `Badge`'s variants are colours (`primary` / `destructive`), not
///   meanings, so nothing stops "openable" and "not openable" from ending
///   up the same shape.
///
/// ### The four things this component enforces
///
/// 1. **Unfilled.** Outline and text only. There is no `backgroundColor`
///    slot on [CoreDisclosureBadgeStyle] to add one through.
/// 2. **Shape, not just colour.** `open` is a solid outline, `commitment`
///    a solid outline with a marker dot, `private` a dashed outline.
///    Those live on [CoreDisclosureKind], out of reach of any theme, so
///    the three states stay distinct for a colour-blind reader and on the
///    black-and-white printout a 실사 담당자 actually works from
///    (WCAG 1.4.1).
/// 3. **The state is written down.** [label] is a required, non-empty
///    `String`; an empty one throws rather than rendering a wordless
///    outline.
/// 4. **No pointer feedback.** No hover, no press, no animation, no
///    cursor change, no `Clickable`. A `StatelessWidget` with no gesture
///    and no state, because a static marker that reacts to a pointer is
///    claiming to be a control.
///
/// ### What Flutter has to draw by hand
///
/// Flutter's `Border` carries no dash pattern — `BorderStyle` offers only
/// `solid` and `none` — so `private`'s broken outline is painted by a
/// [CustomPainter] rather than being expressed in a `BoxDecoration`. That
/// is deliberate work rather than a colour substitution: the gaps in the
/// stroke are the signal that survives greyscale, and swapping them for a
/// different hue would leave the three kinds separated by colour alone,
/// which is exactly the failure this component exists to prevent.
///
/// Chrome overrides flow through the single [disclosureBadgeStyle] slot;
/// see [CoreDisclosureBadgeStyle] for the merge chain.
class DisclosureBadge extends StatelessWidget
    implements CoreDisclosureBadgeContract<Widget> {
  /// Creates a [DisclosureBadge].
  ///
  /// - [kind]: which of the three disclosure states this badge states. It
  ///   carries the stroke pattern and the marker dot, so it is what keeps
  ///   the three legible without colour.
  /// - [label]: the status text. Must not be empty — a badge with no word
  ///   on it states its meaning through colour and shape alone, which is
  ///   what this component exists to prevent. For
  ///   [CoreDisclosureKind.private] the reason goes here ("비공개 · NDA"),
  ///   not a bare "비공개".
  /// - [disclosureBadgeStyle]: per-instance chrome override.
  const DisclosureBadge({
    required this.kind,
    required this.label,
    super.key,
    this.labelMaxLines,
    this.labelOverflow,
    this.disclosureBadgeStyle,
  }) : assert(
         label != '',
         'DisclosureBadge.label must not be empty — the disclosure state '
         'has to be readable as text, not inferred from colour or border '
         'style alone.',
       );

  @override
  final CoreDisclosureKind kind;

  @override
  final String label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  /// Per-instance chrome style. See [CoreDisclosureBadgeStyle] for the
  /// merge chain.
  @override
  final CoreDisclosureBadgeStyle? disclosureBadgeStyle;

  /// Returns a copy of this [DisclosureBadge] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  DisclosureBadge copyWith({
    Key? key,
    CoreDisclosureKind? kind,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    CoreDisclosureBadgeStyle? disclosureBadgeStyle,
  }) {
    return DisclosureBadge(
      key: key ?? this.key,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      disclosureBadgeStyle: disclosureBadgeStyle ?? this.disclosureBadgeStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveDisclosureBadge(
      context,
      kind: kind,
      disclosureBadgeStyle: disclosureBadgeStyle,
    );

    // Both branches paint the stroke on the box edge without insetting
    // what is inside it — `DecoratedBox` adds no room for a border and a
    // `CustomPaint` cannot — so the width is reserved once, here, for
    // both. A branch that reserved it on only one side would make the
    // dashed kind a stroke narrower than the solid ones, and a size
    // difference between kinds is a second signal nobody specified.
    final content = Padding(
      padding: EdgeInsets.all(resolved.borderWidth) + resolved.padding,
      child: Row(
        mainAxisSize: .min,
        spacing: resolved.markerSpacing,
        children: [
          if (kind.hasMarker) _buildMarker(resolved),
          // Loose flex is the Flutter reading of the Web twin's
          // `shrink-0` on the dot: under a narrow parent the words give
          // way and the marker keeps its diameter, so a long label can
          // never squeeze the shape signal out of existence. `fit.loose`
          // (never `Expanded`) is what keeps the badge legal inside a
          // horizontally unbounded parent — see `Divider`'s note on the
          // same constraint.
          Flexible(
            child: Text(
              label,
              style: resolved.labelTextStyle,
              maxLines: labelMaxLines,
              overflow: labelOverflow?.toValue(),
            ),
          ),
        ],
      ),
    );

    // Read off the kind, never off a style slot — that is the WCAG 1.4.1
    // guarantee, and routing it through `resolved` would put it back
    // within a theme's reach.
    return switch (kind.stroke) {
      .solid => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: resolved.borderColor,
            width: resolved.borderWidth,
          ),
          borderRadius: resolved.borderRadius,
        ),
        child: content,
      ),
      .dashed => CustomPaint(
        painter: _DashedOutlinePainter(
          color: resolved.borderColor,
          strokeWidth: resolved.borderWidth,
          borderRadius: resolved.borderRadius,
          dashLength: resolved.dashLength,
          dashGap: resolved.dashGap,
        ),
        child: content,
      ),
    };
  }

  /// The deferral marker dot — the second non-colour signal, and the one
  /// that separates [CoreDisclosureKind.commitment] from
  /// [CoreDisclosureKind.open], which share a solid outline.
  ///
  /// Hidden from assistive tech for the reason the Web twin marks it
  /// `aria-hidden`: it restates in shape what [label] already says in
  /// words, so announcing it would put an empty stop between the outline
  /// and the status text.
  Widget _buildMarker(ResolvedDisclosureBadge resolved) => ExcludeSemantics(
    child: Container(
      width: resolved.markerSize,
      height: resolved.markerSize,
      decoration: BoxDecoration(
        color: resolved.foregroundColor,
        borderRadius: resolved.markerRadius,
      ),
    ),
  );
}

/// Paints [CoreDisclosureStroke.dashed] — the outline of a badge whose
/// evidence is not going to open.
///
/// Flutter has no dashed `BorderSide`, so the broken line is walked out
/// of the rounded rect by hand. The gaps are the whole point: they are
/// what a colour-blind reader and a black-and-white printout still see,
/// so this is drawn rather than approximated with a lighter colour or a
/// lower opacity, either of which would put the distinction back on
/// colour alone (WCAG 1.4.1).
class _DashedOutlinePainter extends CustomPainter {
  const _DashedOutlinePainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    required this.dashLength,
    required this.dashGap,
  });

  final Color color;
  final double strokeWidth;
  final BorderRadius borderRadius;
  final double dashLength;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final step = dashLength + dashGap;
    // A non-positive step would walk the perimeter forever. Nothing in
    // the design system produces one, but a painter that can hang the
    // frame on a bad number is not a painter worth shipping.
    if (step <= 0 || strokeWidth <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = .stroke;

    // Inset by half the stroke so the line is drawn inside the box the
    // way `Border.all` draws it, rather than straddling the edge and
    // being clipped to half its width by whatever contains the badge.
    final rrect = borderRadius.toRRect(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += step;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedOutlinePainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        borderRadius != oldDelegate.borderRadius ||
        dashLength != oldDelegate.dashLength ||
        dashGap != oldDelegate.dashGap;
  }
}

/// Chain sugar for merging a [CoreDisclosureBadgeStyle] patch into
/// [DisclosureBadge.disclosureBadgeStyle] without hand-reconstructing
/// every field. Mirrors the Web `DisclosureBadge.withStyle` extension so
/// both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDisclosureBadgeStyle.merge` right-side-wins semantics).
///
/// There is deliberately no `.primary` / `.surface` colour sugar of the
/// kind `Badge` carries: those getters set a *background*, and this
/// component has no background to set.
///
/// ```dart
/// DisclosureBadge(kind: CoreDisclosureKind.open, label: '공개')
///     .withStyle(const CoreDisclosureBadgeStyle(borderWidth: 2))
/// ```
extension DisclosureBadgeStyleChain on DisclosureBadge {
  /// Sets the content padding.
  DisclosureBadge contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreDisclosureBadgeStyle(padding: value));

  /// Sets the border color.
  DisclosureBadge borderColor(CoreColor value) =>
      withStyle(CoreDisclosureBadgeStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  DisclosureBadge borderWidth(double value) =>
      withStyle(CoreDisclosureBadgeStyle(borderWidth: value));

  /// Sets the content foreground color.
  DisclosureBadge foregroundColor(CoreColor value) =>
      withStyle(CoreDisclosureBadgeStyle(foregroundColor: value));

  /// Returns a copy of this [DisclosureBadge] with [patch] merged into
  /// [DisclosureBadge.disclosureBadgeStyle] (patch fields win on
  /// conflict).
  DisclosureBadge withStyle(CoreDisclosureBadgeStyle patch) => copyWith(
    disclosureBadgeStyle:
        (disclosureBadgeStyle ?? const CoreDisclosureBadgeStyle()).merge(patch),
  );
}
