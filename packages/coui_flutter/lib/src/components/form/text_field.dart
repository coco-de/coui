/// This file contains mostly patches from another package/SDK.
/// Due to changes that need to be made but cannot be done normally.
import 'dart:math';
import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/cupertino.dart'
    show
        CupertinoSpellCheckSuggestionsToolbar,
        cupertinoDesktopTextSelectionHandleControls;
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/foundation.dart'
    show IterableProperty, defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/hidden.dart';

/// Theme data for customizing [TextField] appearance.
///
/// This class defines the visual properties that can be applied to
/// [TextField] widgets, including border styling, fill state, padding,
/// and border radius. These properties can be set at the theme level
/// to provide consistent styling across the application.
class TextFieldTheme {
  const TextFieldTheme({
    this.border,
    this.borderRadius,
    this.filled,
    this.padding,
  });

  final BorderRadiusGeometry? borderRadius;
  final bool? filled;
  final EdgeInsetsGeometry? padding;

  final Border? border;

  TextFieldTheme copyWith({
    ValueGetter<Border?>? border,
    ValueGetter<BorderRadiusGeometry?>? borderRadius,
    ValueGetter<bool?>? filled,
    ValueGetter<EdgeInsetsGeometry?>? padding,
  }) {
    return TextFieldTheme(
      border: border == null ? this.border : border(),
      borderRadius: borderRadius == null ? this.borderRadius : borderRadius(),
      filled: filled == null ? this.filled : filled(),
      padding: padding == null ? this.padding : padding(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TextFieldTheme &&
        other.border == border &&
        other.borderRadius == borderRadius &&
        other.filled == filled &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(border, borderRadius, filled, padding);
}

const kTextFieldHeight = 34;

abstract class InputFeatureVisibility {
  const InputFeatureVisibility();
  const factory InputFeatureVisibility.and(
    Iterable<InputFeatureVisibility> features,
  ) = _LogicAndInputFeatureVisibility;
  const factory InputFeatureVisibility.or(
    Iterable<InputFeatureVisibility> features,
  ) = _LogicOrInputFeatureVisibility;
  const factory InputFeatureVisibility.not(InputFeatureVisibility feature) =
      _NegateInputFeatureVisibility;
  static const textNotEmpty = _TextNotEmptyInputFeatureVisibility();
  static const textEmpty = _TextEmptyInputFeatureVisibility();
  static const focused = _FocusedInputFeatureVisibility();
  static const hovered = _HoveredInputFeatureVisibility();
  static const never = _NeverVisibleInputFeatureVisibility();
  static const always = _AlwaysVisibleInputFeatureVisibility();
  static const hasSelection = _HasSelectionInputFeatureVisibility();

  Iterable<Listenable> getDependencies(TextFieldState state);

  bool canShow(TextFieldState state);

  InputFeatureVisibility and(InputFeatureVisibility other) =>
      InputFeatureVisibility.and([this, other]);

  InputFeatureVisibility operator &(InputFeatureVisibility other) => and(other);

  InputFeatureVisibility or(InputFeatureVisibility other) =>
      InputFeatureVisibility.or([this, other]);

  InputFeatureVisibility operator |(InputFeatureVisibility other) => or(other);

  InputFeatureVisibility operator ~() => InputFeatureVisibility.not(this);
}

class _LogicAndInputFeatureVisibility extends InputFeatureVisibility {
  const _LogicAndInputFeatureVisibility(this.features);
  final Iterable<InputFeatureVisibility> features;

  @override
  Iterable<Listenable> getDependencies(TextFieldState state) sync* {
    for (final feature in features) {
      yield* feature.getDependencies(state);
    }
  }

  @override
  bool canShow(TextFieldState state) {
    return features.every((feature) => feature.canShow(state));
  }

  @override
  bool operator ==(Object other) =>
      other is _LogicAndInputFeatureVisibility &&
      other.features.length == features.length &&
      other.features.every(features.contains);

  @override
  int get hashCode => features.hashCode;
}

class _LogicOrInputFeatureVisibility extends InputFeatureVisibility {
  const _LogicOrInputFeatureVisibility(this.features);
  final Iterable<InputFeatureVisibility> features;

  @override
  Iterable<Listenable> getDependencies(TextFieldState state) sync* {
    for (final feature in features) {
      yield* feature.getDependencies(state);
    }
  }

  @override
  bool canShow(TextFieldState state) {
    return features.any((feature) => feature.canShow(state));
  }

  @override
  bool operator ==(Object other) =>
      other is _LogicOrInputFeatureVisibility &&
      other.features.length == features.length &&
      other.features.every(features.contains);

  @override
  int get hashCode => features.hashCode;
}

class _NegateInputFeatureVisibility extends InputFeatureVisibility {
  const _NegateInputFeatureVisibility(this.feature);
  final InputFeatureVisibility feature;

  @override
  Iterable<Listenable> getDependencies(TextFieldState state) =>
      feature.getDependencies(state);

  @override
  bool canShow(TextFieldState state) => !feature.canShow(state);

  @override
  bool operator ==(Object other) =>
      other is _NegateInputFeatureVisibility && other.feature == feature;

  @override
  int get hashCode => feature.hashCode;
}

class _TextNotEmptyInputFeatureVisibility extends InputFeatureVisibility {
  const _TextNotEmptyInputFeatureVisibility();

  @override
  Iterable<Listenable> getDependencies(TextFieldState state) sync* {
    yield state._effectiveText;
  }

  @override
  bool canShow(TextFieldState state) {
    return state._effectiveText.value.isNotEmpty;
  }
}

class _TextEmptyInputFeatureVisibility extends InputFeatureVisibility {
  const _TextEmptyInputFeatureVisibility();

  @override
  Iterable<Listenable> getDependencies(TextFieldState state) sync* {
    yield state._effectiveText;
  }

  @override
  bool canShow(TextFieldState state) {
    return state._effectiveText.value.isEmpty;
  }
}

class _HasSelectionInputFeatureVisibility extends InputFeatureVisibility {
  const _HasSelectionInputFeatureVisibility();

  @override
  Iterable<Listenable> getDependencies(TextFieldState state) sync* {
    yield state._effectiveSelection;
  }

  @override
  bool canShow(TextFieldState state) {
    final selection = state._effectiveSelection.value;

    return selection.isValid && selection.start != selection.end;
  }
}

class _FocusedInputFeatureVisibility extends InputFeatureVisibility {
  const _FocusedInputFeatureVisibility();

  @override
  Iterable<Listenable> getDependencies(TextFieldState state) sync* {
    yield state._effectiveFocusNode;
  }

  @override
  bool canShow(TextFieldState state) {
    return state._effectiveFocusNode.hasFocus;
  }
}

class _HoveredInputFeatureVisibility extends InputFeatureVisibility {
  const _HoveredInputFeatureVisibility();

  @override
  Iterable<Listenable> getDependencies(TextFieldState state) sync* {
    yield state._statesController;
  }

  @override
  bool canShow(TextFieldState state) {
    return state._statesController.value.hovered;
  }
}

class _NeverVisibleInputFeatureVisibility extends InputFeatureVisibility {
  const _NeverVisibleInputFeatureVisibility();

  @override
  Iterable<Listenable> getDependencies(TextFieldState state) sync* {}

  @override
  bool canShow(TextFieldState state) => false;
}

class _AlwaysVisibleInputFeatureVisibility extends InputFeatureVisibility {
  const _AlwaysVisibleInputFeatureVisibility();

  @override
  Iterable<Listenable> getDependencies(TextFieldState state) sync* {}

  @override
  bool canShow(TextFieldState state) => true;
}

abstract class InputFeature {
  const InputFeature({this.visibility = InputFeatureVisibility.always});
  const factory InputFeature.hint({
    bool enableShortcuts,
    Widget? icon,
    required WidgetBuilder popupBuilder,
    InputFeaturePosition position,
    InputFeatureVisibility visibility,
  }) = InputHintFeature;
  const factory InputFeature.passwordToggle({
    Widget? icon,
    Widget? iconShow,
    PasswordPeekMode mode,
    InputFeaturePosition position,
    InputFeatureVisibility visibility,
  }) = InputPasswordToggleFeature;
  const factory InputFeature.clear({
    Widget? icon,
    InputFeaturePosition position,
    InputFeatureVisibility visibility,
  }) = InputClearFeature;
  const factory InputFeature.revalidate({
    Widget? icon,
    InputFeaturePosition position,
    InputFeatureVisibility visibility,
  }) = InputRevalidateFeature;
  const factory InputFeature.autoComplete({
    required Widget child,
    AutoCompleteMode mode,
    AlignmentDirectional? popoverAlignment,
    AlignmentDirectional? popoverAnchorAlignment,
    BoxConstraints? popoverConstraints,
    PopoverConstraint? popoverWidthConstraint,
    required SuggestionBuilder querySuggestions,
    InputFeatureVisibility visibility,
  }) = InputAutoCompleteFeature;
  const factory InputFeature.spinner({
    bool enableGesture,
    double? invalidValue,
    double step,
    InputFeatureVisibility visibility,
  }) = InputSpinnerFeature;
  const factory InputFeature.copy({
    Widget? icon,
    InputFeaturePosition position,
    InputFeatureVisibility visibility,
  }) = InputCopyFeature;
  const factory InputFeature.paste({
    Widget? icon,
    InputFeaturePosition position,
    InputFeatureVisibility visibility,
  }) = InputPasteFeature;
  const factory InputFeature.leading(
    Widget child, {
    InputFeatureVisibility visibility,
  }) = InputLeadingFeature;
  const factory InputFeature.trailing(
    Widget child, {
    InputFeatureVisibility visibility,
  }) = InputTrailingFeature;
  final InputFeatureVisibility visibility;

  InputFeatureState createState();

  static bool canUpdate(InputFeature newFeature, InputFeature oldFeature) {
    return oldFeature.runtimeType == newFeature.runtimeType;
  }
}

abstract class InputFeatureState<T extends InputFeature> {
  _AttachedInputFeature? _attached;

  /// Used to control whether the feature should be mounted or not.
  /// With AnimationController, we are able to determine when to
  /// not mount the widget.
  TextFieldState? _inputState;
  late AnimationController _visibilityController;

  T get feature {
    assert(
      _attached != null && _attached!.feature is T,
      'Feature not attached',
    );

    return _attached!.feature as T;
  }

  TickerProvider get tickerProvider {
    final inputState = _inputState;
    assert(inputState != null, 'Feature not attached');

    return inputState!;
  }

  BuildContext get context {
    final inputState = _inputState;
    assert(inputState != null, 'Feature not attached');
    final context = inputState!.editableTextKey.currentContext;
    if (context == null) {
      throw FlutterError(
        'InputFeatureState.context was accessed but editableTextKey.currentContext is null.\n'
        'This usually means the widget is not mounted. Ensure the widget is mounted before accessing context.',
      );
    }

    return context;
  }

  TextField get input {
    final inputState = _inputState;
    assert(inputState != null, 'Feature not attached');

    return inputState!.widget;
  }

  bool get attached => _attached != null;

  TextEditingController get controller {
    final inputState = _inputState;
    assert(inputState != null, 'Feature not attached');

    return inputState!.effectiveController;
  }

  void initState() {
    _visibilityController = AnimationController(
      duration: kDefaultDuration,
      vsync: tickerProvider,
    );
    _visibilityController.value = feature.visibility.canShow(_inputState!)
        ? 1
        : 0;
    _visibilityController.addListener(_updateAnimation);
    for (final dependency in feature.visibility.getDependencies(_inputState!)) {
      dependency.addListener(_updateVisibility);
    }
  }

  void didChangeDependencies() {}

  void dispose() {
    _visibilityController.dispose();
    for (final dependency in feature.visibility.getDependencies(_inputState!)) {
      dependency.removeListener(_updateVisibility);
    }
  }

  void didFeatureUpdate(InputFeature oldFeature) {
    if (oldFeature.visibility != feature.visibility) {
      for (final oldDependency in oldFeature.visibility.getDependencies(
        _inputState!,
      )) {
        oldDependency.removeListener(_updateVisibility);
      }
      for (final newDependency in feature.visibility.getDependencies(
        _inputState!,
      )) {
        newDependency.addListener(_updateVisibility);
      }
    }
  }

  void onTextChanged(String text) {}

  void onSelectionChanged(TextSelection selection) {}

  Iterable<Widget> buildLeading() sync* {}

  Iterable<Widget> buildTrailing() sync* {}

  Iterable<MapEntry<Type, Action<Intent>>> buildActions() sync* {}

  Iterable<MapEntry<ShortcutActivator, Intent>> buildShortcuts() sync* {}

  Widget wrap(Widget child) => child;

  TextField interceptInput(TextField input) => input;

  void setState(VoidCallback fn) {
    assert(attached, 'Feature not attached');
    _inputState!._setStateFeature(fn);
  }

  Iterable<Widget> _internalBuildLeading() sync* {
    if (_visibilityController.value == 0) {
      return;
    }
    for (final widget in buildLeading()) {
      yield Hidden(
        duration: kDefaultDuration,
        hidden: _visibilityController.value < 1,
        child: widget,
      );
    }
  }

  Iterable<Widget> _internalBuildTrailing() sync* {
    if (_visibilityController.value == 0) {
      return;
    }
    for (final widget in buildTrailing()) {
      yield Hidden(
        duration: kDefaultDuration,
        hidden: _visibilityController.value < 1,
        child: widget,
      );
    }
  }

  void _updateAnimation() {
    setState(() {});
  }

  void _updateVisibility() {
    final canShow = feature.visibility.canShow(_inputState!);
    if (canShow && _visibilityController.value == 1) return;
    if (!canShow && _visibilityController.value == 0) return;
    if (canShow) {
      _visibilityController.forward();
    } else {
      _visibilityController.reverse();
    }
  }
}

class _TextFieldSelectionGestureDetectorBuilder
    extends TextSelectionGestureDetectorBuilder {
  _TextFieldSelectionGestureDetectorBuilder({required TextFieldState state})
    : _state = state,
      super(delegate: state);

  final TextFieldState _state;

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    /// Because TextSelectionGestureDetector listens to taps that happen on
    /// widgets in front of it, tapping the clear button will also trigger
    /// this handler. If the clear button widget recognizes the up event,
    /// then do not handle it.
    if (_state._clearGlobalKey.currentContext != null) {
      final renderBox =
          _state._clearGlobalKey.currentContext!.findRenderObject()!
              as RenderBox;
      final localOffset = renderBox.globalToLocal(details.globalPosition);
      if (renderBox.hitTest(BoxHitTestResult(), position: localOffset)) {
        return;
      }
    }
    super.onSingleTapUp(details);
    _state.widget.onTap?.call();
  }

  @override
  void onDragSelectionEnd(TapDragEndDetails details) {
    _state._requestKeyboard();
    super.onDragSelectionEnd(details);
  }
}

/// Mixin widget used to avoid human error (e.g. missing properties) when
/// implementing a [TextField], [ChipInput], [TextArea], etc.
mixin TextInput on Widget {
  Object get groupId;
  TextEditingController? get controller;
  FocusNode? get focusNode;
  BoxDecoration? get decoration;
  EdgeInsetsGeometry? get padding;
  Widget? get placeholder;
  Widget? get leading;
  Widget? get trailing;
  CrossAxisAlignment get crossAxisAlignment;
  String? get clearButtonSemanticLabel;
  TextInputType get keyboardType;
  TextInputAction? get textInputAction;
  TextCapitalization get textCapitalization;
  TextStyle? get style;
  StrutStyle? get strutStyle;
  TextAlign get textAlign;
  TextAlignVertical? get textAlignVertical;
  TextDirection? get textDirection;
  bool get readOnly;
  bool? get showCursor;
  bool get autofocus;
  String get obscuringCharacter;
  bool get obscureText;
  bool get autocorrect;
  SmartDashesType get smartDashesType;
  SmartQuotesType get smartQuotesType;
  bool get enableSuggestions;
  int? get maxLines;
  int? get minLines;
  bool get expands;
  int? get maxLength;
  MaxLengthEnforcement? get maxLengthEnforcement;
  ValueChanged<String>? get onChanged;
  VoidCallback? get onEditingComplete;
  ValueChanged<String>? get onSubmitted;
  TapRegionCallback? get onTapOutside;
  TapRegionCallback? get onTapUpOutside;
  List<TextInputFormatter>? get inputFormatters;
  bool get enabled;
  double get cursorWidth;
  double? get cursorHeight;
  Radius get cursorRadius;
  bool get cursorOpacityAnimates;
  Color? get cursorColor;
  ui.BoxHeightStyle get selectionHeightStyle;
  ui.BoxWidthStyle get selectionWidthStyle;
  Brightness? get keyboardAppearance;
  EdgeInsets get scrollPadding;
  bool get enableInteractiveSelection;
  TextSelectionControls? get selectionControls;
  DragStartBehavior get dragStartBehavior;
  ScrollController? get scrollController;
  ScrollPhysics? get scrollPhysics;
  bool get selectionEnabled;
  GestureTapCallback? get onTap;
  Iterable<String>? get autofillHints;
  Clip get clipBehavior;
  String? get restorationId;
  bool get stylusHandwritingEnabled;
  bool get enableIMEPersonalizedLearning;
  ContentInsertionConfiguration? get contentInsertionConfiguration;
  EditableTextContextMenuBuilder? get contextMenuBuilder;
  String? get initialValue;
  String? get hintText;
  Border? get border;
  BorderRadiusGeometry? get borderRadius;
  bool? get filled;
  WidgetStatesController? get statesController;
  TextMagnifierConfiguration? get magnifierConfiguration;
  SpellCheckConfiguration? get spellCheckConfiguration;
  UndoHistoryController? get undoController;
  List<InputFeature> get features;
  List<TextInputFormatter>? get submitFormatters;
  bool get skipInputFeatureFocusTraversal;
}

/// A highly customizable single-line text input widget with extensive feature support.
///
/// [TextField] provides a comprehensive text editing experience with support for
/// a wide range of input types, validation, formatting, and interactive features.
/// It serves as the foundation for most text input scenarios in the coui_flutter
/// design system, offering both basic text input and advanced capabilities through
/// its feature system.
///
/// Key features:
/// - Comprehensive text input with platform-native behavior
/// - Extensive customization through [InputFeature] system
/// - Built-in support for validation and formatting
/// - Configurable appearance with theming support
/// - Context menu customization and clipboard operations
/// - Keyboard shortcuts and accessibility support
/// - Form integration with automatic value management
///
/// The widget supports various input modes:
/// - Single-line text input (default)
/// - Obscured text for passwords
/// - Formatted input with custom formatters
/// - Auto-completion and suggestions
/// - Numeric input with spinners
///
/// Input features can be added to enhance functionality:
/// - Clear button for easy text clearing
/// - Password visibility toggle
/// - Copy/paste operations
/// - Auto-complete suggestions
/// - Validation indicators
/// - Custom leading/trailing widgets
///
/// Example:
/// ```dart
/// TextField(
///   hintText: 'Enter your email',
///   keyboardType: TextInputType.emailAddress,
///   features: [
///     InputClearFeature(),
///     InputRevalidateFeature(),
///   ],
///   onChanged: (text) => _handleTextChange(text),
/// );
/// ```
class TextField extends StatefulWidget with TextInput {
  const TextField({
    this.autocorrect = true,
    this.autofillHints = const [],
    this.autofocus = false,
    this.border,
    this.borderRadius,
    this.clearButtonSemanticLabel,
    this.clipBehavior = Clip.hardEdge,
    this.contentInsertionConfiguration,
    this.contextMenuBuilder = _defaultContextMenuBuilder,
    this.controller,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.cursorColor,
    this.cursorHeight,
    this.cursorOpacityAnimates = true,
    this.cursorRadius = const Radius.circular(2),
    this.cursorWidth = 2.0,
    this.decoration,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableIMEPersonalizedLearning = true,
    bool? enableInteractiveSelection,
    this.enableSuggestions = true,
    this.enabled = true,
    this.expands = false,
    this.features = const [],
    this.filled,
    this.focusNode,
    this.groupId = EditableText,
    this.hintText,
    this.initialValue,
    this.inputFormatters,
    super.key,
    this.keyboardAppearance,
    TextInputType? keyboardType,
    @Deprecated('Use InputFeature.leading instead') this.leading,
    this.magnifierConfiguration,
    this.maxLength,
    this.maxLengthEnforcement,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTap,
    this.onTapOutside,
    this.onTapUpOutside,
    this.padding,
    this.placeholder,
    this.readOnly = false,
    this.restorationId,
    this.scrollController,
    this.scrollPadding = const EdgeInsets.all(20),
    this.scrollPhysics,
    this.selectionControls,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.showCursor,
    this.skipInputFeatureFocusTraversal = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    this.spellCheckConfiguration,
    this.statesController,
    this.strutStyle,
    this.style,
    this.stylusHandwritingEnabled =
        EditableText.defaultStylusHandwritingEnabled,
    this.submitFormatters = const [],
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textCapitalization = TextCapitalization.none,
    this.textDirection,
    this.textInputAction,
    @Deprecated('Use InputFeature.trailing instead') this.trailing,
    this.undoController,
  }) : assert(obscuringCharacter.length == 1),
       smartDashesType =
           smartDashesType ??
           (obscureText ? SmartDashesType.disabled : SmartDashesType.enabled),
       smartQuotesType =
           smartQuotesType ??
           (obscureText ? SmartQuotesType.disabled : SmartQuotesType.enabled),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(
         (maxLines == null) || (minLines == null) || (maxLines >= minLines),
         "minLines can't be greater than maxLines",
       ),
       assert(
         !expands || (maxLines == null && minLines == null),
         'minLines and maxLines must be null when expands is true.',
       ),
       assert(
         !obscureText || maxLines == 1,
         'Obscured fields cannot be multiline.',
       ),
       assert(maxLength == null || maxLength > 0),

       /// Assert the following instead of setting it directly to avoid
       /// surprising the user by silently changing the value they set.
       assert(
         !identical(textInputAction, TextInputAction.newline) ||
             maxLines == 1 ||
             !identical(keyboardType, TextInputType.text),
         'Use keyboardType TextInputType.multiline when using TextInputAction.newline on a multiline TextField.',
       ),
       keyboardType =
           keyboardType ??
           (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
       enableInteractiveSelection =
           enableInteractiveSelection ?? (!readOnly || !obscureText);

  static EditableTextContextMenuBuilder nativeContextMenuBuilder() {
    return (context, editableTextState) {
      return material.AdaptiveTextSelectionToolbar.editableText(
        editableTextState: editableTextState,
      );
    };
  }

  static EditableTextContextMenuBuilder cupertinoContextMenuBuilder() {
    return (context, editableTextState) {
      return cupertino.CupertinoAdaptiveTextSelectionToolbar.editableText(
        editableTextState: editableTextState,
      );
    };
  }

  static EditableTextContextMenuBuilder materialContextMenuBuilder() {
    return (context, editableTextState) {
      final anchors = editableTextState.contextMenuAnchors;

      return material.TextSelectionToolbar(
        anchorAbove: anchors.primaryAnchor,
        anchorBelow: anchors.secondaryAnchor == null
            ? anchors.primaryAnchor
            : anchors.secondaryAnchor!,
        children: _getMaterialButtons(
          context,
          editableTextState.contextMenuButtonItems,
        ),
      );
    };
  }

  static List<Widget> _getMaterialButtons(
    List<ContextMenuButtonItem> buttonItems,
    BuildContext context,
  ) {
    final buttons = <Widget>[];
    for (int i = 0; i < buttonItems.length; i += 1) {
      final buttonItem = buttonItems[i];
      buttons.add(
        material.TextSelectionToolbarTextButton(
          onPressed: buttonItem.onPressed,
          alignment: AlignmentDirectional.centerStart,
          padding: material.TextSelectionToolbarTextButton.getPadding(
            i,
            buttonItems.length,
          ),
          child: Text(_getMaterialButtonLabel(context, buttonItem)),
        ),
      );
    }

    return buttons;
  }

  static String _getMaterialButtonLabel(
    ContextMenuButtonItem buttonItem,
    BuildContext context,
  ) {
    final localizations = material.MaterialLocalizations.of(context);

    return switch (buttonItem.type) {
      ContextMenuButtonType.cut => localizations.cutButtonLabel,
      ContextMenuButtonType.copy => localizations.copyButtonLabel,
      ContextMenuButtonType.paste => localizations.pasteButtonLabel,
      ContextMenuButtonType.selectAll => localizations.selectAllButtonLabel,
      ContextMenuButtonType.delete =>
        localizations.deleteButtonTooltip.toUpperCase(),
      ContextMenuButtonType.lookUp => localizations.lookUpButtonLabel,
      ContextMenuButtonType.searchWeb => localizations.searchWebButtonLabel,
      ContextMenuButtonType.share => localizations.shareButtonLabel,
      ContextMenuButtonType.liveTextInput => localizations.scanTextButtonLabel,
      ContextMenuButtonType.custom => '',
    };
  }

  static Widget _defaultContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return buildEditableTextContextMenu(context, editableTextState);
  }

  @visibleForTesting
  static Widget defaultSpellCheckSuggestionsToolbarBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return CupertinoSpellCheckSuggestionsToolbar.editableText(
      editableTextState: editableTextState,
    );
  }

  @override
  final bool skipInputFeatureFocusTraversal;

  @override
  final List<InputFeature> features;

  @override
  final Object groupId;

  @override
  final TextEditingController? controller;

  @override
  final FocusNode? focusNode;

  @override
  final BoxDecoration? decoration;

  @override
  final EdgeInsetsGeometry? padding;

  @override
  final Widget? placeholder;

  @override
  final Widget? leading;

  @override
  final Widget? trailing;

  @override
  final CrossAxisAlignment crossAxisAlignment;

  @override
  final String? clearButtonSemanticLabel;

  @override
  final TextInputType keyboardType;

  @override
  final TextInputAction? textInputAction;

  @override
  final TextCapitalization textCapitalization;

  @override
  final TextStyle? style;

  @override
  final StrutStyle? strutStyle;

  @override
  final TextAlign textAlign;

  @override
  final TextAlignVertical? textAlignVertical;

  @override
  final TextDirection? textDirection;

  @override
  final bool readOnly;

  @override
  final bool? showCursor;

  @override
  final bool autofocus;

  @override
  final String obscuringCharacter;

  @override
  final bool obscureText;

  @override
  final bool autocorrect;

  @override
  final SmartDashesType smartDashesType;

  @override
  final SmartQuotesType smartQuotesType;

  @override
  final bool enableSuggestions;

  @override
  final int? maxLines;

  @override
  final int? minLines;

  @override
  final bool expands;

  @override
  final int? maxLength;

  @override
  final MaxLengthEnforcement? maxLengthEnforcement;

  @override
  final ValueChanged<String>? onChanged;

  @override
  final VoidCallback? onEditingComplete;

  @override
  final ValueChanged<String>? onSubmitted;

  @override
  final TapRegionCallback? onTapOutside;

  @override
  final TapRegionCallback? onTapUpOutside;

  @override
  final List<TextInputFormatter>? inputFormatters;

  @override
  final bool enabled;

  @override
  final double cursorWidth;

  @override
  final double? cursorHeight;

  @override
  final Radius cursorRadius;

  @override
  final bool cursorOpacityAnimates;

  @override
  final Color? cursorColor;

  @override
  final ui.BoxHeightStyle selectionHeightStyle;

  @override
  final ui.BoxWidthStyle selectionWidthStyle;

  @override
  final Brightness? keyboardAppearance;

  @override
  final EdgeInsets scrollPadding;

  @override
  final bool enableInteractiveSelection;

  @override
  final TextSelectionControls? selectionControls;

  @override
  final DragStartBehavior dragStartBehavior;

  @override
  final ScrollController? scrollController;

  @override
  final ScrollPhysics? scrollPhysics;

  @override
  final GestureTapCallback? onTap;

  @override
  final Iterable<String>? autofillHints;

  @override
  final Clip clipBehavior;

  @override
  final String? restorationId;

  @override
  final bool stylusHandwritingEnabled;

  @override
  final bool enableIMEPersonalizedLearning;

  @override
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  @override
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  @override
  final String? initialValue;

  @override
  final String? hintText; // used for autofill hints (use placeholder for decoration)

  @override
  final Border? border;

  @override
  final BorderRadiusGeometry? borderRadius;

  @override
  final bool? filled;

  @override
  final WidgetStatesController? statesController;

  @override
  final List<TextInputFormatter>? submitFormatters;

  @override
  final TextMagnifierConfiguration? magnifierConfiguration;

  @override
  final SpellCheckConfiguration? spellCheckConfiguration;

  @override
  final UndoHistoryController? undoController;

  @override
  bool get selectionEnabled => enableInteractiveSelection;

  @override
  State<TextField> createState() => TextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<TextEditingController>(
        'controller',
        controller,
      ),
    );
    properties.add(
      DiagnosticsProperty<FocusNode>(
        'focusNode',
        focusNode,
      ),
    );
    properties.add(
      DiagnosticsProperty<UndoHistoryController>(
        'undoController',
        undoController,
      ),
    );
    properties.add(
      DiagnosticsProperty<BoxDecoration>('decoration', decoration),
    );
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties.add(
      DiagnosticsProperty<String>(
        'clearButtonSemanticLabel',
        clearButtonSemanticLabel,
      ),
    );
    properties.add(
      DiagnosticsProperty<TextInputType>(
        'keyboardType',
        keyboardType,
        defaultValue: TextInputType.text,
      ),
    );
    properties.add(
      DiagnosticsProperty<TextStyle>(
        'style',
        style,
      ),
    );
    properties.add(
      DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false),
    );
    properties.add(
      DiagnosticsProperty<String>(
        'obscuringCharacter',
        obscuringCharacter,
        defaultValue: '•',
      ),
    );
    properties.add(
      DiagnosticsProperty<bool>(
        'obscureText',
        obscureText,
        defaultValue: false,
      ),
    );
    properties.add(
      DiagnosticsProperty<bool>(
        'autocorrect',
        autocorrect,
        defaultValue: true,
      ),
    );
    properties.add(
      EnumProperty<SmartDashesType>(
        'smartDashesType',
        smartDashesType,
        defaultValue: obscureText
            ? SmartDashesType.disabled
            : SmartDashesType.enabled,
      ),
    );
    properties.add(
      EnumProperty<SmartQuotesType>(
        'smartQuotesType',
        smartQuotesType,
        defaultValue: obscureText
            ? SmartQuotesType.disabled
            : SmartQuotesType.enabled,
      ),
    );
    properties.add(
      DiagnosticsProperty<bool>(
        'enableSuggestions',
        enableSuggestions,
        defaultValue: true,
      ),
    );
    properties.add(IntProperty('maxLines', maxLines, defaultValue: 1));
    properties.add(
      IntProperty(
        'minLines',
        minLines,
      ),
    );
    properties.add(
      DiagnosticsProperty<bool>('expands', expands, defaultValue: false),
    );
    properties.add(
      IntProperty(
        'maxLength',
        maxLength,
      ),
    );
    properties.add(
      EnumProperty<MaxLengthEnforcement>(
        'maxLengthEnforcement',
        maxLengthEnforcement,
      ),
    );
    properties.add(
      DoubleProperty('cursorWidth', cursorWidth, defaultValue: 2.0),
    );
    properties.add(
      DoubleProperty(
        'cursorHeight',
        cursorHeight,
      ),
    );
    properties.add(
      DiagnosticsProperty<Radius>(
        'cursorRadius',
        cursorRadius,
      ),
    );
    properties.add(
      DiagnosticsProperty<bool>(
        'cursorOpacityAnimates',
        cursorOpacityAnimates,
        defaultValue: true,
      ),
    );
    properties.add(ColorProperty('cursorColor', cursorColor));
    properties.add(
      FlagProperty(
        'selectionEnabled',
        defaultValue: true,
        ifFalse: 'selection disabled',
        value: selectionEnabled,
      ),
    );
    properties.add(
      DiagnosticsProperty<TextSelectionControls>(
        'selectionControls',
        selectionControls,
      ),
    );
    properties.add(
      DiagnosticsProperty<ScrollController>(
        'scrollController',
        scrollController,
      ),
    );
    properties.add(
      DiagnosticsProperty<ScrollPhysics>(
        'scrollPhysics',
        scrollPhysics,
      ),
    );
    properties.add(
      EnumProperty<TextAlign>(
        'textAlign',
        textAlign,
        defaultValue: TextAlign.start,
      ),
    );
    properties.add(
      DiagnosticsProperty<TextAlignVertical>(
        'textAlignVertical',
        textAlignVertical,
      ),
    );
    properties.add(
      EnumProperty<TextDirection>(
        'textDirection',
        textDirection,
      ),
    );
    properties.add(
      DiagnosticsProperty<Clip>(
        'clipBehavior',
        clipBehavior,
        defaultValue: Clip.hardEdge,
      ),
    );
    properties.add(
      DiagnosticsProperty<bool>(
        'stylusHandwritingEnabled',
        stylusHandwritingEnabled,
        defaultValue: EditableText.defaultStylusHandwritingEnabled,
      ),
    );
    properties.add(
      DiagnosticsProperty<bool>(
        'enableIMEPersonalizedLearning',
        enableIMEPersonalizedLearning,
        defaultValue: true,
      ),
    );
    properties.add(
      DiagnosticsProperty<SpellCheckConfiguration>(
        'spellCheckConfiguration',
        spellCheckConfiguration,
      ),
    );
    properties.add(
      DiagnosticsProperty<List<String>>(
        'contentCommitMimeTypes',
        contentInsertionConfiguration?.allowedMimeTypes ?? const <String>[],
        defaultValue: contentInsertionConfiguration == null
            ? const <String>[]
            : kDefaultContentInsertionMimeTypes,
      ),
    );
    properties.add(IterableProperty<InputFeature>('features', features));
  }

  TextField copyWith({
    ValueGetter<bool>? autocorrect,
    ValueGetter<Iterable<String>?>? autofillHints,
    ValueGetter<bool>? autofocus,
    ValueGetter<Border?>? border,
    ValueGetter<BorderRadiusGeometry?>? borderRadius,
    ValueGetter<String?>? clearButtonSemanticLabel,
    ValueGetter<Clip>? clipBehavior,
    ValueGetter<ContentInsertionConfiguration?>? contentInsertionConfiguration,
    ValueGetter<EditableTextContextMenuBuilder?>? contextMenuBuilder,
    ValueGetter<TextEditingController?>? controller,
    ValueGetter<CrossAxisAlignment>? crossAxisAlignment,
    ValueGetter<Color?>? cursorColor,
    ValueGetter<double?>? cursorHeight,
    ValueGetter<bool>? cursorOpacityAnimates,
    ValueGetter<Radius>? cursorRadius,
    ValueGetter<double>? cursorWidth,
    ValueGetter<BoxDecoration?>? decoration,
    ValueGetter<bool>? enableIMEPersonalizedLearning,
    ValueGetter<bool>? enableInteractiveSelection,
    ValueGetter<bool>? enableSuggestions,
    ValueGetter<bool>? enabled,
    ValueGetter<bool>? expands,
    ValueGetter<List<InputFeature>>? features,
    ValueGetter<bool?>? filled,
    ValueGetter<FocusNode?>? focusNode,
    ValueGetter<String?>? hintText,
    ValueGetter<String?>? initialValue,
    ValueGetter<List<TextInputFormatter>?>? inputFormatters,
    ValueGetter<Key?>? key,
    ValueGetter<Brightness?>? keyboardAppearance,
    ValueGetter<TextInputType?>? keyboardType,
    ValueGetter<Widget?>? leading,
    ValueGetter<TextMagnifierConfiguration?>? magnifierConfiguration,
    ValueGetter<int?>? maxLength,
    ValueGetter<MaxLengthEnforcement?>? maxLengthEnforcement,
    ValueGetter<int?>? maxLines,
    ValueGetter<int?>? minLines,
    ValueGetter<bool>? obscureText,
    ValueGetter<String>? obscuringCharacter,
    ValueGetter<ValueChanged<String>?>? onChanged,
    ValueGetter<VoidCallback?>? onEditingComplete,
    ValueGetter<ValueChanged<String>?>? onSubmitted,
    ValueGetter<GestureTapCallback?>? onTap,
    ValueGetter<TapRegionCallback?>? onTapOutside,
    ValueGetter<TapRegionCallback?>? onTapUpOutside,
    ValueGetter<EdgeInsetsGeometry?>? padding,
    ValueGetter<Widget?>? placeholder,
    ValueGetter<bool>? readOnly,
    ValueGetter<String?>? restorationId,
    ValueGetter<ScrollController?>? scrollController,
    ValueGetter<EdgeInsets>? scrollPadding,
    ValueGetter<ScrollPhysics?>? scrollPhysics,
    ValueGetter<TextSelectionControls?>? selectionControls,
    ValueGetter<ui.BoxHeightStyle>? selectionHeightStyle,
    ValueGetter<ui.BoxWidthStyle>? selectionWidthStyle,
    ValueGetter<bool?>? showCursor,
    ValueGetter<bool>? skipInputFeatureFocusTraversal,
    ValueGetter<SmartDashesType?>? smartDashesType,
    ValueGetter<SmartQuotesType?>? smartQuotesType,
    ValueGetter<SpellCheckConfiguration?>? spellCheckConfiguration,
    ValueGetter<WidgetStatesController?>? statesController,
    ValueGetter<StrutStyle?>? strutStyle,
    ValueGetter<TextStyle?>? style,
    ValueGetter<bool>? stylusHandwritingEnabled,
    ValueGetter<List<TextInputFormatter>?>? submitFormatters,
    ValueGetter<TextAlign>? textAlign,
    ValueGetter<TextAlignVertical?>? textAlignVertical,
    ValueGetter<TextCapitalization>? textCapitalization,
    ValueGetter<TextDirection?>? textDirection,
    ValueGetter<TextInputAction?>? textInputAction,
    ValueGetter<Widget?>? trailing,
    ValueGetter<UndoHistoryController?>? undoController,
  }) {
    return TextField(
      key: key == null ? this.key : key(),
      autocorrect: autocorrect == null ? this.autocorrect : autocorrect(),
      autofillHints: autofillHints == null
          ? this.autofillHints
          : autofillHints(),
      autofocus: autofocus == null ? this.autofocus : autofocus(),
      border: border == null ? this.border : border(),
      borderRadius: borderRadius == null ? this.borderRadius : borderRadius(),
      clearButtonSemanticLabel: clearButtonSemanticLabel == null
          ? this.clearButtonSemanticLabel
          : clearButtonSemanticLabel(),
      clipBehavior: clipBehavior == null ? this.clipBehavior : clipBehavior(),
      contentInsertionConfiguration: contentInsertionConfiguration == null
          ? this.contentInsertionConfiguration
          : contentInsertionConfiguration(),
      contextMenuBuilder: contextMenuBuilder == null
          ? this.contextMenuBuilder
          : contextMenuBuilder(),
      controller: controller == null ? this.controller : controller(),
      crossAxisAlignment: crossAxisAlignment == null
          ? this.crossAxisAlignment
          : crossAxisAlignment(),
      cursorColor: cursorColor == null ? this.cursorColor : cursorColor(),
      cursorHeight: cursorHeight == null ? this.cursorHeight : cursorHeight(),
      cursorOpacityAnimates: cursorOpacityAnimates == null
          ? this.cursorOpacityAnimates
          : cursorOpacityAnimates(),
      cursorRadius: cursorRadius == null ? this.cursorRadius : cursorRadius(),
      cursorWidth: cursorWidth == null ? this.cursorWidth : cursorWidth(),
      decoration: decoration == null ? this.decoration : decoration(),
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning == null
          ? this.enableIMEPersonalizedLearning
          : enableIMEPersonalizedLearning(),
      enableInteractiveSelection: enableInteractiveSelection == null
          ? this.enableInteractiveSelection
          : enableInteractiveSelection(),
      enableSuggestions: enableSuggestions == null
          ? this.enableSuggestions
          : enableSuggestions(),
      enabled: enabled == null ? this.enabled : enabled(),
      expands: expands == null ? this.expands : expands(),
      features: features == null ? this.features : features(),
      filled: filled == null ? this.filled : filled(),
      focusNode: focusNode == null ? this.focusNode : focusNode(),
      hintText: hintText == null ? this.hintText : hintText(),
      initialValue: initialValue == null ? this.initialValue : initialValue(),
      inputFormatters: inputFormatters == null
          ? this.inputFormatters
          : inputFormatters(),
      keyboardAppearance: keyboardAppearance == null
          ? this.keyboardAppearance
          : keyboardAppearance(),
      keyboardType: keyboardType == null ? this.keyboardType : keyboardType(),
      leading: leading == null ? this.leading : leading(),
      magnifierConfiguration: magnifierConfiguration == null
          ? this.magnifierConfiguration
          : magnifierConfiguration(),
      maxLength: maxLength == null ? this.maxLength : maxLength(),
      maxLengthEnforcement: maxLengthEnforcement == null
          ? this.maxLengthEnforcement
          : maxLengthEnforcement(),
      maxLines: maxLines == null ? this.maxLines : maxLines(),
      minLines: minLines == null ? this.minLines : minLines(),
      obscureText: obscureText == null ? this.obscureText : obscureText(),
      obscuringCharacter: obscuringCharacter == null
          ? this.obscuringCharacter
          : obscuringCharacter(),
      onChanged: onChanged == null ? this.onChanged : onChanged(),
      onEditingComplete: onEditingComplete == null
          ? this.onEditingComplete
          : onEditingComplete(),
      onSubmitted: onSubmitted == null ? this.onSubmitted : onSubmitted(),
      onTap: onTap == null ? this.onTap : onTap(),
      onTapOutside: onTapOutside == null ? this.onTapOutside : onTapOutside(),
      onTapUpOutside: onTapUpOutside == null
          ? this.onTapUpOutside
          : onTapUpOutside(),
      padding: padding == null ? this.padding : padding(),
      placeholder: placeholder == null ? this.placeholder : placeholder(),
      readOnly: readOnly == null ? this.readOnly : readOnly(),
      restorationId: restorationId == null
          ? this.restorationId
          : restorationId(),
      scrollController: scrollController == null
          ? this.scrollController
          : scrollController(),
      scrollPadding: scrollPadding == null
          ? this.scrollPadding
          : scrollPadding(),
      scrollPhysics: scrollPhysics == null
          ? this.scrollPhysics
          : scrollPhysics(),
      selectionControls: selectionControls == null
          ? this.selectionControls
          : selectionControls(),
      selectionHeightStyle: selectionHeightStyle == null
          ? this.selectionHeightStyle
          : selectionHeightStyle(),
      selectionWidthStyle: selectionWidthStyle == null
          ? this.selectionWidthStyle
          : selectionWidthStyle(),
      showCursor: showCursor == null ? this.showCursor : showCursor(),
      skipInputFeatureFocusTraversal: skipInputFeatureFocusTraversal == null
          ? this.skipInputFeatureFocusTraversal
          : skipInputFeatureFocusTraversal(),
      smartDashesType: smartDashesType == null
          ? this.smartDashesType
          : smartDashesType(),
      smartQuotesType: smartQuotesType == null
          ? this.smartQuotesType
          : smartQuotesType(),
      spellCheckConfiguration: spellCheckConfiguration == null
          ? this.spellCheckConfiguration
          : spellCheckConfiguration(),
      statesController: statesController == null
          ? this.statesController
          : statesController(),
      strutStyle: strutStyle == null ? this.strutStyle : strutStyle(),
      style: style == null ? this.style : style(),
      stylusHandwritingEnabled: stylusHandwritingEnabled == null
          ? this.stylusHandwritingEnabled
          : stylusHandwritingEnabled(),
      submitFormatters: submitFormatters == null
          ? this.submitFormatters
          : submitFormatters(),
      textAlign: textAlign == null ? this.textAlign : textAlign(),
      textAlignVertical: textAlignVertical == null
          ? this.textAlignVertical
          : textAlignVertical(),
      textCapitalization: textCapitalization == null
          ? this.textCapitalization
          : textCapitalization(),
      textDirection: textDirection == null
          ? this.textDirection
          : textDirection(),
      textInputAction: textInputAction == null
          ? this.textInputAction
          : textInputAction(),
      trailing: trailing == null ? this.trailing : trailing(),
      undoController: undoController == null
          ? this.undoController
          : undoController(),
    );
  }
}

