import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Theme data for customizing [InputOTP] widget appearance.
///
/// This class defines the visual properties that can be applied to
/// [InputOTP] widgets, including spacing between OTP input fields
/// and the height of the input containers. These properties can be
/// set at the theme level to provide consistent styling across the application.
class InputOTPTheme {
  const InputOTPTheme({this.height, this.spacing});

  final double? spacing;

  final double? height;

  InputOTPTheme copyWith({
    ValueGetter<double?>? height,
    ValueGetter<double?>? spacing,
  }) {
    return InputOTPTheme(
      height: height == null ? this.height : height(),
      spacing: spacing == null ? this.spacing : spacing(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InputOTPTheme &&
        other.spacing == spacing &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(spacing, height);
}

class _InputOTPSpacing extends StatelessWidget {
  const _InputOTPSpacing();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<InputOTPTheme>(context);

    return SizedBox(width: compTheme?.spacing ?? theme.scaling * 8);
  }
}

abstract class InputOTPChild {
  static InputOTPChild get separator =>
      const WidgetInputOTPChild(OTPSeparator());
  static InputOTPChild get space =>
      const WidgetInputOTPChild(_InputOTPSpacing());
  static InputOTPChild get empty => const WidgetInputOTPChild(SizedBox());
  const InputOTPChild();
  factory InputOTPChild.input({
    TextInputType? keyboardType,
    bool obscured = false,
    CodepointPredicate? predicate,
    bool readOnly = false,
    CodepointUnaryOperator? transform,
  }) => CharacterInputOTPChild(
    keyboardType: keyboardType,
    obscured: obscured,
    predicate: predicate,
    readOnly: readOnly,
    transform: transform,
  );
  factory InputOTPChild.character({
    bool allowDigit = false,
    bool allowLowercaseAlphabet = false,
    bool allowUppercaseAlphabet = false,
    TextInputType? keyboardType,
    bool obscured = false,
    bool onlyLowercaseAlphabet = false,
    bool onlyUppercaseAlphabet = false,
    bool readOnly = false,
  }) {
    assert(
      !(onlyUppercaseAlphabet && onlyLowercaseAlphabet),
      'onlyUppercaseAlphabet and onlyLowercaseAlphabet cannot be true at the same time',
    );
    keyboardType ??=
        allowDigit &&
            !allowLowercaseAlphabet &&
            !allowUppercaseAlphabet &&
            !onlyUppercaseAlphabet &&
            !onlyLowercaseAlphabet
        ? TextInputType.number
        : TextInputType.text;

    return CharacterInputOTPChild(
      keyboardType: keyboardType,
      obscured: obscured,
      predicate: (codepoint) {
        if (allowLowercaseAlphabet &&
            CharacterInputOTPChild.isAlphabetLower(codepoint)) {
          return true;
        }
        if (allowUppercaseAlphabet &&
            CharacterInputOTPChild.isAlphabetUpper(codepoint)) {
          return true;
        }

        return allowDigit && CharacterInputOTPChild.isDigit(codepoint)
            ? true
            : (allowDigit && CharacterInputOTPChild.isDigit(codepoint)) &&
                  (true);
      },
      readOnly: readOnly,
      transform: (codepoint) {
        if (onlyUppercaseAlphabet) {
          return CharacterInputOTPChild.lowerToUpper(codepoint);
        }

        return onlyLowercaseAlphabet
            ? CharacterInputOTPChild.upperToLower(codepoint)
            : codepoint;
      },
    );
  }

  Widget build(BuildContext context, InputOTPChildData data);
  bool get hasValue;
}

typedef CodepointPredicate = bool Function(int codepoint);
typedef CodepointUnaryOperator = int Function(int codepoint);

class CharacterInputOTPChild extends InputOTPChild {
  const CharacterInputOTPChild({
    this.keyboardType,
    this.obscured = false,
    this.predicate,
    this.readOnly = false,
    this.transform,
  });

  final CodepointPredicate? predicate;
  final CodepointUnaryOperator? transform;
  final bool obscured;
  final bool readOnly;
  final TextInputType? keyboardType;

  static const _startAlphabetLower = 97; // 'a'
  static const _endAlphabetLower = 122; // 'z'
  static const _startAlphabetUpper = 65; // 'A'
  static const _endAlphabetUpper = 90; // 'Z'
  static const _startDigit = 48; // '0'

  static const _endDigit = 57; // '9'

  static bool isAlphabetLower(int codepoint) =>
      codepoint >= _startAlphabetLower && codepoint <= _endAlphabetLower;

  static bool isAlphabetUpper(int codepoint) =>
      codepoint >= _startAlphabetUpper && codepoint <= _endAlphabetUpper;

  static int lowerToUpper(int codepoint) =>
      isAlphabetLower(codepoint) ? codepoint - 32 : codepoint;

  static int upperToLower(int codepoint) =>
      isAlphabetUpper(codepoint) ? codepoint + 32 : codepoint;

  static bool isDigit(int codepoint) =>
      codepoint >= _startDigit && codepoint <= _endDigit;

  @override
  Widget build(BuildContext context, InputOTPChildData data) {
    return _OTPCharacterInput(
      key: data._key,
      data: data,
      keyboardType: keyboardType,
      obscured: obscured,
      predicate: predicate,
      readOnly: readOnly,
      transform: transform,
    );
  }

  @override
  bool get hasValue {
    return true;
  }
}

class _OTPCharacterInput extends StatefulWidget {
  const _OTPCharacterInput({
    required this.data,
    super.key,
    this.keyboardType,
    this.obscured = false,
    this.predicate,
    this.readOnly = false,
    this.transform,
  });

  final InputOTPChildData data;
  final CodepointPredicate? predicate;
  final CodepointUnaryOperator? transform;
  final bool obscured;
  final bool readOnly;

  final TextInputType? keyboardType;

  @override
  State<_OTPCharacterInput> createState() => _OTPCharacterInputState();
}

class _OTPCharacterInputState extends State<_OTPCharacterInput> {
  static BorderRadius getBorderRadiusByRelativeIndex(
    int groupLength,
    int relativeIndex,
    ThemeData theme,
  ) {
    if (relativeIndex == 0) {
      return BorderRadius.only(
        bottomLeft: Radius.circular(theme.radiusMd),
        topLeft: Radius.circular(theme.radiusMd),
      );
    } else if (relativeIndex == groupLength - 1) {
      return BorderRadius.only(
        bottomRight: Radius.circular(theme.radiusMd),
        topRight: Radius.circular(theme.radiusMd),
      );
    }

    return BorderRadius.zero;
  }

  final _controller = TextEditingController();

  final _focusScopeNode = FocusScopeNode();

  final _key = GlobalKey();

  int? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.data.value;
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      int codepoint = text.codeUnitAt(0);
      if (text.length > 1) {
        // forward to the next input
        final currentIndex = widget.data.index;
        final inputs = widget.data._state._children;
        if (currentIndex + 1 < inputs.length) {
          final nextInput = inputs[currentIndex + 1];
          nextInput.key.currentState?._controller.text = text.substring(1);
          if (text.length == 2) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              nextInput.key.currentState?._controller.text = text.substring(1);
            });
          } else {
            nextInput.key.currentState?._controller.text = text.substring(1);
          }
        }
      }
      if (widget.predicate != null && !widget.predicate!(codepoint)) {
        _value = null;
        _controller.clear();
        setState(() {});

        return;
      }
      if (widget.transform != null) {
        codepoint = widget.transform!(codepoint);
      }
      _value = codepoint;
      widget.data.changeValue(codepoint);
      _controller.clear();
      // next focus
      if (widget.data.nextFocusNode != null) {
        widget.data.nextFocusNode!.requestFocus();
      }
      setState(() {});
    }
  }

  Widget getValueWidget(ThemeData theme) {
    if (_value == null) {
      return const SizedBox();
    }

    return widget.obscured
        ? Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.foreground,
              shape: BoxShape.circle,
            ),
            height: theme.scaling * 8,
            width: theme.scaling * 8,
          )
        : Text(String.fromCharCode(_value!)).small().foreground();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FocusScope(
      node: _focusScopeNode,
      onKeyEvent: (node, event) {
        if (event is KeyUpEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (widget.data.previousFocusNode != null) {
              widget.data.previousFocusNode!.requestFocus();
            }

            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (widget.data.nextFocusNode != null) {
              widget.data.nextFocusNode!.requestFocus();
            }

            return KeyEventResult.handled;
          }
          // backspace
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_value == null) {
              if (widget.data.previousFocusNode != null) {
                widget.data.previousFocusNode!.requestFocus();
              }
            } else {
              widget.data.changeValue(null);
              _value = null;
              setState(() {});
            }

            return KeyEventResult.handled;
          }
          // enter
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (_controller.text.isNotEmpty) {
              _onControllerChanged();
            }

            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: SizedBox.square(
        dimension: theme.scaling * 36,
        child: Stack(
          children: [
            Positioned.fill(
              child: ListenableBuilder(
                builder: (context, child) {
                  return FocusOutline(
                    borderRadius: getBorderRadiusByRelativeIndex(
                      theme,
                      widget.data.relativeIndex,
                      widget.data.groupLength,
                    ),
                    focused: widget.data.focusNode!.hasFocus,
                    child: child!,
                  );
                },
                listenable: widget.data.focusNode!,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.border),
                    borderRadius: getBorderRadiusByRelativeIndex(
                      theme,
                      widget.data.relativeIndex,
                      widget.data.groupLength,
                    ),
                    color: theme.colorScheme.input.scaleAlpha(0.3),
                  ),
                ),
              ),
            ),
            if (_value != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: getValueWidget(theme)),
                ),
              ),
            Positioned.fill(
              key: _key,
              child: Opacity(
                opacity: _value == null ? 1 : 0,
                child: ComponentTheme(
                  data: const FocusOutlineTheme(
                    border: Border.fromBorderSide(BorderSide.none),
                  ),
                  child: TextField(
                    border: const Border.fromBorderSide(BorderSide.none),
                    controller: _controller,
                    decoration: const BoxDecoration(),
                    focusNode: widget.data.focusNode,
                    keyboardType: widget.keyboardType,
                    maxLines: null,
                    padding: EdgeInsets.zero,
                    readOnly: widget.readOnly,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WidgetInputOTPChild extends InputOTPChild {
  const WidgetInputOTPChild(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context, InputOTPChildData data) {
    final theme = Theme.of(context);

    return SizedBox.square(
      dimension: theme.scaling * 32,
      child: Center(child: child),
    );
  }

  @override
  bool get hasValue => false;
}

class OTPSeparator extends StatelessWidget {
  const OTPSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return const Text(
      '-',
    ).bold().withPadding(horizontal: theme.scaling * 4).base().foreground();
  }
}

class InputOTPChildData {
  const InputOTPChildData._(
    this._key,
    this._state, {
    required this.focusNode,
    required this.groupIndex,
    required this.groupLength,
    required this.index,
    this.nextFocusNode,
    this.previousFocusNode,
    required this.relativeIndex,
    this.value,
  });

  final FocusNode? previousFocusNode;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final int index;
  final int groupIndex;
  final int groupLength;
  final int relativeIndex;
  final int? value;
  final _InputOTPState _state;

  final GlobalKey<_OTPCharacterInputState>? _key;

  void changeValue(int? value) {
    _state._changeValue(index, value);
  }
}

class _InputOTPChild {
  _InputOTPChild({
    required this.child,
    required this.focusNode,
    required this.groupIndex,
    required this.relativeIndex,
    this.value,
  }) : key = GlobalKey<_OTPCharacterInputState>();

  _InputOTPChild.withNewChild(InputOTPChild newChild, _InputOTPChild old)
    : focusNode = old.focusNode,
      value = old.value,
      groupIndex = old.groupIndex,
      relativeIndex = old.relativeIndex,
      child = newChild,
      groupLength = old.groupLength,
      key = old.key;
  int? value;
  final FocusNode focusNode;
  final int groupIndex;
  final int relativeIndex;
  final InputOTPChild child;

  int groupLength = 0;

  final GlobalKey<_OTPCharacterInputState> key;
}

typedef OTPCodepointList = List<int?>;

extension OTPCodepointListExtension on OTPCodepointList {
  String otpToString() {
    return map((e) => e == null ? '' : String.fromCharCode(e)).join();
  }
}

/// A specialized input widget for One-Time Password (OTP) and verification code entry.
///
/// [InputOTP] provides a user-friendly interface for entering OTP codes, verification
/// numbers, and similar sequential input scenarios. The widget displays a series of
/// individual input fields that automatically advance focus as the user types,
/// creating an intuitive experience for multi-digit input.
///
/// Key features:
/// - Sequential character input with automatic focus advancement
/// - Customizable field layout with separators and spacing
/// - Support for various character types (digits, letters, symbols)
/// - Keyboard navigation and clipboard paste support
/// - Form integration with validation support
/// - Accessibility features for screen readers
/// - Theming and visual customization
///
/// The widget uses a flexible child system that allows mixing input fields
/// with separators, spaces, and custom widgets:
/// - Character input fields for actual OTP digits/letters
/// - Separators for visual grouping (e.g., dashes, dots)
/// - Spacing elements for layout control
/// - Custom widgets for specialized display needs
///
/// Common use cases:
/// - SMS verification codes (e.g., 6-digit codes)
/// - Two-factor authentication tokens
/// - Credit card security codes
/// - License key input
/// - PIN code entry
///
/// Example:
/// ```dart
/// InputOTP(
///   children: [
///     CharacterInputOTPChild(),
///     CharacterInputOTPChild(),
///     CharacterInputOTPChild(),
///     InputOTPChild.separator,
///     CharacterInputOTPChild(),
///     CharacterInputOTPChild(),
///     CharacterInputOTPChild(),
///   ],
///   onChanged: (code) => _handleOTPChange(code),
///   onSubmitted: (code) => _verifyOTP(code),
/// );
/// ```
class InputOTP extends StatefulWidget {
  const InputOTP({
    required this.children,
    this.initialValue,
    super.key,
    this.onChanged,
    this.onSubmitted,
  });

  final List<InputOTPChild> children;
  final OTPCodepointList? initialValue;
  final ValueChanged<OTPCodepointList>? onChanged;

  final ValueChanged<OTPCodepointList>? onSubmitted;

  @override
  State<InputOTP> createState() => _InputOTPState();
}

class _InputOTPState extends State<InputOTP>
    with FormValueSupplier<OTPCodepointList, InputOTP> {
  final _children = <_InputOTPChild>[];

  OTPCodepointList get value {
    return _children.map((e) => e.value).toList();
  }

  @override
  void initState() {
    super.initState();
    int index = 0;
    int groupIndex = 0;
    int relativeIndex = 0;
    for (final child in widget.children) {
      if (child.hasValue) {
        final value = getInitialValue(index);
        _children.add(
          _InputOTPChild(
            focusNode: FocusNode(),
            groupIndex: groupIndex,
            relativeIndex: relativeIndex,
            value: value,
            child: child,
          ),
        );
        index += 1;
        relativeIndex += 1;
      } else {
        // update previous group length
        for (int i = 0; i < index; i += 1) {
          _children[i].groupLength = relativeIndex;
        }
        groupIndex += 1;
        relativeIndex = 0;
      }
    }
    for (int i = index - relativeIndex; i < index; i += 1) {
      _children[i].groupLength = relativeIndex;
    }
    formValue = value;
  }

  void _changeValue(int index, int? value) {
    _children[index].value = value;
    final val = this.value;
    if (widget.onChanged != null) {
      widget.onChanged!(val);
    }
    if (widget.onSubmitted != null && val.every((e) => e != null)) {
      widget.onSubmitted?.call(val);
    }
    formValue = this.value;
  }

  int? getInitialValue(int index) {
    return widget.initialValue != null && index < widget.initialValue!.length
        ? widget.initialValue![index]
        : null;
  }

  @override
  void didUpdateWidget(covariant InputOTP oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.initialValue, widget.initialValue) ||
        !listEquals(oldWidget.children, widget.children)) {
      int index = 0;
      int groupIndex = 0;
      int relativeIndex = 0;
      for (final child in widget.children) {
        if (child.hasValue) {
          if (index < _children.length) {
            _children[index] = _InputOTPChild.withNewChild(
              _children[index],
              child,
            );
          } else {
            _children.add(
              _InputOTPChild(
                focusNode: FocusNode(),
                groupIndex: groupIndex,
                relativeIndex: relativeIndex,
                value: getInitialValue(index),
                child: child,
              ),
            );
          }
          index += 1;
          relativeIndex += 1;
        } else {
          // update previous group length
          for (int i = index - relativeIndex; i < index; i += 1) {
            _children[i].groupLength = relativeIndex;
          }
          groupIndex += 1;
          relativeIndex = 0;
        }
      }
      for (int i = index - relativeIndex; i < index; i += 1) {
        _children[i].groupLength = relativeIndex;
      }
      formValue = value;
    }
  }

  @override
  void didReplaceFormValue(OTPCodepointList value) {
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    int i = 0;
    for (final child in widget.children) {
      if (child.hasValue) {
        children.add(
          child.build(
            context,
            InputOTPChildData._(
              this,
              _children[i].key,
              focusNode: _children[i].focusNode,
              groupIndex: _children[i].groupIndex,
              groupLength: _children[i].groupLength,
              index: i,
              nextFocusNode: i == _children.length - 1
                  ? null
                  : _children[i + 1].focusNode,
              previousFocusNode: i == 0 ? null : _children[i - 1].focusNode,
              relativeIndex: _children[i].relativeIndex,
              value: _children[i].value,
            ),
          ),
        );
        i += 1;
      } else {
        children.add(
          child.build(
            context,
            InputOTPChildData._(
              this,
              null,
              focusNode: null,
              groupIndex: -1,
              groupLength: -1,
              index: -1,
              relativeIndex: -1,
            ),
          ),
        );
      }
    }
    final compTheme = ComponentTheme.maybeOf<InputOTPTheme>(context);

    return SizedBox(
      height: compTheme?.height ?? theme.scaling * 36,
      child: IntrinsicWidth(
        child: Row(
          children: [for (final child in children) Expanded(child: child)],
        ),
      ),
    );
  }
}
