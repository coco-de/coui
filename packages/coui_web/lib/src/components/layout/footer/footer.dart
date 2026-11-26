import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/layout/collapsible/collapsible.dart';
import 'package:coui_web/src/components/layout/footer/footer_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified page footer for CoUI Web.
///
/// Mirrors Flutter `Footer` — stacks an opt-in full-bleed top rule
/// ([showDivider]) above a padded content box holding the navigation
/// band ([aside] + [sections]) and the legal block ([company] / the
/// business-info disclosure / [links] /
/// [copyright]). Every block is skipped when its slots are empty, so a
/// footer that only carries navigation renders what it did before the
/// legal block existed. Uses a `<div>`-based flex layout; no DaisyUI
/// `footer-*` classes.
///
/// Every chrome / dimensional / nested-slot override flows through the
/// single [footerStyle] (a [CoreFooterStyle]). The semantic [layout]
/// enum, the composition slots, and the behaviour flags
/// ([businessInfoExpanded] / [showDivider] / [semanticLabel]) stay flat
/// on the component.
///
/// ```text
/// design system default
///   → CoreFooterTheme.style                  // 프로젝트 공통
///   → component.footerStyle                  // 인스턴스별
/// ```
///
/// Composition, not re-implementation: the top rule and the hairline
/// ticks between inline legal items are `Divider`s, and the business-info
/// disclosure is a `Collapsible` — which owns its own chevron, its own
/// expand animation, and its own hybrid controlled/uncontrolled state.
///
/// Example:
/// ```dart
/// Footer(
///   aside: div([Text('© 2026 CoUI')]),
///   sections: [
///     CoreFooterNavData<Component>(
///       title: 'Services',
///       children: [
///         div([Text('Branding')]),
///         div([Text('Design')]),
///       ],
///     ),
///   ],
///   company: const Text('Cocode Inc.'),
///   businessInfoLabel: const Text('Business info'),
///   businessInfo: const Text('CEO Jane Doe · Business registration no. …'),
///   links: [
///     Link(href: '/refund', child: const Text('Refund policy')),
///     Link(href: '/terms', child: const Text('Terms of service')),
///   ],
///   copyright: const Text('© 2026 Cocode Inc. All rights reserved.'),
/// )
/// ```
///
/// surface:content — a page-flow band, not something mounted over
/// content.
class Footer extends UiComponent implements CoreFooterContract<Component> {
  /// Creates a [Footer].
  ///
  /// Renders a real `<footer>`, which *is* the `contentinfo` landmark.
  ///
  /// This was hardcoded to `'div'`, so the `aria-label` below landed on
  /// a plain `<div>` with no role — and an `aria-label` on a roleless
  /// element creates no landmark at all. Screen-reader landmark
  /// navigation showed nothing, while `HeroSection` sets `role="region"`
  /// and `NavigationBar` emits a real `<nav>`, so this read as an
  /// oversight rather than a policy.
  ///
  /// `tag` changes only the element: the component always states
  /// `role="contentinfo"` (see [configureAttributes]), so a `tag: 'div'`
  /// footer is still a `contentinfo` landmark. A footer nested where a
  /// second landmark is not wanted overrides `role` through `attributes` —
  /// caller attributes win over the component's.
  const Footer({
    required this.sections,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
    this.aside,
    this.layout,
    this.company,
    this.businessInfoLabel,
    this.businessInfo,
    this.businessInfoExpanded = CoreFooterContract.defaultBusinessInfoExpanded,
    this.onBusinessInfoExpandedChanged,
    this.links = const [],
    this.copyright,
    this.showDivider = CoreFooterContract.defaultShowDivider,
    this.semanticLabel,
    this.footerStyle,
    super.tag = 'footer',
  });

  @override
  final List<CoreFooterNavData<Component>> sections;

  @override
  final Component? aside;

  @override
  final CoreFooterLayout? layout;

  @override
  final Component? company;

  @override
  final Component? businessInfoLabel;

  @override
  final Component? businessInfo;

  @override
  final bool businessInfoExpanded;

  @override
  final void Function(bool)? onBusinessInfoExpandedChanged;

  @override
  final List<Component> links;

  @override
  final Component? copyright;

  @override
  final bool showDivider;

  @override
  final String? semanticLabel;

