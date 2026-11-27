import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/bottom_sheet/bottom_sheet_measurer.dart';
import 'package:coui_web/src/components/layout/bottom_sheet/bottom_sheet_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform bottom sheet — the panel that rises from the
/// bottom of a phone screen: a title, a short line under it, the content,
/// and the actions that finish it.
///
/// Uses [CoreBottomSheetContract] from `coui_core`, so the Flutter
/// `BottomSheet` takes the same named properties. Anatomy, top to bottom:
/// `[ handle ] [ title · close ] [ description ] [ divider ] [ content ]
/// [ footer ]`. The sheet owns the arrangement, the padding and the filled
/// surface with its two rounded top corners; the [content] and the
/// [footer] (a `BottomActionBar` by convention) are the caller's own.
///
/// The sheet is the panel, not the presenter: it does not open, dim the
/// page or dismiss itself — [onClose] only reports the close button's
/// press.
///
/// The sheet is at most `maxHeightFactor` of the viewport's height. Past
/// that the content alone scrolls — the header stays at the top and the
/// footer stays pinned at the bottom, with the content clipped above it.
/// The footer's area paints no fill, and the hairline above it shows only
/// while more content lies below.
///
/// ```dart
/// BottomSheet(
///   title: const Text('Sort by'),
///   showCloseButton: true,
///   onClose: () {},
///   content: OptionList(children: [...]),
/// )
/// ```
///
/// The root is a plain `<div>` with no role: the sheet is a surface, not a
/// dialog — a page that presents it as one passes
/// `attributes: {'role': 'dialog', 'aria-label': '…'}`.
///
/// surface:behind — a sheet rises over a page that scrolls beneath it.
///
/// surface:functional — the sheet groups a short task above the page.
class BottomSheet extends UiComponent
    implements CoreBottomSheetContract<Component> {
  /// Creates a [BottomSheet].
  const BottomSheet({
    required this.title,
    super.key,
    this.description,
    this.content,
    this.footer,
    this.showHandle = CoreBottomSheetContract.defaultShowHandle,
    this.showCloseButton = CoreBottomSheetContract.defaultShowCloseButton,
    this.showDivider = CoreBottomSheetContract.defaultShowDivider,
    this.onClose,
    this.bottomSheetStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component title;

  @override
  final Component? description;

  @override
  final Component? content;

  @override
  final Component? footer;

  @override
  final bool showHandle;

  @override
  final bool showCloseButton;

  @override
  final bool showDivider;

  @override
  final void Function()? onClose;

  @override
  final CoreBottomSheetStyle? bottomSheetStyle;

  @override
  BottomSheet copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    Component? title,
    Component? description,
    Component? content,
    Component? footer,
    bool? showHandle,
    bool? showCloseButton,
    bool? showDivider,
    void Function()? onClose,
    CoreBottomSheetStyle? bottomSheetStyle,
  }) {
    return BottomSheet(
      key: key ?? this.key,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      footer: footer ?? this.footer,
      showHandle: showHandle ?? this.showHandle,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      showDivider: showDivider ?? this.showDivider,
      onClose: onClose ?? this.onClose,
      bottomSheetStyle: bottomSheetStyle ?? this.bottomSheetStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveBottomSheet(
      context,
      bottomSheetStyle: bottomSheetStyle,
    );

    return div(
      [
        if (showHandle)
          div(
            [
              div(
                const [],
                classes: resolved.handle.className,
                styles: resolved.handle.inlineStyles,
              ),
            ],
            classes: resolved.handleRow.className,
            styles: resolved.handleRow.inlineStyles,
          ),
        div(
          [
            div(
              [
                div(
                  [title],
                  classes: resolved.title.className,
                  styles: resolved.title.inlineStyles,
                ),
                if (showCloseButton)
                  Button(
                    onPressed: onClose,
                    variant: .plain,
                    size: .sm,
                    shape: .square,
                    buttonStyle: resolved.closeButtonStyle,
                    attributes: {
                      // The glyph is an icon alone, so the accessible name
                      // would be empty.
                      'aria-label': CouiLocalizations.of(context).dismissLabel,
                    },
                    child: const Icon(LucideIcons.x),
                  ),
              ],
              classes: resolved.titleRow.className,
              styles: resolved.titleRow.inlineStyles,
            ),
            if (description case final description?) ...[
              Gap(gapStyle: resolved.titleGapStyle),
              div(
                [description],
                classes: resolved.description.className,
                styles: resolved.description.inlineStyles,
              ),
            ],
          ],
          classes: resolved.header.className,
          styles: resolved.header.inlineStyles,
        ),
        if (showDivider) Divider(dividerStyle: resolved.dividerStyle),
        if (content != null || footer != null)
          _BottomSheetBody(
            resolved: resolved,
            content: content,
            footer: footer,
          ),
      ],
      id: id,
      classes: mergeClasses(resolved.root.className, classes),
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
    );
  }
}

/// Radix for the per-instance element id suffix.
const int _kBottomSheetIdRadix = 36;

int _bottomSheetIdCounter = 0;

/// The content's scroll viewport and the pinned footer. Hands the two
/// element ids to the measurer, which writes the "more below" state on the
/// footer's area as a CSS variable — no re-render on scroll.
class _BottomSheetBody extends StatefulComponent {
  const _BottomSheetBody({
    required this.resolved,
    required this.content,
    required this.footer,
  });

  final ResolvedBottomSheet resolved;
  final Component? content;
  final Component? footer;

  @override
  State<_BottomSheetBody> createState() => _BottomSheetBodyState();
}

class _BottomSheetBodyState extends State<_BottomSheetBody> {
  late final String _viewportId;
  late final String _footerId;
  BottomSheetMeasurer? _measurer;

  @override
  void initState() {
    super.initState();
    final suffix = (_bottomSheetIdCounter++).toRadixString(
      _kBottomSheetIdRadix,
    );
    _viewportId = 'co-bottom-sheet-content-$suffix';
    _footerId = 'co-bottom-sheet-footer-$suffix';
  }

  void _ensureMeasurer() {
    if (_measurer != null) return;
    if (component.content == null || component.footer == null) return;
    _measurer = BottomSheetMeasurer(
      viewportId: _viewportId,
      footerId: _footerId,
    )..attach();
  }

  @override
  void dispose() {
    _measurer?.dispose();
    _measurer = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final resolved = component.resolved;
    if (kIsWeb) {
      scheduleMicrotask(() {
        if (mounted) _ensureMeasurer();
      });
    }
    return div(
      [
        if (component.content case final content?)
          div(
            [content],
            id: _viewportId,
            classes: resolved.contentArea.className,
            styles: resolved.contentArea.inlineStyles,
          ),
        if (component.footer case final footer?)
          div(
            [
              _FooterBarTheme(
                footerBarStyle: resolved.footerBarStyle,
                child: footer,
              ),
              div(
                const [],
                classes: resolved.footerDivider.className,
                styles: resolved.footerDivider.inlineStyles,
                attributes: const {'aria-hidden': 'true'},
              ),
            ],
            id: _footerId,
            classes: resolved.footerArea.className,
            styles: resolved.footerArea.inlineStyles,
          ),
      ],
      classes: resolved.body.className,
      styles: resolved.body.inlineStyles,
    );
  }
}

/// Installs the sheet's `BottomActionBar` theme style around the footer, so
/// a bar placed there resolves the sheet's action-area chrome. Any other
/// component ignores the slot. Mirrors the Flutter twin.
class _FooterBarTheme extends StatelessComponent {
  const _FooterBarTheme({required this.footerBarStyle, required this.child});

  final CoreBottomActionBarStyle footerBarStyle;
  final Component child;

  @override
  Component build(BuildContext context) {
    final theme = Theme.of(context);
    final components = theme.coreComponentTheme ?? const CoreComponentTheme();
    return Theme(
      data: theme.copyWith(
        coreComponentTheme: components.copyWith(
          bottomActionBar: CoreBottomActionBarTheme(style: footerBarStyle),
        ),
      ),
      child: child,
    );
  }
}

/// Chain sugar for merging a [CoreBottomSheetStyle] patch into
/// [BottomSheet.bottomSheetStyle] without hand-reconstructing every field.
/// Mirrors the Flutter `BottomSheet.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBottomSheetStyle.merge` right-side-wins semantics).
extension BottomSheetStyleChain on BottomSheet {
  /// Sets the background paint and preserves the other style fields.
  BottomSheet backgroundColor(CoreColor value) =>
      withStyle(CoreBottomSheetStyle(backgroundColor: value));

  /// Returns a copy of this [BottomSheet] with [patch] merged into
  /// [bottomSheetStyle] (patch fields win on conflict).
  BottomSheet withStyle(CoreBottomSheetStyle patch) => copyWith(
    bottomSheetStyle: (bottomSheetStyle ?? const CoreBottomSheetStyle()).merge(
      patch,
    ),
  );
}
