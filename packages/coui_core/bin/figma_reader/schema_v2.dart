/// Assembles the schema v2 `components.json` document from the reader's
/// discoveries — the piece that wires `repo_reader.dart` (structure) +
/// `token_scale.dart` (primitive forward table) + `emit.dart` (typed leaf
/// shapes) into one component's `{fields, variants, sizes}` and, from
/// there, the whole `{meta, components}` document.
///
/// ## Governing principles (from the schema v2 design)
///
///  1. **leaf is always `{v, ref}`-shaped** (or the type-specific
///     equivalent) — never a union. `emit.dart` already guarantees this
///     per-value; this file's job is deciding *which* emit function a
///     field's declared type routes to, uniformly, and never silently
///     dropping a field it can't route (see [ComponentDoc.untokenized]).
///  2. **The exporter never renames a field** — `emit.dart#jsonKeyFor`
///     strips only the `default` prefix; this file calls it exactly once
///     per field and never substitutes a different key.
///  3. **Deterministic output** — `repo_reader.dart` already sorts file
///     order; this file sorts component names and, within a component,
///     preserves *source order* for fields (the order `style_reader.dart`
///     walked the class body in) and dispatch-table entries (the order
///     `readValue` walked the map literal in) — never a `Map` iteration
///     order that depends on insertion happening to match source, which a
///     future refactor of this file could silently break.
library;

import 'ast_value.dart';
import 'emit.dart';
import 'style_reader.dart';

/// Routes an instance field's declared type to the `emit.dart` function
/// that knows its shape. Covers the eight types that
/// (`emit.dart`'s own census) make up 88.6% of every `default*` field in
/// this codebase — `double`/`int` (Dim), `CoreColor`, `CoreEdgeInsets`,
/// `CoreBorderRadius`, `CoreTextStyle`, `CoreGapStyle`, `CoreIconStyle`,
/// `Duration`. Anything else routes to `null` — the caller records that as
/// `untokenized`, per the "explicit long-tail marker" completion
/// criterion, rather than guessing at a shape or silently dropping the
/// field.
enum FieldKind {
  dim,
  color,
  insets,
  radius,
  text,
  gap,
  icon,
  duration,
  choice,
  shadow,
  flag,
  colorList,
  gradient,
  glyph,
  stateLayer,
}

FieldKind? fieldKindOf(String typeSource) {
  final bare = typeSource.replaceAll('?', '').trim();
  return switch (bare) {
    'double' || 'int' => FieldKind.dim,
    // A boolean default had no kind at all, so four components' `false`
    // never left Dart. `false` is a value — `button.dashedBorder = false`
    // says this button is not dashed — and an absent field lets the plugin
    // pick, which is the same reachable-but-unread state this whole guard
    // exists to find.
    'bool' => FieldKind.flag,
    'CoreColor' => FieldKind.color,
    'CoreEdgeInsets' => FieldKind.insets,
    'CoreBorderRadius' => FieldKind.radius,
    'CoreTextStyle' => FieldKind.text,
    'CoreGapStyle' => FieldKind.gap,
    'CoreIconStyle' => FieldKind.icon,
    // The first `CoreXxx` value class in this repo that is NOT an enum, so
    // it has to be named before the catch-all below claims it. Left to that
    // branch it emitted `{"choice": "strong"}` — the name of the const
    // instead of the three numbers it stands for, which is a label the
    // builder cannot paint with.
    'CoreStateLayer' => FieldKind.stateLayer,
    'Duration' => FieldKind.duration,
    // Eleven components declare one and none reached Figma: `CoreShadowLayer`
    // is a record `typedef`, so a shadow step is a list of record literals
    // rather than a class the class-registry could resolve. Every card,
    // popup, dialog, drawer and toast on the canvas was flat, and a shadow
    // that was never emitted is indistinguishable from one deliberately
    // omitted.
    'List<CoreShadowLayer>' => FieldKind.shadow,
    'List<CoreColor>' => FieldKind.colorList,
    // A `CoreXxx` value class that is not an enum, named before the catch-all
    // below claims it. Routed as a `choice` it emitted nothing — the value is
    // a constructor call, not a member name — so a gradient fill (a mockup
    // device's body, its lens core, its hardware gloss) never left Dart and
    // the canvas drew a flat colour for it. `{type, colors, stops, begin,
    // end}` is what the builder needs to paint one.
    'CoreGradient' => FieldKind.gradient,
    // Another `CoreXxx` value class that is not an enum: a small vector
    // drawing (a status bar's wifi fan). Routed as a `choice` it emitted
    // nothing — the value is a constructor call — so the outline never left
    // Dart and the builder had nothing to draw. `{path, width, height,
    // fillRule}` is what it needs to place and fill one.
    'CoreVectorGlyph' => FieldKind.glyph,
    // A `CoreXxx`-typed field that is none of the above is an enum in every
    // case this repo has: alignment, shape, half, layout, breakpoint, trigger
    // sizing. Routed as `choice` and emitted as the member NAME — the builder
    // branches on it (`alignment === 'topEnd'`), it has no numeric value to
    // resolve, and a token ref would be meaningless.
    //
    // Forty fields sat in `unroutable-type` for want of this, so a value the
    // component genuinely has — `basic.mainAxisAlignment`, `mask.shape`,
    // `footer.layout` — reached the plugin as absent, and the builder guessed.
    //
    // Ordered last so a real token type never falls through to it.
    // A `String` chrome field is a semantic token, not content: content strings
    // live on the widget plane (`core/style-contract.md` — a Style slot carries
    // visual chrome only), so a String that reached a Style is a name the
    // builder
    // branches on. One field in this repo is that, and it is checked: no other
    // `final String?` exists under `contracts/*/*_style.dart`.
    'String' => FieldKind.choice,
    _ when _looksLikeCoreEnum(bare) => FieldKind.choice,
    _ => null,
  };
}

/// `CoreFooBar` with no generic argument and no `Style`/`Theme` suffix.
///
/// Deliberately shape-based rather than a list: an enum list would go stale the
/// day someone adds one, and the failure mode of going stale here is silent
/// (the field simply stops being emitted, exactly the state this fixes). The
/// `Style` exclusion matters because a nested `CoreXxxStyle` slot is handled by
/// the nested-style path above, not as a leaf.
bool _looksLikeCoreEnum(String bare) {
  if (!bare.startsWith('Core') || bare.contains('<')) return false;
  return !bare.endsWith('Style') && !bare.endsWith('Theme');
}

