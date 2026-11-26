/// Typed emit layer — one function per *value type* (`emitDim` /
/// `emitColor` / `emitInsets` / `emitRadius` / `emitText` / `emitGap` /
/// `emitIcon`), not one function per component. The old
/// `export_figma_components.dart` picked a shape decision — how many
/// corners a radius has, whether padding keeps its directional flag,
/// which `CoreTextStyle` fields survive — *inside* each of its ten
/// hand-written per-component functions, so the same bug (e.g. "only
/// `topLeft` survives") had to be independently reintroduced or
/// independently fixed in every one. Deciding shape once, per type, here,
/// means a fix like "read all four corners" lands for every component that
/// has a radius in a single change (`core/style-contract.md`'s "same
/// concept, same shape").
///
/// ## The ten divergences this layer closes
///
///  1. **Key naming** — the emitted JSON key is always the Dart field name
///     with a leading `default` stripped and the next letter lowercased
///     (`defaultBackgroundColor` → `backgroundColor`; a non-`default`
///     override field like `background` emits as `background`, verbatim).
///     No component-specific key remap table exists anywhere in this
///     reader — see `census.dart`'s and `style_reader.dart`'s "이름이
///     아니라 타입" principle applied to output, not just input.
///  2. **Variant-name normalisation applies everywhere or nowhere** — see
///     `normalizeVariantName`, called by every dispatch-table emitter, not
///     hand-wired into one component's function.
///  3. **Radius always emits all four corners** — `emitRadius` reads
///     `topLeft`/`topRight`/`bottomLeft`/`bottomRight` from a
///     `CoreBorderRadius.all/only(...)` call, never just the first
///     argument.
///  4. **Insets never drop the directional flag** — `emitInsets` picks the
///     schema v2 union member (`{l,t,r,b}` physical vs `{start,t,end,b}`
///     logical) from which `CoreEdgeInsets` constructor was called
///     (`.directional(...)` vs `.all`/`.symmetric`/`.only(...)`), it never
///     flattens to physical unconditionally.
///  5. **Text style keeps every field** — `emitText` reads role, fontSize,
///     fontWeight, letterSpacing, lineHeight, lineHeightPx, fontFamily, and
///     color, not just the first two it finds.
///  6/9. **State/variant/size coverage is structural, not curated** — the
///     caller (the exporter driving this layer) walks every static member
///     `census.dart` discovers, so which fields survive is never a
///     per-component editorial choice; and every component's JSON always
///     has the same three-key shape (`fields`/`variants`/`sizes`), present
///     even when empty, rather than three divergent output shapes.
///  7/8. **No field gets left out because a hand-written function forgot
///     it** — the same "walk everything the reader found" property as
///     6/9 — this layer has no per-component allowlist to fall out of.
/// 10. **Color is a fixed 4-key shape, never a union** — `emitColor`
///     always returns `{ref, argb, opacity, fallbacks}`; a color with no
///     token still gets `ref: null` and a real `argb`, not a
///     differently-shaped map.
library;

import 'ast_value.dart';
import 'style_reader.dart';
import 'token_scale.dart';

/// `defaultBackgroundColor` → `backgroundColor`. A name with no `default`
/// prefix (a caller-override slot like `background`) passes through
/// unchanged — divergence #1's fix: the emitted key is *always* this
/// function of the Dart field name, never a per-component lookup table.
///
/// Only for the `static const default*` MEMBER side of the pairing — an
/// instance field's key is its own name ([jsonKeyForField]). Applying this to
/// both sides cost `CoreAspectRatioBoxStyle` its only value: the field really is
/// named `defaultRatio` and its default really is `defaultDefaultRatio`, so
/// stripping both landed the constant on `defaultRatio` and the field on
/// `ratio`. The two never met, `fields` came out empty, and the absence pass
/// then recorded a decision about `ratio` — a name no field has.
String jsonKeyFor(String dartFieldName) {
  if (!dartFieldName.startsWith('default') || dartFieldName == 'default') {
    return dartFieldName;
  }
  final rest = dartFieldName.substring('default'.length);
  if (rest.isEmpty) return dartFieldName;
  return rest[0].toLowerCase() + rest.substring(1);
}

/// An instance field's JSON key: its own name.
///
/// Spelled as a function rather than left implicit at the call sites so the
/// asymmetry with [jsonKeyFor] is stated where someone reading either one will
/// see it. A field named `defaultRatio` keeps that name — the `default` there is
/// part of what the field is called, not a prefix announcing a constant.
String jsonKeyForField(String dartFieldName) => dartFieldName;

/// `defaultVariant` / `default_` → `default` — the one normalisation this
/// reader applies, and it applies to *every* dispatch table's keys, not
/// only the one component the old exporter happened to call it for
/// (divergence #2).
String normalizeVariantName(String enumMemberName) =>
    (enumMemberName == 'defaultVariant' || enumMemberName == 'default_')
    ? 'default'
    : enumMemberName;

/// Everything an emit function needs to resolve a reference — the
/// namespace forward table (`token_scale.dart`) for primitive tokens, and
/// the global class registry (`repo_reader.dart`) for cross-Style-class
/// references (`core/style-contract.md` convention #3: "2차 해소는
/// 전역") and same-class bare references
/// (`CoreRangeStyle.defaultsByVariant`'s `defaultActiveTrackColor` reading
/// the sibling `static const` in the same class).
final class EmitContext {
  const EmitContext({
    required this.tokenScale,
    required this.classRegistry,
    this.resolveSemanticColor,
  });

  final Map<String, TokenEntry> tokenScale;
  final Map<String, DiscoveredClass> classRegistry;

