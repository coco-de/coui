/// Theme data for Accordion customization.
library;

import 'package:coui_core/src/component/contracts/accordion/accordion_style.dart';
import 'package:meta/meta.dart';

/// Theme overrides for Accordion.
///
/// Per Epic #1302 the visual chrome of every Accordion flows
/// through the single [style] field — see [CoreAccordionStyle] for
/// the merge chain. Animation timing lives on
/// [CoreAccordionStyle.duration].
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreAccordionTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance accordionStyle
/// ```
@immutable
class CoreAccordionTheme {
  /// Creates a [CoreAccordionTheme].
  const CoreAccordionTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreAccordionStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAccordionTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
