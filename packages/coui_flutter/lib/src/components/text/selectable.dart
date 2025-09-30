import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart' show CupertinoTextMagnifier;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as m;
import 'package:coui_flutter/coui_flutter.dart';

/// {@template selectable_text_theme}
/// Theme data for [SelectableText] to customize cursor and selection behavior.
/// {@endtemplate}
class SelectableTextTheme {
  /// {@macro selectable_text_theme}
  const SelectableTextTheme({
    this.cursorColor,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorWidth,
    this.enableInteractiveSelection,
    this.selectionHeightStyle,
    this.selectionWidthStyle,
  });

  final double? cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final ui.BoxHeightStyle? selectionHeightStyle;
  final ui.BoxWidthStyle? selectionWidthStyle;

  final bool? enableInteractiveSelection;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SelectableTextTheme &&
        other.cursorWidth == cursorWidth &&
        other.cursorHeight == cursorHeight &&
        other.cursorRadius == cursorRadius &&
        other.cursorColor == cursorColor &&
        other.selectionHeightStyle == selectionHeightStyle &&
        other.selectionWidthStyle == selectionWidthStyle &&
        other.enableInteractiveSelection == enableInteractiveSelection;
  }

  @override
  String toString() {
    return 'SelectableTextTheme(cursorWidth: $cursorWidth, cursorHeight: $cursorHeight, cursorRadius: $cursorRadius, cursorColor: $cursorColor, selectionHeightStyle: $selectionHeightStyle, selectionWidthStyle: $selectionWidthStyle, enableInteractiveSelection: $enableInteractiveSelection)';
  }

  @override
  int get hashCode => Object.hash(
    cursorWidth,
    cursorHeight,
    cursorRadius,
    cursorColor,
    selectionHeightStyle,
    selectionWidthStyle,
    enableInteractiveSelection,
  );
}

class SelectableText extends StatelessWidget {
  const SelectableText(
    String this.data, {
    this.autofocus = false,
    this.contextMenuBuilder = _defaultContextMenuBuilder,
    this.cursorColor,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorWidth = 2.0,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.focusNode,
    super.key,
    this.magnifierConfiguration,
    this.maxLines,
    this.minLines,
    this.onSelectionChanged,
    this.onTap,
    this.scrollPhysics,
    this.selectionControls,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.semanticsLabel,
    this.showCursor = false,
    this.strutStyle,
    this.style,
    this.textAlign,
    this.textDirection,
    this.textHeightBehavior,
    this.textScaler,
    this.textWidthBasis,
    this.useNativeContextMenu = false,
  }) : assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(
         (maxLines == null) || (minLines == null) || (maxLines >= minLines),
         "minLines can't be greater than maxLines",
       ),
       textSpan = null;

  const SelectableText.rich(
    TextSpan this.textSpan, {
    this.autofocus = false,
    this.contextMenuBuilder = _defaultContextMenuBuilder,
    this.cursorColor,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorWidth = 2.0,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.focusNode,
    super.key,
    this.magnifierConfiguration,
    this.maxLines,
    this.minLines,
    this.onSelectionChanged,
    this.onTap,
    this.scrollPhysics,
    this.selectionControls,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.semanticsLabel,
    this.showCursor = false,
    this.strutStyle,
    this.style,
    this.textAlign,
    this.textDirection,
    this.textHeightBehavior,
    this.textScaler,
    this.textWidthBasis,
    this.useNativeContextMenu = false,
  }) : assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(
         (maxLines == null) || (minLines == null) || (maxLines >= minLines),
         "minLines can't be greater than maxLines",
       ),
       data = null;

