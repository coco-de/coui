import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart' as dom_utils;
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/form/star_rating/star_rating_style.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

// ─── Behaviour / star-geometry defaults ───────────────────────────────
// Widget-flat behaviour defaults (verify.md rule (u-2): behaviour 값은
// Style 슬롯이 아니라 widget 평면). 같은 값을 Flutter 측 `co_star_rating.dart`
// 도 file-local 로 들고 있어 silent divergence 위험은 없음 — Flutter / Web
// 양쪽 모두 `StarRating` widget API 의 default 자리.

const double _kDefaultMax = 5;
const double _kDefaultStep = 0.5;
const double _kDefaultStarPoints = 5;
const double _kDefaultStarPointRounding = 0.15;
const double _kDefaultStarValleyRounding = 0;
const double _kDefaultStarSquash = 0;
const double _kDefaultStarInnerRadiusRatio = 0.4;
const double _kDefaultStarRotation = 0;

/// Canonical SVG `viewBox` coordinate size for the star path. The SVG
/// `<svg>` element's rendered width/height is driven by the resolved
/// chrome (`resolved.star.inlineStyles` carries rem values), so the
/// coordinate space here is scale-invariant — pick a round number that
/// the path generator can subdivide cleanly.
const double _kStarCanvasSize = 100;

/// Active fill colour CSS reference — SVG `<path fill="...">` markup
/// reads this CSS custom property which `star_rating_style.dart`'s
/// resolver writes into `resolved.star.inlineStyles`.
const String _kStarActiveFill = 'var(--coui-star-active)';

/// Inactive (empty) fill colour CSS reference — see [_kStarActiveFill].
const String _kStarInactiveFill = 'var(--coui-star-inactive)';

/// Unified cross-platform star rating for CoUI Web.
///
/// Hover-based interaction matching Flutter parity:
/// hover changes preview, click confirms value.
class StarRating extends UiStatefulComponent implements CoreStarRatingContract {
  /// Creates a [StarRating].
  const StarRating({
    required this.value,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.max = _kDefaultMax,
    this.step = _kDefaultStep,
    this.enabled = true,
    this.onChanged,
    this.direction = CoreAxis.horizontal,
    this.size = CoreStarRatingStyle.defaultSize,
    this.showValue = CoreStarRatingContract.defaultShowValue,
    this.showCount = CoreStarRatingContract.defaultShowCount,
    this.count,
    this.starPoints,
    this.starPointRounding,
    this.starValleyRounding,
    this.starSquash,
    this.starInnerRadiusRatio,
    this.starRotation,
    this.name,
    this.starRatingStyle,
  });

  @override
  final double value;

  @override
  final double max;

  @override
  final double step;

  @override
  final bool enabled;

  /// Change callback.
  final CoreValueChanged<double>? onChanged;

  /// Axis the stars are laid out along. Also decides which way an
  /// individual star fills — along the axis when horizontal, bottom-up
  /// when vertical. The Flutter twin reads the same parameter.
  @override
  final CoreAxis direction;

  @override
  final CoreComponentSize size;

  @override
  final bool showValue;

  @override
  final bool showCount;

  @override
  final int? count;

  @override
  final CoreStarRatingStyle? starRatingStyle;

  /// Number of points per star.
  final double? starPoints;

  /// Rounding radius for star points.
  final double? starPointRounding;

  /// Rounding radius for star valleys.
  final double? starValleyRounding;

  /// Vertical compression factor.
  final double? starSquash;

  /// Inner to outer radius ratio.
  final double? starInnerRadiusRatio;

  /// Rotation angle in radians.
  final double? starRotation;

  /// The name of the input for form submission.
  final String? name;

