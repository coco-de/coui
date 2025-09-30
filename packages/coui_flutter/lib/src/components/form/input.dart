import 'dart:async';

import 'package:flutter/services.dart' show Clipboard, LogicalKeyboardKey;
import 'package:coui_flutter/coui_flutter.dart';

enum InputFeaturePosition {
  leading,
  trailing,
}

class InputHintFeature extends InputFeature {
  const InputHintFeature({
    this.enableShortcuts = true,
    this.icon,
    required this.popupBuilder,
    this.position = InputFeaturePosition.trailing,
    super.visibility,
  });

  final WidgetBuilder popupBuilder;
  final Widget? icon;
  final InputFeaturePosition position;
  final bool enableShortcuts;

  @override
  InputFeatureState createState() => _InputHintFeatureState();
}

class _InputHintFeatureState extends InputFeatureState<InputHintFeature> {
  final _popoverController = PopoverController();

  @override
  Iterable<Widget> buildTrailing() sync* {
    if (feature.position == InputFeaturePosition.trailing) {
      yield Builder(
        builder: (context) {
          return IconButton.text(
            density: ButtonDensity.compact,
            icon: feature.icon ?? const Icon(LucideIcons.info),
            onPressed: () => _showPopup(context),
          );
        },
      );
    }
  }

  @override
  Iterable<Widget> buildLeading() sync* {
    if (feature.position == InputFeaturePosition.leading) {
      yield IconButton.text(
        density: ButtonDensity.compact,
        icon: feature.icon ?? const Icon(LucideIcons.info),
        onPressed: () => _showPopup(context),
      );
    }
  }

  @override
  Iterable<MapEntry<ShortcutActivator, Intent>> buildShortcuts() sync* {
    if (feature.enableShortcuts) {
      yield const MapEntry(
        SingleActivator(LogicalKeyboardKey.f1),
        InputShowHintIntent(),
      );
    }
  }

  @override
  Iterable<MapEntry<Type, Action<Intent>>> buildActions() sync* {
    if (feature.enableShortcuts) {
      yield MapEntry(
        InputShowHintIntent,
        CallbackContextAction<InputShowHintIntent>(
          onInvoke: (intent, [context]) {
            if (context == null) {
              throw FlutterError(
                'CallbackContextAction was invoked without a valid BuildContext. '
                'This likely indicates a problem in the action system. '
                'Context must not be null when invoking InputShowHintIntent.',
              );
            }
            _showPopup(context);

            return true;
          },
        ),
      );
    }
  }

  void _showPopup(BuildContext context) {
    _popoverController.show(
      alignment: AlignmentDirectional.topCenter,
      anchorAlignment: AlignmentDirectional.bottomCenter,
      builder: feature.popupBuilder,
      context: context,
    );
  }
}

class InputShowHintIntent extends Intent {
  const InputShowHintIntent();
}

enum PasswordPeekMode {
  hold,
  toggle,
}

class InputPasswordToggleFeature extends InputFeature {
  const InputPasswordToggleFeature({
    this.icon,
    this.iconShow,
    this.mode = PasswordPeekMode.toggle,
    this.position = InputFeaturePosition.trailing,
    super.visibility,
  });

  final PasswordPeekMode mode;
  final InputFeaturePosition position;
  final Widget? icon;
  final Widget? iconShow;

  @override
  InputFeatureState createState() => _InputPasswordToggleFeatureState();
}

