/// Platform-independent contract for form container components.
library;

import 'package:coui_core/src/component/contracts/form/form_style.dart';

/// Contract for a form container component.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreFormContract<W> {
  /// The form content widgets.
  List<W>? get children;

  /// Called when the form is submitted.
  ///
  /// Deliberately independent of [primaryAction] — `Form` never wires
  /// the default (or a caller-supplied) action button's press to this
  /// callback. Whatever triggers the button also has to call
  /// [onSubmit] itself (2026-09-11 결정: 완전 수동).
  void Function()? get onSubmit;

  /// Inter-item spacing (logical px, pre-scaling) between adjacent form
  /// rows. Flows directly into `Column.spacing` (Flutter) or flex `gap`
  /// CSS (Web) — both are native paint-API arguments that consume raw
  /// doubles. `null` defers to [CoreFormStyle.defaultRowSpacing].
  double? get rowSpacing;

  /// Whether to render the actions row ([primaryAction] /
  /// [secondaryAction]) as the last row below [children]. `false` by
  /// default — an existing `Form` gains no visual change unless the
  /// caller opts in.
  bool get showActions;

  /// The primary (call-to-action) button in the actions row — rendered
  /// only when [showActions] is `true`. `null` renders the
  /// design-system default: a `Button(variant: .primary)` labelled
  /// "Submit". A caller-supplied widget replaces the default outright
  /// rather than being layered under it.
  ///
  /// Deliberately NOT wired to [onSubmit] — even the default button's
  /// press goes nowhere on its own. The two slots are fully independent
  /// by design, so a caller who wants a working submit button supplies
  /// one with its own `onPressed`.
  W? get primaryAction;

  /// The secondary button in the actions row — rendered only when
  /// [showActions] and [showSecondaryAction] are both `true`. `null`
  /// renders the design-system default: a `Button(variant: .ghost)`
  /// labelled "Cancel". `null` never means "no button" — hiding the
  /// slot is [showSecondaryAction]'s job.
  W? get secondaryAction;

  /// Whether the actions row renders [secondaryAction] at all. `true` by
  /// default; `false` leaves only [primaryAction], still right-aligned.
  /// Mirrors the Figma component's `Show secondary action` boolean
  /// (2026-09-11 결정: 캔버스 기준) — the primary button has no such
  /// toggle because an actions row with no primary action is just
  /// [showActions] `false`.
  bool get showSecondaryAction;

  /// Spacing between [secondaryAction] and [primaryAction] in the
  /// actions row (logical px, pre-scaling) — the same native-paint-API
  /// shape as [rowSpacing]. `null` defers to
  /// [CoreFormStyle.defaultActionSpacing].
  double? get actionSpacing;
}
