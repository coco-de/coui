// Exports CoUI design tokens to `build/tokens.figma.json` for the
// `tools/figma-token-sync` Figma plugin (code → Figma, one-way).
//
// Run: `dart run packages/coui_core/bin/export_figma_tokens.dart`
// or via melos: `melos run export:figma-tokens`.
//
// Output schema maps 1:1 to the Figma Variables model:
//   { collections: [ { name, modes,
//       variables: [ { name, type, valuesByMode, description?,
//                      hiddenFromPublishing? } ] } ] }
//   `hiddenFromPublishing` is carried by colour primitives only — the
//   library brand's and every shared group's — see
//   `_stampRampPublishVisibility` for the rule that sets it.
// - Primitives collection (mode "Value"): colors + numeric scales, plus the
//   duration/easing semantic alias tier (`duration/alias/*`,
//   `easing/alias/*`) — each aliases a raw `duration/<n>` or `easing/<key>`
//   variable in this same collection rather than duplicating its value.
//   Figma variable aliases are not restricted to cross-collection use (the
//   focus-ring color aliases below already alias into the Semantic
//   collection from here), so same-collection self-aliasing needs no
//   separate collection.
// - Semantic collection (modes "Light"/"Dark"/"HC Light"/"HC Dark"):
//   CoreColorScheme vocabulary, each mode value aliasing a Primitives color
//   — by value into the brand's own colours where it resolves to one, or,
//   for a slot a shared group links (`_kSharedColourGroups`), by name into
//   that group (`color/<namespace>/...`). The brand's shadow colours
//   (`effect/shadow/<step>/<layer>`) are the one exception: each is a colour
//   at its layer's own alpha, which an alias cannot carry, so they are
//   written as values — see `_brandShadowColorRows`.
//
//   Figma variable modes have no cascade — a mode that omits a value for a
//   slot is *unresolved*, not "falls through to a sibling mode" the way the
//   Web `@media (prefers-contrast: more)` block only restates the slots
//   the source's raise writes (`PrimitiveCssGenerator.semanticVarsRaised`,
//   read by `coui_web/lib/src/base/theme_config.dart`). So every mode here —
//   including the two high-contrast ones — carries the full vocabulary; on
//   the slots high contrast leaves alone, HC Light/HC Dark simply restate
//   the same alias Light/Dark already use.
//
// - Content collections (`Semantic/ Content`, `Semantic/ Content Status`): the
//   colour a glyph takes from the slot frame it sits in. A glyph's stroke is
//   bound to `content/current` and the slot frame pins one mode of the collection;
//   each mode aliases the Semantic colour slot of the same name, and the status
//   tones go one alias further through `Semantic/ Content Status`. See
//   `_buildContentColors`.
//
// SSOT: `coui_core` tokens. Colors come from the same `PrimitiveCssGenerator`
// the web build uses, so Figma stays consistent with `--coui-*` CSS vars.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';

import 'figma_brands/brands.dart';
import 'figma_reader/typography_modes.dart';

/// The brands this export ships to Figma (`figma_brands/brands.dart`).
///
/// The first is the **library** brand: its colours are the Figma library's one
/// `Semantic/ Color · <name>` collection and its `color/<id>/…` primitives
/// (`_buildBrandCollections`). Every other brand is a **brand value table**
/// (`_buildBrandTable`, written to `brands.json`): the values that differ from
/// the library brand, which the plugin writes into an extension of that one
/// collection in a consumer file. A brand therefore adds no collection and no
/// primitive to the library — adding one is one more entry in the registry,
/// and `brands.json` grows by one table.
final CoreBrandRegistry _kBrands = kFigmaBrands;

/// A colour group that belongs to no brand: its primitives are the same in
/// every brand, so they are written once under the brand-less [namespace]
/// (`color/<namespace>/...`), and a brand's slots reach them by name.
class _SharedColourGroup {
  const _SharedColourGroup({
    required this.namespace,
    required this.triplets,
    required this.linksFor,
  });

  /// The reserved, brand-less path segment the group's primitives live
  /// under — no brand may take it as its id or as a primitive family.
  final String namespace;

  /// Primitive name (`<namespace>/...`) → `'R G B'`, in the group's own
  /// order.
  final Map<String, String> triplets;

  /// The links one mode states: slot CSS key → primitive name.
  final Map<String, String> Function(
    CoreBrightness brightness, {
    required bool highContrast,
  })
  linksFor;
}

/// Every shared colour group, in the order their rows are written.
///
/// - **category** — the classification colours. Every category slot is
///   linked but the strong label (`on-category-<hue>`), which reads the
///   brand's own white or black by value.
/// - **syntax** — code highlighting. Keyword, type and string are linked;
///   function is not, because it reads a step of the brand's own info ramp
///   and so aliases the brand's primitive by value like any brand slot.
///   High contrast reads the same tones as the normal mode of its
///   brightness.
final _kSharedColourGroups = [
  _SharedColourGroup(
    namespace: CoreCategoryPalette.namespace,
    triplets: PrimitiveCssGenerator.categoryPrimitiveTriplets(),
    linksFor: CoreCategoryPalette.primitiveLinks,
  ),
  _SharedColourGroup(
    namespace: CoreSyntaxPalette.namespace,
    triplets: PrimitiveCssGenerator.syntaxPrimitiveTriplets(),
    linksFor: (brightness, {required highContrast}) =>
        CoreSyntaxPalette.primitiveLinks(brightness),
  ),
];

/// One brand's Primitives-colour rows (folded into the single shared
/// `_kCollPrimitives` collection by `main`, not a collection of their own —
/// see `_buildBrandCollections`) plus its own Semantic/Color collection,
/// and what the rest of the file needs from it: the alias table other
/// collections (Effect's focus-ring color, in particular) reach into, and
/// the counters the integrity gate reports on.
class _BrandCollections {
  const _BrandCollections({
    required this.brand,
    required this.semanticColorCollectionName,
    required this.primitives,
    required this.semantics,
    required this.tripletToAlias,
    required this.tripletCounts,
    required this.unresolved,
    required this.ambiguous,
    required this.sharedLinked,
    required this.linkMismatches,
    required this.danglingLinks,
    required this.unlinked,
    required this.reservedPrimitives,
    required this.shadowColorMismatches,
  });

  final CoreBrand brand;
  final String semanticColorCollectionName;
  final List<Map<String, dynamic>> primitives;
  final List<Map<String, dynamic>> semantics;
  final Map<String, String> tripletToAlias;
  final Map<String, int> tripletCounts;
  final List<String> unresolved;
  final List<String> ambiguous;

  /// Shared group namespace → mode → how many Semantic slots alias that
  /// group by name in that mode.
  final Map<String, Map<String, int>> sharedLinked;

  /// Slots linked by name whose own value is not the value of the
  /// primitive they link to, and slots two shared groups both link.
  final List<String> linkMismatches;

  /// Links to a primitive name no shared group carries.
  final List<String> danglingLinks;

  /// Links whose slot this brand's Semantic vocabulary does not carry, so
  /// no row was routed by them.
  final List<String> unlinked;

  /// This brand's primitive CSS variables that sit under a reserved shared
  /// namespace.
  final List<String> reservedPrimitives;

  /// Shadow-colour rows whose value is not the mode's `color/shadow` at the
  /// layer's derived alpha, or that are missing or extra.
  final List<String> shadowColorMismatches;
}

/// A primitive colour path, namespaced under [brandId] so every brand's
/// primitives can share one Figma collection without colliding on name —
/// `_colorPathFromCssVar` alone would give two brands the identical
/// `color/neutral/100`. The result is `color/<brandId>/<name>` for the
/// source's own `'<family>/<step>'` name (see `_colorPathFromCssVar`).
///
/// A shared group never goes through here: a category name would come out
/// as `color/coui/category/red-light-fill`. Shared rows have their own
/// [_sharedColorPath].
String _brandColorPath(String brandId, String cssVar) =>
    _colorPathFromCssVar(cssVar).replaceFirst('color/', 'color/$brandId/');

/// The path of a brand-less primitive colour — `category/red/light-fill`
/// -> `color/category/red/light-fill`, `syntax/purple/light` ->
/// `color/syntax/purple/light`, no brand segment.
///
/// The one path both the shared rows and every alias into them are
/// written with, so a row and the link that names it cannot be spelled
/// two ways.
String _sharedColorPath(String name) => 'color/$name';

/// The prefix every brand-colour shadow row is named under —
/// `effect/shadow/<step>/<layer>`.
const _kBrandShadowPrefix = 'effect/shadow/';

/// One mode's shadow-colour rows for a brand — a row per layer of every
/// step of the shadow scale, named `effect/shadow/<step>/<layer>` (layer
/// numbered from 0), each the mode's `shadow` slot at the layer's own
/// alpha. [dark] says which brightness the mode reads: a dark mode draws
/// each layer at its alpha × `CoreShadow.darkStrength`, capped at 1 — the
/// strength both platforms' geometry seat applies
/// (`CoreSurfaceGeometryConstraint.shadow`).
///
/// The one place a brand shadow colour is derived: the brand's Semantic
/// collection writes these values, and the integrity gate re-derives them
/// to check what was written. The row list follows the scale in code, so a
/// step or layer added there arrives here without an edit.
///
/// Each value is a colour, not an alias: an alias cannot carry an alpha,
/// and every layer is the shadow colour at its own strength. Each entry is
/// `{name, value}`; the caller spreads the values over the modes.
List<Map<String, dynamic>> _brandShadowColorRows(
  ResolvedColorScheme scheme, {
  required bool dark,
}) {
  final color = scheme.shadow;
  final rows = <Map<String, dynamic>>[];
  for (final step in _kShadowScale.entries) {
    for (final (i, layer) in step.value.indexed) {
      final alpha = dark
          ? math.min<double>(1, layer.opacity * CoreShadow.darkStrength)
          : layer.opacity;
      rows.add({
        'name': '$_kBrandShadowPrefix${step.key}/$i',
        'value': _rgba(color.argb, alpha),
      });
    }
  }

  return rows;
}

/// A brand's resolved scheme in every Semantic mode, by mode name — one walk
/// over [_kSemanticModeAxes], so a mode's name and the scheme that supplies
/// its values cannot name different modes.
Map<String, ResolvedColorScheme> _schemesByMode(CoreSchemeSource source) => {
  for (final (mode, brightness, highContrast) in _kSemanticModeAxes)
    mode: switch ((brightness, highContrast)) {
      (.light, false) => source.light(),
      (.dark, false) => source.dark(),
      (.light, true) => source.highContrastLight(),
      (.dark, true) => source.highContrastDark(),
    }.resolved(brightness),
};

/// Each mode's Semantic colour slots as the CSS vocabulary writes them
/// (`--coui-<slot>` -> `'R G B'`).
Map<String, Map<String, String>> _semanticCssVarsByMode(
  Map<String, ResolvedColorScheme> schemesByMode,
) => {
  for (final MapEntry(key: mode, value: scheme) in schemesByMode.entries)
    mode: PrimitiveCssGenerator.semanticVars(scheme),
};

/// Every mode's shadow-colour rows (`_brandShadowColorRows`) for one brand.
Map<String, List<Map<String, dynamic>>> _shadowRowsByMode(
  Map<String, ResolvedColorScheme> schemesByMode,
) => {
  for (final (mode, brightness, _) in _kSemanticModeAxes)
    mode: _brandShadowColorRows(
      schemesByMode[mode]!,
      dark: brightness == CoreBrightness.dark,
    ),
};

/// The links the shared groups state in every Semantic mode: mode -> slot ->
/// (shared namespace, primitive name). They name tones of a group, not a
/// brand's colours, so they are the same for every brand.
///
/// A slot two groups both link is appended to [conflicts].
Map<String, Map<String, (String, String)>> _sharedLinksByMode(
  List<String> conflicts,
) {
  final out = <String, Map<String, (String, String)>>{};
  for (final (mode, brightness, highContrast) in _kSemanticModeAxes) {
    final links = <String, (String, String)>{};
    for (final group in _kSharedColourGroups) {
      final groupLinks = group.linksFor(
        brightness,
        highContrast: highContrast,
      );
      for (final MapEntry(key: slot, value: link) in groupLinks.entries) {
        final claimed = links[slot];
        if (claimed != null) {
          conflicts.add(
            'color/$slot @ $mode linked by both ${claimed.$1} and '
            '${group.namespace}',
          );
        }
        links[slot] = (group.namespace, link);
      }
    }
    out[mode] = links;
  }

  return out;
}

/// Builds the LIBRARY brand's Primitives-colour rows and its Semantic/Color
/// collection — called for the registry's first brand only. Every other brand
/// is a value table over that collection (`_buildBrandTable`), so it adds no
/// collection and no primitive to the library.
///
/// Semantic/Color is a collection of its own (`Semantic/ Color ·
/// CoUI`, not a second tier, and not folded into that collection's
/// `modes` list alongside Light/Dark/HCLight/HCDark — the
/// `Semantic/ Dimension` collection above already made the
/// modes-vs-collections call for a hypothetical density axis (spec §5):
/// combining an orthogonal axis into one collection's mode list multiplies
/// modes combinatorially, brand × brightness × contrast, and Figma
/// Variable modes have no cascade (see this file's header), so every mode
/// would have to restate the full semantic vocabulary again).
///
/// Primitives colours are not a collection of their own — they fold into
/// `main`'s single shared `_kCollPrimitives` collection, namespaced by path
/// (`color/<brandId>/...`). Nothing in a design ever binds a node directly to
/// a Primitives colour, only to a Semantic one.
///
/// A brand that is not the library brand states its colours as a table of
/// the values that differ from this collection (`_buildBrandTable`): a
/// consumer file extends this one collection and the plugin writes the table
/// into the extension's overrides, so a second brand needs no collection of
/// its own and the library never carries a lagging copy of the vocabulary.
///
/// The one exception to the brand namespace is the shared groups
/// (`_kSharedColourGroups`, written by `main`): their colours are the same
/// in every brand, so they are stated once, outside every brand's path, and
/// the library brand's linked slots reach them by name — each group's own
/// link table — not by value. A value match finds a colour, not a name:
/// where a group states one value under two names (yellow's light
/// on-container is also its dark outline) it cannot tell which one a slot
/// means, and a value a
/// brand's ramp also held would land on that ramp.
_BrandCollections _buildBrandCollections(CoreBrand brand) {
  final source = brand.source;
  final semanticColorCollectionName =
      '$_kCollSemanticColor · ${brand.displayName}';

  final primitives = <Map<String, dynamic>>[];
  final semantics = <Map<String, dynamic>>[];

  // --- Primitive colors, namespaced under this brand's own path ----------
  // Same map the web CSS build emits: { '--coui-neutral-100': 'R G B', ... }
  // — CoUI's 67 fixed steps, or a generated palette's 64 scale names.
  final primitiveColors = PrimitiveCssGenerator.primitiveVars(source);
  // A shared namespace is also a CSS name space — `--coui-category-*` is
  // the category vocabulary's own (`CoreCategorySlot.cssName`), and
  // `--coui-syntax-*` holds the syntax slots: a brand family named after a
  // shared namespace would emit its primitives under the same names.
  final reservedPrimitives = [
    for (final cssVar in primitiveColors.keys)
      for (final group in _kSharedColourGroups)
        if (cssVar.startsWith('--coui-${group.namespace}-')) cssVar,
  ];
  // triplet -> "Primitives/color/<brandId>/<path>" for semantic aliasing.
  // Two brands landing on the same triplet (most brands share a pure
  // white/black) is normal and not ambiguous here — they are two distinct
  // variables (different, brand-namespaced paths) that happen to hold the
  // same value, not one variable two brands are fighting to own.
  // First-wins *within this brand's own path prefix*: `tripletCounts`
  // below catches the case that would make that silent.
  final tripletToAlias = <String, String>{};
  final tripletCounts = <String, int>{};
  primitiveColors.forEach((cssVar, triplet) {
    final path = _brandColorPath(brand.id, cssVar);
    primitives.add(_colorVariable(path, triplet, mode: 'Value'));
    tripletToAlias[triplet] ??= '$_kCollPrimitives/$path';
    tripletCounts[triplet] = (tripletCounts[triplet] ?? 0) + 1;
  });

  // --- Semantic colors (Light/Dark/HCLight/HCDark, alias to primitives) --
  // One walk over `_kSemanticModeAxes`, so a mode's name, the scheme that
  // supplies its values and the shared links it states cannot name
  // different modes — or drift from the collection's `modes` array.
  // The BRAND's source, not a standard reading of some palette — CoUI's
  // own mapping and Unibook's dark-mode overrides both live on the brand.
  final schemesByMode = _schemesByMode(source);
  final semanticCssVarsByMode = _semanticCssVarsByMode(schemesByMode);
  // Mode -> slot -> (shared namespace, primitive name).
  final linkMismatches = <String>[];
  final sharedLinksByMode = _sharedLinksByMode(linkMismatches);
  // A slot a shared group links is routed by KEY before any value lookup:
  // the link names the tone the group's table chose for that slot in that
  // mode, and a value lookup can only find whichever primitive happens to
  // hold the same colour. A link always aliases, so it is proven by value
  // instead: the slot's own colour must be the linked primitive's.
  final sharedTriplets = {
    for (final group in _kSharedColourGroups) ...group.triplets,
  };
  final sharedLinked = {
    for (final group in _kSharedColourGroups)
      group.namespace: {for (final mode in _kSemanticModes) mode: 0},
  };
  for (final cssVar in semanticCssVarsByMode[_kSemanticModes.first]!.keys) {
    final slot = cssVar.replaceFirst('--coui-', '');
    final name = 'color/$slot';
    final valuesByMode = <String, Map<String, dynamic>>{};
    for (final mode in _kSemanticModes) {
      final triplet = semanticCssVarsByMode[mode]![cssVar]!;
      final shared = sharedLinksByMode[mode]![slot];
      if (shared == null) {
        valuesByMode[mode] = _aliasOrColor(triplet, tripletToAlias);
        continue;
      }
      final (namespace, link) = shared;
      valuesByMode[mode] = {
        'alias': '$_kCollPrimitives/${_sharedColorPath(link)}',
      };
      sharedLinked[namespace]![mode] = sharedLinked[namespace]![mode]! + 1;
      final linked = sharedTriplets[link];
      if (linked != null && linked != triplet) {
        linkMismatches.add(
          '$name @ $mode -> $link: primitive $linked, slot $triplet',
        );
      }
    }
    semantics.add({
      'name': name,
      'type': 'COLOR',
      'valuesByMode': valuesByMode,
    });
  }
  // Every link of every mode, whether or not this brand's scheme states the
  // slot: a link to a name no shared group carries would alias a variable
  // that does not exist.
  final danglingLinks = [
    for (final MapEntry(key: mode, value: links) in sharedLinksByMode.entries)
      for (final MapEntry(key: slot, value: (_, link)) in links.entries)
        if (!sharedTriplets.containsKey(link)) 'color/$slot @ $mode -> $link',
  ];
  // And every link must have been routed. A link whose slot the vocabulary
  // lacks routes nothing — the shared slot it names is missing from the
  // scheme walk, and the Figma collection would lack it.
  final unlinked = [
    for (final MapEntry(key: mode, value: links) in sharedLinksByMode.entries)
      for (final MapEntry(key: slot, value: (_, link)) in links.entries)
        if (!semanticCssVarsByMode[mode]!.containsKey('--coui-$slot'))
          'color/$slot @ $mode -> $link',
  ];

  // --- Shadow colours (Light/Dark/HCLight/HCDark, values) -----------------
  // A row per layer of the shadow scale, its value in each mode the mode's
  // `shadow` slot at the layer's alpha. Brand colour, so it lives in this
  // collection and moves with a brand swap; a value, because an alias
  // cannot carry the alpha.
  final shadowRowsByMode = _shadowRowsByMode(schemesByMode);
  final shadowRows = shadowRowsByMode[_kSemanticModes.first]!;
  for (var i = 0; i < shadowRows.length; i++) {
    semantics.add({
      'name': shadowRows[i]['name'],
      'type': 'COLOR',
      'scopes': ['EFFECT_COLOR'],
      'valuesByMode': {
        for (final mode in _kSemanticModes)
          mode: shadowRowsByMode[mode]![i]['value'],
      },
    });
  }

  // --- Color-axis integrity gate (per brand) ------------------------------
  // No skip on the color axis: every Semantic `color/*` slot, in every
  // mode, must alias a Primitives colour, and every primitive value must
  // have exactly one owner within this brand's own path namespace
  // (`color/<brandId>/...`) in the shared Primitives collection. A slot
  // matched by value must resolve to THIS BRAND's own primitive — a raw
  // `{r,g,b,a}` here means a mode computed a colour this brand's primitive
  // palette does not contain; for the two high-contrast modes that would
  // mean `raiseContrast` reached outside the palette. A shared triplet
  // means `tripletToAlias[t] ??= …`'s first-wins pick silently hid which
  // primitive every Semantic slot actually points at. A slot linked by name
  // to a shared group resolves by construction, so this check cannot see
  // it; the checks above prove it instead (`linkMismatches`,
  // `danglingLinks`, `unlinked`).
  //
  // The shadow rows are values by design, so they are kept out of the
  // alias check and held to their own: each value's RGB is the same mode's
  // `color/shadow` and its alpha is the one `_brandShadowColorRows`
  // derived — the derivation read against the rows as written.
  // Any failure means the exported document does not say what `coui_core`
  // says for this brand, so this fails the build instead of writing a
  // Figma document a designer would read as authoritative.
  final unresolved = <String>[];
  for (final variable in semantics) {
    final name = variable['name']! as String;
    if (name.startsWith(_kBrandShadowPrefix)) continue;
    final valuesByMode = variable['valuesByMode']! as Map<String, dynamic>;
    for (final mode in _kSemanticModes) {
      final value = valuesByMode[mode];
      if (value is Map && !value.containsKey('alias')) {
        unresolved.add('$name @ $mode');
      }
    }
  }
  final shadowColorMismatches = _shadowColorMismatches(
    semantics,
    semanticCssVarsByMode,
    shadowRowsByMode,
  );
  final ambiguous = tripletCounts.entries
      .where((e) => e.value > 1)
      .map((e) => e.key)
      .toList();

  return _BrandCollections(
    brand: brand,
    semanticColorCollectionName: semanticColorCollectionName,
    primitives: primitives,
    semantics: semantics,
    tripletToAlias: tripletToAlias,
    tripletCounts: tripletCounts,
    unresolved: unresolved,
    ambiguous: ambiguous,
    sharedLinked: sharedLinked,
    linkMismatches: linkMismatches,
    danglingLinks: danglingLinks,
    unlinked: unlinked,
    reservedPrimitives: reservedPrimitives,
    shadowColorMismatches: shadowColorMismatches,
  );
}

