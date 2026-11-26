/// Per-file class discovery — walks one parsed compilation unit and
/// extracts every `class` declaration's shape (fields, static members),
/// following `core/style-contract.md`'s seven reader conventions:
///
///  1. Field collection is by *type*, not name — [DiscoveredClass] doesn't
///     filter static members by name pattern; classification into scalar
///     default / dispatch table happens on declared type in
///     `census.dart`, one layer up.
///  2. Both `static const` and `static final` are collected (needed for
///     e.g. `description_card`'s `static final` typography defaults, which
///     can't be `const` because `CoreTypography.coui.X` is an instance-
///     field read on a `static const` singleton).
///  3. Cross-class reference resolution ("who does `Core...Style.defaultX`
///     mean") is explicitly *not* this file's job — see `repo_reader.dart`.
///  4. Component identity comes from the *class name*
///     (`CoreXxxStyle` → `xxx`), never the file name — `repo_reader.dart`
///     globs every `.dart` file under `contracts/`, not just `*_style.dart`.
///  5. Dispatch-table detection is type-based (`Map<K, V>`), not limited to
///     the seven conventionally-named members (`defaultsByVariant` etc.) —
///     an off-convention name still gets discovered and classified as a
///     dispatch table by `census.dart`.
///  6. A file can declare more than one class implementing `CoreStyle<T>`
///     (`chat_style.dart`, `progress_style.dart`) — [readCompilationUnit]
///     returns every one, keyed by class name, not "the first."
///  7. Cyclic / repeated nested-Style references are the caller's problem
///     (a visited-set walk) — this file only records what a class's
///     members *say*, it doesn't resolve or dereference them.
// ignore_for_file: depend_on_referenced_packages
// `analyzer` is a direct `dev_dependency` of this package (see
// `pubspec.yaml`) — see `ast_value.dart`'s matching ignore for why the
// lint still flags `bin/`-only dev tooling imports.
library;

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'ast_value.dart';
import 'parse_source.dart';

/// One `final` (instance) field of a discovered class:
/// `final CoreColor? backgroundColor;`.
final class InstanceField {
  const InstanceField({
    required this.name,
    required this.typeSource,
    this.isHostDerived = false,
  });

  final String name;

  /// `true` when the declaration carries `@hostDerived` — the value is
  /// injected by the host at render time, so "no default" is not an absence
  /// the design decided. See `HostDerived` in coui_core.
  final bool isHostDerived;

  /// Raw declared-type source text (`'CoreColor?'`, `'double'`, …) — kept
  /// as text rather than resolved, matching this reader's unresolved-AST
  /// design (see `style_reader.dart`'s library doc comment).
  final String typeSource;
}

/// One `static const`/`static final` member of a discovered class — a
/// single-value default (`static const double defaultBorderWidth = ...;`)
/// or a dispatch table keyed by variant/size/etc.
/// (`static const Map<Variant, VariantStyle> defaultsByVariant = {...};`).
final class StaticMember {
  const StaticMember({
    required this.name,
    required this.typeSource,
    required this.isConst,
    required this.value,
    required this.isPrivate,
    this.isDeprecated = false,
  });

  final String name;
  final String typeSource;

  /// `true` when the declaration carries `@Deprecated(...)`.
  ///
  /// Every one of them in this repo says "No longer applied", and the value
  /// was being exported anyway — so the Figma builder could paint chrome that
  /// neither platform renders. That is worse than a missing value: a missing
  /// one leaves the builder with nothing to go on, this one hands it something
  /// wrong and looks authoritative.
  final bool isDeprecated;

  /// `true` for `static const`, `false` for `static final` (convention #2
  /// — both are collected, this only records which keyword was used).
  final bool isConst;
  final AstValue value;

  /// `_leadingUnderscore` — private members are still collected (an AST
  /// reader can see them; only name-based tooling can't), but flagged so
  /// census / coverage tooling can report them distinctly (matches
  /// `core/style-contract.md`'s discussion of `description_card`'s
  /// private per-size dispatch holders).
  final bool isPrivate;
}

/// A static `defaultX` method, with a source field only for a verified
/// one-argument identity expression (`=> argument`). Other bodies are not
/// interpreted; the exporter must report them as unresolved.
final class DerivedDefaultMethod {
  const DerivedDefaultMethod({
    required this.name,
    this.sourceField,
    this.parameterType,
    this.returnType,
  });
  final String name;
  final String? sourceField;
  final String? parameterType;
  final String? returnType;
}