  /// Per-instance composite style. See [CoreFooterStyle] for the merge
  /// chain.
  @override
  final CoreFooterStyle? footerStyle;
  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.add('role', CoreSemanticRole.contentInfo.ariaRole);
    final label = semanticLabel;
    if (label != null) {
      attributes.add('aria-label', label);
    }
    // The locale fallback cannot happen here — this runs without a
    // BuildContext, so it cannot ask what locale is active. It is
    // applied in `build` instead; see the comment there.
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveFooter(
      context,
      layout: layout,
      footerStyle: footerStyle,
    );

    return Component.element(
      tag: tag,
      id: id,
      classes: [resolved.root.className, ?classes].join(' ').trim(),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      // Landmark name. A page can carry several landmarks, and ones
      // without names are indistinguishable to a screen reader — the
      // landmark list reads back as a row of bare role names and tells a
      // user nothing about which is which. The Flutter twin has fallen
      // back to the locale all along; this side required the caller to
      // pass a label and stayed unnamed when they did not.
      //
      // Fallback first, so an explicit `semanticLabel` and any caller
      // `attributes` still override it.
      attributes: {
        'aria-label': CouiLocalizations.of(context).footerLabel,
        ...componentAttributes,
      },
      events: events,
      children: [
        // The rule is full-bleed *and* flush — the root carries no
        // padding at all, so the rule runs edge to edge at the very top
        // and the box below it starts the inset. That is where the
        // designer set draws it: 640 wide at `y=0` inside a 640 root
        // whose other children are 592 and start at `y=40`.
        if (showDivider) Divider(dividerStyle: resolved.dividerStyle),
        div(
          [
            if (aside != null || sections.isNotEmpty)
              div(
                [
                  ?aside,
                  if (sections.isNotEmpty)
                    div(
                      [
                        for (final section in sections)
                          _buildSection(resolved, section),
                      ],
                      classes: resolved.sections.className,
                      styles: resolved.sections.inlineStyles,
                    ),
                ],
                classes: resolved.main.className,
                styles: resolved.main.inlineStyles,
              ),
            if (_hasLegalBlock) _buildLegal(resolved),
          ],
          classes: resolved.content.className,
          styles: resolved.content.inlineStyles,
        ),
      ],
    );
  }

  @override
  Footer copyWith({
    List<CoreFooterNavData<Component>>? sections,
    Component? aside,
    CoreFooterLayout? layout,
    Component? company,
    Component? businessInfoLabel,
    Component? businessInfo,
    bool? businessInfoExpanded,
    void Function(bool)? onBusinessInfoExpandedChanged,
    List<Component>? links,
    Component? copyright,
    bool? showDivider,
    String? semanticLabel,
    CoreFooterStyle? footerStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return Footer(
      key: key ?? this.key,
      sections: sections ?? this.sections,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      aside: aside ?? this.aside,
      layout: layout ?? this.layout,
      company: company ?? this.company,
      businessInfoLabel: businessInfoLabel ?? this.businessInfoLabel,
      businessInfo: businessInfo ?? this.businessInfo,
      businessInfoExpanded: businessInfoExpanded ?? this.businessInfoExpanded,
      onBusinessInfoExpandedChanged:
          onBusinessInfoExpandedChanged ?? this.onBusinessInfoExpandedChanged,
      links: links ?? this.links,
      copyright: copyright ?? this.copyright,
      showDivider: showDivider ?? this.showDivider,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      footerStyle: footerStyle ?? this.footerStyle,
    );
  }

  /// Whether any legal slot is filled. Nothing filled means the block is
  /// not drawn at all — an empty stack would still contribute the
  /// column's block gap.
  bool get _hasLegalBlock =>
      company != null ||
      businessInfo != null ||
      links.isNotEmpty ||
      copyright != null;

  /// Builds the legal block — company row, link row, copyright line,
  /// each skipped when its own slots are empty.
  Component _buildLegal(ResolvedFooter resolved) {
    final currentCompany = company;
    final currentInfo = businessInfo;
    final currentCopyright = copyright;
    return div(
      [
        if (currentCompany != null || currentInfo != null)
          div(
            [
              if (currentCompany != null)
                div(
                  [currentCompany],
                  classes: resolved.company.className,
                  styles: resolved.company.inlineStyles,
                ),
              // The tick separates two things, so it is drawn only when
              // both sides are there.
              if (currentCompany != null && currentInfo != null)
                _buildInlineDivider(resolved),
              if (currentInfo != null)
                Collapsible(
                  // Label alone — the `Collapsible` draws the chevron
                  // itself, so hand-rolling a disclosure here would be
                  // re-implementing a component the kit already has.
                  trigger: businessInfoLabel ?? const div([]),
                  content: currentInfo,
                  // Layout passthrough only. The disclosure hugs its
                  // label — the designer set's company row is HUG/HUG
                  // and the trigger sits right beside the tick, so
                  // `flex-1` would stretch it across the row and throw
                  // the chevron to the far edge. `min-w-0` stays: it is
                  // what lets a long paragraph wrap inside the remaining
                  // width instead of widening the row, which is the same
                  // clamp the Flutter twin gets from a loose `Flexible`.
                  classes: WebLayout.minWZero,
                  expanded: businessInfoExpanded,
                  onExpandedChanged: onBusinessInfoExpandedChanged,
                  collapsibleStyle: resolved.collapsibleStyle,
                ),
            ],
            classes: resolved.companyRow.className,
            styles: resolved.companyRow.inlineStyles,
          ),
        if (links.isNotEmpty)
          div(
            [
              for (final (index, link) in links.indexed) ...[
                if (index > 0) _buildInlineDivider(resolved),
                link,
              ],
            ],
            classes: resolved.linkRow.className,
            styles: resolved.linkRow.inlineStyles,
          ),
        if (currentCopyright != null)
          div(
            [currentCopyright],
            classes: resolved.copyright.className,
            styles: resolved.copyright.inlineStyles,
          ),
      ],
      classes: resolved.legal.className,
      styles: resolved.legal.inlineStyles,
    );
  }

  /// Builds one hairline tick between inline legal items.
  ///
  /// A vertical `Divider` sizes itself `h-full`, so the box it lives in
  /// has to state a height — that is what `inlineDividerBox` carries,
  /// and it rides `classes` / `css` as pure layout passthrough (the
  /// tick's colour and thickness travel in `inlineDividerStyle`).
  Component _buildInlineDivider(ResolvedFooter resolved) => Divider(
    orientation: CoreDividerOrientation.vertical,
    dividerStyle: resolved.inlineDividerStyle,
    classes: resolved.inlineDividerBox.className,
    css: resolved.inlineDividerBox.inlineStyles,
  );

  Component _buildSection(
    ResolvedFooter resolved,
    CoreFooterNavData<Component> section,
  ) {
    final title = section.title;
    final hasTitle = title != null && title.isNotEmpty;
    return div(
      [
        if (hasTitle) ...[
          div(
            [Text(title)],
            classes: resolved.title.className,
            styles: resolved.title.inlineStyles,
          ),
          // Bottom-margin spacer between the title and the section
          // children, owned by the nested `sectionTitleGapStyle` slot
          // (mirrors Flutter — `Gap(gapStyle: …)` rendered between
          // the same siblings). `Gap` runs its own resolve / scaling
          // step.
          Gap(gapStyle: resolved.sectionTitleGapStyle),
        ],
        ...section.children,
      ],
      classes: resolved.section.className,
      styles: resolved.section.inlineStyles,
    );
  }
}

