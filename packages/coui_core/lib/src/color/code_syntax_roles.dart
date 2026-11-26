/// The colour a highlighted span of code takes — one table for both
/// platforms.
///
/// A highlighter hands back spans tagged with TextMate scopes
/// (`keyword.control.dart`, `string.quoted.double.json`, …). Two things turn
/// a scope into a colour, and this file is the only place either is written:
///
/// - [CoreSyntaxScopes.roles] — which scope prefix is which
///   [CoreSyntaxRole];
/// - [CoreSyntaxRole.token] — which colour slot each role reads.
///
/// Splitting the two is what makes a slot a one-line change: a role names
/// *what a span is*, a slot names *what colour that is*, and nothing between
/// them is restated per platform. Flutter and Web both read this table and
/// resolve the slot through their own colour path.
///
/// Whether the role colours apply at all depends on the face the code sits
/// on — [CoreSyntaxFaces.admits] answers it, for both platforms.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';

/// What a highlighted span of code is, for colouring.
///
/// Eight roles. [punctuation] and [comment] read the same slot today but are
/// different roles on purpose: the day comments get a slot of their own,
/// only [comment] moves.
enum CoreSyntaxRole {
  /// Text with no colour of its own — variables and anything the highlighter
  /// did not name. It is the snippet's own ink (its `codeTextStyle` colour,
  /// `onSurface` by default), not a slot, so it follows a caller who restates
  /// the code colour and is exactly what unscoped text already inherits.
  plain(null),

  /// Keywords, storage and control words, and the language's own constants
  /// (`true`, `false`, `null`).
  keyword(CoreColors.syntaxKeyword),

  /// Type and class names, and numbers.
  type(CoreColors.syntaxType),

  /// Function and method names, and the keys of an object or mapping.
  function(CoreColors.syntaxFunction),

  /// String literals.
  string(CoreColors.syntaxString),

  /// Punctuation, operators and brackets.
  punctuation(CoreColors.onSurfaceVariant),

  /// Comments.
  ///
  /// `onSurfaceVariant`, not the quieter `onSurfaceSubtle`: the third text
  /// tier measures 4.45:1 on `surfaceContainerLow` in light, under the 4.5
  /// that code text owes, and `onSurfaceVariant` clears it in all four modes.
  comment(CoreColors.onSurfaceVariant),

  /// Text the grammar marks as an error.
  ///
  /// `onErrorContainer`, not `error`: `error` measures 4.47:1 on
  /// `surfaceContainerLow` in light, under 4.5.
  invalid(CoreColors.onErrorContainer);

  const CoreSyntaxRole(this.token);

  /// The colour slot this role reads, or `null` for [plain], which reads the
  /// snippet's own ink rather than a slot.
  final CoreColorToken? token;
}

/// The scope-prefix → [CoreSyntaxRole] table.
///
/// A scope matches a key by dotted prefix: `keyword.control.dart` is matched
/// by `keyword.control` and by `keyword`. The highlighter takes, for each
/// scope of a span from the outermost in, the most specific key that matches;
/// the first scope with any match decides. Three consequences shape the
/// table:
///
/// - **A key more specific than its parent overrides it** — `keyword.operator`
///   (punctuation) over `keyword`, `variable.language` over `variable`,
///   `support.type.property-name` over `support.type`.
/// - **There are no broad keys.** `meta`, `source`, `other` and `entity.name`
///   wrap spans that mean something else; a key on any of them would win
///   (outermost first) over the scope inside it and paint the wrong thing.
/// - **An outer scope wins over what it holds** — a string stays one colour
///   through an interpolation, and a comment through the identifiers inside
///   it.
///
/// A span matching nothing takes the fallback, which is [CoreSyntaxRole.plain].
abstract final class CoreSyntaxScopes {
  /// The table, scope prefix → role.
  static const Map<String, CoreSyntaxRole> roles = {
    // ── plain ──
    'variable': CoreSyntaxRole.plain,

    // ── keyword ──
    'keyword': CoreSyntaxRole.keyword,
    'storage': CoreSyntaxRole.keyword,
    'constant.language': CoreSyntaxRole.keyword,
    'variable.language': CoreSyntaxRole.keyword,

    // ── type ──
    'entity.name.type': CoreSyntaxRole.type,
    'entity.name.class': CoreSyntaxRole.type,
    'support.class': CoreSyntaxRole.type,
    'support.type': CoreSyntaxRole.type,
    'constant.numeric': CoreSyntaxRole.type,
    // The bundled JSON grammar scopes every number as one of these two, so a
    // JSON number would read as an error. Both are numbers in practice.
    'invalid.illegal.expected-dictionary-separator': CoreSyntaxRole.type,
    'invalid.illegal.expected-array-separator': CoreSyntaxRole.type,

    // ── function ──
    'entity.name.function': CoreSyntaxRole.function,
    'support.function': CoreSyntaxRole.function,
    // An object key (JSON) and a mapping key (YAML).
    'support.type.property-name': CoreSyntaxRole.function,
    'entity.name.tag': CoreSyntaxRole.function,

    // ── string ──
    'string': CoreSyntaxRole.string,
    'constant.character.escape': CoreSyntaxRole.string,

    // ── punctuation ──
    'keyword.operator': CoreSyntaxRole.punctuation,
    'punctuation': CoreSyntaxRole.punctuation,
    // The angle brackets of a Dart type argument list.
    'other.source': CoreSyntaxRole.punctuation,

    // ── comment ──
    'comment': CoreSyntaxRole.comment,

    // ── invalid ──
    'invalid': CoreSyntaxRole.invalid,
  };

