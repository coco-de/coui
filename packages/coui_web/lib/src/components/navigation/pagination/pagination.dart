import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/navigation/pagination/pagination_fit_measurer.dart';
import 'package:coui_web/src/components/navigation/pagination/pagination_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// A unified cross-platform pagination control for CoUI Web.
///
/// `Pagination` renders a row of square page-number buttons flanked
/// by previous / next controls inside a `<div role="navigation">`. The
/// active page is highlighted; when the page count exceeds [maxPages]
/// an ellipsis button condenses the hidden range and (optionally)
/// skip-to-first / skip-to-last buttons jump to the edges.
///
/// Every chrome / dimensional override flows through the single
/// [paginationStyle] field — see [CorePaginationStyle] for the merge
/// chain. The behaviour fields (`maxPages` / `showSkipToFirstPage` /
/// `showSkipToLastPage` / `hidePreviousOnFirstPage` /
/// `hideNextOnLastPage` / `showLabel`) stay flat on the component.
///
/// [enabled] follows the handler (`enabled ?? (onPageChanged != null)`): a
/// pagination with no handler, or an explicit `enabled: false`, draws every
/// number, the `…` and the chevrons in the disabled content colour (the
/// current page on the disabled container fill) and makes no button
/// interactive.
///
/// Mirrors Flutter `Pagination` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// Pagination(
///   page: 1,
///   totalPages: 10,
///   onPageChanged: (p) => print('Page: $p'),
/// )
/// ```
///
/// surface:content — a page-nav control that sits in the flow, not
/// something mounted over content.
class Pagination extends UiComponent implements CorePaginationContract {
  /// Creates a [Pagination].
  const Pagination({
    required this.page,
    required this.totalPages,
    super.key,
    this.onPageChanged,
    this.enabled,
    this.maxPages = _kDefaultMaxPages,
    this.showSkipToFirstPage = true,
    this.showSkipToLastPage = true,
    this.hidePreviousOnFirstPage = false,
    this.hideNextOnLastPage = false,
    this.showLabel = false,
    this.variant = CorePaginationVariant.defaultVariant,
    this.role = .defaultRole,
    this.paginationStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  /// One-based current page index.
  final int page;

  @override
  final int totalPages;

  @override
  final CoreValueChanged<int>? onPageChanged;

  @override
  final bool? enabled;

  /// Maximum number of page-number buttons to show at once.
  final int maxPages;

  /// Whether to show a skip-to-first-page button when the leading
  /// ellipsis is visible.
  final bool showSkipToFirstPage;

  /// Whether to show a skip-to-last-page button when the trailing
  /// ellipsis is visible.
  final bool showSkipToLastPage;

  /// Whether to hide the previous button while on the first page.
  final bool hidePreviousOnFirstPage;

  /// Whether to hide the next button while on the last page.
  final bool hideNextOnLastPage;

  /// Whether the previous / next buttons show a text label next to the
  /// chevron.
  final bool showLabel;

  /// The visual variant of the pagination control.
  final CorePaginationVariant variant;

  @override
  final CoreSurfaceRole role;

  @override
  final CorePaginationStyle? paginationStyle;

  /// Default maximum number of page-number buttons to display.
  static const int _kDefaultMaxPages = 3;

  @override
  int get currentPage => page;

  @override
  Component build(BuildContext context) {
    // Single entry point — merge chain + token fallback resolved in
    // `pagination_style.dart`. Per-button chrome ships through the
    // dedicated per-state resolvers so this build only reads
    // `chrome.X.className / inlineStyles`.
    // Scope id for the per-instance `:hover` scoped rules — used to build
    // the shared `.co-pagination-h-*` class name that the page buttons and
    // the `<style>` rules agree on (the caller's id wins, else generated).
    final scopeId = id ?? elementScopeId(context, prefix: 'co-pagination');
    final resolved = resolvePagination(
      context,
      variant: variant,
      scopeId: scopeId,
      role: role,
      paginationStyle: paginationStyle,
    );
    final rules = resolvePaginationRules(
      context,
      variant: variant,
      scopeId: scopeId,
      paginationStyle: paginationStyle,
    );
    final handler = onPageChanged;
    final effectiveEnabled = enabled ?? (onPageChanged != null);

    final children = <Component>[
      // `<style>` is `display: none`, so it is not a flex item and never
      // affects the row layout / gap. Present only when a raw hover-colour
      // override moved off the Tailwind scale.
      if (rules.css.isNotEmpty)
        Component.element(tag: 'style', children: [RawText(rules.css)]),
    ];

    List<Component> rowAt(CorePaginationCompaction compaction) => [
      for (final entry in CorePaginationLayout.entries(
        page: page,
        totalPages: totalPages,
        maxPages: maxPages,
        showSkipToFirstPage: showSkipToFirstPage,
        showSkipToLastPage: showSkipToLastPage,
        hidePreviousOnFirstPage: hidePreviousOnFirstPage,
        hideNextOnLastPage: hideNextOnLastPage,
        showLabel: showLabel,
        compaction: compaction,
      ))
        _buildEntry(context, resolved, handler, entry, effectiveEnabled),
    ];

    final ladder = CorePaginationLayout.ladder(
      page: page,
      totalPages: totalPages,
      maxPages: maxPages,
      showSkipToFirstPage: showSkipToFirstPage,
      showSkipToLastPage: showSkipToLastPage,
      hidePreviousOnFirstPage: hidePreviousOnFirstPage,
      hideNextOnLastPage: hideNextOnLastPage,
      showLabel: showLabel,
    );

    if (ladder.length == 1) {
      children.addAll(rowAt(ladder.single));
    } else {
      // Mirrors the Flutter row: every step of the ladder is built, and
      // the first one as narrow as the width the row is given is shown.
      children.add(
        _PaginationFit(
          steps: [for (final step in ladder) rowAt(step)],
          probes: [for (final step in ladder) rowAt(step)],
          resolved: resolved,
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
        'aria-label': CouiLocalizations.of(context).paginationLabel,
        if (!effectiveEnabled) 'aria-disabled': 'true',
      },
      events: events,
      children: children,
    );
  }

  @override
  Pagination copyWith({
    Key? key,
    int? page,
    int? totalPages,
    CoreValueChanged<int>? onPageChanged,
    bool? enabled,
    int? maxPages,
    bool? showSkipToFirstPage,
    bool? showSkipToLastPage,
    bool? hidePreviousOnFirstPage,
    bool? hideNextOnLastPage,
    bool? showLabel,
    CorePaginationVariant? variant,
    CoreSurfaceRole? role,
    CorePaginationStyle? paginationStyle,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Map<String, List<UiEventHandler>>? eventHandlers,
  }) {
    return Pagination(
      key: key ?? this.key,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      onPageChanged: onPageChanged ?? this.onPageChanged,
      enabled: enabled ?? this.enabled,
      maxPages: maxPages ?? this.maxPages,
      showSkipToFirstPage: showSkipToFirstPage ?? this.showSkipToFirstPage,
      showSkipToLastPage: showSkipToLastPage ?? this.showSkipToLastPage,
      hidePreviousOnFirstPage:
          hidePreviousOnFirstPage ?? this.hidePreviousOnFirstPage,
      hideNextOnLastPage: hideNextOnLastPage ?? this.hideNextOnLastPage,
      showLabel: showLabel ?? this.showLabel,
      variant: variant ?? this.variant,
      role: role ?? this.role,
      paginationStyle: paginationStyle ?? this.paginationStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  Component _buildButton({
    required ResolvedPagination resolved,
    required bool active,
    required bool enabled,
    required bool paginationEnabled,
    required CoreValueChanged<int>? handler,
    required int targetPage,
    required String ariaLabel,
    required List<Component> children,
    bool labelled = false,
  }) {
    final isInteractive = paginationEnabled && enabled && handler != null;
    // A disabled pagination states one chrome for every button and is not
    // wrapped in a `Clickable` at all: the Clickable would dim the whole
    // button on top of the disabled colours (a second, stacked disabled
    // treatment), and there is nothing left for it to own — no tap, no
    // focus, no hover. The button keeps its role, name and
    // `aria-current` so assistive tech still reads a disabled button row.
    if (!paginationEnabled) {
      final disabledChrome = active
          ? resolved.buttonActiveDisabled
          : labelled
          ? resolved.labelButtonDisabled
          : resolved.buttonDisabled;
      return Component.element(
        tag: 'div',
        classes: disabledChrome.className,
        styles: disabledChrome.inlineStyles,
        attributes: {
          'role': 'button',
          'aria-label': ariaLabel,
          'aria-disabled': 'true',
          if (active) 'aria-current': 'page',
        },
        children: children,
      );
    }
    // A labelled button (previous / next with `showLabel`) is never the
    // active page; its chrome takes its width from the label.
    final buttonChrome = active
        ? resolved.buttonActive
        : isInteractive
        ? (labelled
              ? resolved.labelButtonInactiveEnabled
              : resolved.buttonInactiveEnabled)
        : (labelled
              ? resolved.labelButtonInactiveDisabled
              : resolved.buttonInactiveDisabled);
    // Web twin of the Flutter button: the per-button Clickable owns
    // tap / keyboard activation / cursor / press feedback / focus ring
    // and the disabled affordance (button role, tabindex and
    // aria-disabled are Clickable-native, replacing the hand-rolled
    // click / keydown handlers); the inner div carries only the square
    // box / colour chrome.
    return Clickable(
      onPressed: isInteractive ? () => handler(targetPage) : null,
      attributes: {
        'aria-label': ariaLabel,
        if (active) 'aria-current': 'page',
      },
      enabled: isInteractive,
      clickableStyle: resolved.clickableStyle,
      child: Component.element(
        tag: 'div',
        classes: buttonChrome.className,
        styles: buttonChrome.inlineStyles,
        children: children,
      ),
    );
  }

  Component _buildEntry(
    BuildContext context,
    ResolvedPagination resolved,
    CoreValueChanged<int>? handler,
    CorePaginationEntry entry,
    bool paginationEnabled,
  ) {
    return switch (entry) {
      CorePaginationNavigationEntry() => _buildNavigation(
        context,
        resolved,
        handler,
        entry,
        paginationEnabled,
      ),
      CorePaginationPageEntry(page: final pageNumber) => _buildPageButton(
        resolved: resolved,
        label: pageNumber.toString(),
        pageNumber: pageNumber,
        handler: handler,
        paginationEnabled: paginationEnabled,
      ),
      CorePaginationEllipsisEntry(:final targetPage) => _buildEllipsis(
        context,
        resolved,
        handler,
        targetPage,
        paginationEnabled,
      ),
    };
  }

  Component _buildPageButton({
    required ResolvedPagination resolved,
    required String label,
    required int pageNumber,
    required CoreValueChanged<int>? handler,
    required bool paginationEnabled,
  }) {
    final active = pageNumber == page;
    // The active page stays interactive (mirrors Flutter — tapping the
    // current page re-fires the handler with the same index) so the
    // composed Clickable keeps it undimmed and focusable; `aria-current`
    // above marks it for assistive tech.
    return _buildButton(
      resolved: resolved,
      active: active,
      enabled: true,
      paginationEnabled: paginationEnabled,
      handler: handler,
      targetPage: pageNumber,
      ariaLabel: 'Page $label',
      children: [Text(label)],
    );
  }

  Component _buildNavigation(
    BuildContext context,
    ResolvedPagination resolved,
    CoreValueChanged<int>? handler,
    CorePaginationNavigationEntry entry,
    bool paginationEnabled,
  ) {
    final previous = entry.direction == CorePaginationDirection.previous;
    final localizations = CouiLocalizations.of(context);
    final label = previous
        ? localizations.buttonPrevious
        : localizations.buttonNext;
    final icon = Icon(
      previous ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
      iconStyle: resolved.iconStyle,
    );
    // The label stays the button's accessible name whether or not it is
    // drawn, so an icon-only step still says "previous" / "next".
    return _buildButton(
      resolved: resolved,
      active: false,
      enabled: entry.enabled,
      paginationEnabled: paginationEnabled,
      handler: handler,
      targetPage: entry.targetPage,
      ariaLabel: label,
      labelled: entry.showsLabel,
      children: [
        if (entry.showsLabel)
          span(
            previous ? [icon, Text(label)] : [Text(label), icon],
            classes:
                '${WebLayout.inlineFlex} ${WebLayout.itemsCenter} '
                'gap-${CoreSpace.scale.space4}',
          )
        else
          icon,
      ],
    );
  }

  Component _buildEllipsis(
    BuildContext context,
    ResolvedPagination resolved,
    CoreValueChanged<int>? handler,
    int targetPage,
    bool paginationEnabled,
  ) {
    final isInteractive = paginationEnabled && handler != null;
    final ariaLabel = CouiLocalizations.of(
      context,
    ).paginationJumpToPage(targetPage);
    // See `_buildButton` — a disabled pagination draws the bare chrome; the
    // composed Clickable owns the interactive affordance otherwise, and the
    // inner <div> carries only the box / text chrome.
    if (!paginationEnabled) {
      return Component.element(
        tag: 'div',
        classes: resolved.ellipsisDisabled.className,
        styles: resolved.ellipsisDisabled.inlineStyles,
        attributes: {
          'role': 'button',
          'aria-label': ariaLabel,
          'aria-disabled': 'true',
        },
        children: const [Text('…')],
      );
    }
    return Clickable(
      onPressed: isInteractive ? () => handler(targetPage) : null,
      attributes: {'aria-label': ariaLabel},
      enabled: isInteractive,
      clickableStyle: resolved.clickableStyle,
      child: Component.element(
        tag: 'div',
        classes: resolved.ellipsis.className,
        styles: resolved.ellipsis.inlineStyles,
        children: const [Text('…')],
      ),
    );
  }
}

/// Process-level counter for the probe id — instance-unique without a key.
int _paginationFitIdCounter = 0;

/// Shows the first step of a pagination ladder that fits the width the
/// row is given.
///
/// The steps sit directly in the pagination row (a fragment), next to an
/// invisible, inert probe holding a measuring copy of every step. The
/// server renders the first (full) step and no probe; on the client the
/// probe joins after hydration and a
/// [PaginationFitMeasurer] reads the copies and the container width and
/// reports the step to show.
class _PaginationFit extends StatefulComponent {
  const _PaginationFit({
    required this.steps,
    required this.probes,
    required this.resolved,
  });

  /// The row at each step, widest first.
  final List<List<Component>> steps;

  /// A second, measuring copy of [steps] for the probe.
  final List<List<Component>> probes;

  final ResolvedPagination resolved;

  @override
  State<_PaginationFit> createState() => _PaginationFitState();
}

class _PaginationFitState extends State<_PaginationFit> {
  late final String _probeId;
  PaginationFitMeasurer? _measurer;
  int _step = 0;

  /// Whether the measuring copies are rendered — client-only, from the
  /// second frame on.
  bool _probing = false;

  @override
  void initState() {
    super.initState();
    _probeId = 'co-pagination-fit-${_paginationFitIdCounter++}';
  }

  void _handleStep(int step) {
    if (!mounted || step == _step) return;
    setState(() => _step = step);
  }

  @override
  void dispose() {
    _measurer?.dispose();
    _measurer = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    if (kIsWeb) {
      scheduleMicrotask(() {
        if (!mounted) return;
        if (!_probing) {
          // The probe joins after the first client frame, so the
          // hydrating render matches the server's (which has none).
          setState(() => _probing = true);
          return;
        }
        // Re-measure once the copies are committed to the DOM — the
        // ladder (and so the copies) change with the page, locale and
        // text size.
        (_measurer ??= PaginationFitMeasurer(
          probeId: _probeId,
          onStep: _handleStep,
        )).sync();
      });
    }

    final steps = component.steps;
    final step = _step < steps.length ? _step : steps.length - 1;
    final resolved = component.resolved;
    return Component.fragment([
      ...steps[step],
      if (_probing)
        Component.element(
          tag: 'div',
          id: _probeId,
          classes: resolved.fitProbe.className,
          styles: resolved.fitProbe.inlineStyles,
          // Copies for measuring only — never focusable, never announced.
          attributes: const {'inert': '', 'aria-hidden': 'true'},
          children: [
            for (final probe in component.probes)
              Component.element(
                tag: 'div',
                classes: resolved.fitProbeRow.className,
                styles: resolved.fitProbeRow.inlineStyles,
                children: probe,
              ),
          ],
        ),
    ]);
  }
}

/// Chain sugar mirroring the Flutter `Pagination.withStyle` extension —
/// merges a [CorePaginationStyle] patch into [Pagination.paginationStyle]
/// via the existing [Pagination.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CorePaginationStyle.merge` right-side-wins semantics).
extension PaginationStyleChain on Pagination {
  /// Returns a copy of this [Pagination] with [patch] merged into
  /// [paginationStyle] (patch fields win on conflict).
  Pagination withStyle(CorePaginationStyle patch) => copyWith(
    paginationStyle: (paginationStyle ?? const CorePaginationStyle()).merge(
      patch,
    ),
  );
}
