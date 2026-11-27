import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart' as dom_utils;
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/layout/hero/hero_appear_dom.dart';
import 'package:coui_web/src/components/layout/hero/hero_style.dart';
import 'package:coui_web/src/theme/theme_context.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// How many event-queue turns to wait for the content node before
/// showing it anyway. The yield is [Duration.zero] — a scheduling
/// turn, not a motion duration — so the document can commit the node
/// the build just returned.
const int _kMaxAttachAttempts = 3;

int _nextHeroAppearId = 0;

/// Marketing hero block for CoUI Web.
///
/// Mirrors Flutter `Hero`. [layout] arranges the foreground: centred
/// copy, or a copy/media pair that stacks below the tablet breakpoint
/// and splits (media trailing) at that breakpoint and above. The
/// threshold is [heroSplitIsRow], the same one `ResponsiveRowColumn`
/// uses. A window resize re-resolves it — Flutter gets the same update
/// from `MediaQuery`.
///
/// [imageUrl] stays the background. [media] is foreground content.
/// A split with no [media] centres [child].
///
/// surface:content — a page-flow banner, not something mounted over
/// content.
class Hero extends UiStatefulComponent implements CoreHeroContract<Component> {
  /// Creates a [Hero] block.
  const Hero({
    required this.child,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    this.layout,
    this.imageUrl,
    this.semanticLabel,
    this.appear = CoreHeroContract.defaultAppear,
    this.heroStyle,
    this.media,
  });

  @override
  final CoreHeroLayout? layout;

  @override
  final String? imageUrl;

  @override
  final String? semanticLabel;

  @override
  final bool appear;

  @override
  final CoreHeroStyle? heroStyle;

  @override
  final Component? media;

  @override
  final Component child;

  /// Returns a copy of this block with the given fields replaced.
  Hero copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    CoreHeroLayout? layout,
    String? imageUrl,
    String? semanticLabel,
    bool? appear,
    CoreHeroStyle? heroStyle,
    Component? media,
    Component? child,
  }) {
    return Hero(
      key: key ?? this.key,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      layout: layout ?? this.layout,
      imageUrl: imageUrl ?? this.imageUrl,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      appear: appear ?? this.appear,
      heroStyle: heroStyle ?? this.heroStyle,
      media: media ?? this.media,
      child: child ?? this.child,
    );
  }

  @override
  State<Hero> createState() => _HeroState();
}

class _HeroState extends State<Hero> {
  void Function()? _disposeResizeListener;

  @override
  void initState() {
    super.initState();
    _disposeResizeListener = dom_utils.listenForViewportResize(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _disposeResizeListener?.call();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final layoutChoice = heroEffectiveLayout(
      layout: component.layout,
      themeStyle: context.theme.coreComponentTheme?.heroSection?.style,
      widgetStyle: component.heroStyle,
    );
    final resolved = resolveHero(
      context,
      imageUrl: component.imageUrl,
      layout: component.layout,
      appear: component.appear,
      heroSectionStyle: component.heroStyle,
    );

    final body = _body(resolved, layoutChoice);
    final hidden = resolved.appearHidden;
    final shown = resolved.appearShown;
    final contentChild = component.appear && hidden != null && shown != null
        ? _HeroContentAppear(hidden: hidden, shown: shown, child: body)
        : body;

    final children = <Component>[
      if (resolved.overlay != null)
        div(
          const [],
          classes: resolved.overlay!.className,
          styles: resolved.overlay!.inlineStyles,
        ),
      div(
        [contentChild],
        classes: resolved.content.className,
        styles: resolved.content.inlineStyles,
      ),
    ];

    final attrs = {
      ...component.componentAttributes,
      'role': CoreSemanticRole.region.ariaRole,
    };
    final label = component.semanticLabel;
    if (label != null) attrs['aria-label'] = label;

    return div(
      children,
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: attrs,
      events: component.events.isEmpty ? null : component.events,
    );
  }

  /// Copy, or the copy/media pair. A split with no media centres the copy.
  Component _body(ResolvedHero resolved, CoreHeroLayout layoutChoice) {
    final trailing = component.media;
    if (layoutChoice != CoreHeroLayout.split || trailing == null) {
      return component.child;
    }
    return div(
      [
        div(
          [component.child],
          classes: resolved.splitSlot.className,
          styles: resolved.splitSlot.inlineStyles,
        ),
        Gap(gapStyle: resolved.splitGapStyle),
        div(
          [trailing],
          classes: resolved.splitSlot.className,
          styles: resolved.splitSlot.inlineStyles,
        ),
      ],
      classes: resolved.splitTrack.className,
      styles: resolved.splitTrack.inlineStyles,
    );
  }
}

/// Renamed to [Hero] (since 0.147).
///
/// `HeroSection` was the component name. `Hero` is the block. Omitting
/// [layout] and [media] keeps the centred hero. [heroSectionStyle]
/// forwards to [Hero.heroStyle].
@Deprecated(
  'Renamed to Hero (since 0.147) — Hero is a Block. heroSectionStyle '
  'moved to heroStyle; layout defaults to center and media is trailing '
  'on split.',
)
class HeroSection extends Hero {
  /// Creates a deprecated [HeroSection] that forwards to [Hero].
  @Deprecated(
    'Renamed to Hero (since 0.147) — Hero is a Block. heroSectionStyle '
    'moved to heroStyle; layout defaults to center and media is trailing '
    'on split.',
  )
  const HeroSection({
    required super.child,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.layout,
    super.imageUrl,
    super.semanticLabel,
    super.appear,
    CoreHeroStyle? heroSectionStyle,
    super.media,
  }) : super(heroStyle: heroSectionStyle);

