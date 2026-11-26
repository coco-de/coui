/// Per-component axis discovery (schema v3 `axes` — #4012 / FR-001).
///
/// Walks each component directory under `contracts/` and derives the four
/// Figma-representable axes plus the "everything else" record:
///
///   `variant` — The enum named exactly `Core{Pascal}Variant` for that
///             directory's slug. Members in source declaration order, plus
///             the enum's own `static const defaultVariant` member when it
///             declares one (21 of 28 variant enums do today; absent →
///             `default: null`, never a guessed first member).
///   `size`    — Present iff the component's contract class declares a
///             `size` getter typed `CoreComponentSize`; members come from
///             the single `CoreComponentSize` enum source.
///   `state`   — The enum named exactly `Core{Pascal}State`. Exact match
///             only: `CoreCalendarDateState` / `CoreValidationState`
///             deliberately do NOT match — a loose suffix match would
///             promote non-convention enums into axes and manufacture
///             wrong Figma variant dimensions.
///   `enabled` — True iff the contract class declares an `enabled` getter
///             (`bool` / `bool?`).
///   `other`   — Every other enum declared in that component's directory,
///             members in full, plus the literal arguments each member
///             passes to an enhanced enum's const constructor (`fields`).
///             Recorded, never promoted — axes.other 의 Figma 축 승격은
///             명시적 범위 외.
///
/// The same contract-class walk also collects the component's **widget
/// composition slots** (`props.slots` — #4099 / D-25): every getter typed
/// `W`, `W?`, `List<W>` or `List<W>?` on the contract class, in source
/// declaration order. A single slot reads `required` off its nullability; a
/// collection slot (`List<W>`) is marked `repeated` and is never `required`
/// — the list may be empty, and Figma has no repeated-slot property, so the
/// canvas draws such a slot as one swap a designer fills with whatever the
/// caller would put first. The names are what a builder's INSTANCE_SWAP
/// properties are held to; omitting the collections would make a swap on
/// AppBar's `leading` read as a composition point the widget does not have.
/// Slots are not axes (they never become Figma variant
/// dimensions), so they are emitted under a separate top-level `props` key
/// by [propsJson]; they live in this reader only to reuse the single AST
/// walk.
///
/// Grouping key is the *directory* slug (`contracts/{slug}/`), matching the
/// exact-match predicates which are themselves derived from that slug —
/// `navigation_bar/` → `CoreNavigationBarVariant`. This is deliberately NOT
/// `slugOf(class name)`: an off-convention enum (`CoreNavigationLabelMode`)
/// carries no component name to derive from, but its home directory does.
///
/// Determinism: directories and files are walked in sorted order, enum
/// members keep source order, `other` is sorted by enum name — two runs
/// over the same tree emit byte-identical JSON (schema v2's standing
/// requirement, inherited unchanged).
// ignore_for_file: depend_on_referenced_packages
// `analyzer` is a direct `dev_dependency` of this package — see
// `style_reader.dart`'s matching ignore.
library;

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';

import 'ast_value.dart' show namedArg;
import 'parse_source.dart';

/// One discovered enum — name plus members in source declaration order.
final class DiscoveredEnum {
  const DiscoveredEnum({
    required this.name,
    required this.members,
    this.hidden = const [],
    this.defaultMember,
    this.fields = const {},
  });

  final String name;

  /// The members the canvas draws — source order, minus [hidden].
  final List<String> members;

  /// Members the enum declares that the canvas must NOT offer, in source
  /// order: `@Deprecated` (going away — the message on `CoreButtonVariant
  /// .text` literally reads "Dropped from the Figma Button variant set", a
  /// promise only this list keeps) and `@behaviourOnly` (staying, but a
  /// widget's mechanism rather than a designer's option). Named rather than
  /// silently dropped: the plugin retires their canvas members by name, and
  /// a member that just vanished from `members` would surface as an
  /// unexplained leftover instead.
  final List<String> hidden;

  /// The member named by the enum's own `static const … defaultVariant`
  /// declaration, when present. `CoreTabVariant.pill` and plain `pill`
  /// initializer spellings both resolve to `pill`.
  final String? defaultMember;