  /// Resolves a semantic colour token name (`'primary'`, `'onSurface'`)
  /// to a concrete ARGB int. `null` when no resolver is wired — schema
  /// v2's `argb` field then falls back to `0` (unresolved sentinel,
  /// matching `CoreColor.token(...)`'s own `argb == 0` until a
  /// `CoreColorScheme` resolves it — see `core_color.dart`'s doc
  /// comment). Kept as an injectable callback rather than importing
  /// `coui_core`'s runtime `CoreColorScheme` directly, so this file stays
  /// a pure function of the AST it's handed and is unit-testable without
  /// constructing a real theme; the exporter wires a real resolver.
  final int? Function(String semanticName)? resolveSemanticColor;
}

// ── Dim ──────────────────────────────────────────────────────────────────

/// A resolved scalar — literal, or a chain through [EmitContext] ending in
/// one. Mirrors `token_scale.dart`'s `_Resolved` but generalized to also
/// walk Style-class static members, not just namespace classes.
final class _Scalar {
  const _Scalar(this.value, this.ref, this.via);
  final Object value;
  final String? ref;
  final List<String> via;
}

/// Resolves [value] to a terminal scalar, following reference hops through
/// both [EmitContext.tokenScale] (namespace primitives — already fully
/// resolved, so a namespace hit is always terminal) and
/// [EmitContext.classRegistry] (Style-class static members, which may
/// themselves chain further — same-class bare refs and cross-class refs
/// alike). `via` accumulates every hop's own name, nearest-first — a
/// same-class hop records as `member`, a cross-class one as
/// `'Owner.member'`, matching `token_scale.dart`'s convention so the two
/// modules' `via` values read the same way.
_Scalar? _resolveScalar(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
  List<String> viaSoFar = const [],
  int hopsRemaining = 6,
}) {
  if (hopsRemaining < 0) return null;
  return switch (value) {
    LiteralValue(:final value) when value is num => _Scalar(
      value,
      null,
      viaSoFar,
    ),
    LiteralValue(:final value) when value is String => _Scalar(
      value,
      null,
      viaSoFar,
    ),
    RefValue(:final owner, :final member) => _followRef(
      ctx,
      targetOwner: owner ?? currentClass,
      member: member,
      hopLabel: owner == null ? member : '$owner.$member',
      viaSoFar: viaSoFar,
      hopsRemaining: hopsRemaining,
    ),
    // `ringOffset + ringWidth` — folded here rather than in the parser,
    // because folding needs the registry and the parser has none.
    //
    // The result carries `ref: null` and the two operands' names in `via`.
    // That is the honest shape: the sum is not any one token, so binding it
    // to a Figma variable would name the wrong primitive, while the `via`
    // chain still records what it was computed from.
    BinaryValue(:final op, :final left, :final right) => _foldBinary(
      ctx,
      op: op,
      left: left,
      right: right,
      currentClass: currentClass,
      viaSoFar: viaSoFar,
      hopsRemaining: hopsRemaining,
    ),
    _ => null,
  };
}

_Scalar? _foldBinary(
  EmitContext ctx, {
  required String op,
  required AstValue left,
  required AstValue right,
  required String currentClass,
  required List<String> viaSoFar,
  required int hopsRemaining,
}) {
  if (hopsRemaining < 0) return null;
  final l = _resolveScalar(
    ctx,
    left,
    currentClass: currentClass,
    hopsRemaining: hopsRemaining - 1,
  );
  final r = _resolveScalar(
    ctx,
    right,
    currentClass: currentClass,
    hopsRemaining: hopsRemaining - 1,
  );
  if (l == null || r == null) return null;
  final lv = l.value;
  final rv = r.value;
  if (lv is! num || rv is! num) return null;
  final folded = switch (op) {
    '+' => lv + rv,
    '-' => lv - rv,
    '*' => lv * rv,
    // Division is deliberately absent: no default in this codebase uses it,
    // and adding an untested branch here would be the same shape of guess
    // this reader refuses everywhere else.
    _ => null,
  };
  if (folded == null) return null;
  return _Scalar(folded, null, [...viaSoFar, ...l.via, ...r.via]);
}

_Scalar? _followRef(
  EmitContext ctx, {
  required String targetOwner,
  required String member,
  required String hopLabel,
  required List<String> viaSoFar,
  required int hopsRemaining,
}) {
  final via = [...viaSoFar, hopLabel];
  final tokenEntry = ctx.tokenScale['$targetOwner.$member'];
  if (tokenEntry != null) {
    return _Scalar(tokenEntry.value, tokenEntry.ref, [
      ...via,
      ...tokenEntry.via,
    ]);
  }
  final cls = ctx.classRegistry[targetOwner];
  if (cls == null) return null;
  final target = cls.staticMembers.where((m) => m.name == member).toList();
  if (target.isEmpty) return null;
  return _resolveScalar(
    ctx,
    target.single.value,
    currentClass: targetOwner,
    viaSoFar: via,
    hopsRemaining: hopsRemaining - 1,
  );
}

/// The terminal number or string [value] resolves to — through the same
/// token table and class registry every emit function here resolves
/// through — or `null` when the chain ends in neither.
///
/// For a reader that needs a plain value rather than a leaf: the role table
/// (`typography_roles.dart`) reads `CoreTypography.coui` with it, so a
/// reference there resolves exactly as it does in a component field. A
/// second resolver would be a second answer to what `CoreLineBox.px21` or
/// `CoreFontFamily.mono` is — neither is a token namespace, so only the
/// registry half of this path reaches them.
Object? resolveScalarValue(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) => _resolveScalar(ctx, value, currentClass: currentClass)?.value;