/// The shadow-colour rows in [semantics] that do not say what the brand
/// says: a value whose RGB is not the same mode's `color/shadow` or whose
/// alpha is not the derived one, a derived row that was not written, and a
/// written row nothing derives.
List<String> _shadowColorMismatches(
  List<Map<String, dynamic>> semantics,
  Map<String, Map<String, String>> semanticCssVarsByMode,
  Map<String, List<Map<String, dynamic>>> derivedByMode,
) {
  final out = <String>[];
  final written = {
    for (final row in semantics)
      if ((row['name']! as String).startsWith(_kBrandShadowPrefix))
        row['name']! as String: row['valuesByMode']! as Map<String, dynamic>,
  };
  final derivedNames = {
    for (final rows in derivedByMode.values)
      for (final row in rows) row['name']! as String,
  };
  for (final name in written.keys) {
    if (!derivedNames.contains(name)) out.add('$name: not derived');
  }
  for (final MapEntry(key: mode, value: derived) in derivedByMode.entries) {
    final shadow = _rgb(semanticCssVarsByMode[mode]!['--coui-shadow']!);
    for (final row in derived) {
      final name = row['name']! as String;
      final value = written[name]?[mode];
      if (value is! Map) {
        out.add('$name @ $mode: not written');
        continue;
      }
      final alpha = (row['value']! as Map<String, double>)['a'];
      final channels = ['r', 'g', 'b'];
      if (channels.any((c) => value[c] != shadow[c]) || value['a'] != alpha) {
        out.add(
          '$name @ $mode: ${[
            for (final c in [...channels, 'a']) value[c],
          ]} '
          '— expected color/shadow ${[for (final c in channels) shadow[c]]} '
          'at alpha $alpha',
        );
      }
    }
  }

  return out;
}

/// One non-library brand's value table: the Semantic colours where the brand
/// differs from the library brand, per mode, and what could not be tabled.
class _BrandTable {
  const _BrandTable({
    required this.brand,
    required this.overrides,
    required this.slotSetMismatches,
    required this.sharedStated,
  });

  final CoreBrand brand;

  /// `{name, valuesByMode}` per slot (and shadow-colour row) whose value in at
  /// least one mode is not the library brand's; `valuesByMode` holds only
  /// those modes. Anything absent follows the library brand.
  final List<Map<String, dynamic>> overrides;

  /// Slots one side states and the other does not, in any mode — the two
  /// brands do not share a Semantic vocabulary, so there is nothing to
  /// override by name.
  final List<String> slotSetMismatches;

  /// Slots a shared group links whose value in this brand is not the
  /// library's: a group is the same in every brand by definition, so a
  /// brand-owned value there means the group is not shared.
  final List<String> sharedStated;
}

/// Builds [brand]'s value table against the library brand [library].
///
/// The library brand's Semantic collection is what a consumer file extends,
/// and an extension stores only what it changes — so the table is a
/// difference, not a second copy of the vocabulary: a slot whose colour in a
/// mode is the library brand's is left out and keeps following it (including
/// when the library's colours change). Values are colours, not aliases —
/// the library holds no primitive of this brand to point at. The shadow
/// colours (`effect/shadow/<step>/<layer>`) are tabled the same way, each at
/// its layer's alpha (`_brandShadowColorRows`).
_BrandTable _buildBrandTable(CoreBrand brand, CoreBrand library) {
  final brandSchemes = _schemesByMode(brand.source);
  final librarySchemes = _schemesByMode(library.source);
  final brandVars = _semanticCssVarsByMode(brandSchemes);
  final libraryVars = _semanticCssVarsByMode(librarySchemes);
  final brandShadows = _shadowRowsByMode(brandSchemes);
  final libraryShadows = _shadowRowsByMode(librarySchemes);
  final links = _sharedLinksByMode([]);

  final slotSetMismatches = <String>[];
  final sharedStated = <String>[];
  // name -> mode -> value, in the library's own slot order.
  final byName = <String, Map<String, Map<String, double>>>{};

  for (final mode in _kSemanticModes) {
    final theirs = brandVars[mode]!;
    final ours = libraryVars[mode]!;
    for (final cssVar in {...ours.keys, ...theirs.keys}) {
      final slot = cssVar.replaceFirst('--coui-', '');
      final name = 'color/$slot';
      final ourTriplet = ours[cssVar];
      final theirTriplet = theirs[cssVar];
      if (ourTriplet == null || theirTriplet == null) {
        slotSetMismatches.add(
          '$name @ $mode: ${ourTriplet == null ? 'library' : 'brand'} '
          'does not state it',
        );
        continue;
      }
      if (ourTriplet == theirTriplet) continue;
      if (links[mode]!.containsKey(slot)) {
        sharedStated.add('$name @ $mode: $theirTriplet (library $ourTriplet)');
        continue;
      }
      (byName[name] ??= {})[mode] = _rgb(theirTriplet);
    }

    final ourShadows = {
      for (final row in libraryShadows[mode]!)
        row['name']! as String: row['value']! as Map<String, double>,
    };
    for (final row in brandShadows[mode]!) {
      final name = row['name']! as String;
      final value = row['value']! as Map<String, double>;
      final ours = ourShadows[name];
      if (ours == null) {
        slotSetMismatches.add('$name @ $mode: library does not state it');
      } else if (!_sameColour(ours, value)) {
        (byName[name] ??= {})[mode] = value;
      }
    }
  }

  return _BrandTable(
    brand: brand,
    overrides: [
      for (final MapEntry(key: name, value: byMode) in byName.entries)
        {
          'name': name,
          'valuesByMode': {
            for (final mode in _kSemanticModes)
              if (byMode[mode] != null) mode: byMode[mode],
          },
        },
    ],
    slotSetMismatches: slotSetMismatches,
    sharedStated: sharedStated,
  );
}

bool _sameColour(Map<String, double> a, Map<String, double> b) =>
    ['r', 'g', 'b', 'a'].every((c) => a[c] == b[c]);

/// The document the plugin bundles (`tools/figma-token-sync/src/data/brands.json`):
/// which library collection every table extends, and each brand's table.
Map<String, dynamic> _brandsDocument(
  _BrandCollections library,
  List<_BrandTable> tables,
) => {
  'generator': 'export_figma_tokens.dart',
  'library': {
    'brand': library.brand.id,
    'collection': library.semanticColorCollectionName,
    'modes': _kSemanticModes,
  },
  'brands': [
    for (final t in tables)
      {
        'id': t.brand.id,
        'displayName': t.brand.displayName,
        'overrides': t.overrides,
      },
  ],
};

/// The two content collections and the document the plugin bundles for them.
class _ContentColors {
  const _ContentColors({
    required this.content,
    required this.status,
    required this.document,
    required this.unreadSlots,
    required this.tooManyModes,
  });

  /// `Semantic/ Content` — one variable, one mode per tone plus the hand-off.
  final Map<String, dynamic> content;

  /// `Semantic/ Content Status` — one variable, one mode per status tone.
  final Map<String, dynamic> status;

  /// `tools/figma-token-sync/src/data/content-colors.json`.
  final Map<String, dynamic> document;

  /// Modes that name a slot the colour collection does not carry — an alias to
  /// nothing.
  final List<String> unreadSlots;

  /// Collections over [_kFigmaModeLimit].
  final List<String> tooManyModes;
}

/// Builds `Semantic/ Content` and `Semantic/ Content Status`: the colour a glyph
/// inherits from the frame it sits in.
///
/// A glyph's stroke is bound to `content/current`, and the **slot frame** (the
/// parent of the icon instance) pins the mode that says which tone it is. The
/// mode is inherited by everything below the frame, so the colour survives an
/// icon swapped in or deleted and added again — the strokes the plugin used to
/// paint per variant did not (a swapped-in glyph keeps the library's colour).
/// Every mode value is an alias to the colour collection's slot of the same
/// name, so light, dark and high contrast follow that collection's mode, and a
/// brand that extends it carries its own colours here too: content is one
/// collection and never one per brand.
///
/// The colour collection is the **library brand's** (the same collection
/// `Effect` reads), because the extension a consumer file opens is an
/// extension of that one.
_ContentColors _buildContentColors({
  required String colorCollection,
  required Set<String> colorSlots,
}) {
  final contentModes = [..._kContentTones, _kContentStatusMode];
  final statusModes = _kContentStatusTones;
  final unreadSlots = [
    for (final tone in [..._kContentTones, ...statusModes])
      if (!colorSlots.contains(tone)) tone,
  ];
  final tooManyModes = [
    if (contentModes.length > _kFigmaModeLimit)
      '$_kCollSemanticContent: ${contentModes.length}',
    if (statusModes.length > _kFigmaModeLimit)
      '$_kCollSemanticContentStatus: ${statusModes.length}',
  ];
  const scopes = ['SHAPE_FILL', 'STROKE_COLOR'];
  Map<String, String> aliasTo(String tone) => {
    'alias': '$colorCollection/color/$tone',
  };

  final status = {
    'name': _kCollSemanticContentStatus,
    'modes': statusModes,
    'variables': [
      {
        'name': _kContentStatus,
        'type': 'COLOR',
        'scopes': scopes,
        'description':
            'The status tone a glyph takes when its slot pins `status` in '
            '$_kCollSemanticContent. Pin the same status mode here.',
        'valuesByMode': {for (final tone in statusModes) tone: aliasTo(tone)},
      },
    ],
  };
  final content = {
    'name': _kCollSemanticContent,
    'modes': contentModes,
    'variables': [
      {
        'name': _kContentCurrent,
        'type': 'COLOR',
        'scopes': scopes,
        'description':
            "The colour of the content a slot holds — a glyph's stroke is "
            'bound to this, and the slot frame pins the mode that names the '
            'tone. The status mode reads $_kCollSemanticContentStatus.',
        'valuesByMode': {
          for (final tone in _kContentTones) tone: aliasTo(tone),
          _kContentStatusMode: {
            'alias': '$_kCollSemanticContentStatus/$_kContentStatus',
          },
        },
      },
    ],
  };
  return _ContentColors(
    content: content,
    status: status,
    unreadSlots: unreadSlots,
    tooManyModes: tooManyModes,
    document: {
      'generator': 'export_figma_tokens.dart',
      'colorCollection': colorCollection,
      'content': {
        'collection': _kCollSemanticContent,
        'variable': _kContentCurrent,
        'statusMode': _kContentStatusMode,
        'modes': contentModes,
      },
      'status': {
        'collection': _kCollSemanticContentStatus,
        'variable': _kContentStatus,
        'modes': statusModes,
      },
    },
  );
}

