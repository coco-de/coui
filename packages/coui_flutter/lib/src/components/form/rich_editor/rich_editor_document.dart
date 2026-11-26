// Adapted from Wonky Work's wonky_rich_editor (BSD-3-Clause, Copyright 2026
// The Wonky Work authors) — see NOTICE.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/rich_editor/markdown/markdown_document_codec.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_quill/flutter_quill.dart' as quill;

class RichEditorDocumentStyle {
  const RichEditorDocumentStyle({
    required this.resolved,
    required this.base,
    required this.placeholder,
    required this.padding,
    required this.onImagePressed,
  });

  final ResolvedRichEditor resolved;
  final TextStyle base;
  final TextStyle placeholder;
  final EdgeInsets padding;
  final ValueChanged<int>? onImagePressed;

  TextStyle _role(TextStyle style) =>
      base.merge(style.copyWith(color: base.color));

  quill.DefaultStyles get styles {
    const noHorizontal = quill.HorizontalSpacing(0, 0);
    const noVertical = quill.VerticalSpacing(0, 0);
    final spacing = quill.VerticalSpacing(0, resolved.blockSpacing);
    final code = _role(resolved.codeTextStyle);
    quill.DefaultTextBlockStyle textBlock(TextStyle style) =>
        quill.DefaultTextBlockStyle(
          style,
          noHorizontal,
          spacing,
          noVertical,
          null,
        );

    return quill.DefaultStyles(
      paragraph: textBlock(base),
      h1: textBlock(_role(resolved.heading1TextStyle)),
      h2: textBlock(_role(resolved.heading2TextStyle)),
      h3: textBlock(_role(resolved.heading3TextStyle)),
      h4: textBlock(_role(resolved.heading3TextStyle)),
      h5: textBlock(_role(resolved.heading3TextStyle)),
      h6: textBlock(_role(resolved.heading3TextStyle)),
      bold: const TextStyle(fontWeight: FontWeight.w600),
      italic: const TextStyle(fontStyle: FontStyle.italic),
      strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
      link: TextStyle(
        color: resolved.linkColor,
        decoration: TextDecoration.underline,
        decorationColor: resolved.linkColor,
      ),
      inlineCode: quill.InlineCodeStyle(
        style: resolved.codeTextStyle,
        backgroundColor: resolved.codeBackgroundColor,
      ),
      placeHolder: textBlock(placeholder),
      leading: textBlock(base),
      lists: quill.DefaultListBlockStyle(
        base,
        noHorizontal,
        spacing,
        noVertical,
        null,
        null,
        indentWidthBuilder: (block, _, _, _) {
          final attributes = block.style.attributes;
          if (attributes.containsKey(quill.Attribute.list.key)) {
            final depth =
                attributes[quill.Attribute.indent.key]?.value as int? ?? 0;
            return quill.HorizontalSpacing(
              resolved.listIndent * (depth + 1),
              0,
            );
          }
          if (attributes.containsKey(quill.Attribute.blockQuote.key)) {
            return quill.HorizontalSpacing(
              resolved.quoteBarWidth + resolved.quoteSpacing,
              0,
            );
          }
          if (attributes.containsKey(quill.Attribute.codeBlock.key)) {
            return quill.HorizontalSpacing(
              resolved.codePadding.left,
              resolved.codePadding.right,
            );
          }
          return noHorizontal;
        },
      ),
      quote: quill.DefaultTextBlockStyle(
        base.copyWith(color: resolved.quoteTextColor),
        noHorizontal,
        spacing,
        noVertical,
        BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: resolved.quoteBarColor,
              width: resolved.quoteBarWidth,
            ),
          ),
        ),
      ),
      code: quill.DefaultTextBlockStyle(
        code,
        noHorizontal,
        spacing,
        quill.VerticalSpacing(
          resolved.codePadding.top,
          resolved.codePadding.bottom,
        ),
        BoxDecoration(color: resolved.codeBackgroundColor),
      ),
    );
  }

  Widget? leading(quill.Node node, quill.LeadingConfig config) {
    if (node is! quill.Line ||
        config.attribute.key != quill.Attribute.list.key) {
      return null;
    }
    final indent = MarkdownDocumentCodec.indentOf(node);
    final width = resolved.listIndent * (indent + 1);
    final value = config.attribute.value;
    final Widget marker;
    if (value == 'checked' || value == 'unchecked') {
      marker = Checkbox(
        checked: config.value,
        onChanged: config.enabled == true
            ? (checked) => config.onCheckboxTap(checked == true)
            : null,
      );
    } else {
      marker = Text(
        value == 'ordered' ? '${config.getIndexNumberByIndent}.' : '•',
        style: config.style,
      );
    }
    return SizedBox(
      width: width,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: resolved.listIndent / 4),
          child: marker,
        ),
      ),
    );
  }

  static InlineSpan textSpan(
    BuildContext context,
    quill.Node node,
    int offset,
    String text,
    TextStyle? style,
    GestureRecognizer? recognizer,
  ) => _EditorTextSpan(
    node,
    offset,
    text: text,
    style: style,
    recognizer: recognizer,
  );

  /// Geometry from the rendered glyph boxes, excluding cursor/strut padding.
  static Rect? selectionBounds(
    quill.RenderEditor layout,
    TextSelection selection,
  ) {
    Rect? selected;

    void collect(RenderObject object) {
      if (object is! RenderParagraph || !object.hasSize) {
        object.visitChildren(collect);
        return;
      }
      int? firstOffset;
      var length = 0;
      object.text.visitChildren((span) {
        if (span is _EditorTextSpan) {
          firstOffset ??= span.node.documentOffset + span.offset - length;
        }
        length += switch (span) {
          TextSpan(:final text) => text?.length ?? 0,
          PlaceholderSpan() => 1,
          _ => 0,
        };
        return true;
      });
      final start = firstOffset;
      if (start == null) return;
      final left = math.max(0, selection.start - start);
      final right = math.min(length, selection.end - start);
      if (left >= right) return;
      for (final box in object.getBoxesForSelection(
        TextSelection(baseOffset: left, extentOffset: right),
      )) {
        final rect = Rect.fromPoints(
          object.localToGlobal(box.toRect().topLeft),
          object.localToGlobal(box.toRect().bottomRight),
        );
        selected = selected?.expandToInclude(rect) ?? rect;
      }
    }

    layout.visitChildren(collect);
    return selected;
  }

  List<quill.EmbedBuilder> get embeds => [_ImageEmbed(this), _RuleEmbed(this)];
}