/// Emits a `Dim` leaf: `{v, ref, via}`. `via` is the alias chain joined
/// `' -> '` (nearest-first), or `null` for a value already at a terminal
/// primitive. Returns `null` when [value] isn't a scalar shape at all
/// (e.g. a nested composite) — the caller (a per-type emitter below)
/// decides what that means for its own field.
Map<String, dynamic>? emitDim(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  // `double.infinity` — a real value meaning "no ceiling", and the only value a
  // max constraint can take to say so. Emitted with no `v` because there is no
  // number to paint: a consumer reading `.v` correctly finds nothing, and the
  // field still reaches the JSON so the ledger stops calling it a reader
  // failure. Three `text_area` constraints said this and read as unreadable.
  if (value case RefValue(owner: 'double', member: 'infinity')) {
    return {'unbounded': true, 'ref': null, 'via': null};
  }
  final scalar = _resolveScalar(ctx, value, currentClass: currentClass);
  if (scalar == null || scalar.value is! num) return null;
  return {
    'v': (scalar.value as num).toDouble(),
    'ref': scalar.ref,
    'via': scalar.via.isEmpty ? null : scalar.via.join(' -> '),
  };
}

// ── Color ────────────────────────────────────────────────────────────────

/// Emits a `Color` leaf — always the fixed four-key shape
/// `{ref, argb, opacity, fallbacks}` (divergence #10: never a union, never
/// a bare `null`). [value] must be a `CoreColor.token(...)` call, a raw
/// `CoreColor(...)`/`.fromARGB(...)`/`.fromRGB(...)`/`.fromHex(...)` call,
/// or a reference resolving to one of those — anything else returns
/// `null` (not a colour at all; the caller's field is mistyped).
Map<String, dynamic>? emitColor(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  // `.transparent` (dot-shorthand) — the one `CoreColor` sentinel this
  // codebase's Style defaults use (`core/design-tokens.md`: "Transparent
  // 는 Core sentinel 사용"). Dot-shorthand resolves against the
  // *expression position's static type*, which for a colour-typed
  // argument is always `CoreColor` — but `CoreColor` lives outside
  // `contracts/` (`color/core_color.dart`), so it's never in
  // [EmitContext.classRegistry] the way a Style class is. Since this is
  // the only sentinel member `CoreColor` exposes for a bare dot-shorthand
  // in this position, it's resolved here directly rather than growing
  // `resolveCallInScope`'s registry lookup with a special case for a class
  // outside its domain.
  //
  // Checked on the END of the alias chain, not on [value] as written: a
  // parent forwarding its own `defaultBackgroundColor = .transparent` by name
  // hands this emitter a reference, and the sentinel sits one hop behind it.
  final terminal = terminalValue(ctx, value, currentClass: currentClass).value;
  if (terminal case RefValue(owner: null, member: 'transparent')) {
    // `argb: 0` (alpha channel 0) is what actually makes this transparent
    // — `opacity` stays `1.0`, matching every other raw-ARGB `CoreColor`
    // constructor (`core_color.dart`: `opacity = 1.0` for the raw-ARGB
    // path). A consumer combines both: `alpha = argbAlpha * opacity`.
    return const <String, dynamic>{
      'ref': null,
      'argb': 0,
      'opacity': 1.0,
      'fallbacks': <String>[],
    };
  }

  final resolved = resolveCallInScope(ctx, value, currentClass: currentClass);
  final call = resolved?.call;
  // Arguments belong to the class that WROTE the call, not the one that
  // named it — `resolveCallInScope`'s doc carries the failure this avoids.
  final scope = resolved?.scope ?? currentClass;
  if (call == null) return null;

  if (call.callee == 'token') {
    final tokenRef = call.positionalArgs.isEmpty
        ? null
        : call.positionalArgs.first;
    final semanticName = tokenRef is RefValue ? tokenRef.member : null;
    if (semanticName == null) return null;
    final opacityArg = call.namedArgs['opacity'];
    final opacity = opacityArg == null
        ? 1.0
        : (_resolveScalar(
                        ctx,
                        opacityArg,
                        currentClass: scope,
                      )?.value
                      as num?)
                  ?.toDouble() ??
              1.0;
    final fallbacksArg = call.namedArgs['fallbacks'];
    final fallbacks = <String>[
      if (fallbacksArg is ListValue)
        for (final item in fallbacksArg.items)
          if (item is RefValue) item.member,
    ];
    final argb = ctx.resolveSemanticColor?.call(semanticName) ?? 0;
    return {
      'ref': 'Semantic/color/${_kebab(semanticName)}',
      'argb': argb,
      'opacity': opacity,
      'fallbacks': fallbacks,
    };
  }

  // Raw ARGB construction — `CoreColor(0xAARRGGBB)`.
  if (call.owner == null &&
      call.callee == 'CoreColor' &&
      call.positionalArgs.length == 1) {
    final argbValue = _resolveScalar(
      ctx,
      call.positionalArgs.first,
      currentClass: scope,
    );
    if (argbValue?.value is num) {
      return {
        'ref': null,
        'argb': (argbValue!.value as num).toInt(),
        'opacity': 1.0,
        'fallbacks': const <String>[],
      };
    }
  }

  return null;
}

String _kebab(String camel) => camel.replaceAllMapped(
  RegExp('[A-Z]'),
  (m) => '-${m[0]!.toLowerCase()}',
);

/// Resolves [value] to the `CallValue` it names — either directly, or by
/// following reference hops (same-class or cross-class) until landing on
/// one. Used by every emitter whose leaf shape comes from a constructor
/// call (`emitColor`, `emitInsets`, `emitRadius`, `emitText`).
/// The `CallValue` a default eventually names, following identifier aliases.
///