  /// Returns a copy of this [StarRating] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  StarRating copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    CoreValueChanged<double>? onChanged,
    double? value,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    double? max,
    double? step,
    bool? enabled,
    CoreAxis? direction,
    CoreComponentSize? size,
    bool? showValue,
    bool? showCount,
    int? count,
    double? starPoints,
    double? starPointRounding,
    double? starValleyRounding,
    double? starSquash,
    double? starInnerRadiusRatio,
    double? starRotation,
    String? name,
    CoreStarRatingStyle? starRatingStyle,
  }) {
    return StarRating(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      value: value ?? this.value,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      max: max ?? this.max,
      step: step ?? this.step,
      enabled: enabled ?? this.enabled,
      direction: direction ?? this.direction,
      size: size ?? this.size,
      showValue: showValue ?? this.showValue,
      showCount: showCount ?? this.showCount,
      count: count ?? this.count,
      starPoints: starPoints ?? this.starPoints,
      starPointRounding: starPointRounding ?? this.starPointRounding,
      starValleyRounding: starValleyRounding ?? this.starValleyRounding,
      starSquash: starSquash ?? this.starSquash,
      starInnerRadiusRatio: starInnerRadiusRatio ?? this.starInnerRadiusRatio,
      starRotation: starRotation ?? this.starRotation,
      name: name ?? this.name,
      starRatingStyle: starRatingStyle ?? this.starRatingStyle,
    );
  }

  @override
  State<StarRating> createState() => _StarRatingState();
}

