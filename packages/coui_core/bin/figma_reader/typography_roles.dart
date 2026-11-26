/// Reads `CoreTypography.coui`'s per-role metrics so the Figma plugin can
/// render text at the size the role actually is.
///
/// Why this exists: `components.json` carries the role NAME on every text
/// style (`{"role": "bodySmall"}`) and nothing else — the metrics live on
/// `CoreTypography`, which the component-contract reader never opens. The
/// plugin's `textLabelOpts` therefore fell back to a hardcoded 14 for any
/// style that did not override `fontSize`, which was **all of them**:
/// `headlineLarge` and `labelSmall` came out the same size on the canvas.
///
/// Nothing caught it. The literal ratchet does not count a fallback inside a
/// helper; the field-coverage guard sees the role key present and calls the
/// field reached; the runtime harness sees a number and binds it. A guard can
/// only find a value that is wrong, not a value that is uniformly wrong.
///
/// The table is emitted once at the document root rather than inlined per
/// style: one entry per role against hundreds of references, and a role is a
/// property of the type scale, not of the component that happens to use it.
library;

import 'dart:io';

import 'ast_value.dart';
import 'emit.dart';
import 'style_reader.dart';

/// One typography role's paint-ready metrics.
///
/// Every key is always written, `null` when the role does not state it, so
/// the plugin reads one shape for every role rather than telling an absent
/// key from a key that was never exported.
final class RoleMetrics {
  /// Metrics for one role, each `null` when the role leaves it unstated.
  const RoleMetrics({
    required this.fontSize,
    required this.lineHeight,
    required this.fontWeight,
    required this.letterSpacing,
    required this.fontFamily,
    required this.lineHeightPx,
  });

  /// Font size in logical px.
  final num? fontSize;

  /// Line-height multiplier; `null` on a role that states only a fixed box
  /// ([lineHeightPx]) — the code roles.
  final num? lineHeight;

  /// Font weight (CSS 100–900).
  final num? fontWeight;

  /// Tracking in em.
  final num? letterSpacing;

  /// The family the role names (`CoreFontFamily.mono` for the code roles);
  /// `null` when it names none — the text face both platforms draw it in.
  final String? fontFamily;

  /// Fixed line box in logical px (`CoreLineBox`). Wins over [lineHeight]
  /// when both are set, the same precedence `CoreTextStyle` gives it.
  final num? lineHeightPx;

  /// The role's entry in the document's `typography` table.
  Map<String, dynamic> toJson() => {
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'fontWeight': fontWeight,
    'letterSpacing': letterSpacing,
    'fontFamily': fontFamily,
    'lineHeightPx': lineHeightPx,
  };
}

/// Parses `typography_scale.dart` and returns `{roleName: metrics}` for the
/// `CoreTypography.coui` baseline scale.
///
/// Values arrive as references (`CoreFontSize.s14`, `CoreLineBox.px21`,
/// `CoreFontFamily.mono`), resolved through [ctx] — the token table and
/// class registry every component field resolves through. The registry half
/// matters here: neither `CoreFontFamily` (strings, no primitive ladder) nor
/// `CoreLineBox` (a px box no primitive carries) is a token namespace, and
/// making either one would hand readers a `ref` to a variable the tokens
/// export never creates. A reference that resolves to nothing yields `null`
/// for that one field rather than dropping the role: a role with a known
/// size and an unknown letter-spacing is still worth far more than no role
/// at all.
Map<String, RoleMetrics> readTypographyRoles({
  required String srcRoot,
  required EmitContext ctx,
}) {
  final file = File('$srcRoot/typography/typography_scale.dart');
  if (!file.existsSync()) return const {};
  // Reuses the shared reader instead of walking the AST here. Two reasons, and
  // the second is the one that bit: `readCompilationUnit` already turns an
  // initializer into an `AstValue`, and it is the layer that absorbs analyzer's
  // API churn (`check_analyzer_ast_churn.sh` guards exactly that). A local walk
  // reached for `ClassDeclaration.body.members`, which analyzer 10 no longer
  // offers on the type it returns — the exporter stopped compiling, and the
  // freshness guard reported "cannot judge" rather than a wrong number.
  final classes = readCompilationUnit(file.path, file.readAsStringSync());
  if (classes == null) return const {};

  // Matched by name, so a retired table beside it (`couiV1`) is never read
  // as the scale.
  CallValue? scale;
  for (final cls in classes) {
    for (final m in cls.staticMembers) {
      if (m.name == 'coui' && m.value is CallValue) {
        scale = m.value as CallValue;
      }
    }
  }
  if (scale == null) return const {};

  Object? resolve(AstValue? value) => value == null
      ? null
      : resolveScalarValue(ctx, value, currentClass: 'CoreTypography');

  final out = <String, RoleMetrics>{};
  for (final entry in scale.namedArgs.entries) {
    final style = entry.value;
    if (style is! CallValue) continue;
    final args = style.namedArgs;
    out[entry.key] = RoleMetrics(
      fontSize: _asNum(resolve(args['fontSize'])),
      lineHeight: _asNum(resolve(args['lineHeight'])),
      fontWeight: _asNum(resolve(args['fontWeight'])),
      letterSpacing: _asNum(resolve(args['letterSpacing'])),
      fontFamily: _asString(resolve(args['fontFamily'])),
      lineHeightPx: _asNum(resolve(args['lineHeightPx'])),
    );
  }
  return out;
}

/// A resolved value can be a number or a string (a scale key, a family
/// name), so each metric takes only its own kind and leaves the rest null
/// rather than stringifying something into a font size.
num? _asNum(Object? value) => value is num ? value : null;

String? _asString(Object? value) => value is String ? value : null;
