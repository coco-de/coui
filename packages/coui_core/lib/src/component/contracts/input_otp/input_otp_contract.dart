/// Platform-independent contract for OTP input components.
library;

import 'package:coui_core/src/component/contracts/input_otp/input_otp_size.dart';
import 'package:coui_core/src/component/contracts/input_otp/input_otp_style.dart';

/// Contract for an OTP input component.
///
/// Type parameters:
/// - [Val] - value type (e.g., `List<int?>` for Flutter, `String` for Web).
///
/// The change / completion callbacks are derived directly as
/// `void Function(Val)?` — no phantom `ChangedCb` / `CompletedCb`
/// type parameters (per `cautions.md` "Contract callback 타입").
abstract interface class CoreInputOtpContract<Val> {
  /// Default number of OTP cells — the count a caller who passes no
  /// [length] gets. One value both platforms' widgets and the Figma builder
  /// read, so the default field is drawn and built at the same size.
  static const int defaultLength = 6;

  /// Default interval at which a separator is inserted between cells — a
  /// caller who passes no [separatorInterval] gets one every third cell, so
  /// the default six-cell field reads `000-000`. `0` turns separators off.
  static const int defaultSeparatorInterval = 3;

  /// Number of OTP cells.
  int get length;

  /// Whether to mask input characters.
  bool get obscured;

  /// Whether the input is enabled.
  bool get enabled;

  /// Whether to automatically focus the input on mount — commonly used
  /// for SMS/2FA verification screens where the code entry should be
  /// ready to type as soon as the screen appears.
  bool get autofocus;

  /// Insert a separator every N cells (0 = none) — defaults to
  /// [defaultSeparatorInterval].
  int get separatorInterval;

  /// Initial OTP value.
  Val? get initialValue;

  /// Callback when the OTP value changes.
  void Function(Val)? get onChanged;

  /// Callback when all cells are filled.
  void Function(Val)? get onCompleted;

  /// Error message. When non-null, the input shows the error variant
  /// (border / focus ring switch to the `error` token) and, if
  /// [CoreInputOtpStyle.errorTextStyle] resolves, renders this message
  /// below the cell row — mirroring `TextField.errorText`.
  ///
  /// Purely presentational: the caller owns clearing the code on retry
  /// (e.g. by rebuilding with a fresh `key` once the user requests a new
  /// code), matching the uncontrolled-input model the rest of the
  /// component already uses.
  String? get errorText;

  /// Size of the cells, their corner and the digit — selects the
  /// [CoreInputOtpStyle.defaultsBySize] rung. Widget-only semantic
  /// identifier, not theme-overridable (the theme cannot silently change a
  /// caller's `size:`). Defaults to [CoreInputOtpSize.defaultSize].
  CoreInputOtpSize get size;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain, keyed by [size] and by the
  /// variant implied by [errorText] (`error` when non-null,
  /// `defaultVariant` otherwise):
  ///
  /// ```text
  /// design system default
  ///   → CoreInputOtpStyle.defaultsBySize[size]        ┐ head of the chain
  ///   → CoreInputOtpStyle.defaultsByVariant[variant]  ┘ (chainHeadFor)
  ///   → CoreInputOtpTheme.style
  ///   → CoreInputOtpTheme.variantStyles[variant]
  ///   → widget.inputOtpStyle
  /// ```
  ///
  /// The variant row states only border colours and lies over the size row,
  /// so where `lg` states its own cell colours the error variant's `error`
  /// borders still win.
  CoreInputOtpStyle? get inputOtpStyle;
}

/// Optional capability for OTP controls that support editing an individual
/// filled cell. Existing [CoreInputOtpContract] implementers need not adopt it.
abstract interface class CoreInputOtpCellEditingContract {
  /// Allows selecting a filled cell to replace its digit. When false,
  /// taps retain the historical append/backspace-from-the-end behavior.
  bool get allowCellEditing;
}
