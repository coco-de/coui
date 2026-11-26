import 'dart:io';

import 'package:test/test.dart';

import '../generate_style_tables.dart';

const _fixtureNoVariant = '''
/// Immutable style describing how a `Widget` should render.
@immutable
class CoreWidgetStyle implements CoreStyle<CoreWidgetStyle> {
  const CoreWidgetStyle({this.padding, this.borderRadius});

  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(CoreSpace.space16);

  /// Content padding override.
  final CoreEdgeInsets? padding;

  /// Border radius override.
  final CoreBorderRadius? borderRadius;

  @override
  CoreWidgetStyle merge(CoreWidgetStyle? other) => this;
}
''';

const _fixtureWithTrackerMeta = '''
class CoreTrackedStyle implements CoreStyle<CoreTrackedStyle> {
  const CoreTrackedStyle({this.gapStyle});

  /// Nested gap slot. `null` defers to [defaultGapStyle]. (Per Epic #2228
  /// the receiving `Gap` owns its own scaling).
  final CoreGapStyle? gapStyle;
}
''';

const _kFixtureWithDeprecatedFields = '''
class CoreDeprecatedFieldsStyle implements CoreStyle<CoreDeprecatedFieldsStyle> {
  const CoreDeprecatedFieldsStyle({this.legacyGap, this.oneLineDeprecated, this.gap});

  /// Old gap override, replaced by [gap].
  @Deprecated(
    'No longer applied — see gap (since 0.129).',
  )
  final double? legacyGap;

  /// Single-line annotation form.
  @Deprecated('Use gap instead.')
  final double? oneLineDeprecated;

  /// Current gap override.
  final double? gap;
}
''';

// Deprecation must reach the table row of the field it annotates — and no
// other. The traps are the ones hand-counting fell into: an annotation on a
// `static const default*` landing on the next field, a message that wraps
// across adjacent string literals, parens inside the message, and a
// same-named field in the file's `CoreXxxVariantStyle`.
const _kFixtureDeprecationBoundaries = '''
class CoreEdgeStyle implements CoreStyle<CoreEdgeStyle> {
  const CoreEdgeStyle({this.borderWidth, this.padding, this.sameLine, this.bare, this.openParen, this.closeParen, this.gap});

  @Deprecated('Retired default (since 0.140).')
  static const double defaultBorderWidth = 1;

  /// Border width override.
  final double? borderWidth;

  /// Deprecated — use gap instead (since 0.141). Outer padding.
  @Deprecated(
    'Use gap instead (since 0.141) — padding (the old '
    'axis) never reached the inner row.',
  )
  final CoreEdgeInsets? padding;

  /// Same-line form.
  @Deprecated('Use gap.') final double? sameLine;

  /// Bare annotation form.
  @deprecated
  final double? bare;

  /// Unbalanced open paren in a wrapped message.
  @Deprecated(
    'Opens a paren :( '
    'and never closes it (since 0.143).',
  )
  final double? openParen;

  /// Unbalanced close paren.
  @Deprecated('Closes :) without opening.') final double? closeParen;

  /// Gap override.
  final double? gap;
}

class CoreEdgeVariantStyle {
  const CoreEdgeVariantStyle({this.borderWidth});

  @Deprecated('Variant-only (since 0.142).')
  final double? borderWidth;
}
''';

const _fixtureWithFinalVariantMap = '''
@immutable
class CoreSlabStyle implements CoreStyle<CoreSlabStyle> {
  const CoreSlabStyle({this.backgroundColor, this.padding});

  static final Map<CoreSlabVariant, CoreSlabStyle> defaultsByVariant = {
    CoreSlabVariant.plain: const CoreSlabStyle(
      padding: CoreEdgeInsets.all(CoreSpace.space8),
    ),
    CoreSlabVariant.tinted: CoreSlabStyle(
      backgroundColor: const CoreColor.token(CoreColors.surfaceContainerLow),
      padding: const CoreEdgeInsets.all(CoreSpace.space16),
    ),
  };

  /// Background colour override.
  final CoreColor? backgroundColor;

  /// Inset override.
  final CoreEdgeInsets? padding;
}
''';

