/// A structured, uninterpreted representation of what a Dart initializer
/// expression means, captured directly from the *unresolved* AST
/// (`parseString` — no analyzer element model, no `dart pub get`-time type
/// resolution). `readValue` only needs to know the *syntax shape* of an
/// expression, never what it resolves to — element-model resolution would
/// require a full analysis context per file, at a cost this reader's own
/// benchmark (145 files, 0 failures, 2.55s) exists specifically to avoid.
///
/// This is the "raw" layer — [readValue] classifies syntax shapes only. It
/// never decides what a reference *means* (is `CoreSpace.space16` a token or
/// a cross-class default?) — that resolution happens one layer up, against
/// the global class/namespace registry built by walking every file first
/// (`core/style-contract.md`'s convention #3: "2차 해소는 전역").
// ignore_for_file: depend_on_referenced_packages
// `analyzer` is a direct `dev_dependency` of this package (see
// `pubspec.yaml`) — the lint's package-graph check doesn't distinguish
// `bin/`-only dev tooling from `lib/`-published code here, so it still
// flags this import. Verified working (`dart run` resolves and executes
// this file without error) — see the reader's own doc comment in
// `pubspec.yaml` for why `dev_dependencies` is the correct section.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:meta/meta.dart';

/// Base type for every recognized expression shape.
sealed class AstValue {
  const AstValue();
}

/// A literal: `1.0`, `16`, `true`, `'text'`, `null`.
@immutable
final class LiteralValue extends AstValue {
  const LiteralValue(this.value);

  /// `double`, `int`, `bool`, `String`, or `null`.
  final Object? value;

  @override
  bool operator ==(Object other) =>
      other is LiteralValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Literal($value)';
}

/// A named reference with no call parens: `CoreColors.primary`,
/// `CoreSpace.space16`, `.small` (dot-shorthand), or a bare identifier like
/// `defaultBorderRadius` (same-class static reference).
///
/// [owner] is the prefix before the final `.` — `null` for dot-shorthand
/// (`.small`) and bare identifiers (`defaultX`). Whether `owner` names a
/// token namespace (`CoreColors`), another Style class
/// (`CoreFocusOutlineStyle`), or is absent entirely is a *resolution*
/// question, not something this raw layer decides.
@immutable
final class RefValue extends AstValue {
  const RefValue({required this.member, this.owner});

  final String? owner;
  final String member;

  @override
  bool operator ==(Object other) =>
      other is RefValue && other.owner == owner && other.member == member;

  @override
  int get hashCode => Object.hash(owner, member);

  @override
  String toString() => owner == null ? '.$member' : '$owner.$member';
}

/// A call expression: `CoreColor.token(...)`, `CoreEdgeInsets.all(...)`,
/// `Duration(milliseconds: ...)`, or a bare constructor call
/// `CoreButtonVariantStyle(...)`.
///
/// At the unresolved-AST stage a constructor call with no explicit
/// `const`/`new` and a plain function call are syntactically identical
/// (`MethodInvocation`) — this reader does not need to tell them apart,
/// it only needs the callee name and arguments.
final class CallValue extends AstValue {
  const CallValue({
    required this.callee,
    required this.positionalArgs,
    required this.namedArgs,
    this.owner,
    this.receiver,
  });

  /// Prefix before the call, e.g. `CoreColor` in `CoreColor.token(...)`.
  /// `null` for a bare call: `CoreButtonVariantStyle(...)`.
  final String? owner;

  /// The value the method was called ON, when that value is itself an
  /// expression rather than a bare name — `A[size]!` in
  /// `A[size]!.merge(B[size])`.
  ///
  /// [owner] cannot carry it: that is a plain prefix string, so a call on
  /// anything but an identifier had no representation and fell through to
  /// [RawValue]. Additive, so every existing pattern that matches on
  /// `owner`/`callee` keeps working.
  final AstValue? receiver;
  final String callee;
  final List<AstValue> positionalArgs;
  final Map<String, AstValue> namedArgs;

  @override
  String toString() {
    final target = owner == null ? callee : '$owner.$callee';
    final args = [
      ...positionalArgs.map((a) => a.toString()),
      ...namedArgs.entries.map((e) => '${e.key}: ${e.value}'),
    ].join(', ');
    return '$target($args)';
  }
}