/// Emits one value per its [FieldKind]. `Duration(milliseconds: X)` routes
/// through `emitDim` on its `milliseconds` argument — CoUI never emits raw
/// millisecond doubles any other way (`core/design-tokens.md`'s duration
/// alias tiers), so a `Dim` leaf (value + token ref, when the ms count
/// traces to a `CoreDuration` member) is the right shape, not a bespoke
/// duration leaf type.
Map<String, dynamic>? emitByKind(
  EmitContext ctx,
  FieldKind kind,
  AstValue value, {
  required String currentClass,
}) {
  switch (kind) {
    case FieldKind.dim:
      return emitDim(ctx, value, currentClass: currentClass);
    case FieldKind.color:
      return emitColor(ctx, value, currentClass: currentClass);
    case FieldKind.insets:
      return emitInsets(ctx, value, currentClass: currentClass);
    case FieldKind.radius:
      return emitRadius(ctx, value, currentClass: currentClass);
    case FieldKind.text:
      return emitText(ctx, value, currentClass: currentClass);
    case FieldKind.gap:
      return emitGap(ctx, value, currentClass: currentClass);
    case FieldKind.icon:
      return emitIcon(ctx, value, currentClass: currentClass);
    case FieldKind.duration:
      // `.zero` in either spelling — the dot shorthand and the qualified
      // `Duration.zero`. A real value: "no delay", not "unspecified". Only the
      // shorthand was handled, so `frame` and `outlined_container` reported
      // their transition duration as unreadable.
      //
      // Read off the end of the alias chain, in the scope that wrote the
      // call: a nested default may forward a sibling `defaultFadeDuration`
      // by name, and the `Duration(...)` behind it names its milliseconds in
      // the class that declared it (see `terminalValue`).
      final duration = terminalValue(ctx, value, currentClass: currentClass);
      if (duration.value case RefValue(member: 'zero')) {
        return emitDim(ctx, const LiteralValue(0), currentClass: currentClass);
      }
      if (duration.value case CallValue(
        owner: null,
        callee: 'Duration',
        :final namedArgs,
      )) {
        final ms = namedArgs['milliseconds'];
        if (ms != null) {
          return emitDim(ctx, ms, currentClass: duration.scope);
        }
      }
      return null;
    case FieldKind.flag:
      if (value case LiteralValue(value: final bool b)) return {'v': b};
      return null;
    case FieldKind.colorList:
      if (value case ListValue(:final items)) {
        final colors = <Map<String, dynamic>>[];
        for (final item in items) {
          final c = emitColor(ctx, item, currentClass: currentClass);
          // One unreadable stop makes the whole gradient wrong, not partly
          // wrong — a two-stop fade emitted with one stop is a solid fill.
          if (c == null) return null;
          colors.add(c);
        }
        return {'colors': colors};
      }
      return null;
    case FieldKind.gradient:
      return emitGradient(ctx, value, currentClass: currentClass);
    case FieldKind.glyph:
      return emitGlyph(ctx, value, currentClass: currentClass);
    case FieldKind.shadow:
      return emitShadow(ctx, value, currentClass: currentClass);
    case FieldKind.stateLayer:
      return emitStateLayer(ctx, value, currentClass: currentClass);
    case FieldKind.choice:
      // The member name, from either spelling: `.topEnd` (a dot shorthand,
      // which the unresolved parser gives as an owner-less ref) or
      // `CoreAlignment.topEnd`. Both are the same choice, and the name is the
      // whole value — the builder branches on it.
      if (value case RefValue(:final member)) {
        return {'choice': member};
      }
      // A bare string is the same kind of value under a weaker type: a field
      // whose platforms branch on it by comparing the string. The name IS the
      // whole value, which is what `choice` means; the only difference from an
      // enum is that Dart is not checking the spelling. Without this case such
      // a field would land in `unroutable-type` and never reach the canvas.
      if (value case LiteralValue(value: final String text)) {
        return {'choice': text};
      }
      return null;
  }
}

/// A field this component's scalar defaults *tried* to emit but couldn't
/// route — recorded rather than silently dropped, per the "fallback이
/// 미검증 문자열을 산출물에 섞지 않도록 명시적으로 표시" completion
/// criterion. `reason` is `'unroutable-type'` (the declared type isn't one
/// of the eight [FieldKind]s) or `'unresolvable-value'` (the type routes,
/// but the value's shape didn't match what that emitter expects — e.g. a
/// `CoreColor` field whose value is a non-`.token`/non-raw-ARGB
/// expression this reader doesn't model).
final class UntokenizedField {
  const UntokenizedField({
    required this.jsonKey,
    required this.typeSource,
    required this.reason,
  });
  final String jsonKey;
  final String typeSource;
  final String reason;
}

/// One component's `{fields, variants, sizes}`, plus whatever couldn't be
/// routed — always this exact three-key shape (divergence #6/#9's fix:
/// every component has the same shape, present-but-empty when a component
/// has no variants or no sizes, rather than three different output
/// shapes for three different components).
final class ComponentDoc {
  const ComponentDoc({
    required this.fields,
    required this.variants,
    required this.sizes,
    required this.untokenized,
    this.constants = const {},
    this.constantsUnroutable = const [],
    this.behaviour = const {},
    this.slots = const {},
    this.absent = const {},
    this.deprecated = const [],
    this.hostDerived = const [],
    this.derivedDefaults = const {},
  });
  final Map<String, dynamic> fields;
  final Map<String, dynamic> variants;
  final Map<String, dynamic> sizes;
  final List<UntokenizedField> untokenized;

  /// `{ field: FieldKind }` for the declared chrome fields that carry no value
  /// anywhere — no `default*`, no entry in any variant or size table.
  ///
  /// Absence is a decision (`core/style-contract.md`: a `!= null` branch
  /// decides whether something is drawn at all), and until this map existed
  /// the pipeline could not tell that decision apart from a field the reader
  /// had simply failed to route: both arrived as a missing key. So the Figma
  /// builder hardcoded the rendering — `button.width` carries no value,
  /// meaning "no fixed width", and the builder wrote
  /// `primaryAxisSizingMode = 'AUTO'` from its own knowledge. The two agreed,
  /// and nothing checked that they did; had someone given the field a width,
  /// the canvas would have kept hugging and no gate would have noticed.
  ///
  /// What is carried is the **kind**, not a Figma word for it. `dim` is a fact
  /// about the Dart declaration; `'HUG'` is emit vocabulary, and Core does not
  /// know emit vocabulary. The kind → canvas-assertion table lives on the
  /// plugin side, in one reviewable place.
  final Map<String, String> absent;

  /// Fields whose `default*` carries `@Deprecated` — a value the code no longer
  /// applies.
  ///
  /// Neither a value nor an absence. Exported as its own list because the two
  /// wrong answers are equally bad: emit it into `fields` and the builder
  /// paints chrome the widgets dropped (a monospace 16px separator
  /// `FormattedInput` no longer renders on either platform, which is what
  /// happened); put it in [absent] and the pipeline claims a decision was made
  /// to have no value when the value is right there, just retired.
  final List<String> deprecated;

  /// Declared fields whose value the host injects at render time
  /// (`@hostDerived`). Not in [absent]: the canvas may show any host's
  /// value, so the fidelity check lists them as not compared instead
  /// of asserting a shape the code never stated.
  final List<String> hostDerived;

  /// Dynamic identity fallbacks to another same-style field, keyed by the
  /// destination. These are relations, not absent or constant values. Canvas
  /// fidelity must report them as unverified until it compares the relation.
  final Map<String, String> derivedDefaults;

  /// Public `static const` values with no same-named instance field —
  /// `{ name: leaf }`.
  ///
  /// These were dropped, with a justification that was half right: a const like
  /// `defaultMinWidth` with no `minWidth` slot is indeed outside the
  /// caller-visible OVERRIDE surface. The other half is the defect — it is still
  /// a value a widget paints, and the canvas had nothing to source it from.
  ///
  /// `PhoneInput` is the case that showed it. Its inner number field is
  /// chromeless (`chromelessFieldStyle`: transparent fill and border, zero
  /// width, zero padding) so the outer container owns the single boundary, and
  /// that style is deliberately NOT exposed as a slot. With the const dropped,
  /// the Figma builder composed a plain `TextField` instance and the canvas grew
  /// a second border inside the first — a field drawn inside a field, which is
  /// what the report showed side by side with the app.
  ///
  /// Kept separate from [fields] rather than merged, because the distinction is
  /// real and a consumer needs it: a `fields` entry is a value a CALLER can
  /// override, a `constants` entry is one the component fixes. Merging them would
  /// tell the plugin it can offer a component property for something no
  /// `CoreXxxStyle` slot accepts.
  final Map<String, dynamic> constants;

