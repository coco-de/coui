/// Color scheme for the Web theme.
///
/// As of Epic #1415 (Story 17 Phase 2), Web aligns with Flutter and
/// exposes `theme.colorScheme` as a [CoreColorScheme] from `coui_core`.
/// Each field is a [CoreColor] that carries its semantic token; Web
/// callers select rendering by:
///
/// - Tailwind class composition — `'bg-${cs.primary}'` (Dart string
///   interpolation calls [CoreColor.toString], which renders the token
///   name `'primary'` or `'on-surface/60'`).
/// - Inline CSS via `Styles.raw` — `cs.onSurface?.toValue()` (returns
///   `'var(--color-on-surface)'` or `'rgba(...)'`).
///
/// `.toValue()` lives in `coui_web/lib/src/util/core_to_css.dart`.
///
/// The legacy string-token `ColorScheme` (60+ fields like
/// `final String primary = 'primary'`) has been deleted; `ColorScheme`
/// is now a typedef for [CoreColorScheme] so any `cw.ColorScheme`
/// annotations across the codebase still resolve.
library;

import 'package:coui_core/coui_core.dart';

/// Re-export of [CoreColorScheme] under the historical `ColorScheme`
/// name. Components, examples, and apps that import
/// `package:coui_web/coui_web.dart` keep the same identifier.
typedef ColorScheme = CoreColorScheme;
