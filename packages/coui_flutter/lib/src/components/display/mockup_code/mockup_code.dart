import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform code mockup with token-based rendering.
///
/// Displays a code editor frame with optional line numbers.
/// Uses [CoreMockupCodeContract] from `coui_core` for consistent
/// cross-platform API. Chrome / colour overrides flow through the
/// single [mockupCodeStyle] slot per Epic #1302.
///
/// Example:
/// ```dart
/// MockupCode.fromString('void main() {\n  print("hello");\n}')
/// ```
class MockupCode extends StatelessWidget implements CoreMockupCodeContract {
  /// Creates a [MockupCode].
  const MockupCode({
    super.key,
    required this.lines,
    this.mockupCodeStyle,
  });

  /// Creates from a multiline string, optionally showing line numbers.
  factory MockupCode.fromString(
    String code, {
    Key? key,
    bool showLineNumbers = true,
    CoreMockupCodeStyle? mockupCodeStyle,
  }) {
    final codeLines = code.split('\n');
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
    );
  }

  /// Creates from a list of CoreCodeLine objects.
  factory MockupCode.fromList(
    List<CoreCodeLine> codeLines, {
    Key? key,
    CoreMockupCodeStyle? mockupCodeStyle,
  }) {
    return MockupCode(
      key: key,
      lines: codeLines,
      mockupCodeStyle: mockupCodeStyle,
    );
  }

  @override
  final List<CoreCodeLine> lines;

  @override
  final CoreMockupCodeStyle? mockupCodeStyle;

  /// Returns a copy of this [MockupCode] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  MockupCode copyWith({
    Key? key,
    List<CoreCodeLine>? lines,
    CoreMockupCodeStyle? mockupCodeStyle,
  }) {
    return MockupCode(
      key: key ?? this.key,
      lines: lines ?? this.lines,
      mockupCodeStyle: mockupCodeStyle ?? this.mockupCodeStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMockupCode(
      context,
      mockupCodeStyle: mockupCodeStyle,
    );

    return OutlinedContainer(
      containerStyle: resolved.containerStyle,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          for (final line in lines)
            Padding(
              padding: .only(bottom: resolved.lineSpacing),
              child: Row(
                crossAxisAlignment: .start,
                children: [
                  if (line.prefix != null)
                    SizedBox(
                      width: resolved.lineNumberWidth,
                      child: Text(
                        line.prefix!,
                        style: resolved.prefixTextStyle,
                      ),
                    ),
                  Expanded(
                    // 코드 라인은 줄바꿈하지 않는다 (코드 블록 semantics)
                    // — 넘치는 부분은 잘린다. Web 쪽 whitespace-nowrap +
                    // overflow-hidden 과 동일 동작.
                    child: Text(
                      line.text,
                      style: resolved.toneTextStyles[line.tone],
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Chain sugar for merging a [CoreMockupCodeStyle] patch into
/// [MockupCode.mockupCodeStyle] without hand-reconstructing every field.
/// Mirrors the Web `MockupCode.withStyle` extension so both platforms
/// read identically.
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
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
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