void main() {
  // A shared namespace is the group's (`color/<namespace>/...`): a brand
  // with that id would put its own primitives under the same path, and the
  // plugin, which never rebinds a shared primitive, would read them as
  // shared.
  final reservedIds = [
    for (final brand in _kBrands.all)
      for (final group in _kSharedColourGroups)
        if (brand.id == group.namespace) brand.id,
  ];
  if (reservedIds.isNotEmpty) {
    stderr.writeln(
      '❌ brand id "${reservedIds.join('", "')}" is reserved for a shared '
      'colour group (${_kSharedColourGroups.map((g) => g.namespace).join(', ')}'
      ') — rename the brand.',
    );
    exit(1);
  }

  // Only the library brand (the registry's first) becomes a Semantic/Color
  // collection with primitives; every other brand is a value table over it
  // (`_buildBrandTable`). A brand adds no collection to the library.
  final libraryBrand = _kBrands.all.first;
  final brandCollections = [_buildBrandCollections(libraryBrand)];
  final brandTables = [
    for (final brand in _kBrands.all.skip(1))
      _buildBrandTable(brand, libraryBrand),
  ];

  // --- Color-axis integrity gate — reported across every brand at once,
  // so a designer fixing one failure sees the whole list rather than
  // re-running per brand to discover the next one.
  final failedBrands = brandCollections.where(
    (b) =>
        b.unresolved.isNotEmpty ||
        b.ambiguous.isNotEmpty ||
        b.linkMismatches.isNotEmpty ||
        b.danglingLinks.isNotEmpty ||
        b.unlinked.isNotEmpty ||
        b.reservedPrimitives.isNotEmpty ||
        b.shadowColorMismatches.isNotEmpty,
  );
  if (failedBrands.isNotEmpty) {
    for (final b in failedBrands) {
      if (b.unresolved.isNotEmpty) {
        stderr
          ..writeln(
            '❌ [${b.brand.displayName}] ${b.unresolved.length} Semantic '
            'slot(s) did not resolve to a Primitives alias (raw colour — '
            "outside the brand's primitive palette):",
          )
          ..writeln(b.unresolved.map((s) => '   $s').join('\n'));
      }
      if (b.ambiguous.isNotEmpty) {
        stderr
          ..writeln(
            '❌ [${b.brand.displayName}] ${b.ambiguous.length} primitive '
            'colour value(s) have more than one owner (ambiguous '
            'first-wins alias):',
          )
          ..writeln(b.ambiguous.map((t) => '   $t').join('\n'));
      }
      if (b.linkMismatches.isNotEmpty) {
        stderr
          ..writeln(
            '❌ [${b.brand.displayName}] ${b.linkMismatches.length} Semantic '
            'slot(s) linked by name to a shared primitive that holds a '
            'different colour, or linked by two shared groups:',
          )
          ..writeln(b.linkMismatches.map((s) => '   $s').join('\n'));
      }
      if (b.danglingLinks.isNotEmpty) {
        stderr
          ..writeln(
            '❌ [${b.brand.displayName}] ${b.danglingLinks.length} shared '
            'link(s) name a primitive no shared group carries:',
          )
          ..writeln(b.danglingLinks.map((s) => '   $s').join('\n'));
      }
      if (b.unlinked.isNotEmpty) {
        stderr
          ..writeln(
            '❌ [${b.brand.displayName}] ${b.unlinked.length} shared '
            'link(s) name a slot the Semantic vocabulary does not carry:',
          )
          ..writeln(b.unlinked.map((s) => '   $s').join('\n'));
      }
      if (b.reservedPrimitives.isNotEmpty) {
        stderr
          ..writeln(
            '❌ [${b.brand.displayName}] ${b.reservedPrimitives.length} '
            'primitive(s) sit under a reserved shared namespace '
            '(${_kSharedColourGroups.map((g) => g.namespace).join(', ')}) '
            '— rename the family:',
          )
          ..writeln(b.reservedPrimitives.map((s) => '   $s').join('\n'));
      }
      if (b.shadowColorMismatches.isNotEmpty) {
        stderr
          ..writeln(
            '❌ [${b.brand.displayName}] ${b.shadowColorMismatches.length} '
            "shadow colour row(s) are not the mode's color/shadow at the "
            "layer's alpha:",
          )
          ..writeln(b.shadowColorMismatches.map((s) => '   $s').join('\n'));
      }
    }
    exit(1);
  }

  // The same all-at-once reporting for the tables: a brand whose vocabulary
  // differs from the library's, or that states a shared group's colour, would
  // write an extension that cannot be a difference over the library.
  final failedTables = brandTables.where(
    (t) => t.slotSetMismatches.isNotEmpty || t.sharedStated.isNotEmpty,
  );
  if (failedTables.isNotEmpty) {
    for (final t in failedTables) {
      if (t.slotSetMismatches.isNotEmpty) {
        stderr
          ..writeln(
            '❌ [${t.brand.displayName}] ${t.slotSetMismatches.length} '
            "slot(s) are not in both this brand's and the library brand's "
            'Semantic vocabulary:',
          )
          ..writeln(t.slotSetMismatches.map((s) => '   $s').join('\n'));
      }
      if (t.sharedStated.isNotEmpty) {
        stderr
          ..writeln(
            '❌ [${t.brand.displayName}] ${t.sharedStated.length} slot(s) '
            'a shared colour group links hold a value of their own — a '
            'group is the same in every brand:',
          )
          ..writeln(t.sharedStated.map((s) => '   $s').join('\n'));
      }
    }
    exit(1);
  }

  // Effect's focus-ring color/offset-color has no brand axis of its own
  // (it is a single shared collection — see `_kCollSemanticEffect` below),
  // so it aliases the FIRST registered brand's Semantic/Color collection.
  // With one brand today this is the only brand there is; once a second
  // brand exists, Effect keeps following the first one specifically
  // (rather than, say, silently switching to "whichever brand exported
  // last") until Effect itself grows a brand axis — a separate, later
  // decision, not implied by adding a brand to `_kBrands`.
  final defaultSemanticColorCollectionName =
      brandCollections.first.semanticColorCollectionName;

  // The colour a glyph inherits from its slot. Read from the same collection
  // `Effect` is — the library brand's — and checked here, before anything is
  // written, so a mode that names no slot or a collection over the plan's mode
  // limit stops the build instead of shipping an alias to nothing.
  final contentColors = _buildContentColors(
    colorCollection: defaultSemanticColorCollectionName,
    colorSlots: {
      for (final variable in brandCollections.first.semantics)
        if ((variable['name']! as String).startsWith('color/'))
          (variable['name']! as String).substring('color/'.length),
    },
  );
  if (contentColors.unreadSlots.isNotEmpty ||
      contentColors.tooManyModes.isNotEmpty) {
    if (contentColors.unreadSlots.isNotEmpty) {
      stderr.writeln(
        '❌ ${contentColors.unreadSlots.length} content colour mode(s) name a '
        'slot the Semantic colour vocabulary does not carry — the mode would '
        'alias nothing: ${contentColors.unreadSlots.join(', ')}',
      );
    }
    if (contentColors.tooManyModes.isNotEmpty) {
      stderr.writeln(
        '❌ content colour collection(s) over the $_kFigmaModeLimit-mode limit '
        'of a Figma collection: ${contentColors.tooManyModes.join(', ')}',
      );
    }
    exit(1);
  }

  // --- Shared Primitives collection ---------------------------------------
  // One collection, four sources: the library brand's colour rows (namespaced
  // `color/<brandId>/...` — see `_buildBrandCollections`), the rows of
  // every shared group (`color/<namespace>/...`, once each, no brand
  // segment), the numeric/string scale tokens (brand-invariant), and the
  // composite tokens below. A brand that is not the library brand adds no
  // row here (`_buildBrandTable`).
  //
  // The shared rows stay out of the library brand's `tripletToAlias` and
  // `tripletCounts`: nothing reaches them by value, and a value a group
  // states under two names, or one the brand's ramp also holds, would read
  // as ambiguous to the uniqueness check.
  final sharedRowsByGroup = {
    for (final group in _kSharedColourGroups)
      group.namespace: [
        for (final e in group.triplets.entries)
          _colorVariable(_sharedColorPath(e.key), e.value, mode: 'Value'),
      ],
  };
  final sharedColourRows = [
    for (final rows in sharedRowsByGroup.values) ...rows,
  ];
  final sharedPrimitives = <Map<String, dynamic>>[
    for (final b in brandCollections) ...b.primitives,
    ...sharedColourRows,
    for (final token in _numericTokens()) token.toVariable(),
    // --- Composite primitives (shadow / easing / spring / focus-ring) ----
    // Figma Variables can't hold composites, so motion/shadow tokens are
    // emitted as a single CSS STRING each (readable/copyable in Figma);
    // focus-ring is decomposed into FLOATs + semantic color aliases.
    ..._compositeTokens(),
  ];

  // --- Semantic / Dimension (one mode per density) -----------------------
  // Kept as its own collection, away from the colour `Semantic`
  // collection — colour modes (Light/Dark/HC) and density are different
  // axes, and putting them in one collection would combinatorially explode
  // modes (spec §5).
  //
  // One mode per density, named as code names it (the Web
  // `data-coui-density` value), default first so a frame that pins nothing
  // draws the authored values. Every value is an alias computed by the same
  // seat the two platforms read (`resolveThemeGeometry(density:)`), so the
  // canvas cannot hold a number neither platform renders:
  //
  // * `control-size/*` — the control rows, into `Primitives/size`.
  // * `space/*` — the spacing a density moves, into `Primitives/space`.
  // * `radius/*` — the corners, into `Semantic/ Surface`, so a frame that
  //   pins both a density and a style composes them in code's order:
  //   density first, then the style.
  // * `a11y/*` — the pointer floor and the touch target; a density does not
  //   move them, so every mode aliases the same primitive.
  final densityModes = [for (final d in _kDensityModes) d.name];
  final dimensions = <Map<String, dynamic>>[
    for (final e in <String, double>{
      'xs': CoreControlSize.heightXs,
      'sm': CoreControlSize.heightSm,
      'md': CoreControlSize.heightMd,
      'lg': CoreControlSize.heightLg,
      'xl': CoreControlSize.heightXl,
      'xl2': CoreControlSize.heightXl2,
    }.entries)
      _densityVar(
        'control-size/${e.key}',
        scopes: ['WIDTH_HEIGHT'],
        alias: (d) => _sizeAlias(d.controlHeight(e.value)),
        description: switch (e.key) {
          'xs' => 'Row-aligned form-control height — smallest tier.',
          'md' => 'Row-aligned form-control height — default.',
          'xl2' => 'Row-aligned form-control height — largest tier.',
          _ => 'Row-aligned form-control height.',
        },
      ),
    // Two different kinds of value: pointer-target-min is the floor the
    // platforms enforce (`CoreTouchTarget.minimum` reads it), touch-target
    // is a recommended drawn size that nothing enforces. The Apple HIG /
    // AAA 44 (`CoreA11ySize.minTouchTarget`) stays code-only until the
    // designer opts it into the file.
    _densityVar(
      'a11y/pointer-target-min',
      scopes: ['WIDTH_HEIGHT'],
      alias: (_) => _sizeAlias(CoreA11ySize.minPointerTarget),
      description:
          'Guaranteed minimum area that accepts a pointer (WCAG 2.2 AA '
          '2.5.8). Small controls keep their drawn size; only the pointer '
          'area extends to this.',
    ),
    _densityVar(
      'a11y/touch-target',
      scopes: ['WIDTH_HEIGHT'],
      alias: (_) => _sizeAlias(CoreA11ySize.touchTarget),
      description:
          'Recommended drawn size for targets on touch-primary screens '
          '(M3 / Flutter kMinInteractiveDimension). Not enforced — the '
          'guaranteed floor is a11y/pointer-target-min.',
    ),
    for (final e in _kSpaceLadder.entries)
      _densityVar(
        'space/${e.key}',
        scopes: ['GAP'],
        alias: (d) =>
            '$_kCollPrimitives/space/'
            '${_ladderLeaf(_kSpaceLadder, d.space(e.value), 'space')}',
        description:
            'space/${e.key} under each density — pin a mode on a frame to '
            'see its spacing.',
      ),
    for (final e in _kRadiusLadder.entries)
      _densityVar(
        'radius/${e.key}',
        scopes: ['CORNER_RADIUS'],
        alias: (d) =>
            '$_kCollSemanticSurface/radius/'
            '${_ladderLeaf(_kRadiusLadder, d.radius(e.value), 'radius')}',
        description:
            'radius/${e.key} under each density, then the surface style — '
            'a density moves the corners that follow a control row.',
      ),
  ];

  // --- Component (per-component tier tokens, alias to size/*) -------------
  // Values come from the same `defaultsBySize` maps the Flutter/Web
  // resolvers read, so this collection can never drift from what the
  // components actually render. Chip heights, ListTile and AppBar are
  // the exceptions: chip height is intrinsic (padding-based) in code,
  // and ListTile/AppBar have no code component yet — their tokens are
  // spec values (CoUI_Size_Token_Specification §3-4) referencing
  // `CoreSize` directly until the components land.
  const tierNames = {
    CoreComponentSize.xs: 'xs',
    CoreComponentSize.sm: 'sm',
    CoreComponentSize.md: 'md',
    CoreComponentSize.lg: 'lg',
    CoreComponentSize.xl: 'xl',
    CoreComponentSize.xl2: 'xl2',
  };
  final components = <Map<String, dynamic>>[
    // icon-size — the value-named subset (`CoreIconSize`).
    for (final e in <String, double>{
      '10': CoreIconSize.size10,
      '12': CoreIconSize.size12,
      '14': CoreIconSize.size14,
      '16': CoreIconSize.size16,
      '18': CoreIconSize.size18,
      '20': CoreIconSize.size20,
      '24': CoreIconSize.size24,
      '28': CoreIconSize.size28,
      '32': CoreIconSize.size32,
      '48': CoreIconSize.size48,
    }.entries)
      _dimAliasVar('icon-size/${e.key}', e.value),
    _dimAliasVar(
      'icon-size/default',
      CoreIconSize.defaultSize,
      description: 'The size an icon draws at when nothing states one.',
    ),
    // button — per-tier icon sizes (heights are `control-size/*`
    // directly; the spec forbids per-component height middlemen).
    for (final e in tierNames.entries)
      _dimAliasVar(
        'button/icon-${e.value}',
        CoreButtonStyle.defaultsBySize[e.key]!.leadingIconStyle!.size!,
      ),
    // The glyph of a square or circle button — no label beside it, so a
    // step larger than `button/icon-*` of the same tier.
    for (final e in tierNames.entries)
      _dimAliasVar(
        'button/icon-shape-${e.value}',
        CoreButtonStyle.defaultsBySize[e.key]!.iconShapeIconStyle!.size!,
      ),
    // Button · Menu redesign (2026-09-08 §4) — the two size ladders the
    // builder binds per Size pill. `padding-x` is the inline pair
    // (`left` == `right` on every symmetric row; the exporter would
    // otherwise need to pick a side), the gap is the icon↔label
    // `iconLabelGapStyle`.
    for (final e in tierNames.entries)
      _spaceAliasVar(
        'button/padding-x-${e.value}',
        CoreButtonStyle.defaultsBySize[e.key]!.padding!.left,
      ),
    for (final e in tierNames.entries)
      _spaceAliasVar(
        'button/gap-${e.value}',
        CoreButtonStyle.defaultsBySize[e.key]!.iconLabelGapStyle!.size!,
      ),
    // Corner radii are not component tokens. A control corner lives in the
    // component's own style — its `defaultBorderRadius`, or the size row's
    // `borderRadius` where the component has a size ladder — and the plugin
    // binds a corner by value to `Primitives/radius/<n>` — a component
    // alias in this collection would have nothing reading it (the focus
    // band / ring and container corners are derived from the control
    // corner, `+2` / `+4` / `+ padding`, and are not tokens either).
    //
    // menu-item (Button · Menu redesign §6-3) — the row density ladder the
    // builder binds per Size pill: minimum height, the inline / block
    // inset pair, the seat gap and the leading icon. Mark / chevron are
    // size-free (an optical band).
    for (final e in {
      'sm': CoreMenuItemSize.sm,
      'md': CoreMenuItemSize.md,
      'lg': CoreMenuItemSize.lg,
    }.entries) ...[
      // A row on the control ladder aliases its density row; the 36 `md`
      // row is off the ladder, a density leaves it as authored
      // (`CoreDensity.controlHeight`), so it aliases the primitive size.
      _rowHeightAliasVar(
        'menu-item/height-${e.key}',
        CoreMenuItemStyle.defaultsBySize[e.value]!.minHeight!,
        description: e.value == CoreMenuItemSize.defaultSize
            ? 'Default.'
            : null,
      ),
      _spaceAliasVar(
        'menu-item/padding-x-${e.key}',
        CoreMenuItemStyle.defaultsBySize[e.value]!.padding!.left,
      ),
      _spaceAliasVar(
        'menu-item/padding-y-${e.key}',
        CoreMenuItemStyle.defaultsBySize[e.value]!.padding!.top,
      ),
      _spaceAliasVar(
        'menu-item/gap-${e.key}',
        CoreMenuItemStyle.defaultsBySize[e.value]!.contentGapStyle!.size!,
      ),
      _dimAliasVar(
        'menu-item/leading-${e.key}',
        CoreMenuItemStyle.defaultsBySize[e.value]!.leadingIconStyle!.size!,
      ),
    ],
    _dimAliasVar(
      'menu-item/mark',
      CoreMenuItemStyle.defaultMarkIconStyle.size!,
    ),
    _dimAliasVar(
      'menu-item/chevron',
      CoreMenuItemStyle.defaultChevronIconStyle.size!,
    ),
    // select (Select 코드 인계 통합본 2026-09-08 §8-1) — the trigger's
    // ladder read straight from the `TextField` rows the trigger composes,
    // so the two cannot drift: height, the inline / block inset pair and
    // the chevron per rung; and the panel's three numbers (padding, gap,
    // offset). A `select/*` token that restated a value of its own would
    // be the second source the document warns against.
    for (final e in {
      'sm': CoreSelectSize.sm,
      'md': CoreSelectSize.md,
      'lg': CoreSelectSize.lg,
    }.entries) ...[
      _controlRowAliasVar(
        'select/height-${e.key}',
        CoreTextFieldStyle
            .defaultsBySize[e.value.toComponentSize()]!
            .minHeight!,
        description: e.value == CoreSelectSize.md ? 'Default.' : null,
      ),
      _spaceAliasVar(
        'select/padding-x-${e.key}',
        CoreTextFieldStyle
            .defaultsBySize[e.value.toComponentSize()]!
            .padding!
            .left,
      ),
      _spaceAliasVar(
        'select/padding-y-${e.key}',
        CoreTextFieldStyle
            .defaultsBySize[e.value.toComponentSize()]!
            .padding!
            .top,
      ),
      _dimAliasVar(
        'select/icon-${e.key}',
        CoreSelectStyle.defaultsBySize[e.value]!.trailingIconStyle!.size!,
      ),
    ],
    _spaceAliasVar(
      'select/panel-padding',
      CoreSelectStyle.defaultPopoverStyle.panelStyle!.padding!.left,
    ),
    _spaceAliasVar(
      'select/panel-gap',
      CoreSelectStyle.defaultPopoverStyle.panelStyle!.spacing!,
    ),
    // The panel's distance from its trigger is placement, not spacing a
    // density moves — the two platforms do not move it either — so it
    // keeps aliasing the primitive.
    _aliasVar(
      'select/panel-offset',
      'FLOAT',
      _spaceAlias(CoreSelectStyle.defaultPopoverStyle.placementOffset!),
      scopes: ['GAP'],
    ),
    // avatar-size — diameters from the shared resolver table.
    for (final e in tierNames.entries)
      _dimAliasVar(
        'avatar-size/${e.value}',
        CoreAvatarStyle.diameterFor(e.key),
        description: e.key == CoreAvatarContract.defaultSize
            ? 'Default.'
            : null,
      ),
    _dimAliasVar(
      'avatar-size/display',
      CoreSize.size128,
      description: 'Standalone profile-header avatar — not an enum tier.',
    ),
    // chip — its own three-tier ladder (`CoreChipSize`), read from the size
    // table rather than restated here: 24 is Badge's row and 48 / 56 are
    // Button's, so a chip has no tier there and a second list would be a
    // second place for that to drift.
    for (final size in CoreChipSize.values)
      _dimAliasVar(
        'chip/height-${size.name}',
        CoreChipStyle.defaultsBySize[size]!.minHeight!,
        description: size == CoreChipSize.defaultSize
            ? 'Default — M3 AssistChip / Flutter _kChipHeight.'
            : null,
      ),
    for (final size in CoreChipSize.values)
      _dimAliasVar(
        'chip/icon-${size.name}',
        CoreChipStyle.defaultsBySize[size]!.leadingIconStyle!.size!,
      ),
    // checkbox — visual box sizes (the pointer area is floored at
    // a11y/pointer-target-min, not the box). No
    // separate radio group: the spec pins radio-size == checkbox-size
    // 1:1 (`CoreRadioGroupStyle.defaultsBySize` mirrors this in code),
    // and the live library carries the shared ladder once, as checkbox.
    for (final e in tierNames.entries)
      _dimAliasVar(
        'checkbox/${e.value}',
        CoreCheckboxStyle.defaultsBySize[e.key]!.boxSize!,
        description: e.key == CoreComponentSize.md ? 'Default.' : null,
      ),
    // checkbox — the thickness of the indeterminate dash only. The check mark
    // is an ordinary icon and follows the icon stroke rule
    // (`CoreIconStroke`), so the canvas binds only the dash's height to this
    // variable ("thickness is a constant, length is per size").
    // A raw FLOAT rather than a `stroke/<n>` alias: the primitive stroke
    // scale steps in whole pixels and this weight sits between two rungs,
    // so there is no leaf to point at. The value is Core's, not restated —
    // `CoreCheckboxStyle.defaultMarkThickness` is the single source, and it
    // is taken from the icon rule's floor so the dash and the check read at
    // the same weight.
    {
      'name': 'checkbox/mark-thickness',
      'type': 'FLOAT',
      'scopes': ['STROKE_FLOAT'],
      'description':
          'Indeterminate-dash height — one weight at every size; only the '
          'length follows the size ladder. Does not bind the check mark, '
          'which is an icon and follows the icon stroke rule.',
      'valuesByMode': {'Value': CoreCheckboxStyle.defaultMarkThickness},
    },
    // loading (spinner) diameters.
    for (final e in tierNames.entries)
      _dimAliasVar(
        'loading/${e.value}',
        CoreLoadingStyle.defaultsBySize[e.key]!.size!,
        description: e.key == CoreComponentSize.md ? 'Default.' : null,
      ),
    // list-tile — spec §3-4 (no code component yet).
    _dimAliasVar('list-tile/height-one-line', CoreSize.size56),
    _dimAliasVar('list-tile/height-two-line', CoreSize.size72),
    _dimAliasVar('list-tile/height-three-line', CoreSize.size88),
    _dimAliasVar('list-tile/leading-avatar', CoreSize.size40),
    _dimAliasVar('list-tile/leading-icon', CoreSize.size24),
    // app-bar — spec §3-4 (no code component yet).
    _dimAliasVar('app-bar/height-compact', CoreSize.size56),
    _dimAliasVar(
      'app-bar/height-standard',
      CoreSize.size64,
      description: 'Default.',
    ),
    _dimAliasVar('app-bar/height-medium', CoreSize.size112),
    // fab — dedicated enum ladder.
    for (final e in {
      'mini': CoreFabSize.mini,
      'regular': CoreFabSize.regular,
      'large': CoreFabSize.large,
    }.entries)
      _dimAliasVar(
        'fab/${e.key}',
        CoreFabStyle.defaultsBySize[e.value]!.diameter!,
        description: e.value == CoreFabSize.regular ? 'Default.' : null,
      ),
    for (final e in {
      'mini': CoreFabSize.mini,
      'regular': CoreFabSize.regular,
      'large': CoreFabSize.large,
    }.entries)
      _dimAliasVar(
        'fab/icon-${e.key}',
        CoreFabStyle.defaultsBySize[e.value]!.iconStyle!.size!,
      ),
    // status — dedicated enum ladder.
    for (final e in {
      'xs': CoreStatusSize.xs,
      'sm': CoreStatusSize.sm,
      'md': CoreStatusSize.md,
      'lg': CoreStatusSize.lg,
      'xl': CoreStatusSize.xl,
    }.entries)
      _dimAliasVar(
        'status/${e.key}',
        CoreStatusStyle.defaultsBySize[e.value]!.size!,
        description: e.value == CoreStatusSize.md ? 'Default.' : null,
      ),
  ];

  // --- Semantic / Typography (responsive role tokens, 3 modes) ------------
  // The one multi-mode dimension collection: Mobile / Tablet / Desktop, one
  // mode per viewport tier. Desktop IS the code scale — `CoreTypography.coui`
  // as authored — and each smaller mode is that scale at its tier
  // (`CoreTypography.atTier`, the same step both platforms draw): the
  // display roles step 8px per tier and the headline roles 4px, per
  // `CoreHeadingSizes.couiByTier`, while title/body/label/code stay flat.
  // Weight and line-height come from the scale's roles and do not vary by
  // mode.
  //
  // letter-spacing is the exception that emits raw: Figma wants px, and a
  // role tracks by the size it is rendered at — the two-step rule
  // `CoreTypography.coui`'s sans roles state (`CoreTrackingRule.coui`) —
  // while a monospace role keeps its own 0. The px value therefore changes
  // with the mode's font size: px = em(role, fontSize) × fontSize, so
  // `headline-small`, 16px on Mobile, tracks the smaller step there and the
  // larger one at its own 24px.
  //
  // The modes and each role's size in them come from
  // `figma_reader/typography_modes.dart`, which reads them off the scale at
  // each tier (`CoreTypography.atTier`) — so no size here can drift from what
  // the platforms draw at the same width. The components export hands the
  // same table to the plugin, so a consumer-file check compares a literal
  // against what a style draws in that file's mode.
  //
  // The rule is read before anything that steps a tier: a scale that no
  // longer states two steps stops the build here, saying why, rather than
  // inside the step.
  final tracking = couiTrackingRule(fail: _failTypography);
  final typographyModes = kTypographyModes;
  final typographyFontSizes = typographyFontSizesByMode();
  // The six role groups share weight/line-height; each group's
  // representative role supplies both (all roles in a group agree —
  // see `CoreTypography.coui`'s grouped authoring; `_typographyProblems`
  // holds every role to its group).
  final typographyGroups = <String, CoreTextStyle>{
    'display': CoreTypography.coui.displayLarge,
    'headline': CoreTypography.coui.headlineLarge,
    'title': CoreTypography.coui.titleLarge,
    'body': CoreTypography.coui.bodyMedium,
    'label': CoreTypography.coui.labelMedium,
    'code': CoreTypography.coui.codeSm,
  };
  // Every role, in ladder order, keyed the way the semantic variables are.
  // `textStyles` below is generated from this map so a role cannot exist in
  // code without a matching canvas text style — a role landing as a
  // variable but never as a style was how Button lg/xl labels ended up with
  // nothing to attach. Kept a literal map: the plugin's text-style-name
  // self-test reads the role keys from this block.
  final typographyRoles = <String, CoreTextStyle>{
    'display-large': CoreTypography.coui.displayLarge,
    'display-medium': CoreTypography.coui.displayMedium,
    'display-small': CoreTypography.coui.displaySmall,
    'headline-large': CoreTypography.coui.headlineLarge,
    'headline-medium': CoreTypography.coui.headlineMedium,
    'headline-small': CoreTypography.coui.headlineSmall,
    'title-large': CoreTypography.coui.titleLarge,
    'title-medium': CoreTypography.coui.titleMedium,
    'title-small': CoreTypography.coui.titleSmall,
    'body-large': CoreTypography.coui.bodyLarge,
    'body-medium': CoreTypography.coui.bodyMedium,
    'body-small': CoreTypography.coui.bodySmall,
    'body-xs': CoreTypography.coui.bodyXs,
    'label-xl2': CoreTypography.coui.labelXl2,
    'label-xl': CoreTypography.coui.labelXl,
    'label-large': CoreTypography.coui.labelLarge,
    'label-medium': CoreTypography.coui.labelMedium,
    'label-small': CoreTypography.coui.labelSmall,
    'label-xs': CoreTypography.coui.labelXs,
    'code-xs': CoreTypography.coui.codeXs,
    'code-sm': CoreTypography.coui.codeSm,
    'code-md': CoreTypography.coui.codeMd,
  };
  // The lists above are held to the scale, not trusted — the two hand lists
  // and the size table read off it alike: each way they can disagree with it
  // fails silently on the canvas (a missing row is a role with no variable
  // and no style; a role off its group's line binds a variable that draws
  // another line), so each stops the build here.
  final typographyProblems = _typographyProblems(
    roles: typographyRoles,
    fontSizes: typographyFontSizes,
    groups: typographyGroups,
  );
  if (typographyProblems.isNotEmpty) {
    _failTypography(
      'the export disagrees with CoreTypography.coui:\n  '
      '${typographyProblems.join('\n  ')}',
    );
  }
  // Canvas text styles — one per role, named `Group/Size` the way the live
  // library already names them (`Display/Large` …). The plugin upserts
  // these BY NAME and binds each field to the semantic variable named here:
  // size and letter-spacing follow the responsive modes, weight follows the
  // role group. Line-height is written as a PERCENT literal, not bound —
  // Figma reads a number variable bound to line-height as PIXELS whatever the
  // field's unit was (measured on a probe node: `{PERCENT,140}` + bind →
  // `{PIXELS,1.4}`), so a ratio can only reach a style as a literal. A role
  // that states a fixed line box (the code roles) is the exception: its box
  // IS px, which is how Figma reads a bound number, so it binds
  // `line-height/<group>` and ships `lineHeightPx` in place of
  // `lineHeightPercent`. The literal values ride along so the plugin can
  // load the font face and fill the unbound fallback without resolving the
  // alias chain itself.
  final textStyles = <Map<String, dynamic>>[
    for (final e in typographyRoles.entries)
      {
        'name': _textStyleNameOf(e.key),
        'role': e.key,
        // A role that names no family draws in the text face — the same
        // default both platforms apply when they convert the role.
        'fontFamily': {
          'variable':
              '$_kCollPrimitives/font/family/'
              '${e.value.fontFamily ?? CoreFontFamily.sans}',
          'value': e.value.fontFamily ?? CoreFontFamily.sans,
        },
        'fontSize': {
          'variable': '$_kCollSemanticTypography/font-size/${e.key}',
          'value': e.value.fontSize!,
        },
        'fontWeight': {
          'variable':
              '$_kCollSemanticTypography/font-weight/${_typographyGroupOf(e.key)}',
          'value': e.value.fontWeight!,
        },
        'letterSpacing': {
          'variable': '$_kCollSemanticTypography/letter-spacing/${e.key}',
          'value':
              tracking.forRole(e.value, e.value.fontSize!) * e.value.fontSize!,
        },
        if (e.value.lineHeightPx case final box?)
          'lineHeightPx': {
            'variable':
                '$_kCollSemanticTypography/line-height/'
                '${_typographyGroupOf(e.key)}',
            'value': box,
          }
        else
          'lineHeightPercent': (_lineHeightOf(e.key, e.value) * 100).round(),
        'description':
            '${e.key} · 크기 font-size/${e.key}(반응형) · 굵기 '
            'font-weight/${_typographyGroupOf(e.key)} · 행간 '
            '${_lineHeightNote(e.key, e.value)} · 자간 '
            'letter-spacing/${e.key}',
      },
  ];
  final typography = <Map<String, dynamic>>[
    for (final e in typographyFontSizes.entries)
      {
        'name': 'font-size/${e.key}',
        'type': 'FLOAT',
        'scopes': ['FONT_SIZE'],
        'valuesByMode': {
          for (var i = 0; i < typographyModes.length; i++)
            typographyModes[i]: {
              'alias':
                  '$_kCollPrimitives/font/size/${_fontSizeLeaf(e.value[i])}',
            },
        },
      },
    // A group that states a multiplier aliases its `line-height/<n>`
    // primitive — bound nowhere, since Figma would read the bound ratio as
    // px. A group that states a fixed box writes the px raw in every mode,
    // the way the letter-spacing rows write theirs: the box is not on the
    // multiplier ladder, and it is the one line-height a text style binds.
    for (final e in typographyGroups.entries)
      {
        'name': 'line-height/${e.key}',
        'type': 'FLOAT',
        'scopes': ['LINE_HEIGHT'],
        if (e.value.lineHeightPx case final box?)
          'description':
              '${e.key} 역할의 고정 줄 상자 ${box.round()}px — 배수의 별칭이 '
              '아니라 px 값이다. Figma 는 행간에 묶인 숫자를 px 로 읽으므로 '
              '${e.key} 텍스트 스타일의 행간이 이 변수에 묶인다.',
        'valuesByMode': {
          for (final mode in typographyModes)
            mode:
                e.value.lineHeightPx ??
                {
                  'alias':
                      '$_kCollPrimitives/line-height/'
                      '${_lineHeightLeaf(_lineHeightOf(e.key, e.value))}',
                },
        },
      },
    for (final e in typographyFontSizes.entries)
      {
        'name': 'letter-spacing/${e.key}',
        'type': 'FLOAT',
        'scopes': ['LETTER_SPACING'],
        'valuesByMode': {
          for (var i = 0; i < typographyModes.length; i++)
            typographyModes[i]:
                tracking.forRole(typographyRoles[e.key]!, e.value[i]) *
                e.value[i],
        },
      },
    // Size-keyed tracking, one per font-size step — the second tier a label
    // binds when it has no role to bind (`makeLabel`: role leaf first, then
    // this by rendered size). A per-size `fontSize` overlay on a role-bearing
    // default drops the role (its variable would overwrite the size), and
    // with it the only letter-spacing variable the label could reach — so
    // the tracking stayed a literal on every rung whose size departed from
    // its role, while the font size on the same node was bound to the
    // primitive step. This tier closes that half: the same rule the sans
    // roles track by, keyed the way `font/size/<n>` is. Mode-invariant
    // because the size IS the key — a breakpoint changes which size a role
    // resolves to, not what 14px tracks at.
    //
    // Sans only: the plugin binds a row here by comparing values, so a
    // monospace label's 0 never matches one and stays the literal its role
    // states.
    //
    // Named `size-<n>` under `letter-spacing/` (not `letter-spacing/<n>`)
    // so it cannot be read as a role leaf by anything that splits on `-`.
    for (final e in _kFontSizeScale.entries)
      {
        'name': 'letter-spacing/size-${e.key}',
        'type': 'FLOAT',
        'scopes': ['LETTER_SPACING'],
        'description':
            '${e.key}px 글자의 자간(px) — 역할이 없는 라벨이 크기로 묶는 '
            '2단 변수. 값은 sans 역할과 같은 규칙 '
            '(${tracking.from.round()}px 이상 ${_emPercent(tracking.above)}, '
            '아래 ${_emPercent(tracking.below)}).',
        'valuesByMode': {
          for (final mode in typographyModes)
            mode: tracking.atSize(e.value) * e.value,
        },
      },
    for (final e in typographyGroups.entries)
      {
        'name': 'font-weight/${e.key}',
        'type': 'FLOAT',
        'scopes': ['FONT_WEIGHT'],
        'valuesByMode': {
          for (final mode in typographyModes)
            mode: {
              'alias':
                  '$_kCollPrimitives/font/weight/'
                  '${_fontWeightLeaf(e.value.fontWeight!)}',
            },
        },
      },
  ];

  // --- Semantic / Surface (what a surface style does, one mode per style) --
  // A surface style bends geometry the same way on both platforms — it
  // redistributes the radius ladder and floors stroke widths — and that bend
  // is the part of a style a variable can carry. One mode per style, named
  // as code names it (the Web `data-coui-style` value), so a frame pinned to
  // a mode shows that style's corners and lines. Each value is an alias into
  // the primitive the style lands on, computed by the same seat Web and
  // Flutter read (`resolveThemeGeometry`), so the canvas cannot hold a number
  // neither platform renders.
  //
  // The material rides the same modes, as far as a number can carry it: the
  // casts the style bends (`_shadowCastRows`), the fill share and backdrop
  // blur each role's material states, whether the role is refracting glass,
  // the inset rim, and what the style contributes to a surface that authors
  // nothing (`_materialRows`). What has no number to ride on is listed there.
  final surfaceModes = [for (final id in CoreSurfaceStyleId.values) id.name];
  String bentRadius(CoreSurfaceStyleId id, double px) => _ladderLeaf(
    _kRadiusLadder,
    resolveThemeGeometry(surfaceStyle: id).radius(px),
    'radius',
  );
  String bentStroke(CoreSurfaceStyleId id, double px) => _ladderLeaf(
    _kStrokeLadder,
    resolveThemeGeometry(surfaceStyle: id).stroke(px),
    'stroke',
  );
  final surfaceGeometry = <Map<String, dynamic>>[
    for (final e in _kRadiusLadder.entries)
      {
        'name': 'radius/${e.key}',
        'type': 'FLOAT',
        'scopes': ['CORNER_RADIUS'],
        'description':
            'radius/${e.key} under each surface style — the style '
            'redistributes the radius ladder; pin a mode on a frame to see '
            'its corners.',
        'valuesByMode': {
          for (final id in CoreSurfaceStyleId.values)
            id.name: {
              'alias': '$_kCollPrimitives/radius/${bentRadius(id, e.value)}',
            },
        },
      },
    for (final e in _kStrokeLadder.entries)
      {
        'name': 'stroke/${e.key}',
        'type': 'FLOAT',
        'scopes': ['STROKE_FLOAT'],
        'description':
            'stroke/${e.key} under each surface style — a style may floor '
            'line widths; pin a mode on a frame to see its lines.',
        'valuesByMode': {
          for (final id in CoreSurfaceStyleId.values)
            id.name: {
              'alias': '$_kCollPrimitives/stroke/${bentStroke(id, e.value)}',
            },
        },
      },
    ..._shadowCastRows(),
    ..._materialRows(),
  ];

  // --- Semantic / Effect (opacity roles + focus-ring + shadow) ------------
  // Mirrors the live library's tiering: state opacities and the
  // focus-ring recipe are semantic decisions over primitives, expressed
  // as aliases; shadows are multi-layer composites Figma Variables
  // cannot hold structurally, so they stay copyable CSS strings.
  final effects = <Map<String, dynamic>>[
    for (final e in <String, double>{
      'disabled': CoreOpacity.disabled,
      'hover': CoreOpacity.hover,
      'focus': CoreOpacity.focus,
      'pressed': CoreOpacity.pressed,
      'scrim': CoreOpacity.scrim,
    }.entries)
      _aliasVar(
        'opacity/${e.key}',
        'FLOAT',
        '$_kCollPrimitives/opacity/${_opacityLeaf(e.value)}',
      ),
    // The semantic state-layer ramp (`CoreStateLayer.standard`, Button ·
    // Menu redesign §8-1). Authoring registry: a layer's opacity binds to a
    // percent FLOAT such as `opacity/70`, but no builder binds one of these
    // three rungs — the state-layer builders write the alpha as a literal —
    // the arrangement `line-height/control` has.
    for (final e in <String, double>{
      'hover': CoreStateLayer.standard.hover,
      'focus': CoreStateLayer.standard.focus,
      'pressed': CoreStateLayer.standard.pressed,
    }.entries)
      _aliasVar(
        'state-layer/${e.key}',
        'FLOAT',
        '$_kCollPrimitives/opacity/${_opacityLeaf(e.value)}',
      ),
    _aliasVar(
      'focus-ring/width',
      'FLOAT',
      '$_kCollPrimitives/stroke/${_num(CoreFocusRing.ringWidth)}',
    ),
    _aliasVar(
      'focus-ring/offset',
      'FLOAT',
      _spaceAlias(CoreFocusRing.ringOffset),
    ),
    _aliasVar(
      'focus-ring/opacity',
      'FLOAT',
      '$_kCollPrimitives/opacity/${_opacityLeaf(CoreFocusRing.ringOpacity)}',
    ),
    // Both colours come from `CoreFocusRing` itself: a token colour aliases
    // its semantic slot (`ringColor` is `focusRing`, its own slot — not
    // `primary`), and a raw one is written as its ARGB value. The band is
    // the raw case — `ringOffsetColor` is the transparent sentinel, so the
    // gap shows whatever is behind the control, and no semantic slot holds
    // "transparent" for an alias to point at.
    _coreColorVar(
      'focus-ring/color',
      CoreFocusRing.ringColor,
      defaultSemanticColorCollectionName,
    ),
    _coreColorVar(
      'focus-ring/offset-color',
      CoreFocusRing.ringOffsetColor,
      defaultSemanticColorCollectionName,
    ),
    _stringVar('shadow/none', 'none'),
    for (final e in const {
      'xs': CoreShadow.xs,
      'sm': CoreShadow.sm,
      'md': CoreShadow.md,
      'lg': CoreShadow.lg,
      'xl': CoreShadow.xl,
      '2xl': CoreShadow.xl2,
      '3xl': CoreShadow.xl3,
      'inset': CoreShadow.inset,
    }.entries)
      _stringVar('shadow/${e.key}', _cssBoxShadow(e.value)),
  ];

  // --- Semantic / Motion (easing roles, alias to raw curves) --------------
  // The four roles name what moves (enter/exit/move/feedback — the same
  // vocabulary as `CoreEasing`'s alias tier); each aliases the raw curve
  // its code constant is pinned to, resolved by value so this can never
  // say something different from `easing_scale.dart`.
  final motions = <Map<String, dynamic>>[
    for (final e in {
      'enter': CoreEasing.enter,
      'exit': CoreEasing.exit,
      'move': CoreEasing.move,
      'feedback': CoreEasing.feedback,
    }.entries)
      _aliasVar(
        'easing/${e.key}',
        'STRING',
        '$_kCollPrimitives/easing/${_easingLeaf(e.value)}',
      ),
  ];

  final doc = {
    'meta': {
      'source': 'coui_core',
      'generator': 'export_figma_tokens.dart',
      // #3740 (A-1b) — single source is docs_core/content/_data/figma_library.json;
      // moving the canonical library means editing that file only, zero code
      // changes here or in the plugin. The plugin warns (never blocks) when
      // the open document's root pluginData stamp doesn't match `identifier`.
      'canonicalLibrary': _canonicalLibrary(),
    },
    'collections': [
      {
        'name': _kCollPrimitives,
        'modes': ['Value'],
        'variables': sharedPrimitives,
      },
      // The library brand's Semantic/Color collection — one, whatever
      // `_kBrands` grows to: every other brand is a value table over it
      // (`_buildBrandTable`, written to `brands.json`), not a collection.
      for (final b in brandCollections)
        {
          'name': b.semanticColorCollectionName,
          'modes': _kSemanticModes,
          'variables': b.semantics,
        },
      // What a glyph inherits from its slot frame (`_buildContentColors`): two
      // collections, because one cannot hold the neutral tones and the status
      // tones together. They only alias the colour collection above, so they
      // follow its modes and its brand extension.
      contentColors.content,
      contentColors.status,
      {
        'name': _kCollSemanticTypography,
        'modes': typographyModes,
        'variables': typography,
      },
      {
        'name': _kCollSemanticSurface,
        'modes': surfaceModes,
        'variables': surfaceGeometry,
      },
      {
        'name': _kCollSemanticDimension,
        'modes': densityModes,
        'variables': dimensions,
      },
      {
        'name': _kCollSemanticEffect,
        'modes': ['Value'],
        'variables': effects,
      },
      {
        'name': _kCollSemanticMotion,
        'modes': ['Value'],
        'variables': motions,
      },
      {
        'name': _kCollComponent,
        'modes': ['Value'],
        'variables': components,
      },
    ],
    'textStyles': textStyles,
  };

  // Publish visibility is decided here, after every collection exists,
  // because it is a property of what the WHOLE document aliases — see
  // `_stampRampPublishVisibility`.
  final hiddenRamps = _stampRampPublishVisibility(
    brandCollections,
    sharedColourRows,
    doc['collections']! as List<Object?>,
  );

  final outFile = File('build/tokens.figma.json');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(doc),
  );

  // The brand value tables ride in the plugin bundle, not in the pasted
  // token file: a consumer file applies a brand without ever importing
  // tokens, so the plugin has to carry them (like `components.json`).
  final brandsFile = File('tools/figma-token-sync/src/data/brands.json');
  brandsFile.parent.createSync(recursive: true);
  final brandsDoc = _brandsDocument(brandCollections.first, brandTables);
  brandsFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(brandsDoc)}\n',
  );

  // The content vocabulary rides in the plugin bundle too: Generate turns a
  // token into a mode through it, and the harness seeds its collections from
  // it, so the plugin never states a mode name of its own.
  final contentFile = File(
    'tools/figma-token-sync/src/data/content-colors.json',
  );
  contentFile.parent.createSync(recursive: true);
  contentFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(contentColors.document)}\n',
  );

  stdout
    ..writeln('Wrote ${outFile.path}')
    ..writeln('Wrote ${brandsFile.path}')
    ..writeln('Wrote ${contentFile.path}')
    ..writeln(
      '  $_kCollPrimitives: ${sharedPrimitives.length} variables '
      "(shared — numeric/string tokens + the library brand's colour rows, "
      'namespaced color/<brandId>/..., + the shared groups)',
    );
  for (final MapEntry(key: namespace, value: rows)
      in sharedRowsByGroup.entries) {
    // `color/<namespace>/<hue>/<tone>` -> `<hue>`.
    final ramps = {
      for (final row in rows) (row['name']! as String).split('/')[2],
    };
    stdout.writeln(
      '    $namespace group: ${rows.length} rows / ${ramps.length} ramps '
      '(color/$namespace/<hue>/..., no brand segment)',
    );
  }
  stdout.writeln(
    '  publish-hidden colour ramps (no alias reads them): '
    '${hiddenRamps.isEmpty ? 'none' : hiddenRamps.join(', ')}',
  );
  for (final t in brandTables) {
    stdout.writeln(
      '  brand table ${t.brand.displayName}: ${t.overrides.length} slots '
      "that differ from ${libraryBrand.displayName} (an extension's "
      'overrides; the rest follows the library)',
    );
  }
  for (final b in brandCollections) {
    final linked = [
      for (final MapEntry(key: namespace, value: byMode)
          in b.sharedLinked.entries)
        '$namespace-linked=${_kSemanticModes.map((m) => byMode[m]).join('/')}',
    ];
    final shadowRows = b.semantics
        .where((v) => (v['name']! as String).startsWith(_kBrandShadowPrefix))
        .length;
    stdout.writeln(
      '  ${b.semanticColorCollectionName}: ${b.semantics.length} '
      'variables x ${_kSemanticModes.length} modes '
      '(${_kSemanticModes.join('/')})  '
      'unresolved=0  ambiguous=0  mismatches=0  dangling=0  unlinked=0  '
      '${linked.join('  ')}  '
      'shadow colours=$shadowRows  '
      'distinct primitive colours=${b.tripletCounts.length}',
    );
  }
  stdout
    ..writeln(
      '  $_kCollSemanticContent: 1 variable x '
      '${(contentColors.content['modes']! as List).length} modes '
      '(${_kContentTones.length} tones + $_kContentStatusMode) — the colour '
      'a glyph takes from the slot frame that pins the mode',
    )
    ..writeln(
      '  $_kCollSemanticContentStatus: 1 variable x '
      '${(contentColors.status['modes']! as List).length} modes '
      '(${_kContentStatuses.join("/")}, each with its on- and on-container)',
    )
    ..writeln(
      '  $_kCollSemanticTypography: ${typography.length} variables x 3 '
      'modes (Mobile/Tablet/Desktop)',
    )
    ..writeln(
      '  $_kCollSemanticDimension: ${dimensions.length} variables x '
      '${densityModes.length} modes (${densityModes.join('/')}) — '
      'control-size 6 + a11y 2 into size/*, space '
      '${_kSpaceLadder.length} into space/*, radius ${_kRadiusLadder.length} '
      'into Semantic/ Surface',
    )
    ..writeln(
      '  $_kCollSemanticEffect: ${effects.length} variables '
      '(opacity 5 + focus-ring 5 + shadow 9)',
    )
    ..writeln(
      '  $_kCollSemanticMotion: ${motions.length} variables '
      '(easing roles, all aliasing easing/*)',
    )
    ..writeln(
      '  $_kCollComponent: ${components.length} variables '
      '(icon/button/avatar/chip/checkbox/loading/list-tile/app-bar/'
      'fab/status — size/* aliases, plus button/padding-x·gap → space/*)',
    );
}