class _EditorTextSpan extends TextSpan {
  const _EditorTextSpan(
    this.node,
    this.offset, {
    super.text,
    super.style,
    super.recognizer,
  });

  final quill.Node node;
  final int offset;
}

class _ImageEmbed extends quill.EmbedBuilder {
  const _ImageEmbed(this.style);

  final RichEditorDocumentStyle style;

  @override
  String get key => MarkdownDocumentCodec.imageType;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final image = MarkdownDocumentCodec.imageData(
      embedContext.node.value.toJson(),
    )!;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: MouseRegion(
        cursor: SystemMouseCursors.basic,
        child: Builder(
          builder: (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: style.onImagePressed == null
                ? null
                : (details) {
                    final trailing =
                        details.localPosition.dx >= context.size!.width / 2;
                    final rtl = Directionality.of(context) == TextDirection.rtl;
                    style.onImagePressed!(
                      embedContext.node.documentOffset +
                          (trailing != rtl ? 1 : 0),
                    );
                  },
            child: Semantics(
              image: true,
              label: image.alt,
              child: _ImageView(url: image.url, alt: image.alt, style: style),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleEmbed extends quill.EmbedBuilder {
  const _RuleEmbed(this.style);

  final RichEditorDocumentStyle style;

  @override
  String get key => MarkdownDocumentCodec.ruleType;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: style.resolved.blockSpacing / 2),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: style.resolved.ruleColor),
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
