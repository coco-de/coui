import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/roving_focus.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/control/toggle_group/toggle_group_style.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform grouped toggle for CoUI Web with token-based
/// rendering.
///
/// `ToggleGroup` holds its [items] on one track as mutually exclusive
/// segments; the chosen one is a raised face. It is the shared shape
/// behind a filter's segments, a time picker's AM / PM and a colour
/// picker's mode tabs. It is a **controlled** component: the parent owns
/// the chosen value via [value] and reacts through [onChanged]. With no
/// [onChanged] (or `enabled: false`) the group is inert and paints its
/// flat disabled look.
///
/// Rendered entirely with `<div>` elements (no native `<input
/// type="radio">`) so Web and Flutter share one rendering model; the
/// track is a `radiogroup` of `radio` segments (WAI-ARIA radio group
/// pattern): one tab stop (the chosen segment, else the first), arrow
/// keys on either axis move focus — wrapping — and choose the segment
/// they land on.
///
/// Every chrome / dimensional / nested-slot override flows through the
/// single [toggleGroupStyle] (a [CoreToggleGroupStyle]). Behaviour fields
/// (`items` / `value` / `onChanged` / `enabled`) stay flat on the
/// component.
///
/// ```text
/// design system default for toggleGroup
///   → CoreToggleGroupTheme.style                  // 프로젝트 공통
///   → component.toggleGroupStyle                  // 인스턴스별
/// ```
///
/// surface:content — a track that sits in the page flow, not something
/// mounted over content. The track is the surface; the moving chosen face
/// is not.
///
/// Example:
/// ```dart
/// ToggleGroup<String>(
///   value: _selected,
///   onChanged: (value) => setState(() => _selected = value),
///   items: const [
///     CoreToggleGroupItem(value: 'am', label: 'AM'),
///     CoreToggleGroupItem(value: 'pm', label: 'PM'),
///   ],
/// )
/// ```
class ToggleGroup<T> extends UiComponent
    implements CoreToggleGroupContract<Component, T> {
  /// Creates a [ToggleGroup].
  const ToggleGroup({
    required this.items,
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled,
    this.size = CoreToggleGroupContract.defaultSize,
    this.direction = CoreToggleGroupContract.defaultDirection,
    this.fillWidth = false,
    this.trailing,
    this.toggleGroupStyle,
    super.id,
  }) : assert(items.length > 0, 'ToggleGroup must have at least one item.'),
       super(tag: 'div');

  @override
  final List<CoreToggleGroupItem<T, Component>> items;

  @override
  final T? value;

  @override
  final void Function(T)? onChanged;

  @override
  final bool? enabled;

  @override
  final CoreComponentSize size;

  @override
  final CoreAxis direction;

  @override
  final bool fillWidth;

  @override
  final Component? trailing;

  /// Per-instance composite style. See [CoreToggleGroupStyle] for the
  /// merge chain.
  @override
  final CoreToggleGroupStyle? toggleGroupStyle;

  /// Whether the group accepts input: `enabled`, else whether [onChanged]
  /// is set.
  bool get _effectiveEnabled => enabled ?? (onChanged != null);

  @override
  ToggleGroup<T> copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<CoreToggleGroupItem<T, Component>>? items,
    T? value,
    void Function(T)? onChanged,
    bool? enabled,
    CoreComponentSize? size,
    CoreAxis? direction,
    bool? fillWidth,
    Component? trailing,
    CoreToggleGroupStyle? toggleGroupStyle,
  }) {
    return ToggleGroup(
      key: key ?? this.key,
      items: items ?? this.items,
      value: value ?? this.value,
      onChanged: onChanged ?? this.onChanged,
      enabled: enabled ?? this.enabled,
      size: size ?? this.size,
      direction: direction ?? this.direction,
      fillWidth: fillWidth ?? this.fillWidth,
      trailing: trailing ?? this.trailing,
      toggleGroupStyle: toggleGroupStyle ?? this.toggleGroupStyle,
      id: id ?? this.id,
    );
  }

  @override
  Component build(BuildContext context) {
    final isEnabled = _effectiveEnabled;
    final handleChanged = onChanged;
    final resolved = resolveToggleGroup(
      context,
      enabled: isEnabled,
      size: size,
      direction: direction,
      fillWidth: fillWidth,
      toggleGroupStyle: toggleGroupStyle,
    );

    // A radio group is one tab stop — the chosen radio, else the first —
    // and the arrows (either axis, wrapping) move focus and choose the
    // radio they land on. Stateless, so the stop is the chosen item. A
    // disabled group has no tab stop and no keys.
    final hostId = id ?? elementScopeId(context, prefix: 'co-toggle-group');
    final chosen = items.indexWhere((item) => item.value == value);
    final tabStop = chosen < 0 ? 0 : chosen;

    final children = <Component>[
      for (final (index, item) in items.indexed)
        _buildItem(
          resolved,
          item,
          enabled: isEnabled,
          rovingAttributes: isEnabled
              ? rovingItemAttributes(hostId, index, active: index == tabStop)
              : const <String, String>{},
        ),
      ?trailing,
    ];

    return Component.element(
      tag: 'div',
      id: id,
      classes: resolved.root.className,
      styles: resolved.root.inlineStyles,
      attributes: {
        ...componentAttributes,
        'role': 'radiogroup',
        if (!isEnabled) 'aria-disabled': 'true',
      },
      events: isEnabled && handleChanged != null
          ? withRovingKeys(
              events,
              hostId: hostId,
              count: items.length,
              tabStop: tabStop,
              vertical: false,
              bothAxes: true,
              onMove: (index) => handleChanged(items[index].value),
            )
          : events,
      children: [
        div(
          children,
          classes: resolved.inner.className,
          styles: resolved.inner.inlineStyles,
        ),
      ],
    );
  }

  Component _buildItem(
    ResolvedToggleGroup resolved,
    CoreToggleGroupItem<T, Component> item, {
    required bool enabled,
    required Map<String, String> rovingAttributes,
  }) {
    final isSelected = item.value == value;
    final handleChanged = onChanged;
    final itemChrome = isSelected
        ? resolved.itemSelected
        : resolved.itemUnselected;
    final iconSlot = isSelected
        ? resolved.iconSlotSelected
        : resolved.iconSlotUnselected;
    final iconStyle = isSelected
        ? resolved.selectedIconStyle
        : resolved.iconStyle;
    final icon = item.icon;
    // The composed Clickable owns tap, keyboard activation, cursor, press
    // feedback and the focus ring; the inner element carries only the
    // fill, shadow and label chrome. The radio role, aria-checked and
    // aria-label pass through to the Clickable root, where caller
    // attributes win over its generic button role. The label stays the
    // accessible name even when it is not painted (icon-only segment).
    return Clickable(
      onPressed: enabled && handleChanged != null
          ? () => handleChanged(item.value)
          : null,
      enabled: enabled,
      semanticsButton: false,
      attributes: {
        'role': 'radio',
        'aria-checked': '$isSelected',
        'aria-label': item.label,
        // After the Clickable's own `tabindex`, so the roving value wins.
        ...rovingAttributes,
      },
      clickableStyle: resolved.clickableStyle,
      css: resolved.itemHost.inlineStyles,
      child: Component.element(
        tag: 'div',
        classes: itemChrome.className,
        styles: itemChrome.inlineStyles,
        children: [
          // Icon slot — the per-state icon colour rides the span chrome
          // (inherited via `currentColor`); the size reaches the
          // caller-supplied component through the ambient `IconTheme`.
          if (icon != null)
            Component.element(
              tag: 'span',
              classes: iconSlot.className,
              styles: iconSlot.inlineStyles,
              children: [
                IconTheme(
                  data: IconThemeData(size: iconStyle.size),
                  child: icon,
                ),
              ],
            ),
          // Label box — the label's own horizontal inset; omitted for an
          // icon-only segment so it collapses to a square.
          if (item.showLabel)
            Component.element(
              tag: 'span',
              classes: resolved.labelBox.className,
              styles: resolved.labelBox.inlineStyles,
              children: [
                // Label stack — overlays the visible label on an
                // invisible chosen-typography twin so the segment width
                // stays constant when the choice moves.
                Component.element(
                  tag: 'span',
                  styles: resolved.labelStack.inlineStyles,
                  children: [
                    Text(item.label),
                    Component.element(
                      tag: 'span',
                      classes: resolved.labelGhost.className,
                      styles: resolved.labelGhost.inlineStyles,
                      attributes: const {'aria-hidden': 'true'},
                      children: [Text(item.label)],
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Chain sugar for merging a [CoreToggleGroupStyle] patch into
/// [ToggleGroup.toggleGroupStyle] without hand-reconstructing every field.
/// Mirrors the Flutter `ToggleGroup.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreToggleGroupStyle.merge` right-side-wins semantics). This is
/// the full-control path — every field of the style is reachable through it.
///
/// ```dart
/// ToggleGroup<String>(...).withStyle(
///   const CoreToggleGroupStyle(
///     borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
///   ),
/// )
/// ```
extension ToggleGroupStyleChain<T> on ToggleGroup<T> {
  /// Sets the content padding.
  ToggleGroup<T> contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreToggleGroupStyle(padding: value));

  /// Sets the background paint and preserves the other style fields.
  ToggleGroup<T> backgroundColor(CoreColor value) =>
      withStyle(CoreToggleGroupStyle(backgroundColor: value));

  /// Returns a copy of this [ToggleGroup] with [patch] merged into
  /// [toggleGroupStyle] (patch fields win on conflict).
  ToggleGroup<T> withStyle(CoreToggleGroupStyle patch) => copyWith(
    toggleGroupStyle: (toggleGroupStyle ?? const CoreToggleGroupStyle()).merge(
      patch,
    ),
  );
}