  /// Public `static const` values whose type this reader cannot route —
  /// `[{name, type}]`.
  ///
  /// Named rather than counted, for the reason [untokenized] is: a total says
  /// nothing about a regression, and a silent skip is indistinguishable from
  /// "there was nothing there".
  final List<Map<String, String>> constantsUnroutable;

  /// Behaviour defaults this component's `CoreXxxContract` fixes as
  /// `static const default*` — `{ name: literal }` (`defaultLength` →
  /// `length: 6`).
  ///
  /// Not chrome, and kept out of [fields] and [constants] for that reason:
  /// these are the values a caller who passes nothing to a *widget*
  /// parameter gets (`length`, `separatorInterval`), not values a
  /// `CoreXxxStyle` slot carries. `core/style-contract.md` puts them on the
  /// contract precisely so the two widgets cannot each keep their own copy —
  /// and the Figma builder was the third copy, a literal in its source with
  /// a comment naming the widget const it mirrored. Exported so the builder
  /// draws the default field from the same number the widgets build it from.
  ///
  /// Numbers, flags and strings only (`int` / `double` / `bool` / `String`) —
  /// a literal, or a reference that resolves to one: a primitive token
  /// (`CoreSpace.space8`) or a sibling literal static, followed the way a
  /// Style default is. A behaviour default is a count, a flag, a limit or a
  /// distance; one spelled as an expression that does not resolve to a scalar
  /// (`Duration(…)`, an enum, a call) is not something a canvas can be built
  /// from, and is left out rather than guessed.
  final Map<String, Object> behaviour;

  /// Composition slots declared by this component's `CoreXxxContract` —
  /// `{ name: {type, required, repeated} }`.
  ///
  /// Not chrome, and deliberately not merged into [fields]: a field carries a
  /// *value* the resolver merges, a slot declares *what the widget accepts*.
  /// The Figma plugin needs the second to create component properties (an
  /// optional slot is a Boolean-property candidate, a repeated one is not),
  /// and it has had no way to know them — the contracts were parsed and
  /// registered from the start but nothing read their getters.
  final Map<String, dynamic> slots;

  Map<String, dynamic> toJson() => {
    'fields': fields,
    'constants': constants,
    'constantsUnroutable': constantsUnroutable,
    'behaviour': behaviour,
    'variants': variants,
    'sizes': sizes,
    'slots': slots,
    'absent': absent,
    'deprecated': deprecated,
    'hostDerived': hostDerived,
    'derivedDefaults': derivedDefaults,
    // Exported, not just counted on stderr. A total ("21 fields could not be
    // routed") tells a reviewer nothing about a regression — 22 next week is
    // indistinguishable from a different 21. With the fields named, the four
    // buckets also PARTITION every declared field: a value reached, an absence
    // was decided, a default was retired, or the reader failed. Anything in
    // none of them is a gap nobody has looked at, and that is what the
    // coverage gate can then assert instead of infer.
    'untokenized': [
      for (final u in untokenized)
        {'field': u.jsonKey, 'type': u.typeSource, 'reason': u.reason},
    ],
  };
}

/// The `constants` key for a `static const` name, refusing a collision.
///
/// `jsonKeyFor` strips a leading `default`, so `defaultFocusRingColor` becomes
/// `focusRingColor` — which a component could also declare as a separate const
/// under that exact name. Silently overwriting would export one value under a key
/// the other one also claims, and the loser would be whichever the census
/// happened to visit second.
String _constantKeyFor(String memberName, Map<String, dynamic> constants) {
  final key = _constantJsonKey(memberName);
  if (!constants.containsKey(key)) return key;
  throw StateError(
    'two static consts map to the constants key "\$key" (one of them is '
    '"\$memberName") — `jsonKeyFor` strips a leading `default`, so rename one '
    'of the two rather than letting the later one win.',
  );
}

/// A constant's JSON key — `jsonKeyFor`, except it refuses to mangle a name that
/// is not `default<Field>`.
///
/// `jsonKeyFor` strips a leading `default` because that is how a chrome default is
/// paired with its field. Applied to a const that merely STARTS with those seven
/// letters it produces nonsense: `defaultsByVariant` came out as `sByVariant`.
///
/// Three components (`Dialog`, `Slider`, `Range`) declare `defaultsByVariant` as a
/// single `CoreXxxVariantStyle` bundle rather than a `Map`, deliberately and with
/// the reason written down — a component with one design-system default needs no
/// table, and the dispatch-registry NAME is kept so prefix-walking census tooling
/// finds it. This reader is that tooling.
///
/// Classifying them as dispatches by name was the other wrong answer, and worse
/// than the mangled key: `_emitDispatch` cannot evaluate a non-`Map`, an
/// unevaluated dispatch suppresses every absence claim on its component
/// (deliberately — see `_absentFields`), and three `Dialog` fields that had
/// declared absences went to "no value anywhere" instead. Nothing about the canvas
/// changed; the coverage arithmetic just stopped being able to say what it knew.
///
/// The values in those bundles are not lost either way: each references a flat
/// `default<Field>` const that has its own matching slot, which is exactly what
/// `Dialog`'s comment says it is for.
String _constantJsonKey(String memberName) {
  const prefix = 'default';
  if (!memberName.startsWith(prefix)) return memberName;
  final rest = memberName.substring(prefix.length);
  // `default` + uppercase is the field pairing. Anything else — `defaults…`,
  // or the bare word — is a name in its own right.
  if (rest.isEmpty || rest[0].toUpperCase() != rest[0]) return memberName;
  return jsonKeyFor(memberName);
}

