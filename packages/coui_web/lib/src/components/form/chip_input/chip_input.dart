import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/chip/chip.dart';
import 'package:coui_web/src/components/form/chip_input/chip_input_style.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/text_field/text_field.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' show RawText, Styles;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Unified cross-platform chip input for CoUI Web.
///
/// `ChipInput` is a multi-value text input — users type text and press
/// Enter to add chips; each chip carries a remove button. The chip list
/// is a `List<String>` so the API is identical on Flutter and Web.
///
/// Per Epic #1302 all chrome / dimensional overrides flow through the
/// single [chipInputStyle] (a [CoreChipInputStyle]). Behavioural /
/// semantic fields (`chips` / `placeholder` / `enabled` / `maxChips` /
/// callbacks) stay flat.
///
/// Example:
/// ```dart
/// ChipInput(
///   chips: ['apple', 'banana'],
///   placeholder: 'Add a fruit...',
///   onChanged: (chips) => print('Chips: $chips'),
/// )
/// ```
///
/// surface:behind — the root `<div role="group">` paints the frame's box
/// directly rather than composing `OutlinedContainer` (the inline entry
/// field is deliberately chromeless so the root owns the single visible
/// boundary), so what shows through it is the page it is laid on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class ChipInput extends UiComponent
    implements
        CoreChipInputContract<
          CoreValueChanged<List<String>>?,
          CoreValueChanged<String>?
        > {
  /// Creates a [ChipInput].
  const ChipInput({
    super.key,
    this.chips = const [],
    this.placeholder,
    this.enabled = true,
    this.maxChips,
    this.onChanged,
    this.onSubmitted,
    this.pasteSplitter,
    this.chipInputStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final List<String> chips;

  @override
  final String? placeholder;

  @override
  final bool enabled;

  @override
  final int? maxChips;

  @override
  final CoreValueChanged<List<String>>? onChanged;

  @override
  final CoreValueChanged<String>? onSubmitted;

  /// Splits pasted text into chips. `null` leaves paste untouched — the
  /// browser drops the text into the entry buffer as it always has.
  @override
  final List<String> Function(String pasted)? pasteSplitter;

  @override
  final CoreChipInputStyle? chipInputStyle;

  @override
  ChipInput copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    CoreValueChanged<List<String>>? onChanged,
    List<String>? chips,
    String? placeholder,
    bool? enabled,
    int? maxChips,
    CoreValueChanged<String>? onSubmitted,
    List<String> Function(String pasted)? pasteSplitter,
    CoreChipInputStyle? chipInputStyle,
  }) {
    return ChipInput(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      chips: chips ?? this.chips,
      placeholder: placeholder ?? this.placeholder,
      enabled: enabled ?? this.enabled,
      maxChips: maxChips ?? this.maxChips,
      onSubmitted: onSubmitted ?? this.onSubmitted,
      pasteSplitter: pasteSplitter ?? this.pasteSplitter,
      chipInputStyle: chipInputStyle ?? this.chipInputStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  bool get _canAddMore => maxChips == null || chips.length < maxChips!;

  /// Turns a `paste` on the entry input into chips.
  ///
  /// `preventDefault` first: the split values become chips, so letting
  /// the browser also drop the raw text into the buffer would leave the
  /// whole pasted string sitting under the chips it just produced.
  ///
  /// The typed [EventHandlers] helper keeps the `ClipboardEvent` cast out
  /// of dynamic dispatch, which dart2js release builds minify into
  /// mangled names that compile-graph changes can desync.
  UiEventHandler _buildPasteHandler(List<String> Function(String) splitter) {
    return EventHandlers.createClipboardInputEventHandler((event, _) {
      final pasted = event.clipboardData?.getData('text');
      if (pasted == null || pasted.isEmpty) return;

      event.preventDefault();

      final next = CoreChipInputContract.chipsAfterPaste(
        existing: chips,
        pasted: pasted,
        splitter: splitter,
        maxChips: maxChips,
      );
      // Identity means the paste contributed nothing — a field already
      // at `maxChips`, or separators with only blanks between them.
      if (identical(next, chips)) return;

      onChanged?.call(next);
    });
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1603
    // 옵션 B — `WebResolvedChrome` contract). `co_chip_input` reads
    // the paint-ready strings directly without invoking any builder
    // helpers.
    final resolved = resolveChipInput(
      context,
      enabled: enabled,
      chipInputStyle: chipInputStyle,
    );
    // Scope id for the frame's focus-ring scoped rule — the caller's own
    // id wins, else the owning element retains its generated scope.
    final scopeId = id ?? elementScopeId(context, prefix: 'co-chip-input');
    final rules = resolveChipInputRules(
      context,
      scopeId: scopeId,
      enabled: enabled,
      chipInputStyle: chipInputStyle,
    );

    final children = <Component>[
      // `<style>` is `display: none`, so it creates no flex item and
      // never affects the wrapping row (nor picks up the container gap).
      if (rules.css.isNotEmpty)
        Component.element(tag: 'style', children: [RawText(rules.css)]),
      for (int i = 0; i < chips.length; i += 1) _buildChip(i, resolved),
      if (_canAddMore)
        // Chromeless unified TextField — the ChipInput frame owns the
        // visible boundary; the field renders only the caret + text +
        // placeholder (caret follows the TextField's primary caret,
        // matching the Flutter twin's cursor colour). The wrapper div
        // carries the flex-grow + min-width so the field shares the
        // chips' row like the Flutter self-sizing editor.
        Component.element(
          tag: 'div',
          classes: resolved.field.className,
          styles: resolved.field.inlineStyles,
          children: [
            // Uncontrolled on purpose: `ChipInput` is stateless — the
            // committed value lives in the `chips` prop and the typed
            // buffer is DOM-owned until Enter reads + clears it (same
            // pattern as the Select search input).
            // Part of this composite: walled off from the enclosing
            // `FormField`, which is shown the composite's own value.
            FormFieldHandleScope.boundary(
              child: TextField(
                // Enter adds a chip — extract the inner input value and
                // clear the field. The `case final web.X` runtime pattern
                // keeps the cast dart2js-minification safe (cautions.md
                // § "Web 이벤트 핸들러").
                onKeyDown: (event) {
                  if (event.key != 'Enter') return;
                  // IME composition guard — with a composing IME (Korean
                  // etc.) the commit-Enter fires keydown too; submitting
                  // then would add the full text AND leave the live
                  // composition to re-materialise after the clear,
                  // producing a second phantom chip on the real Enter.
                  // (keyCode 229 is the legacy composing marker — same
                  // guard for older engines.)
                  if (event.isComposing ||
                      event.keyCode == _kComposingKeyCode) {
                    return;
                  }
                  if (event.target case final web.HTMLInputElement target) {
                    event.preventDefault();
                    final value = target.value.trim();
                    if (value.isEmpty) return;
                    onSubmitted?.call(value);
                    target.value = '';
                  }
                },
                placeholder: placeholder != null ? Text(placeholder!) : null,
                enabled: enabled,
                variant: CoreChipInputStyle.fieldVariant,
                // Registered only when a splitter was supplied, so an
                // ordinary paste keeps the browser's own default — the
                // handler below cancels it.
                eventHandlers: pasteSplitter == null
                    ? const {}
                    : {
                        'paste': [_buildPasteHandler(pasteSplitter!)],
                      },
                textFieldStyle: resolved.fieldStyle,
              ),
            ),
          ],
        ),
    ];

    return Component.element(
      tag: 'div',
      // The generated scope id is stamped only when a rule actually
      // targets it, so the default path's markup is unchanged.
      id: rules.css.isEmpty ? id : scopeId,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: {
        ...componentAttributes,
        'role': 'group',
        'aria-label': CouiLocalizations.of(context).chipInputLabel,
      },
      events: events.isEmpty ? null : events,
      children: children,
    );
  }

  Component _buildChip(int index, ResolvedChipInput resolved) {
    final label = chips[index];
    // Composed unified `Chip` — the badge box / label / remove button
    // are the Chip's responsibility; ChipInput only forwards its
    // compact-pill chrome through the nested `chipStyle` slot.
    return Chip(
      label: label,
      variant: CoreChipInputStyle.chipVariant,
      emphasis: CoreChipInputStyle.chipEmphasis,
      size: CoreChipInputStyle.chipSize,
      enabled: enabled,
      onRemove: enabled
          ? () {
              final currentOnChanged = onChanged;
              if (currentOnChanged != null) {
                // Non-mutating removal — `chips` is the caller's list and
                // `removeAt` would edit it in place. Spread the prefix +
                // suffix instead.
                final next = <String>[
                  ...chips.take(index),
                  ...chips.skip(index + 1),
                ];
                currentOnChanged(next);
              }
            }
          : null,
      chipStyle: resolved.chipStyle,
    );
  }
}

/// Legacy `keyCode` browsers report for every keydown during an IME
/// composition session (the Process key) — the pre-`isComposing`
/// composing marker.
const int _kComposingKeyCode = 229;

/// Chain sugar mirroring the Flutter `ChipInput.withStyle` extension —
/// merges a [CoreChipInputStyle] patch into [ChipInput.chipInputStyle]
/// via the existing [ChipInput.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreChipInputStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreChipInputStyle.borderRadius] and `.primary` sets
/// [CoreChipInputStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// ChipInput(chips: ['apple', 'banana']).radius4.surface
/// ```
extension ChipInputStyleChain on ChipInput {
  /// Sets the background paint and preserves the other style fields.
  ChipInput backgroundColor(CoreColor value) =>
      withStyle(CoreChipInputStyle(backgroundColor: value));

  /// Returns a copy of this [ChipInput] with [patch] merged into
  /// [chipInputStyle] (patch fields win on conflict).
  ChipInput withStyle(CoreChipInputStyle patch) => copyWith(
    chipInputStyle: (chipInputStyle ?? const CoreChipInputStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  ChipInput get radius0 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  ChipInput get radius2 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  ChipInput get radius4 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  ChipInput get radius6 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  ChipInput get radius8 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  ChipInput get radius10 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  ChipInput get radius12 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  ChipInput get radius14 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  ChipInput get radius16 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  ChipInput get radius20 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  ChipInput get radius24 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  ChipInput get radius28 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  ChipInput get radius32 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  ChipInput get radius36 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  ChipInput get radius40 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  ChipInput get radius48 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  ChipInput get radius56 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  ChipInput get radius64 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  ChipInput get radius9999 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  ChipInput get primary => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  ChipInput get secondary => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  ChipInput get tertiary => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  ChipInput get surface => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  ChipInput get surfaceContainer => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  ChipInput get error => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  ChipInput get success => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  ChipInput get warning => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  ChipInput get info => withStyle(
    const CoreChipInputStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  ChipInput get outline => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  ChipInput get transparent => withStyle(
    const CoreChipInputStyle(backgroundColor: .transparent),
  );
}