/// A map literal: `{ key: value, ... }`. Recorded as ordered entries — the
/// reader never assumes key uniqueness or relies on `Map` semantics itself,
/// so source order (used by schema v2's determinism requirement) survives.
final class MapEntryValue {
  const MapEntryValue(this.key, this.value);
  final AstValue key;
  final AstValue value;
}

final class MapValue extends AstValue {
  const MapValue(this.entries);
  final List<MapEntryValue> entries;

  @override
  String toString() =>
      '{${entries.map((e) => '${e.key}: ${e.value}').join(', ')}}';
}

/// A list literal: `[a, b, c]`.
final class ListValue extends AstValue {
  const ListValue(this.items);
  final List<AstValue> items;

  @override
  String toString() => '[${items.join(', ')}]';
}

/// A record literal: `(offsetX: 0, offsetY: 4, inset: false)`.
///
/// `CoreShadowLayer` is a `typedef` for a named-field record, not a class, so
/// every shadow step in `CoreShadow` is a list of these. Without a case for
/// them the analyzer's `RecordLiteral` fell to [RawValue] — the layers arrived
/// as source text, no emitter could read them, and eleven components
/// (card, popup, dialog, drawer, toast, fab, …) declared a shadow that never
/// left Dart. They render flat on the canvas, and nothing reports it: a
/// shadow that was never emitted and a component the designer chose not to
/// shadow look the same.
///
/// Positional fields are kept as well as named ones. This codebase's records
/// are all-named, but dropping the positional half would make the node lie
/// about what a record is, and the next record type to arrive would lose its
/// values the same silent way.
final class RecordValue extends AstValue {
  const RecordValue({
    required this.positionalFields,
    required this.namedFields,
  });
  final List<AstValue> positionalFields;
  final Map<String, AstValue> namedFields;

  @override
  String toString() =>
      '(${[
        ...positionalFields.map((f) => '$f'),
        ...namedFields.entries.map((e) => '${e.key}: ${e.value}'),
      ].join(', ')})';
}

/// A binary arithmetic expression on two token references: `a + b`.
///
/// One default in this codebase is written this way — a focus ring's total
/// outer extension is stated as `ringOffset + ringWidth` rather than as the
/// number 4, which is the better source: it survives either token changing.
/// Kept as a shape instead of folded here because this is the raw syntax
/// layer, and folding needs the registry that resolution owns.
final class BinaryValue extends AstValue {
  const BinaryValue(this.op, this.left, this.right);
  final String op;
  final AstValue left;
  final AstValue right;

  @override
  String toString() => '($left $op $right)';
}

/// A conditional expression: `cond ? a : b`. CoUI Style defaults don't use
/// these in practice, but keeping the shape rather than falling back to
/// [RawValue] means a reader consumer sees the real branches, not opaque
/// source text, if one ever shows up.
final class ConditionalValue extends AstValue {
  const ConditionalValue(this.condition, this.thenValue, this.elseValue);
  final String condition; // kept as source text — a boolean-typed AstValue
  // shape isn't needed anywhere else in this reader, and re-modelling
  // arbitrary boolean expressions would be scope the census doesn't need.
  final AstValue thenValue;
  final AstValue elseValue;

  @override
  String toString() => '($condition ? $thenValue : $elseValue)';
}

/// Anything not specifically modelled above (unary/binary arithmetic on
/// tokens, cascades, etc.) — kept as the *real* compacted source text, never
/// a guess. Mirrors `tool/generate_style_tables.dart#formatStyleValue`'s
/// "always either the token name or the real source text" contract, so a
/// consumer can at least display or grep the fallback instead of losing the
/// value silently.
/// `someMap[key]` — an index read, kept unevaluated because resolving it needs
/// the class registry (the map may be another member of the same class) and
/// this file deliberately knows nothing about classes.
final class IndexValue extends AstValue {
  const IndexValue(this.target, this.index);

  /// The thing being indexed — a [RefValue] for a member of the same class.
  final AstValue target;
  final AstValue index;

  @override
  String toString() => '$target[$index]';
}