/// The `CallValue` a default names AND the class whose body that call was
/// written in.
///
/// A constructor call's bare-identifier arguments (`backgroundColor:
/// defaultBackgroundColor`) are Dart names in the lexical scope of the class
/// that wrote the call — the alias hops that led to it do not change that, and
/// neither does the type being constructed. `_emitNestedStyle` used to emit
/// those arguments in the CHILD class's scope, so `CoreCardImageStyle`'s
/// `defaultBackgroundColor` (transparent) was looked up on
/// `CoreOutlinedContainerStyle`, found ITS `defaultBackgroundColor` (surface),
/// and the canvas drew a fill neither platform paints. Where the child had no
/// member of that name the argument resolved to nothing and the child's own
/// default reached the canvas instead — the same lie, reached the other way.
///
/// `scope` is [currentClass] for a call written inline, or the owner of the
/// static member the last alias hop landed on: a parent that forwards
/// `CoreOtherStyle.someNamedPartial` states its partial in `CoreOtherStyle`'s
/// scope, and that partial's identifiers belong there.
({CallValue call, String scope})? resolveCallInScope(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
  int hopsRemaining = 6,
}) {
  final terminal = terminalValue(
    ctx,
    value,
    currentClass: currentClass,
    hopsRemaining: hopsRemaining,
  );
  return terminal.value is CallValue
      ? (call: terminal.value as CallValue, scope: terminal.scope)
      : null;
}

/// Follows [value] through every reference hop that lands on a static member
/// of a registry class — a same-class bare name or a cross-class
/// `Owner.member` — and returns what the chain ends on, with the class whose
/// body wrote it.
///
/// The end is whatever is NOT such a hop: a literal, a constructor call, a
/// token-namespace reference (`CoreSpace.space16` — not a class in the
/// registry), or a dot-shorthand sentinel (`.transparent`, `.zero`). The
/// sentinel case is why this exists as its own function: a parent that
/// states `static const CoreColor defaultBackgroundColor = .transparent;` and
/// then forwards it by name into a nested default hands the emitter a
/// reference whose end is not a call, and `resolveCallInScope` alone reports
/// that as "not a colour". The colour is right there — one hop away.
({AstValue value, String scope}) terminalValue(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
  int hopsRemaining = 6,
}) {
  var current = value;
  var scope = currentClass;
  var hops = hopsRemaining;
  while (hops-- >= 0 && current is RefValue) {
    final ref = current;
    final owner = ref.owner ?? scope;
    final cls = ctx.classRegistry[owner];
    if (cls == null) break;
    final target = cls.staticMembers
        .where((m) => m.name == ref.member)
        .toList();
    if (target.isEmpty) break;
    current = target.single.value;
    scope = owner;
  }
  final folded = _foldNamedMerge(ctx, current, scope: scope, hops: hops);
  if (folded != null) return folded;
  return (value: current, scope: scope);
}

/// `someNamedConst.merge(const X(...))` — the receiver followed to its call,
/// with the merge argument's named args laid over it (right wins, as
/// `CoreXxxStyle.merge` does). `null` when [value] is not that shape.
///
/// The folded call has ONE scope, and its arguments come from two places: the
/// receiver's from the class that wrote the receiver, the overlay's from the
/// class that wrote the `merge`. The fold takes the receiver's scope. An
/// overlay argument that is a bare name (resolved by scope) would then be
/// read in the wrong class when the two differ, so that case refuses loudly
/// rather than emitting a sibling constant from the wrong class.
({AstValue value, String scope})? _foldNamedMerge(
  EmitContext ctx,
  AstValue value, {
  required String scope,
  required int hops,
}) {
  if (value is! CallValue ||
      value.callee != 'merge' ||
      value.receiver is! RefValue ||
      value.positionalArgs.length != 1) {
    return null;
  }
  final overlay = value.positionalArgs.single;
  if (overlay is! CallValue) return null;
  final base = terminalValue(
    ctx,
    value.receiver!,
    currentClass: scope,
    hopsRemaining: hops,
  );
  final baseCall = base.value;
  if (baseCall is! CallValue) return null;
  if (base.scope != scope &&
      overlay.namedArgs.values.any((v) => v is RefValue && v.owner == null)) {
    throw StateError(
      '$scope: `${value.receiver}.merge(...)` overlays a bare name onto a '
      'receiver written in `${base.scope}` — the folded call would read that '
      'name in the wrong class. Qualify it (`$scope.member`).',
    );
  }
  return (
    value: CallValue(
      owner: baseCall.owner,
      callee: baseCall.callee,
      positionalArgs: baseCall.positionalArgs,
      namedArgs: {...baseCall.namedArgs, ...overlay.namedArgs},
    ),
    scope: base.scope,
  );
}

// ── Insets ───────────────────────────────────────────────────────────────

/// Emits an `Insets` leaf — the schema v2 union's *only* sanctioned
/// member: `{l,t,r,b}` (physical) for `CoreEdgeInsets.all/symmetric/only`,
/// `{start,t,end,b}` (logical) for `CoreEdgeInsets.directional` (divergence
/// #4 — the directional flag decides the *shape*, it's never dropped).
Map<String, dynamic>? emitInsets(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  final zeroDim = emitDim(
    ctx,
    const LiteralValue(0),
    currentClass: currentClass,
  )!;

  // `.zero` (dot-shorthand). Same reasoning as `emitColor`'s `.transparent`:
  // the shorthand resolves against the field's static type, `CoreEdgeInsets`
  // lives outside `contracts/`, and `zero` is the only member reachable this
  // way. Written out rather than routed through the registry because "all
  // four sides are 0" is exactly what it means, and a padding of zero is a
  // decision — leaving it unemitted let the plugin apply its own default
  // instead.
  //
  // On the end of the alias chain (see `emitColor`): a parent forwarding its
  // own `defaultPadding = .zero` by name hands this a reference.
  final terminal = terminalValue(ctx, value, currentClass: currentClass).value;
  if (terminal case RefValue(owner: null, member: 'zero')) {
    return {'l': zeroDim, 't': zeroDim, 'r': zeroDim, 'b': zeroDim};
  }

  final resolved = resolveCallInScope(ctx, value, currentClass: currentClass);
  final call = resolved?.call;
  // Arguments belong to the class that WROTE the call, not the one that
  // named it — `resolveCallInScope`'s doc carries the failure this avoids.
  final scope = resolved?.scope ?? currentClass;
  if (call == null || call.owner != 'CoreEdgeInsets') return null;

  final zero = zeroDim;
  Map<String, dynamic>? dim(String argName) {
    final arg = call.namedArgs[argName];
    return arg == null ? zero : emitDim(ctx, arg, currentClass: scope);
  }

  switch (call.callee) {
    case 'all':
      final v = call.positionalArgs.isNotEmpty
          ? emitDim(ctx, call.positionalArgs.first, currentClass: scope)
          : zero;
      return {'l': v, 't': v, 'r': v, 'b': v};
    case 'symmetric':
      final h = dim('horizontal');
      final v = dim('vertical');
      return {'l': h, 't': v, 'r': h, 'b': v};
    case 'only':
      return {
        'l': dim('left'),
        't': dim('top'),
        'r': dim('right'),
        'b': dim('bottom'),
      };
    case 'directional':
      return {
        'start': dim('start'),
        't': dim('top'),
        'end': dim('end'),
        'b': dim('bottom'),
      };
    default:
      return null;
  }
}