/// Builds one component's document from its MAIN `CoreXxxStyle` class.
/// [mainClass] must be a class with `implementsCoreStyle == true`
/// (`census.dart`'s MAIN category).
ComponentDoc buildComponentDoc(
  EmitContext ctx,
  DiscoveredClass mainClass, {
  DiscoveredClass? contract,
}) {
  final fieldTypeByJsonKey = <String, String>{
    for (final f in mainClass.instanceFields)
      jsonKeyForField(f.name): f.typeSource,
  };

  final fields = <String, dynamic>{};
  final constants = <String, dynamic>{};
  final constantsUnroutable = <Map<String, String>>[];
  final variants = <String, dynamic>{};
  final sizes = <String, dynamic>{};
  final untokenized = <UntokenizedField>[];
  // Dispatch tables this reader could not evaluate — see [_absentFields] for
  // why their presence has to suppress every absence claim on the component.
  final unevaluatedDispatches = <String>[];
  final deprecated = <String>[];
  final derivedDefaults = <String, String>{};

  // A method named defaultX is evidence of a dynamic default, never an
  // absence. Only the exact identity form with an existing same-type sibling
  // is understood; all other forms are named as unresolved rather than guessed.
  final fieldsByName = {for (final f in mainClass.instanceFields) f.name: f};
  for (final method in mainClass.derivedDefaults) {
    final key = jsonKeyFor(method.name);
    final field = fieldsByName[key];
    if (field == null) continue;
    final source = fieldsByName[method.sourceField];
    if (source != null &&
        source.name != field.name &&
        source.typeSource.replaceAll('?', '') ==
            field.typeSource.replaceAll('?', '') &&
        method.parameterType == source.typeSource.replaceAll('?', '') &&
        method.returnType == field.typeSource.replaceAll('?', '')) {
      derivedDefaults[key] = source.name;
    } else {
      untokenized.add(
        UntokenizedField(
          jsonKey: key,
          typeSource: field.typeSource,
          reason: 'dynamic-default-unresolved',
        ),
      );
    }
  }

  for (final member in mainClass.staticMembers) {
    if (member.isPrivate) continue;
    final isDispatch = member.typeSource.startsWith('Map<');
    if (isDispatch) {
      final bucket = member.name.contains('BySize') ? sizes : variants;
      final dispatchDoc = _emitDispatch(
        ctx,
        member,
        currentClass: mainClass.name,
        untokenized: untokenized,
      );
      if (dispatchDoc != null) {
        bucket[member.name] = dispatchDoc;
      } else {
        unevaluatedDispatches.add(member.name);
      }
      continue;
    }

    final jsonKey = jsonKeyFor(member.name);
    // A retired default is not a value to export. `FormattedInput` has eight,
    // every message reading "No longer applied", and all eight were reaching
    // the plugin — so a builder could paint a monospace separator neither
    // platform draws, sourced from Core and looking authoritative.
    if (member.isDeprecated) {
      if (fieldTypeByJsonKey.containsKey(jsonKey)) deprecated.add(jsonKey);
      continue;
    }
    final typeSource = fieldTypeByJsonKey[jsonKey];
    if (typeSource == null) {
      // A `static const` with no matching instance field — a value the
      // component FIXES rather than one a caller can override
      // (`defaultMinWidth` with no `minWidth` slot, or a named partial like
      // `chromelessFieldStyle`). It does not belong in `fields`, and it was
      // dropped here on that reasoning.
      //
      // Dropping it was the other half of the story. `PhoneInput`'s inner number
      // field is chromeless by that named const, and with the const gone the
      // Figma builder had nothing to suppress the composed `TextField`'s own
      // border with — so the canvas drew a field inside a field. 95 constants
      // across 48 components were in that state.
      //
      // Its own type, not the field's, because there is no field: read from the
      // `static const` declaration.
      final constKey = _constantKeyFor(member.name, constants);
      final leaf = _emitLeafOrNested(
        ctx,
        member.typeSource,
        member.value,
        currentClass: mainClass.name,
        visited: <String>{},
      );
      if (leaf != null) {
        constants[constKey] = leaf;
      } else {
        constantsUnroutable.add({
          'name': constKey,
          'type': member.typeSource,
        });
      }
      continue;
    }
    final kind = fieldKindOf(typeSource);
    if (kind == null) {
      // A nested `CoreXxxStyle?` slot. Not a leaf — the value is the child
      // component's whole style, and what's written here is only a *partial*
      // (`core/style-contract.md`: the parent forwards raw and the child's
      // resolver fills its own defaults, so the parent must not reach into
      // them). Emitting the partial alone would hand the builder a style with
      // every non-diverging field missing, so the merge happens here.
      final nested = _emitNestedStyle(
        ctx,
        typeSource,
        member.value,
        parentClass: mainClass.name,
        visited: <String>{},
      );
      if (nested != null) {
        fields[jsonKey] = nested;
        continue;
      }
      // …or an ENUM whose name ends in `Style`. See `_emitLeafOrNested` for why
      // the registry and not the name decides.
      final bareType = typeSource.replaceAll('?', '').trim();
      if (_nestedStyleName.hasMatch(bareType) &&
          ctx.classRegistry[bareType] == null) {
        final choice = emitByKind(
          ctx,
          FieldKind.choice,
          member.value,
          currentClass: mainClass.name,
        );
        if (choice != null) {
          fields[jsonKey] = choice;
          continue;
        }
      }
      // A slot whose type is the component's OWN style is self-referential —
      // `CoreMenuStyle.submenuStyle` is a `CoreMenuStyle?`, because a menu item
      // can open a menu. The cycle guard in `_emitNestedStyle` stops the
      // recursion (correctly — expanding it has no fixed point), and the reason
      // says so instead of claiming the reader has no route for the type. It
      // has
      // one; the type is its own container.
      final selfRef = typeSource.replaceAll('?', '').trim() == mainClass.name;
      untokenized.add(
        UntokenizedField(
          jsonKey: jsonKey,
          typeSource: typeSource,
          reason: selfRef ? 'self-referential' : 'unroutable-type',
        ),
      );
      continue;
    }
    final leaf = emitByKind(
      ctx,
      kind,
      member.value,
      currentClass: mainClass.name,
    );
    if (leaf == null) {
      untokenized.add(
        UntokenizedField(
          jsonKey: jsonKey,
          typeSource: typeSource,
          reason: 'unresolvable-value',
        ),
      );
      continue;
    }
    fields[jsonKey] = leaf;
  }

  return ComponentDoc(
    fields: fields,
    variants: variants,
    sizes: sizes,
    untokenized: untokenized,
    constants: constants,
    constantsUnroutable: constantsUnroutable,
    behaviour: _emitBehaviour(ctx, contract),
    slots: _emitSlots(contract),
    absent: _absentFields(
      mainClass,
      fields: fields,
      dispatches: [variants, sizes],
      untokenized: untokenized,
      unevaluatedDispatches: unevaluatedDispatches,
      deprecated: deprecated,
      derivedDefaults: derivedDefaults,
    ),
    derivedDefaults: derivedDefaults,
    deprecated: deprecated,
    hostDerived: [
      for (final f in mainClass.instanceFields)
        if (f.isHostDerived) jsonKeyForField(f.name),
    ],
  );
}

/// The declared instance fields that reached no value — see
/// [ComponentDoc.absent].
///
/// "Reached" spans all three places a value can land: a `default*` leaf in
/// [fields], and a per-variant or per-size entry inside a dispatch table. A
/// field the reader *tried* and failed on is not absent but broken, so
/// [untokenized] is subtracted: mixing the two would let a routing regression
/// hide as a design decision, which is the same conflation this map exists to
/// undo.
Map<String, String> _absentFields(
  DiscoveredClass mainClass, {
  required Map<String, dynamic> fields,
  required List<Map<String, dynamic>> dispatches,
  required List<UntokenizedField> untokenized,
  required List<String> unevaluatedDispatches,
  required List<String> deprecated,
  required Map<String, String> derivedDefaults,
}) {
  // A dispatch table this reader could not evaluate holds values for fields it
  // cannot name, so no absence claim about this component is trustworthy.
  //
  // Not a hypothetical: `DescriptionCard.defaultsBySize` is a `static final`
  // comprehension that stitches two private tables through `merge`, which this
  // reader does not evaluate — so `padding` reached nothing, and the first
  // version of this map called it an intentional absence. It is not; the widget
  // reads `merged.padding ?? sizeDefaults.padding!` and paints 16. Publishing
  // that as "flush by design" would have taught the builder to stop padding a
  // component that pads, which is worse than the silence it replaced.
  //
  // The whole purpose of this map is telling a decision apart from a gap. A gap
  // wearing a decision's label is the one output that must not happen, so the
  // reader keeps quiet about the entire component rather than guess which of
  // its fields the unread table covers. The gap itself stays visible where it
  // already was — the field-coverage guard counts it.
  if (unevaluatedDispatches.isNotEmpty) return const {};

  final reached = {...fields.keys};
  for (final dispatch in dispatches) {
    for (final table in dispatch.values) {
      if (table is! Map) continue;
      for (final row in table.values) {
        if (row is Map) reached.addAll(row.keys.cast<String>());
      }
    }
  }
  final broken = {for (final u in untokenized) u.jsonKey};
  // A retired default is not an absence either: the value exists and the code
  // stopped applying it. Calling it "no value by decision" would publish the
  // opposite of what happened.
  final retired = deprecated.toSet();

  final absent = <String, String>{};
  for (final field in mainClass.instanceFields) {
    final jsonKey = jsonKeyForField(field.name);
    // A host-derived field reached no value because no constant CAN hold
    // it, not because the design decided on nothing — reporting it here
    // would ask the canvas to draw the one shape the code never stated.
    if (field.isHostDerived ||
        derivedDefaults.containsKey(jsonKey) ||
        reached.contains(jsonKey) ||
        broken.contains(jsonKey) ||
        retired.contains(jsonKey)) {
      continue;
    }
    final kind = fieldKindOf(field.typeSource);
    // A nested `CoreXxxStyle?` slot with nothing written is the documented
    // forward: the child's resolver supplies its own defaults, so there is no
    // parent decision to assert. Recorded so the ledger covers every declared
    // field, and distinguished so the assertion table can stay silent on it.
    absent[jsonKey] = kind?.name ?? 'nested';
  }
  return absent;
}