class _InputPasswordToggleFeatureState
    extends InputFeatureState<InputPasswordToggleFeature> {
  bool? _obscureText = true;

  @override
  Iterable<Widget> buildTrailing() sync* {
    if (feature.position == InputFeaturePosition.trailing) {
      yield _buildIconButton();
    }
  }

  @override
  Iterable<Widget> buildLeading() sync* {
    if (feature.position == InputFeaturePosition.leading) {
      yield _buildIconButton();
    }
  }

  @override
  TextField interceptInput(TextField input) {
    return input.copyWith(obscureText: () => _obscureText ?? false);
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = _obscureText == null ? true : null;
    });
  }

  Widget _buildIcon() {
    return _obscureText ?? false || input.obscureText
        ? feature.icon ?? const Icon(LucideIcons.eye)
        : feature.iconShow ?? const Icon(LucideIcons.eyeOff);
  }

  Widget _buildIconButton() {
    return feature.mode == PasswordPeekMode.hold
        ? IconButton.text(
            density: ButtonDensity.compact,
            enabled: true,
            icon: _buildIcon(),
            onTapDown: (_) {
              setState(() {
                _obscureText = null;
              });
            },
            onTapUp: (_) {
              setState(() {
                _obscureText = true;
              });
            },
          )
        : IconButton.text(
            density: ButtonDensity.compact,
            icon: _buildIcon(),
            onPressed: _toggleObscureText,
          );
  }
}

class InputClearFeature extends InputFeature {
  const InputClearFeature({
    this.icon,
    this.position = InputFeaturePosition.trailing,
    super.visibility,
  });

  final InputFeaturePosition position;
  final Widget? icon;

  @override
  InputFeatureState createState() => _InputClearFeatureState();
}

class _InputClearFeatureState extends InputFeatureState<InputClearFeature> {
  @override
  Iterable<Widget> buildTrailing() sync* {
    if (feature.position == InputFeaturePosition.trailing) {
      yield IconButton.text(
        density: ButtonDensity.compact,
        icon: feature.icon ?? const Icon(LucideIcons.x),
        onPressed: _clear,
      );
    }
  }

  @override
  Iterable<Widget> buildLeading() sync* {
    if (feature.position == InputFeaturePosition.leading) {
      yield IconButton.text(
        density: ButtonDensity.compact,
        icon: feature.icon ?? const Icon(LucideIcons.x),
        onPressed: _clear,
      );
    }
  }

  void _clear() {
    controller.text = '';
  }
}

class InputRevalidateFeature extends InputFeature {
  const InputRevalidateFeature({
    this.icon,
    this.position = InputFeaturePosition.trailing,
    super.visibility,
  });

  final InputFeaturePosition position;
  final Widget? icon;

  @override
  InputFeatureState createState() => _InputRevalidateFeatureState();
}

class _InputRevalidateFeatureState
    extends InputFeatureState<InputRevalidateFeature> {
  @override
  Iterable<Widget> buildTrailing() sync* {
    if (feature.position == InputFeaturePosition.trailing) {
      yield _buildIcon();
    }
  }

  @override
  Iterable<Widget> buildLeading() sync* {
    if (feature.position == InputFeaturePosition.leading) {
      yield _buildIcon();
    }
  }

  void _revalidate() {
    final formFieldHandle = Data.maybeFind<FormFieldHandle>(context);
    if (formFieldHandle != null) {
      formFieldHandle.revalidate();
    }
  }

  Widget _buildIcon() {
    return FormPendingBuilder(
      builder: (context, futures, _) {
        if (futures.isEmpty) {
          return IconButton.text(
            density: ButtonDensity.compact,
            icon: feature.icon ?? const Icon(LucideIcons.refreshCw),
            onPressed: _revalidate,
          );
        }

        final futureAll = Future.wait(futures.values);

        return FutureBuilder(
          builder: (context, snapshot) {
            return snapshot.connectionState == ConnectionState.waiting
                ? IconButton.text(
                    density: ButtonDensity.compact,
                    icon: RepeatedAnimationBuilder(
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: degToRad(value),
                          child: child,
                        );
                      },
                      duration: const Duration(seconds: 1),
                      end: 360,
                      start: 0,
                      child: feature.icon ?? const Icon(LucideIcons.refreshCw),
                    ),
                  )
                : IconButton.text(
                    density: ButtonDensity.compact,
                    icon: feature.icon ?? const Icon(LucideIcons.refreshCw),
                    onPressed: _revalidate,
                  );
          },
          future: futureAll,
        );
      },
    );
  }
}

typedef SuggestionBuilder = FutureOr<Iterable<String>> Function(String query);