// ── Radius ───────────────────────────────────────────────────────────────

/// Emits a `Radius` leaf — always all four corners (divergence #3: the
/// old exporter's `_radius()` read only `topLeft` and silently discarded
/// the other three, which is correct only for the uniform-corner case and
/// wrong — not just incomplete — for any asymmetric radius).
Map<String, dynamic>? emitRadius(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  final zero = emitDim(ctx, const LiteralValue(0), currentClass: currentClass)!;
  // `.zero` — the dot shorthand, which the unresolved parser gives as an
  // owner-less ref. Spelled out here for the reason `emitInsets` spells out its
  // own: "all four corners are 0" is exactly what it means, and a radius of zero
  // is a decision — leaving it unemitted let the plugin apply its own. One row
  // of one variant table (`swiper.defaultsByVariant.sheet.panelBorderRadius`)
  // sat in `unroutable-type` for want of these four lines, and `CoreBorderRadius`
  // was never the type the reader could not route.
  //
  // On the end of the alias chain (see `emitColor`), for the same reason.
  final terminal = terminalValue(ctx, value, currentClass: currentClass).value;
  if (terminal case RefValue(owner: null, member: 'zero')) {
    return {
      'topLeft': zero,
      'topRight': zero,
      'bottomLeft': zero,
      'bottomRight': zero,
    };
  }

  final resolved = resolveCallInScope(ctx, value, currentClass: currentClass);
  final call = resolved?.call;
  // Arguments belong to the class that WROTE the call, not the one that
  // named it — `resolveCallInScope`'s doc carries the failure this avoids.
  final scope = resolved?.scope ?? currentClass;
  if (call == null || call.owner != 'CoreBorderRadius') return null;

  Map<String, dynamic>? corner(String argName) {
    final arg = call.namedArgs[argName];
    return arg == null ? zero : emitDim(ctx, arg, currentClass: scope);
  }

  switch (call.callee) {
    case 'all':
    case 'circular':
      final v = call.positionalArgs.isNotEmpty
          ? emitDim(ctx, call.positionalArgs.first, currentClass: scope)
          : zero;
      return {
        'topLeft': v,
        'topRight': v,
        'bottomLeft': v,
        'bottomRight': v,
      };
    case 'only':
      return {
        'topLeft': corner('topLeft'),
        'topRight': corner('topRight'),
        'bottomLeft': corner('bottomLeft'),
        'bottomRight': corner('bottomRight'),
      };
    default:
      return null;
  }
}

// ── Text ─────────────────────────────────────────────────────────────────

/// Emits a `TextStyle` leaf — role (the stable Figma Text Style binding
/// key, e.g. `'body-small'`) plus every overlay field the source actually
/// set (divergence #5: the old exporter kept only fontSize/fontWeight and
/// silently dropped lineHeight/letterSpacing/fontFamily/the role name
/// itself — the role is what makes Figma Text Style binding possible at
/// all, so losing it wasn't a partial win, it was the one field that
/// mattered most).
Map<String, dynamic>? emitText(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  // `CoreTypography.coui.bodySmall`, with or without a `.copyWith(...)` on
  // top. Six defaults are written this way — a role picked straight off the
  // baseline scale rather than through `CoreTextStyle.token`. Both spellings
  // name the same role and emit the same leaf; the plugin looks the metrics
  // up in the document's role table either way.
  final scaleRole = _typographyScaleRole(value);
  if (scaleRole != null) {
    final overrides = value is CallValue
        ? value.namedArgs
        : const <String, AstValue>{};
    return _textLeaf(
      ctx,
      role: scaleRole,
      args: overrides,
      currentClass: currentClass,
    );
  }

  final resolved = resolveCallInScope(ctx, value, currentClass: currentClass);
  final call = resolved?.call;
  // Arguments belong to the class that WROTE the call, not the one that
  // named it — `resolveCallInScope`'s doc carries the failure this avoids.
  final scope = resolved?.scope ?? currentClass;
  if (call == null) return null;
  // A role-LESS `CoreTextStyle(color: …)` — the plain constructor, so the call
  // has no owner at all, only the class name as its callee. Seven components
  // state one and every one arrived as `unresolvable-value`:
  // `code_snippet.codeTextStyle`, `window`'s unfocused title, three
  // `validation_badge` labels, `code_diff`'s unchanged rows, `text_area`'s
  // error line. Refusing them read "no role" as "no value", and the colour
  // they carry is the whole point of the field.
  if (call.owner == null && call.callee == 'CoreTextStyle') {
    if (call.namedArgs.isEmpty) return null;
    return _textLeaf(
      ctx,
      role: null,
      args: call.namedArgs,
      currentClass: scope,
    );
  }
  if (call.owner != 'CoreTextStyle') return null;
  if (call.callee != 'token') return null;

  final roleArg = call.positionalArgs.isEmpty
      ? null
      : call.positionalArgs.first;
  final role = roleArg is RefValue ? roleArg.member : null;
  return _textLeaf(
    ctx,
    role: role,
    args: call.namedArgs,
    currentClass: scope,
  );
}

