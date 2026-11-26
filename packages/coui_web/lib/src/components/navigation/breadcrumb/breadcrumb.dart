import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/navigation/breadcrumb/breadcrumb_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// A unified cross-platform breadcrumb navigation trail for CoUI Web.
///
/// `Breadcrumb` renders a horizontal row of [CoreBreadcrumbItem]s
/// separated by chevron glyphs inside a `<div role="navigation">`. The
/// last item is treated as the current location and is rendered as
/// plain (non-interactive) text; every preceding item is an interactive
/// `role="link"` element that invokes [onItemTap] with its zero-based
/// index. [CoreBreadcrumbItem.href], when provided, is exposed as a
/// `data-href` attribute for tooling — it is not rendered as a native
/// `<a>` and does not drive navigation on its own.
///
/// [enabled] follows the handler (`enabled ?? (onItemTap != null)`): a trail
/// with no handler, or an explicit `enabled: false`, draws every item and
/// separator in the disabled content colour and makes no item interactive.
///
/// Data-driven: pass a [items] list of [CoreBreadcrumbItem]s. Every
/// chrome / dimensional override flows through the single
/// [breadcrumbStyle] field — see [CoreBreadcrumbStyle] for the merge
/// chain.
///
/// Mirrors Flutter `Breadcrumb` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// Breadcrumb(
///   items: const [
///     CoreBreadcrumbItem(label: 'Home', href: '/'),
///     CoreBreadcrumbItem(label: 'Components', href: '/components'),
///     CoreBreadcrumbItem(label: 'Breadcrumb'),
///   ],
///   onItemTap: (i) => navigateTo(i),
/// )
/// ```
class Breadcrumb extends UiComponent implements CoreBreadcrumbContract {
  /// Creates a [Breadcrumb].
  const Breadcrumb({
    required this.items,
    super.key,
    this.onItemTap,
    this.enabled,
    this.variant = CoreBreadcrumbVariant.defaultVariant,
    this.breadcrumbStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final List<CoreBreadcrumbItem> items;

  @override
  final CoreValueChanged<int>? onItemTap;

  @override
  final bool? enabled;

  @override
  final CoreBreadcrumbStyle? breadcrumbStyle;

  /// The visual variant of the breadcrumb.
  final CoreBreadcrumbVariant variant;
  @override
  Component build(BuildContext context) {
    // Scope id for the per-instance pseudo-state scoped rules — used to
    // build the `.co-breadcrumb-h-<id>` class shared by the interactive
    // items and the `<style>` hover rule (the caller's id wins, else a
    // generated one).
    final scopeId = id ?? elementScopeId(context, prefix: 'co-breadcrumb');

    // Single entry point — merge chain + token fallback + every
    // per-state slot pre-composed in `breadcrumb_style.dart`. This
    // build only reads `chrome.X.className / inlineStyles`.
    final effectiveEnabled = enabled ?? (onItemTap != null);
    final resolved = resolveBreadcrumb(
      context,
      variant: variant,
      enabled: effectiveEnabled,
      scopeId: scopeId,
      breadcrumbStyle: breadcrumbStyle,
    );
    final rules = resolveBreadcrumbRules(
      context,
      variant: variant,
      scopeId: scopeId,
      breadcrumbStyle: breadcrumbStyle,
    );
    final handler = effectiveEnabled ? onItemTap : null;

    // Render an explicit `Gap` on either side of every chevron
    // separator so the per-side spacing is owned by the nested
    // `itemSeparatorGapStyle` slot (matching the Flutter widget).
    // `Gap` runs its own resolve / scaling step.
    final gap = Gap(gapStyle: resolved.itemSeparatorGapStyle);

    final children = <Component>[
      // `<style>` is `display: none`, so it never affects the flex row
      // layout — emitted only when a raw hover override needs a scoped rule.
      if (rules.css.isNotEmpty)
        Component.element(tag: 'style', children: [RawText(rules.css)]),
    ];
    for (var i = 0; i < items.length; i++) {
      final isCurrent = i == items.length - 1;
      if (i > 0) {
        children
          ..add(gap)
          ..add(_buildSeparator(resolved))
          ..add(gap);
      }
      children.add(
        _buildItem(
          item: items[i],
          index: i,
          isCurrent: isCurrent,
          resolved: resolved,
          handler: handler,
        ),
      );
    }

    return Component.element(
      tag: tag,
      id: id,
      classes: [
        resolved.root.className,
        ?classes,
      ].join(' ').trim(),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?css,
      ]),
      attributes: {
        ...componentAttributes,
        'role': CoreSemanticRole.navigation.ariaRole,
        'aria-label': CouiLocalizations.of(context).breadcrumbLabel,
        if (!effectiveEnabled) 'aria-disabled': 'true',
      },
      events: events,
      children: children,
    );
  }

