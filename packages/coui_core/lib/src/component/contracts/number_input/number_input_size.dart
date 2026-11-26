/// Height steps for a `NumberInput` — and, through it, its step buttons.
library;

import 'package:coui_core/src/size/component_size.dart';

/// The three heights a number input comes in — 32 / 40 / 48, the same rungs
/// the form fields sit on. The step buttons are one rung below the field
/// (24 / 32 / 40), so the field's border and inset wrap them evenly.
///
/// Component-specific rather than [CoreComponentSize] because the ladder
/// really is three rungs: a number input is a small, dense control, and an
/// axis that stated `xs` / `xl` / `xl2` would be lying about its range.
enum CoreNumberInputSize {
  /// 32px field, 24px buttons — dense desktop forms.
  sm,

  /// 40px field, 32px buttons — the default, level with the `md`
  /// `TextField` beside it.
  md,

  /// 48px field, 40px buttons — touch targets.
  lg;

  /// Widget default. Both platform constructors reference this value.
  static const CoreNumberInputSize defaultSize = md;

  /// The `TextField` rung the composed field takes — the same name on both
  /// ladders, and the same 32 / 40 / 48 heights.
  CoreComponentSize toComponentSize() => switch (this) {
    sm => CoreComponentSize.sm,
    md => CoreComponentSize.md,
    lg => CoreComponentSize.lg,
  };

  /// The `Button` rung the two step buttons take: one below the field.
  CoreComponentSize toStepButtonSize() => switch (this) {
    sm => CoreComponentSize.xs,
    md => CoreComponentSize.sm,
    lg => CoreComponentSize.md,
  };
}