/// The role a value names when it reads off the baseline type scale —
/// `CoreTypography.coui.bodySmall`, or that same chain with `.copyWith(...)`.
/// `null` for anything else.
///
/// Matched on the accessor path rather than on a list of role names: the role
/// set changes when the scale changes, and a hardcoded list would silently
/// stop recognising a newly added role.
String? _typographyScaleRole(AstValue value) {
  const scale = 'CoreTypography.coui';
  return switch (value) {
    RefValue(owner: scale, :final member) => member,
    CallValue(callee: 'copyWith', :final positionalArgs)
        when positionalArgs.isNotEmpty =>
      switch (positionalArgs.first) {
        RefValue(owner: scale, :final member) => member,
        _ => null,
      },
    _ => null,
  };
}

/// The shared `{role, …overrides}` leaf both text spellings produce.
Map<String, dynamic>? _textLeaf(
  EmitContext ctx, {
  required String? role,
  required Map<String, AstValue> args,
  required String currentClass,
}) {
  final call = (namedArgs: args);

  Map<String, dynamic>? colorLeaf;
  final colorArg = call.namedArgs['color'];
  if (colorArg != null) {
    colorLeaf = emitColor(ctx, colorArg, currentClass: currentClass);
  }

  return {
    'role': role,
    if (call.namedArgs['fontSize'] case final arg?)
      'fontSize': emitDim(ctx, arg, currentClass: currentClass),
    if (call.namedArgs['fontWeight'] case final arg?)
      'fontWeight': _resolveScalar(
        ctx,
        arg,
        currentClass: currentClass,
      )?.value,
    if (call.namedArgs['letterSpacing'] case final arg?)
      'letterSpacing': _resolveScalar(
        ctx,
        arg,
        currentClass: currentClass,
      )?.value,
    if (call.namedArgs['lineHeight'] case final arg?)
      'lineHeight': _resolveScalar(
        ctx,
        arg,
        currentClass: currentClass,
      )?.value,
    if (call.namedArgs['lineHeightPx'] case final arg?)
      'lineHeightPx': _resolveScalar(
        ctx,
        arg,
        currentClass: currentClass,
      )?.value,
    if (call.namedArgs['fontFamily'] case final arg?)
      'fontFamily': _resolveScalar(
        ctx,
        arg,
        currentClass: currentClass,
      )?.value,
    if (colorLeaf != null) 'color': colorLeaf,
  };
}

// ── Gap ──────────────────────────────────────────────────────────────────

/// Emits a `Gap` leaf — `CoreGapStyle(size: ...)`'s single dimensional
/// value.
Map<String, dynamic>? emitGap(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  final resolved = resolveCallInScope(ctx, value, currentClass: currentClass);
  final call = resolved?.call;
  // Arguments belong to the class that WROTE the call, not the one that
  // named it — `resolveCallInScope`'s doc carries the failure this avoids.
  final scope = resolved?.scope ?? currentClass;
  if (call == null || call.owner != null || call.callee != 'CoreGapStyle') {
    return null;
  }
  final sizeArg = call.namedArgs['size'];
  if (sizeArg == null) return null;
  return {'size': emitDim(ctx, sizeArg, currentClass: scope)};
}

// ── State layer ──────────────────────────────────────────────────────────

/// Emits a state-layer ramp — `CoreStateLayer(hover:, focus:, pressed:)`.
///
/// Plain numbers, not dim leaves. These are 0..1 weights with no token
/// behind them: the canvas carries them as a node's `opacity`, and there is
/// no `--coui-*` variable for "3 %".
///
/// Reached through `resolveCallInScope`, which follows `CoreStateLayer.subtle`
/// across class boundaries to the const it names. That matters here more
/// than elsewhere — every variant states the ramp by NAME, so a resolver
/// that only accepted an inline call would emit nothing at all.
Map<String, dynamic>? emitStateLayer(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  final resolved = resolveCallInScope(ctx, value, currentClass: currentClass);
  final call = resolved?.call;
  // Arguments belong to the class that WROTE the call, not the one that
  // named it — `resolveCallInScope`'s doc carries the failure this avoids.
  final scope = resolved?.scope ?? currentClass;
  if (call == null || call.owner != null || call.callee != 'CoreStateLayer') {
    return null;
  }
  final out = <String, dynamic>{};
  for (final key in const ['hover', 'focus', 'pressed']) {
    final arg = call.namedArgs[key];
    if (arg == null) return null;
    // Resolved, not literal-matched. The weights used to be bare numbers
    // here; they are `CoreOpacity.hover` and friends now, because the same
    // three are published to the canvas as `opacity/hover|focus|pressed`
    // and writing them twice let the two drift. A matcher that only
    // accepted literals turned that consolidation into four fields the
    // exporter silently dropped — the ramps stopped reaching the canvas
    // while every test still passed.
    final scalar = _resolveScalar(ctx, arg, currentClass: scope);
    if (scalar case _Scalar(value: final num n)) {
      out[key] = n.toDouble();
    } else {
      // All three or none. A ramp missing a step is not a weaker ramp —
      // it is a state that draws nothing while its neighbours draw
      // something, which reads as the control ignoring the pointer.
      return null;
    }
  }
  return out;
}

// ── Icon ─────────────────────────────────────────────────────────────────

/// Emits an `Icon` leaf — `CoreIconStyle(size: ..., color: ...)`'s size
/// and colour, each field optional (a caller may set only one).
Map<String, dynamic>? emitIcon(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  final resolved = resolveCallInScope(ctx, value, currentClass: currentClass);
  final call = resolved?.call;
  // Arguments belong to the class that WROTE the call, not the one that
  // named it — `resolveCallInScope`'s doc carries the failure this avoids.
  final scope = resolved?.scope ?? currentClass;
  if (call == null || call.owner != null || call.callee != 'CoreIconStyle') {
    return null;
  }
  final sizeArg = call.namedArgs['size'];
  final colorArg = call.namedArgs['color'];
  return {
    if (sizeArg != null) 'size': emitDim(ctx, sizeArg, currentClass: scope),
    if (colorArg != null)
      'color': emitColor(ctx, colorArg, currentClass: scope),
  };
}

