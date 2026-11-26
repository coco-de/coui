/// Platform-independent contract for the definition-list component.
library;

import 'package:coui_core/src/component/contracts/definition_list/core_definition_entry.dart';
import 'package:coui_core/src/component/contracts/definition_list/core_definition_layout.dart';
import 'package:coui_core/src/component/contracts/definition_list/definition_list_style.dart';

/// Contract for a list of term / description pairs.
///
/// The component exists for the accessibility statement, not the visual
/// one: a run of values with no stated labels ("000-00-00000",
/// "000000-0000000") is read aloud as a run of digits with nothing to
/// attach them to. Each pair here carries its own label, and the Web
/// implementation renders that as `<dl>` / `<dt>` / `<dd>` so the
/// pairing is in the document rather than in the visual arrangement.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreDefinitionListContract<W> {
  /// The term / description pairs, in reading order.
  List<CoreDefinitionEntry<W>> get items;

  /// How each term is arranged against its description. Visual only —
  /// the announced reading order is the same for all three.
  CoreDefinitionLayout get layout;

  /// Whether the descriptions are numbers that should line up
  /// column-wise — registration numbers, amounts, dates.
  ///
  /// Turns on tabular (fixed-width) figures, so digits in successive
  /// descriptions occupy the same horizontal positions. Purely
  /// typographic: it changes no text and no semantics.
  bool get numeric;

  /// Whether the descriptions are identifiers or codes that should read as
  /// code — hashes, keys, registration codes.
  ///
  /// Sets the descriptions in the `code-sm` role (Geist Mono, 12px, a fixed
  /// 21px line box) instead of the layout's description role. Purely
  /// typographic, like [numeric], and the two combine: a mono description
  /// can also carry tabular figures.
  bool get mono;

  /// Per-instance gap / typography / term-column style. See
  /// [CoreDefinitionListStyle] for the merge chain.
  CoreDefinitionListStyle? get definitionListStyle;
}