/// The contract's public, non-deprecated `static const default*` scalars —
/// [ComponentDoc.behaviour].
///
/// Only the `default*` names: that is the shape `core/style-contract.md`
/// gives a behaviour default, and a contract also holds constants that are
/// not one (a diagnostic message, a scale) which a canvas has no use for.
///
/// A default is a literal, or a reference that resolves to a scalar through the
/// same token table and class registry a Style default resolves through
/// (`CoreSpace.space8`, a sibling `defaultLongPressSlop`). One number, spelled
/// once on the contract, therefore reaches the widgets and the canvas alike —
/// the builder does not keep a copy of it.
Map<String, Object> _emitBehaviour(EmitContext ctx, DiscoveredClass? contract) {
  final behaviour = <String, Object>{};
  if (contract == null) return behaviour;
  for (final member in contract.staticMembers) {
    if (member.isPrivate || member.isDeprecated || !member.isConst) continue;
    if (!member.name.startsWith('default')) continue;
    final value = member.value;
    final scalar = value is LiteralValue
        ? value.value
        : value is RefValue
        ? resolveScalarValue(ctx, value, currentClass: contract.name)
        : null;
    if (scalar is int ||
        scalar is double ||
        scalar is bool ||
        scalar is String) {
      behaviour[jsonKeyFor(member.name)] = scalar!;
    }
  }
  return behaviour;
}

/// `{ name: {type, required, repeated} }` from a contract's widget-typed
/// getters (`W get child;` / `W? get leading;` / `List<W> get children;`).
///
/// The filter is the *declared type*, not the getter name — same convention
/// #1 as field collection. A contract's non-widget getters (`variant`,
/// `enabled`, `onTap`, `xxxStyle`) are semantic identifiers, behaviour and
/// chrome, and belong to the surface the resolver already covers; only the
/// widget-typed ones are composition slots the canvas has to represent.
///
/// `required` / `repeated` are what the plugin needs to pick a Figma
/// property kind: an optional single slot can become a Boolean (present /
/// absent) plus an instance swap, a required one only an instance swap, and
/// a repeated one neither — a variable-length list has no fixed property.
Map<String, dynamic> _emitSlots(DiscoveredClass? contract) {
  if (contract == null) return const {};
  final slots = <String, dynamic>{};
  final names = [for (final g in contract.getters) g.name]..sort();
  for (final name in names) {
    final getter = contract.getters.firstWhere((g) => g.name == name);
    final type = getter.typeSource;
    final bare = type.endsWith('?') ? type.substring(0, type.length - 1) : type;
    final repeated = bare.startsWith('List<') || bare.startsWith('Iterable<');
    final inner = repeated
        ? bare.substring(bare.indexOf('<') + 1, bare.lastIndexOf('>'))
        : bare;
    if (inner != 'W') continue;
    slots[name] = {
      'type': type,
      'required': !type.endsWith('?'),
      'repeated': repeated,
    };
  }
  return slots;
}