// ── Shadow ───────────────────────────────────────────────────────────────

/// Resolves [value] to the `ListValue` it names, following reference hops
/// the same way [resolveCallInScope] does.
///
/// The hop matters more here than elsewhere: a shadow default is almost
/// never written inline. It is `CoreShadow.md` — a cross-class reference
/// into a namespace that lived outside the resolution registry until that
/// registry was widened, which is why every one of these emitted nothing.
ListValue? _resolveToList(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
  int hopsRemaining = 6,
}) {
  if (hopsRemaining < 0) return null;
  switch (value) {
    case ListValue():
      return value;
    case RefValue(:final owner, :final member):
      final cls = ctx.classRegistry[owner ?? currentClass];
      if (cls == null) return null;
      final target = cls.staticMembers.where((m) => m.name == member);
      if (target.isEmpty) return null;
      return _resolveToList(
        ctx,
        target.first.value,
        currentClass: owner ?? currentClass,
        hopsRemaining: hopsRemaining - 1,
      );
    default:
      return null;
  }
}

/// Emits a `Shadow` leaf — the ordered layer list, each layer the six
/// fields `CoreShadowLayer` declares.
///
/// An empty list is a value, not an absence: `CoreShadow.none` is how a
/// component says "flat", and returning `null` for it would put it back in
/// the untokenized bucket alongside the ones that genuinely failed to
/// resolve. So `[]` emits as `{'layers': []}`.
///
/// The colour is not part of the record — every step in `CoreShadow` is
/// black at the layer's own `opacity`, and the Style field that carries a
/// tint is a separate `shadowColor`. Emitting an invented colour here would
/// give the plugin a second, wrong source for it.
Map<String, dynamic>? emitShadow(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  final list = _resolveToList(ctx, value, currentClass: currentClass);
  if (list == null) return null;
  final layers = <Map<String, dynamic>>[];
  for (final item in list.items) {
    if (item is! RecordValue) return null;
    num? field(String name) => switch (item.namedFields[name]) {
      LiteralValue(:final value) when value is num => value,
      _ => null,
    };
    final x = field('offsetX');
    final y = field('offsetY');
    final blur = field('blurRadius');
    final spread = field('spreadRadius');
    final opacity = field('opacity');
    // A layer missing any geometry field is not a layer this reader
    // understands. Emitting it with zeros would draw a shadow the Dart side
    // does not describe — worse than the flat rendering that is already
    // there, because it looks intentional.
    if (x == null ||
        y == null ||
        blur == null ||
        spread == null ||
        opacity == null) {
      return null;
    }
    layers.add({
      'x': x.toDouble(),
      'y': y.toDouble(),
      'blur': blur.toDouble(),
      'spread': spread.toDouble(),
      'opacity': opacity.toDouble(),
      'inset': switch (item.namedFields['inset']) {
        LiteralValue(value: true) => true,
        _ => false,
      },
    });
  }
  final step = _shadowStepOf(ctx, value, currentClass: currentClass);

  return {'layers': layers, 'step': ?step};
}

/// The `CoreShadow` member [value] names, as the canvas spells the step
/// (`shadow/<step>` — `xl2` / `xl3` are `2xl` / `3xl` there), or `null` when the
/// chain of references does not end in one.
///
/// Read from the reference rather than matched by value: the record above is
/// six numbers per layer and says nothing about which step produced them,
/// but the source does — `CoreShadow.md` is a name, and keeping it is what
/// lets the canvas bind a shadow to the rows a surface style bends per mode
/// instead of drawing numbers that stay put under every style.
String? _shadowStepOf(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
  int hopsRemaining = 6,
}) {
  if (hopsRemaining < 0) return null;
  if (value is! RefValue) return null;
  final owner = value.owner ?? currentClass;
  if (owner == 'CoreShadow') {
    return switch (value.member) {
      'none' => null,
      'xl2' => '2xl',
      'xl3' => '3xl',
      final member => member,
    };
  }
  final cls = ctx.classRegistry[owner];
  if (cls == null) return null;
  final target = cls.staticMembers.where((m) => m.name == value.member);
  if (target.isEmpty) return null;

  return _shadowStepOf(
    ctx,
    target.first.value,
    currentClass: owner,
    hopsRemaining: hopsRemaining - 1,
  );
}

// ── Gradient ─────────────────────────────────────────────────────────────

/// Resolves a `CoreAlignment` reference (`CoreAlignment.topCenter`, or the
/// dot shorthand `.topCenter`) to its `{x, y}` pair by reading the const the
/// name points at, so the table of named anchors lives in `alignment.dart`
/// and nowhere else.
///
/// `null` when the name does not end in a `CoreAlignment(x, y)` call — the
/// caller then drops the whole gradient rather than guess a direction.
Map<String, double>? _emitAlignment(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  // A dot shorthand has no owner, and an owner-less name is looked up in the
  // class that wrote it — which is not `CoreAlignment`. Name the owner here.
  final named = switch (value) {
    RefValue(owner: null, :final member) => RefValue(
      owner: 'CoreAlignment',
      member: member,
    ),
    _ => value,
  };
  final resolved = resolveCallInScope(
    ctx,
    named,
    currentClass: currentClass,
  );
  final call = resolved?.call;
  final scope = resolved?.scope ?? currentClass;
  if (call == null ||
      call.owner != null ||
      call.callee != 'CoreAlignment' ||
      call.positionalArgs.length != 2) {
    return null;
  }
  final x = _resolveScalar(ctx, call.positionalArgs[0], currentClass: scope);
  final y = _resolveScalar(ctx, call.positionalArgs[1], currentClass: scope);
  if (x?.value is! num || y?.value is! num) return null;
  return {
    'x': (x!.value as num).toDouble(),
    'y': (y!.value as num).toDouble(),
  };
}

