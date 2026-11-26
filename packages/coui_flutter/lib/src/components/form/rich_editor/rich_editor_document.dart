// Adapted from Wonky Work's `wonky_rich_editor` (BSD-3-Clause, Copyright 2026
// The Wonky Work authors) — see NOTICE.

/// How a `RichEditor`'s document is laid out: block spacing, headings,
/// quotes with a bar, literal blocks in a box, tasks with a CoUI
/// `Checkbox`, rules, images — on super_editor.
library;

import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/rich_editor/markdown/markdown_document_codec.dart';
import 'package:coui_flutter/src/components/form/rich_editor/markdown/rich_editor_reactions.dart';
import 'package:super_editor/super_editor.dart';

/// The text styles and component builders of the editor's document.
class RichEditorDocumentStyle {
  /// Creates a [RichEditorDocumentStyle].
  const RichEditorDocumentStyle({
    required this.resolved,
    required this.base,
    required this.placeholder,
    required this.padding,
  });

  /// The resolved chrome.
  final ResolvedRichEditor resolved;

  /// Paragraph text — the `TextArea`'s value text.
  final TextStyle base;

  /// The empty editor's hint — the `TextArea`'s placeholder text.
  final TextStyle placeholder;

  /// Inset of the document inside the box — the `TextArea`'s padding.
  final EdgeInsets padding;

  /// Where a list item's text starts, in from the list's edge, at nesting
  /// depth [indent] (0 for a top-level list) — one [ResolvedRichEditor
  /// .listIndent] per level, the Web twin's padding on each nested list.
  double listItemIndent(int indent) => resolved.listIndent * (indent + 1);

  TextStyle get _code => base.merge(
    resolved.codeTextStyle.copyWith(color: base.color),
  );

  /// [role] over the paragraph text, in the paragraph's colour.
  TextStyle _role(TextStyle role) =>
      base.merge(role.copyWith(color: base.color));

  /// The stylesheet of the document.
  Stylesheet stylesheet() {
    final gap = resolved.blockSpacing;
    final codePadding = resolved.codePadding;
    // One text per level: the resolved title roles, over the paragraph text
    // (whose colour they keep). Levels 4–6 are not offered by the toolbar
    // and read as the smallest.
    final headings = [
      _role(resolved.heading1TextStyle),
      _role(resolved.heading2TextStyle),
      _role(resolved.heading3TextStyle),
    ];
    return Stylesheet(
      documentPadding: padding,
      inlineTextStyler: _inline,
      rules: [
        StyleRule(
          BlockSelector.all,
          (doc, node) => {
            Styles.maxWidth: double.infinity,
            Styles.padding: CascadingPadding.only(bottom: gap),
            Styles.textStyle: base,
          },
        ),
        // A list is one block on the Web: the space is below the list, none
        // between its items.
        StyleRule(
          BlockSelector.all,
          (doc, node) => _continuesList(doc, node)
              ? {Styles.padding: const CascadingPadding.only(bottom: 0)}
              : const {},
        ),
        for (final (level, name) in const [
          (0, 'header1'),
          (1, 'header2'),
          (2, 'header3'),
          (2, 'header4'),
          (2, 'header5'),
          (2, 'header6'),
        ])
          StyleRule(
            BlockSelector(name),
            (doc, node) => {Styles.textStyle: headings[level]},
          ),
        StyleRule(
          const BlockSelector('blockquote'),
          (doc, node) => {
            Styles.padding: CascadingPadding.only(
              left: resolved.quoteBarWidth + resolved.quoteSpacing,
            ),
            Styles.textStyle: base.copyWith(color: resolved.quoteTextColor),
          },
        ),
        StyleRule(
          const BlockSelector('blockquote').after('blockquote'),
          (doc, node) => {Styles.padding: const CascadingPadding.only(top: 0)},
        ),
        StyleRule(
          const BlockSelector('code'),
          (doc, node) => {
            // The box's padding is added around the component.
            Styles.padding: CascadingPadding.only(
              left: codePadding.left,
              right: codePadding.right,
              bottom: gap + codePadding.bottom,
            ),
            Styles.textStyle: _code,
          },
        ),
        StyleRule(
          BlockSelector.all.last(),
          (doc, node) => {
            Styles.padding: CascadingPadding.only(
              bottom: isCodeLike(node) ? codePadding.bottom : 0,
            ),
          },
        ),
      ],
    );
  }