  @override
  Breadcrumb copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    List<CoreBreadcrumbItem>? items,
    CoreValueChanged<int>? onItemTap,
    bool? enabled,
    CoreBreadcrumbVariant? variant,
    CoreBreadcrumbStyle? breadcrumbStyle,
  }) {
    return Breadcrumb(
      key: key ?? this.key,
      items: items ?? this.items,
      onItemTap: onItemTap ?? this.onItemTap,
      enabled: enabled ?? this.enabled,
      variant: variant ?? this.variant,
      breadcrumbStyle: breadcrumbStyle ?? this.breadcrumbStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  Component _buildSeparator(ResolvedBreadcrumb resolved) {
    return Component.element(
      tag: 'span',
      classes: resolved.separator.className,
      styles: resolved.separator.inlineStyles,
      attributes: const {'aria-hidden': 'true'},
      children: [
        Icon(
          LucideIcons.chevronRight,
          iconStyle: resolved.separatorIconStyle,
        ),
      ],
    );
  }

  Component _buildItem({
    required CoreBreadcrumbItem item,
    required int index,
    required bool isCurrent,
    required ResolvedBreadcrumb resolved,
    required CoreValueChanged<int>? handler,
  }) {
    final isInteractive = !isCurrent && handler != null;
    final itemChrome = isCurrent
        ? resolved.itemCurrent
        : isInteractive
        ? resolved.itemInteractive
        : resolved.itemPlain;
    final label = Text(item.label);

    if (!isInteractive) {
      return Component.element(
        tag: 'div',
        classes: itemChrome.className,
        styles: itemChrome.inlineStyles,
        attributes: {
          if (isCurrent) 'aria-current': 'page',
        },
        children: [label],
      );
    }

    // Interactive items compose the unified `Clickable`, which owns
    // click / keyboard (Enter / Space) activation / cursor / focus ring
    // — no hand-rolled keydown. The caller attributes override the
    // Clickable root's generic `role="button"` with `role="link"` (not
    // a native `<a>`) so the unified component owns navigation through
    // `onItemTap`, exactly mirroring the Flutter `Clickable` +
    // `Semantics(link:)` path. The destination is exposed as
    // `data-href` for tooling.
    return Clickable(
      onPressed: () => handler(index),
      attributes: {
        'role': 'link',
        'data-href': ?item.href,
      },
      clickableStyle: resolved.clickableStyle,
      child: Component.element(
        tag: 'div',
        classes: itemChrome.className,
        styles: itemChrome.inlineStyles,
        children: [label],
      ),
    );
  }
}

/// Chain sugar mirroring the Flutter `Breadcrumb.withStyle` extension —
/// merges a [CoreBreadcrumbStyle] patch into [Breadcrumb.breadcrumbStyle]
/// via the existing [Breadcrumb.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBreadcrumbStyle.merge` right-side-wins semantics).
extension BreadcrumbStyleChain on Breadcrumb {
  /// Returns a copy of this [Breadcrumb] with [patch] merged into
  /// [breadcrumbStyle] (patch fields win on conflict).
  Breadcrumb withStyle(CoreBreadcrumbStyle patch) => copyWith(
    breadcrumbStyle: (breadcrumbStyle ?? const CoreBreadcrumbStyle()).merge(
      patch,
    ),
  );
}