/// `{for (final x in Something.values) x: <body>}` — a map built by a
/// comprehension rather than spelled out entry by entry.
///
/// Kept as its own shape for the same reason as [IndexValue]: expanding it
/// needs the other members of the class. `description_card`'s `defaultsBySize`
/// is one, stitching two private per-size tables through `merge`, and until
/// this existed it fell through to [RawValue] — so six sizes of padding and
/// typography never left Dart, the builder hardcoded them, and the
/// field-coverage ledger could not tell that from a decision to have no value.
final class ComprehensionValue extends AstValue {
  const ComprehensionValue({
    required this.loopVariable,
    required this.key,
    required this.body,
  });

  /// The loop variable's name — `size` in the example above. The expansion
  /// substitutes each key for it.
  final String loopVariable;

  /// The entry key expression. Handled only when it IS the loop variable; any
  /// other shape stays unexpanded rather than guessed at.
  final AstValue key;
  final AstValue body;

  @override
  String toString() => '{for (…) $key: $body}';
}

final class RawValue extends AstValue {
  const RawValue(this.source);
  final String source;

  @override
  String toString() => source;
}

/// Portable named-argument reader — isolates the sole analyzer-version AST
/// churn point this reader depends on (`NamedExpression` in analyzer <13,
/// `NamedArgument` in analyzer >=13 — see
/// `scripts/guards/structure/check_analyzer_ast_churn.sh`) behind dynamic
/// member access instead of an `is NamedExpression` type check.
/// The older node exposes `.name.label.name` and `.expression`; newer
/// analyzer versions use a token name and `argumentExpression` or
/// `fieldExpression` for a named argument or record field respectively.
({String name, Expression value})? namedArg(Object node) {
  // Version-portability adapter (see doc comment above).
  final dyn = node as dynamic;
  try {
    // Same version-portability adapter as `dyn` above.
    // ignore: avoid_dynamic_calls
    final label = dyn.name.label.name as String;
    // Same version-portability adapter as `dyn` above.
    // ignore: avoid_dynamic_calls
    final expr = dyn.expression as Expression;
    return (name: label, value: expr);
    // Newer analyzer versions expose these members with different names.
    // ignore: avoid_catching_errors
  } on NoSuchMethodError {
    try {
      // Newer analyzer versions expose the name as a token.
      // ignore: avoid_dynamic_calls
      final label = dyn.name.lexeme as String;
      try {
        // Newer named call arguments use this getter.
        // ignore: avoid_dynamic_calls
        return (name: label, value: dyn.argumentExpression as Expression);
        // A named record field uses the other getter below.
        // ignore: avoid_catching_errors
      } on NoSuchMethodError {
        // Newer named record fields use this getter.
        // ignore: avoid_dynamic_calls
        return (name: label, value: dyn.fieldExpression as Expression);
      }
      // An ordinary positional expression does not expose these getters.
      // ignore: avoid_catching_errors
    } on NoSuchMethodError {
      return null;
    }
  }
}

/// Converts a raw argument-list expression (from either
/// `ArgumentList.arguments` in analyzer <13 or the `Argument`-typed list in
/// >=13 — both iterate fine as `Object` since this file never references
/// either wrapper type name directly) to a [CallValue] positional or named
/// slot. Used by [readValue] when descending into a `MethodInvocation`.
class ParsedArguments {
  const ParsedArguments(this.positional, this.named);
  final List<AstValue> positional;
  final Map<String, AstValue> named;
}

// Positional nodes are Expressions in all supported analyzer versions,
// although newer argument and record lists expose a wider static type.
Expression _positionalExpression(Object node) => node as Expression;

ParsedArguments readArguments(Iterable<Object> rawArgs) {
  final positional = <AstValue>[];
  final named = <String, AstValue>{};
  for (final raw in rawArgs) {
    final na = namedArg(raw);
    if (na != null) {
      named[na.name] = readValue(na.value);
    } else {
      positional.add(readValue(_positionalExpression(raw)));
    }
  }
  return ParsedArguments(positional, named);
}