  TextStyle _inline(Set<Attribution> attributions, TextStyle style) {
    var s = style;
    if (attributions.contains(boldAttribution)) {
      s = s.copyWith(fontWeight: FontWeight.w600);
    }
    if (attributions.contains(italicsAttribution)) {
      s = s.copyWith(fontStyle: FontStyle.italic);
    }
    final link = attributions.any((a) => a is LinkAttribution);
    final decorations = [
      if (attributions.contains(strikethroughAttribution))
        TextDecoration.lineThrough,
      if (link) TextDecoration.underline,
    ];
    if (decorations.isNotEmpty) {
      s = s.copyWith(
        decoration: TextDecoration.combine(decorations),
        decorationColor: link ? resolved.linkColor : null,
      );
    }
    if (link) s = s.copyWith(color: resolved.linkColor);
    if (attributions.contains(codeAttribution)) {
      s = s.merge(
        resolved.codeTextStyle.copyWith(
          color: s.color,
          backgroundColor: resolved.codeBackgroundColor,
        ),
      );
    }
    return s;
  }

  /// The component builders: the hint, paragraphs (quote bar, literal box,
  /// headings), list items, tasks, rules and images.
  List<ComponentBuilder> componentBuilders(Editor editor, {String? hint}) => [
    if (hint != null && hint.isNotEmpty) _HintBuilder(hint, placeholder),
    _ParagraphBuilder(this),
    _ListItemBuilder(this),
    _TaskBuilder(editor, this),
    _RuleBuilder(this),
    _ImageBuilder(this),
  ];
}

/// The placeholder in the empty editor's paragraph, wrapped over as many
/// lines as it takes — the `TextArea`'s placeholder.
class _HintBuilder extends HintComponentBuilder {
  _HintBuilder(String hint, TextStyle style) : super(hint, (_) => style);

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (document.nodeCount != 1 ||
        !isPlainParagraph(node) ||
        (node as ParagraphNode).text.isNotEmpty) {
      return null;
    }
    return super.createViewModel(document, node);
  }

  /// `super_editor`'s component, but the hint clipped rather than ellipsized.
  /// It asks for an ellipsis with no line limit, and a paragraph ellipsized
  /// with no line limit ends at its first line that overflows: the hint was
  /// always one line, cut off with "…".
  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! HintComponentViewModel) return null;
    return TextWithHintComponent(
      key: componentContext.componentKey,
      text: componentViewModel.text,
      inlineWidgetBuilders: componentViewModel.inlineWidgetBuilders,
      textStyleBuilder: componentViewModel.textStyleBuilder,
      hintText: AttributedText(componentViewModel.hintText),
      hintOverflow: TextOverflow.clip,
      hintStyleBuilder: (_) => hintStyleBuilder(componentContext.context),
      textSelection: componentViewModel.selection,
      selectionColor: componentViewModel.selectionColor,
      underlines: componentViewModel.createUnderlines(),
      metadata: {
        if (componentViewModel.blockType != null)
          NodeMetadata.blockType: componentViewModel.blockType,
      },
    );
  }
}

class _ParagraphBuilder implements ComponentBuilder {
  const _ParagraphBuilder(this.style);

  final RichEditorDocumentStyle style;
  static const _inner = ParagraphComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! ParagraphNode) return null;
    return _inner.createViewModel(document, node);
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! ParagraphComponentViewModel) return null;
    final blockType = viewModel.blockType;
    // super_editor adds the block type to every span's attributions; for
    // code that would draw every character as inline code.
    final component = _inner.createComponent(
      componentContext,
      blockType == codeAttribution
          ? (viewModel.copy()..blockType = null)
          : viewModel,
    );
    if (component == null) return null;
    if (blockType == blockquoteAttribution) {
      return CustomPaint(
        painter: _QuoteBar(style.resolved),
        child: component,
      );
    }
    if (blockType == codeAttribution) {
      return _CodeBox(style: style, child: component);
    }
    final level = MarkdownDocumentCodec.headingLevelOf(
      _BlockTypeNode(blockType),
    );
    if (level != null) {
      return Semantics(header: true, headingLevel: level, child: component);
    }
    return component;
  }
}