class _AttachedInputFeature {
  _AttachedInputFeature(this.feature, this.state);
  InputFeature feature;
  final InputFeatureState state;
}

class TextFieldState extends State<TextField>
    with
        RestorationMixin,
        AutomaticKeepAliveClientMixin<TextField>,
        FormValueSupplier<String, TextField>,
        TickerProviderStateMixin
    implements TextSelectionGestureDetectorBuilderDelegate, AutofillClient {
  final _effectiveText = ValueNotifier<String>('');
  final _effectiveSelection = ValueNotifier<TextSelection>(
    const TextSelection.collapsed(offset: -1),
  );
  final _clearGlobalKey = GlobalKey();

  final _attachedFeatures = <_AttachedInputFeature>[];

  @override
  final editableTextKey = GlobalKey<EditableTextState>();

  WidgetStatesController _statesController;
  RestorableTextEditingController? _controller;

  TextEditingController get effectiveController =>
      widget.controller ?? _controller!.value;
  FocusNode? _focusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_focusNode ??= FocusNode());

  MaxLengthEnforcement get _effectiveMaxLengthEnforcement =>
      widget.maxLengthEnforcement ??
      LengthLimitingTextInputFormatter.getDefaultMaxLengthEnforcement();

  bool _showSelectionHandles = false;

  _TextFieldSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;

  /// End of API for TextSelectionGestureDetectorBuilderDelegate.

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder =
        _TextFieldSelectionGestureDetectorBuilder(state: this);
    if (widget.controller == null) {
      _createLocalController(
        widget.initialValue == null
            ? null
            : TextEditingValue(text: widget.initialValue!),
      );
    } else {
      widget.controller!.addListener(_handleControllerChanged);
    }
    _effectiveFocusNode.canRequestFocus = widget.enabled;
    _effectiveFocusNode.addListener(_handleFocusChanged);
    _statesController = widget.statesController ?? WidgetStatesController();
    final effectiveText = widget.controller?.text ?? widget.initialValue ?? '';
    formValue = effectiveText.isEmpty ? null : effectiveText;
    for (final feature in widget.features) {
      final state = feature.createState();
      state._attached = _AttachedInputFeature(feature, state);
      state._inputState = this;
      state.initState();
      _attachedFeatures.add(state._attached!);
    }
  }

  void _setStateFeature(VoidCallback fn) {
    setState(fn);
  }

  void _registerController() {
    assert(_controller != null);
    registerForRestoration(_controller!, 'controller');
    _controller!.value.addListener(updateKeepAlive);
    _controller!.value.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    _effectiveText.value = effectiveController.text;
    _effectiveSelection.value = effectiveController.selection;
    formValue = effectiveController.text.isEmpty
        ? null
        : effectiveController.text;
  }

  void _createLocalController([TextEditingValue? value]) {
    assert(_controller == null);
    _controller = value == null
        ? RestorableTextEditingController()
        : RestorableTextEditingController.fromValue(value);
    if (value != null) {
      _effectiveText.value = value.text;
      _effectiveSelection.value = value.selection;
    }
    if (!restorePending) {
      _registerController();
    }
  }

  void _requestKeyboard() {
    _editableText.requestKeyboard();
  }

  void _handleFocusChanged() {
    setState(() {
      /// Rebuild the widget on focus change to show/hide the text selection
      /// highlight.
    });
    _statesController.update(WidgetState.focused, _effectiveFocusNode.hasFocus);
    if (!_effectiveFocusNode.hasFocus) {
      _formatSubmit();
    }
  }

  void _formatSubmit() {
    if (widget.submitFormatters != null) {
      TextEditingValue value = effectiveController.value;
      for (final formatter in widget.submitFormatters!) {
        value = formatter.formatEditUpdate(value, value);
      }
      if (value != effectiveController.value) {
        effectiveController.value = value;
        widget.onChanged?.call(value.text);
      }
    }
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    /// When the text field is activated by something that doesn't trigger the
    /// selection overlay, we shouldn't show the handles either.
    if (!_selectionGestureDetectorBuilder.shouldShowSelectionToolbar) {
      return false;
    }

    /// On iOS, we don't show handles when the selection is collapsed.
    if (effectiveController.selection.isCollapsed) {
      return false;
    }

    if (cause == SelectionChangedCause.keyboard) {
      return false;
    }

    if (cause == SelectionChangedCause.stylusHandwriting) {
      return true;
    }

    return effectiveController.text.isNotEmpty
        ? true
        : effectiveController.text.isNotEmpty && true;
  }

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    _effectiveSelection.value = selection;
    final willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
      case TargetPlatform.android:
        if (cause == SelectionChangedCause.longPress) {
          _editableText.bringIntoView(selection.extent);
        }
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.android:
        break;

      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        if (cause == SelectionChangedCause.drag) {
          _editableText.hideToolbar();
        }
    }

    for (final attached in _attachedFeatures) {
      attached.state.onSelectionChanged(selection);
    }
  }

  Widget _addTextDependentAttachments(
    Widget editableText,
    TextStyle textStyle,
    ThemeData theme,
  ) {
    final widget = this.widget;

    /// Otherwise, listen to the current state of the text entry.
    return !_hasDecoration
        ? editableText
        : ValueListenableBuilder<TextEditingValue>(
            builder: (BuildContext context, TextEditingValue text, Widget? child) {
              final hasText = text.text.isNotEmpty;
              final placeholder = widget.placeholder == null
                  ? null
                  /// Make the placeholder invisible when hasText is true.
                  : Visibility(
                      maintainAnimation: true,
                      maintainSize: true,
                      maintainState: true,
                      visible: !hasText,
                      child: SizedBox(
                        width: double.infinity,
                        child: DefaultTextStyle(
                          maxLines: widget.maxLines,
                          style: textStyle
                              .merge(theme.typography.small)
                              .merge(theme.typography.normal)
                              .copyWith(
                                color: theme.colorScheme.mutedForeground,
                              ),
                          textAlign: widget.textAlign,
                          child: widget.placeholder!,
                        ),
                      ),
                    );

              final leadingChildren = <Widget>[];
              final trailingChildren = <Widget>[];
              for (final attached in _attachedFeatures) {
                leadingChildren.addAll(
                  attached.state._internalBuildLeading().map(
                    (e) => Focus(
                      skipTraversal: widget.skipInputFeatureFocusTraversal,
                      child: e,
                    ),
                  ),
                );
              }
              for (final attached in _attachedFeatures) {
                trailingChildren.addAll(
                  attached.state._internalBuildTrailing().map(
                    (e) => Focus(
                      skipTraversal: widget.skipInputFeatureFocusTraversal,
                      child: e,
                    ),
                  ),
                );
              }

              final Widget? leadingWidget = leadingChildren.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.scaling * 4,
                      children: leadingChildren,
                    )
                  : null;
              final Widget? trailingWidget = trailingChildren.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.scaling * 4,
                      children: trailingChildren,
                    )
                  : null;
              return Row(
                crossAxisAlignment: widget.crossAxisAlignment,
                spacing: theme.scaling * 8.0,
                children: [
                  /// Insert a prefix at the front if the prefix visibility mode matches
                  /// the current text state.
                  if (leadingWidget != null) leadingWidget,

                  /// In the middle part, stack the placeholder on top of the main EditableText
                  /// if needed.
                  Expanded(
                    child: Stack(
                      /// Ideally this should be baseline aligned. However that comes at
                      /// the cost of the ability to compute the intrinsic dimensions of
                      /// this widget.
                      /// See also https://github.com/flutter/flutter/issues/13715.
                      alignment: AlignmentDirectional.center,
                      textDirection: widget.textDirection,
                      children: [
                        if (placeholder != null) placeholder,
                        editableText,
                      ],
                    ),
                  ),
                  if (trailingWidget != null) trailingWidget,
                ],
              );
            },
            valueListenable: effectiveController,
            child: editableText,
          );
  }

  // AutofillClient implementation end.

  void _onChanged(String value) {
    final widget = this.widget;
    if (widget.onChanged != null) {
      widget.onChanged!(value);
    }
    formValue = value.isEmpty ? null : value;
    _effectiveText.value = value;

    for (final attached in _attachedFeatures) {
      attached.state.onTextChanged(value);
    }
  }

  void _onEnter(PointerEnterEvent event) {
    _statesController.update(WidgetState.hovered, true);
  }

  void _onExit(PointerExitEvent event) {
    _statesController.update(WidgetState.hovered, false);
  }

  Widget _wrapActions({required Widget child}) {
    final featureActions = <Type, Action<Intent>>{};
    final featureShortcuts = <ShortcutActivator, Intent>{};
    for (final attached in _attachedFeatures) {
      for (final action in attached.state.buildActions()) {
        featureActions[action.key] = action.value;
      }
      for (final shortcut in attached.state.buildShortcuts()) {
        featureShortcuts[shortcut.key] = shortcut.value;
      }
    }

    return Actions(
      actions: {
        TextFieldClearIntent: CallbackAction(
          onInvoke: (_) {
            effectiveController.clear();

            return null;
          },
        ),
        TextFieldAppendTextIntent: CallbackAction<TextFieldAppendTextIntent>(
          onInvoke: (intent) {
            final newText = effectiveController.text + intent.text;
            effectiveController.value = TextEditingValue(
              selection: TextSelection.collapsed(offset: newText.length),
              text: newText,
            );

            return null;
          },
        ),
        TextFieldReplaceCurrentWordIntent:
            CallbackAction<TextFieldReplaceCurrentWordIntent>(
              onInvoke: (intent) {
                final replacement = intent.text;
                final value = effectiveController.value;
                final text = value.text;
                final selection = value.selection;
                if (selection.isCollapsed) {
                  final start = selection.start;
                  final newText = replaceWordAtCaret(text, start, replacement);
                  effectiveController.value = TextEditingValue(
                    selection: TextSelection.collapsed(
                      offset: newText.$1 + replacement.length,
                    ),
                    text: newText.$2,
                  );
                }

                return null;
              },
            ),
        TextFieldSetTextIntent: CallbackAction<TextFieldSetTextIntent>(
          onInvoke: (intent) {
            effectiveController.value = TextEditingValue(
              selection: TextSelection.collapsed(offset: intent.text.length),
              text: intent.text,
            );

            return null;
          },
        ),
        TextFieldSetSelectionIntent:
            CallbackAction<TextFieldSetSelectionIntent>(
              onInvoke: (intent) {
                effectiveController.selection = intent.selection;

                return null;
              },
            ),
        TextFieldSelectAllAndCopyIntent:
            CallbackAction<TextFieldSelectAllAndCopyIntent>(
              onInvoke: (intent) {
                effectiveController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: effectiveController.text.length,
                );
                final text = effectiveController.text;
                if (text.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: text));
                }

                return null;
              },
            ),
        ...featureActions,
      },
      child: Shortcuts(shortcuts: featureShortcuts, child: child),
    );
  }

  // API for TextSelectionGestureDetectorBuilderDelegate.
  @override
  bool get forcePressEnabled => true;

  @override
  bool get selectionEnabled => widget.selectionEnabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final attached in _attachedFeatures) {
      attached.state.didChangeDependencies();
    }
  }

  @override
  void didUpdateWidget(TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null) {
      _createLocalController(oldWidget.controller!.value);
    } else if (widget.controller != null && oldWidget.controller == null) {
      unregisterFromRestoration(_controller!);
      _controller!.dispose();
      _controller = null;
    }

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);
      if (widget.controller != null) {
        _handleControllerChanged();
      }
    }

    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _focusNode)?.removeListener(_handleFocusChanged);
      (widget.focusNode ?? _focusNode)?.addListener(_handleFocusChanged);
    }
    _effectiveFocusNode.canRequestFocus = widget.enabled;

    for (
      int i = 0;
      i < max(oldWidget.features.length, widget.features.length);
      i += 1
    ) {
      if (i >= oldWidget.features.length) {
        final newFeature = widget.features[i];
        final newState = newFeature.createState();
        newState._attached = _AttachedInputFeature(newFeature, newState);
        newState._inputState = this;
        newState.initState();
        newState.didChangeDependencies();
        _attachedFeatures.add(newState._attached!);
        continue;
      }
      if (i >= widget.features.length) {
        final oldState = _attachedFeatures[i].state;
        oldState.dispose();
        _attachedFeatures.removeAt(i);
        continue;
      }
      final oldFeature = oldWidget.features[i];
      final newFeature = widget.features[i];
      final oldState = _attachedFeatures[i].state;
      if (InputFeature.canUpdate(oldFeature, newFeature)) {
        oldState._attached!.feature = newFeature;
        oldState.didFeatureUpdate(oldFeature);
      } else {
        oldState.dispose();
        final newState = newFeature.createState();
        newState._attached = _AttachedInputFeature(newFeature, newState);
        newState._inputState = this;
        newState.initState();
        newState.didChangeDependencies();
        _attachedFeatures[i] = newState._attached!;
      }
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (_controller != null) {
      _registerController();
    }
  }

  @override
  void dispose() {
    for (final attached in _attachedFeatures) {
      attached.state.dispose();
    }
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _focusNode?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void autofill(TextEditingValue newEditingValue) =>
      _editableText.autofill(newEditingValue);

  @override
  void didReplaceFormValue(String value) {
    effectiveController.text = value;
    widget.onChanged?.call(value);
  }

  @override
  String? get restorationId => widget.restorationId;

  EditableTextState get _editableText => editableTextKey.currentState!;

  @override
  bool get wantKeepAlive => _controller?.value.text.isNotEmpty ?? false;

  // True if any surrounding decoration widgets will be shown.
  bool get _hasDecoration {
    return widget.placeholder != null ||
        widget.leading != null ||
        widget.trailing != null ||
        widget.features.isNotEmpty;
  }

  // Provide default behavior if widget.textAlignVertical is not set.
  // CupertinoTextField has top alignment by default, unless it has decoration
  // like a prefix or suffix, in which case it's aligned to the center.
  TextAlignVertical get _textAlignVertical {
    if (widget.textAlignVertical != null) {
      return widget.textAlignVertical!;
    }

    return _hasDecoration ? TextAlignVertical.center : TextAlignVertical.top;
  }

  @override
  TextField get widget {
    TextField widget = super.widget;
    for (final attached in _attachedFeatures) {
      widget = attached.state.interceptInput(widget);
    }

    return widget;
  }

  // AutofillClient implementation start.
  @override
  String get autofillId => _editableText.autofillId;

  @override
  TextInputConfiguration get textInputConfiguration {
    final widget = this.widget;
    final autofillHints = widget.autofillHints?.toList(growable: false);
    final autofillConfiguration = autofillHints == null
        ? AutofillConfiguration.disabled
        : AutofillConfiguration(
            autofillHints: autofillHints,
            currentEditingValue: effectiveController.value,
            hintText: widget.hintText,
            uniqueIdentifier: autofillId,
          );

    return _editableText.textInputConfiguration.copyWith(
      autofillConfiguration: autofillConfiguration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    super.build(context); // See AutomaticKeepAliveClientMixin.
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<TextFieldTheme>(context);
    assert(debugCheckHasDirectionality(context));
    final controller = effectiveController;

    TextSelectionControls? textSelectionControls = widget.selectionControls;
    VoidCallback? handleDidGainAccessibilityFocus;
    VoidCallback? handleDidLoseAccessibilityFocus;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        textSelectionControls ??= cupertinoDesktopTextSelectionHandleControls;
        handleDidGainAccessibilityFocus = () {
          // Automatically activate the TextField when it receives accessibility focus.
          if (!_effectiveFocusNode.hasFocus &&
              _effectiveFocusNode.canRequestFocus) {
            _effectiveFocusNode.requestFocus();
          }
        };
        handleDidLoseAccessibilityFocus = () {
          _effectiveFocusNode.unfocus();
        };
    }

    final enabled = widget.enabled;
    final formatters = <TextInputFormatter>[
      ...?widget.inputFormatters,
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(
          widget.maxLength,
          maxLengthEnforcement: _effectiveMaxLengthEnforcement,
        ),
    ];

    TextStyle defaultTextStyle;
    defaultTextStyle = widget.style == null
        ? DefaultTextStyle.of(context).style
              .merge(theme.typography.small)
              .merge(theme.typography.normal)
              .copyWith(color: theme.colorScheme.foreground)
              .merge(widget.style)
        : DefaultTextStyle.of(context).style
              .merge(theme.typography.small)
              .merge(theme.typography.normal)
              .copyWith(color: theme.colorScheme.foreground);
    final keyboardAppearance = widget.keyboardAppearance ?? theme.brightness;
    final cursorColor =
        widget.cursorColor ??
        DefaultSelectionStyle.of(context).cursorColor ??
        theme.colorScheme.primary;

    // Use the default disabled color only if the box decoration was not set.
    final effectiveBorder = styleValue(
      defaultValue: Border.all(color: theme.colorScheme.border),
      themeValue: compTheme?.border,
      widgetValue: widget.border,
    );
    final effectiveDecoration =
        widget.decoration ??
        BoxDecoration(
          border: effectiveBorder,
          borderRadius:
              optionallyResolveBorderRadius(
                context,
                widget.borderRadius ?? compTheme?.borderRadius,
              ) ??
              BorderRadius.circular(theme.radiusMd),
          color: (widget.filled ?? compTheme?.filled ?? false)
              ? theme.colorScheme.muted
              : theme.colorScheme.input.scaleAlpha(0.3),
        );

    final selectionColor =
        DefaultSelectionStyle.of(context).selectionColor ??
        theme.colorScheme.primary.withValues(alpha: 0.2);

    // Set configuration as disabled if not otherwise specified. If specified,
    // ensure that configuration uses Cupertino text style for misspelled words
    // unless a custom style is specified.
    final spellCheckConfiguration =
        widget.spellCheckConfiguration ??
        const SpellCheckConfiguration.disabled();

    final scaling = theme.scaling;
    final editable = RepaintBoundary(
      child: UnmanagedRestorationScope(
        bucket: bucket,
        child: EditableText(
          key: editableTextKey,
          autocorrect: widget.autocorrect,
          autocorrectionTextRectColor: selectionColor,
          autofillClient: this,
          autofillHints: widget.autofillHints,
          autofocus: widget.autofocus,
          backgroundCursorColor: theme.colorScheme.border,
          clipBehavior: widget.clipBehavior,
          contentInsertionConfiguration: widget.contentInsertionConfiguration,
          contextMenuBuilder: widget.contextMenuBuilder,
          controller: controller,
          cursorColor: cursorColor,
          cursorHeight: widget.cursorHeight,
          cursorOpacityAnimates: widget.cursorOpacityAnimates,
          cursorRadius: widget.cursorRadius,
          cursorWidth: widget.cursorWidth,
          dragStartBehavior: widget.dragStartBehavior,
          enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          enableSuggestions: widget.enableSuggestions,
          expands: widget.expands,
          focusNode: _effectiveFocusNode,
          groupId: widget.groupId,
          inputFormatters: formatters,
          keyboardAppearance: keyboardAppearance,
          keyboardType: widget.keyboardType,
          magnifierConfiguration:
              widget.magnifierConfiguration ??
              const TextMagnifierConfiguration(),
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          obscureText: widget.obscureText,
          obscuringCharacter: widget.obscuringCharacter,
          onChanged: _onChanged,
          onEditingComplete: () {
            widget.onEditingComplete?.call();
            _formatSubmit();
          },
          onSelectionChanged: _handleSelectionChanged,
          onSubmitted: (value) {
            widget.onSubmitted?.call(value);
            _formatSubmit();
          },
          onTapOutside: widget.onTapOutside,
          paintCursorAboveText: true,
          readOnly: widget.readOnly || !enabled,
          rendererIgnoresPointer: true,
          restorationId: 'editable',
          scrollController: widget.scrollController,
          scrollPadding: widget.scrollPadding,
          scrollPhysics: widget.scrollPhysics,
          // Only show the selection highlight when the text field is focused.
          selectionColor: _effectiveFocusNode.hasFocus ? selectionColor : null,
          selectionControls: widget.selectionEnabled
              ? textSelectionControls
              : null,
          selectionHeightStyle: widget.selectionHeightStyle,
          selectionWidthStyle: widget.selectionWidthStyle,
          showCursor: widget.showCursor,
          showSelectionHandles: _showSelectionHandles,
          smartDashesType: widget.smartDashesType,
          smartQuotesType: widget.smartQuotesType,
          spellCheckConfiguration: spellCheckConfiguration,
          strutStyle: widget.strutStyle,
          style: defaultTextStyle,
          stylusHandwritingEnabled: widget.stylusHandwritingEnabled,
          textAlign: widget.textAlign,
          textCapitalization: widget.textCapitalization,
          textDirection: widget.textDirection,
          textInputAction: widget.textInputAction,
          undoController: widget.undoController,
        ),
      ),
    );

    Widget textField = MouseRegion(
      cursor: enabled ? SystemMouseCursors.text : SystemMouseCursors.forbidden,
      child: FocusOutline(
        borderRadius: effectiveDecoration.borderRadius,
        focused: _effectiveFocusNode.hasFocus,
        child: IconTheme.merge(
          data: theme.iconTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
          child: _wrapActions(
            child: MouseRegion(
              onEnter: _onEnter,
              onExit: _onExit,
              opaque: false,
              child: Semantics(
                enabled: enabled,
                onDidGainAccessibilityFocus: handleDidGainAccessibilityFocus,
                onDidLoseAccessibilityFocus: handleDidLoseAccessibilityFocus,
                onFocus: enabled
                    ? () {
                        assert(
                          _effectiveFocusNode.canRequestFocus,
                          'Received SemanticsAction.focus from the engine. However, the FocusNode '
                          'of this text field cannot gain focus. This likely indicates a bug. '
                          'If this text field cannot be focused (e.g. because it is not '
                          'enabled), then its corresponding semantics node must be configured '
                          'such that the assistive technology cannot request focus on it.',
                        );

                        if (_effectiveFocusNode.canRequestFocus &&
                            !_effectiveFocusNode.hasFocus) {
                          _effectiveFocusNode.requestFocus();
                        } else if (!widget.readOnly) {
                          // If the platform requested focus, that means that previously the
                          // platform believed that the text field did not have focus (even
                          // though Flutter's widget system believed otherwise). This likely
                          // means that the on-screen keyboard is hidden, or more generally,
                          // there is no current editing session in this field. To correct
                          // that, keyboard must be requested.
                          //
                          // A concrete scenario where this can happen is when the user
                          // dismisses the keyboard on the web. The editing session is
                          // closed by the engine, but the text field widget stays focused
                          // in the framework.
                          _requestKeyboard();
                        }
                      }
                    : null,
                onTap: !enabled || widget.readOnly
                    ? null
                    : () {
                        if (!controller.selection.isValid) {
                          controller.selection = TextSelection.collapsed(
                            offset: controller.text.length,
                          );
                        }
                        _requestKeyboard();
                      },
                child: TextFieldTapRegion(
                  child: IgnorePointer(
                    ignoring: !enabled,
                    child: Container(
                      decoration: effectiveDecoration,
                      child: _selectionGestureDetectorBuilder
                          .buildGestureDetector(
                            behavior: HitTestBehavior.translucent,
                            child: Align(
                              alignment: Alignment(-1, _textAlignVertical.y),
                              heightFactor: 1,
                              widthFactor: 1,
                              child: Padding(
                                padding:
                                    widget.padding ??
                                    compTheme?.padding ??
                                    EdgeInsets.symmetric(
                                      horizontal: scaling * 12,
                                      vertical: scaling * 8,
                                    ),
                                child: _addTextDependentAttachments(
                                  editable,
                                  defaultTextStyle,
                                  theme,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    for (final attached in _attachedFeatures) {
      textField = attached.state.wrap(textField);
    }

    return WidgetStatesProvider(
      states: {if (_effectiveFocusNode.hasFocus) WidgetState.hovered},
      child: textField,
    );
  }
}

class TextFieldAppendTextIntent extends Intent {
  const TextFieldAppendTextIntent({required this.text});

  final String text;
}

class TextFieldClearIntent extends Intent {
  const TextFieldClearIntent();
}

class TextFieldReplaceCurrentWordIntent extends Intent {
  const TextFieldReplaceCurrentWordIntent({required this.text});

  final String text;
}

class TextFieldSetTextIntent extends Intent {
  const TextFieldSetTextIntent({required this.text});

  final String text;
}

class TextFieldSetSelectionIntent extends Intent {
  const TextFieldSetSelectionIntent({required this.selection});
  final TextSelection selection;
}

class TextFieldSelectAllAndCopyIntent extends Intent {
  const TextFieldSelectAllAndCopyIntent();
}