/// One `class` declaration discovered in a file.
final class DiscoveredClass {
  const DiscoveredClass({
    required this.name,
    required this.filePath,
    required this.implementsCoreStyle,
    required this.instanceFields,
    required this.staticMembers,
    this.getters = const [],
    this.derivedDefaults = const [],
    this.isDeprecated = false,
  });

  final String name;
  final String filePath;

  /// Whether the class's `implements` clause names `CoreStyle` (the MAIN
  /// Style marker — `core/style-contract.md`'s "Style 클래스 3 종" MAIN
  /// category). Auxiliary classes (`CoreXxxVariantStyle` and similar) are
  /// still fully discovered — this flag only records the distinction, it
  /// doesn't filter.
  final bool implementsCoreStyle;

  /// `true` when the class declaration itself carries `@Deprecated(...)`.
  ///
  /// A retired component is still discovered — the deprecation window
  /// (`process/deprecation.md`) keeps the class compiling for two minors —
  /// but it is not a surface the design system draws any more: its
  /// replacement is. Exporting it would hand the plugin a component whose
  /// builder has been retired, and every one of its fields would then
  /// report as "sent but never read". Same reasoning as [StaticMember
  /// .isDeprecated], one level up.
  final bool isDeprecated;
  final List<InstanceField> instanceFields;
  final List<StaticMember> staticMembers;
  final List<DerivedDefaultMethod> derivedDefaults;

  /// Bodyless getters declared by this class. Empty for every `CoreXxxStyle`
  /// (Style classes declare fields, not getters) and populated for
  /// `CoreXxxContract`, whose whole API is abstract getters — that's where the
  /// composition slots (`child` / `leading` / `title` / …) live.
  final List<DiscoveredGetter> getters;
}

/// One bodyless getter declaration — `W? get leading;`.
///
/// Separate from [InstanceField] because the two answer different questions:
/// an instance field on a Style class is a *chrome override slot* (it carries
/// a value the resolver merges), while a contract getter is *API surface*
/// (it declares what the widget accepts). Merging them into one list would
/// make "which slots does this component have" unanswerable without
/// re-deriving the distinction from the class name.
final class DiscoveredGetter {
  const DiscoveredGetter({required this.name, required this.typeSource});

  final String name;

  /// Raw declared-type source text (`'W?'`, `'CoreIconStyle?'`, …) — kept as
  /// text, same unresolved-AST reasoning as [InstanceField.typeSource].
  final String typeSource;
}

/// Parses [source] (the full text of one `.dart` file) and returns every
/// `class` declaration found — `enum` declarations (the four `*_style.dart`
/// files that are actually enums: chip's selected/unselected, frame's
/// border, outlined_container's border) are walked past without producing
/// a [DiscoveredClass], matching convention: a class-shaped reader doesn't
/// guess at enum-shaped exceptions, it just doesn't match them.
///
/// Returns `null` (rather than throwing) when the file fails to parse —
/// the caller counts failures; a reader that throws on the first bad file
/// can't report "145 files, 0 failures" the way an accumulating one can.
List<DiscoveredClass>? readCompilationUnit(String filePath, String source) {
  final ParseStringResult result;
  try {
    result = parseSource(content: source, path: filePath);
  } on Object {
    return null;
  }
  if (result.errors.isNotEmpty) return null;

  final classes = <DiscoveredClass>[];
  for (final decl in result.unit.declarations) {
    if (decl is! ClassDeclaration) continue;
    classes.add(_readClass(decl, filePath));
  }
  return classes;
}