/// Classifies a single initializer expression into an [AstValue]. This is
/// the reader's only "does the shape look like X" logic — everything past
/// this point works on the structured [AstValue] tree, never back on the
/// analyzer AST.
AstValue readValue(Expression expr) {
  if (expr is PrefixExpression && expr.operator.lexeme == '-') {
    if (readValue(expr.operand) case LiteralValue(value: final num n)) {
      return LiteralValue(-n);
    }
  }
  return switch (expr) {
    IntegerLiteral(:final value) => LiteralValue(value),
    DoubleLiteral(:final value) => LiteralValue(value),
    BooleanLiteral(:final value) => LiteralValue(value),
    NullLiteral() => const LiteralValue(null),
    SimpleStringLiteral(:final value) => LiteralValue(value),
    // `'abc' 'def'` — one string written across lines, which is how a long
    // vector outline stays inside the line width. Read as its concatenation;
    // an interpolation inside has no value to read, so it is not one.
    AdjacentStrings(:final stringValue?) => LiteralValue(stringValue),
    DotShorthandPropertyAccess(:final propertyName) => RefValue(
      member: propertyName.name,
    ),
    DotShorthandInvocation(:final memberName, :final argumentList) =>
      _readShorthandCall(memberName.name, argumentList),
    SimpleIdentifier(:final name) => RefValue(member: name),
    PrefixedIdentifier(:final prefix, :final identifier) => RefValue(
      owner: prefix.name,
      member: identifier.name,
    ),
    PropertyAccess(
      target: SimpleIdentifier(:final name),
      :final propertyName,
    ) =>
      RefValue(owner: name, member: propertyName.name),
    // `const CoreTextStyle.token(...)` — the `const` keyword is what makes
    // the parser produce an `InstanceCreationExpression` here instead of a
    // `MethodInvocation`. Without the keyword (`static const X =
    // CoreTextStyle.token(...)`, where the const-ness comes from the field)
    // the *unresolved* parser can't tell a constructor from a static method
    // and emits `MethodInvocation`, which the two cases below already read.
    // So the same Dart value reached this reader through two different node
    // types depending on whether `const` was written — and only one of them
    // was handled, which is why every `static final … = const X(...)…`
    // default was invisible.
    //
    // `constructorName.toSource()` rather than `type.name2` / `type.name`:
    // that property was renamed across analyzer majors, and this file's whole
    // job is to not name version-specific AST members (see `namedArg` below).
    // `toSource()` is stable and gives `CoreTextStyle.token` / `CoreTextStyle`.
    InstanceCreationExpression(:final constructorName, :final argumentList) =>
      _readConstructorCall(constructorName.toSource(), argumentList),
    // `<readable const value>.copyWith(...)` / `.merge(...)` — fold the
    // overlay into the receiver's named args so downstream emitters see one
    // flat call. `core/style-contract.md` blesses this exact shape for a
    // token-backed default carrying a weight overlay, so the value is
    // correct Dart; it was the reader that could not follow it.
    //
    // Deliberately narrow: the receiver must itself read to a `CallValue`
    // (a const constructor call or a static-method-shaped call). Anything
    // else — a variable, a function result, a conditional — falls through to
    // `RawValue` as before. This is not a const evaluator; it is the one
    // syntactic fold the design system's own default convention needs.
    MethodInvocation(:final target?, :final methodName, :final argumentList)
        when methodName.name == 'copyWith' || methodName.name == 'merge' =>
      _readOverlayCall(expr, target, methodName.name, argumentList),
    MethodInvocation(
      target: null,
      :final methodName,
      :final argumentList,
    ) =>
      _readCall(null, methodName.name, argumentList),
    MethodInvocation(
      target: SimpleIdentifier(:final name),
      :final methodName,
      :final argumentList,
    ) =>
      _readCall(name, methodName.name, argumentList),
    IndexExpression(:final target, :final index) when target != null =>
      IndexValue(readValue(target), readValue(index)),
    // `x!` — the assertion says nothing about the value, only that the author
    // knows it is not null. Reading through it keeps `A[size]!` readable.
    PostfixExpression(:final operand, :final operator)
        when operator.lexeme == '!' =>
      readValue(operand),
    // A method called on an expression rather than a bare name. Placed after
    // the identifier-target case above so `CoreColor.token(...)` keeps its
    // `owner` shape.
    MethodInvocation(:final target, :final methodName, :final argumentList)
        when target != null && target is! SimpleIdentifier =>
      CallValue(
        callee: methodName.name,
        positionalArgs: [
          for (final a in argumentList.arguments)
            if (namedArg(a) == null) readValue(_positionalExpression(a)),
        ],
        namedArgs: {
          for (final a in argumentList.arguments)
            if (namedArg(a) case (name: final n, value: final v))
              n: readValue(v),
        },
        receiver: readValue(target),
      ),
    // A single-element map comprehension over `X.values`. Only this exact shape
    // — one `for`, key IS the loop variable — because that is the shape this
    // repo writes and anything looser would be guessing at what the map's keys
    // are. The expansion happens in `schema_v2.dart`, which has the class
    // registry the body needs.
    SetOrMapLiteral(elements: [ForElement(:final forLoopParts, :final body)])
        when body is MapLiteralEntry &&
            forLoopParts is ForEachPartsWithDeclaration =>
      ComprehensionValue(
        loopVariable: forLoopParts.loopVariable.name.lexeme,
        key: readValue(body.key),
        body: readValue(body.value),
      ),
    SetOrMapLiteral(:final elements)
        when elements.every(
          (e) => e is MapLiteralEntry,
        ) =>
      MapValue([
        for (final e in elements.cast<MapLiteralEntry>())
          MapEntryValue(readValue(e.key), readValue(e.value)),
      ]),
    ListLiteral(:final elements) => ListValue([
      for (final e in elements)
        if (e is Expression) readValue(e),
    ]),
    // A record's fields split positional from named through [namedArg], not
    // through an `is NamedExpression` test: that type is the one analyzer name
    // this reader is not allowed to spell (it becomes `NamedArgument` in
    // analyzer >= 13), and `namedArg` is the single adapter that hides the
    // difference. Reading a shadow step is what brought records in, and it
    // introduced the type check the churn guard exists to prevent.
    RecordLiteral(:final fields) => RecordValue(
      positionalFields: [
        for (final f in fields)
          if (namedArg(f) == null) readValue(_positionalExpression(f)),
      ],
      namedFields: {
        for (final f in fields)
          if (namedArg(f) case (name: final n, value: final v)) n: readValue(v),
      },
    ),
    ConditionalExpression(
      :final condition,
      :final thenExpression,
      :final elseExpression,
    ) =>
      ConditionalValue(
        condition.toSource(),
        readValue(thenExpression),
        readValue(elseExpression),
      ),
    // `CoreTypography.coui.bodySmall` — a property access whose target is
    // itself dotted. The `SimpleIdentifier`-target cases above cannot see it,
    // so six typography defaults arrived as source text and emitted nothing.
    // The owner is kept as the full dotted path: `CoreTypography.coui` is not
    // a class name, and pretending it were one would make the registry
    // lookup succeed against the wrong thing rather than fail visibly.
    PropertyAccess(:final target, :final propertyName) when target != null =>
      RefValue(owner: _compact(target.toSource()), member: propertyName.name),
    // `<dotted path>.copyWith(...)` — the same chain with an override on top.
    MethodInvocation(:final target, :final methodName, :final argumentList)
        when target != null =>
      _readChainedCall(target, methodName.name, argumentList),
    BinaryExpression(
      :final leftOperand,
      :final operator,
      :final rightOperand,
    ) =>
      BinaryValue(
        operator.lexeme,
        readValue(leftOperand),
        readValue(rightOperand),
      ),
    ParenthesizedExpression(:final expression) => readValue(expression),
    _ => RawValue(_compact(expr.toSource())),
  };
}