/// Chain sugar mirroring the Flutter `Footer.withStyle` extension —
/// merges a [CoreFooterStyle] patch into [Footer.footerStyle] via the
/// existing [Footer.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFooterStyle.merge` right-side-wins semantics).
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
/// sets [CoreFooterStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Footer(sections: sections).surface
/// ```
extension FooterStyleChain on Footer {
  /// Returns a copy of this [Footer] with [patch] merged into
  /// [footerStyle] (patch fields win on conflict).
  Footer withStyle(CoreFooterStyle patch) => copyWith(
    footerStyle: (footerStyle ?? const CoreFooterStyle()).merge(patch),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Footer get primary => withStyle(
    const CoreFooterStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Footer get secondary => withStyle(
    const CoreFooterStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Footer get tertiary => withStyle(
    const CoreFooterStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Footer get surface => withStyle(
    const CoreFooterStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Footer get surfaceContainer => withStyle(
    const CoreFooterStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Footer get error => withStyle(
    const CoreFooterStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Footer get success => withStyle(
    const CoreFooterStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Footer get warning => withStyle(
    const CoreFooterStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Footer get info => withStyle(
    const CoreFooterStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Footer get outline => withStyle(
    const CoreFooterStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Footer get transparent =>
      withStyle(const CoreFooterStyle(backgroundColor: .transparent));
}