DiscoveredClass _readClass(ClassDeclaration decl, String filePath) {
  final name = _classNameOf(decl);
  final implementsCoreStyle =
      decl.implementsClause?.interfaces.any(
        (t) => t.name.lexeme == 'CoreStyle',
      ) ??
      false;

  final instanceFields = <InstanceField>[];
  final staticMembers = <StaticMember>[];
  final getters = <DiscoveredGetter>[];
  final derivedDefaults = <DerivedDefaultMethod>[];

  for (final member in decl.body.members) {
    // Abstract getters — the shape a `CoreXxxContract` declares its API in
    // (`W get child;` / `W? get leading;`). `FieldDeclaration` never matches
    // these, so before this every contract was parsed and registered and
    // then contributed nothing: the composition-slot list the Figma plugin
    // needs for component properties was sitting in the registry unread.
    //
    // Only bodyless getters are recorded. A getter with a body is derived
    // state (`bool get isEmpty => ...`), not a declared slot, and including
    // it would put computed members in the same list as API surface.
    if (member is MethodDeclaration &&
        member.isGetter &&
        member.body is EmptyFunctionBody) {
      getters.add(
        DiscoveredGetter(
          name: member.name.lexeme,
          typeSource: member.returnType?.toSource() ?? 'dynamic',
        ),
      );
      continue;
    }
    if (member is MethodDeclaration &&
        member.isStatic &&
        member.name.lexeme.startsWith('default')) {
      final params = member.parameters?.parameters;
      final body = member.body;
      final parameter = params != null && params.length == 1
          ? _identityParameter(params.single)
          : null;
      String? source;
      if (parameter != null &&
          body is ExpressionFunctionBody &&
          body.expression is SimpleIdentifier) {
        if ((body.expression as SimpleIdentifier).name == parameter.name) {
          source = parameter.name;
        }
      }
      derivedDefaults.add(
        DerivedDefaultMethod(
          name: member.name.lexeme,
          sourceField: source,
          parameterType: parameter?.type,
          returnType: member.returnType?.toSource(),
        ),
      );
      continue;
    }
    if (member is! FieldDeclaration) continue;
    final typeSource = member.fields.type?.toSource() ?? 'dynamic';
    for (final variable in member.fields.variables) {
      final fieldName = variable.name.lexeme;
      if (member.isStatic) {
        final init = variable.initializer;
        // `static` fields always have an initializer in valid Dart — a
        // missing one means an unparseable/incomplete member; skip rather
        // than fabricate a value.
        if (init == null) continue;
        staticMembers.add(
          StaticMember(
            name: fieldName,
            typeSource: typeSource,
            isConst: member.fields.isConst,
            value: readValue(init),
            isPrivate: fieldName.startsWith('_'),
            // Read off the source text rather than the annotation's element
            // so this stays clear of the analyzer type names the churn gate
            // forbids naming (see that gate's own doc comment).
            isDeprecated: member.metadata.any(
              (a) => a.toSource().startsWith('@Deprecated'),
            ),
          ),
        );
      } else {
        instanceFields.add(
          InstanceField(
            name: fieldName,
            typeSource: typeSource,
            isHostDerived: member.metadata.any(
              (a) => a.toSource() == '@hostDerived',
            ),
          ),
        );
      }
    }
  }

  return DiscoveredClass(
    name: name,
    filePath: filePath,
    implementsCoreStyle: implementsCoreStyle,
    instanceFields: instanceFields,
    staticMembers: staticMembers,
    getters: getters,
    derivedDefaults: derivedDefaults,
    // Source text, not the annotation's element — same reason as the
    // static-member flag above.
    isDeprecated: decl.metadata.any(
      (a) => a.toSource().startsWith('@Deprecated'),
    ),
  );
}

/// Read a plain required positional parameter without binding to the analyzer
/// 12/13-specific parameter node classes. Function-typed, optional, named,
/// field and super parameters are deliberately not identity-default inputs.
({String name, String? type})? _identityParameter(FormalParameter parameter) {
  final name = parameter.name;
  if (!parameter.isRequiredPositional ||
      name == null ||
      parameter.endToken != name ||
      RegExp(r'\b(?:this|super)\s*\.').hasMatch(parameter.toSource())) {
    return null;
  }
  try {
    // The type getter exists on the plain node in analyzer 12 and on the
    // common parameter interface in analyzer 13+. Avoid either renamed type.
    final dynamic dyn = parameter;
    // This version adapter deliberately invokes the shared getter dynamically.
    // ignore: avoid_dynamic_calls
    final type = dyn.type as TypeAnnotation?;
    return (name: name.lexeme, type: type?.toSource());
    // A different parameter shape is not a supported identity expression.
    // ignore: avoid_catching_errors
  } on NoSuchMethodError {
    return null;
  }
}

/// Extracts the class name from a [ClassDeclaration]. Analyzer 11+ removed
/// the once-simple `ClassDeclaration.name` getter in favor of `namePart`
/// (a `ClassNamePart` — `NameWithTypeParameters` for an ordinary class,
/// `PrimaryConstructorDeclaration` for the newer primary-constructor
/// class shape). None of this codebase's `CoreXxxStyle`/`CoreXxxVariantStyle`
/// classes use primary constructors, so only `NameWithTypeParameters` is
/// handled — a class in the other shape throws rather than silently
/// returning a wrong/empty name (a wrong component name is a worse failure
/// mode than a loud one for a reader whose job is exact census counts).
String _classNameOf(ClassDeclaration decl) {
  final namePart = decl.namePart;
  return switch (namePart) {
    NameWithTypeParameters(:final typeName) => typeName.lexeme,
    _ => throw StateError(
      'Unsupported class name shape (${namePart.runtimeType}) in '
      '${decl.toSource().split('\n').first}',
    ),
  };
}
