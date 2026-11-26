import 'package:coui_flutter/coui_flutter.dart';

// Paragraph leading ratio — a genuinely file-local derived computation:
// Web's `leading-7` (`1.75rem`, a fixed 28px line, the prose paragraph
// standard) over the body size resolves to `28 / bodySize` as Flutter's
// `TextStyle.height` multiplier. The body role is 14px, so the line stays
// 28px on both platforms — the paragraph preset is a fixed-leading statement,
// and moving the body size does not move it.
const double _kParagraphLeading = 28.0 / CoreFontSize.s14;

/// Resolves a [CoreTypography] role to a paint-ready [TextStyle] for the
/// ambient theme of [context] (token role → Flutter `TextStyle`).
TextStyle _role(
  BuildContext context,
  CoreTextStyle Function(CoreTypography typography) pick,
) {
  final theme = context.theme;
  return pick(theme.typography).toValue(theme: theme);
}

/// A text styling wrapper component.
///
/// Flutter counterpart of `coui_web`'s `TextBlock`. It renders prose
/// text for a semantic role ([CoreTextBlockElement] — paragraph, heading
/// `h1`-`h6`, blockquote, inline span, etc.) with CoUI typography
/// presets. Web binds each element to a semantic HTML tag; Flutter reads
/// the same value twice — for the matching typography token (resolved by
/// [resolveTextBlock]) and for the heading level it states to assistive
/// technology, so the document outline survives the platform boundary.
///
/// Key features:
/// - **Semantic roles**: the [element] selects the base typography.
/// - **Typography presets**: pre-built heading / paragraph / utility
///   styles exposed as static helpers, identical in name to Web.
/// - **Rich text**: can contain child widgets for composed content.
/// - **Token-driven**: presets reference CoUI design tokens.
///
/// Example:
/// ```dart
/// TextBlock(
///   text: 'Hello World',
///   element: CoreTextBlockElement.h1,
///   presets: [TextBlock.heading1(context)],
/// )
/// TextBlock(
///   text: 'A muted subtitle',
///   presets: [TextBlock.muted(context)],
/// )
/// ```
class TextBlock extends StatelessWidget
    implements CoreTextBlockContract<Widget> {
  /// Creates a [TextBlock] widget.
  ///
  /// - [text]: text content to display. Ignored when [children] is set.
  /// - [element]: the semantic element role to render.
  /// - [presets]: typography presets applied to the text.
  /// - [textBlockStyle]: per-instance override for the `blockquote` /
  ///   `pre` box chrome (border / radius / padding).
  /// - [children]: child widgets for rich-text content.
  const TextBlock({
    this.text,
    this.element = CoreTextBlockElement.defaultElement,
    this.presets,
    this.textBlockStyle,
    this.children,
    super.key,
  });

  // --- Text presets (context-independent) ---

  /// Paragraph preset with comfortable line height.
  ///
  /// Mirrors Web's `leading-7` (`1.75rem` fixed leading, the prose
  /// paragraph standard). Flutter's [TextStyle.height] is a multiplier,
  /// so `leading-7` over the 14px body size resolves to `28 / 14` — the
  /// same 28px line Web draws.
  static const TextBlockStyle paragraph = TextBlockStyle(
    TextStyle(height: _kParagraphLeading),
  );

  /// Bold text preset.
  static const TextBlockStyle bold = TextBlockStyle(
    TextStyle(fontWeight: .w700),
  );

  /// Italic text preset.
  static const TextBlockStyle italic = TextBlockStyle(
    TextStyle(fontStyle: .italic),
  );

  /// Blockquote preset.
  ///
  /// Renders the quote text in italic. The left accent border is drawn
  /// by [TextBlock] when [element] is [CoreTextBlockElement.blockquote]
  /// (Flutter has no element-level border styling).
  static const TextBlockStyle quote = TextBlockStyle(
    TextStyle(fontStyle: .italic),
  );

  /// Truncated text with an ellipsis.
  ///
  /// Mirrors Web's `truncate`. Flutter [Text] soft-wraps by default;
  /// applying [TextOverflow.ellipsis] clips overflow on a single line.
  static const TextBlockStyle truncate = TextBlockStyle(
    TextStyle(overflow: .ellipsis),
  );

  /// Text that wraps and breaks words.
  ///
  /// Mirrors Web's `break-words`. Flutter [Text] already soft-wraps and
  /// breaks long words by default, so this preset carries no style
  /// override — it exists for naming parity with `coui_web`.
  static const TextBlockStyle wrap = TextBlockStyle(TextStyle());

  // --- Heading presets (context-dependent) ---

  /// Heading 1 preset.
  static TextBlockStyle heading1(BuildContext context) =>
      .new(_role(context, (t) => t.displaySmall));

  /// Heading 2 preset.
  static TextBlockStyle heading2(BuildContext context) => .new(
    _role(context, (t) => t.headlineLarge),
  );

  /// Heading 3 preset.
  static TextBlockStyle heading3(BuildContext context) => .new(
    _role(context, (t) => t.headlineSmall),
  );

  /// Heading 4 preset.
  static TextBlockStyle heading4(BuildContext context) =>
      .new(_role(context, (t) => t.titleLarge));

  /// Large text preset.
  static TextBlockStyle lg(BuildContext context) =>
      .new(_role(context, (t) => t.titleMedium));

  /// Small text preset.
  static TextBlockStyle sm(BuildContext context) => .new(
    _role(context, (t) => t.labelLarge).copyWith(height: CoreLineHeight.h100),
  );

  /// Muted text preset.
  ///
  /// The muted foreground colour routes through the
  /// `CoreTextBlockStyle.defaultMutedForegroundColor` token
  /// (`scheme.resolve(...).toValue()`) so it stays in sync with Web's
  /// `text-{onSurfaceVariant}`.
  static TextBlockStyle muted(BuildContext context) => .new(
    _role(context, (t) => t.bodySmall).copyWith(
      color: context.colorScheme
          .resolve(CoreTextBlockStyle.defaultMutedForegroundColor)
          .toValue(),
    ),
  );

  /// Lead text (subtitle) preset.
  ///
  /// Shares the `muted` foreground token so the subtitle colour stays a
  /// single source of truth with Web.
  static TextBlockStyle lead(BuildContext context) => .new(
    _role(context, (t) => t.titleLarge).copyWith(
      color: context.colorScheme
          .resolve(CoreTextBlockStyle.defaultMutedForegroundColor)
          .toValue(),
    ),
  );

  /// Inline code preset.
  ///
  /// Renders monospace text on a subtle surface background. Web pads the
  /// `<code>` box; Flutter applies [TextStyle.backgroundColor] so the
  /// preset stays a pure [TextStyle] like every other preset. The
  /// surface fill routes through the
  /// `CoreTextBlockStyle.defaultInlineCodeBackgroundColor` token
  /// (`scheme.resolve(...).toValue()`) so it stays in sync with Web's
  /// `bg-{surfaceContainer}`.
  static TextBlockStyle inlineCode(BuildContext context) => .new(
    _role(context, (t) => t.bodySmall)
        .merge(kCoreMonoTextStyle)
        .copyWith(
          backgroundColor: context.colorScheme
              .resolve(CoreTextBlockStyle.defaultInlineCodeBackgroundColor)
              .toValue(),
          fontWeight: CoreFontWeight.semiBold.weight,
        ),
  );

  /// Text content to display. Ignored when [children] is provided.
  @override
  final String? text;

  /// The semantic element role to render.
  @override
  final CoreTextBlockElement element;

  /// Typography presets applied to the text.
  ///
  /// Build presets with the static helpers above
  /// (`TextBlock.paragraph`, `TextBlock.heading1(context)`, …).
  final List<TextBlockStyle>? presets;

  /// Per-instance override for the `blockquote` / `pre` box chrome —
  /// border width / colour, indent padding, surface radius. Flows
  /// through [resolveTextBlock]'s merge chain.
  @override
  final CoreTextBlockStyle? textBlockStyle;

  /// Rich-text child widgets. When non-null, [text] is ignored.
  @override
  final List<Widget>? children;

  /// Returns a copy of this [TextBlock] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  TextBlock copyWith({
    Key? key,
    String? text,
    CoreTextBlockElement? element,
    List<TextBlockStyle>? presets,
    CoreTextBlockStyle? textBlockStyle,
    List<Widget>? children,
  }) {
    return TextBlock(
      key: key ?? this.key,
      text: text ?? this.text,
      element: element ?? this.element,
      presets: presets ?? this.presets,
      textBlockStyle: textBlockStyle ?? this.textBlockStyle,
      children: children ?? this.children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTextBlock(
      context,
      element: element,
      presets: presets,
      textBlockStyle: textBlockStyle,
    );

    final currentChildren = children;
    final Widget content;
    if (currentChildren != null) {
      content = DefaultTextStyle.merge(
        style: resolved.textStyle,
        child: currentChildren.length == 1
            ? currentChildren.first
            : Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: currentChildren,
              ),
      );
    } else {
      content = Text(text ?? '', style: resolved.textStyle);
    }

    return switch (element) {
      .blockquote => _BlockQuote(resolved: resolved, child: content),
      .pre => _InlineCodeBox(resolved: resolved, child: content),
      // A heading is the one element whose meaning does not survive as
      // typography. Web states it structurally — the element renders as
      // `<h2>` and the browser puts it in the document outline — and
      // until this arm existed Flutter drew the same words larger and
      // told assistive technology nothing, so the outline stopped at the
      // platform boundary.
      //
      // `headingLevel` alone, not `header: true`. They are independent
      // setters, and `header:` is already this kit's mechanism for the
      // page-banner landmark; setting it here would make every heading
      // also read as the banner.
      .h1 ||
      .h2 ||
      .h3 ||
      .h4 ||
      .h5 ||
      .h6 => Semantics(headingLevel: element.headingLevel, child: content),
      .p || .span || .label || .strong || .em || .small => content,
    };
  }
}