/// Child's own defaults ⊕ the parent's partial, for a nested `CoreXxxStyle`
/// slot — `{ backgroundColor: {...}, borderRadius: {...}, ... }`.
///
/// ## Why the merge belongs here and not in the plugin
///
/// `core/style-contract.md` requires nested slots to be **raw-forwarded**:
/// the parent resolver hands the child's resolver whatever partial the caller
/// gave, and the *child* fills its own defaults. It explicitly forbids the
/// parent reaching into `CoreChildStyle.defaultX` field by field ("자식
/// default 에 reach 하지 마라"), because a second copy of the child's
/// defaults in the parent is a divergence source at runtime.
///
/// The Figma builder has no child resolver to defer to — a generated
/// component is a flattened snapshot. So one of two things has to happen:
/// either the plugin re-implements the merge chain in TypeScript (a second
/// copy of the child's defaults, in a second language — exactly what the rule
/// forbids), or the merge happens here.
///
/// Here is the right place because this is an **observer**, not runtime: it
/// runs at build time, it is deterministic, its output is committed, and G1
/// re-runs it and byte-compares. The single source stays the Dart class — this
/// only records what that class's value resolves to.
///
/// [visited] breaks reference cycles (`style-contract.md` convention #7 makes
/// that the caller's job) and is threaded through recursion so a chain like
/// `chip_input → chip → closeButton` terminates. It starts EMPTY — seeding it
/// with the component's own class blocked the first self-reference rather than
/// the second, and a slot whose type is its own parent is a real value, not a
/// cycle: `CoreMenuStyle.submenuStyle` is a `CoreMenuStyle?` because a menu
/// item
/// opens a menu, and `defaultSubmenuStyle` states that the inline submenu's
/// panel is box-less (padding 0 / radius 0 / no border / transparent / no
/// shadow
/// / minWidth 0) because it renders flush inside its parent's panel. One level
/// down, the base below is the parent's own `default*` — which is exactly the
/// base the child menu's resolver uses, since the child IS the same class — so
/// the emitted object is the value the child draws, panel zeros and all. The
/// recursion into ITS `submenuStyle` then finds the class in [visited] and
/// stops.
///
/// The pre-seed was recorded as an untokenized `self-referential` field, which
/// was true about the type and wrong about the conclusion: there was a value to
/// carry and the seed dropped it whole.
Map<String, dynamic>? _emitNestedStyle(
  EmitContext ctx,
  String typeSource,
  AstValue parentDefault, {
  required String parentClass,
  required Set<String> visited,
  bool baseless = false,
}) {
  final bare = typeSource.replaceAll('?', '').trim();
  if (!_nestedStyleName.hasMatch(bare)) return null;
  if (visited.contains(bare)) return null;
  final child = ctx.classRegistry[bare];
  if (child == null) return null;

  final nextVisited = {...visited, bare};
  final childFieldType = <String, String>{
    for (final f in child.instanceFields) jsonKeyForField(f.name): f.typeSource,
  };

  final result = <String, dynamic>{};

  // Base — the child's own scalar defaults, unless this emit IS an overlay:
  // then
  // the base already exists one level up (the parent's own `default<Field>`)
  // and
  // filling the child's defaults in here would speak where the partial is
  // silent.
  //
  // `defaultSubmenuStyle` restates the submenu panel as box-less and says
  // nothing
  // about `spacing`; `merge` therefore keeps
  // `CoreMenuStyle.defaultPopupStyle`'s
  // spacing. Emitting the child's own defaults here instead handed it
  // `CorePopupStyle`'s — a number no resolver on either platform produces.
  if (!baseless) {
    // Base — the child's own scalar defaults. Its dispatch tables
    // (`defaultsByVariant` / `defaultsBySize`) are deliberately skipped: a
    // parent's slot holds one style instance, not a variant map, and which
    // variant it would be is the parent's semantic choice, not a value.
    for (final member in child.staticMembers) {
      if (member.isPrivate) continue;
      if (member.typeSource.startsWith('Map<')) continue;
      // A retired default is not the child's base, for the reason the
      // top-level branch in `buildComponentDoc` drops it: the child's
      // resolver no longer reads it. Kept, it would pin the slot to a value
      // neither platform draws — `CoreButtonStyle.defaultBorderRadius` (8)
      // forced into every Button slot a parent leaves silent, while the
      // composed Button paints its size row's corner.
      if (member.isDeprecated) continue;
      final key = jsonKeyFor(member.name);
      final fieldType = childFieldType[key];
      if (fieldType == null) continue;
      final leaf = _emitLeafOrNested(
        ctx,
        fieldType,
        member.value,
        currentClass: child.name,
        visited: nextVisited,
      );
      if (leaf != null) result[key] = leaf;
    }
  }

  // Overlay — the parent's partial wins, field by field, same direction as
  // `CoreXxxStyle.merge(other)`.
  //
  // Through an alias, not only a literal call. A parent may state its partial
  // in
  // a shared const and point the slot at it by name
  // (`static const defaultSearchFieldStyle = chromelessFieldStyle;`), and an
  // overlay that accepted only `CallValue` skipped every one of those — the
  // leaf
  // came out as the CHILD's own defaults, which for a chromeless forward is the
  // opposite of what the parent says. Four forwards in this repo were inverted
  // that way, and a builder writing the exported numbers would have painted
  // `TextField`'s defaults onto a `TextField`.
  final parent = resolveCallInScope(
    ctx,
    parentDefault,
    currentClass: parentClass,
  );
  if (parent != null) {
    for (final arg in parent.call.namedArgs.entries) {
      final key = jsonKeyFor(arg.key);
      final fieldType = childFieldType[key];
      if (fieldType == null) continue;
      // In the scope of the class that WROTE the call, never the child's. A
      // bare `defaultBackgroundColor` here is the parent's sibling constant;
      // emitting it in the child's scope found the child's same-named default
      // (a different value) or nothing at all, and either way the canvas got
      // the child's chrome where the parent had stated its own. `CardImage`'s
      // frame drew a `surface` fill and an `outline-variant` border while both
      // platforms paint it transparent; `Chip`'s clickable radius came out 4
      // where Core says 9999.
      final leaf = _emitLeafOrNested(
        ctx,
        fieldType,
        arg.value,
        currentClass: parent.scope,
        visited: nextVisited,
        baseless: baseless || result[key] is Map<String, dynamic>,
      );
      // A reference the reader could not follow is the whole fault in one
      // line: the parent stated a value, and silence here hands the child's
      // default to the canvas with nothing reporting it. Refuse.
      //
      // Two shapes, told apart because null means different things. On a LEAF
      // field `fieldKindOf` names the shape, so no emission means the
      // identifier went nowhere. On a NESTED-STYLE slot null is also what the
      // cycle guard returns, and the two are separated by asking whether the
      // identifier names a constructor at all: a cycle's does — only the
      // recursion is cut — and an unresolved one's does not. Restricting the
      // refusal to leaves left that slot as the one door this check did not
      // close, and the child's base default walked through it exactly as
      // before (#5001; no site reaches it today, which is why it went unseen).
      if (leaf == null && arg.value is RefValue) {
        final namesLeafShape = fieldKindOf(fieldType) != null;
        final namesConstructor =
            resolveCallInScope(
              ctx,
              arg.value,
              currentClass: parent.scope,
            ) !=
            null;
        if (namesLeafShape || !namesConstructor) {
          throw StateError(
            '${parent.scope}: nested `${child.name}` default argument '
            '`${arg.key}: ${arg.value}` could not be resolved — the identifier '
            'names no static member the reader can follow (from '
            '`$parentClass`), or its value has no emission for a `$fieldType` '
            "field. Left unresolved, `${child.name}`'s own default would reach "
            'the canvas in its place.',
          );
        }
      }
      if (leaf != null) result[key] = _deepOverlay(result[key], leaf);
    }
  }

  return result.isEmpty ? null : result;
}

/// One overlay step, recursive through nested-style objects — the emit's stand-
/// in
/// for `CoreXxxStyle.merge(other)`, which is itself recursive for nested slots
/// (`iconStyle?.merge(other.iconStyle) ?? other.iconStyle`, `style-
/// contract.md`).
///
/// Replacing wholesale instead lost every sub-field the parent's partial did
/// not
/// restate. `CoreMenuStyle.defaultPopupStyle` sets the panel's `spacing`, and
/// `defaultSubmenuStyle` restates that panel as box-less WITHOUT naming spacing
/// —
/// so a wholesale overlay handed the submenu `CorePopupStyle`'s own spacing,
/// not
/// the menu's, and the exported number disagreed with what the child resolver
/// computes. The zeros the partial DOES name still win; only the silence stops
/// erasing.
///
/// Leaves are unaffected: [emitColor] / [emitDim] and friends always write
/// their
/// full key set, so for them a recursive overlay and a replacement agree.
Object _deepOverlay(Object? base, Object over) {
  if (base is! Map<String, dynamic> || over is! Map<String, dynamic>)
    return over;
  final merged = <String, dynamic>{...base};
  for (final e in over.entries) {
    final prior = merged[e.key];
    final value = e.value;
    merged[e.key] = value == null ? null : _deepOverlay(prior, value as Object);
  }
  return merged;
}

final RegExp _nestedStyleName = RegExp(r'^Core[A-Z][A-Za-z0-9]*Style$');

/// One field of a nested style — a leaf when [fieldKindOf] routes it, another
/// nested object when it is itself a `CoreXxxStyle` slot, `null` otherwise.
Map<String, dynamic>? _emitLeafOrNested(
  EmitContext ctx,
  String typeSource,
  AstValue value, {
  required String currentClass,
  required Set<String> visited,
  bool baseless = false,
}) {
  final kind = fieldKindOf(typeSource);
  if (kind != null) {
    return emitByKind(ctx, kind, value, currentClass: currentClass);
  }
  final nested = _emitNestedStyle(
    ctx,
    typeSource,
    value,
    parentClass: currentClass,
    visited: visited,
    baseless: baseless,
  );
  if (nested != null) return nested;
  // A `Core*Style` name the class registry does not know is an ENUM whose name
  // happens to end in `Style`, and it routes as a `choice` like every other
  // Core
  // enum.
  //
  // `fieldKindOf` cannot tell them apart on its own — it sees only the name,
  // and
  // `_looksLikeCoreEnum` excludes the `Style` suffix on the (correct) grounds
  // that a nested style slot is handled above. Deciding by what the type IS
  // rather than by what it is called is what separates the two, and the
  // registry
  // is where that answer lives. Two fields sat in `unroutable-type` for want of
  // it — `frame.borderStyle` and `outlined_container.borderStyle`, both
  // `enum Core…BorderStyle`.
  final bare = typeSource.replaceAll('?', '').trim();
  if (_nestedStyleName.hasMatch(bare) && ctx.classRegistry[bare] == null) {
    return emitByKind(ctx, FieldKind.choice, value, currentClass: currentClass);
  }
  return null;
}

