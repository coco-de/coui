import 'package:test/test.dart';

import '../bin/figma_reader/ast_value.dart';
import '../bin/figma_reader/census.dart';
import '../bin/figma_reader/repo_reader.dart';
import '../bin/figma_reader/style_reader.dart';

void main() {
  test('an identity default may declare a final parameter', () {
    final result = readCompilationUnit('test.dart', '''
      class Example {
        static double defaultWidth(final double value) => value;
      }
    ''')!;
    final method = result.single.derivedDefaults.single;
    expect(method.sourceField, 'value');
    expect(method.parameterType, 'double');
  });

  group('readValue — expression shape classification', () {
    DiscoveredClass parseOneClass(String classSource) {
      final classes = readCompilationUnit('test.dart', classSource);
      expect(classes, isNotNull, reason: 'must parse with 0 errors');
      expect(classes, hasLength(1));
      return classes!.single;
    }

    test('literal values', () {
      final cls = parseOneClass('''
        class Foo {
          static const double a = 1.0;
          static const int b = 2;
          static const bool c = true;
          static const String d = 'hi';
          static const double e = -4.0;
        }
      ''');
      final byName = {for (final m in cls.staticMembers) m.name: m.value};
      expect(byName['a'], equals(const LiteralValue(1.0)));
      expect(byName['b'], equals(const LiteralValue(2)));
      expect(byName['c'], equals(const LiteralValue(true)));
      expect(byName['d'], equals(const LiteralValue('hi')));
      expect(byName['e'], equals(const LiteralValue(-4.0)));
    });

    test('namespace token references and dot-shorthand', () {
      final cls = parseOneClass('''
        class Foo {
          static const CoreColor a = CoreColors.primary;
          static const CoreFooVariant b = .outlined;
        }
      ''');
      final byName = {for (final m in cls.staticMembers) m.name: m.value};
      // `CoreColors.primary` — a MethodInvocation-free property access.
      expect(byName['a'], isA<RefValue>());
      final a = byName['a']! as RefValue;
      expect(a.owner, 'CoreColors');
      expect(a.member, 'primary');

      expect(byName['b'], isA<RefValue>());
      final b = byName['b']! as RefValue;
      expect(b.owner, isNull);
      expect(b.member, 'outlined');
    });

    test('call expressions with named and positional args', () {
      final cls = parseOneClass('''
        class Foo {
          static const CoreColor a = CoreColor.token(
            CoreColors.primary,
            opacity: CoreOpacity.opacity60,
          );
        }
      ''');
      final call = cls.staticMembers.single.value as CallValue;
      expect(call.owner, 'CoreColor');
      expect(call.callee, 'token');
      expect(call.positionalArgs, hasLength(1));
      expect(call.namedArgs.keys, contains('opacity'));
      expect(
        (call.positionalArgs.single as RefValue).member,
        'primary',
      );
    });

    test('bare constructor calls (no const/new keyword)', () {
      final cls = parseOneClass('''
        class Foo {
          static const CoreFooVariantStyle a = CoreFooVariantStyle(
            background: CoreColor.token(CoreColors.surface),
            radius: 4.0,
          );
        }
      ''');
      final call = cls.staticMembers.single.value as CallValue;
      expect(call.owner, isNull);
      expect(call.callee, 'CoreFooVariantStyle');
      expect(call.namedArgs['radius'], equals(const LiteralValue(4.0)));
      expect(call.namedArgs['background'], isA<CallValue>());
    });

    test('map literal dispatch table with mixed key/value shapes', () {
      final cls = parseOneClass('''
        class Foo {
          static const Map<CoreFooSize, FooVariantStyle> defaultsBySize = {
            CoreFooSize.xs: FooVariantStyle(a: 1.0),
            CoreFooSize.sm: FooVariantStyle(a: 2.0),
          };
        }
      ''');
      final map = cls.staticMembers.single.value as MapValue;
      expect(map.entries, hasLength(2));
      final firstKey = map.entries.first.key as RefValue;
      expect(firstKey.owner, 'CoreFooSize');
      expect(firstKey.member, 'xs');
      expect(map.entries.first.value, isA<CallValue>());
    });

    test(
      'unmodelled expressions fall back to compacted source text, not a guess',
      () {
        // Something still outside the grammar this reader claims to
        // understand. This test has now named three different expressions:
        // `1.0 + 2.0` until arithmetic became a modelled shape (a focus-ring
        // default states its extension as `ringOffset + ringWidth`), then
        // `kTable[0]` until indexing did (a per-size table stitched by a map
        // comprehension had to be readable), and now a cascade — which nothing
        // in this codebase's defaults uses and which carries no value to read.
        //
        // The churn is the point rather than a nuisance: every time a shape
        // moves out of this test it is because the reader stopped guessing at
        // something real. What has to stay true is the fallback itself — an
        // expression the reader cannot model keeps its SOURCE rather than
        // arriving as a wrong value.
        final cls = parseOneClass('''
        class Foo {
          static const double a = kBuilder..configure();
        }
      ''');
        final value = cls.staticMembers.single.value;
        expect(value, isA<RawValue>());
        expect((value as RawValue).source, 'kBuilder..configure()');
      },
    );

    test('binary arithmetic keeps both operands as a shape, unfolded', () {
      final cls = parseOneClass('''
        class Foo {
          static const double a = CoreFocusRing.ringOffset + CoreFocusRing.ringWidth;
        }
      ''');
      final value = cls.staticMembers.single.value;
      expect(value, isA<BinaryValue>());
      final binary = value as BinaryValue;
      expect(binary.op, '+');
      // Unfolded on purpose: folding needs the class/namespace registry, and
      // this layer has none. Resolution folds it (`_foldBinary`), and the
      // result carries no token ref because the sum is not any one token.
      expect(
        binary.left,
        const RefValue(owner: 'CoreFocusRing', member: 'ringOffset'),
      );
      expect(
        binary.right,
        const RefValue(owner: 'CoreFocusRing', member: 'ringWidth'),
      );
    });

    test('a record literal keeps its named fields', () {
      final cls = parseOneClass('''
        class Foo {
          static const List<CoreShadowLayer> a = [
            (offsetX: 0, offsetY: 4, blurRadius: 8, spreadRadius: -2,
             opacity: 0.06, inset: false),
          ];
        }
      ''');
      final list = cls.staticMembers.single.value as ListValue;
      final layer = list.items.single as RecordValue;
      expect(layer.positionalFields, isEmpty);
      expect(layer.namedFields['offsetY'], const LiteralValue(4));
      expect(layer.namedFields['spreadRadius'], const LiteralValue(-2));
      expect(layer.namedFields['inset'], const LiteralValue(false));
    });

    test('a role read off the type scale, with an override, is one call', () {
      final cls = parseOneClass('''
        class Foo {
          static final CoreTextStyle a = CoreTypography
              .coui
              .bodyMedium
              .copyWith(color: const CoreColor.token(CoreColors.onSurface));
        }
      ''');
      final call = cls.staticMembers.single.value as CallValue;
      expect(call.callee, 'copyWith');
      // The receiver survives as the first positional argument — without it
      // the role is lost and only the override reaches the emitter.
      expect(
        call.positionalArgs.single,
        const RefValue(owner: 'CoreTypography.coui', member: 'bodyMedium'),
      );
      expect(call.namedArgs['color'], isA<CallValue>());
    });
  });

  group('readCompilationUnit — class/field/member discovery', () {
    test('separates instance fields from static members', () {
      final classes = readCompilationUnit('test.dart', '''
        class CoreFooStyle implements CoreStyle<CoreFooStyle> {
          const CoreFooStyle({this.a, this.b});
          final double? a;
          final CoreColor? b;
          static const double defaultA = 1.0;
        }
      ''')!;
      final cls = classes.single;
      expect(cls.name, 'CoreFooStyle');
      expect(cls.implementsCoreStyle, isTrue);
      expect(cls.instanceFields.map((f) => f.name), ['a', 'b']);
      expect(cls.staticMembers.map((m) => m.name), ['defaultA']);
    });

    test('collects both static const and static final', () {
      final classes = readCompilationUnit('test.dart', '''
        class Foo {
          static const double a = 1.0;
          static final double b = 2.0;
        }
      ''')!;
      final byName = {
        for (final m in classes.single.staticMembers) m.name: m,
      };
      expect(byName['a']!.isConst, isTrue);
      expect(byName['b']!.isConst, isFalse);
    });

    test('a file can declare more than one class', () {
      final classes = readCompilationUnit('test.dart', '''
        class CoreChatStyle implements CoreStyle<CoreChatStyle> {
          const CoreChatStyle();
        }
        class CoreChatBubbleStyle implements CoreStyle<CoreChatBubbleStyle> {
          const CoreChatBubbleStyle();
        }
      ''')!;
      expect(classes.map((c) => c.name), [
        'CoreChatStyle',
        'CoreChatBubbleStyle',
      ]);
      expect(classes.every((c) => c.implementsCoreStyle), isTrue);
    });

    test('enum declarations are walked past, not treated as a class', () {
      final classes = readCompilationUnit('test.dart', '''
        enum CoreChipUnselectedStyle { outlined, filled }
      ''')!;
      expect(classes, isEmpty);
    });

    test('private static members are collected and flagged', () {
      final classes = readCompilationUnit('test.dart', '''
        class Foo {
          static const Map<int, Foo> _hidden = {};
        }
      ''')!;
      final member = classes.single.staticMembers.single;
      expect(member.name, '_hidden');
      expect(member.isPrivate, isTrue);
    });

    test('a class-level @Deprecated is read off the declaration', () {
      // A retired component stays discovered through its deprecation window,
      // but the exporter must be able to tell it apart — it ships the
      // replacement, not the retired surface. The annotation's message may
      // itself hold a call, so the flag reads the source, not the element.
      final classes = readCompilationUnit('test.dart', '''
        @Deprecated('Use CoreBarStyle(addressBar: null) instead (since 0.1).')
        @immutable
        class CoreFooStyle implements CoreStyle<CoreFooStyle> {
          const CoreFooStyle();
        }
        @immutable
        class CoreBarStyle implements CoreStyle<CoreBarStyle> {
          const CoreBarStyle();
        }
      ''')!;
      final byName = {for (final c in classes) c.name: c};
      expect(byName['CoreFooStyle']!.isDeprecated, isTrue);
      expect(byName['CoreBarStyle']!.isDeprecated, isFalse);
    });

    test('parse failure returns null rather than throwing', () {
      final classes = readCompilationUnit('test.dart', 'class Foo {{{{');
      expect(classes, isNull);
    });
  });

  group('census — type-based classification', () {
    test('Map-typed members are dispatch tables regardless of name', () {
      final classes = readCompilationUnit('test.dart', '''
        class CoreFooStyle {
          static const Map<int, int> weirdName = {1: 2};
          static const Map<int, int> defaultsByVariant = {1: 2};
          static const double defaultA = 1.0;
        }
      ''')!;
      final census = buildCensus(
        classes: classes,
        filesParsed: 1,
        filesFailed: const [],
      );
      expect(census.dispatchTableCount, 2);
      expect(census.scalarDefaultCount, 1);
      expect(
        census.offConventionDispatchNames,
        contains('CoreFooStyle.weirdName'),
      );
      expect(
        census.offConventionDispatchNames,
        isNot(contains('CoreFooStyle.defaultsByVariant')),
      );
    });
  });

  group('readContracts — integration against the real contracts tree', () {
    // These verify #3746's own completion bar: 145 (well, every contracts/
    // *.dart) files parse with 0 failures, and two consecutive runs produce
    // byte-identical census output (determinism — file order is sorted,
    // not filesystem-dependent).
    late RepoReadResult result;

    setUpAll(() {
      result = readContracts(
        repoRoot: '.',
        contractsRoot: 'lib/src/component/contracts',
      );
    });

    test('parses every contracts/ file with 0 failures', () {
      expect(
        result.filesFailed,
        isEmpty,
        reason: 'regex-free AST reader must not silently drop files',
      );
      expect(result.filesParsed, greaterThan(500));
    });

    test('discovers at least 100 MAIN CoreStyle classes', () {
      final mainCount = result.classesByName.values
          .where((c) => c.implementsCoreStyle)
          .length;
      expect(mainCount, greaterThan(100));
    });

    test('two consecutive runs are byte-identical (determinism)', () {
      final second = readContracts(
        repoRoot: '.',
        contractsRoot: 'lib/src/component/contracts',
      );
      expect(second.filesParsed, result.filesParsed);
      expect(
        second.classesByName.keys.toList(),
        result.classesByName.keys.toList(),
      );
    });

    test('description_card private dispatch holders are discovered', () {
      final cls = result.classesByName['CoreDescriptionCardStyle'];
      expect(cls, isNotNull);
      final names = cls!.staticMembers.map((m) => m.name).toSet();
      expect(names, contains('_dimensionalDefaultsBySize'));
      expect(names, contains('_typographyDefaultsBySize'));
      expect(names, contains('defaultsBySize'));
    });

    test('validation_badge typedef-record classes were promoted to classes '
        'discoverable like any other class (#3752)', () {
      expect(result.classesByName['CoreValidationBadgeSizeStyle'], isNotNull);
      expect(
        result.classesByName['CoreValidationBadgeStateColors'],
        isNotNull,
      );
    });
  });
}
