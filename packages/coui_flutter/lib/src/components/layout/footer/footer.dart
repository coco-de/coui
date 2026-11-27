import 'package:coui_flutter/coui_flutter.dart';

/// Unified page footer for Flutter.
///
/// Stacks an optional full-bleed top rule ([showDivider]) above a padded
/// content box holding the navigation band ([aside] + [sections]) and the
/// legal block ([company] / the business-info disclosure / [links] /
/// [copyright]). Every block is skipped when its slots are empty, so a
/// footer that carries only navigation renders exactly what it did
/// before the legal block existed.
///
/// Colours, padding, and default text style flow from the widget →
/// `CoreComponentTheme.footer` → design system defaults.
///
/// ```dart
/// Footer(
///   aside: Logo(),
///   sections: [
///     CoreFooterNavData<Widget>(
///       title: 'Services',
///       children: [
///         Link(href: '/branding', child: const Text('Branding')),
///         Link(href: '/design', child: const Text('Design')),
///       ],
///     ),
///   ],
///   company: const Text('Cocode Inc.'),
///   businessInfoLabel: const Text('Business info'),
///   businessInfo: const Text('CEO Jane Doe · Registration no. …'),
///   links: [Link(href: '/terms', child: const Text('Terms of service'))],
///   copyright: const Text('© 2026 Cocode Inc.'),
/// )
/// ```
///
/// surface:content — a page-flow band, not something mounted over
/// content.
class Footer extends StatelessWidget implements CoreFooterContract<Widget> {
  /// Creates a [Footer].
  const Footer({
    required this.sections,
    super.key,
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
  });

  @override
  final List<CoreFooterNavData<Widget>> sections;

  @override
  final Widget? aside;

  @override
  final CoreFooterLayout? layout;

  @override
  final Widget? company;

  @override
  final Widget? businessInfoLabel;

  @override
  final Widget? businessInfo;

  @override
  final bool businessInfoExpanded;

  @override
  final void Function(bool)? onBusinessInfoExpandedChanged;

  @override
  final List<Widget> links;

  @override
  final Widget? copyright;

  @override
  final bool showDivider;

  @override
  final String? semanticLabel;

  @override
  final CoreFooterStyle? footerStyle;

