import 'dart:ui' show ImageFilter;

import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform browser mockup with token-based rendering.
///
/// Displays a rounded window with a blurred toolbar over its content:
/// controls, navigation, address, share and new-tab capsules. Uses
/// [CoreMockupBrowserContract] from `coui_core` for consistent
/// cross-platform API.
///
/// With [addressBar] set the toolbar reads as a web page; with
/// [addressBar] `null` the address bar, the chevrons and the action are
/// left out of the tree (not merely hidden) and only the window controls
/// remain — the desktop app-window composition.
///
/// Chrome / colour / dimensional overrides flow through the single
/// [mockupBrowserStyle] slot. Behavioural / content fields
/// ([showControls], [addressBar], [child]) stay flat on the widget.
///
/// Example:
/// ```dart
/// // Web page.
/// MockupBrowser(
///   addressBar: 'https://example.com',
///   child: Text('Page content'),
/// )
///
/// // Desktop app window — controls only.
/// MockupBrowser(
///   addressBar: null,
///   child: Text('App content'),
/// )
/// ```
class MockupBrowser extends StatelessWidget
    implements CoreMockupBrowserContract<Widget> {
  /// Creates a [MockupBrowser].
  const MockupBrowser({
    super.key,
    this.showControls = CoreMockupBrowserContract.defaultShowControls,
    this.addressBar = CoreMockupBrowserContract.defaultAddressBar,
    this.child,
    this.mockupBrowserStyle,
  });

  @override
  final bool showControls;

  @override
  final String? addressBar;

  @override
  final Widget? child;

  @override
  final CoreMockupBrowserStyle? mockupBrowserStyle;

  /// Returns a copy of this [MockupBrowser] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted. [addressBar] is a getter so a copy can clear it —
  /// `copyWith(addressBar: () => null)` turns a web page into the app-window
  /// composition, which a plain `String?` parameter could not express
  /// (omitting it and passing `null` would read the same).
  MockupBrowser copyWith({
    Key? key,
    bool? showControls,
    ValueGetter<String?>? addressBar,
    CoreMockupBrowserStyle? mockupBrowserStyle,
    Widget? child,
  }) {
    return MockupBrowser(
      key: key ?? this.key,
      showControls: showControls ?? this.showControls,
      addressBar: addressBar == null ? this.addressBar : addressBar(),
      mockupBrowserStyle: mockupBrowserStyle ?? this.mockupBrowserStyle,
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMockupBrowser(
      context,
      mockupBrowserStyle: mockupBrowserStyle,
    );
    final currentAddressBar = addressBar;

    Widget capsule(Widget content) => Container(
      height: resolved.capsuleHeight,
      padding: resolved.capsulePadding,
      decoration: BoxDecoration(
        color: resolved.capsuleBackgroundColor,
        borderRadius: resolved.capsuleBorderRadius,
      ),
      child: content,
    );

    return OutlinedContainer(
      containerStyle: resolved.containerStyle,
      child: Stacks(
        fit: .passthrough,
        children: [
          Container(
            width: double.infinity,
            clipBehavior: .antiAlias,
            decoration: BoxDecoration(
              color: resolved.contentBackgroundColor,
              borderRadius: resolved.contentBorderRadius,
            ),
            child: Padding(
              padding: resolved.contentInset,
              child: DefaultTextStyle(
                style: resolved.contentTextStyle,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
          Position(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: resolved.toolbarBorderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: resolved.toolbarBlur,
                  sigmaY: resolved.toolbarBlur,
                ),
                child: Container(
                  height: resolved.toolbarHeight,
                  padding: resolved.toolbarPadding,
                  decoration: BoxDecoration(
                    color: resolved.toolbarBackgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: resolved.toolbarBorderColor,
                        width: resolved.toolbarBorderWidth,
                      ),
                    ),
                  ),
                  child: Row(
                    spacing: resolved.toolbarSpacing,
                    children: [
                      if (showControls)
                        Row(
                          mainAxisSize: .min,
                          spacing: resolved.controlSpacing,
                          children: [
                            _ControlDot(
                              color: resolved.controlCloseColor,
                              size: resolved.controlSize,
                              borderRadius: resolved.controlBorderRadius,
                            ),
                            _ControlDot(
                              color: resolved.controlMinimizeColor,
                              size: resolved.controlSize,
                              borderRadius: resolved.controlBorderRadius,
                            ),
                            _ControlDot(
                              color: resolved.controlMaximizeColor,
                              size: resolved.controlSize,
                              borderRadius: resolved.controlBorderRadius,
                            ),
                          ],
                        ),
                      if (currentAddressBar != null) ...[
                        capsule(
                          Row(
                            mainAxisSize: .min,
                            spacing: resolved.navSpacing,
                            children: [
                              Icon(
                                LucideIcons.chevronLeft,
                                iconStyle: resolved.navIconStyle,
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                iconStyle: resolved.navDisabledIconStyle,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: resolved.addressBarHeight,
                            padding: resolved.addressBarPadding,
                            decoration: BoxDecoration(
                              color: resolved.addressBarBackgroundColor,
                              borderRadius: resolved.addressBarBorderRadius,
                            ),
                            child: Row(
                              spacing: resolved.addressBarSpacing,
                              children: [
                                Expanded(
                                  child: Row(
                                    spacing: resolved.domainSpacing,
                                    children: [
                                      Icon(
                                        LucideIcons.lock,
                                        iconStyle: resolved.addressIconStyle,
                                      ),
                                      Flexible(
                                        fit: resolved.expandDomainLabel
                                            ? FlexFit.tight
                                            : FlexFit.loose,
                                        child: Text(
                                          currentAddressBar,
                                          style: resolved.addressBarTextStyle,
                                          textAlign:
                                              resolved.addressBarTextAlign,
                                          maxLines: 1,
                                          overflow: .ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  LucideIcons.rotateCw,
                                  iconStyle: resolved.addressIconStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                        capsule(
                          Row(
                            mainAxisSize: .min,
                            spacing: resolved.actionSpacing,
                            children: [
                              Icon(
                                LucideIcons.share,
                                iconStyle: resolved.actionIconStyle,
                              ),
                              Icon(
                                LucideIcons.plus,
                                iconStyle: resolved.actionIconStyle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Position.fill(
            child: IgnorePointer(
              child: InsetShadow(
                shadows: resolved.highlightShadows,
                radius: resolved.windowBorderRadius,
                child: DecoratedBox(
                  decoration: resolved.windowBorderDecoration,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlDot extends StatelessWidget {
  const _ControlDot({
    required this.color,
    required this.size,
    required this.borderRadius,
  });

  final Color color;
  final double size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      width: size,
      height: size,
    );
  }
}

/// Chain sugar for merging a [CoreMockupBrowserStyle] patch into
/// [MockupBrowser.mockupBrowserStyle] without hand-reconstructing every
/// field. Mirrors the Web `MockupBrowser.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMockupBrowserStyle.merge` right-side-wins semantics).
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
/// sets [CoreMockupBrowserStyle.borderRadius] and `.primary` sets
/// [CoreMockupBrowserStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with design)
/// is a follow-up once more components adopt this pattern.
///
/// ```dart
/// MockupBrowser(addressBar: '...', child: Text('...')).radius4.surface
/// ```
extension MockupBrowserStyleChain on MockupBrowser {
  /// Sets the border color.
  MockupBrowser borderColor(CoreColor value) =>
      withStyle(CoreMockupBrowserStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  MockupBrowser borderWidth(double value) =>
      withStyle(CoreMockupBrowserStyle(borderWidth: value));

  /// Sets the background paint and preserves the other style fields.
  MockupBrowser backgroundColor(CoreColor value) =>
      withStyle(CoreMockupBrowserStyle(backgroundColor: value));

  /// Returns a copy of this [MockupBrowser] with [patch] merged into
  /// [mockupBrowserStyle] (patch fields win on conflict).
  MockupBrowser withStyle(CoreMockupBrowserStyle patch) => copyWith(
    mockupBrowserStyle: (mockupBrowserStyle ?? const CoreMockupBrowserStyle())
        .merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  MockupBrowser get radius0 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  MockupBrowser get radius2 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  MockupBrowser get radius4 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  MockupBrowser get radius6 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  MockupBrowser get radius8 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  MockupBrowser get radius10 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  MockupBrowser get radius12 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  MockupBrowser get radius14 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  MockupBrowser get radius16 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  MockupBrowser get radius20 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  MockupBrowser get radius24 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  MockupBrowser get radius28 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  MockupBrowser get radius32 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  MockupBrowser get radius36 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  MockupBrowser get radius40 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  MockupBrowser get radius48 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  MockupBrowser get radius56 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  MockupBrowser get radius64 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  MockupBrowser get radius9999 => withStyle(
    const CoreMockupBrowserStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  MockupBrowser get primary => withStyle(
    const CoreMockupBrowserStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  MockupBrowser get secondary => withStyle(
    const CoreMockupBrowserStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  MockupBrowser get tertiary => withStyle(
    const CoreMockupBrowserStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  MockupBrowser get surface => withStyle(
    const CoreMockupBrowserStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  MockupBrowser get surfaceContainer => withStyle(
    const CoreMockupBrowserStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  MockupBrowser get error => withStyle(
    const CoreMockupBrowserStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  MockupBrowser get success => withStyle(
    const CoreMockupBrowserStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  MockupBrowser get warning => withStyle(
    const CoreMockupBrowserStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  MockupBrowser get info => withStyle(
    const CoreMockupBrowserStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  MockupBrowser get outline => withStyle(
    const CoreMockupBrowserStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  MockupBrowser get transparent => withStyle(
    const CoreMockupBrowserStyle(backgroundColor: .transparent),
  );
}
