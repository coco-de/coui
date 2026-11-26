import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'input_otp.stories.g.dart';

// InputOtp widgetbook constants.
const _kDefaultLength = 6;
const _kDefaultSeparatorInterval = 3;
const _kEmptyCode = '';

/// Interactive demo host for [InputOtp] stories.
///
/// Tracks the last completed code so the OTP callback is observable
/// in the preview.
class InputOtpDemo extends StatefulWidget {
  /// Creates an [InputOtpDemo].
  const InputOtpDemo({
    super.key,
    this.length = _kDefaultLength,
    this.obscured = false,
    this.separatorInterval = _kDefaultSeparatorInterval,
    this.enabled = true,
    this.autofocus = false,
    this.errorText,
    this.size = CoreInputOtpSize.defaultSize,
  });

  /// Number of OTP slots.
  final int length;

  /// Whether entered digits are obscured.
  final bool obscured;

  /// Interval at which separators are inserted between slots.
  final int separatorInterval;

  /// Whether the input accepts interaction.
  final bool enabled;

  /// Whether to automatically focus the input on mount.
  final bool autofocus;

  /// Error message — shows the error variant + helper message when set.
  final String? errorText;

  /// Cell size rung — `md` is the everyday field, `lg` the large one a
  /// verification screen draws.
  final CoreInputOtpSize size;

  @override
  State<InputOtpDemo> createState() => _InputOtpDemoState();
}

class _InputOtpDemoState extends State<InputOtpDemo> {
  String _completed = _kEmptyCode;

  void handleCompleted(OTPCodepointList value) {
    setState(() {
      _completed = value.nonNulls.map(String.fromCharCode).join();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space16,
      children: [
        InputOtp(
          key: ValueKey('${widget.length}-${widget.separatorInterval}'),
          length: widget.length,
          obscured: widget.obscured,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          separatorInterval: widget.separatorInterval,
          onCompleted: handleCompleted,
          errorText: widget.errorText,
          size: widget.size,
        ),
        if (_completed.isNotEmpty)
          Text('Completed: $_completed').bodySmall().onSurface(),
      ],
    );
  }
}

/// Navigation metadata for the InputOtp component.
const kComponentMeta = ComponentMeta(name: 'InputOtp', path: 'form');

/// Story metadata for [InputOtpDemo].
const kMeta = Meta(InputOtpDemo.new);

/// OTP input with editable length, obscure, separator and size knobs.
final $Default = _Story();

/// 56px cells with `titleLarge` bold digits — for a screen whose one job is
/// entering the code.
final $Large = _Story(
  args: _Args(
    size: EnumArg(CoreInputOtpSize.lg, values: CoreInputOtpSize.values),
  ),
);