  /// The scope prefixes that map to [role], in table order.
  static List<String> scopesOf(CoreSyntaxRole role) => [
    for (final entry in roles.entries)
      if (entry.value == role) entry.key,
  ];
}

/// The faces the syntax role colours are certified on — one rule for both
/// platforms.
///
/// A role colour is an absolute slot ([CoreSyntaxRole.token]), tuned against
/// the tones code is shown on rather than against whatever face a caller
/// states. The contrast audit holds the four syntax slots to 4.5:1 on exactly
/// [tones], and the rest of the role slots (`onSurfaceVariant`,
/// `onErrorContainer`) clear the same bar on every one of them in all four
/// modes. A solid role fill (`primary` … `outline`) is not one of those tones:
/// the slots read 1.0–3.4:1 there, and only the code ink is repainted for it.
///
/// The bar is CoUI's own colour source (`CouiColorPresets.source`), in light,
/// dark and both high-contrast variants. A brand on the standard mapping brings
/// its own palette, and the audit holds some of its role slots under 4.5:1 on
/// some of these tones in its baseline — a rule decided on token identity
/// cannot see that, so it admits those tones all the same.
///
/// So the roles apply on an admitted face and nowhere else. [admits] is the
/// whole decision, and it is made on the face's identity alone — a plain,
/// fully opaque token whose slot is in [tones]. It reads no theme and
/// computes no contrast, which is what Web needs: Web emits token names and
/// lets the browser resolve them, so it cannot ask a scheme anything.
///
/// A face that is not admitted — a solid role token, a raw colour (a
/// `CoreColor.transparent` face included, which shows an unknown page), or a
/// token laid over at less than full opacity — paints every role except
/// [CoreSyntaxRole.plain] in the snippet's own ink, i.e. highlighting is off
/// and the text reads as one colour. Each platform keeps the table and the
/// slot resolution it already has; neither restates [tones].
abstract final class CoreSyntaxFaces {
  /// The tones the role colours are certified on: the page, the chrome and
  /// card rungs, the grey control face, and the four status containers a
  /// code span lands on inside an alert or a callout.
  ///
  /// The same eight the contrast audit holds the syntax slots to (its
  /// `_kSyntaxTones`); a test reads the audit and fails if the two differ.
  static const List<CoreColorToken> tones = [
    CoreColors.surface,
    CoreColors.surfaceContainerLow,
    CoreColors.surfaceContainer,
    CoreColors.surfaceContainerHigh,
    CoreColors.errorContainer,
    CoreColors.successContainer,
    CoreColors.warningContainer,
    CoreColors.infoContainer,
  ];

  /// Whether the role colours apply on [face]: it is a plain token at full
  /// opacity whose slot is one of [tones].
  ///
  /// `false` means every role but [CoreSyntaxRole.plain] takes the snippet's
  /// own ink instead of its slot.
  static bool admits(CoreColor face) {
    final token = face.token;
    return token != null && face.opacity == 1 && tones.contains(token);
  }
}