/// A call whose target is an arbitrary expression rather than a bare
/// identifier — `CoreTypography.coui.bodyMedium.copyWith(...)`.
///
/// The target's own shape is preserved as the call's first positional
/// argument, so a consumer can resolve the base and the override separately
/// instead of choosing between them.
CallValue _readChainedCall(
  Expression target,
  String callee,
  ArgumentList argumentList,
) {
  final parsed = readArguments(argumentList.arguments);
  return CallValue(
    callee: callee,
    positionalArgs: [readValue(target), ...parsed.positional],
    namedArgs: parsed.named,
  );
}

CallValue _readCall(String? owner, String callee, ArgumentList argumentList) {
  final parsed = readArguments(argumentList.arguments);
  return CallValue(
    owner: owner,
    callee: callee,
    positionalArgs: parsed.positional,
    namedArgs: parsed.named,
  );
}

/// Splits a constructor name (`CoreTextStyle.token` or `CoreTextStyle`) into
/// the same `(owner, callee)` pair [_readCall] produces for the
/// `MethodInvocation` spelling of the same value, so a `const`-written and a
/// keyword-less default are indistinguishable downstream.
CallValue _readConstructorCall(String name, ArgumentList argumentList) {
  final dot = name.indexOf('.');
  return _readCall(
    dot < 0 ? null : name.substring(0, dot),
    dot < 0 ? name : name.substring(dot + 1),
    argumentList,
  );
}