  /// What an enhanced enum's members pass to its const constructor, per
  /// canvas member — `private(stroke: CoreDisclosureStroke.dashed,
  /// hasMarker: false)` → `{'private': {'stroke': 'dashed', 'hasMarker':
  /// false}}`.
  ///
  /// Some enums carry a DESIGN fact on the member itself rather than in a
  /// style slot, on purpose: `CoreDisclosureKind` fixes each kind's outline
  /// pattern and marker so no theme can collapse the three kinds into colour
  /// alone. A canvas that draws those kinds needs the same facts, and a
  /// builder that restated them would be a second source that nothing keeps
  /// in step with the enum. So they are read here, off the AST.
  ///
  /// Named arguments only, and only the ones whose value is a literal
  /// (`bool` / number / string) or an enum member (`X.y` or bare `y` →
  /// `'y'`). Anything else — a computed expression — is left out rather than
  /// guessed; a builder that needs it finds the key missing and fails loudly.
  final Map<String, Map<String, Object>> fields;
}

/// One widget composition slot on a contract class — `W? get title;` →
/// `(name: 'title', required: false)`.
final class DiscoveredSlot {
  const DiscoveredSlot({
    required this.name,
    required this.required,
    this.repeated = false,
  });

  final String name;

  /// `W get child` (non-nullable) → true; `W? get title` → false. Read off
  /// the source nullability, never inferred. Always false for a [repeated]
  /// slot — a list may be empty.
  final bool required;

  /// `List<W>` / `List<W>?` — a collection the widget renders as handed.
  final bool repeated;
}

/// Axis surface of one component directory.
final class ComponentAxes {
  const ComponentAxes({
    required this.variant,
    required this.hasSize,
    required this.state,
    required this.enabled,
    required this.other,
    required this.slots,
  });

  static const ComponentAxes empty = ComponentAxes(
    variant: null,
    hasSize: false,
    state: null,
    enabled: false,
    other: [],
    slots: [],
  );

  final DiscoveredEnum? variant;

  /// Whether the contract declares `CoreComponentSize get size` — the
  /// member list itself lives once in [readComponentSizeMembers], not per
  /// component.
  final bool hasSize;
  final DiscoveredEnum? state;
  final bool enabled;
  final List<DiscoveredEnum> other;

  /// Widget composition slots (`W` / `W?` / `List<W>` getters) in source declaration
  /// order — emitted under `props.slots`, not `axes` (slots are not Figma
  /// variant dimensions).
  final List<DiscoveredSlot> slots;
}

/// JSON shape for one component's `axes` key. Every key always present,
/// value `null`/`false`/`[]` when absent — schema v2's "union 금지" rule
/// carried into v3.
Map<String, dynamic> axesJson(
  ComponentAxes axes, {
  required List<String> componentSizeMembers,
}) => {
  'variant': axes.variant == null
      ? null
      : {
          'enum': axes.variant!.name,
          'members': axes.variant!.members,
          'hidden': axes.variant!.hidden,
          'default': axes.variant!.defaultMember,
        },
  'size': axes.hasSize
      ? {'enum': 'CoreComponentSize', 'members': componentSizeMembers}
      : null,
  'state': axes.state == null
      ? null
      : {
          'enum': axes.state!.name,
          'members': axes.state!.members,
          'hidden': axes.state!.hidden,
        },
  'enabled': axes.enabled,
  'other': [
    for (final e in axes.other)
      {
        'enum': e.name,
        'members': e.members,
        'hidden': e.hidden,
        'fields': e.fields,
      },
  ],
};

/// JSON shape for one component's `props` key (#4099 / D-25) — the widget
/// composition slots a Figma TEXT/BOOLEAN component property can bind to.
/// Names only, straight off the contract AST; which slot actually becomes
/// a TEXT vs BOOLEAN property is the plugin builder's call (it knows which
/// nodes it renders), never guessed here.
Map<String, dynamic> propsJson(ComponentAxes axes) => {
  'slots': [
    for (final s in axes.slots)
      {'name': s.name, 'required': s.required, 'repeated': s.repeated},
  ],
};

/// Reads the `CoreComponentSize` member list from its single source file.
/// Throws when the file/enum shape changes — a silent `[]` here would emit
/// `size: null` for every component and read as "no size axes anywhere",
/// which is exactly the kind of quiet collapse the extraction floors in
/// `check_figma_registry_parity.sh` exist to prevent.
List<String> readComponentSizeMembers({required String srcRoot}) {
  final path = '$srcRoot/size/component_size.dart';
  final source = File(path).readAsStringSync();
  final result = parseSource(content: source, path: path);
  if (result.errors.isNotEmpty) {
    throw StateError('failed to parse $path');
  }
  for (final decl in result.unit.declarations) {
    if (decl is EnumDeclaration &&
        _typeNameOf(decl.namePart) == 'CoreComponentSize') {
      return [for (final c in decl.body.constants) c.name.lexeme];
    }
  }
  throw StateError('enum CoreComponentSize not found in $path');
}

