/// Cross-platform contract for `PanelHeader`.
library;

import 'package:coui_core/src/component/contracts/panel_header/panel_header_style.dart';

/// The head of a panel inside a page — the panel's title, and one action at
/// the end of the row (a "see all" link, by convention).
///
/// Anatomy: `[ title ] [ action ]`. The title takes the width the action
/// leaves and wraps. When that would fall under
/// [CorePanelHeaderStyle.minTitleWidth], the action moves under the title,
/// start aligned — the same rule `PageHeader` follows, on both platforms.
///
/// The title slot takes any widget; its text takes the header's role
/// through the ambient text style ([CorePanelHeaderStyle.titleTextStyle]).
///
/// Chrome flows through the single [panelHeaderStyle] slot; everything here
/// is content (the slots) or semantics (the heading level).
abstract interface class CorePanelHeaderContract<W> {
  /// The heading level a panel title takes — one under the page's own.
  static const int defaultHeadingLevel = 2;

  /// The panel title. Announced as a heading of [headingLevel].
  W get title;

  /// The action at the end of the row — usually a small `plain` `Button`
  /// with a trailing chevron ("View all >").
  W? get action;

  /// The heading level [title] is announced at (1–6) — Flutter's
  /// `Semantics.headingLevel`, Web's `<h1>`…`<h6>`. The look does not change
  /// with it; [panelHeaderStyle] does that.
  int get headingLevel;

  /// Single chrome slot — see [CorePanelHeaderStyle].
  CorePanelHeaderStyle? get panelHeaderStyle;
}
