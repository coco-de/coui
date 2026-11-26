/// TokenScale — a *forward-only* name → value table for `coui_core`'s
/// numeric primitive namespaces (`CoreSpace`, `CoreSize`, `CoreIconSize`,
/// `CoreRadius`, `CoreStrokeWidth`, `CoreFontSize`, `CoreFontWeight`,
/// `CoreLineHeight`, `CoreLetterSpacing`, `CoreOpacity`, `CoreDuration`,
/// `CoreZIndex`).
///
/// ## Why forward-only — no value → name reverse index
///
/// A census of every numeric primitive value in this codebase found that
/// 166 of 257 values (64.6%) are shared by two or more namespaces — `16.0`
/// alone is `space/16`, `size/16`, `radius/16`, and `font-size/16`
/// simultaneously, and `CoreSpace` is a strict subset of `CoreSize` (every
/// space value also exists as a size value). A reverse index keyed on the
/// bare number can't tell those apart; the AST *can*, because it sees which
/// namespace the source actually wrote (`CoreSpace.space16` vs
/// `CoreRadius.radius16`) — but only if nothing tries to recover that
/// distinction from the number alone afterward. So this module exposes
/// exactly one direction: `Owner.member` (as read from source) → resolved
/// value. There is no `valueToRef` function, and there must never be one.
///
/// ## Alias resolution
///
/// A namespace member's initializer isn't always a literal — it can be a
/// same-class reference (`CoreDuration.fast = ms150;`) or a cross-class one
/// (`CoreIconSize.size24 = CoreSize.size24;`, itself possibly chained:
/// `CoreIconSize.defaultSize = size24;` → `CoreIconSize.size24` →
/// `CoreSize.size24`). [resolveNamespaces] follows these until it reaches a
/// literal, recording every name hopped through in `via` — the only record
/// of which token the source *actually named*, since the final resolved
/// value alone can't distinguish `CoreIconSize.defaultSize` from
/// `CoreSize.size24` (they're numerically identical by construction: "값을
/// 담은 것이 아니라 값이 사는 곳을 옮긴 것" — the size ladder doc comment).
library;

import 'dart:io';

import 'ast_value.dart';
import 'style_reader.dart';

/// One resolved forward-table entry.
final class TokenEntry {
  const TokenEntry({
    required this.owner,
    required this.member,
    required this.value,
    required this.ref,
    required this.via,
  });

  /// The namespace class, e.g. `CoreDuration`.
  final String owner;

  /// The member name as declared, e.g. `fast`.
  final String member;

  /// The terminal literal value (`double`, `int`, or `String` for the
  /// handful of non-numeric leaves like `CoreZIndex.zAuto`).
  final Object value;

  /// Figma variable path this token corresponds to, e.g.
  /// `Primitives/duration/150` — built from the namespace's Figma group
  /// plus the *terminal* member's leaf key, never the alias's own name (a
  /// token named `fast` still resolves to the `150` variable, because
  /// that's the primitive it terminates at).
  /// `Collection/group/leaf` — the Figma variable this value corresponds to,
  /// named with the collection it actually lives in (see
  /// [NamespaceSpec.collection]).
  final String? ref;

  /// Names hopped through to reach [value], nearest-alias-first — empty
  /// for a member whose initializer was already a literal. E.g.
  /// `CoreIconSize.defaultSize` → `via: ['size24', 'CoreSize.size24']`.
  final List<String> via;
}

/// Describes one namespace class to read: where its source lives, what the
/// Figma primitive group name is, and how to turn a member name into the
/// scale's leaf key (`space16` → `16`, `ms150` → `150`, `semiBold` →
/// `semibold`, or pass-through for members that are already semantic
/// names like `CoreLetterSpacing.tight`).
final class NamespaceSpec {
  const NamespaceSpec({
    required this.filePath,
    required this.className,
    required this.group,
    required this.leafKey,
    this.collection = 'Primitives',
    this.leafFromOwnName = false,
  });

  final String filePath;
  final String className;
  final String group;
  final String Function(String memberName) leafKey;

  /// Figma COLLECTION this namespace's variables live in.
  ///
  /// Not every group is in `Primitives`. `export_figma_tokens.dart` emits seven
  /// collections and files two of these groups outside the primitive ladder:
  /// `control-size/*` is a semantic dimension constraint (`Semantic/ Dimension`)
  /// and `icon-size/*` is a per-component tier (`Component`). A `ref` that says
  /// `Primitives` for either names a variable that is not there.
  ///
  /// Canonical form — the plugin canonicalizes both sides of its lookup
  /// (`canonicalCollection` in variables.ts), so `Semantic/Dimension` here
  /// and `Semantic/ Dimension` in the document are the same collection, as
  /// is a file that still spells it with an ordering prefix.
  final String collection;