/// Stamps `hiddenFromPublishing` on every Primitives colour row — every
/// brand's and every shared group's — and returns the ramps it hid
/// (`<brandId>/<family>`, `<namespace>/<hue>`), for the summary.
///
/// **The rule — a whole ramp is hidden from the published library exactly
/// when nothing in this document aliases any step of it.** A designer never
/// binds a node to a Primitives colour (see `_buildBrandCollections`), so a
/// ramp no Semantic slot reads is not something a consumer can use: it is
/// palette kept for derivation, not vocabulary offered.
///
/// Why the ramp and not the single step: most ramps leave a step or two
/// unread in some mode (a status ramp's lightest step, say) — hiding those
/// piecemeal would publish a ramp with holes in it. The question the flag
/// answers is "does anything consume this family at all", and that is a
/// family-level fact. A shared group's hue is one ramp: a category hue's
/// thirteen tones are read across the four modes, never all in one, and a
/// syntax hue's two shades are read one per brightness.
///
/// Why a ramp would be emitted at all if it is hidden: a brand on a
/// generated palette gets every family the generator produces, whether or
/// not its mapping reads them, and a mapping may read a family's ramp only
/// to derive others from it. Deleting an unread ramp would break that
/// derivation; publishing it would offer a consumer a family the brand
/// itself never uses. Hiding is the state between. CoUI's fixed palette
/// carries only the ramps its mapping reads, so the rule hides nothing of
/// CoUI's — the rule is stated over the document, not over a brand list,
/// so a brand added later or a variable re-created by Import is judged the
/// same way rather than coming back published by default. Every shared
/// group's rows are judged by the same rule: published while a Semantic
/// slot links to the hue, hidden while none does.
///
/// The value is written on EVERY colour row, brand and shared, `false`
/// included: the importer only touches a variable whose spec carries the
/// key, so an explicit `false` is what un-hides a ramp once something
/// starts reading it. Non-colour primitives carry no key and their
/// visibility stays the file's.
List<String> _stampRampPublishVisibility(
  List<_BrandCollections> brandCollections,
  List<Map<String, dynamic>> sharedColourRows,
  List<Object?> collections,
) {
  final aliasTargets = <String>{};
  for (final collection in collections) {
    final variables = (collection! as Map)['variables']! as List<Object?>;
    for (final variable in variables) {
      final valuesByMode = (variable! as Map)['valuesByMode']! as Map;
      for (final value in valuesByMode.values) {
        if (value is Map && value['alias'] is String) {
          aliasTargets.add(value['alias']! as String);
        }
      }
    }
  }

  // `color/<brandId>/<family>/<leaf>` -> `<brandId>/<family>`, and
  // `color/<namespace>/<hue>/<tone>` -> `<namespace>/<hue>`.
  String rampOf(String path) => path.split('/').skip(1).take(2).join('/');

  final consumedRamps = {
    for (final target in aliasTargets)
      if (target.startsWith('$_kCollPrimitives/color/'))
        rampOf(target.substring(_kCollPrimitives.length + 1)),
  };
  final hidden = <String>{};
  for (final row in [
    for (final b in brandCollections) ...b.primitives,
    ...sharedColourRows,
  ]) {
    final ramp = rampOf(row['name']! as String);
    final isHidden = !consumedRamps.contains(ramp);
    row['hiddenFromPublishing'] = isHidden;
    if (isHidden) hidden.add(ramp);
  }
  return hidden.toList()..sort();
}