/// Chain sugar mirroring the Flutter `StarRating.withStyle` extension —
/// merges a [CoreStarRatingStyle] patch into [StarRating.starRatingStyle]
/// via the existing [StarRating.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStarRatingStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreColors` primitive — the
/// getter *name* is the token name, so `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreStarRatingStyle.backgroundColor]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// StarRating(value: 3).primary
/// ```
extension StarRatingStyleChain on StarRating {
  /// Returns a copy of this [StarRating] with [patch] merged into
  /// [starRatingStyle] (patch fields win on conflict).
  StarRating withStyle(CoreStarRatingStyle patch) => copyWith(
    starRatingStyle: (starRatingStyle ?? const CoreStarRatingStyle()).merge(
      patch,
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  StarRating get primary => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  StarRating get secondary => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  StarRating get tertiary => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  StarRating get surface => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  StarRating get surfaceContainer => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  StarRating get error => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  StarRating get success => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  StarRating get warning => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  StarRating get info => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  StarRating get outline => withStyle(
    const CoreStarRatingStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  StarRating get transparent => withStyle(
    const CoreStarRatingStyle(backgroundColor: .transparent),
  );
}

class _StarRatingState extends State<StarRating> {
  double? _hoverValue;
  bool _focused = false;

  double get _displayValue => _hoverValue ?? component.value;

  void _handleMouseMove(web.MouseEvent event) {
    if (!component.enabled || component.onChanged == null) return;
    final target = event.currentTarget;
    if (target == null) return;
    final progress = dom_utils.getMouseRatio(event, target);
    if (progress == null) return;
    final newValue = (progress * component.max).clamp(0.0, component.max);
    final stepped = (newValue / component.step).round() * component.step;
    setState(() {
      _hoverValue = stepped;
    });
  }

  void _handleMouseLeave(web.MouseEvent event) {
    setState(() {
      _hoverValue = null;
    });
  }

  void _handleClick(web.MouseEvent event) {
    if (!component.enabled || component.onChanged == null) return;
    component.onChanged!(_displayValue);
    setState(() {
      _hoverValue = null;
    });
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveStarRating(
      context,
      isInteractive: component.enabled && component.onChanged != null,
      enabled: component.enabled,
      direction: component.direction,
      size: component.size,
      starRatingStyle: component.starRatingStyle,
    );

    final displayVal = _displayValue;
    final maxInt = component.max.ceil();
    final count = component.count;
    final showCount = component.showCount && count != null;

    final stars = div(
      [
        for (int i = 0; i < maxInt; i++)
          Star(
            state: CoreStarState.forIndex(displayVal, i),
            size: component.size,
            enabled: component.enabled,
            direction: component.direction,
            starPoints: component.starPoints,
            starPointRounding: component.starPointRounding,
            starValleyRounding: component.starValleyRounding,
            starSquash: component.starSquash,
            starInnerRadiusRatio: component.starInnerRadiusRatio,
            starRotation: component.starRotation,
            starRatingStyle: component.starRatingStyle,
          ),
      ],
      classes: resolved.stars.className,
      styles: resolved.stars.inlineStyles,
      events: {
        'mousemove': EventHandlers.createMouseEventHandler(_handleMouseMove),
        'mouseleave': EventHandlers.createMouseEventHandler(_handleMouseLeave),
        'click': EventHandlers.createMouseEventHandler(_handleClick),
      },
    );

    // One ring around the whole group — stars and the text beside them.
    return FocusOutline(
      focused: _focused,
      focusOutlineStyle: resolved.focusOutlineStyle,
      classes: WebLayout.inlineFlex,
      child: div(
        [
          stars,
          if (component.showValue) ...[
            Gap(gapStyle: resolved.valueGapStyle),
            span(
              [Text(displayVal.toStringAsFixed(1))],
              classes: resolved.value.className,
              styles: resolved.value.inlineStyles,
            ),
          ],
          if (showCount) ...[
            Gap(gapStyle: resolved.valueGapStyle),
            span(
              [Text('($count)')],
              classes: resolved.count.className,
              styles: resolved.count.inlineStyles,
            ),
          ],
          if (component.name != null)
            Component.element(
              tag: 'input',
              attributes: {
                'type': 'hidden',
                'name': component.name!,
                'value': component.value.toString(),
              },
            ),
        ],
        id: component.id,
        classes: component.rootClasses(resolved.root.className),
        styles: component.css,
        attributes: {
          ...component.componentAttributes,
          'role': 'slider',
          'aria-label': CouiLocalizations.of(context).ratingLabel,
          'aria-valuenow': component.value.toString(),
          'aria-valuemin': '0',
          'aria-valuemax': component.max.toString(),
          // Keyboard-focusable only when interactive (matches the Flutter
          // `FocusableActionDetector(enabled: _enabled)`).
          if (component.enabled && component.onChanged != null) 'tabindex': '0',
        },
        events: {
          ...component.events,
          // The ring is Dart-driven because `FocusOutline` takes a
          // boolean, so the `:focus-visible` match the browser already
          // computed is read off the target. Typed handler: dart2js
          // release minifies dynamic `event.target` dispatches.
          'focus': EventHandlers.createElementTargetEventHandler(
            (_, target) =>
                setState(() => _focused = target.matches(':focus-visible')),
          ),
          'blur': (_) => setState(() => _focused = false),
        },
      ),
    );
  }
}

/// One star, drawn in one of three fills: [CoreStarState.filled],
/// [CoreStarState.half] or [CoreStarState.empty].
///
/// `StarRating` draws one per index; it is also usable on its own. The
/// size and colours come from the same `resolveStarRating` the rating
/// uses. A half star fills the lower half instead when [direction] is
/// vertical.
class Star extends UiStatefulComponent {
  /// Creates a [Star].
  const Star({
    super.key,
    super.id,
    super.classes,
    super.css,
    this.state = CoreStarState.defaultState,
    this.size = CoreStarRatingStyle.defaultSize,
    this.enabled = true,
    this.direction = CoreAxis.horizontal,
    this.starPoints,
    this.starPointRounding,
    this.starValleyRounding,
    this.starSquash,
    this.starInnerRadiusRatio,
    this.starRotation,
    this.starRatingStyle,
  });

  /// How much of the star is filled.
  final CoreStarState state;

  /// Size step — `sm` 16 · `md` 20 · `lg` 24 · `xl` 32.
  final CoreComponentSize size;

  /// Whether the disabled colours are used when `false`.
  final bool enabled;

  /// Axis the half fill runs along — left half when horizontal, lower
  /// half when vertical.
  final CoreAxis direction;

  /// Number of points per star.
  final double? starPoints;

  /// Rounding radius for star points.
  final double? starPointRounding;

  /// Rounding radius for star valleys.
  final double? starValleyRounding;

  /// Vertical compression factor.
  final double? starSquash;

  /// Inner to outer radius ratio.
  final double? starInnerRadiusRatio;

  /// Rotation angle in radians.
  final double? starRotation;

  /// Per-instance chrome / dimensional style.
  final CoreStarRatingStyle? starRatingStyle;

  /// Returns a copy of this [Star] with the given fields replaced.
  Star copyWith({
    Key? key,
    String? id,
    String? classes,
    Styles? css,
    CoreStarState? state,
    CoreComponentSize? size,
    bool? enabled,
    CoreAxis? direction,
    double? starPoints,
    double? starPointRounding,
    double? starValleyRounding,
    double? starSquash,
    double? starInnerRadiusRatio,
    double? starRotation,
    CoreStarRatingStyle? starRatingStyle,
  }) {
    return Star(
      key: key ?? this.key,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      state: state ?? this.state,
      size: size ?? this.size,
      enabled: enabled ?? this.enabled,
      direction: direction ?? this.direction,
      starPoints: starPoints ?? this.starPoints,
      starPointRounding: starPointRounding ?? this.starPointRounding,
      starValleyRounding: starValleyRounding ?? this.starValleyRounding,
      starSquash: starSquash ?? this.starSquash,
      starInnerRadiusRatio: starInnerRadiusRatio ?? this.starInnerRadiusRatio,
      starRotation: starRotation ?? this.starRotation,
      starRatingStyle: starRatingStyle ?? this.starRatingStyle,
    );
  }

  @override
  State<Star> createState() => _StarState();
}

int _starClipCounter = 0;

class _StarState extends State<Star> {
  // One clip id per star on the page — two stars sharing an id would
  // clip against whichever `<clipPath>` the browser finds first.
  final int _clipSerial = _starClipCounter++;

  @override
  Component build(BuildContext context) {
    final component = this.component;
    final resolved = resolveStarRating(
      context,
      isInteractive: false,
      enabled: component.enabled,
      direction: component.direction,
      size: component.size,
      starRatingStyle: component.starRatingStyle,
    );
    final pathD = CoreStarPath.toSvgPath(
      size: _kStarCanvasSize,
      points: component.starPoints ?? _kDefaultStarPoints,
      innerRadiusRatio:
          component.starInnerRadiusRatio ?? _kDefaultStarInnerRadiusRatio,
      rotation: component.starRotation ?? _kDefaultStarRotation,
      squash: component.starSquash ?? _kDefaultStarSquash,
      pointRounding: component.starPointRounding ?? _kDefaultStarPointRounding,
      valleyRounding:
          component.starValleyRounding ?? _kDefaultStarValleyRounding,
    );
    final canvasInt = _kStarCanvasSize.toInt();
    // The three states are three fill fractions of one structure: the
    // active path is clipped by a rect whose CSS carries the fraction, so
    // the resolver's transition sweeps the fill edge when the state
    // changes (empty 0 · half 0.5 · filled 1).
    final fraction = switch (component.state) {
      CoreStarState.filled => 1.0,
      CoreStarState.half => 0.5,
      CoreStarState.empty => 0.0,
    };
    final clipId = 'star-fill-$_clipSerial';
    final isVertical = component.direction == .vertical;
    // Clip geometry in SVG viewBox USER units, styled via CSS so the
    // transition can animate it. Vertical fills bottom-up by scaling the
    // full-canvas rect from its bottom edge.
    final fillStyle = isVertical
        ? Styles(raw: {'transform': 'scaleY($fraction)'})
        : Styles(raw: {'width': svgUserUnitCss(_kStarCanvasSize * fraction)});

    return Component.element(
      tag: 'svg',
      id: component.id,
      classes: [
        resolved.star.className,
        ?component.classes,
      ].where((c) => c.isNotEmpty).join(' '),
      styles: Styles.combine([?resolved.star.inlineStyles, ?component.css]),
      attributes: {
        'xmlns': 'http://www.w3.org/2000/svg',
        'viewBox': '0 0 $canvasInt $canvasInt',
        'fill': 'none',
        'data-coui-star-state': component.state.name,
      },
      children: [
        Component.element(
          tag: 'path',
          attributes: {'d': pathD, 'fill': _kStarInactiveFill},
        ),
        Component.element(
          tag: 'defs',
          children: [
            Component.element(
              tag: 'clipPath',
              attributes: {'id': clipId},
              children: [
                Component.element(
                  tag: 'rect',
                  styles: Styles.combine([
                    ?resolved.starFill.inlineStyles,
                    fillStyle,
                  ]),
                  attributes: {
                    'x': '0',
                    'y': '0',
                    'height': '$canvasInt',
                    if (isVertical) 'width': '$canvasInt',
                  },
                ),
              ],
            ),
          ],
        ),
        Component.element(
          tag: 'path',
          attributes: {
            'd': pathD,
            'fill': _kStarActiveFill,
            'clip-path': 'url(#$clipId)',
          },
        ),
      ],
    );
  }
}