  /// Key the leaf off the member's OWN name instead of the terminal it aliases.
  ///
  /// A `ref` normally follows the alias chain to its end, because that is where
  /// the primitive variable is: `CoreDuration.fast` resolves to `150` and the
  /// variable is `duration/150`, not `duration/fast`. `control-size` is the
  /// other shape — its variables are keyed by the tier (`control-size/md`) and
  /// its members alias a primitive step (`heightMd = CoreSize.size40`), so
  /// following the chain produced `control-size/size40`, a name in neither
  /// collection.
  final bool leafFromOwnName;
}

/// Strips a fixed `prefix` from a member name if present (lowercasing the
/// new leading character — `zAuto` → `Auto` → `auto`), otherwise returns it
/// unchanged. Covers both the numeric-suffix members (`space16` → `16`) and
/// the semantic-name members that share a namespace with them
/// (`CoreOpacity.hover` has no `opacity` prefix to strip, so it passes
/// through as `hover`).
String Function(String) _stripPrefix(String prefix) =>
    (name) => name.startsWith(prefix)
    ? _lowerFirst(name.substring(prefix.length))
    : name;

/// Every namespace this forward table covers. Paths are relative to
/// `packages/coui_core/lib/src/`. Group names match the `Primitives/<group>`
/// vocabulary `export_figma_tokens.dart` already emits for colours, so
/// schema v2's `ref` strings are drop-in compatible with the existing
/// tokens.figma.json alias vocabulary.
List<NamespaceSpec> buildCoreNamespaces() => [
  NamespaceSpec(
    filePath: 'spacing/spacing.dart',
    className: 'CoreSpace',
    group: 'space',
    leafKey: _stripPrefix('space'),
  ),
  NamespaceSpec(
    filePath: 'size/size.dart',
    className: 'CoreSize',
    group: 'size',
    leafKey: _stripPrefix('size'),
  ),
  // Panel / overlay bounds — a dialog's max width, a list's scroll ceiling.
  // Its own group (`layout/<n>`, `Primitives`), because a `Command` field
  // that states `CoreLayout.layout640` must route to `layout/640`, not to
  // whichever of `size/*` / `space/*` happens to hold the same number.
  NamespaceSpec(
    filePath: 'size/layout.dart',
    className: 'CoreLayout',
    group: 'layout',
    leafKey: _stripPrefix('layout'),
  ),
  // Semantic dimension constraint (CoUI_Size_Token_Specification §2-1)
  // — Button/TextField heights reference `CoreControlSize.heightMd`
  // etc. directly, so the reader must resolve this namespace for those
  // fields to stay routable. Leaf vocabulary matches the
  // `control-size/<tier>` names the tokens exporter emits.
  NamespaceSpec(
    filePath: 'size/control_size.dart',
    className: 'CoreControlSize',
    group: 'control-size',
    leafKey: _stripPrefix('height'),
    // `Semantic/ Dimension`, keyed by tier — `heightMd` aliases
    // `CoreSize.size40`, so following the chain named `control-size/size40`.
    collection: 'Semantic/Dimension',
    leafFromOwnName: true,
  ),
  // A-4 (icon-size group, added not folded — `core/design-tokens.md`'s
  // "size 토큰 함정" documents `CoreSize.scale` not working for Tailwind
  // `w-`/`h-` utilities; the Figma side has no such constraint, but the
  // *ladder* is still deliberately separate — `size/icon_size.dart`'s own
  // doc comment: "A separate ladder from CoreSize... naming the ladder is
  // what lets a new component pick a step instead of a number").
  NamespaceSpec(
    filePath: 'size/icon_size.dart',
    className: 'CoreIconSize',
    group: 'icon-size',
    // `Component` — a per-component tier group, not a primitive ladder.
    collection: 'Component',
    leafKey: _stripPrefix('size'),
    // `icon-size/<n>` is its own emitted group, aliased to `size/<n>`
    // (`export_figma_tokens.dart` A-4), so the leaf resolves in place.
  ),
  NamespaceSpec(
    filePath: 'shape/radius_scale.dart',
    className: 'CoreRadius',
    group: 'radius',
    leafKey: _stripPrefix('radius'),
  ),
  NamespaceSpec(
    filePath: 'shape/stroke_width.dart',
    className: 'CoreStrokeWidth',
    group: 'stroke',
    // `stroke0_5` → `0_5`, which is also the Figma variable key
    // (`stroke/0_5`): neither a Dart identifier nor a Figma variable name can
    // hold a `.`, so the member's own spelling is the key.
    leafKey: _stripPrefix('stroke'),
  ),
  NamespaceSpec(
    filePath: 'typography/font_size.dart',
    className: 'CoreFontSize',
    // Folded under `font/` by the tokens exporter.
    group: 'font/size',
    leafKey: _stripPrefix('s'),
  ),
  NamespaceSpec(
    filePath: 'typography/font_weight.dart',
    className: 'CoreFontWeight',
    group: 'font/weight',
    // `semiBold` → `semibold` — matches the existing hand-written map in
    // `export_figma_tokens.dart#_numericTokens` this reader replaces.
    leafKey: (s) => s.toLowerCase(),
  ),
  NamespaceSpec(
    filePath: 'typography/line_height.dart',
    className: 'CoreLineHeight',
    group: 'line-height',
    leafKey: _stripPrefix('h'),
  ),
  const NamespaceSpec(
    filePath: 'typography/letter_spacing.dart',
    className: 'CoreLetterSpacing',
    group: 'letter-spacing',
    leafKey: _identity,
  ),
  NamespaceSpec(
    filePath: 'effect/opacity_scale.dart',
    className: 'CoreOpacity',
    group: 'opacity',
    leafKey: _stripPrefix('opacity'),
  ),
  NamespaceSpec(
    filePath: 'motion/duration_token.dart',
    className: 'CoreDuration',
    group: 'duration',
    leafKey: _stripPrefix('ms'),
  ),
  NamespaceSpec(
    filePath: 'stacking/z_index_scale.dart',
    className: 'CoreZIndex',
    group: 'z-index',
    leafKey: _stripPrefix('z'),
  ),
];