/// A node stand-in to read a heading level from a block type.
class _BlockTypeNode extends ParagraphNode {
  _BlockTypeNode(Attribution? type)
    : super(
        id: '',
        text: AttributedText(),
        metadata: {NodeMetadata.blockType: type},
      );
}

class _QuoteBar extends CustomPainter {
  _QuoteBar(this.resolved);

  final ResolvedRichEditor resolved;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(
        -(resolved.quoteBarWidth + resolved.quoteSpacing),
        0,
        resolved.quoteBarWidth,
        size.height,
      ),
      Paint()..color = resolved.quoteBarColor,
    );
  }

  @override
  bool shouldRepaint(_QuoteBar oldDelegate) =>
      oldDelegate.resolved.quoteBarColor != resolved.quoteBarColor ||
      oldDelegate.resolved.quoteBarWidth != resolved.quoteBarWidth ||
      oldDelegate.resolved.quoteSpacing != resolved.quoteSpacing;
}

/// A block kept as literal Markdown (fenced code, tables, HTML …) as one
/// filled box. The box ignores pointers and its padding is outside the
/// component, so taps, caret and selection stay aligned with the text.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.style, required this.child});

  final RichEditorDocumentStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = style.resolved.codePadding;
    return Semantics(
      label: 'Markdown',
      child: Stacks(
        clipBehavior: .none,
        children: [
          Position(
            left: -p.left,
            right: -p.right,
            top: 0,
            bottom: -p.bottom,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: style.resolved.codeBackgroundColor,
                  borderRadius: BorderRadius.circular(p.top * 0.75),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: p.top),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Tasks with the CoUI `Checkbox` (super_editor's uses Material's).
/// Whether [node] is followed by another item of the same list — an item of
/// the same kind, or a task after a task.
bool _continuesList(Document doc, DocumentNode node) {
  final next = doc.getNodeAfterById(node.id);
  return switch ((node, next)) {
    (final ListItemNode item, final ListItemNode following) =>
      item.type == following.type,
    (TaskNode(), TaskNode()) => true,
    _ => false,
  };
}

/// The list items: `super_editor`'s own, with the text set in by the Core list
/// indent. Its builder does not hand the view model's indent calculator on to
/// the component, which then sets the text in by a share of the font size — so
/// the component is built here.
class _ListItemBuilder implements ComponentBuilder {
  const _ListItemBuilder(this.style);

  static const _inner = ListItemComponentBuilder();

  final RichEditorDocumentStyle style;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) => _inner.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    double indentOf(TextStyle textStyle, int indent) =>
        style.listItemIndent(indent);
    return switch (viewModel) {
      final UnorderedListItemComponentViewModel item =>
        UnorderedListItemComponent(
          componentKey: componentContext.componentKey,
          text: item.text,
          styleBuilder: item.textStyleBuilder,
          indent: item.indent,
          indentCalculator: indentOf,
          dotStyle: item.dotStyle,
          textSelection: item.selection,
          textDirection: item.textDirection,
          textAlignment: item.textAlignment,
          selectionColor: item.selectionColor,
          highlightWhenEmpty: item.highlightWhenEmpty,
          underlines: item.createUnderlines(),
          inlineWidgetBuilders: item.inlineWidgetBuilders,
        ),
      final OrderedListItemComponentViewModel item => OrderedListItemComponent(
        componentKey: componentContext.componentKey,
        indent: item.indent,
        indentCalculator: indentOf,
        listIndex: item.ordinalValue!,
        text: item.text,
        textDirection: item.textDirection,
        textAlignment: item.textAlignment,
        styleBuilder: item.textStyleBuilder,
        numeralStyle: item.numeralStyle,
        textSelection: item.selection,
        selectionColor: item.selectionColor,
        highlightWhenEmpty: item.highlightWhenEmpty,
        underlines: item.createUnderlines(),
        inlineWidgetBuilders: item.inlineWidgetBuilders,
      ),
      _ => null,
    };
  }
}

class _TaskBuilder implements ComponentBuilder {
  _TaskBuilder(Editor editor, this.style)
    : _inner = TaskComponentBuilder(editor);

  final TaskComponentBuilder _inner;
  final RichEditorDocumentStyle style;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) => _inner.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! TaskComponentViewModel) return null;
    return _TaskComponent(
      key: componentContext.componentKey,
      viewModel: viewModel,
      completedColor: style.resolved.completedTaskColor,
      indentOf: style.listItemIndent,
    );
  }
}