/// Reads the canonical-Figma-library record (#3740, A-1b) — a single small
/// JSON file, not coui_core state, so moving the library later is a
/// one-file edit with zero code changes here or in the plugin. Determinism
/// (no DateTime/Random/Platform in this exporter's output) is preserved:
/// this reads a literal file's contents, not the current time.
Map<String, dynamic> _canonicalLibrary() {
  final file = File('docs_core/content/_data/figma_library.json');
  if (!file.existsSync()) {
    return {'identifier': null, 'displayName': null, 'url': null};
  }
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    'identifier': data['identifier'],
    'displayName': data['displayName'],
    'url': data['url'],
  };
}

/// Semantic collection modes, in Figma mode order, each with the
/// brightness and contrast it reads. Single source for the mode list — the
/// scheme each mode's values come from, the shared links it states, the
/// collection's `modes` array, the per-slot `valuesByMode` keys read by the
/// integrity gate above, and the summary all walk this one list so they
/// cannot name a different set of modes. Mode names match the live library
/// file exactly (`HCLight`, no space) so Import updates the existing modes
/// instead of adding new ones.
const _kSemanticModeAxes = <(String, CoreBrightness, bool)>[
  ('Light', CoreBrightness.light, false),
  ('Dark', CoreBrightness.dark, false),
  ('HCLight', CoreBrightness.light, true),
  ('HCDark', CoreBrightness.dark, true),
];

/// The names of [_kSemanticModeAxes], in the same order.
final List<String> _kSemanticModes = [
  for (final (mode, _, _) in _kSemanticModeAxes) mode,
];

/// Collection names of the live library file ("CoUI - Cocode Design
/// System"). Import matches collections by these names, so they are what
/// lets a re-run update the designer's collections in place instead of
/// creating duplicates — a collection still carrying an ordering prefix
/// (`0. Primitives`) is renamed in place rather than duplicated
/// (`import-tokens.ts`). The space after the slash (`Semantic/ Dimension`)
/// is the file's own naming, kept as-is.
///
/// The names carry no ordering prefix: Figma's variables panel sorts
/// collections by name, so a prefix is the only thing that would hold
/// Primitives → Semantic → Component order there, and the library does
/// without it.
const _kCollPrimitives = 'Primitives';
const _kCollSemanticColor = 'Semantic/ Color';
const _kCollSemanticTypography = 'Semantic/ Typography';
const _kCollSemanticDimension = 'Semantic/ Dimension';
const _kCollSemanticEffect = 'Semantic/ Effect';
const _kCollSemanticMotion = 'Semantic/ Motion';
const _kCollSemanticSurface = 'Semantic/ Surface';
const _kCollSemanticContent = 'Semantic/ Content';
const _kCollSemanticContentStatus = 'Semantic/ Content Status';

/// The one variable each content collection holds.
const _kContentCurrent = 'content/current';
const _kContentStatus = 'content/status';
const _kCollComponent = 'Component';

/// The most modes one Figma collection can hold — measured on this file's
/// plan, Enterprise included (`Limited to 20 modes only`); an extension
/// collection lifts the number of *themes*, not this one.
const _kFigmaModeLimit = 20;

/// The tones a glyph can take from its slot, as `Semantic/ Content` modes —
/// each is the name of the `color/<name>` slot the mode reads. A mode is named
/// for the slot it aliases, so the mode a slot pins and the token the code
/// states for that glyph are the same word; the plugin reads this very list
/// (`content-colors.json`) to turn a token into a mode and never states a mode
/// of its own.
///
/// A slot is a tone when a glyph is painted with it as the colour of the
/// content it stands for. A slot that is a border, a surface or a fill is not:
/// a glyph painted with one keeps the colour Core states for it. The first mode
/// is the one a slot that pins nothing reads.
const _kContentTones = <String>[
  'on-surface',
  'on-surface-variant',
  'on-surface-subtle',
  'disabled-content',
  'on-primary',
  'on-primary-container',
  'on-secondary-container',
  'inverse-on-surface',
  'placeholder',
  'primary',
  'primary-text',
  'link',
];

/// The mode of `Semantic/ Content` that hands the choice to
/// `Semantic/ Content Status`: a slot whose glyph states a status tone pins
/// this mode there and the tone's own mode in the status collection.
const _kContentStatusMode = 'status';

/// The status families, each stated as its own tone, the tone on it, and the
/// tone on its container. They are a collection of their own because the
/// neutral tones and the status tones together are more modes than one
/// collection holds (`_kFigmaModeLimit`).
const _kContentStatuses = <String>['success', 'info', 'warning', 'error'];

/// The modes of `Semantic/ Content Status`, status family by family.
final List<String> _kContentStatusTones = [
  for (final status in _kContentStatuses) ...[
    status,
    'on-$status',
    'on-$status-container',
  ],
];