/// Emits one dispatch table (`defaultsByVariant` / `defaultsBySize` /
/// off-convention) — `{ normalizedKeyName: { field: leaf, ... }, ... }`,
/// each entry's fields routed by the dispatch's *value class*'s own
/// instance-field types (e.g. `CoreCardVariantStyle`'s `backgroundColor:
/// CoreColor`), looked up from [EmitContext.classRegistry] the same way
/// [buildComponentDoc] looks up the MAIN class's own fields.
/// Expands a per-key map comprehension into the [MapValue] the rest of this
/// file already emits, or `null` when the shape is anything but the one this
/// repo writes.
///
/// The iterated domain is NOT taken from the enum — this reader does not read
/// enums. It comes from the map being indexed, and the `!` in `A[size]!` is
/// what makes that sound: a null there would throw at runtime, so `A`'s keys
/// already cover every member the loop visits. Recovering the domain from `A`
/// gives the same set without teaching the reader a second thing.
///
/// One shape handled: the entry key IS the loop variable, and the body is
/// either `A[v]` or `A[v].merge(B[v])`. Anything else returns `null` and the
/// table stays unevaluated — which surfaces as a suppressed absence claim, the
/// honest outcome for a value this reader cannot read.
MapValue? _expandComprehension(
  ComprehensionValue value,
  String currentClass,
  EmitContext ctx,
) {
  final key = value.key;
  if (key is! RefValue ||
      key.owner != null ||
      key.member != value.loopVariable) {
    return null;
  }
  final cls = ctx.classRegistry[currentClass];
  if (cls == null) return null;

  final body = value.body;
  final isMergeCall =
      body is CallValue && body.callee == 'merge' && body.receiver != null;
  if (isMergeCall && body.positionalArgs.length != 1) return null;
  final baseExpr = isMergeCall ? body.receiver! : body;
  final overlayExpr = isMergeCall ? body.positionalArgs.first : null;

  final base = _indexedTable(baseExpr, value.loopVariable, cls);
  if (base == null) return null;
  final overlay = overlayExpr == null
      ? null
      : _indexedTable(overlayExpr, value.loopVariable, cls);

  final entries = <MapEntryValue>[];
  for (final entry in base.entries) {
    final left = entry.value;
    if (left is! CallValue) return null;
    final right = overlay == null ? null : _entryFor(overlay, entry.key);
    entries.add(
      MapEntryValue(
        entry.key,
        right is CallValue ? _mergeCalls(left, right) : left,
      ),
    );
  }
  return MapValue(entries);
}

/// The [MapValue] that a `someTable[loopVar]` body indexes into, or `null`.
///
/// Private members are accepted, unlike in the emission loop. A table being
/// private is *why* the comprehension exists — it stitches two of them — so
/// refusing to look would defeat the expansion.
MapValue? _indexedTable(
  AstValue body,
  String loopVariable,
  DiscoveredClass cls,
) {
  if (body is! IndexValue) return null;
  final index = body.index;
  if (index is! RefValue ||
      index.owner != null ||
      index.member != loopVariable) {
    return null;
  }
  final target = body.target;
  if (target is! RefValue || target.owner != null) return null;
  for (final m in cls.staticMembers) {
    if (m.name != target.member) continue;
    final v = m.value;
    return v is MapValue ? v : null;
  }
  return null;
}

AstValue? _entryFor(MapValue table, AstValue key) {
  if (key is! RefValue) return null;
  for (final e in table.entries) {
    final k = e.key;
    if (k is RefValue && k.member == key.member) return e.value;
  }
  return null;
}

/// `A.merge(B)` on two constructor calls: B's named arguments win where it has
/// them, A's stand where it does not — the right-wins semantics every
/// `CoreXxxStyle.merge` implements.
CallValue _mergeCalls(CallValue base, CallValue overlay) => CallValue(
  owner: base.owner,
  callee: base.callee,
  positionalArgs: base.positionalArgs,
  namedArgs: {...base.namedArgs, ...overlay.namedArgs},
);

/// The VALUE type of a `Map<K, V>` declaration, as written.
///
/// Split on the top-level comma so a generic key or value
/// (`Map<Size, Map<Bool, Row>>`) keeps its own brackets intact — a naive
/// `split(',')` would cut inside them and hand back a fragment that
/// matches no route.
String _mapValueTypeSource(String typeSource) {
  final open = typeSource.indexOf('<');
  if (open < 0 || !typeSource.trimRight().endsWith('>')) return typeSource;
  final inner = typeSource.substring(open + 1, typeSource.lastIndexOf('>'));

  var depth = 0;
  for (var i = 0; i < inner.length; i++) {
    final char = inner[i];
    if (char == '<') depth++;
    if (char == '>') depth--;
    if (char == ',' && depth == 0) return inner.substring(i + 1).trim();
  }
  return inner.trim();
}

