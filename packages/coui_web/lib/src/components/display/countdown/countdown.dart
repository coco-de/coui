import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/countdown/countdown_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform countdown for CoUI Web with token-based rendering.
///
/// Per Epic #1302 chrome / dimensional / animation overrides flow
/// through the single [countdownStyle] slot. Behavioural fields
/// (`value`, `min`, `max`) stay flat on the widget.
class Countdown extends UiComponent
    implements CoreCountdownContract<Component> {
  /// Creates a [Countdown].
  const Countdown({
    required this.value,
    this.min = CoreCountdownContract.defaultMinValue,
    this.max = CoreCountdownContract.defaultMaxValue,
    this.countdownStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'span');

  @override
  final int value;

  @override
  final int min;

  @override
  final int max;

  @override
  final CoreCountdownStyle? countdownStyle;
  @override
  Countdown copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    int? value,
    int? min,
    int? max,
    CoreCountdownStyle? countdownStyle,
  }) {
    return Countdown(
      key: key ?? this.key,
      value: value ?? this.value,
      min: min ?? this.min,
      max: max ?? this.max,
      countdownStyle: countdownStyle ?? this.countdownStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final clampedValue = value.clamp(min, max);

    // Resolver finishes className + inlineStyles synthesis (Epic #1601
    // PoC — `WebResolvedChrome` contract). `co_countdown` reads the
    // paint-ready strings directly without invoking the top-level
    // builder helpers.
    final resolved = resolveCountdown(
      context,
      countdownStyle: countdownStyle,
    );

    final userClasses = classes;
    final finalClasses = userClasses == null || userClasses.isEmpty
        ? resolved.root.className
        : '${resolved.root.className} $userClasses';

    return span(
      [Text(clampedValue.toString())],
      id: id,
      classes: finalClasses,
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: {
        ...componentAttributes,
        'aria-live': 'polite',
        'aria-label': clampedValue.toString(),
      },
      events: this.events,
    );
  }
}

/// Chain sugar mirroring the Flutter `Countdown.withStyle` extension —
/// merges a [CoreCountdownStyle] patch into [Countdown.countdownStyle]
/// via the existing [Countdown.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCountdownStyle.merge` right-side-wins semantics).
extension CountdownStyleChain on Countdown {
  /// Returns a copy of this [Countdown] with [patch] merged into
  /// [countdownStyle] (patch fields win on conflict).
  Countdown withStyle(CoreCountdownStyle patch) => copyWith(
    countdownStyle: (countdownStyle ?? const CoreCountdownStyle()).merge(patch),
  );
}