/// `--coui-neutral-100` -> `color/neutral/100`,
/// `--coui-base-white` -> `color/base/white`,
/// `--coui-neutral-grey-lightest` -> `color/neutral/grey-lightest`.
///
/// The inverse of `PrimitiveCssGenerator.primitiveVars`'s naming
/// (`'<family>/<step>'` → `--coui-<family>-<step>`): a family name never
/// holds a `-`, so splitting at the first one gives back the source's own
/// `<family>/<step>` — the Figma name and the CSS name stay one vocabulary.
///
/// Brand primitives only. A category name has three segments, and this
/// split would fold the last two into one (`color/category/red-light-fill`);
/// shared rows are named with `_sharedColorPath`.
String _colorPathFromCssVar(String cssVar) {
  final rest = cssVar.replaceFirst('--coui-', '');
  final parts = rest.split('-');
  final family = parts.first;
  final leaf = parts.skip(1).join('-');
  return 'color/$family/$leaf';
}

/// The shadow scale, keyed as the canvas names its steps (`shadow/<step>`).
const _kShadowScale = <String, List<CoreShadowLayer>>{
  'xs': CoreShadow.xs,
  'sm': CoreShadow.sm,
  'md': CoreShadow.md,
  'lg': CoreShadow.lg,
  'xl': CoreShadow.xl,
  '2xl': CoreShadow.xl2,
  '3xl': CoreShadow.xl3,
  'inset': CoreShadow.inset,
};

/// `Semantic/ Surface` rows for every layer of every shadow step — what a
/// surface style does to the casts.
///
/// A style bends a shadow the same way on both platforms
/// (`CoreSurfaceGeometryConstraint.shadow`): it scales blur and offset, adds
/// a fixed offset, replaces the opacity, and under a mirroring style gives
/// each cast a twin thrown the other way in the surface highlight. Each of
/// those is a number a variable can carry, so each layer gets rows `x` ·
/// `y` · `blur` · `color` whose value in each style's mode is the seat's
/// answer for that layer. A fifth row, `spread`, carries the layer's own
/// spread — the same in every mode, since no style touches it — so Import
/// can rebuild an effect style to the layers the code exports instead of
/// rebinding whatever layers the style happens to hold. The twin shares
/// its cast's spread row.
///
/// A cast's twin is a layer of its own (`<i>-mirror`) that exists under
/// every style, because a mode cannot add a layer — it can only change one.
/// Under a style that does not mirror, the twin is the cast's twin at zero
/// alpha: present, and drawing nothing.
///
/// The colours are literals, not aliases: a Figma alias cannot carry an
/// alpha, and every cast is a colour at the layer's own strength. The cast is
/// black, as every step of the scale is. The twin is the CoUI palette's
/// surface highlight in light mode — the modes here are styles, not
/// brightness, so a twin under dark mode draws the light highlight. That is
/// stated where the rule is written, not discovered.
List<Map<String, dynamic>> _shadowCastRows() {
  final highlight = _lightSurfaceHighlight();

  // For each style, the bent stack laid out as the canvas lays it out: one
  // entry per authored layer, each with its twin (or null when the style
  // does not mirror, or the layer is inset).
  List<({CoreShadowLayer cast, CoreShadowLayer? twin})> bent(
    CoreSurfaceStyleId id,
    List<CoreShadowLayer> layers,
  ) {
    final geometry = resolveThemeGeometry(surfaceStyle: id);
    final out = geometry.shadow(layers);
    final rows = <({CoreShadowLayer cast, CoreShadowLayer? twin})>[];
    var k = 0;
    for (final authored in layers) {
      final cast = out[k++];
      final twin = geometry.shadowMirror && !authored.inset ? out[k++] : null;
      rows.add((cast: cast, twin: twin));
    }

    return rows;
  }

  Map<String, dynamic> row(
    String name,
    String type,
    List<String> scopes,
    Object Function(CoreSurfaceStyleId) value,
  ) => {
    'name': name,
    'type': type,
    'scopes': scopes,
    'valuesByMode': {
      for (final id in CoreSurfaceStyleId.values) id.name: value(id),
    },
  };

  return [
    for (final step in _kShadowScale.entries)
      for (var i = 0; i < step.value.length; i++) ...[
        row(
          'shadow/${step.key}/$i/x',
          'FLOAT',
          ['EFFECT_FLOAT'],
          (id) => bent(id, step.value)[i].cast.offsetX,
        ),
        row(
          'shadow/${step.key}/$i/y',
          'FLOAT',
          ['EFFECT_FLOAT'],
          (id) => bent(id, step.value)[i].cast.offsetY,
        ),
        row(
          'shadow/${step.key}/$i/blur',
          'FLOAT',
          ['EFFECT_FLOAT'],
          (id) => bent(id, step.value)[i].cast.blurRadius,
        ),
        row(
          'shadow/${step.key}/$i/color',
          'COLOR',
          ['EFFECT_COLOR'],
          (id) => _rgba(_kCastBlack, bent(id, step.value)[i].cast.opacity),
        ),
        row(
          'shadow/${step.key}/$i/spread',
          'FLOAT',
          ['EFFECT_FLOAT'],
          (id) => bent(id, step.value)[i].cast.spreadRadius,
        ),
        if (!step.value[i].inset) ...[
          row(
            'shadow/${step.key}/$i-mirror/x',
            'FLOAT',
            ['EFFECT_FLOAT'],
            (id) => bent(id, step.value)[i].twin?.offsetX ?? 0.0,
          ),
          row(
            'shadow/${step.key}/$i-mirror/y',
            'FLOAT',
            ['EFFECT_FLOAT'],
            (id) => bent(id, step.value)[i].twin?.offsetY ?? 0.0,
          ),
          row(
            'shadow/${step.key}/$i-mirror/blur',
            'FLOAT',
            ['EFFECT_FLOAT'],
            (id) =>
                (bent(id, step.value)[i].twin ?? bent(id, step.value)[i].cast)
                    .blurRadius,
          ),
          row(
            'shadow/${step.key}/$i-mirror/color',
            'COLOR',
            ['EFFECT_COLOR'],
            (id) => switch (bent(id, step.value)[i].twin) {
              final twin? => _rgba(highlight.argb, twin.opacity),
              null => _rgba(highlight.argb, 0),
            },
          ),
        ],
      ],
  ];
}

/// The colour every cast of the shadow scale is drawn in.
const _kCastBlack = 0xFF000000;

/// The CoUI palette's surface highlight in light mode — the tint a mirror
/// twin and the inset rim are drawn in.
///
/// Light only, because the modes of `Semantic/ Surface` are styles, not
/// brightness: a literal holds one colour, and the light one is what the
/// code paints on the light canvas a designer reviews first.
CoreColor _lightSurfaceHighlight() {
  final scheme = resolveThemeSchemeFrom(
    CouiColorPresets.source,
    brightness: .light,
  );
  // The same fallback the painted value takes when a palette states none.
  // A resolved scheme states every surface slot; the bang documents that
  // rather than guarding a case the seat cannot produce.
  return scheme.surfaceHighlight ?? deriveSurfaceHighlight(scheme.surface!);
}

/// An ARGB colour at [alpha], as Figma's `{ r, g, b, a }` (0–1).
Map<String, double> _rgba(int argb, double alpha) => {
  'r': ((argb >> 16) & 0xFF) / _kColorChannelMax,
  'g': ((argb >> 8) & 0xFF) / _kColorChannelMax,
  'b': (argb & 0xFF) / _kColorChannelMax,
  'a': alpha,
};

/// How much of a Figma blur *radius* the platforms' blur argument is.
///
/// Figma states a blur as a radius that spans the whole fall-off, while both
/// backdrop passes take the Gaussian's standard deviation — CSS
/// `backdrop-filter: blur(σ)` on Web, `ImageFilter.blur(sigmaX: σ)` on
/// Flutter — which is half of it. The Web adapter states the same factor for
/// the layer blurs it converts (`kFigmaBlurRadiusToCssBlur`); it is restated
/// here rather than imported because this script reads `coui_core` alone.
const double _kFigmaBlurRadiusToSigma = 0.5;

/// `Semantic/ Surface` rows for the material a style gives a surface — the
/// part of it a number can carry — and for what the style contributes to a
/// surface or control that authors nothing.
///
/// Per role (`material/<role>/…`), read from that role's material at depth 0
/// (`CoreSurfaceRecipe.surfaceFor`), the seat both platforms ask:
///
/// * `fill-opacity` — the share of the fill that shows, as an alias into the
///   `Primitives/opacity` percent ladder; 100 where the style states no
///   material.
/// * `backdrop-blur` — the frost, as a Figma blur radius (the platforms' σ
///   over [_kFigmaBlurRadiusToSigma]); 0 where none.
/// * `glass` — whether the surface bends what is behind its edge: the style
///   states a refraction and the role's material is glass. The bend is a
///   GLASS effect, which takes no variable, so its dials travel as
///   `components.json`'s `surfaceGlass` table and this row only switches the
///   layer that carries them.
///
/// Shared (`material/rim/<n>/…`): the inset rim a style adds
/// (`CoreSurfaceGeometryConstraint.highlightRim`), an `x` · `y` · `blur` ·
/// `color` group per layer, at zero alpha under a style with fewer layers.
///
/// Contributions: `material/control-border` is the boundary a style gives a
/// surface that draws none (`controlBorder`), aliased onto the stroke ladder
/// and 0 under a style that gives none; `material/control-shadow/<n>/…` is the
/// cast it gives a control that casts none (`controlShadow`), at zero alpha
/// under a style that gives none — a mode can change a layer, not add one.
///
/// ## What does not carry
///
/// * **The dark-mode fill share.** The modes here are styles, not
///   brightness, so the rows hold the light value; a material that states a
///   different share for dark (a pair, `CoreSurfaceOpacity`) shows its light
///   share in both colour modes.
/// * **Saturation and backdrop brightness.** Figma's background blur has no
///   chroma lift and no dimming term; the canvas shows the blurred backdrop
///   without them.
/// * **The edge sheen** — the two outline runs, the bevel's crescents and the
///   rim crest, which the platforms paint per element from its own rectangle.
///   The GLASS effect's light stands in for the bevel only.
/// * **Nested depth.** A surface inside a surface keeps the depth-0 material:
///   the nesting table is a statement about the tree, and a frame's mode
///   cannot see what it sits in.
/// * **Colour modes for the rim and the contributed cast.** Both are literals
///   — an alias cannot carry an alpha — so the rim is the light highlight and
///   the cast is black, as the cast rows above are.
List<Map<String, dynamic>> _materialRows() {
  Map<String, dynamic> row(
    String name,
    String type,
    List<String>? scopes,
    String description,
    Object Function(CoreSurfaceStyleId) value,
  ) => {
    'name': name,
    'type': type,
    // A BOOLEAN takes no scope: Figma offers it to a layer's visibility and
    // nothing else, so there is nothing to narrow.
    'scopes': ?scopes,
    'description': description,
    'valuesByMode': {
      for (final id in CoreSurfaceStyleId.values) id.name: value(id),
    },
  };

  CoreSurfaceToken? material(CoreSurfaceStyleId id, CoreSurfaceRole role) =>
      resolveThemeRecipe(surfaceStyle: id).surfaceFor(role);
  CoreSurfaceGeometryConstraint geometry(CoreSurfaceStyleId id) =>
      resolveThemeGeometry(surfaceStyle: id);

  // A layer the rows cannot hold fails here rather than drawing a different
  // layer on the canvas: the rows carry offset, blur and colour, and the
  // plugin draws a rim inset and a contributed cast outside, each with no
  // spread.
  for (final id in CoreSurfaceStyleId.values) {
    for (final l in geometry(id).highlightRim) {
      if (!l.inset || l.spreadRadius != 0) {
        throw StateError(
          '${id.name} states a rim layer that is not an inset with no spread '
          '— material/rim/* has no row for it',
        );
      }
    }
    for (final l in geometry(id).controlShadow) {
      if (l.inset || l.spreadRadius != 0) {
        throw StateError(
          '${id.name} contributes a control shadow that is not an outer cast '
          'with no spread — material/control-shadow/* has no row for it',
        );
      }
    }
  }
  int most(List<CoreShadowLayer> Function(CoreSurfaceStyleId) layers) =>
      CoreSurfaceStyleId.values
          .map((id) => layers(id).length)
          .fold(0, (a, b) => a > b ? a : b);
  final rimLayers = most((id) => geometry(id).highlightRim);
  final castLayers = most((id) => geometry(id).controlShadow);
  final highlight = _lightSurfaceHighlight();
  // The leaves the two aliasing rows point at — off the ladder fails the
  // export, the contract every other aliasing row here keeps.
  String fillLeaf(CoreSurfaceStyleId id, CoreSurfaceRole role) => _opacityLeaf(
    material(id, role)?.opacity.resolve(.light) ??
        CoreSurfaceOpacity.opaqueValue,
  );
  String borderLeaf(CoreSurfaceStyleId id) => _ladderLeaf(
    _kStrokeLadder,
    geometry(id).controlBorder ?? CoreStrokeWidth.stroke0,
    'stroke',
  );

  // One layer of [layers] as four rows, zero alpha where a style has fewer.
  List<Map<String, dynamic>> layerRows(
    String prefix,
    String what,
    int argb,
    List<CoreShadowLayer> Function(CoreSurfaceStyleId) layers,
    int i,
  ) {
    CoreShadowLayer? at(CoreSurfaceStyleId id) =>
        i < layers(id).length ? layers(id)[i] : null;

    return [
      row(
        '$prefix/$i/x',
        'FLOAT',
        ['EFFECT_FLOAT'],
        '$what layer $i, horizontal offset, under each surface style.',
        (id) => at(id)?.offsetX ?? 0.0,
      ),
      row(
        '$prefix/$i/y',
        'FLOAT',
        ['EFFECT_FLOAT'],
        '$what layer $i, vertical offset, under each surface style.',
        (id) => at(id)?.offsetY ?? 0.0,
      ),
      row(
        '$prefix/$i/blur',
        'FLOAT',
        ['EFFECT_FLOAT'],
        '$what layer $i, blur, under each surface style.',
        (id) => at(id)?.blurRadius ?? 0.0,
      ),
      row(
        '$prefix/$i/color',
        'COLOR',
        ['EFFECT_COLOR'],
        '$what layer $i, colour at its strength — zero alpha under a style '
            'that states no such layer.',
        (id) => _rgba(argb, at(id)?.opacity ?? 0),
      ),
    ];
  }

  return [
    for (final role in CoreSurfaceRole.values) ...[
      row(
        'material/${role.name}/fill-opacity',
        'FLOAT',
        ['OPACITY'],
        'How much of the fill of a ${role.name} surface shows under each '
            'surface style (the light-mode share) — bound to the opacity of '
            'the layer that carries the fill.',
        (id) => {'alias': '$_kCollPrimitives/opacity/${fillLeaf(id, role)}'},
      ),
      row(
        'material/${role.name}/backdrop-blur',
        'FLOAT',
        ['EFFECT_FLOAT'],
        'The frost behind a ${role.name} surface under each surface style, '
            'as a Figma blur radius — 0 where the style states none.',
        (id) =>
            (material(id, role)?.blurRadius ?? 0) / _kFigmaBlurRadiusToSigma,
      ),
      row(
        'material/${role.name}/glass',
        'BOOLEAN',
        null,
        'Whether a ${role.name} surface bends what is behind its edge under '
            'each surface style — shows the layer carrying the GLASS effect.',
        (id) =>
            resolveThemeRecipe(surfaceStyle: id).refraction != null &&
            material(id, role)?.type == SurfaceType.glass,
      ),
    ],
    for (var i = 0; i < rimLayers; i++)
      ...layerRows(
        'material/rim',
        'The inset rim a style adds to a surface',
        highlight.argb,
        (id) => geometry(id).highlightRim,
        i,
      ),
    row(
      'material/control-border',
      'FLOAT',
      ['STROKE_FLOAT'],
      'The boundary a surface style gives a surface that draws none — 0 under '
          'a style that gives none.',
      (id) => {'alias': '$_kCollPrimitives/stroke/${borderLeaf(id)}'},
    ),
    for (var i = 0; i < castLayers; i++)
      ...layerRows(
        'material/control-shadow',
        'The cast a style gives a control that casts none',
        _kCastBlack,
        (id) => geometry(id).controlShadow,
        i,
      ),
  ];
}

/// Max 8-bit color channel value, for 0–255 -> 0–1 conversion.
const _kColorChannelMax = 255.0;

/// `'98 0 238'` (0–255 triplet) -> `{ r, g, b, a }` (0–1) for Figma COLOR.
Map<String, double> _rgb(String triplet) {
  final parts = triplet.trim().split(RegExp(r'\s+'));
  return {
    'r': int.parse(parts[0]) / _kColorChannelMax,
    'g': int.parse(parts[1]) / _kColorChannelMax,
    'b': int.parse(parts[2]) / _kColorChannelMax,
    'a': 1.0,
  };
}

Map<String, dynamic> _colorVariable(
  String path,
  String triplet, {
  required String mode,
}) => {
  'name': path,
  'type': 'COLOR',
  'valuesByMode': {mode: _rgb(triplet)},
};

/// Returns `{ alias: 'Primitives/...' }` when the resolved triplet matches a
/// primitive color, otherwise a raw `{ r, g, b, a }` value.
Map<String, dynamic> _aliasOrColor(
  String triplet,
  Map<String, String> tripletToAlias,
) {
  final alias = tripletToAlias[triplet];
  if (alias != null) return {'alias': alias};
  return _rgb(triplet);
}

/// A single numeric/string primitive token row.
class _NumToken {
  const _NumToken(
    this.group,
    this.leaf,
    this.value, {
    this.type = 'FLOAT',
    this.description,
    this.scopes,
  });

  final String group;
  final String leaf;
  final Object value;
  final String type;
  final String? description;

  /// Figma variable scopes (e.g. `WIDTH_HEIGHT`, `GAP`) — restricts
  /// where the variable is offered in Figma's binding pickers, so the
  /// tool enforces the Size/Space namespace boundary the code enforces
  /// with lint (CoUI_Size_Token_Specification §5).
  final List<String>? scopes;

  Map<String, dynamic> toVariable() => {
    'name': '$group/$leaf',
    'type': type,
    if (description != null) 'description': description,
    if (scopes != null) 'scopes': scopes,
    'valuesByMode': {'Value': value},
  };
}