const _fixtureWithVariant = '''
@immutable
class CoreThingStyle implements CoreStyle<CoreThingStyle> {
  const CoreThingStyle({this.backgroundColor, this.borderWidth});

  static const Map<CoreThingVariant, CoreThingVariantStyle> defaultsByVariant = {
    CoreThingVariant.outlined: CoreThingVariantStyle(
      backgroundColor: CoreColor.token(
        CoreColors.surface,
        fallbacks: [CoreColors.surfaceContainerLowest],
      ),
      borderWidth: CoreStrokeWidth.stroke1,
    ),
    CoreThingVariant.filled: CoreThingVariantStyle(
      // Explicit transparent border — see docs (no border class here either).
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer, opacity: CoreOpacity.opacity80),
      borderWidth: 0,
    ),
  };

  /// Background colour override.
  final CoreColor? backgroundColor;

  /// Border width override.
  final double? borderWidth;
}

@immutable
class CoreThingVariantStyle {
  const CoreThingVariantStyle({required this.backgroundColor, required this.borderWidth});
  final CoreColor backgroundColor;
  final double borderWidth;
}
''';

// A component whose `variant` names the look of one state, so its colour
// table is keyed by the colour enum and called `defaultsByColor`.
const _fixtureWithColor = '''
@immutable
class CoreSwatchStyle implements CoreStyle<CoreSwatchStyle> {
  const CoreSwatchStyle({this.padding});

  static const Map<CoreSwatchColor, CoreSwatchColorStyle> defaultsByColor = {
    CoreSwatchColor.neutral: CoreSwatchColorStyle(
      selectedBg: CoreColor.token(CoreColors.inverseSurface),
    ),
    CoreSwatchColor.primary: CoreSwatchColorStyle(
      selectedBg: CoreColor.token(CoreColors.primary),
    ),
  };

  /// Padding override.
  final CoreEdgeInsets? padding;
}
''';

// A component whose colours are keyed by tone, in a row class of their own,
// next to a variant axis that means strength.
const _fixtureWithToneRows = '''
@immutable
class CoreMarkStyle implements CoreStyle<CoreMarkStyle> {
  const CoreMarkStyle({this.backgroundColor});

  static const Map<CoreMarkVariant, CoreMarkVariantStyle> defaultsByVariant = {
    CoreMarkVariant.filled: CoreMarkVariantStyle(borderWidth: 0),
  };

  static const Map<CoreMarkTone, CoreMarkToneStyle> defaultsByTone = {
    CoreMarkTone.neutral: CoreMarkToneStyle(
      filledBackgroundColor: CoreColor.token(
        CoreColors.surfaceContainerHighest,
      ),
      dotColor: CoreColor.token(CoreColors.outline),
    ),
    CoreMarkTone.success: CoreMarkToneStyle(
      filledBackgroundColor: CoreColor.token(CoreColors.success),
      dotColor: CoreColor.token(CoreColors.success),
    ),
  };

  /// Fill override.
  final CoreColor? backgroundColor;
}
''';

// A tone map whose rows are partial patches of the component's own style —
// not the table shape, and reading it would change a page that never asked
// for a tone table.
const _fixtureWithToneSelfPatches = '''
@immutable
class CorePatchStyle implements CoreStyle<CorePatchStyle> {
  const CorePatchStyle({this.foregroundColor});

  static const Map<CorePatchTone, CorePatchStyle> defaultsByTone = {
    CorePatchTone.neutral: CorePatchStyle(
      foregroundColor: CoreColor.token(CoreColors.onSurface),
    ),
    CorePatchTone.critical: CorePatchStyle(
      foregroundColor: CoreColor.token(CoreColors.error),
    ),
  };

  /// Foreground override.
  final CoreColor? foregroundColor;
}
''';