Map<String, dynamic>? _emitDispatch(
  EmitContext ctx,
  StaticMember member, {
  required String currentClass,
  required List<UntokenizedField> untokenized,
}) {
  final mapValue = switch (member.value) {
    final MapValue v => v,
    // `{for (final size in Enum.values) size: A[size]!.merge(B[size])}` —
    // expanded here rather than in `ast_value.dart` because it needs the
    // class's other members, which that file deliberately cannot see.
    final ComprehensionValue v => _expandComprehension(v, currentClass, ctx),
    _ => null,
  };
  if (mapValue == null) return null;

  final result = <String, dynamic>{};

  // A table may be keyed on TWO axes — `Map<Variant, Map<Emphasis, Row>>`,
  // which is how a component with two axes states its rows. Flattened to
  // `outer/inner` keys before the loop rather than taught to it: the loop
  // resolves each value to a constructor call, and a nested map is not one,
  // so every entry was skipped and the whole table exported as `{}`.
  //
  // Banner lost all five variants' colours to exactly that, and nothing
  // said so — an empty table reads as "this component declined to decide",
  // which is the opposite of what a two-axis table means. The third time
  // this shape has bitten; the BOOL-key and alias notes below are the other
  // two, and all three ended with the same symptom.
  final entries = <MapEntry<String, AstValue>>[];
  for (final entry in mapValue.entries) {
    final outer = switch (entry.key) {
      RefValue(:final member) => normalizeVariantName(member),
      LiteralValue(value: final bool b) => b ? 'true' : 'false',
      _ => null,
    };
    if (outer == null) continue;
    final nested = entry.value;
    if (nested is MapValue) {
      for (final sub in nested.entries) {
        final inner = switch (sub.key) {
          RefValue(:final member) => normalizeVariantName(member),
          LiteralValue(value: final bool b) => b ? 'true' : 'false',
          _ => null,
        };
        if (inner != null) entries.add(MapEntry('$outer/$inner', sub.value));
      }
    } else {
      entries.add(MapEntry(outer, nested));
    }
  }

  for (final entry in entries) {
    // Both key shapes are already resolved above — enum members through
    // `normalizeVariantName`, booleans as 'false'/'true' (which is what
    // builders write into variant NAMES for a boolean axis, so a row lands
    // under the same string a member is named after), and two-axis rows as
    // `outer/inner`.
    final keyName = entry.key;

    // Through an alias, not only a literal call. A dispatch table may point
    // each
    // key at a NAMED constant instead of writing the call inline
    // (`{CoreTextFieldVariant.defaultVariant: defaultNormalVariant, …}`), and
    // refusing anything but a `CallValue` dropped the whole table: `text_field`
    // exported `defaultsByVariant: {}` while Dart stated two full rows, and the
    // colours those rows carry landed in `absent` — recorded as decisions the
    // component had declined to make, when it had made them by name.
    final row = resolveCallInScope(
      ctx,
      entry.value,
      currentClass: currentClass,
    );
    final call = row?.call;
    // The row's arguments are names in the scope of the class that wrote the
    // row — `currentClass` for an inline row, the alias's owner otherwise.
    // See `resolveCallInScope`.
    final rowScope = row?.scope ?? currentClass;
    if (call == null) {
      // A row may be a bare SCALAR rather than a field bag —
      // `Map<CoreComponentSize, double>` states one number per size, and
      // there is no field name to hang it under because the table itself
      // is the field. Skipping those exported `{}` while Dart stated six
      // rows, so Avatar reached the canvas with no diameter for any size.
      //
      // The fourth time this reader has dropped a whole table on a value
      // shape it did not expect. The routing is the same one the field
      // bags use, aimed at the map's declared VALUE type instead of at a
      // constructor's parameter types.
      final leaf = _emitLeafOrNested(
        ctx,
        _mapValueTypeSource(member.typeSource),
        entry.value,
        currentClass: currentClass,
        visited: <String>{},
      );
      if (leaf != null) {
        result[keyName] = leaf;
      } else {
        untokenized.add(
          UntokenizedField(
            jsonKey: '${member.name}.$keyName',
            typeSource: _mapValueTypeSource(member.typeSource),
            reason: 'unroutable-type',
          ),
        );
      }
      continue;
    }
    final valueClassName = call.owner ?? call.callee;
    final valueClass = ctx.classRegistry[valueClassName];
    final fieldTypeByJsonKey = <String, String>{
      if (valueClass != null)
        for (final f in valueClass.instanceFields)
          jsonKeyForField(f.name): f.typeSource,
    };

    final entryFields = <String, dynamic>{};
    for (final arg in call.namedArgs.entries) {
      final jsonKey = jsonKeyFor(arg.key);
      final typeSource = fieldTypeByJsonKey[jsonKey];
      // The same router the top-level fields use, not `fieldKindOf` alone. A
      // row
      // may hold a nested `CoreXxxStyle?` slot exactly as a top-level field can
      // —
      // `chip.defaultsBySize.<size>.closeButtonStyle` is a `CoreButtonStyle?` —
      // and routing rows by leaf kind only sent every one of those to
      // `unroutable-type`. Five rows of one component's forward were missing
      // for
      // that reason, and "the reader has no route for this type" was not true:
      // it had one, on the other path.
      final leaf = typeSource == null
          ? null
          : _emitLeafOrNested(
              ctx,
              typeSource,
              arg.value,
              currentClass: rowScope,
              visited: <String>{},
            );
      if (leaf == null) {
        // An explicit `null` is a STATEMENT, not a routing failure. A row that
        // writes `backgroundColor: null` says "this variant has no fill", which
        // is a different thing from not mentioning the field (that inherits the
        // flat default), and `unroutable-type` said the reader had no route for
        // `CoreColor?` — which it plainly does. Emitted as JSON null so the
        // builder can tell the two apart.
        if (arg.value case LiteralValue(value: null)) {
          entryFields[jsonKey] = null;
          continue;
        }
        untokenized.add(
          UntokenizedField(
            // `member.name`, not `member` — interpolating the object put
            // "Instance of 'StaticMember'" in the key, which is only visible
            // once the list is exported rather than counted.
            jsonKey: '${member.name}.$keyName.$jsonKey',
            typeSource: typeSource ?? 'unknown',
            reason: typeSource == null
                ? 'unresolvable-value'
                : 'unroutable-type',
          ),
        );
        continue;
      }
      entryFields[jsonKey] = leaf;
    }
    result[keyName] = entryFields;
  }
  return result;
}

/// Builds the full document — `{meta, components}` — from every MAIN Style
/// class the reader discovered, sorted by component slug for deterministic
/// output. `slugOf` derives the component slug from the class name
/// (`CoreButtonStyle` → `button`) the same way `census.dart`'s "identity
/// from class name, not filename" convention already establishes for
/// discovery.
String slugOf(String className) {
  var name = className;
  if (name.startsWith('Core')) name = name.substring(4);
  if (name.endsWith('Style')) name = name.substring(0, name.length - 5);
  final buffer = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final char = name[i];
    if (i > 0 && char.toUpperCase() == char && char != char.toLowerCase()) {
      buffer.write('_');
    }
    buffer.write(char.toLowerCase());
  }
  return buffer.toString();
}

final class BuildResult {
  const BuildResult({required this.doc, required this.untokenizedTotal});
  final Map<String, dynamic> doc;
  final int untokenizedTotal;
}

/// Pure document builder — no file I/O, so the golden test can call it
/// directly against the reader's output and byte-compare, matching
/// `tool/generate_style_tables.dart`'s established golden-test shape
/// (`buildDoc()` separated from `main()`'s file writing).
BuildResult buildDoc(
  EmitContext ctx,
  Map<String, DiscoveredClass> classesByName,
) {
  // A retired component is not a value to export, for the same reason a
  // retired default is not (see the `member.isDeprecated` branch in
  // `buildComponentDoc`): the class still compiles through its deprecation
  // window, but the design system draws its replacement now. Shipping it
  // would put a component on the canvas whose builder has been retired,
  // with every field it carries reporting as sent-but-unread.
  final componentNames =
      classesByName.values
          .where((c) => c.implementsCoreStyle && !c.isDeprecated)
          .map((c) => c.name)
          .toList()
        ..sort();

  final components = <String, dynamic>{};
  var untokenizedTotal = 0;
  for (final className in componentNames) {
    final slug = slugOf(className);
    // `CoreCardStyle` → `CoreCardContract`. Absent for components whose
    // contract lives under a different name (or has none) — `_emitSlots`
    // then emits `{}` rather than guessing.
    final contractName =
        '${className.substring(0, className.length - 'Style'.length)}Contract';
    final doc = buildComponentDoc(
      ctx,
      classesByName[className]!,
      contract: classesByName[contractName],
    );
    components[slug] = doc.toJson();
    untokenizedTotal += doc.untokenized.length;
  }

  return BuildResult(
    doc: {
      'meta': {
        // v3 = v2 상위 집합 — v2 leaf 3종(fields/variants/sizes)은 byte-불변,
        // 그 위에 additive 키 4종(section/axes/docs/examples)이 얹힌다.
        // 숫자 하나로 소비자(plugin data.ts)가 기대 키 집합을 조건 없이
        // 알 수 있게 하는 자기 기술 마커.
        'schema': 3,
        'source': 'coui_core',
        'generator': 'export_figma_components.dart (schema v3)',
        'note':
            'Visual defaults for the Figma plugin data-driven builders — '
            'every CoreXxxStyle the AST reader discovered, walked '
            'generically (no per-component hand-written extraction). '
            'v3 adds per-component section/axes/docs/examples on top of '
            'the byte-stable v2 fields/variants/sizes.',
      },
      'components': components,
    },
    untokenizedTotal: untokenizedTotal,
  );
}