/// Built fresh per call — a `leafKey` closure isn't a compile-time
/// constant, so this list can't be a top-level `const`.
final List<NamespaceSpec> coreNamespaces = buildCoreNamespaces();

String _identity(String s) => s;
String _lowerFirst(String s) =>
    s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

/// Reads every [NamespaceSpec] under [srcRoot] (default:
/// `packages/coui_core/lib/src` relative to [repoRoot]) and resolves each
/// class's `static const`/`static final` members into a forward table keyed
/// by `Owner.member`.
///
/// Throws [StateError] if a spec's class can't be found (a missing
/// namespace file is a build-breaking configuration error, not a
/// zero-results case a caller should silently tolerate) or if resolution
/// exceeds [maxHops] (default 4 — twice the "최대 2 hop" the census found,
/// so a legitimate new 3-hop alias doesn't get mistaken for a cycle while a
/// genuine `A = B; B = A;` cycle still terminates instead of looping
/// forever).
Map<String, TokenEntry> resolveNamespaces({
  required String repoRoot,
  String? srcRoot,
  int maxHops = 4,
}) {
  final root = srcRoot ?? '$repoRoot/packages/coui_core/lib/src';
  final classesByName = <String, DiscoveredClass>{};
  for (final spec in coreNamespaces) {
    final path = '$root/${spec.filePath}';
    final source = File(path).readAsStringSync();
    final classes = readCompilationUnit(path, source);
    if (classes == null) {
      throw StateError('Failed to parse namespace file: $path');
    }
    final match = classes.where((c) => c.name == spec.className).toList();
    if (match.isEmpty) {
      throw StateError(
        'Class ${spec.className} not found in $path — namespace spec is '
        'stale (file moved, or class renamed).',
      );
    }
    classesByName[spec.className] = match.single;
  }

  final entries = <String, TokenEntry>{};
  for (final spec in coreNamespaces) {
    final cls = classesByName[spec.className]!;
    for (final member in cls.staticMembers) {
      if (member.isPrivate) continue;
      final resolved = _resolve(
        classesByName,
        owner: spec.className,
        member: member.name,
        via: const [],
        hopsRemaining: maxHops,
      );
      if (resolved == null) continue; // Non-numeric / unresolved — skip.
      final leaf = spec.leafKey(
        spec.leafFromOwnName ? member.name : resolved.terminalMember,
      );
      entries['${spec.className}.${member.name}'] = TokenEntry(
        owner: spec.className,
        member: member.name,
        value: resolved.value,
        ref: '${spec.collection}/${spec.group}/$leaf',
        via: resolved.via,
      );
    }
  }
  return entries;
}

final class _Resolved {
  const _Resolved(this.value, this.terminalMember, this.via);
  final Object value;
  final String terminalMember;
  final List<String> via;
}

_Resolved? _resolve(
  Map<String, DiscoveredClass> classesByName, {
  required String owner,
  required String member,
  required List<String> via,
  required int hopsRemaining,
}) {
  if (hopsRemaining < 0) {
    throw StateError(
      'Alias chain too deep resolving $owner.$member (via: $via) — likely '
      'a cycle.',
    );
  }
  final cls = classesByName[owner];
  if (cls == null) return null; // Reference to an unmodelled namespace.
  final target = cls.staticMembers.where((m) => m.name == member).toList();
  if (target.isEmpty) return null;
  final value = target.single.value;
  return switch (value) {
    LiteralValue(:final value) when value is num => _Resolved(
      value,
      member,
      via,
    ),
    LiteralValue(:final value) when value is String => _Resolved(
      value,
      member,
      via,
    ),
    RefValue(owner: null, :final member) => _resolve(
      classesByName,
      owner: owner,
      member: member,
      via: [...via, member],
      hopsRemaining: hopsRemaining - 1,
    ),
    RefValue(:final owner, :final member) when owner != null => _resolve(
      classesByName,
      owner: owner,
      member: member,
      via: [...via, '$owner.$member'],
      hopsRemaining: hopsRemaining - 1,
    ),
    _ => null, // Composite (record/call) value — not a scalar primitive.
  };
}