  static Widget _defaultContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return buildEditableTextContextMenu(context, editableTextState);
  }

  final String? data;
  final TextSpan? textSpan;

  final FocusNode? focusNode;

  final bool useNativeContextMenu;

  final TextStyle? style;

  /// {@macro flutter.widgets.editableText.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.widgets.editableText.textAlign}
  final TextAlign? textAlign;

  /// {@macro flutter.widgets.editableText.textDirection}
  final TextDirection? textDirection;

  /// {@macro flutter.painting.textPainter.textScaler}
  final TextScaler? textScaler;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.editableText.minLines}
  final int? minLines;

  /// {@macro flutter.widgets.editableText.maxLines}
  final int? maxLines;

  /// {@macro flutter.widgets.editableText.showCursor}
  final bool showCursor;

  /// {@macro flutter.widgets.editableText.cursorWidth}
  final double cursorWidth;

  /// {@macro flutter.widgets.editableText.cursorHeight}
  final double? cursorHeight;

  /// {@macro flutter.widgets.editableText.cursorRadius}
  final Radius? cursorRadius;
  final Color? cursorColor;
  final ui.BoxHeightStyle selectionHeightStyle;

  final ui.BoxWidthStyle selectionWidthStyle;

  /// {@macro flutter.widgets.editableText.enableInteractiveSelection}
  final bool enableInteractiveSelection;

  /// {@macro flutter.widgets.editableText.selectionControls}
  final TextSelectionControls? selectionControls;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// Called when the user taps on this selectable text.
  ///
  /// The selectable text builds a [GestureDetector] to handle input events like tap,
  /// to trigger focus requests, to move the caret, adjust the selection, etc.
  /// Handling some of those events by wrapping the selectable text with a competing
  /// GestureDetector is problematic.
  ///
  /// To unconditionally handle taps, without interfering with the selectable text's
  /// internal gesture detector, provide this callback.
  ///
  /// To be notified when the text field gains or loses the focus, provide a
  /// [focusNode] and add a listener to that.
  ///
  /// To listen to arbitrary pointer events without competing with the
  /// selectable text's internal gesture detector, use a [Listener].
  final GestureTapCallback? onTap;

  /// {@macro flutter.widgets.editableText.scrollPhysics}
  final ScrollPhysics? scrollPhysics;

  /// {@macro flutter.widgets.Text.semanticsLabel}
  final String? semanticsLabel;

  /// {@macro dart.ui.textHeightBehavior}
  final TextHeightBehavior? textHeightBehavior;

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  final TextWidthBasis? textWidthBasis;

  /// {@macro flutter.widgets.editableText.onSelectionChanged}
  final SelectionChangedCallback? onSelectionChanged;

  /// {@macro flutter.widgets.EditableText.contextMenuBuilder}
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// The configuration for the magnifier used when the text is selected.
  ///
  /// By default, builds a [CupertinoTextMagnifier] on iOS and [m.TextMagnifier]
  /// on Android, and builds nothing on all other platforms. To suppress the
  /// magnifier, consider passing [TextMagnifierConfiguration.disabled].
  ///
  /// {@macro flutter.widgets.magnifier.intro}
  final TextMagnifierConfiguration? magnifierConfiguration;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<SelectableTextTheme>(context);
    final cursorWidth = compTheme?.cursorWidth ?? this.cursorWidth;
    final cursorHeight = compTheme?.cursorHeight ?? this.cursorHeight;
    final cursorRadius = compTheme?.cursorRadius ?? this.cursorRadius;
    final cursorColor = compTheme?.cursorColor ?? this.cursorColor;
    final selectionHeightStyle =
        compTheme?.selectionHeightStyle ?? this.selectionHeightStyle;
    final selectionWidthStyle =
        compTheme?.selectionWidthStyle ?? this.selectionWidthStyle;
    final enableSelection =
        compTheme?.enableInteractiveSelection ?? enableInteractiveSelection;

    return data == null
        ? m.SelectableText.rich(
            textSpan!,
            autofocus: autofocus,
            contextMenuBuilder: useNativeContextMenu
                ? (context, editableTextState) {
                    return m.AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: editableTextState,
                    );
                  }
                : contextMenuBuilder,
            cursorColor: cursorColor,
            cursorHeight: cursorHeight,
            cursorRadius: cursorRadius,
            cursorWidth: cursorWidth,
            enableInteractiveSelection: enableSelection,
            focusNode: focusNode,
            magnifierConfiguration: magnifierConfiguration,
            maxLines: maxLines,
            minLines: minLines,
            onSelectionChanged: onSelectionChanged,
            onTap: onTap,
            scrollPhysics: scrollPhysics,
            selectionControls: selectionControls,
            selectionHeightStyle: selectionHeightStyle,
            selectionWidthStyle: selectionWidthStyle,
            semanticsLabel: semanticsLabel,
            showCursor: showCursor,
            strutStyle: strutStyle,
            style: style,
            textAlign: textAlign,
            textDirection: textDirection,
            textHeightBehavior: textHeightBehavior,
            textWidthBasis: textWidthBasis,
          )
        : m.SelectableText(
            data!,
            autofocus: autofocus,
            contextMenuBuilder: useNativeContextMenu
                ? (context, editableTextState) {
                    return m.AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: editableTextState,
                    );
                  }
                : contextMenuBuilder,
            cursorColor: cursorColor,
            cursorHeight: cursorHeight,
            cursorRadius: cursorRadius,
            cursorWidth: cursorWidth,
            enableInteractiveSelection: enableSelection,
            focusNode: focusNode,
            magnifierConfiguration: magnifierConfiguration,
            maxLines: maxLines,
            minLines: minLines,
            onSelectionChanged: onSelectionChanged,
            onTap: onTap,
            scrollPhysics: scrollPhysics,
            selectionControls: selectionControls,
            selectionHeightStyle: selectionHeightStyle,
            selectionWidthStyle: selectionWidthStyle,
            semanticsLabel: semanticsLabel,
            showCursor: showCursor,
            strutStyle: strutStyle,
            style: style,
            textAlign: textAlign,
            textDirection: textDirection,
            textHeightBehavior: textHeightBehavior,
            textWidthBasis: textWidthBasis,
          );
  }
}