void main() {
  group('marker text is safe to embed as an HTML comment', () {
    // Regression: an earlier marker read `--write` inline. The WHATWG HTML
    // tokenizer treats any `--` inside a comment body (outside the
    // opening `<!--`/closing `-->` delimiters) as a parse error, and
    // jaspr build's markdown pipeline throws building the page — this
    // broke every one of the 28 docs the marker had been inserted into.
    // A pure string check here is the fast, no-jaspr-build-required way
    // to catch a repeat.
    String stripDelimiters(String marker) =>
        marker.replaceFirst('<!--', '').replaceFirst(RegExp(r'-->$'), '');

    test('BEGIN marker body has no `--` outside its delimiters', () {
      expect(stripDelimiters(kStyleTableBeginMarker), isNot(contains('--')));
    });

    test('END marker body has no `--` outside its delimiters', () {
      expect(stripDelimiters(kStyleTableEndMarker), isNot(contains('--')));
    });
  });

  group('parseStyleFile — no variant', () {
    test('extracts class name and fields with descriptions', () {
      final parsed = parseStyleFile(_fixtureNoVariant);
      expect(parsed, isNotNull);
      expect(parsed!.className, 'CoreWidgetStyle');
      expect(parsed.fields, hasLength(2));
      expect(parsed.fields[0].name, 'padding');
      expect(parsed.fields[0].type, 'CoreEdgeInsets?');
      expect(parsed.fields[0].description, 'Content padding override.');
      expect(parsed.fields[1].name, 'borderRadius');
      expect(parsed.variantDefaults, isEmpty);
    });

    test('does not capture static const defaults as instance fields', () {
      final parsed = parseStyleFile(_fixtureNoVariant)!;
      expect(
        parsed.fields.map((f) => f.name),
        isNot(contains('defaultPadding')),
      );
    });
  });

  group('parseStyleFile — tracker metadata scrubbing', () {
    // docs_api_sync_test.dart's "문서에 tracker 메타가 남아 있지 않다" gate
    // bans `Epic #\d+` etc. in docs_core/content/**. Source doc comments
    // are allowed to reference one; this generator's output is not.
    test('strips Epic #N references from field descriptions', () {
      final parsed = parseStyleFile(_fixtureWithTrackerMeta)!;
      final description = parsed.fields.single.description!;
      expect(description, isNot(contains('Epic #2228')));
      expect(description, isNot(contains('#2228')));
    });

    test(
      'sanitized description has no leftover double spaces or empty parens',
      () {
        final parsed = parseStyleFile(_fixtureWithTrackerMeta)!;
        final description = parsed.fields.single.description!;
        expect(description, isNot(contains('  ')));
        expect(description, isNot(contains('()')));
      },
    );
  });

  group('parseStyleFile — what reaches the field table', () {
    // The table is read by people who use the kit. The first paragraph of
    // a field's doc comment is written for them; the paragraphs after it
    // are notes for the people who change the field.
    const fixture = '''
@immutable
class CoreWidgetStyle implements CoreStyle<CoreWidgetStyle> {
  const CoreWidgetStyle({this.gap, this.colors});

  /// Space between the icon and the label. `null` uses [defaultGap].
  ///
  /// Raw-forwarded to the gap resolver — a note for the people who change
  /// this field.
  final double? gap;

  /// Colours of the fade.
  final List<CoreColor>? colors;

  @override
  bool operator ==(Object other) {
    final a = colors;
    return other is CoreWidgetStyle && a == other.colors;
  }
}
''';

    test('only the first paragraph of a doc comment', () {
      final gap = parseStyleFile(fixture)!.fields.first;
      expect(
        gap.description,
        'Space between the icon and the label. `null` uses [defaultGap].',
      );
    });

    test('a local in a method body is not read as a field', () {
      final names = parseStyleFile(fixture)!.fields.map((f) => f.name);
      expect(names, ['gap', 'colors']);
    });
  });

  group('parseStyleFile — annotation between doc comment and field', () {
    // `dart format`'s canonical order is doc comment, then annotation, then
    // the field — an `@Deprecated(...)` between the two must not break
    // doc/field adjacency the way an unrelated line does.
    test('multi-line @Deprecated(...) does not swallow the doc comment', () {
      final parsed = parseStyleFile(_kFixtureWithDeprecatedFields)!;
      final field = parsed.fields.firstWhere((f) => f.name == 'legacyGap');
      expect(field.description, 'Old gap override, replaced by [gap].');
    });

    test('single-line @Deprecated(...) does not swallow the doc comment', () {
      final parsed = parseStyleFile(_kFixtureWithDeprecatedFields)!;
      final field = parsed.fields.firstWhere(
        (f) => f.name == 'oneLineDeprecated',
      );
      expect(field.description, 'Single-line annotation form.');
    });

    test(
      'the field right after a deprecated one keeps its own doc comment',
      () {
        // Pins that a closed annotation never leaks into the next field's
        // own doc/field adjacency.
        final parsed = parseStyleFile(_kFixtureWithDeprecatedFields)!;
        final gap = parsed.fields.firstWhere((f) => f.name == 'gap');
        expect(gap.description, 'Current gap override.');
      },
    );
  });

  group('deprecation reaches the table row', () {
    // A generated table is read as matching its source. One that drops
    // `@Deprecated` tells the reader the field is alive.
    StyleField field(String name) => parseStyleFile(
      _kFixtureDeprecationBoundaries,
    )!.fields.firstWhere((f) => f.name == name);

    test('a multi-line message is joined across its adjacent literals', () {
      expect(
        field('padding').deprecation,
        'Use gap instead (since 0.141) — padding (the old axis) never '
        'reached the inner row.',
      );
    });

    test('parens inside the message do not end or extend the annotation', () {
      // The field after the annotation is still found, with its type.
      expect(field('padding').type, 'CoreEdgeInsets?');
      // Balanced parens alone would pass even if quotes were ignored, so the
      // fixture also carries an unbalanced `(` in a wrapped message and an
      // unbalanced `)` in a same-line one. Counting parens inside the quotes
      // swallows both fields.
      expect(field('openParen').type, 'double?');
      expect(
        field('openParen').deprecation,
        'Opens a paren :( and never closes it (since 0.143).',
      );
      expect(field('closeParen').type, 'double?');
      expect(field('closeParen').deprecation, 'Closes :) without opening.');
    });

    test('the badge carries `since`, and the message drops it', () {
      expect(
        describeField(field('padding')),
        startsWith(
          '**Deprecated (since 0.141)** — Use gap instead — padding (the '
          'old axis) never reached the inner row.',
        ),
      );
    });

    test('a doc comment that already says deprecated is not said twice', () {
      final cell = describeField(field('padding'));
      expect(cell, endsWith('reached the inner row. Outer padding.'));
      expect(RegExp('deprecated', caseSensitive: false).allMatches(cell), [
        anything,
      ]);
    });

    test('a message without `since` gets the bare badge', () {
      expect(
        describeField(field('sameLine')),
        '**Deprecated** — Use gap. Same-line form.',
      );
    });

    test('`@deprecated` with no message keeps the doc comment', () {
      expect(field('bare').deprecation, '');
      expect(
        describeField(field('bare')),
        '**Deprecated** — Bare annotation form.',
      );
    });

    test(
      'an annotation on a static default does not land on the next field',
      () {
        expect(field('borderWidth').deprecation, isNull);
        expect(describeField(field('borderWidth')), 'Border width override.');
      },
    );

    test('the field after a deprecated one stays undeprecated', () {
      expect(field('gap').deprecation, isNull);
      expect(describeField(field('gap')), 'Gap override.');
    });

    test(
      'a same-named field in the VariantStyle class does not cross over',
      () {
        final parsed = parseStyleFile(_kFixtureDeprecationBoundaries)!;
        expect(parsed.className, 'CoreEdgeStyle');
        expect(
          parsed.fields
              .where((f) => f.name == 'borderWidth')
              .single
              .deprecation,
          isNull,
        );
      },
    );

    test('the field table row carries the badge', () {
      final table = buildFieldTable(
        parseStyleFile(_kFixtureDeprecationBoundaries)!,
      );
      expect(
        table,
        contains(
          '| `sameLine` | `double?` | **Deprecated** — Use gap. Same-line '
          'form. |',
        ),
      );
      expect(table, contains('| `gap` | `double?` | Gap override. |'));
    });
  });

  group('parseStyleFile — with defaultsByVariant', () {
    test('extracts variant enum/style class names and per-variant values', () {
      final parsed = parseStyleFile(_fixtureWithVariant)!;
      expect(parsed.variantEnumType, 'CoreThingVariant');
      expect(parsed.variantStyleClassName, 'CoreThingVariantStyle');
      expect(parsed.variantDefaults.map((e) => e.key), ['outlined', 'filled']);
    });

    test('formats CoreColor.token(...) with fallbacks', () {
      final parsed = parseStyleFile(_fixtureWithVariant)!;
      final outlined = parsed.variantDefaults
          .firstWhere((e) => e.key == 'outlined')
          .value;
      expect(
        outlined['backgroundColor'],
        'surface (fallback: surfaceContainerLowest)',
      );
    });

    test('formats CoreColor.token(...) with opacity', () {
      final parsed = parseStyleFile(_fixtureWithVariant)!;
      final filled = parsed.variantDefaults
          .firstWhere((e) => e.key == 'filled')
          .value;
      expect(filled['backgroundColor'], 'surfaceContainer (opacity 80%)');
    });

    test('formats a namespace token access to its last segment', () {
      final parsed = parseStyleFile(_fixtureWithVariant)!;
      final outlined = parsed.variantDefaults
          .firstWhere((e) => e.key == 'outlined')
          .value;
      expect(outlined['borderWidth'], 'stroke1');
    });

    test('formats a plain number literal as-is', () {
      final parsed = parseStyleFile(_fixtureWithVariant)!;
      final filled = parsed.variantDefaults
          .firstWhere((e) => e.key == 'filled')
          .value;
      expect(filled['borderWidth'], '0');
    });

    test(
      'a comment with balanced parens inside the map does not break parsing',
      () {
        // The `filled` entry's inline comment ("no border class here either")
        // has a balanced `()` pair — this guards that _splitTopLevel's
        // bracket-depth counting on the *comment-stripped* source is not
        // thrown off by it (comments are stripped before depth counting).
        final parsed = parseStyleFile(_fixtureWithVariant)!;
        expect(parsed.variantDefaults, hasLength(2));
      },
    );
  });

  group('parseStyleFile — a defaultsByVariant map that is `static final`', () {
    // A row that overlays a token-backed text style cannot be `const`, so
    // its map is `final` and the rows state their values with `const`.
    test('the map and its rows are read like a `static const` one', () {
      final parsed = parseStyleFile(_fixtureWithFinalVariantMap)!;
      expect(parsed.variantEnumType, 'CoreSlabVariant');
      expect(parsed.variantDefaults.map((e) => e.key), ['plain', 'tinted']);
    });

    test('a leading `const` is not part of the rendered value', () {
      final parsed = parseStyleFile(_fixtureWithFinalVariantMap)!;
      final tinted = parsed.variantDefaults
          .firstWhere((e) => e.key == 'tinted')
          .value;
      expect(tinted['backgroundColor'], 'surfaceContainerLow');
      expect(
        tinted['padding'],
        'CoreEdgeInsets.all(CoreSpace.space16)',
      );
    });
  });

  group('parseStyleFile — with defaultsByColor', () {
    test('reads the colour-keyed map and labels the table by colour', () {
      final parsed = parseStyleFile(_fixtureWithColor)!;
      expect(parsed.variantEnumType, 'CoreSwatchColor');
      expect(parsed.variantStyleClassName, 'CoreSwatchColorStyle');
      expect(parsed.variantDefaults.map((e) => e.key), ['neutral', 'primary']);

      final table = buildVariantTable(parsed)!;
      expect(
        table,
        contains('### `CoreSwatchStyle` 색별 기본값 (`CoreSwatchColorStyle`)'),
      );
      expect(table, contains('| `selectedBg` | inverseSurface | primary |'));
    });

    test('a defaultsByVariant map keeps the 변형별 heading', () {
      final table = buildVariantTable(parseStyleFile(_fixtureWithVariant)!)!;
      expect(table, contains('변형별 기본값'));
      expect(table, isNot(contains('색별')));
    });
  });

  group('parseStyleFile — with defaultsByTone', () {
    test('reads tone rows of their own class into a 톤별 table', () {
      final parsed = parseStyleFile(_fixtureWithToneRows)!;
      expect(parsed.toneStyleClassName, 'CoreMarkToneStyle');
      expect(parsed.toneDefaults.map((e) => e.key), ['neutral', 'success']);

      final table = buildToneTable(parsed)!;
      expect(
        table,
        contains('### `CoreMarkStyle` 톤별 기본값 (`CoreMarkToneStyle`)'),
      );
      expect(table, contains('| 필드 | `neutral` | `success` |'));
      expect(
        table,
        contains(
          '| `filledBackgroundColor` | surfaceContainerHighest | success |',
        ),
      );
      expect(table, contains('| `dotColor` | outline | success |'));
    });

    test('the tone table sits after the variant table, which is unchanged', () {
      final parsed = parseStyleFile(_fixtureWithToneRows)!;
      expect(parsed.variantStyleClassName, 'CoreMarkVariantStyle');
      final variantTable = buildVariantTable(parsed)!;
      expect(variantTable, contains('변형별 기본값 (`CoreMarkVariantStyle`)'));
      expect(variantTable, isNot(contains('dotColor')));

      final block = buildGeneratedBlock(parsed);
      expect(
        block.indexOf('변형별 기본값'),
        lessThan(block.indexOf('톤별 기본값')),
      );
    });

    test('a tone map of the style class itself is not read', () {
      final parsed = parseStyleFile(_fixtureWithToneSelfPatches)!;
      expect(parsed.toneStyleClassName, isNull);
      expect(parsed.toneDefaults, isEmpty);
      expect(buildToneTable(parsed), isNull);
      expect(buildGeneratedBlock(parsed), isNot(contains('톤별')));
    });

    test('a file without defaultsByTone has no tone table', () {
      expect(buildToneTable(parseStyleFile(_fixtureWithVariant)!), isNull);
    });
  });

  group('formatStyleValue', () {
    test('.dotShorthand → bare name', () {
      expect(formatStyleValue('.transparent'), 'transparent');
    });

    test(
      'unrecognized expression falls back to compacted raw text, never guesses',
      () {
        expect(
          formatStyleValue('someWeirdExpression(1, 2)'),
          'someWeirdExpression(1, 2)',
        );
      },
    );

    test('long unrecognized expression is truncated, not silently dropped', () {
      final long = 'x' * 100;
      final formatted = formatStyleValue(long);
      expect(formatted.length, lessThanOrEqualTo(64));
      expect(formatted, endsWith('…'));
    });
  });

  group('buildFieldTable / buildVariantTable', () {
    test('field table has one row per field, in source order', () {
      final parsed = parseStyleFile(_fixtureNoVariant)!;
      final table = buildFieldTable(parsed);
      expect(table, contains('### `CoreWidgetStyle` 필드'));
      expect(
        table,
        contains(
          '| `padding` | `CoreEdgeInsets?` | Content padding override. |',
        ),
      );
      expect(table, contains('| `borderRadius` | `CoreBorderRadius?` |'));
      expect(table.indexOf('padding'), lessThan(table.indexOf('borderRadius')));
    });

    test('variant table is null when there is no defaultsByVariant', () {
      final parsed = parseStyleFile(_fixtureNoVariant)!;
      expect(buildVariantTable(parsed), isNull);
    });

    test('variant table has one column per variant and one row per field', () {
      final parsed = parseStyleFile(_fixtureWithVariant)!;
      final table = buildVariantTable(parsed)!;
      expect(table, contains('`outlined`'));
      expect(table, contains('`filled`'));
      expect(table, contains('| `backgroundColor` |'));
      expect(table, contains('| `borderWidth` |'));
    });
  });

  group('replaceMarkedSection', () {
    test('returns null when markers are absent (file has not opted in)', () {
      expect(
        replaceMarkedSection('# Doc\n\nno markers here.', 'generated'),
        isNull,
      );
    });

    test(
      'replaces content between markers, keeps markers and surrounding text',
      () {
        const markdown =
            '# Doc\n\n$kStyleTableBeginMarker\n\nold stale content\n\n'
            '$kStyleTableEndMarker\n\n## Next section\n';
        final replaced = replaceMarkedSection(markdown, 'fresh content')!;
        expect(replaced, contains('fresh content'));
        expect(replaced, isNot(contains('old stale content')));
        expect(replaced, contains(kStyleTableBeginMarker));
        expect(replaced, contains(kStyleTableEndMarker));
        expect(replaced, contains('## Next section'));
        expect(replaced, startsWith('# Doc'));
      },
    );

    test(
      'is idempotent — running twice with the same block is a no-op diff',
      () {
        const markdown =
            '# Doc\n\n$kStyleTableBeginMarker\n\nstale\n\n'
            '$kStyleTableEndMarker\n';
        final once = replaceMarkedSection(markdown, 'fresh')!;
        final twice = replaceMarkedSection(once, 'fresh')!;
        expect(twice, once);
      },
    );
  });

  group('real CoreXxxStyle source files parse without crashing', () {
    // Gate: this tool is only useful if it can actually read the contract
    // files it is meant to summarize. A parser that silently stops working
    // on real code (vs. the fixtures above) is worse than none — nobody
    // notices a markdown table stopped updating.
    final contractsDir = Directory(
      'packages/coui_core/lib/src/component/contracts',
    );
    if (!contractsDir.existsSync()) return;

    final slugs = contractsDir
        .listSync()
        .whereType<Directory>()
        .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .where(
          (name) => File(
            '${contractsDir.path}/$name/${name}_style.dart',
          ).existsSync(),
        )
        .toList();

    test('parses at least 80% of real *_style.dart files without throwing', () {
      var withFields = 0;
      for (final name in slugs) {
        final file = File('${contractsDir.path}/$name/${name}_style.dart');
        final result = parseStyleFile(file.readAsStringSync());
        if (result != null && result.fields.isNotEmpty) withFields++;
      }
      expect(
        withFields / slugs.length,
        greaterThanOrEqualTo(0.8),
        reason:
            'Only $withFields/${slugs.length} real style files yielded a '
            'non-empty field list — the regex-based parser has likely '
            'drifted from the real CoreXxxStyle shape.',
      );
    });

    test(
      'no real field description leaks tracker metadata into generated tables',
      () {
        final trackerMeta = RegExp(
          r'(?:Epic|Story|Issue|PR|RFC)\s*#\s*\d+|Phase\s+\d+[a-z]?',
        );
        final offenders = <String>[];
        for (final name in slugs) {
          final file = File('${contractsDir.path}/$name/${name}_style.dart');
          final result = parseStyleFile(file.readAsStringSync());
          if (result == null) continue;
          for (final field in result.fields) {
            if (field.description != null &&
                trackerMeta.hasMatch(field.description!)) {
              offenders.add('$name.${field.name}');
            }
          }
        }
        expect(
          offenders,
          isEmpty,
          reason:
              'Generated field descriptions still contain tracker '
              'metadata: ${offenders.join(", ")} — '
              'docs_api_sync_test.dart will reject these.',
        );
      },
    );

    test(
      'card/button/badge/checkbox/alert/chip — representative variety — parse with fields',
      () {
        for (final slug in [
          'card',
          'button',
          'badge',
          'checkbox',
          'alert',
          'chip',
        ]) {
          if (!slugs.contains(slug)) continue;
          final file = File('${contractsDir.path}/$slug/${slug}_style.dart');
          final result = parseStyleFile(file.readAsStringSync());
          expect(result, isNotNull, reason: '$slug should parse');
          expect(
            result!.fields,
            isNotEmpty,
            reason: '$slug should have fields',
          );
        }
      },
    );
  });

  group('docs_core/content/components — generated tables are not stale', () {
    // CI gate: every doc that has opted in (STYLE_TABLE markers present) is
    // regenerated straight from its CoreXxxStyle source, and the result is
    // committed already. If this test fails, someone edited the
    // CoreXxxStyle source or hand-edited inside the markers without
    // re-running `dart run tool/generate_style_tables.dart --write`.
    final contractsDir = Directory(
      'packages/coui_core/lib/src/component/contracts',
    );
    final docsDirs = [
      Directory('docs_core/content/components'),
      Directory('docs_core/content/blocks'),
    ];
    if (!contractsDir.existsSync() || !docsDirs.first.existsSync()) return;

    final driftedSlugs = <String>[];
    var optedIn = 0;
    for (final docsDir in docsDirs) {
      if (!docsDir.existsSync()) continue;
      for (final docFile in docsDir.listSync().whereType<File>()) {
        if (!docFile.path.endsWith('.md')) continue;
        final slug = docFile.uri.pathSegments.last.replaceAll('.md', '');
        final underscored = slug.replaceAll('-', '_');
        final styleFile = File(
          '${contractsDir.path}/$underscored/${underscored}_style.dart',
        );
        if (!styleFile.existsSync()) continue;

        final markdown = docFile.readAsStringSync();
        if (!markdown.contains(kStyleTableBeginMarker)) {
          continue; // Not opted in.
        }
        optedIn++;

        final parsed = parseStyleFile(styleFile.readAsStringSync());
        if (parsed == null || parsed.fields.isEmpty) continue;
        final generated = buildGeneratedBlock(parsed);
        final replaced = replaceMarkedSection(markdown, generated);
        if (replaced != markdown) driftedSlugs.add(slug);
      }
    }

    test('at least one doc has opted into the marker convention', () {
      // Guards against this whole gate silently checking zero files if the
      // marker text ever changes without updating both sides.
      expect(optedIn, greaterThan(0));
    });

    test('no opted-in doc is stale relative to its CoreXxxStyle source', () {
      expect(
        driftedSlugs,
        isEmpty,
        reason:
            'Run `dart run tool/generate_style_tables.dart --write '
            '${driftedSlugs.join(" ")}` and commit the result.',
      );
    });
  });
}
