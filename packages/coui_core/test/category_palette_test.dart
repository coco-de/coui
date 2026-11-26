// CoreCategoryPalette — the category colour table (redesign #5471,
// revision 2). The expected tables below are pasted from the spec, not read
// from the library, so a typo on either side fails here.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

/// Spec 1-1: the nine hues, in the spec's column order.
const _hues = [
  'red',
  'orange',
  'yellow',
  'green',
  'blue',
  'purple',
  'pink',
  'brown',
  'gray',
];

/// Spec 1-4 (revision 2): role → hex per hue, columns in [_hues] order.
const _spec14 = <String, List<String>>{
  'light-fill': [
    'E35B57',
    'D86810',
    'B07E21',
    '129C4A',
    '3488EC',
    '9E70E3',
    'D75C9D',
    'B5795E',
    '7E848A',
  ],
  'light-container': [
    'FEDEDA',
    'FEDFCE',
    'F5E4C7',
    'D3EFD9',
    'D7E8FE',
    'EAE1FE',
    'FDDBEA',
    'F4E2DA',
    'E4E6E7',
  ],
  'light-on-container': [
    '822B2A',
    '773A08',
    '644708',
    '0B5D2E',
    '154D8C',
    '583A84',
    '7A2B56',
    '6D402C',
    '3C4249',
  ],
  'dark-fill': [
    'BC4945',
    'B2540B',
    '93670B',
    '0D803B',
    '266FC4',
    '825BBD',
    'B34981',
    '96634C',
    '676D74',
  ],
  'dark-container': [
    '44211E',
    '422410',
    '3B2906',
    '14341F',
    '192D47',
    '312644',
    '412030',
    '392820',
    '2C2F33',
  ],
  'dark-on-container': [
    'FDA19A',
    'FDA573',
    'F5AF20',
    '66DA85',
    '92C1FD',
    'C9ADFD',
    'FD99CA',
    'EFAC8D',
    'C4C7CB',
  ],
  'dark-outline': [
    '753935',
    '713E1C',
    '644708',
    '225A35',
    '2B4E7A',
    '544174',
    '6F3854',
    '624539',
    '4B4F54',
  ],
  'hc-light-fill': [
    'A12F2F',
    '8F4207',
    '765107',
    '08662E',
    '0757A9',
    '6B43A3',
    '973069',
    '804B33',
    '54595F',
  ],
  'hc-light-on-container': [
    '832C2A',
    '793705',
    '634405',
    '065726',
    '124A8A',
    '583A84',
    '7A2B56',
    '69402E',
    '464A4F',
  ],
  'hc-dark-fill': [
    'FEB1AA',
    'FDB48B',
    'FBB841',
    '70DA8A',
    '9CC7FD',
    'D0B9FD',
    'FEACD2',
    'F4B79C',
    'BFC5CC',
  ],
  'hc-dark-container': [
    '361715',
    '341A09',
    '2F1E01',
    '0D2814',
    '102239',
    '251C36',
    '331725',
    '2C1E18',
    '1F2226',
  ],
  'hc-dark-on-container': [
    'F1A79F',
    'EDAC88',
    'DDB67A',
    '97D1A1',
    '97C1F7',
    'C6B1F0',
    'EAA5C5',
    'D8B4A3',
    'C4C7CB',
  ],
  'hc-dark-outline': [
    'D25C57',
    'C96621',
    'A87820',
    '23944A',
    '3B83D9',
    '946ED2',
    'C75C92',
    'AB745A',
    '7D8288',
  ],
};

/// Spec 1-3: slot → the tone it reads per mode, in [_modes] order. `null`
/// is the mapping's own white or black.
const _spec13 = <String, List<String?>>{
  'fill': ['light-fill', 'dark-fill', 'hc-light-fill', 'hc-dark-fill'],
  'onFill': [null, null, null, null],
  'container': [
    'light-container',
    'dark-container',
    'light-container',
    'hc-dark-container',
  ],
  'onContainer': [
    'light-on-container',
    'dark-on-container',
    'hc-light-on-container',
    'hc-dark-on-container',
  ],
  'outline': [
    'light-container',
    'dark-outline',
    'hc-light-fill',
    'hc-dark-outline',
  ],
};

/// Light, Dark, HCLight, HCDark — the spec's column order.
const _modes = <(CoreBrightness, bool)>[
  (.light, false),
  (.dark, false),
  (.light, true),
  (.dark, true),
];
const _modeNames = ['Light', 'Dark', 'HCLight', 'HCDark'];

String _hex(CoreColor color) =>
    color.argb.toRadixString(16).padLeft(8, '0').toUpperCase();

CoreCategoryTone _toneKeyed(String key) =>
    CoreCategoryTone.values.singleWhere((tone) => tone.key == key);