/// Walks every component directory under [contractsRoot] and returns the
/// discovered axes keyed by directory slug.
Map<String, ComponentAxes> readAxes({required String contractsRoot}) {
  final root = Directory(contractsRoot);
  if (!root.existsSync()) {
    throw StateError('contracts root not found: $contractsRoot');
  }

  final dirs =
      root.listSync().whereType<Directory>().map((d) => d.path).toList()
        ..sort();

  final bySlug = <String, ComponentAxes>{};
  for (final dirPath in dirs) {
    final slug = dirPath.split(Platform.pathSeparator).last;
    bySlug[slug] = _readDirectory(slug: slug, dirPath: dirPath);
  }
  return bySlug;
}

/// The one real-world irregular where a component's variant enum name
/// doesn't derive from its directory slug (mirrors the reserved
/// `NAME_EXCEPTIONS` in `check_figma_registry_parity.sh`, populated for the
/// same reason that one stayed empty: only when a real name breaks the
/// rule). `tabs`' enum is the singular `CoreTabVariant`, and its v2
/// `defaultsByVariant` (`pill`/`underline`) proves that enum IS the
/// component's variant axis. `chat`'s `CoreChatBubbleVariant` is
/// deliberately NOT here — its variant defaults live under the
/// `chat_bubble` sub-component style, so it stays recorded in `other`
/// rather than being promoted to chat's own axis.
const _kVariantEnumExceptions = {'tabs': 'CoreTabVariant'};

ComponentAxes _readDirectory({required String slug, required String dirPath}) {
  final pascal = _pascalOf(slug);
  final variantEnumName =
      _kVariantEnumExceptions[slug] ?? 'Core${pascal}Variant';
  final stateEnumName = 'Core${pascal}State';
  final contractClassName = 'Core${pascal}Contract';

  final files =
      Directory(dirPath)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.path)
          .toList()
        ..sort();

  DiscoveredEnum? variant;
  DiscoveredEnum? state;
  var enabled = false;
  var hasSize = false;
  final other = <DiscoveredEnum>[];
  final slots = <DiscoveredSlot>[];

  for (final path in files) {
    final source = File(path).readAsStringSync();
    final result = parseSource(content: source, path: path);
    if (result.errors.isNotEmpty) {
      // Same contract as repo_reader: a file this reader cannot parse makes
      // the whole export unreliable — surface it, don't skip it.
      throw StateError('axis reader failed to parse $path');
    }

    for (final decl in result.unit.declarations) {
      if (decl is EnumDeclaration) {
        // A retired enum is not an axis. Its constants are all still
        // spelled (a deprecation window keeps them compiling), so the
        // per-constant `_isOffCanvas` fold below would still promote the
        // whole thing as a live axis — which is how a `Core{X}State` that
        // the widget no longer takes would keep enumerating members the
        // builder has replaced with its own declaration.
        if (_isRetired(decl)) continue;
        // A library-private enum is a computation's own vocabulary, not a
        // value any caller can pass — it cannot reach a contract, so it
        // cannot be an axis of one, recorded or promoted.
        if (_typeNameOf(decl.namePart).startsWith('_')) continue;
        final discovered = DiscoveredEnum(
          name: _typeNameOf(decl.namePart),
          members: [
            for (final c in decl.body.constants)
              if (!_isOffCanvas(c)) c.name.lexeme,
          ],
          hidden: [
            for (final c in decl.body.constants)
              if (_isOffCanvas(c)) c.name.lexeme,
          ],
          defaultMember: _defaultVariantOf(decl),
          fields: {
            for (final c in decl.body.constants)
              if (!_isOffCanvas(c) && _constructorFieldsOf(c).isNotEmpty)
                c.name.lexeme: _constructorFieldsOf(c),
          },
        );
        if (discovered.name == variantEnumName) {
          variant = discovered;
        } else if (discovered.name == stateEnumName) {
          state = discovered;
        } else {
          other.add(discovered);
        }
      } else if (decl is ClassDeclaration &&
          _typeNameOf(decl.namePart) == contractClassName) {
        for (final member in decl.body.members) {
          if (member is! MethodDeclaration || !member.isGetter) continue;
          final returnType = member.returnType?.toSource() ?? '';
          if (member.name.lexeme == 'enabled' &&
              (returnType == 'bool' || returnType == 'bool?')) {
            enabled = true;
          }
          if (member.name.lexeme == 'size' &&
              returnType == 'CoreComponentSize') {
            hasSize = true;
          }
          // #4099 — widget composition slots. Exactly `W`/`W?` (the
          // contracts' universal widget type parameter name), or a
          // `List<W>` of them, recorded as `repeated`.
          if (returnType == 'W' || returnType == 'W?') {
            slots.add(
              DiscoveredSlot(
                name: member.name.lexeme,
                required: returnType == 'W',
              ),
            );
          } else if (returnType == 'List<W>' || returnType == 'List<W>?') {
            slots.add(
              DiscoveredSlot(
                name: member.name.lexeme,
                required: false,
                repeated: true,
              ),
            );
          }
        }
      }
    }
  }

  other.sort((a, b) => a.name.compareTo(b.name));
  return ComponentAxes(
    variant: variant,
    hasSize: hasSize,
    state: state,
    enabled: enabled,
    other: other,
    slots: slots,
  );
}

