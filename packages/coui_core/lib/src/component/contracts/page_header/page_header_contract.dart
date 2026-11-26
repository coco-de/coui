/// Cross-platform contract for `PageHeader`.
library;

import 'package:coui_core/src/component/contracts/page_header/page_header_style.dart';

/// The head of a page — a short eyebrow over the page title, an optional
/// sentence under it, and the page's actions at the end of the row.
///
/// Anatomy: `[ eyebrow / title / description ] [ actions ]`. The text block
/// takes the width the actions leave. When that would fall under
/// [CorePageHeaderStyle.minTextWidth], the actions move under the text, start
/// aligned — both platforms by the same rule, so the row never overflows.
/// The actions wrap among themselves when even a line of their own is too
/// narrow.
///
/// The slots take any widget. Their text takes the header's roles through
/// the ambient text style ([CorePageHeaderStyle.eyebrowTextStyle] and its
/// siblings), so a plain `Text('…')` reads as the design without a style of
/// its own.
///
/// Chrome flows through the single [pageHeaderStyle] slot; everything here
/// is content (the slots) or semantics (the heading level).
abstract interface class CorePageHeaderContract<W> {
  /// The heading level a page title takes — the page's own heading.
  static const int defaultHeadingLevel = 1;

  /// The short line above the title — the section or area the page sits in.
  W? get eyebrow;

  /// The page title. Announced as a heading of [headingLevel].
  W get title;

  /// The sentence under the title.
  W? get description;

  /// The page's actions, start to end — usually a secondary and a primary
  /// `Button`. Empty: the text block takes the whole row.
  List<W> get actions;

  /// The heading level [title] is announced at (1–6) — Flutter's
  /// `Semantics.headingLevel`, Web's `<h1>`…`<h6>`. The look does not change
  /// with it; the roles in [pageHeaderStyle] do that.
  int get headingLevel;

  /// Single chrome slot — see [CorePageHeaderStyle].
  CorePageHeaderStyle? get pageHeaderStyle;
}