/// The 24-token Size primitive ladder (CoUI_Size_Token_Specification
/// §1, v1.1) — single source for the `size/<n>` primitives *and* for
/// [_sizeAlias]'s reverse lookup, so an alias can never point at a leaf
/// this exporter did not emit.
const _kLayoutLadder = <String, double>{
  '160': CoreLayout.layout160,
  '240': CoreLayout.layout240,
  '248': CoreLayout.layout248,
  '280': CoreLayout.layout280,
  '320': CoreLayout.layout320,
  '400': CoreLayout.layout400,
  '560': CoreLayout.layout560,
  '640': CoreLayout.layout640,
};

/// The spacing primitives (`Primitives/space/<n>`), keyed by leaf. One
/// list feeds both the primitive rows and [_spaceAlias]'s reverse lookup,
/// so a component token can only alias a leaf that is actually exported.
const _kSpaceLadder = <String, double>{
  '0': CoreSpace.space0,
  '2': CoreSpace.space2,
  '4': CoreSpace.space4,
  '6': CoreSpace.space6,
  '8': CoreSpace.space8,
  '10': CoreSpace.space10,
  '12': CoreSpace.space12,
  '14': CoreSpace.space14,
  '16': CoreSpace.space16,
  '18': CoreSpace.space18,
  '20': CoreSpace.space20,
  '24': CoreSpace.space24,
  '28': CoreSpace.space28,
  '32': CoreSpace.space32,
  '36': CoreSpace.space36,
  '40': CoreSpace.space40,
  '44': CoreSpace.space44,
  '48': CoreSpace.space48,
  '52': CoreSpace.space52,
  '56': CoreSpace.space56,
  '60': CoreSpace.space60,
  '64': CoreSpace.space64,
  '72': CoreSpace.space72,
  '80': CoreSpace.space80,
  '88': CoreSpace.space88,
  '96': CoreSpace.space96,
  '104': CoreSpace.space104,
  '112': CoreSpace.space112,
  '120': CoreSpace.space120,
  '128': CoreSpace.space128,
  '136': CoreSpace.space136,
  '144': CoreSpace.space144,
  '152': CoreSpace.space152,
  '160': CoreSpace.space160,
  '168': CoreSpace.space168,
  '176': CoreSpace.space176,
  '184': CoreSpace.space184,
  '192': CoreSpace.space192,
  '200': CoreSpace.space200,
  '208': CoreSpace.space208,
  '216': CoreSpace.space216,
  '224': CoreSpace.space224,
  '232': CoreSpace.space232,
  '240': CoreSpace.space240,
  '248': CoreSpace.space248,
  '256': CoreSpace.space256,
};

/// The stroke-width primitives (`Primitives/stroke/<n>`), keyed by leaf.
/// Read by the primitive rows and by `Semantic/ Surface`, whose per-style
/// rows alias back into it.
const _kStrokeLadder = <String, double>{
  '0': CoreStrokeWidth.stroke0,
  // `_`, not `.`: Figma refuses a `.` in a variable name, so a fractional
  // step is `stroke/0_5` · `stroke/1_5` — the same spelling the code names
  // (`stroke0_5`, `--coui-stroke-width-0_5`) already use.
  '0_5': CoreStrokeWidth.stroke0_5,
  '1': CoreStrokeWidth.stroke1,
  '1_5': CoreStrokeWidth.stroke1_5,
  '2': CoreStrokeWidth.stroke2,
  '3': CoreStrokeWidth.stroke3,
  '4': CoreStrokeWidth.stroke4,
  '5': CoreStrokeWidth.stroke5,
  '6': CoreStrokeWidth.stroke6,
  '8': CoreStrokeWidth.stroke8,
};

/// The leaf of [ladder] whose value is [value] — the inverse lookup the
/// surface rows need to alias a bent value back onto its primitive.
///
/// Throws when the value is off the ladder: a style that bent a radius or a
/// stroke to a number the ladder has no step for would otherwise export a
/// dangling alias, and the plugin would bind nothing without saying so.
String _ladderLeaf(Map<String, double> ladder, double value, String group) {
  for (final e in ladder.entries) {
    if (e.value == value) return e.key;
  }
  throw StateError('$group $value is not on the $group ladder');
}

/// The radius primitives (`Primitives/radius/<n>`), keyed by leaf. Read by
/// the primitive rows and by `Semantic/ Surface`, whose per-style rows alias
/// back into it.
const _kRadiusLadder = <String, double>{
  '0': CoreRadius.radius0,
  '2': CoreRadius.radius2,
  '4': CoreRadius.radius4,
  '6': CoreRadius.radius6,
  '8': CoreRadius.radius8,
  '10': CoreRadius.radius10,
  '12': CoreRadius.radius12,
  '14': CoreRadius.radius14,
  '16': CoreRadius.radius16,
  '20': CoreRadius.radius20,
  '24': CoreRadius.radius24,
  '28': CoreRadius.radius28,
  '32': CoreRadius.radius32,
  '36': CoreRadius.radius36,
  '40': CoreRadius.radius40,
  '48': CoreRadius.radius48,
  '56': CoreRadius.radius56,
  '64': CoreRadius.radius64,
  '9999': CoreRadius.radius9999,
};

const _kSizeLadder = <String, double>{
  '4': CoreSize.size4,
  '6': CoreSize.size6,
  '8': CoreSize.size8,
  '10': CoreSize.size10,
  '12': CoreSize.size12,
  '14': CoreSize.size14,
  '16': CoreSize.size16,
  '18': CoreSize.size18,
  '20': CoreSize.size20,
  '24': CoreSize.size24,
  '28': CoreSize.size28,
  '32': CoreSize.size32,
  '36': CoreSize.size36,
  '40': CoreSize.size40,
  '44': CoreSize.size44,
  '48': CoreSize.size48,
  '56': CoreSize.size56,
  '64': CoreSize.size64,
  '72': CoreSize.size72,
  '80': CoreSize.size80,
  '88': CoreSize.size88,
  '96': CoreSize.size96,
  '112': CoreSize.size112,
  '128': CoreSize.size128,
};

/// Resolves a dimension value to its `Primitives/size/<n>` alias path.
///
/// Throws (failing the build) when the value is not on the primitive
/// ladder — a Semantic/Component dimension token referencing a value
/// the palette does not contain is the dimension-axis version of the
/// colour integrity gate above (`primitive-governs-component`), so it
/// must never silently emit a raw number.
String _sizeAlias(double value) {
  final leaf = _kSizeLadder.entries
      .where((e) => e.value == value)
      .map((e) => e.key)
      .firstOrNull;
  if (leaf == null) {
    stderr.writeln(
      '❌ dimension value $value is not on the size primitive ladder '
      '(CoUI_Size_Token_Specification §1) — add the primitive first or '
      'fix the component token.',
    );
    exit(1);
  }
  return '$_kCollPrimitives/size/$leaf';
}

/// Numeric opacity scale, leaf key -> value — single source for the
/// `opacity/<n>` primitives *and* the semantic-opacity / focus-ring
/// alias reverse lookup in [_opacityLeaf].
String _spaceAlias(double value) {
  final leaf = _kSpaceLadder.entries
      .where((e) => e.value == value)
      .map((e) => e.key)
      .firstOrNull;
  if (leaf == null) {
    stderr.writeln(
      '❌ spacing value $value is not on the space primitive ladder — add '
      'the primitive first or fix the component token.',
    );
    exit(1);
  }
  return '$_kCollPrimitives/space/$leaf';
}

const _kOpacityScale = <String, double>{
  '0': CoreOpacity.opacity0,
  '3': CoreOpacity.opacity3,
  '5': CoreOpacity.opacity5,
  '8': CoreOpacity.opacity8,
  '10': CoreOpacity.opacity10,
  '12': CoreOpacity.opacity12,
  '15': CoreOpacity.opacity15,
  '16': CoreOpacity.opacity16,
  '20': CoreOpacity.opacity20,
  '25': CoreOpacity.opacity25,
  '30': CoreOpacity.opacity30,
  '40': CoreOpacity.opacity40,
  '50': CoreOpacity.opacity50,
  '60': CoreOpacity.opacity60,
  '70': CoreOpacity.opacity70,
  '75': CoreOpacity.opacity75,
  '80': CoreOpacity.opacity80,
  '85': CoreOpacity.opacity85,
  '90': CoreOpacity.opacity90,
  '95': CoreOpacity.opacity95,
  '100': CoreOpacity.opacity100,
};

/// Resolves an opacity value to its numeric-scale leaf. Throws (failing
/// the build) when the value is off-scale — a semantic opacity that the
/// numeric palette does not contain must not silently emit raw.
String _opacityLeaf(double value) {
  final leaf = _kOpacityScale.entries
      .where((e) => e.value == value)
      .map((e) => e.key)
      .firstOrNull;
  if (leaf == null) {
    stderr.writeln(
      '❌ opacity value $value is not on the numeric opacity scale — add '
      'the primitive first or fix the semantic token.',
    );
    exit(1);
  }
  return leaf;
}

/// Font-size scale, leaf key -> value — single source for the
/// `font/size/<n>` primitives *and* the typography-semantic reverse
/// lookup in [_fontSizeLeaf].
const _kFontSizeScale = <String, double>{
  '10': CoreFontSize.s10,
  '11': CoreFontSize.s11,
  '12': CoreFontSize.s12,
  '13': CoreFontSize.s13,
  '14': CoreFontSize.s14,
  '15': CoreFontSize.s15,
  '16': CoreFontSize.s16,
  '18': CoreFontSize.s18,
  '20': CoreFontSize.s20,
  '24': CoreFontSize.s24,
  '28': CoreFontSize.s28,
  '32': CoreFontSize.s32,
  '36': CoreFontSize.s36,
  '40': CoreFontSize.s40,
  '44': CoreFontSize.s44,
  '48': CoreFontSize.s48,
  '52': CoreFontSize.s52,
  '60': CoreFontSize.s60,
  '72': CoreFontSize.s72,
  '96': CoreFontSize.s96,
  '128': CoreFontSize.s128,
};

/// Font-weight scale, leaf key -> value — single source for the
/// `font/weight/<key>` primitives *and* [_fontWeightLeaf].
const _kFontWeightScale = <String, int>{
  'thin': CoreFontWeight.thin,
  'extralight': CoreFontWeight.extraLight,
  'light': CoreFontWeight.light,
  'regular': CoreFontWeight.regular,
  'medium': CoreFontWeight.medium,
  'semibold': CoreFontWeight.semiBold,
  'bold': CoreFontWeight.bold,
  'extrabold': CoreFontWeight.extraBold,
  'black': CoreFontWeight.black,
};

/// Line-height scale, leaf key -> value — single source for the
/// `line-height/<n>` primitives *and* [_lineHeightLeaf].
const _kLineHeightScale = <String, double>{
  '100': CoreLineHeight.h100,
  '120': CoreLineHeight.h120,
  '140': CoreLineHeight.h140,
  '150': CoreLineHeight.h150,
  '160': CoreLineHeight.h160,
  '180': CoreLineHeight.h180,
  '200': CoreLineHeight.h200,
};

/// Reverse lookups for the typography-semantic aliases — same
/// fail-the-build contract as [_sizeAlias] / [_opacityLeaf]: a semantic
/// value that is not on its primitive scale must never silently emit raw.
String _scaleLeafOf(String scaleName, Map<String, num> scale, num value) {
  final leaf = scale.entries
      .where((e) => e.value == value)
      .map((e) => e.key)
      .firstOrNull;
  if (leaf == null) {
    stderr.writeln(
      '❌ $scaleName value $value is not on its primitive scale — add the '
      'primitive first or fix the semantic token.',
    );
    exit(1);
  }
  return leaf;
}

/// What keeps the typography export's hand lists from matching the scale —
/// empty when they match.
///
/// [roles] and [fontSizes] must list `CoreTextStyles.values` in order (a
/// role with no row has no variable and no canvas style, and the JSON
/// follows this order); every role must be `CoreTypography.coui`'s role of
/// that name, draw its own size at Desktop, state a line, and share weight
/// and line with its group's row in [groups].
List<String> _typographyProblems({
  required Map<String, CoreTextStyle> roles,
  required Map<String, List<double>> fontSizes,
  required Map<String, CoreTextStyle> groups,
}) {
  final order = [for (final t in CoreTextStyles.values) t.name].join(', ');
  final problems = <String>[
    for (final (list, keys) in [
      ('typographyRoles', roles.keys),
      ('typographyFontSizes', fontSizes.keys),
    ])
      if (keys.join(', ') != order)
        '$list lists ${keys.join(', ')} — CoreTextStyles.values is $order',
  ];
  for (final token in CoreTextStyles.values) {
    final name = token.name;
    final role = roles[name];
    // Already reported by the order check above.
    if (role == null) continue;
    if (role != token.read(CoreTypography.coui)) {
      problems.add("$name is not CoreTypography.coui's $name");
    }
    if (fontSizes[name]?.last != role.fontSize) {
      problems.add(
        '$name draws ${fontSizes[name]?.last} at Desktop, '
        'not its own ${role.fontSize}',
      );
    }
    if (role.lineHeight == null && role.lineHeightPx == null) {
      problems.add('$name states neither lineHeight nor lineHeightPx');
    }
    final group = _typographyGroupOf(name);
    final groupRole = groups[group];
    if (groupRole == null) {
      problems.add('$name has no `$group` group row');
    } else if (groupRole.fontWeight != role.fontWeight ||
        groupRole.lineHeight != role.lineHeight ||
        groupRole.lineHeightPx != role.lineHeightPx) {
      problems.add(
        '$name differs from its `$group` group in weight or line — the '
        'group row is the variable its text style binds',
      );
    }
  }
  return problems;
}

/// The group a role belongs to — the folder of its text style and the
/// leaf of its `font-weight/*` and `line-height/*` rows.
String _typographyGroupOf(String role) => role.split('-').first;

/// The line-height multiplier [style] states. `_typographyProblems` has
/// stopped the build for a role that states neither a multiplier nor a box,
/// so this only fails if it is ever called on a box-only role.
double _lineHeightOf(String role, CoreTextStyle style) =>
    style.lineHeight ??
    _failTypography('$role states a line box, not a multiplier');

/// The line a text style's description names — the bound box for a role
/// that states one, else the percent literal.
String _lineHeightNote(String role, CoreTextStyle style) =>
    switch (style.lineHeightPx) {
      final box? =>
        'line-height/${_typographyGroupOf(role)} (${box.round()}px)',
      null => '${(_lineHeightOf(role, style) * 100).round()}%',
    };

/// `-0.02` → `-2%` — an em tracking ratio as the percent a designer reads.
String _emPercent(double em) {
  final percent = (em * 1000).round() / 10;
  return percent == percent.truncateToDouble()
      ? '${percent.toInt()}%'
      : '$percent%';
}

/// Stops the build over a typography export that cannot be written
/// faithfully — the same fail-the-build contract as [_scaleLeafOf].
Never _failTypography(String problem) {
  stderr.writeln('❌ typography export: $problem');
  exit(1);
}

/// Reverse lookup on the raw easing scale — same fail-the-build
/// contract as the numeric leaf helpers.
String _easingLeaf(CoreCubicBezier value) {
  final leaf = _kEasingRawScale.entries
      .where((e) => e.value == value)
      .map((e) => e.key)
      .firstOrNull;
  if (leaf == null) {
    stderr.writeln(
      '❌ easing curve has no raw primitive on the easing scale — add the '
      'primitive first or fix the alias.',
    );
    exit(1);
  }
  return leaf;
}

/// `display-large` → `Display/Large`, `label-xl2` → `Label/XL2`,
/// `code-sm` → `Code/SM` — the live library's style naming (group folder,
/// size leaf). A leaf that abbreviates a size — one or two letters, then an
/// optional rung number (`xs` · `sm` · `md` · `xl` · `xl2`) — is spelled in
/// capitals the way it reads; a word leaf (`large` · `medium` · `small`) is
/// capitalised. The plugin upserts styles BY NAME, so the rule may only ever
/// add names: every word leaf and both xl rungs keep the spelling the
/// library already publishes.
String _textStyleNameOf(String role) {
  final parts = role.split('-');
  String cap(String s) => s[0].toUpperCase() + s.substring(1);
  final leaf = RegExp(r'^[a-z]{1,2}\d*$').hasMatch(parts[1])
      ? parts[1].toUpperCase()
      : cap(parts[1]);
  return '${cap(parts[0])}/$leaf';
}

String _fontSizeLeaf(double v) => _scaleLeafOf('font/size', _kFontSizeScale, v);
String _fontWeightLeaf(int v) =>
    _scaleLeafOf('font/weight', _kFontWeightScale, v);
String _lineHeightLeaf(double v) =>
    _scaleLeafOf('line-height', _kLineHeightScale, v);

/// Raw duration scale (ms), leaf key -> value — single source for the
/// `duration/<leaf>` primitives below.
const _kDurationRawScale = <String, int>{
  '0': CoreDuration.ms0,
  '50': CoreDuration.ms50,
  '100': CoreDuration.ms100,
  '150': CoreDuration.ms150,
  '200': CoreDuration.ms200,
  '250': CoreDuration.ms250,
  '300': CoreDuration.ms300,
  '350': CoreDuration.ms350,
  '400': CoreDuration.ms400,
  '450': CoreDuration.ms450,
  '500': CoreDuration.ms500,
  '1000': CoreDuration.ms1000,
  '2000': CoreDuration.ms2000,
  '3000': CoreDuration.ms3000,
  '4000': CoreDuration.ms4000,
  '5000': CoreDuration.ms5000,
  'indeterminate': CoreDuration.indeterminate,
};

/// Tier line for a raw `duration/<leaf>` variable, mirroring
/// `CoreReducedMotion.resolve`'s own branches so the reduced-motion
/// boundary (`CoreReducedMotion.transitionCeilingMs`) is legible from the
/// Figma variable itself rather than only from `coui_core` source.
String _durationTierDescription(int ms) {
  const ceiling = CoreReducedMotion.transitionCeilingMs;
  if (ms <= 0) {
    return 'Already 0ms — unaffected by the reduced-motion override.';
  }
  if (ms <= ceiling) {
    return 'Transition tier (0–${ceiling}ms) — suppressed to 0ms under '
        'reduced motion.';
  }
  return 'Display tier (> ${ceiling}ms) — preserved under reduced motion; '
      'answers "how long", not "how fast".';
}