/// `static const CoreTabVariant defaultVariant = pill;` (or a
/// `CoreTabVariant.pill` spelling) inside the enum body → `'pill'`.
/// Whether an enum member is one the canvas must not offer — see
/// [DiscoveredEnum.hidden]. Read off the annotation's source text, not its
/// element, for the reason `style_reader.dart` gives for `isDeprecated`: it
/// keeps this file clear of the analyzer type names the churn gate forbids.
bool _isOffCanvas(EnumConstantDeclaration c) => c.metadata.any((a) {
  final src = a.toSource();
  return src.startsWith('@Deprecated') ||
      src == '@deprecated' ||
      src == '@behaviourOnly';
});

/// Whether the enum *declaration itself* is deprecated — the whole type is
/// going away, not one member of it. Same source-text read as
/// [_isOffCanvas], for the same reason.
bool _isRetired(EnumDeclaration decl) => decl.metadata.any((a) {
  final src = a.toSource();
  return src.startsWith('@Deprecated') || src == '@deprecated';
});

/// The literal named arguments one enum constant passes to its const
/// constructor — see [DiscoveredEnum.fields] for what counts as literal.
Map<String, Object> _constructorFieldsOf(EnumConstantDeclaration c) {
  final arguments = c.arguments?.argumentList.arguments;
  if (arguments == null) return const {};
  final out = <String, Object>{};
  for (final argument in arguments) {
    // Through the reader's version-portable adapter — the named-argument
    // wrapper type is one analyzer renames between majors.
    final named = namedArg(argument);
    if (named == null) continue;
    final value = _literalOf(named.value);
    if (value != null) out[named.name] = value;
  }
  return out;
}

Object? _literalOf(Expression e) => switch (e) {
  BooleanLiteral(:final value) => value,
  IntegerLiteral(:final value?) => value,
  DoubleLiteral(:final value) => value,
  SimpleStringLiteral(:final value) => value,
  PrefixedIdentifier(:final identifier) => identifier.name,
  SimpleIdentifier(:final name) => name,
  _ => null,
};

String? _defaultVariantOf(EnumDeclaration decl) {
  for (final member in decl.body.members) {
    if (member is! FieldDeclaration || !member.isStatic) continue;
    for (final variable in member.fields.variables) {
      if (variable.name.lexeme != 'defaultVariant') continue;
      final initializer = variable.initializer;
      if (initializer == null) return null;
      final source = initializer.toSource();
      final lastDot = source.lastIndexOf('.');
      return lastDot < 0 ? source : source.substring(lastDot + 1);
    }
  }
  return null;
}

/// Extracts the declared name from a class/enum `namePart` — same shape
/// and same loud-failure reasoning as `style_reader.dart#_classNameOf`
/// (analyzer 11+ replaced the `name` getter with `namePart`; none of this
/// codebase's contract enums/classes use primary constructors).
String _typeNameOf(ClassNamePart namePart) => switch (namePart) {
  NameWithTypeParameters(:final typeName) => typeName.lexeme,
  PrimaryConstructorDeclaration() => throw StateError(
    'Unsupported declaration name shape (primary constructor)',
  ),
};

/// `input_otp` → `InputOtp` — segment-by-segment, never letter-by-letter
/// (same rule, same reason as `check_figma_registry_parity.sh#to_pascal`:
/// Effective Dart treats acronyms as ordinary words, so the segment rule
/// already produces coui_flutter's actual class names).
String _pascalOf(String slug) => slug
    .split('_')
    .map((seg) => seg.isEmpty ? seg : seg[0].toUpperCase() + seg.substring(1))
    .join();
