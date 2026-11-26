/// Platform-independent contract for unified `DescriptionCard` components.
///
/// Defines the interface that all `DescriptionCard` implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/description_card/core_description_card_alignment.dart';
import 'package:coui_core/src/component/contracts/description_card/core_description_card_empty_behavior.dart';
import 'package:coui_core/src/component/contracts/description_card/core_description_card_layout.dart';
import 'package:coui_core/src/component/contracts/description_card/core_description_card_overflow.dart';
import 'package:coui_core/src/component/contracts/description_card/core_description_card_row_weight.dart';
import 'package:coui_core/src/component/contracts/description_card/core_description_card_size.dart';
import 'package:coui_core/src/component/contracts/description_card/core_description_card_variant.dart';
import 'package:coui_core/src/component/contracts/description_card/core_description_row.dart';
import 'package:coui_core/src/component/contracts/description_card/description_card_style.dart';

/// Contract for a unified description card component.
///
/// Chrome / dimensional / text-slot overrides flow through the single
/// [descriptionCardStyle] field — see [CoreDescriptionCardStyle] and
/// Epic #1302 / Epic #1370 for the nested resolve chain.
///
/// Semantic enums (`variant`, `size`, `layout`, `alignment`,
/// `valueOverflow`, `rowWeight`, `emptyValueBehavior`) and boolean
/// toggles (`showDivider`, `showRowDividers`,
/// `showBottomActionDivider`) remain on the contract per Epic #1302
/// 원칙 6/7 (behaviour flags / semantic enums stay on the widget).
///
/// Composite-layout slots (`title`, `titleLeading`, `titleTrailing`,
/// `bottomAction`, `rows`) also stay on the contract — they are slot
/// data / child placement parameters, not panel chrome.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreDescriptionCardContract<W> {
  /// Row data list.
  List<CoreDescriptionRow<W>> get rows;

  /// Card size scale.
  CoreDescriptionCardSize get size;

  /// Layout direction (horizontal vs vertical row layout).
  CoreDescriptionCardLayout get layout;

  /// Visual variant (filled / outlined / ghost).
  CoreDescriptionCardVariant get variant;

  /// Optional title text shown above the rows.
  String? get title;

  /// Widget rendered before the title text.
  W? get titleLeading;

  /// Widget rendered after the title text.
  W? get titleTrailing;

  /// Whether to draw a divider below the title section.
  bool get showDivider;

  /// Whether to draw dividers between rows.
  bool get showRowDividers;

  /// Optional bottom action area (e.g. a button).
  W? get bottomAction;

  /// Whether to draw a divider above [bottomAction].
  bool get showBottomActionDivider;

  /// How to align label/value pairs in horizontal layout.
  CoreDescriptionCardAlignment get alignment;

  /// How to handle long value text.
  CoreDescriptionCardOverflow get valueOverflow;

  /// Which side (label or value) is emphasized by default.
  CoreDescriptionCardRowWeight get rowWeight;

  /// How to handle rows whose value is null.
  CoreDescriptionCardEmptyBehavior get emptyValueBehavior;

  /// Placeholder text used when [emptyValueBehavior] is
  /// [CoreDescriptionCardEmptyBehavior.placeholder].
  String get emptyPlaceholder;

  /// Tap callback for the entire card.
  void Function()? get onTap;

  /// Whether the card and its rows react to taps. `null` follows whether
  /// there is anything to tap — [onTap] or a row's `onTap`
  /// ([effectiveEnabled]).
  ///
  /// `false` on a card with a tap target stops the presses, announces the
  /// card disabled and dims its content — the title, rows and bottom
  /// action region — to
  /// `CoreDescriptionCardStyle.disabledContentOpacity`; the card's
  /// background and border stay as they are. A card with nothing to tap
  /// never dims ([dimsContent]).
  bool? get enabled;

  /// Per-instance description-card style covering chrome + dimensional
  /// + text slot overrides (background / border / radius / padding /
  /// shadow / divider / default + emphasised label/value text styles).
  /// Resolves through the nested-merge chain
  /// (`theme.descriptionCard.style` ← parent slot override ←
  /// `widget.descriptionCardStyle`).
  CoreDescriptionCardStyle? get descriptionCardStyle;

  /// Whether the card reacts to taps: an explicit [enabled] wins, else
  /// whether there is a tap target. Both platforms' widgets call this so
  /// the rule lives in one place.
  static bool effectiveEnabled({
    required bool? enabled,
    required bool hasTapTarget,
  }) => enabled ?? hasTapTarget;

  /// Whether the card dims its content: only an explicit `enabled: false`
  /// on a card that has a tap target. A purely informational card (no
  /// tap target) is not "disabled" — it never dims.
  static bool dimsContent({
    required bool? enabled,
    required bool hasTapTarget,
  }) => enabled == false && hasTapTarget;
}