/// Left-accent-bordered wrapper for [CoreTextBlockElement.blockquote].
///
/// Draws the start-side accent border and indent of the blockquote chrome.
/// Render-only: every value comes pre-resolved from [resolveTextBlock].
class _BlockQuote extends StatelessWidget {
  const _BlockQuote({required this.resolved, required this.child});

  final ResolvedTextBlock resolved;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: .new(
            color: resolved.blockQuoteBorderColor,
            width: resolved.blockQuoteBorderWidth,
          ),
        ),
      ),
      child: Padding(
        padding: resolved.blockQuotePadding,
        child: child,
      ),
    );
  }
}

/// Surface-tinted box for [CoreTextBlockElement.pre] preformatted text.
///
/// Render-only: every value comes pre-resolved from
/// [resolveTextBlock].
class _InlineCodeBox extends StatelessWidget {
  const _InlineCodeBox({required this.resolved, required this.child});

  final ResolvedTextBlock resolved;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolved.inlineCodeBackgroundColor,
        borderRadius: resolved.inlineCodeRadius,
      ),
      child: Padding(
        padding: resolved.inlineCodePadding,
        child: child,
      ),
    );
  }
}

/// Chain sugar for merging a [CoreTextBlockStyle] patch into
/// [TextBlock.textBlockStyle] without hand-reconstructing every field.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTextBlockStyle.merge` right-side-wins semantics).
///
/// ```dart
/// TextBlock(
///   text: 'Quoted text',
///   element: CoreTextBlockElement.blockquote,
/// ).withStyle(
///   CoreTextBlockStyle(blockQuoteBorderWidth: CoreStrokeWidth.stroke4),
/// )
/// ```
extension TextBlockStyleChain on TextBlock {
  /// Returns a copy of this [TextBlock] with [patch] merged into
  /// [textBlockStyle] (patch fields win on conflict).
  TextBlock withStyle(CoreTextBlockStyle patch) => copyWith(
    textBlockStyle: (textBlockStyle ?? const CoreTextBlockStyle()).merge(
      patch,
    ),
  );
}