class InputAutoCompleteFeature extends InputFeature {
  const InputAutoCompleteFeature({
    required this.child,
    this.mode = AutoCompleteMode.replaceWord,
    this.popoverAlignment,
    this.popoverAnchorAlignment,
    this.popoverConstraints,
    this.popoverWidthConstraint,
    required this.querySuggestions,
    super.visibility,
  });

  final SuggestionBuilder querySuggestions;
  final Widget child;
  final BoxConstraints? popoverConstraints;
  final PopoverConstraint? popoverWidthConstraint;
  final AlignmentDirectional? popoverAnchorAlignment;
  final AlignmentDirectional? popoverAlignment;

  final AutoCompleteMode mode;

  @override
  InputFeatureState createState() => _AutoCompleteFeatureState();
}

class _AutoCompleteFeatureState
    extends InputFeatureState<InputAutoCompleteFeature> {
  final _key = GlobalKey();
  final _suggestions = ValueNotifier<FutureOr<Iterable<String>>?>(null);

  @override
  void onTextChanged(String text) {
    _suggestions.value = feature.querySuggestions(text);
  }

  @override
  Widget wrap(Widget child) {
    return ListenableBuilder(
      builder: (context, child) {
        final suggestions = _suggestions.value;

        return suggestions is Future<Iterable<String>>
            ? FutureBuilder(
                builder: (context, snapshot) {
                  return AutoComplete(
                    key: _key,
                    mode: feature.mode,
                    popoverAlignment: feature.popoverAlignment,
                    popoverAnchorAlignment: feature.popoverAnchorAlignment,
                    popoverConstraints: feature.popoverConstraints,
                    popoverWidthConstraint: feature.popoverWidthConstraint,
                    suggestions: snapshot.hasData
                        ? snapshot.requireData.toList()
                        : const [],
                    child: child!,
                  );
                },
                future: suggestions,
              )
            : AutoComplete(
                key: _key,
                mode: feature.mode,
                popoverAlignment: feature.popoverAlignment,
                popoverAnchorAlignment: feature.popoverAnchorAlignment,
                popoverConstraints: feature.popoverConstraints,
                popoverWidthConstraint: feature.popoverWidthConstraint,
                suggestions: suggestions == null
                    ? const []
                    : suggestions.toList(),
                child: child!,
              );
      },
      listenable: _suggestions,
      child: child,
    );
  }
}

class InputSpinnerFeature extends InputFeature {
  const InputSpinnerFeature({
    this.enableGesture = true,
    this.invalidValue = 0.0,
    this.step = 1.0,
    super.visibility,
  });

  final double step;
  final bool enableGesture;
  final double? invalidValue;

  @override
  InputFeatureState createState() => _InputSpinnerFeatureState();
}

class _InputSpinnerFeatureState extends InputFeatureState<InputSpinnerFeature> {
  @override
  Iterable<Widget> buildTrailing() sync* {
    yield feature.enableGesture
        ? _wrapGesture(_buildButtons())
        : _buildButtons();
  }

  void _replaceText(UnaryOperator<String> replacer) {
    final controller = this.controller;
    final text = controller.text;
    final newText = replacer(text);
    if (newText != text) {
      controller.text = newText;
      input.onChanged?.call(newText);
    }
  }

  void _increase() {
    _replaceText((text) {
      final value = double.tryParse(text);
      if (value == null) {
        return feature.invalidValue != null
            ? _newText(feature.invalidValue!)
            : text;
      }

      return _newText(value + feature.step);
    });
  }

  static String _newText(double value) {
    String newText = value.toString();
    if (newText.contains('.')) {
      while (newText.endsWith('0')) {
        newText = newText.substring(0, newText.length - 1);
      }
      if (newText.endsWith('.')) {
        newText = newText.substring(0, newText.length - 1);
      }
    }

    return newText;
  }

  void _decrease() {
    _replaceText((text) {
      final value = double.tryParse(text);
      if (value == null) {
        return feature.invalidValue != null
            ? _newText(feature.invalidValue!)
            : text;
      }

      return _newText(value - feature.step);
    });
  }