  /// Returns a copy of this [Footer] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Footer copyWith({
    Key? key,
    List<CoreFooterNavData<Widget>>? sections,
    Widget? aside,
    CoreFooterLayout? layout,
    Widget? company,
    Widget? businessInfoLabel,
    Widget? businessInfo,
    bool? businessInfoExpanded,
    void Function(bool)? onBusinessInfoExpandedChanged,
    List<Widget>? links,
    Widget? copyright,
    bool? showDivider,
    String? semanticLabel,
    CoreFooterStyle? footerStyle,
  }) {
    return Footer(
      key: key ?? this.key,
      sections: sections ?? this.sections,
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

  @override
  Widget build(BuildContext context) {
    final resolved = resolveFooter(
      context,
      layout: layout,
      footerStyle: footerStyle,
    );

    final navColumns = <Widget>[
      for (final section in sections)
        _FooterNavSection(data: section, resolved: resolved),
    ];

    // Two levels, the shape the designer set draws and the Web twin
    // builds: the band holds `aside` beside a *wrapper* around the nav
    // columns, not beside the columns themselves. Flattened to one
    // level, a wrapping run puts `aside` on the same line as whichever
    // columns happen to fit, so the branding slot drifts into the middle
    // of the navigation.
    final bandChildren = <Widget>[
      ?aside,
      if (navColumns.isNotEmpty) _band(resolved, navColumns),
    ];

    final legalRows = _legalRows(resolved);

    // An empty block is left out of the list rather than rendered at
    // zero height: a zero-height child still collects `blockSpacing` on
    // both sides, so a footer with no legal content would grow a gap
    // where nothing is drawn.
    final blocks = <Widget>[
      if (bandChildren.isNotEmpty) _band(resolved, bandChildren),
      if (legalRows.isNotEmpty)
        Column(
          mainAxisSize: .min,
          // Follows the layout, same as every other band: `center` that
          // centred the navigation and left the legal block hard against
          // the leading edge would be two answers to one question. The
          // Web twin puts `items-center` on the same box.
          crossAxisAlignment: resolved.layout == .center ? .center : .start,
          spacing: resolved.legalSpacing,
          children: legalRows,
        ),
    ];

    // The role says what this is; the label says which one it is. They
    // were the same string before — `label: 'footer'` announces the word
    // "footer" and states no landmark at all, so the region a user wants
    // to jump to was not in the landmark list.
    return CoUISemantics(
      role: .contentInfo,
      label: semanticLabel ?? CoUILocalizations.of(context).footerLabel,
      container: true,
      // `OutlinedContainer` owns the band's fill / full-bleed width —
      // the widget only composes it. The band's inset is applied to the
      // content box below instead of inside that container, so the top
      // rule sits flush at the top edge and spans the full width, which
      // is how the designer set draws it (640 wide at `y=0` against
      // 592-wide siblings that start at `y=40`).
      child: OutlinedContainer(
        containerStyle: resolved.containerStyle,
        child: DefaultTextStyle.merge(
          style: resolved.bodyStyle,
          // What `center` means for text: the Web twin puts `text-center`
          // on the whole band, so a wrapped line has to centre on this
          // side too or the two read differently at the second line.
          textAlign: resolved.layout == .center ? .center : null,
          child: Column(
            mainAxisSize: .min,
            // Stretch so the blocks below receive a bounded width: the
            // company row hands its disclosure a `Flexible`, and a flex
            // child under an unbounded main axis is a layout error.
            crossAxisAlignment: .stretch,
            children: [
              if (showDivider) Divider(dividerStyle: resolved.dividerStyle),
              Padding(
                padding: resolved.padding,
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  spacing: resolved.blockSpacing,
                  children: blocks,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lays [children] out the way the resolved layout stacks the
  /// navigation band — a wrapping row, or a start / centre aligned
  /// column.
  ///
  /// Used at both levels of the band (the band itself and the wrapper
  /// around the nav columns), so the two cannot disagree about what a
  /// layout means.
  Widget _band(ResolvedFooter resolved, List<Widget> children) =>
      switch (resolved.layout) {
        .horizontal => Wrap(
          spacing: resolved.sectionSpacing,
          runSpacing: resolved.sectionSpacing,
          children: children,
        ),
        .vertical => Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: resolved.sectionSpacing,
          children: children,
        ),
        .center => Column(
          mainAxisSize: .min,
          crossAxisAlignment: .center,
          spacing: resolved.sectionSpacing,
          children: children,
        ),
      };

  /// Builds the legal block's rows, skipping each row whose slots are
  /// empty. Returns an empty list when the whole block is absent.
  List<Widget> _legalRows(ResolvedFooter resolved) {
    final currentCompany = company;
    final currentBusinessInfo = businessInfo;
    final currentCopyright = copyright;

    // One tick description reused across both rows — the designer set
    // draws the identical mark in each, and a widget is a description,
    // so the same instance may appear more than once.
    final tick = _FooterInlineDivider(resolved: resolved);

    // The trigger is only an affordance for the paragraph, so it cannot
    // outlive it: no `businessInfo` means no disclosure at all, chevron
    // included.
    final companyRow = <Widget>[
      if (currentCompany != null)
        DefaultTextStyle.merge(
          style: resolved.companyStyle,
          child: currentCompany,
        ),
      if (currentCompany != null && currentBusinessInfo != null) tick,
      if (currentBusinessInfo != null)
        // `Flexible` (loose), not `Expanded`: a short paragraph lets the
        // disclosure hug its label so the chevron stays beside it, and a
        // long one is clamped to the remaining width instead of
        // overflowing. `Collapsible` sizes trigger and content together
        // — its `IntrinsicWidth` would otherwise measure the paragraph
        // on a single line and run off the row.
        Flexible(
          child: Collapsible(
            expanded: businessInfoExpanded,
            onExpandedChanged: onBusinessInfoExpandedChanged,
            collapsibleStyle: resolved.collapsibleStyle,
            trigger: businessInfoLabel ?? const SizedBox.shrink(),
            content: currentBusinessInfo,
          ),
        ),
    ];

    return [
      if (companyRow.isNotEmpty)
        Row(
          mainAxisSize: .min,
          // Start, not centre: the disclosure grows downward when it
          // opens, and centring would float the company name into the
          // middle of the revealed paragraph.
          crossAxisAlignment: .start,
          spacing: resolved.companyRowSpacing,
          children: companyRow,
        ),
      if (links.isNotEmpty)
        Wrap(
          // Main-axis, not cross-axis: the row itself stretches, so a
          // centred layout has to say where the run sits inside it. The
          // Web twin says the same thing with `justify-center`.
          alignment: resolved.layout == .center ? .center : .start,
          spacing: resolved.linkRowSpacing,
          runSpacing: resolved.linkRowSpacing,
          crossAxisAlignment: .center,
          children: [
            for (var i = 0; i < links.length; i++) ...[
              if (i > 0) tick,
              links[i],
            ],
          ],
        ),
      if (currentCopyright != null)
        DefaultTextStyle.merge(
          style: resolved.copyrightStyle,
          child: currentCopyright,
        ),
    ];
  }
}

/// Chain sugar for merging a [CoreFooterStyle] patch into
/// [Footer.footerStyle] without hand-reconstructing every field. Mirrors
/// the Web `Footer.withStyle` extension so both platforms read
/// identically.
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
  /// Sets the content padding.
  Footer contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreFooterStyle(padding: value));

  /// Sets the background paint and preserves the other style fields.
  Footer backgroundColor(CoreColor value) =>
      withStyle(CoreFooterStyle(backgroundColor: value));

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

/// The hairline tick between two inline legal items.
///
/// A `Divider` has no length of its own — it fills the box it is given,
/// and collapses to nothing when that box is unbounded (`LimitedBox`
/// guards the assertion). Inside a row the cross axis *is* unbounded,
/// so the tick has to be given a height, which is what
/// `CoreFooterStyle.inlineDividerLength` states.
class _FooterInlineDivider extends StatelessWidget {
  const _FooterInlineDivider({required this.resolved});

  final ResolvedFooter resolved;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: resolved.inlineDividerLength,
      child: Divider(
        orientation: .vertical,
        dividerStyle: resolved.inlineDividerStyle,
      ),
    );
  }
}

class _FooterNavSection extends StatelessWidget {
  const _FooterNavSection({required this.data, required this.resolved});

  final CoreFooterNavData<Widget> data;
  final ResolvedFooter resolved;

  @override
  Widget build(BuildContext context) {
    final title = data.title;
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: resolved.layout == .center ? .center : .start,
      children: [
        if (title != null && title.isNotEmpty) ...[
          Text(title, style: resolved.titleStyle),
          Gap(gapStyle: resolved.sectionTitleGapStyle),
        ],
        ...data.children,
      ],
    );
  }
}
