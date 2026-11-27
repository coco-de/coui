import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/mockup_code/mockup_code_style.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform code mockup for CoUI Web.
///
/// Displays a code editor frame with optional line numbers. Uses
/// [CoreMockupCodeContract] from `coui_core` for consistent
/// cross-platform API. Chrome / colour overrides flow through the
/// single [mockupCodeStyle] (a [CoreMockupCodeStyle]) per Epic #1603
/// (옵션 B 최종).
///
/// Example:
/// ```dart
/// MockupCode.fromString('npm i coui\ninstalling...\nDone!')
/// ```
class MockupCode extends UiComponent implements CoreMockupCodeContract {
  /// Creates a [MockupCode].
  const MockupCode({
    required this.lines,
    this.mockupCodeStyle,
    super.tag = 'div',
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
    super.key,
  });

  /// Creates from a multiline string, optionally showing line numbers.
  factory MockupCode.fromString(
    String multilineCode, {
    bool showLineNumbers = true,
    CoreMockupCodeStyle? mockupCodeStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Key? key,
  }) {
    final codeLines = multilineCode.split('\n');
    return MockupCode(
      key: key,
      lines: [
        for (final (index, line) in codeLines.indexed)
          CoreCodeLine(
            text: line,
            prefix: showLineNumbers ? '${index + 1}' : null,
          ),
      ],
      mockupCodeStyle: mockupCodeStyle,
      id: id,
      classes: classes,
      css: css,
      attributes: attributes,
    );
  }

  /// Creates from a list of [CoreCodeLine] objects.
  factory MockupCode.fromList(
    List<CoreCodeLine> codeLines, {
    CoreMockupCodeStyle? mockupCodeStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Key? key,
  }) {
    return MockupCode(
      key: key,
      lines: codeLines,
      mockupCodeStyle: mockupCodeStyle,
      id: id,
      classes: classes,
      css: css,
      attributes: attributes,
    );
  }

  @override
  final List<CoreCodeLine> lines;

  @override
  final CoreMockupCodeStyle? mockupCodeStyle;
  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1603
    // PoC v3 옵션 B — `WebResolvedChrome` contract). `co_mockup_code`
    // reads the paint-ready strings directly without invoking the
    // top-level builder helpers.
    final resolved = resolveMockupCode(
      context,
      mockupCodeStyle: mockupCodeStyle,
    );

    final userClasses = classes;
    final finalClasses = userClasses == null || userClasses.isEmpty
        ? resolved.root.className
        : '${resolved.root.className} $userClasses';

    return Component.element(
      tag: tag,
      id: id,
      classes: finalClasses,
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
      children: [
        // Container — composed `OutlinedContainer`, not a hand-rolled
        // `<div>` (`core/style-contract.md`'s child-component-composition
        // rule). It only accepts a single `child`, so the N code-line
        // rows are grouped under one content wrapper — the element that
        // carries MockupCode's complete four-side inset. The composed
        // frame explicitly contributes no additional content padding.
        OutlinedContainer(
          containerStyle: resolved.frameStyle,
          child: div(
            [
              for (final line in lines)
                div(
                  [
                    if (line.prefix != null)
                      span(
                        [Component.text(line.prefix!)],
                        classes: resolved.prefix.className,
                        styles: resolved.prefix.inlineStyles,
                      ),
                    span(
                      [Component.text(line.text)],
                      classes: resolved.toneText[line.tone.index].className,
                      styles: resolved.toneText[line.tone.index].inlineStyles,
                    ),
                  ],
                  classes: resolved.row.className,
                  styles: resolved.row.inlineStyles,
                ),
            ],
            classes: resolved.body.className,
            styles: resolved.body.inlineStyles,
          ),
        ),
      ],
    );
  }

  @override
  MockupCode copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    List<CoreCodeLine>? lines,
    CoreMockupCodeStyle? mockupCodeStyle,
    String? tag,
  }) {
    return MockupCode(
      key: key ?? this.key,
      lines: lines ?? this.lines,
      mockupCodeStyle: mockupCodeStyle ?? this.mockupCodeStyle,
      tag: tag ?? this.tag,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }
}

/// Chain sugar mirroring the Flutter `MockupCode.withStyle` extension —
/// merges a [CoreMockupCodeStyle] patch into [MockupCode.mockupCodeStyle]
/// via the existing [MockupCode.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMockupCodeStyle.merge` right-side-wins semantics).
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
/// sets [CoreMockupCodeStyle.borderRadius] and `.primary` sets
/// [CoreMockupCodeStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// MockupCode.fromString('...').radius4.surface
/// ```
extension MockupCodeStyleChain on MockupCode {
  /// Sets the content padding.
  MockupCode contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreMockupCodeStyle(padding: value));

  /// Sets the background paint and preserves the other style fields.
  MockupCode backgroundColor(CoreColor value) =>
      withStyle(CoreMockupCodeStyle(backgroundColor: value));

  /// Returns a copy of this [MockupCode] with [patch] merged into
  /// [mockupCodeStyle] (patch fields win on conflict).
  MockupCode withStyle(CoreMockupCodeStyle patch) => copyWith(
    mockupCodeStyle: (mockupCodeStyle ?? const CoreMockupCodeStyle()).merge(
      patch,
    ),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  MockupCode get radius0 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  MockupCode get radius2 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  MockupCode get radius4 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  MockupCode get radius6 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  MockupCode get radius8 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  MockupCode get radius10 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  MockupCode get radius12 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  MockupCode get radius14 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  MockupCode get radius16 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  MockupCode get radius20 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  MockupCode get radius24 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  MockupCode get radius28 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  MockupCode get radius32 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  MockupCode get radius36 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  MockupCode get radius40 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  MockupCode get radius48 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  MockupCode get radius56 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  MockupCode get radius64 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  MockupCode get radius9999 => withStyle(
    const CoreMockupCodeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  MockupCode get primary => withStyle(
    const CoreMockupCodeStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  MockupCode get secondary => withStyle(
    const CoreMockupCodeStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  MockupCode get tertiary => withStyle(
    const CoreMockupCodeStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  MockupCode get surface => withStyle(
    const CoreMockupCodeStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  MockupCode get surfaceContainer => withStyle(
    const CoreMockupCodeStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  MockupCode get error => withStyle(
    const CoreMockupCodeStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  MockupCode get success => withStyle(
    const CoreMockupCodeStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  MockupCode get warning => withStyle(
    const CoreMockupCodeStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  MockupCode get info => withStyle(
    const CoreMockupCodeStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  MockupCode get outline => withStyle(
    const CoreMockupCodeStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  MockupCode get transparent => withStyle(
    const CoreMockupCodeStyle(backgroundColor: .transparent),
  );
}