/// Raw easing scale, kebab-case leaf key -> cubic-bezier value — single
/// source for the `easing/<leaf>` primitives below.
const _kEasingRawScale = <String, CoreCubicBezier>{
  'linear': CoreEasing.linear,
  'ease': CoreEasing.ease,
  'ease-in': CoreEasing.easeIn,
  'ease-out': CoreEasing.easeOut,
  'ease-in-out': CoreEasing.easeInOut,
  'ease-in-sine': CoreEasing.easeInSine,
  'ease-out-sine': CoreEasing.easeOutSine,
  'ease-in-out-sine': CoreEasing.easeInOutSine,
  'ease-in-quad': CoreEasing.easeInQuad,
  'ease-out-quad': CoreEasing.easeOutQuad,
  'ease-in-out-quad': CoreEasing.easeInOutQuad,
  'ease-in-cubic': CoreEasing.easeInCubic,
  'ease-out-cubic': CoreEasing.easeOutCubic,
  'ease-in-out-cubic': CoreEasing.easeInOutCubic,
  'ease-in-quart': CoreEasing.easeInQuart,
  'ease-out-quart': CoreEasing.easeOutQuart,
  'ease-in-out-quart': CoreEasing.easeInOutQuart,
  'ease-in-quint': CoreEasing.easeInQuint,
  'ease-out-quint': CoreEasing.easeOutQuint,
  'ease-in-out-quint': CoreEasing.easeInOutQuint,
  'ease-in-expo': CoreEasing.easeInExpo,
  'ease-out-expo': CoreEasing.easeOutExpo,
  'ease-in-out-expo': CoreEasing.easeInOutExpo,
  'ease-in-circ': CoreEasing.easeInCirc,
  'ease-out-circ': CoreEasing.easeOutCirc,
  'ease-in-out-circ': CoreEasing.easeInOutCirc,
  'ease-in-back': CoreEasing.easeInBack,
  'ease-out-back': CoreEasing.easeOutBack,
  'ease-in-out-back': CoreEasing.easeInOutBack,
  'fast-out-slow-in': CoreEasing.fastOutSlowIn,
  'slow-middle': CoreEasing.slowMiddle,
  'fast-linear-to-slow-ease-in': CoreEasing.fastLinearToSlowEaseIn,
  'ease-in-to-linear': CoreEasing.easeInToLinear,
  'linear-to-ease-out': CoreEasing.linearToEaseOut,
};

/// All numeric primitive tokens. Values reference the `coui_core` namespace
/// constants directly (single source — no hardcoded numbers). Leaf names use
/// the Tailwind scale-key convention (`space/16`, `font-weight/semibold`).
List<_NumToken> _numericTokens() => [
  // spacing
  for (final e in _kSpaceLadder.entries)
    _NumToken('space', e.key, e.value, scopes: ['GAP']),
  // size — the independent 24-token dimension ladder
  // (CoUI_Size_Token_Specification §1, v1.1). `CoreSize` no longer
  // mirrors `CoreSpace` — it is its own banded scale (4–128px, optical/
  // control/structure/display intervals) with values Space never had
  // (44, 128), so the old F1 "don't export a duplicate ladder"
  // reasoning (#3736) no longer applies; the spec supersedes it and
  // asks for exactly this export. `WIDTH_HEIGHT` scoping keeps the
  // Size/Space boundary designer-visible: width/height pickers offer
  // `size/*`, gap/padding pickers offer `space/*`.
  for (final e in _kSizeLadder.entries)
    _NumToken('size', e.key, e.value, scopes: ['WIDTH_HEIGHT']),
  // layout — the bounds a panel or overlay may take (`CoreLayout`): a
  // dialog's max width, a list's scroll ceiling, an inline panel's floor.
  // Neither an element dimension (`size/*` stops at 128 on purpose) nor a
  // rhythm value (`space/*`), so it is its own group. Same `WIDTH_HEIGHT`
  // scope as `size/*` — a designer binds it on a panel's width/height.
  for (final e in _kLayoutLadder.entries)
    _NumToken('layout', e.key, e.value, scopes: ['WIDTH_HEIGHT']),
  // breakpoint (responsive min-widths — Tailwind-matching, from the
  // shared `CoreBreakpoint` enum; `xs` is the 0-floor and has no token).
  for (final e in {
    'sm': CoreBreakpoint.sm,
    'md': CoreBreakpoint.md,
    'lg': CoreBreakpoint.lg,
    'xl': CoreBreakpoint.xl,
    '2xl': CoreBreakpoint.xxl,
  }.entries)
    _NumToken('breakpoint', e.key, e.value.minWidth),
  // radius
  for (final e in _kRadiusLadder.entries)
    _NumToken('radius', e.key, e.value, scopes: ['CORNER_RADIUS']),
  // stroke width
  for (final e in _kStrokeLadder.entries)
    _NumToken('stroke', e.key, e.value, scopes: ['STROKE_FLOAT']),
  // font-family (String). The live library keys these by the family name
  // itself (`font/family/Pretendard`), not by role — the role (sans/mono)
  // is resolved plugin-side from the value. `serif` is TBD ('' in
  // coui_core) and the live file has no serif slot, so it is not
  // emitted — an empty-string Figma variable binds nothing.
  for (final family in <String>[CoreFontFamily.sans, CoreFontFamily.mono])
    _NumToken('font/family', family, family, type: 'STRING'),
  // font-size
  for (final e in _kFontSizeScale.entries)
    _NumToken('font/size', e.key, e.value),
  // font-weight (leaf = lowercase scale key). Scoped like the semantic
  // weights that alias it: the scope is what tells the Dart export a weight
  // is the `int` `CoreTextStyle.fontWeight` takes, and a primitive no role
  // aliases (thin, black) would otherwise come back as `double`.
  for (final e in _kFontWeightScale.entries)
    _NumToken('font/weight', e.key, e.value, scopes: ['FONT_WEIGHT']),
  // line-height (unitless multiplier)
  for (final e in _kLineHeightScale.entries)
    _NumToken('line-height', e.key, e.value),
  // letter-spacing (em)
  for (final e in <String, double>{
    'tighter': CoreLetterSpacing.tighter,
    'tight': CoreLetterSpacing.tight,
    'tight-20': CoreLetterSpacing.tight20,
    'tight-15': CoreLetterSpacing.tight15,
    'tight-10': CoreLetterSpacing.tight10,
    'tight-5': CoreLetterSpacing.tight5,
    'normal': CoreLetterSpacing.normal,
    'wide': CoreLetterSpacing.wide,
    'wider': CoreLetterSpacing.wider,
    'widest': CoreLetterSpacing.widest,
  }.entries)
    _NumToken('letter-spacing', e.key, e.value),
  // opacity — `_kOpacityScale` (and every reader/consumer of `CoreOpacity`)
  // stays 0–1 truth-space, but a FLOAT variable with `OPACITY` scope binds
  // to Figma's opacity slider as a 0–100 value, not 0–1: an unscaled 0.05
  // reads as "0.05%" and the binding picker refuses it. The ×100 lives
  // only at this emission site — `_opacityLeaf`'s reverse lookup (used by
  // the semantic-opacity / focus-ring aliases) still compares against the
  // Dart-space value, so nothing else in this file needs to know.
  for (final e in _kOpacityScale.entries)
    _NumToken('opacity', e.key, e.value * 100, scopes: ['OPACITY']),
  // The five semantic opacity keys (disabled/hover/focus/pressed/scrim)
  // are NOT primitives — they live in the `Semantic/ Effect`
  // collection as aliases into this numeric scale (see _effectTokens).
  // duration (ms) — each raw leaf gets a tier description (transition vs
  // display) so the reduced-motion boundary is readable in Figma without
  // cross-referencing `coui_core` source.
  for (final e in _kDurationRawScale.entries)
    _NumToken(
      'duration',
      e.key,
      e.value,
      description: _durationTierDescription(e.value),
    ),
  // z-index (int) + auto (string)
  for (final e in <String, int>{
    '0': CoreZIndex.z0,
    '10': CoreZIndex.z10,
    '20': CoreZIndex.z20,
    '30': CoreZIndex.z30,
    '40': CoreZIndex.z40,
    '50': CoreZIndex.z50,
    '60': CoreZIndex.z60,
    '70': CoreZIndex.z70,
    '80': CoreZIndex.z80,
    '90': CoreZIndex.z90,
    '100': CoreZIndex.z100,
  }.entries)
    _NumToken('z-index', e.key, e.value),
  const _NumToken('z-index', 'auto', CoreZIndex.zAuto, type: 'STRING'),
];

Map<String, dynamic> _stringVar(String name, String value) => {
  'name': name,
  'type': 'STRING',
  'valuesByMode': {'Value': value},
};

/// A variable that *aliases* another variable instead of carrying its own
/// value — `tools/figma-token-sync`'s importer resolves `alias` (a
/// `"<CollectionName>/<variable.name>"` path) via
/// `figma.variables.createVariableAlias`, so [type] must match the target
/// variable's Figma type (`FLOAT` alias -> `FLOAT` target, etc).
Map<String, dynamic> _aliasVar(
  String name,
  String type,
  String alias, {
  String? description,
  List<String>? scopes,
}) => {
  'name': name,
  'type': type,
  'description': ?description,
  'scopes': ?scopes,
  'valuesByMode': {
    'Value': {'alias': alias},
  },
};

/// A `FLOAT` dimension alias into `Primitives/size/<n>`, scoped to
/// width/height pickers. Every Semantic-Dimension and Component tier
/// token goes through here so the whole 3-tier chain stays
/// alias-backed (spec §5: "Semantic과 Component는 전부 alias로
/// Primitive를 참조합니다").
Map<String, dynamic> _dimAliasVar(
  String name,
  double value, {
  String? description,
}) => _aliasVar(
  name,
  'FLOAT',
  _sizeAlias(value),
  description: description,
  scopes: ['WIDTH_HEIGHT'],
);

/// A `FLOAT` spacing alias into `Semantic/ Dimension/space/<n>`, scoped to
/// the gap / padding pickers — what a component's padding-x and icon↔label
/// gap tokens are (`button/padding-x-*`, `button/gap-*`). Through the
/// density row rather than the primitive, so a frame that pins a density
/// moves these the way the two platforms move the padding they name.
Map<String, dynamic> _spaceAliasVar(
  String name,
  double value, {
  String? description,
}) => _aliasVar(
  name,
  'FLOAT',
  '$_kCollSemanticDimension/space/'
      '${_ladderLeaf(_kSpaceLadder, value, 'space')}',
  description: description,
  scopes: ['GAP'],
);

/// A `FLOAT` alias for a row height that may or may not sit on the control
/// ladder: a rung aliases its density row ([_controlRowAliasVar]); any other
/// height is not a row of the ladder, a density leaves it where it is, and it
/// aliases the primitive size ([_dimAliasVar]).
Map<String, dynamic> _rowHeightAliasVar(
  String name,
  double height, {
  String? description,
}) => CoreControlSize.isRung(height)
    ? _controlRowAliasVar(name, height, description: description)
    : _dimAliasVar(name, height, description: description);

/// A `FLOAT` alias for a control row's height into
/// `Semantic/ Dimension/control-size/<tier>` — the row a density moves.
/// A height that is not a rung of the control ladder is not a row and has
/// nothing to follow, so it fails the build like an off-ladder size does.
Map<String, dynamic> _controlRowAliasVar(
  String name,
  double height, {
  String? description,
}) {
  final tier = {
    CoreControlSize.heightXs: 'xs',
    CoreControlSize.heightSm: 'sm',
    CoreControlSize.heightMd: 'md',
    CoreControlSize.heightLg: 'lg',
    CoreControlSize.heightXl: 'xl',
    CoreControlSize.heightXl2: 'xl2',
  }[height];
  if (tier == null) {
    stderr.writeln(
      '❌ $name: $height is not a control-row height '
      '(CoreControlSize) — a row a density cannot move must not alias '
      'control-size.',
    );
    exit(1);
  }

  return _aliasVar(
    name,
    'FLOAT',
    '$_kCollSemanticDimension/control-size/$tier',
    description: description,
    scopes: ['WIDTH_HEIGHT'],
  );
}

/// The density modes, default first — the mode a frame that pins nothing
/// reads.
final List<CoreDensity> _kDensityModes = [
  CoreDensity.defaultDensity,
  for (final d in CoreDensity.values)
    if (d != CoreDensity.defaultDensity) d,
];

/// One `Semantic/ Dimension` row: a `FLOAT` whose value in each density
/// mode is the alias [alias] answers for that density.
Map<String, dynamic> _densityVar(
  String name, {
  required List<String> scopes,
  required String Function(CoreDensity) alias,
  String? description,
}) => {
  'name': name,
  'type': 'FLOAT',
  'scopes': scopes,
  'description': ?description,
  'valuesByMode': {
    for (final d in _kDensityModes) d.name: {'alias': alias(d)},
  },
};

Map<String, dynamic> _colorAliasVar(String name, String alias) =>
    _aliasVar(name, 'COLOR', alias);

/// A `COLOR` variable for a [CoreColor] stated in Core: an alias into
/// [semanticCollection]'s `color/<token>` when the colour is a token, else
/// its raw ARGB value — alpha included, unlike [_rgb], which serves the
/// opaque primitive palette and pins `a` to 1.
Map<String, dynamic> _coreColorVar(
  String name,
  CoreColor color,
  String semanticCollection,
) {
  final token = color.token;
  if (token != null) {
    return _colorAliasVar(name, '$semanticCollection/color/${token.name}');
  }
  return {
    'name': name,
    'type': 'COLOR',
    'valuesByMode': {'Value': _argb(color.argb)},
  };
}

/// Max value of an 8-bit ARGB channel, also the shift-free mask for one.
const _kArgbChannelMask = 0xFF;

/// Bit offsets of the alpha, red and green channels in a packed ARGB int.
const _kArgbAlphaShift = 24;
const _kArgbRedShift = 16;
const _kArgbGreenShift = 8;

/// Packed `0xAARRGGBB` -> `{ r, g, b, a }` (0–1) for Figma COLOR.
Map<String, double> _argb(int argb) => {
  'r': ((argb >> _kArgbRedShift) & _kArgbChannelMask) / _kColorChannelMax,
  'g': ((argb >> _kArgbGreenShift) & _kArgbChannelMask) / _kColorChannelMax,
  'b': (argb & _kArgbChannelMask) / _kColorChannelMax,
  'a': ((argb >> _kArgbAlphaShift) & _kArgbChannelMask) / _kColorChannelMax,
};

/// Strip trailing `.0` so `4.0` reads as `4` in CSS strings.
String _num(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

/// Shadow layers -> CSS `box-shadow`
/// (e.g. `'0px 8px 24px 0px rgba(0, 0, 0, 0.1)'`).
String _cssBoxShadow(List<CoreShadowLayer> layers) => layers
    .map(
      (l) =>
          '${l.inset ? 'inset ' : ''}'
          '${_num(l.offsetX)}px ${_num(l.offsetY)}px '
          '${_num(l.blurRadius)}px ${_num(l.spreadRadius)}px '
          'rgba(0, 0, 0, ${l.opacity})',
    )
    .join(', ');

/// Composite tokens. Motion/shadow as CSS STRING; focus-ring decomposed.
List<Map<String, dynamic>> _compositeTokens() => [
  // easing (kebab scale keys) -> cubic-bezier()
  for (final e in _kEasingRawScale.entries)
    _stringVar(
      'easing/${e.key}',
      'cubic-bezier(${_num(e.value.x1)}, ${_num(e.value.y1)}, '
          '${_num(e.value.x2)}, ${_num(e.value.y2)})',
    ),
  // Flutter-native non-bezier curves. `CoreCubicBezier` structurally
  // cannot hold these (bounce/elastic are piecewise, emphasized is a
  // spline), so there is no Core value to convert — the token's value
  // IS the Flutter `Curves.*` identifier, the same reference string the
  // design library documents for hand-off. Web equivalents require
  // keyframes/JS rather than a `cubic-bezier()` and are chosen
  // per-implementation.
  for (final e in const {
    'decelerate': 'Curves.decelerate',
    'ease-in-out-cubic-emphasized': 'Curves.easeInOutCubicEmphasized',
    'fast-ease-in-to-slow-ease-out': 'Curves.fastEaseInToSlowEaseOut',
    'bounce-in': 'Curves.bounceIn',
    'bounce-out': 'Curves.bounceOut',
    'bounce-in-out': 'Curves.bounceInOut',
    'elastic-in': 'Curves.elasticIn',
    'elastic-out': 'Curves.elasticOut',
    'elastic-in-out': 'Curves.elasticInOut',
  }.entries)
    _stringVar('easing/${e.key}', e.value),
  // spring -> readable config string
  for (final e in const {
    'gentle': CoreSpringConfig.gentle,
    'standard': CoreSpringConfig.standard,
    'bouncy': CoreSpringConfig.bouncy,
    'snappy': CoreSpringConfig.snappy,
    'stiff': CoreSpringConfig.stiff,
  }.entries)
    _stringVar(
      'spring/${e.key}',
      'damping ${_num(e.value.dampingRatio)}, '
          'stiffness ${_num(e.value.stiffness)}, mass ${_num(e.value.mass)}',
    ),
  // shadow / focus-ring / semantic opacity live in the
  // `Semantic/ Effect` collection (_effectTokens), mirroring the
  // live library's tiering — a shadow recipe or a focus-ring is a
  // semantic decision over primitives, not a primitive itself.
  // No motion alias tier here: the live library's motion semantics live
  // in its own `Semantic/ Motion` collection with a different, newer
  // vocabulary (enter/exit/move/feedback — the easing docs' 2026-08-07
  // revision) than the code's `CoreEasing` aliases
  // (standard/decelerate/accelerate/spring). Emitting the code vocabulary
  // would sit a second, conflicting alias set next to the designer's.
  // Wiring that collection up follows the code-side rename to the new
  // vocabulary — a separate task. The reduced-motion tier boundary stays
  // readable in Figma via the per-value descriptions on `duration/<n>`.
];
