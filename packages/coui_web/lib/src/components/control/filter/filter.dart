import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/control/filter/filter_style.dart';
import 'package:coui_web/src/components/control/toggle_group/toggle_group.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform segmented filter control for CoUI Web with
/// token-based rendering.
///
/// `Filter` groups its [items] as mutually exclusive toggle buttons,
/// similar to a radio group. It is a **controlled** component: the
/// parent owns the selected value via [groupValue] and reacts through
/// [onValueChanged]. An optional reset button clears the selection via
/// [onReset].
///
/// The segments are a composed [ToggleGroup] — the track, the raised
/// chosen face and its shadow, the segment geometry, the roving radio-group
/// keys and the disabled look are the group's own. The reset affordance (a
/// vertical hairline, then a ghost square `Button`) rides the group's
/// `trailing` slot inside the track, after the last segment. With
/// [fillWidth] the track takes the width its container offers and the
/// segments share it, the trailing row keeping its own width. Rendered
/// entirely with `<div>` elements (no native `<form>` /
/// `<input type="radio">`) so Web and Flutter share one rendering model.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [filterStyle] (a [CoreFilterStyle]). The
/// semantic enum (`variant`) and behaviour fields (`groupValue` /
/// `items` / `onValueChanged` / `onReset` / `showResetButton` / `enabled` /
/// `fillWidth`) stay flat on the component.
///
/// ```text
/// design system default for filter
///   → CoreFilterTheme.style                  // 프로젝트 공통
///   → CoreFilterTheme.variantStyles[variant]
///   → component.filterStyle                  // 인스턴스별
/// ```
///
/// surface:content — a segmented track that sits in the page flow, not
/// something mounted over content. The track is the composed `ToggleGroup`'s
/// surface; the moving chosen face is not.
///
/// Each [CoreFilterItem] may carry a caller-supplied [CoreFilterItem.icon]
/// before its label; with `showLabel: false` the segment renders
/// icon-only (a square of `itemHeight`) while [CoreFilterItem.label]
/// stays its accessible name.
///
/// Example:
/// ```dart
/// Filter<String>(
///   groupValue: _selected,
///   onValueChanged: (value) => setState(() => _selected = value),
///   items: const [
///     CoreFilterItem(value: 'svelte', label: 'Svelte'),
///     CoreFilterItem(value: 'vue', label: 'Vue'),
///     CoreFilterItem(
///       value: 'react',
///       label: 'React',
///       icon: Icon(LucideIcons.atom),
///       showLabel: false,
///     ),
///   ],
/// )
/// ```
class Filter<T> extends UiComponent
    implements CoreFilterContract<Component, T, CoreVoidCallback> {
  /// Creates a [Filter].
  const Filter({
    required this.groupValue,
    required this.items,
    required this.onValueChanged,
    super.key,
    this.variant = CoreFilterVariant.defaultVariant,
    this.size = CoreFilterContract.defaultSize,
    this.onReset,
    this.showResetButton = false,
    this.enabled,
    this.fillWidth = false,
    this.filterStyle,
    super.id,
  }) : assert(items.length > 0, 'Filter must have at least one item.'),
       super(tag: 'div');

  @override
  final CoreFilterVariant variant;

  @override
  final CoreComponentSize size;

  @override
  final T? groupValue;

  @override
  final List<CoreFilterItem<T, Component>> items;

  @override
  final void Function(T) onValueChanged;

  @override
  final CoreVoidCallback? onReset;

  @override
  final bool showResetButton;

  @override
  final bool? enabled;

  @override
  final bool fillWidth;

  /// Per-instance composite style. See [CoreFilterStyle] for the merge
  /// chain.
  @override
  final CoreFilterStyle? filterStyle;

  @override
  Filter<T> copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    CoreFilterVariant? variant,
    CoreComponentSize? size,
    T? groupValue,
    List<CoreFilterItem<T, Component>>? items,
    void Function(T)? onValueChanged,
    CoreVoidCallback? onReset,
    bool? showResetButton,
    bool? enabled,
    bool? fillWidth,
    CoreFilterStyle? filterStyle,
  }) {
    return Filter(
      key: key ?? this.key,
      groupValue: groupValue ?? this.groupValue,
      items: items ?? this.items,
      onValueChanged: onValueChanged ?? this.onValueChanged,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      onReset: onReset ?? this.onReset,
      showResetButton: showResetButton ?? this.showResetButton,
      enabled: enabled ?? this.enabled,
      fillWidth: fillWidth ?? this.fillWidth,
      filterStyle: filterStyle ?? this.filterStyle,
      id: id ?? this.id,
    );
  }

  @override
  Component build(BuildContext context) {
    final hasReset = showResetButton && onReset != null;
    final isEnabled = enabled ?? true;
    final resolved = resolveFilter(
      context,
      variant: variant,
      size: size,
      filterStyle: filterStyle,
      enabled: isEnabled,
    );

    // The segments are a composed `ToggleGroup`: the track, the raised
    // chosen face and its shadow, the segment geometry, the radiogroup
    // roving keys and the disabled look are the group's own, forwarded
    // through `resolved.toggleGroupStyle`. The reset affordance rides the
    // group's `trailing` slot, inside the track and AFTER every segment: a
    // hairline, then the unified `Button(variant: .ghost, size: .sm, shape:
    // .square)`. The hairline shows only while the reset button does.
    // `fillWidth` is the group's own: its segment hosts take equal shares
    // (`flex: 1 1 0%`) of a full-width track and the trailing row keeps its
    // natural width at the end.
    return ToggleGroup<T>(
      id: id,
      items: [
        for (final item in items)
          CoreToggleGroupItem<T, Component>(
            value: item.value,
            label: item.label,
            icon: item.icon,
            showLabel: item.showLabel,
          ),
      ],
      value: groupValue,
      onChanged: isEnabled ? onValueChanged : null,
      size: size,
      enabled: isEnabled,
      fillWidth: fillWidth,
      trailing: hasReset ? _buildTrailing(context, resolved, isEnabled) : null,
      toggleGroupStyle: resolved.toggleGroupStyle,
    );
  }

  // Trailing row — the vertical hairline, then the reset button: unified
  // `Button(variant: .ghost, size: .sm, shape: .square)`; the `ghost`
  // variant owns the transparent fill and hover tint, the square shape the
  // 1:1 aspect, and `resolved.resetButtonStyle` (raw-forward) supplies the
  // fixed side / radius / transition / foreground. The glyph is a `Icon`
  // child (size from the slot's `leadingIconStyle`; colour null so it
  // inherits the button foreground).
  Component _buildTrailing(
    BuildContext context,
    ResolvedFilter resolved,
    bool isEnabled,
  ) {
    return Component.element(
      tag: 'div',
      classes: resolved.root.className,
      styles: resolved.root.inlineStyles,
      children: [
        Component.element(
          tag: 'div',
          classes: resolved.dividerBox.className,
          styles: resolved.dividerBox.inlineStyles,
          children: [
            Divider(
              orientation: .vertical,
              dividerStyle: resolved.dividerStyle,
            ),
          ],
        ),
        Button(
          onPressed: isEnabled ? () => onReset?.call() : null,
          variant: .ghost,
          size: .sm,
          shape: .square,
          buttonStyle: resolved.resetButtonStyle,
          attributes: {
            'aria-label': CouiLocalizations.of(context).filterResetLabel,
          },
          child: Icon(
            LucideIcons.x,
            iconStyle: resolved.resetButtonStyle.leadingIconStyle,
          ),
        ),
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `Filter.withStyle` extension —
/// merges a [CoreFilterStyle] patch into [Filter.filterStyle] via the
/// existing [Filter.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFilterStyle.merge` right-side-wins semantics).
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
/// sets the composed group's `borderRadius` and `.primary` sets its
/// `backgroundColor` (both through [CoreFilterStyle.toggleGroupStyle]). A
/// semantic layer that names these after component-specific intent
/// (decided together with design) is a follow-up once more components
/// adopt this pattern.
///
/// ```dart
/// Filter<String>(...).radius4.surface
/// ```
extension FilterStyleChain<T> on Filter<T> {
  /// Sets the background paint and preserves the other style fields.
  Filter<T> backgroundColor(CoreColor value) => withStyle(
    CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(backgroundColor: value),
    ),
  );

  /// Returns a copy of this [Filter] with [patch] merged into
  /// [filterStyle] (patch fields win on conflict).
  Filter<T> withStyle(CoreFilterStyle patch) => copyWith(
    filterStyle: (filterStyle ?? const CoreFilterStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  Filter<T> get radius0 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.zero,
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Filter<T> get radius2 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Filter<T> get radius4 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Filter<T> get radius6 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Filter<T> get radius8 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Filter<T> get radius10 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Filter<T> get radius12 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Filter<T> get radius14 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Filter<T> get radius16 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Filter<T> get radius20 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Filter<T> get radius24 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Filter<T> get radius28 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Filter<T> get radius32 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Filter<T> get radius36 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Filter<T> get radius40 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Filter<T> get radius48 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Filter<T> get radius56 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Filter<T> get radius64 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
      ),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Filter<T> get radius9999 => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      ),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Filter<T> get primary => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.primary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Filter<T> get secondary => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.secondary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Filter<T> get tertiary => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.tertiary),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Filter<T> get surface => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.surface),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Filter<T> get surfaceContainer => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Filter<T> get error => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.error),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Filter<T> get success => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.success),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Filter<T> get warning => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.warning),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Filter<T> get info => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.info),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Filter<T> get outline => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(
        backgroundColor: CoreColor.token(CoreColors.outline),
      ),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Filter<T> get transparent => withStyle(
    const CoreFilterStyle(
      toggleGroupStyle: CoreToggleGroupStyle(backgroundColor: .transparent),
    ),
  );
}