void main() {
  group('values (spec 1-4, revision 2)', () {
    test("the hues are the spec's nine, in its column order", () {
      expect(CoreCategoryColor.values.map((color) => color.name), _hues);
    });

    test("the tones are the spec's thirteen roles, in its row order", () {
      expect(CoreCategoryTone.values.map((tone) => tone.key), _spec14.keys);
    });

    test('every one of the 117 values equals the spec table', () {
      var checked = 0;
      for (final MapEntry(key: role, value: row) in _spec14.entries) {
        expect(row, hasLength(_hues.length), reason: role);
        final tone = _toneKeyed(role);
        for (final (index, hue) in _hues.indexed) {
          final value = CoreCategoryPalette.tone(
            CoreCategoryColor.values.byName(hue),
            tone,
          );
          // A raw value, not a token: the table is the bottom of the chain.
          expect(value.token, isNull, reason: '$hue $role');
          expect(_hex(value), 'FF${row[index]}', reason: '$hue $role');
          checked++;
        }
      }
      expect(checked, 117);
    });
  });

  group('CoreCategorySlot.toneIn (spec 1-3)', () {
    test('every slot × mode cell equals the spec table', () {
      expect(
        CoreCategorySlot.values.map((slot) => slot.name),
        _spec13.keys,
      );
      for (final slot in CoreCategorySlot.values) {
        final expected = _spec13[slot.name]!;
        for (final (index, (brightness, highContrast)) in _modes.indexed) {
          expect(
            slot.toneIn(brightness, highContrast: highContrast)?.key,
            expected[index],
            reason: '${slot.name} in ${_modeNames[index]}',
          );
        }
      }
    });

    test('onFill reads no category tone in any mode', () {
      for (final (brightness, highContrast) in _modes) {
        expect(
          CoreCategorySlot.onFill.toneIn(
            brightness,
            highContrast: highContrast,
          ),
          isNull,
        );
      }
    });
  });

  group('CoreCategorySlot.cssName', () {
    test('names the five slots of every hue as spec 1-3 does', () {
      for (final hue in _hues) {
        final color = CoreCategoryColor.values.byName(hue);
        expect(
          [for (final slot in CoreCategorySlot.values) slot.cssName(color)],
          [
            'category-$hue',
            'on-category-$hue',
            'category-$hue-container',
            'on-category-$hue-container',
            'category-$hue-outline',
          ],
        );
      }
    });
  });

  group('CoreCategoryPalette.primitives', () {
    final primitives = CoreCategoryPalette.primitives;

    test("has 117 names, hue by hue, each hue's tones in table order", () {
      expect(primitives.keys.toList(), [
        for (final hue in _hues)
          for (final role in _spec14.keys) 'category/$hue/$role',
      ]);
    });

    test('every name is three segments under the brand-less namespace', () {
      expect(CoreCategoryPalette.namespace, 'category');
      for (final name in primitives.keys) {
        final segments = name.split('/');
        expect(segments, hasLength(3), reason: name);
        expect(segments.first, CoreCategoryPalette.namespace, reason: name);
      }
    });

    test('never joins a hue and a role into one dash-separated segment', () {
      for (final hue in _hues) {
        for (final role in _spec14.keys) {
          expect(
            primitives.keys.where((name) => name.contains('$hue-$role')),
            isEmpty,
          );
        }
      }
    });

    test('maps every name to its table value', () {
      for (final color in CoreCategoryColor.values) {
        for (final tone in CoreCategoryTone.values) {
          expect(
            primitives[CoreCategoryPalette.primitiveName(color, tone)],
            CoreCategoryPalette.tone(color, tone),
          );
        }
      }
    });

    test('stays out of every brand vocabulary', () {
      // The brand vocabularies are pinned to 67 (CoUI) and 64 (generated)
      // unique values; gray's tones would collide with CoUI's neutrals.
      for (final source in <CoreSchemeSource>[
        CouiColorPresets.source,
        kBrandFixtureSource,
      ]) {
        expect(
          source.primitives.keys.where((name) => name.startsWith('category')),
          isEmpty,
        );
      }
    });
  });

  group('the intentional duplicates', () {
    // The table is linked by name, so equal cells are harmless. Folding one
    // into the other would make a role read another role's primitive.
    CoreColor value(String hue, CoreCategoryTone tone) =>
        CoreCategoryPalette.tone(CoreCategoryColor.values.byName(hue), tone);

    test('yellow light-on-container equals its dark-outline', () {
      expect(
        value('yellow', .lightOnContainer).argb,
        value('yellow', .darkOutline).argb,
      );
    });

    test('purple and pink light-on-container equal hc-light-on-container', () {
      for (final hue in ['purple', 'pink']) {
        expect(
          value(hue, .lightOnContainer).argb,
          value(hue, .hcLightOnContainer).argb,
          reason: hue,
        );
      }
    });

    test('gray dark-on-container equals hc-dark-on-container', () {
      expect(
        value('gray', .darkOnContainer).argb,
        value('gray', .hcDarkOnContainer).argb,
      );
    });

    test('gray light container equals CoUI neutral/200', () {
      // Gray's other tones were taken from the earlier, cooler neutral and
      // were kept when that ramp went achromatic (#6135) — its
      // light-on-container no longer matches `neutral/800`.
      final neutrals = CouiColorPresets.palette.primitives;
      expect(
        value('gray', .lightContainer).argb,
        neutrals['neutral/200']!.argb,
      );
      expect(
        value('gray', .lightOnContainer).argb,
        isNot(neutrals['neutral/800']!.argb),
      );
    });
  });

  group('CoreCategoryPalette.primitiveLinks', () {
    final links = [
      for (final (brightness, highContrast) in _modes)
        CoreCategoryPalette.primitiveLinks(
          brightness,
          highContrast: highContrast,
        ),
    ];

    test('has 36 links per mode, the same names in every mode', () {
      for (final (index, modeLinks) in links.indexed) {
        expect(modeLinks, hasLength(36), reason: _modeNames[index]);
        expect(
          modeLinks.keys.toSet(),
          links.first.keys.toSet(),
          reason: _modeNames[index],
        );
      }
    });

    test('links no on-category name but the container text', () {
      for (final name in links.first.keys) {
        if (name.startsWith('on-category-')) {
          expect(name, endsWith('-container'));
        }
      }
    });

    test('links every slot to the tone spec 1-3 names', () {
      for (final (index, modeLinks) in links.indexed) {
        for (final hue in _hues) {
          final color = CoreCategoryColor.values.byName(hue);
          for (final slot in CoreCategorySlot.values) {
            final role = _spec13[slot.name]![index];
            expect(
              modeLinks[slot.cssName(color)],
              role == null ? null : 'category/$hue/$role',
              reason: '${slot.cssName(color)} in ${_modeNames[index]}',
            );
          }
        }
      }
    });

    test('points every link at a primitive, all 117 across the modes', () {
      final names = CoreCategoryPalette.primitives.keys.toSet();
      final reached = <String>{};
      for (final modeLinks in links) {
        // Two slots may share a tone (Light container and outline).
        expect(modeLinks.values, everyElement(isIn(names)));
        reached.addAll(modeLinks.values);
      }
      expect(reached, names);
    });
  });

  group('CoreCategoryPalette.valueOf', () {
    // Off by one, so a hard-coded white or black would not pass.
    const white = CoreColor(0xFFFFFFFE);
    const black = CoreColor(0xFF000001);

    test('onFill is the given white, and black only in HCDark', () {
      for (final (index, (brightness, highContrast)) in _modes.indexed) {
        for (final color in CoreCategoryColor.values) {
          expect(
            CoreCategoryPalette.valueOf(
              color,
              .onFill,
              brightness,
              highContrast: highContrast,
              white: white,
              black: black,
            ),
            index == 3 ? black : white,
            reason: '${color.name} in ${_modeNames[index]}',
          );
        }
      }
    });

    test('every other slot is the tone it reads', () {
      for (final (brightness, highContrast) in _modes) {
        for (final color in CoreCategoryColor.values) {
          for (final slot in CoreCategorySlot.values) {
            final tone = slot.toneIn(brightness, highContrast: highContrast);
            if (tone == null) continue;
            expect(
              CoreCategoryPalette.valueOf(
                color,
                slot,
                brightness,
                highContrast: highContrast,
                white: white,
                black: black,
              ),
              CoreCategoryPalette.tone(color, tone),
            );
          }
        }
      }
    });
  });

  group('spec 5: high-contrast dark coloured text', () {
    // Coloured text is onContainer on the page. High contrast must not
    // read weaker than the normal dark mode it raises — the contrast gate
    // checks each pair against a floor and cannot state this relation.
    final pages = {
      'CoUI dark page': CouiColorPresets.source.dark().surface!,
      'generated brand dark page': kBrandFixtureSource.dark().surface!,
    };

    for (final MapEntry(key: pageName, value: page) in pages.entries) {
      test('hc-dark-on-container ≥ dark-on-container on the $pageName', () {
        for (final color in CoreCategoryColor.values) {
          final raised = CoreContrast.ratio(
            CoreCategoryPalette.tone(color, .hcDarkOnContainer),
            page,
          );
          final normal = CoreContrast.ratio(
            CoreCategoryPalette.tone(color, .darkOnContainer),
            page,
          );
          expect(
            raised,
            greaterThanOrEqualTo(normal),
            reason:
                '${color.name}: ${raised.toStringAsFixed(3)} vs '
                '${normal.toStringAsFixed(3)}',
          );
        }
      });
    }
  });
}