  /// The style slot under its previous name.
  @Deprecated('Use heroStyle (since 0.147).')
  CoreHeroStyle? get heroSectionStyle => heroStyle;
}

/// Chain sugar mirroring the Flutter `HeroSection.withStyle` extension —
/// merges a [CoreHeroStyle] patch into [HeroSection.heroStyle]
/// via the existing [HeroSection.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreHeroStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreColors` primitive — the
/// getter *name* is the token name, so `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on. That
/// fixed name-to-value mapping is what makes a short getter safe to
/// reuse across components — a curated nickname (`.rounded`, `.compact`)
/// would silently map to a different value per component, but a
/// primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreHeroStyle.backgroundColor]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Hero(appear: true, child: Text('Welcome')).primary
/// ```
extension HeroStyleChain on Hero {
  /// Sets the background paint and preserves the other style fields.
  Hero backgroundColor(CoreColor value) =>
      withStyle(CoreHeroStyle(backgroundColor: value));

  /// Returns a copy of this [Hero] with [patch] merged into
  /// [heroStyle] (patch fields win on conflict).
  Hero withStyle(CoreHeroStyle patch) => copyWith(
    heroStyle: (heroStyle ?? const CoreHeroStyle()).merge(
      patch,
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Hero get primary => withStyle(
    const CoreHeroStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Hero get secondary => withStyle(
    const CoreHeroStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Hero get tertiary => withStyle(
    const CoreHeroStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Hero get surface => withStyle(
    const CoreHeroStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Hero get surfaceContainer => withStyle(
    const CoreHeroStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Hero get error => withStyle(
    const CoreHeroStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Hero get success => withStyle(
    const CoreHeroStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Hero get warning => withStyle(
    const CoreHeroStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Hero get info => withStyle(
    const CoreHeroStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Hero get outline => withStyle(
    const CoreHeroStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Hero get transparent => withStyle(
    const CoreHeroStyle(backgroundColor: .transparent),
  );
}

/// Applies the resolved entrance chrome to [child] the first time the
/// node intersects the viewport.
///
/// The first build uses [hidden]. An `IntersectionObserver` (no-op on
/// the server) swaps in [shown] once and disconnects. A `<noscript>`
/// rule shows the content when scripting never runs, so the pre-entrance
/// opacity does not hide the hero from a no-JS reader.
class _HeroContentAppear extends StatefulComponent {
  const _HeroContentAppear({
    required this.hidden,
    required this.shown,
    required this.child,
  });

  final WebElementChrome hidden;
  final WebElementChrome shown;
  final Component child;

  @override
  State<_HeroContentAppear> createState() => _HeroContentAppearState();
}

class _HeroContentAppearState extends State<_HeroContentAppear> {
  late final String _id = 'coui-hero-appear-${_nextHeroAppearId++}';
  bool _shown = false;
  Timer? _pending;
  void Function()? _stop;

  @override
  void initState() {
    super.initState();
    _arm(0);
  }

  @override
  void dispose() {
    _pending?.cancel();
    _stop?.call();
    super.dispose();
  }

  void _arm(int attempt) {
    _pending?.cancel();
    _pending = Timer(Duration.zero, () {
      if (!mounted || _shown || _stop != null) return;
      final stop = observeHeroAppear(
        elementId: _id,
        onVisible: () {
          if (!mounted || _shown) return;
          setState(() => _shown = true);
        },
      );
      if (stop != null) {
        _stop = stop;
        return;
      }
      if (attempt + 1 >= _kMaxAttachAttempts) {
        setState(() => _shown = true);
        return;
      }
      _arm(attempt + 1);
    });
  }

  @override
  Component build(BuildContext context) {
    return div(
      [
        Component.element(
          tag: 'noscript',
          children: [
            Component.element(
              tag: 'style',
              children: [
                RawText(
                  '#$_id{opacity:1 !important;transform:none !important; '
                  'pointer-events:auto !important}',
                ),
              ],
            ),
          ],
        ),
        component.child,
      ],
      id: _id,
      styles: _shown
          ? component.shown.inlineStyles
          : component.hidden.inlineStyles,
    );
  }
}