class _TaskComponent extends StatefulWidget {
  const _TaskComponent({
    required this.viewModel,
    required this.completedColor,
    required this.indentOf,
    super.key,
  });

  final TaskComponentViewModel viewModel;
  final Color completedColor;

  /// Where the text of a task at a nesting depth starts, in from the edge —
  /// the bullets' indent, so a checkbox stands where a dot would.
  final double Function(int indent) indentOf;

  @override
  State<_TaskComponent> createState() => _TaskComponentState();
}

class _TaskComponentState extends State<_TaskComponent>
    with ProxyDocumentComponent<_TaskComponent>, ProxyTextComposable {
  final GlobalKey<State<StatefulWidget>> _textKey = GlobalKey();

  /// The checkbox's seat — wide enough for the box and a gap, like a
  /// bullet's.
  static const double _seat = 24;

  @override
  GlobalKey<State<StatefulWidget>> get childDocumentComponentKey => _textKey;

  @override
  TextComposable get childTextComposable =>
      childDocumentComponentKey.currentState! as TextComposable;

  TextStyle _styles(Set<Attribution> attributions) {
    final style = widget.viewModel.textStyleBuilder(attributions);
    if (!widget.viewModel.isComplete) return style;
    return style.copyWith(
      color: widget.completedColor,
      decoration: style.decoration == null
          ? TextDecoration.lineThrough
          : TextDecoration.combine([
              TextDecoration.lineThrough,
              style.decoration!,
            ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.viewModel;
    final base = m.textStyleBuilder({});
    final lineHeight = (base.fontSize ?? 14) * (base.height ?? 1.45);
    final setComplete = m.setComplete;
    return Semantics(
      checked: m.isComplete,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The checkbox sits where a bullet's dot would (same indents).
          SizedBox(
            width: (widget.indentOf(m.indent) - _seat).clamp(
              0.0,
              double.infinity,
            ),
          ),
          SizedBox(
            width: _seat,
            height: lineHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Checkbox(
                checked: m.isComplete,
                enabled: setComplete != null,
                onChanged: setComplete == null
                    ? null
                    : (value) => setComplete(value ?? false),
              ),
            ),
          ),
          Expanded(
            child: TextComponent(
              key: _textKey,
              text: m.text,
              textDirection: m.textDirection,
              textAlign: m.textAlignment,
              textStyleBuilder: _styles,
              inlineWidgetBuilders: m.inlineWidgetBuilders,
              textSelection: m.selection,
              selectionColor: m.selectionColor,
              highlightWhenEmpty: m.highlightWhenEmpty,
              underlines: m.createUnderlines(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rules in the resolved rule colour.
class _RuleBuilder implements ComponentBuilder {
  const _RuleBuilder(this.style);

  final RichEditorDocumentStyle style;
  static const _inner = HorizontalRuleComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) => _inner.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! HorizontalRuleComponentViewModel) return null;
    return HorizontalRuleComponent(
      componentKey: componentContext.componentKey,
      color: style.resolved.ruleColor,
      selection:
          viewModel.selection?.nodeSelection
              as UpstreamDownstreamNodeSelection?,
      selectionColor: viewModel.selectionColor,
      showCaret: viewModel.caret != null,
      caretColor: viewModel.caretColor,
      opacity: viewModel.opacity,
    );
  }
}

/// An image block's view model: [ImageComponentViewModel] plus the alternative
/// text, which the stock one does not carry.
class _ImageViewModel extends ImageComponentViewModel {
  _ImageViewModel({
    required super.nodeId,
    required super.imageUrl,
    required this.altText,
    super.createdAt,
    super.maxWidth,
    super.padding,
    super.opacity,
    super.selection,
    super.selectionColor,
  });

  /// What the image shows, in words.
  final String altText;

  @override
  _ImageViewModel copy() => _ImageViewModel(
    nodeId: nodeId,
    createdAt: createdAt,
    maxWidth: maxWidth,
    padding: padding,
    opacity: opacity,
    imageUrl: imageUrl,
    altText: altText,
    selection: selection,
    selectionColor: selectionColor,
  );
}

/// Images in the editor's own chrome — corner, height cap, loading and
/// unavailable states — in place of super_editor's centred, uncapped one.
class _ImageBuilder implements ComponentBuilder {
  const _ImageBuilder(this.style);

  final RichEditorDocumentStyle style;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! ImageNode) return null;
    return _ImageViewModel(
      nodeId: node.id,
      createdAt: node.metadata[NodeMetadata.createdAt] as DateTime?,
      imageUrl: node.imageUrl,
      altText: node.altText,
    );
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! _ImageViewModel) return null;
    return _ImageComponent(
      componentKey: componentContext.componentKey,
      viewModel: viewModel,
      style: style,
    );
  }
}

/// `ImageComponent`'s structure — pointer-transparent, a selection overlay
/// around a `BoxComponent` — with the image aligned to the text's start
/// rather than centred.
class _ImageComponent extends StatelessWidget {
  const _ImageComponent({
    required this.componentKey,
    required this.viewModel,
    required this.style,
  });

  final GlobalKey componentKey;
  final _ImageViewModel viewModel;
  final RichEditorDocumentStyle style;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      hitTestBehavior: HitTestBehavior.translucent,
      child: IgnorePointer(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: SelectableBox(
            selection:
                viewModel.selection?.nodeSelection
                    as UpstreamDownstreamNodeSelection?,
            selectionColor: viewModel.selectionColor,
            child: BoxComponent(
              key: componentKey,
              opacity: viewModel.opacity,
              child: Semantics(
                image: true,
                label: viewModel.altText,
                child: _ImageView(
                  url: viewModel.imageUrl,
                  alt: viewModel.altText,
                  style: style,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The picture: its bytes from the address (a `data:` address is decoded
/// once), scaled down to the height cap with the resolved corner, on the
/// resolved fill while it loads, and an `Alert` in its place when it cannot
/// be shown.
class _ImageView extends StatefulWidget {
  const _ImageView({
    required this.url,
    required this.alt,
    required this.style,
  });

  final String url;
  final String alt;
  final RichEditorDocumentStyle style;

  @override
  State<_ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<_ImageView> {
  /// The bytes of a `data:` address, decoded once so the bitmap is not
  /// decoded again on every rebuild (a selection change rebuilds the block);
  /// null for any other address, or one that does not decode.
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _decode(widget.url);
  }

  @override
  void didUpdateWidget(_ImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _bytes = _decode(widget.url);
  }

  static Uint8List? _decode(String url) {
    if (!url.startsWith('data:')) return null;
    try {
      return UriData.parse(url).contentAsBytes();
    } on FormatException {
      return null;
    }
  }

  ResolvedRichEditor get _resolved => widget.style.resolved;

  /// The box standing in for a picture that is loading.
  Widget _placeholder() => SizedBox(
    width: _resolved.imageMaxHeight,
    height: _resolved.imageMaxHeight / 2,
  );

  /// The note in place of a picture that cannot be shown: the `Alert` the
  /// upload rows are, saying so and naming the image when it has a name.
  Widget _unavailable(BuildContext context) {
    final message = CoUILocalizations.of(context).richEditorImageUnavailable;
    return Alert(
      layout: CoreAlertLayout.inline,
      title: widget.alt.isEmpty ? message : '$message · ${widget.alt}',
      alertStyle: _resolved.uploadAlertStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget unavailable(BuildContext context, Object _, StackTrace? _) =>
        _unavailable(context);
    final bytes = _bytes;
    final Widget picture;
    if (widget.url.startsWith('data:')) {
      picture = bytes == null
          ? _unavailable(context)
          : Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: unavailable,
            );
    } else {
      picture = Image.network(
        widget.url,
        fit: BoxFit.contain,
        // A server that sends no CORS headers still shows its image on the
        // web, through an `<img>` element.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
        errorBuilder: unavailable,
      );
    }
    return ClipRRect(
      borderRadius: _resolved.imageBorderRadius,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: _resolved.imageMaxHeight),
        child: ColoredBox(
          color: _resolved.imageBackgroundColor,
          child: picture,
        ),
      ),
    );
  }
}
