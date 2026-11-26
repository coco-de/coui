import 'package:coui_flutter/coui_flutter.dart';

/// Unified hero-section landing container for Flutter.
///
/// Renders a large container with an optional background colour, background
/// image (via [imageUrl]), and semi-transparent overlay. The [child] is
/// centred and padded. Set [appear] to fade and raise that content the
/// first time the section meets the viewport; omit it and the hero stays
/// static.
///
/// ```dart
/// Hero(
///   appear: true,
///   semanticLabel: 'Welcome',
///   child: Text('Welcome'),
/// )
/// ```
///
/// surface:content — a page-flow banner, not something mounted over
/// content.
class Hero extends StatelessWidget implements CoreHeroContract<Widget> {
  /// Creates a [Hero] block.
  const Hero({
    required this.child,
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
  final Widget? media;

  @override
  final Widget child;

  /// Returns a copy of this [Hero] with the given fields replaced.
  Hero copyWith({
    Key? key,
    CoreHeroLayout? layout,
    String? imageUrl,
    String? semanticLabel,
    bool? appear,
    CoreHeroStyle? heroStyle,
    Widget? media,
    Widget? child,
  }) {
    return Hero(
      key: key ?? this.key,
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
  Widget build(BuildContext context) {
    final layoutChoice = heroEffectiveLayout(
      layout: layout,
      themeStyle: Theme.of(context).coreComponentTheme?.heroSection?.style,
      widgetStyle: heroStyle,
    );
    final resolved = resolveHero(
      context,
      layout: layout,
      heroSectionStyle: heroStyle,
    );

    final url = imageUrl;

    final stack = Stacks(
      fit: .passthrough,
      children: [
        if (resolved.overlayColor != null)
          Position.fill(child: ColoredBox(color: resolved.overlayColor!)),
        _foreground(resolved, layoutChoice),
      ],
    );

    // `OutlinedContainer` has no image slot, so a picture hero keeps
    // its hand-drawn box (no material — see `ResolvedHero
    // .containerStyle`'s doc). A solid-colour hero composes the
    // primitive (Epic #4349) so a material preset can reach it.
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: resolved.minHeight),
      child: url != null
          ? Container(
              decoration: BoxDecoration(
                color: resolved.backgroundColor,
                image: DecorationImage(image: NetworkImage(url), fit: .cover),
              ),
              child: stack,
            )
          : OutlinedContainer(
              containerStyle: resolved.containerStyle,
              child: stack,
            ),
    );

    // A region needs a name — an unnamed one conveys nothing and the
    // SDK rejects it. So the landmark appears only when the caller gives
    // it one, and a hero without a label stays plain content rather than
    // becoming an anonymous entry in the landmark list.
    final label = semanticLabel;
    if (label == null) return content;

    return CoUISemantics(
      role: .region,
      label: label,
      container: true,
      child: content,
    );
  }

  Widget _foreground(ResolvedHero resolved, CoreHeroLayout layoutChoice) {
    final moving = appear
        ? _HeroContentAppear(
            duration: resolved.appearDuration,
            curve: resolved.appearCurve,
            offset: resolved.appearOffset,
            child: _body(resolved, layoutChoice),
          )
        : _body(resolved, layoutChoice);
    final padded = Padding(padding: resolved.padding, child: moving);
    if (layoutChoice == CoreHeroLayout.center) {
      return Center(child: padded);
    }
    return SizedBox(width: double.infinity, child: padded);
  }

  /// Copy, or the copy/media pair. A split with no [media] centres the
  /// copy so the second cell is not an empty column.
  Widget _body(ResolvedHero resolved, CoreHeroLayout layoutChoice) {
    if (layoutChoice == CoreHeroLayout.center) return child;
    final trailing = media;
    if (trailing == null) return Center(child: child);
    final gap = Gap(gapStyle: resolved.splitGapStyle);
    if (resolved.splitIsRow) {
      return Row(
        children: [
          Expanded(child: child),
          gap,
          Expanded(child: trailing),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [child, gap, trailing],
    );
  }
}

/// Chain sugar for merging a [CoreHeroStyle] patch into
/// [HeroSection.heroStyle] without hand-reconstructing every field.
/// Mirrors the Web `HeroSection.withStyle` extension so both platforms read
/// identically.
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
/// Hero(child: Text('Welcome')).primary
/// ```
extension HeroStyleChain on Hero {
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

/// Renamed to [Hero] (since 0.148).
///
/// `HeroSection` was the component name. `Hero` is the block. Omitting
/// [layout] and [media] keeps the centred hero. [heroSectionStyle]
/// forwards to [Hero.heroStyle].
@Deprecated(
  'Renamed to Hero (since 0.148) — Hero is a Block. heroSectionStyle '
  'moved to heroStyle; layout defaults to center and media is trailing '
  'on split.',
)
class HeroSection extends Hero {
  /// Creates a deprecated [HeroSection] that forwards to [Hero].
  @Deprecated(
    'Renamed to Hero (since 0.148) — Hero is a Block. heroSectionStyle '
    'moved to heroStyle; layout defaults to center and media is trailing '
    'on split.',
  )
  const HeroSection({
    required super.child,
    super.key,
    super.layout,
    super.imageUrl,
    super.semanticLabel,
    super.appear,
    CoreHeroStyle? heroSectionStyle,
    super.media,
  }) : super(heroStyle: heroSectionStyle);

  /// The style slot under its previous name.
  @Deprecated('Use heroStyle (since 0.148).')
  CoreHeroStyle? get heroSectionStyle => heroStyle;
}

/// How many frames to wait for a layout box before showing the content
/// anyway. A hero that never receives a size (offstage, unbounded and
/// dropped) must not stay invisible.
const int _kMaxLayoutAttempts = 8;

/// Plays the hero entrance on [child] the first time its layout box
/// meets the viewport.
///
/// The measurement box sits *outside* the translate. [Transform] does
/// not change layout, but `localToGlobal` follows the paint offset, so
/// measuring the translated child would delay the trigger by [offset].
///
/// Visibility is the intersection of the screen and the nearest
/// [Scrollable] viewport. A hero inside a nested scroller that has not
/// reached that scroller's window stays hidden; a hero with no scroller
/// uses the screen alone. Once revealed, the entrance does not reverse.
class _HeroContentAppear extends StatefulWidget {
  const _HeroContentAppear({
    required this.duration,
    required this.curve,
    required this.offset,
    required this.child,
  });

  final Duration duration;
  final Curve curve;
  final double offset;
  final Widget child;

  @override
  State<_HeroContentAppear> createState() => _HeroContentAppearState();
}

class _HeroContentAppearState extends State<_HeroContentAppear> {
  final GlobalKey _boxKey = GlobalKey();
  ScrollPosition? _position;
  bool _visible = false;
  int _layoutAttempts = 0;

  @override
  void initState() {
    super.initState();
    _scheduleCheck();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindScroll();
    _scheduleCheck();
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  void _bindScroll() {
    if (_visible) return;
    final next = Scrollable.maybeOf(context)?.position;
    if (identical(next, _position)) return;
    _position?.removeListener(_onScroll);
    _position = next;
    _position?.addListener(_onScroll);
  }

  void _onScroll() {
    _checkVisibility();
  }

  void _scheduleCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _visible) return;
      final box = _boxKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) {
        _layoutAttempts += 1;
        if (_layoutAttempts >= _kMaxLayoutAttempts) {
          _reveal();
          return;
        }
        _scheduleCheck();
        return;
      }
      final viewport = _revealViewport();
      if (viewport == null) {
        // A layout box with no usable screen (empty MediaQuery and no
        // FlutterView) would otherwise stay hidden forever — fail open
        // after the same budget used for missing layout.
        _layoutAttempts += 1;
        if (_layoutAttempts >= _kMaxLayoutAttempts) {
          _reveal();
          return;
        }
        _scheduleCheck();
        return;
      }
      _layoutAttempts = 0;
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted || _visible) return;
    final box = _boxKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final viewport = _revealViewport();
    if (viewport == null || !rect.overlaps(viewport)) return;
    _reveal();
  }

  /// The region in which the content counts as on screen.
  ///
  /// Intersecting with the scrollable, not only the screen, is what
  /// keeps a hero scrolled out of a nested list from appearing while
  /// some other part of the window happens to cover its global rect.
  ///
  /// When a parent [MediaQuery] publishes an empty size (common in
  /// hermetic tests that only override flags), fall back to the
  /// enclosing FlutterView so a real layout box can still meet a
  /// real viewport.
  Rect? _revealViewport() {
    final screenSize = _screenSize();
    if (screenSize.isEmpty) return null;
    final screen = Offset.zero & screenSize;
    final scrollable = Scrollable.maybeOf(context);
    final scrollBox = scrollable?.context.findRenderObject();
    if (scrollBox is! RenderBox || !scrollBox.hasSize || !scrollBox.attached) {
      return screen;
    }
    final scrollRect = scrollBox.localToGlobal(Offset.zero) & scrollBox.size;
    final visible = scrollRect.intersect(screen);
    if (visible.isEmpty) return null;
    return visible;
  }

  Size _screenSize() {
    final media = MediaQuery.sizeOf(context);
    if (!media.isEmpty) return media;
    final view = View.maybeOf(context);
    if (view == null) return Size.zero;
    final dpr = view.devicePixelRatio;
    if (dpr <= 0) return Size.zero;
    return view.physicalSize / dpr;
  }

  void _reveal() {
    if (!mounted || _visible) return;
    setState(() => _visible = true);
    _position?.removeListener(_onScroll);
    _position = null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _boxKey,
      child: IgnorePointer(
        ignoring: !_visible,
        child: AnimatedValueBuilder<double>(
          value: _visible ? 1 : 0,
          duration: widget.duration,
          curve: widget.curve,
          builder: (context, t, child) {
            return Opacity(
              // `Opacity` drops semantics at 0 unless asked not to. The
              // entrance is visual; screen readers keep the content.
              opacity: t.clamp(0.0, 1.0),
              alwaysIncludeSemantics: true,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * widget.offset),
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
