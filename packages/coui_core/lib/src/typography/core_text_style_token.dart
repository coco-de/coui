// The CoreTextStyles abstract class is a flat catalog of M3 semantic typography
// tokens (displayLarge … codeMd, 22 slots). Each token is named after its
// kebab-case identifier (e.g. `bodyMedium` → `body-medium`), making it
// self-documenting; the class-level dartdoc covers the catalog's purpose and
// section comments group related tokens. Adding a per-token dartdoc would be
// redundant boilerplate — mirrors the [CoreColors] pattern.
// ignore_for_file: public_member_api_docs

/// Semantic typography token identifiers.
///
/// Each `CoreTextStyleToken` wraps:
/// - a `name` in kebab-case for CSS variable / Tailwind class rendering
///   (`'body-medium'` → `text-body-medium` / `var(--text-body-medium)`),
/// - a `read` accessor that pulls the matching slot from a
///   `CoreTypography` instance at render time.
///
/// Tokens are exposed as compile-time constants on `CoreTextStyles` so
/// they can be embedded inside `const` style definitions — mirroring
/// the `CoreColorToken` / `CoreColors` pattern (Epic #1601 PoC):
///
/// ```dart
/// const filled = CoreButtonStyle(
///   labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
/// );
/// ```
///
/// This catalog deprecates the per-component `CoreXxxTypographyRole`
/// enums (`CoreButtonTypographyRole`, `CoreBadgeTypographyRole`,
/// `CoreFilterTypographyRole`, `CoreTextFieldTypographyRole`) — all four
/// folded into a single source of truth here.
library;

import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:coui_core/src/typography/typography_scale.dart';
import 'package:meta/meta.dart';

/// A semantic typography token — a stable identifier for a slot in
/// `CoreTypography`.
///
/// Mirrors `CoreColorToken` for typography: the token carries a
/// kebab-case `name` (used for Tailwind class / CSS variable emission)
/// plus a `read` accessor that materialises the actual `CoreTextStyle`
/// from a `CoreTypography` instance at render time.
@immutable
class CoreTextStyleToken {
  const CoreTextStyleToken._(this.name, this.read);

  /// Kebab-case identifier used for Tailwind class / CSS variable
  /// emission (`'body-medium'` → `text-body-medium`).
  final String name;

  /// Resolves this token against a [CoreTypography] instance.
  final CoreTextStyle Function(CoreTypography typography) read;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTextStyleToken && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'CoreTextStyleToken($name)';
}

/// All 22 typography slot tokens — compile-time constants.
///
/// Use as:
/// ```dart
/// CoreTextStyle.token(CoreTextStyles.bodyMedium)
/// CoreTextStyle.token(CoreTextStyles.labelLarge)
/// ```
///
/// 22 slots in six families: display · headline · title (large / medium /
/// small), body (large … xs), label (xl2 … xs) and code (xs / sm / md).
/// Mirrors the layout of [CoreTypography] one-for-one — adding a slot here
/// without a matching field on [CoreTypography] (or vice-versa) is caught
/// at compile time by the accessor functions.
abstract final class CoreTextStyles {
  // ── Display ────────────────────────────────────────────────────────
  static const displayLarge = CoreTextStyleToken._(
    'display-large',
    _displayLarge,
  );
  static const displayMedium = CoreTextStyleToken._(
    'display-medium',
    _displayMedium,
  );
  static const displaySmall = CoreTextStyleToken._(
    'display-small',
    _displaySmall,
  );

  // ── Headline ───────────────────────────────────────────────────────
  static const headlineLarge = CoreTextStyleToken._(
    'headline-large',
    _headlineLarge,
  );
  static const headlineMedium = CoreTextStyleToken._(
    'headline-medium',
    _headlineMedium,
  );
  static const headlineSmall = CoreTextStyleToken._(
    'headline-small',
    _headlineSmall,
  );

  // ── Title ──────────────────────────────────────────────────────────
  static const titleLarge = CoreTextStyleToken._('title-large', _titleLarge);
  static const titleMedium = CoreTextStyleToken._('title-medium', _titleMedium);
  static const titleSmall = CoreTextStyleToken._('title-small', _titleSmall);