  Widget _wrapGesture(Widget child) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < 0) {
          _increase();
        } else {
          _decrease();
        }
      },
      child: child,
    );
  }

  Widget _buildButtons() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return Column(
          children: [
            IconButton.text(
              density: ButtonDensity.compact,
              icon: Transform.translate(
                offset: Offset(0, -1 * theme.scaling),
                child: Transform.scale(
                  scale: 1.5,
                  child: const Icon(LucideIcons.chevronUp),
                ),
              ),
              onPressed: _increase,
              size: ButtonSize.xSmall,
            ),
            IconButton.text(
              density: ButtonDensity.compact,
              icon: Transform.translate(
                offset: Offset(0, theme.scaling * 1),
                child: Transform.scale(
                  scale: 1.5,
                  child: const Icon(LucideIcons.chevronDown),
                ),
              ),
              onPressed: _decrease,
              size: ButtonSize.xSmall,
            ),
          ],
        );
      },
    );
  }
}

class InputCopyFeature extends InputFeature {
  const InputCopyFeature({
    this.icon,
    this.position = InputFeaturePosition.trailing,
    super.visibility,
  });

  final InputFeaturePosition position;
  final Widget? icon;

  @override
  InputFeatureState createState() => _InputCopyFeatureState();
}

class _InputCopyFeatureState extends InputFeatureState<InputCopyFeature> {
  @override
  Iterable<Widget> buildTrailing() sync* {
    if (feature.position == InputFeaturePosition.trailing) {
      yield IconButton.text(
        density: ButtonDensity.compact,
        icon: feature.icon ?? const Icon(LucideIcons.copy),
        onPressed: _copy,
      );
    }
  }

  @override
  Iterable<Widget> buildLeading() sync* {
    if (feature.position == InputFeaturePosition.leading) {
      yield IconButton.text(
        density: ButtonDensity.compact,
        icon: feature.icon ?? const Icon(LucideIcons.copy),
        onPressed: _copy,
      );
    }
  }

  void _copy() {
    Actions.invoke(context, const TextFieldSelectAllAndCopyIntent());
  }
}

class InputLeadingFeature extends InputFeature {
  const InputLeadingFeature(this.prefix, {super.visibility});

  final Widget prefix;

  @override
  InputFeatureState createState() => _InputLeadingFeatureState();
}

class _InputLeadingFeatureState extends InputFeatureState<InputLeadingFeature> {
  @override
  Iterable<Widget> buildLeading() sync* {
    yield feature.prefix;
  }
}

class InputTrailingFeature extends InputFeature {
  const InputTrailingFeature(this.suffix, {super.visibility});

  final Widget suffix;

  @override
  InputFeatureState createState() => _InputTrailingFeatureState();
}

class _InputTrailingFeatureState
    extends InputFeatureState<InputTrailingFeature> {
  @override
  Iterable<Widget> buildTrailing() sync* {
    yield feature.suffix;
  }
}

class InputPasteFeature extends InputFeature {
  const InputPasteFeature({
    this.icon,
    this.position = InputFeaturePosition.trailing,
    super.visibility,
  });

  final InputFeaturePosition position;
  final Widget? icon;

  @override
  InputFeatureState createState() => _InputPasteFeatureState();
}

class _InputPasteFeatureState extends InputFeatureState<InputPasteFeature> {
  @override
  Iterable<Widget> buildTrailing() sync* {
    if (feature.position == InputFeaturePosition.trailing) {
      yield IconButton.text(
        density: ButtonDensity.compact,
        icon: feature.icon ?? const Icon(LucideIcons.clipboard),
        onPressed: _paste,
      );
    }
  }

  @override
  Iterable<Widget> buildLeading() sync* {
    if (feature.position == InputFeaturePosition.leading) {
      yield IconButton.text(
        density: ButtonDensity.compact,
        icon: feature.icon ?? const Icon(LucideIcons.clipboard),
        onPressed: _paste,
      );
    }
  }

  void _paste() {
    final clipboardData = Clipboard.getData('text/plain');
    clipboardData.then((value) {
      if (value != null) {
        final text = value.text;
        if (text != null && text.isNotEmpty && context.mounted) {
          Actions.invoke(context, TextFieldAppendTextIntent(text: text));
        }
      }
    });
  }
}