/// Emits a `Gradient` leaf — `CoreGradient(type:, colors:, stops:, begin:,
/// end:)` as `{type, colors, stops, begin?, end?}`.
///
/// - `type` is the member name (`linear` / `radial`), spelled with or without
///   its owner.
/// - `colors` are `Color` leaves (`emitColor`), in stop order. One unreadable
///   stop makes the whole gradient wrong, not partly wrong — a two-stop fade
///   emitted with one stop is a solid fill — so any failure returns `null`.
/// - `stops` is always explicit. A gradient that states none is evenly
///   distributed (`CoreGradient.stops`), and the even spacing is written out
///   so no consumer has to know that rule.
/// - `begin` / `end` are `{x, y}` anchors (`-1..1`), present for a linear
///   gradient only: a radial one runs outward from the centre of its box and
///   has no direction to state.
Map<String, dynamic>? emitGradient(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  final resolved = resolveCallInScope(ctx, value, currentClass: currentClass);
  final call = resolved?.call;
  // Arguments belong to the class that WROTE the call, not the one that
  // named it — `resolveCallInScope`'s doc carries the failure this avoids.
  final scope = resolved?.scope ?? currentClass;
  if (call == null || call.owner != null || call.callee != 'CoreGradient') {
    return null;
  }
  final typeArg = call.namedArgs['type'];
  final type = switch (typeArg) {
    RefValue(:final member) => member,
    _ => null,
  };
  if (type != 'linear' && type != 'radial') return null;

  final colorsArg = call.namedArgs['colors'];
  if (colorsArg is! ListValue || colorsArg.items.isEmpty) return null;
  final colors = <Map<String, dynamic>>[];
  for (final item in colorsArg.items) {
    final c = emitColor(ctx, item, currentClass: scope);
    if (c == null) return null;
    colors.add(c);
  }

  final stopsArg = call.namedArgs['stops'];
  final List<double> stops;
  if (stopsArg == null) {
    final last = colors.length - 1;
    stops = [
      for (var i = 0; i < colors.length; i++)
        if (last == 0) 0.0 else i / last,
    ];
  } else if (stopsArg is ListValue && stopsArg.items.length == colors.length) {
    stops = [];
    for (final item in stopsArg.items) {
      final stop = _resolveScalar(ctx, item, currentClass: scope);
      if (stop?.value is! num) return null;
      stops.add((stop!.value as num).toDouble());
    }
  } else {
    // A stop list that does not pair with the colours is a gradient this
    // reader cannot place — Flutter would throw on it.
    return null;
  }

  final out = <String, dynamic>{
    'type': type,
    'colors': colors,
    'stops': stops,
  };
  if (type == 'linear') {
    // `CoreGradient`'s own defaults, for a call that states neither anchor.
    final begin = call.namedArgs['begin'] == null
        ? const {'x': -1.0, 'y': 0.0}
        : _emitAlignment(
            ctx,
            call.namedArgs['begin']!,
            currentClass: scope,
          );
    final end = call.namedArgs['end'] == null
        ? const {'x': 1.0, 'y': 0.0}
        : _emitAlignment(ctx, call.namedArgs['end']!, currentClass: scope);
    if (begin == null || end == null) return null;
    out['begin'] = begin;
    out['end'] = end;
  }
  return out;
}

// ── Vector glyph ─────────────────────────────────────────────────────────

/// Emits a `Glyph` leaf — `CoreVectorGlyph(path:, width:, height:, fillRule:)`
/// as `{path, width, height, fillRule}`.
///
/// - `path` is the outline string as written: absolute `M` / `L` / `C` / `Z`
///   commands, which an SVG `<path d>` and Figma's `vectorPaths` both take
///   unchanged.
/// - `width` / `height` are the coordinate box the path is drawn in, so a
///   consumer scales the path to whatever rectangle it places the glyph in.
/// - `fillRule` is the member name (`evenOdd` / `nonZero`), not a Figma word
///   for it — the winding-rule vocabulary belongs to the plugin.
///
/// Any part this reader cannot read makes the whole glyph `null`: a path with
/// a guessed box or a guessed fill rule draws a different shape.
Map<String, dynamic>? emitGlyph(
  EmitContext ctx,
  AstValue value, {
  required String currentClass,
}) {
  final resolved = resolveCallInScope(ctx, value, currentClass: currentClass);
  final call = resolved?.call;
  // Arguments belong to the class that WROTE the call, not the one that
  // named it — `resolveCallInScope`'s doc carries the failure this avoids.
  final scope = resolved?.scope ?? currentClass;
  if (call == null || call.owner != null || call.callee != 'CoreVectorGlyph') {
    return null;
  }
  final path = switch (call.namedArgs['path']) {
    LiteralValue(value: final String text) when text.isNotEmpty => text,
    _ => null,
  };
  final fillRule = switch (call.namedArgs['fillRule']) {
    RefValue(:final member) when member == 'evenOdd' || member == 'nonZero' =>
      member,
    _ => null,
  };
  final width = _resolveScalar(
    ctx,
    call.namedArgs['width'] ?? const LiteralValue(null),
    currentClass: scope,
  );
  final height = _resolveScalar(
    ctx,
    call.namedArgs['height'] ?? const LiteralValue(null),
    currentClass: scope,
  );
  if (path == null ||
      fillRule == null ||
      width?.value is! num ||
      height?.value is! num) {
    return null;
  }
  return {
    'path': path,
    'width': (width!.value as num).toDouble(),
    'height': (height!.value as num).toDouble(),
    'fillRule': fillRule,
  };
}
