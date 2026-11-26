import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/mockup_browser/mockup_browser_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform browser mockup for CoUI Web.
///
/// Displays a rounded window with a blurred toolbar over its content:
/// controls, navigation, address, share and new-tab capsules. Uses
/// [CoreMockupBrowserContract] from `coui_core` for consistent
/// cross-platform API.
///
/// With [addressBar] set the toolbar reads as a web page; with
/// [addressBar] `null` the address bar, the chevrons and the action are
/// left out of the DOM (not merely hidden) and only the window controls
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
///   addressBar: 'https://coui.dev',
///   child: div([text('Hello!')]),
/// )
///
/// // Desktop app window — controls only.
/// MockupBrowser(
///   addressBar: null,
///   child: div([text('App content')]),
/// )
/// ```
class MockupBrowser extends UiComponent
    implements CoreMockupBrowserContract<Component> {
  /// Creates a [MockupBrowser].
  const MockupBrowser({
    this.showControls = CoreMockupBrowserContract.defaultShowControls,
    this.addressBar = CoreMockupBrowserContract.defaultAddressBar,
    this.child,
    this.mockupBrowserStyle,
    super.tag = 'div',
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
    super.key,
  });

  @override
  final bool showControls;

  @override
  final String? addressBar;

  @override
  final Component? child;

  @override
  final CoreMockupBrowserStyle? mockupBrowserStyle;

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis
    // (`WebResolvedChrome` contract). The widget reads the paint-ready
    // strings directly without merging or token lookups.
    final resolved = resolveMockupBrowser(
      context,
      mockupBrowserStyle: mockupBrowserStyle,
    );
    final currentAddressBar = addressBar;

    return Component.element(
      tag: tag,
      id: id,
      classes: mergeClasses(resolved.root.className, classes),
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
      children: [
        // Composed window surface; the relative body hosts the overlays.
        OutlinedContainer(
          containerStyle: resolved.frameStyle,
          classes: 'h-full',
          child: div(
            [
              div(
                [
                  div(
                    [?child],
                    classes: resolved.contentInset.className,
                    styles: resolved.contentInset.inlineStyles,
                  ),
                ],
                classes: resolved.content.className,
                styles: resolved.content.inlineStyles,
              ),
              // Translucent toolbar overlays the content background.
              div(
                [
                  if (showControls)
                    div(
                      [
                        div(
                          const [],
                          classes: resolved.controlClose.className,
                          styles: resolved.controlClose.inlineStyles,
                        ),
                        div(
                          const [],
                          classes: resolved.controlMinimize.className,
                          styles: resolved.controlMinimize.inlineStyles,
                        ),
                        div(
                          const [],
                          classes: resolved.controlMaximize.className,
                          styles: resolved.controlMaximize.inlineStyles,
                        ),
                      ],
                      classes: resolved.controls.className,
                      styles: resolved.controls.inlineStyles,
                    ),
                  // Browser affordances — absent, not hidden, in the
                  // app-window composition.
                  if (currentAddressBar != null) ...[
                    div(
                      [
                        Icon(
                          LucideIcons.chevronLeft,
                          iconStyle: resolved.navIconStyle,
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          iconStyle: resolved.navDisabledIconStyle,
                        ),
                      ],
                      classes: resolved.nav.className,
                      styles: resolved.nav.inlineStyles,
                    ),
                    div(
                      [
                        div(
                          [
                            Icon(
                              LucideIcons.lock,
                              iconStyle: resolved.addressIconStyle,
                            ),
                            div(
                              [Text(currentAddressBar)],
                              classes: resolved.addressBarLabel.className,
                              styles: resolved.addressBarLabel.inlineStyles,
                            ),
                          ],
                          classes: resolved.domain.className,
                          styles: resolved.domain.inlineStyles,
                        ),
                        Icon(
                          LucideIcons.rotateCw,
                          iconStyle: resolved.addressIconStyle,
                        ),
                      ],
                      classes: resolved.addressBar.className,
                      styles: resolved.addressBar.inlineStyles,
                    ),
                    div(
                      [
                        Icon(
                          LucideIcons.share,
                          iconStyle: resolved.actionIconStyle,
                        ),
                        Icon(
                          LucideIcons.plus,
                          iconStyle: resolved.actionIconStyle,
                        ),
                      ],
                      classes: resolved.action.className,
                      styles: resolved.action.inlineStyles,
                    ),
                  ],
                ],
                classes: resolved.toolbar.className,
                styles: resolved.toolbar.inlineStyles,
              ),
              div(
                const [],
                classes: resolved.windowBorder.className,
                styles: resolved.windowBorder.inlineStyles,
              ),
            ],
            classes: resolved.body.className,
            styles: resolved.body.inlineStyles,
          ),
        ),
      ],
    );
  }

  /// Returns a copy of this [MockupBrowser] with the given fields
  /// replaced. [addressBar] is a getter so a copy can clear it —
  /// `copyWith(addressBar: () => null)` turns a web page into the app-window
  /// composition, which a plain `String?` parameter could not express
  /// (omitting it and passing `null` would read the same).
  @override
  MockupBrowser copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    bool? showControls,
    ValueGetter<String?>? addressBar,
    Component? child,
    CoreMockupBrowserStyle? mockupBrowserStyle,
    String? tag,
  }) {
    return MockupBrowser(
      key: key ?? this.key,
      showControls: showControls ?? this.showControls,
      addressBar: addressBar == null ? this.addressBar : addressBar(),
      mockupBrowserStyle: mockupBrowserStyle ?? this.mockupBrowserStyle,
      tag: tag ?? this.tag,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }
}

/// Chain sugar mirroring the Flutter `MockupBrowser.withStyle` extension —
/// merges a [CoreMockupBrowserStyle] patch into
/// [MockupBrowser.mockupBrowserStyle] via the existing
/// [MockupBrowser.copyWith].
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
/// MockupBrowser(addressBar: '...', child: div([])).radius4.surface
/// ```
extension MockupBrowserStyleChain on MockupBrowser {
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