  // ── Body ───────────────────────────────────────────────────────────
  static const bodyLarge = CoreTextStyleToken._('body-large', _bodyLarge);
  static const bodyMedium = CoreTextStyleToken._('body-medium', _bodyMedium);
  static const bodySmall = CoreTextStyleToken._('body-small', _bodySmall);
  static const bodyXs = CoreTextStyleToken._('body-xs', _bodyXs);

  // ── Label ──────────────────────────────────────────────────────────
  static const labelXl2 = CoreTextStyleToken._('label-xl2', _labelXl2);
  static const labelXl = CoreTextStyleToken._('label-xl', _labelXl);
  static const labelLarge = CoreTextStyleToken._('label-large', _labelLarge);
  static const labelMedium = CoreTextStyleToken._('label-medium', _labelMedium);
  static const labelSmall = CoreTextStyleToken._('label-small', _labelSmall);
  static const labelXs = CoreTextStyleToken._('label-xs', _labelXs);

  // ── Code ───────────────────────────────────────────────────────────
  static const codeXs = CoreTextStyleToken._('code-xs', _codeXs);
  static const codeSm = CoreTextStyleToken._('code-sm', _codeSm);
  static const codeMd = CoreTextStyleToken._('code-md', _codeMd);

  /// All 22 role tokens in scale order (display → code) — the single
  /// source for per-role iteration (CSS variable emission, Tailwind config).
  static const List<CoreTextStyleToken> values = [
    displayLarge,
    displayMedium,
    displaySmall,
    headlineLarge,
    headlineMedium,
    headlineSmall,
    titleLarge,
    titleMedium,
    titleSmall,
    bodyLarge,
    bodyMedium,
    bodySmall,
    bodyXs,
    labelXl2,
    labelXl,
    labelLarge,
    labelMedium,
    labelSmall,
    labelXs,
    codeXs,
    codeSm,
    codeMd,
  ];
}

// ── Reader functions ─────────────────────────────────────────────────
// One per typography slot. Each pulls the matching field from a
// [CoreTypography] instance. Adding a token in [CoreTextStyles] without
// a matching reader (or matching field on [CoreTypography]) is caught
// at compile time.

CoreTextStyle _displayLarge(CoreTypography t) => t.displayLarge;
CoreTextStyle _displayMedium(CoreTypography t) => t.displayMedium;
CoreTextStyle _displaySmall(CoreTypography t) => t.displaySmall;
CoreTextStyle _headlineLarge(CoreTypography t) => t.headlineLarge;
CoreTextStyle _headlineMedium(CoreTypography t) => t.headlineMedium;
CoreTextStyle _headlineSmall(CoreTypography t) => t.headlineSmall;
CoreTextStyle _titleLarge(CoreTypography t) => t.titleLarge;
CoreTextStyle _titleMedium(CoreTypography t) => t.titleMedium;
CoreTextStyle _titleSmall(CoreTypography t) => t.titleSmall;
CoreTextStyle _bodyLarge(CoreTypography t) => t.bodyLarge;
CoreTextStyle _bodyMedium(CoreTypography t) => t.bodyMedium;
CoreTextStyle _bodySmall(CoreTypography t) => t.bodySmall;
CoreTextStyle _bodyXs(CoreTypography t) => t.bodyXs;
CoreTextStyle _labelXl2(CoreTypography t) => t.labelXl2;
CoreTextStyle _labelXl(CoreTypography t) => t.labelXl;
CoreTextStyle _labelLarge(CoreTypography t) => t.labelLarge;
CoreTextStyle _labelMedium(CoreTypography t) => t.labelMedium;
CoreTextStyle _labelSmall(CoreTypography t) => t.labelSmall;
CoreTextStyle _labelXs(CoreTypography t) => t.labelXs;
CoreTextStyle _codeXs(CoreTypography t) => t.codeXs;
CoreTextStyle _codeSm(CoreTypography t) => t.codeSm;
CoreTextStyle _codeMd(CoreTypography t) => t.codeMd;
