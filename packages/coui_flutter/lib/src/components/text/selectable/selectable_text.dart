import 'package:coui_flutter/coui_flutter.dart';
import 'package:material_ui/material_ui.dart' as m;

/// Unified cross-platform selectable-text component.
///
/// Renders text the user can highlight and copy. Pass [text] for a
/// plain string, or [children] for rich-text composition (each child
/// is laid out inline through a `WidgetSpan`).
///
/// Cursor / text-style overrides flow through the single
/// [selectableTextStyle] slot. Cross-platform behavioural fields
/// (`maxLines`, `textAlign`, …) stay flat on the widget. `autofocus`,
/// `showCursor` and `minLines` are Flutter-framework-specific extras.
///
/// ```dart
/// SelectableText('This text is selectable')
/// SelectableText.rich(children: [Text('Selectable content')])
/// ```
class SelectableText extends StatelessWidget
    implements CoreSelectableTextContract<Widget> {
  /// Creates a [SelectableText] from a plain string.
  const SelectableText(
    String this.text, {
    super.key,
    this.onTap,
    this.selectableTextStyle,
    this.maxLines,
    this.textAlign,
    this.textDirection,
    this.enableInteractiveSelection = true,
    this.semanticsLabel,
    this.autofocus = false,
    this.showCursor = false,
    this.minLines,
  }) : children = null;

  /// Creates a [SelectableText] from rich-text [children].
  const SelectableText.rich({
    required List<Widget> this.children,
    super.key,
    this.onTap,
    this.selectableTextStyle,
    this.maxLines,
    this.textAlign,
    this.textDirection,
    this.enableInteractiveSelection = true,
    this.semanticsLabel,
    this.autofocus = false,
    this.showCursor = false,
    this.minLines,
  }) : text = null;

  @override
  final String? text;

  @override
  final List<Widget>? children;

  @override
  final CoreSelectableTextStyle? selectableTextStyle;

  @override
  final int? maxLines;

  @override
  final CoreTextAlign? textAlign;

  @override
  final CoreTextDirection? textDirection;

  @override
  final bool enableInteractiveSelection;

  @override
  final String? semanticsLabel;

  @override
  final void Function()? onTap;

  /// Whether the text should be focused on first build (Flutter only).
  final bool autofocus;

  /// Whether to show the text-selection caret (Flutter only).
  final bool showCursor;

  /// Minimum number of lines of vertical space to occupy (Flutter
  /// only).
  final int? minLines;

  /// Returns a copy of this [SelectableText] with the given fields
  /// replaced. All fields default to this instance's current value
  /// when omitted.
  SelectableText copyWith({
    Key? key,
    String? text,
    List<Widget>? children,
    CoreSelectableTextStyle? selectableTextStyle,
    int? maxLines,
    CoreTextAlign? textAlign,
    CoreTextDirection? textDirection,
    bool? enableInteractiveSelection,
    String? semanticsLabel,
    bool? autofocus,
    bool? showCursor,
    int? minLines,
    void Function()? onTap,
  }) {
    final resolvedChildren = children ?? this.children;
    if (resolvedChildren != null) {
      return SelectableText.rich(
        key: key ?? this.key,
        onTap: onTap ?? this.onTap,
        selectableTextStyle: selectableTextStyle ?? this.selectableTextStyle,
        maxLines: maxLines ?? this.maxLines,
        textAlign: textAlign ?? this.textAlign,
        textDirection: textDirection ?? this.textDirection,
        enableInteractiveSelection:
            enableInteractiveSelection ?? this.enableInteractiveSelection,
        semanticsLabel: semanticsLabel ?? this.semanticsLabel,
        autofocus: autofocus ?? this.autofocus,
        showCursor: showCursor ?? this.showCursor,
        minLines: minLines ?? this.minLines,
        children: resolvedChildren,
      );
    }
    return SelectableText(
      text ?? this.text ?? '',
      key: key ?? this.key,
      onTap: onTap ?? this.onTap,
      selectableTextStyle: selectableTextStyle ?? this.selectableTextStyle,
      maxLines: maxLines ?? this.maxLines,
      textAlign: textAlign ?? this.textAlign,
      textDirection: textDirection ?? this.textDirection,
      enableInteractiveSelection:
          enableInteractiveSelection ?? this.enableInteractiveSelection,
      semanticsLabel: semanticsLabel ?? this.semanticsLabel,
      autofocus: autofocus ?? this.autofocus,
      showCursor: showCursor ?? this.showCursor,
      minLines: minLines ?? this.minLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSelectableText(
      context,
      selectableTextStyle: selectableTextStyle,
    );

    final flutterTextAlign = coSelectableTextAlign(textAlign);
    final flutterTextDirection = coSelectableTextDirection(textDirection);

    final richChildren = children;
    if (richChildren != null) {
      // `DefaultSelectionStyle` ancestor supplies the CoUI selection tint
      // — `m.SelectableText` exposes no `selectionColor` ctor arg and would
      // otherwise inherit the Material theme's selection colour.
      return DefaultSelectionStyle(
        selectionColor: resolved.selectionColor,
        child: m.SelectableText.rich(
          TextSpan(
            children: [
              for (final child in richChildren) WidgetSpan(child: child),
            ],
          ),
          onTap: onTap,
          style: resolved.textStyle,
          textAlign: flutterTextAlign,
          textDirection: flutterTextDirection,
          showCursor: showCursor,
          autofocus: autofocus,
          minLines: minLines,
          maxLines: maxLines,
          cursorWidth: resolved.cursorWidth,
          cursorHeight: resolved.cursorHeight,
          cursorRadius: resolved.cursorRadius,
          cursorColor: resolved.cursorColor,
          enableInteractiveSelection: enableInteractiveSelection,
          semanticsLabel: semanticsLabel,
        ),
      );
    }

    return DefaultSelectionStyle(
      selectionColor: resolved.selectionColor,
      child: m.SelectableText(
        text ?? '',
        onTap: onTap,
        style: resolved.textStyle,
        textAlign: flutterTextAlign,
        textDirection: flutterTextDirection,
        showCursor: showCursor,
        autofocus: autofocus,
        minLines: minLines,
        maxLines: maxLines,
        cursorWidth: resolved.cursorWidth,
        cursorHeight: resolved.cursorHeight,
        cursorRadius: resolved.cursorRadius,
        cursorColor: resolved.cursorColor,
        enableInteractiveSelection: enableInteractiveSelection,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}

/// Chain sugar for merging a [CoreSelectableTextStyle] patch into
/// [SelectableText.selectableTextStyle] without hand-reconstructing
/// every field. Mirrors the Web `SelectableText.withStyle` extension
/// so both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSelectableTextStyle.merge` right-side-wins semantics).
extension SelectableTextStyleChain on SelectableText {
  /// Returns a copy of this [SelectableText] with [patch] merged into
  /// [selectableTextStyle] (patch fields win on conflict).
  SelectableText withStyle(CoreSelectableTextStyle patch) => copyWith(
    selectableTextStyle:
        (selectableTextStyle ?? const CoreSelectableTextStyle()).merge(patch),
  );
}