/// Folds `receiver.copyWith(a: 1)` / `receiver.merge(Other(b: 2))` into the
/// receiver's [CallValue] by overlaying named args.
///
/// Both methods mean the same thing to this reader — "the receiver, with these
/// fields replaced" — because a `merge` argument only spells out the fields it
/// sets, exactly like `copyWith`'s named args. The difference is only where
/// the overlay is written: `copyWith`'s own named args vs the single
/// positional argument's named args.
///
/// Returns [RawValue] (previous behaviour) when the receiver or the merge
/// argument isn't readable — a partially-folded value would be worse than an
/// unread one, because it would emit a leaf that silently lost the overlay.
AstValue _readOverlayCall(
  Expression whole,
  Expression target,
  String method,
  ArgumentList argumentList,
) {
  final base = readValue(target);
  final parsed = readArguments(argumentList.arguments);

  // A reference receiver: `CoreTypography.coui.bodyMedium.copyWith(...)`.
  // There is no call to fold the overlay into, so the reference is kept as
  // the first positional argument and the overlay as named args — the same
  // shape `_readChainedCall` produces, which is what lets one emitter read
  // both spellings of a role-plus-override default.
  if (base is RefValue && method == 'copyWith') {
    return CallValue(
      callee: 'copyWith',
      positionalArgs: [base],
      namedArgs: parsed.named,
    );
  }
  // A named-const receiver: `chromelessFieldStyle.merge(const X(...))`. The
  // name is a static member of some class, and only the class registry can
  // say what it holds — so the call is kept whole with the receiver attached,
  // and `terminalValue` (emit.dart) folds it once the receiver resolves.
  //
  // Before this the shape fell to `RawValue`, the nested-style overlay found
  // no call, and `PhoneInput`'s number field exported `TextField`'s own
  // chrome (outline border, radius, padding) where Core states a chromeless
  // field — the canvas drew a field inside the field.
  if (base is RefValue && method == 'merge') {
    return CallValue(
      callee: method,
      positionalArgs: parsed.positional,
      namedArgs: parsed.named,
      receiver: base,
    );
  }
  // An indexed receiver: `_table[size]!.merge(_other[size])`. Nothing to fold
  // here — the receiver names a map entry this layer cannot look up (that
  // needs the class registry) — so the call is kept whole, with the receiver
  // attached, and `schema_v2.dart` resolves it. Before this, the `merge`
  // interception above reached the `RawValue` below and `description_card`'s
  // whole per-size table arrived as source text.
  if (base is IndexValue) {
    return CallValue(
      callee: method,
      positionalArgs: parsed.positional,
      namedArgs: parsed.named,
      receiver: base,
    );
  }
  if (base is! CallValue) return RawValue(_compact(whole.toSource()));

  final Map<String, AstValue> overlay;
  if (method == 'copyWith') {
    overlay = parsed.named;
  } else {
    final other = parsed.positional.isEmpty ? null : parsed.positional.first;
    if (other is! CallValue) return RawValue(_compact(whole.toSource()));
    overlay = other.namedArgs;
  }

  return CallValue(
    owner: base.owner,
    callee: base.callee,
    positionalArgs: base.positionalArgs,
    namedArgs: {...base.namedArgs, ...overlay},
  );
}

/// Dot-shorthand invocation (`.token(...)` style — not currently used by
/// any `CoreXxxStyle` default in this codebase, but the grammar allows it
/// alongside `DotShorthandPropertyAccess`, so it's modelled the same way
/// rather than silently falling to [RawValue].
CallValue _readShorthandCall(String callee, ArgumentList argumentList) {
  final parsed = readArguments(argumentList.arguments);
  return CallValue(
    callee: callee,
    positionalArgs: parsed.positional,
    namedArgs: parsed.named,
  );
}

String _compact(String source) => source.replaceAll(RegExp(r'\s+'), ' ').trim();
