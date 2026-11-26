import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../src/web/box_padding_text_field_units_probe.dart';

void main() {
  Map<String, Object?> observe(Map<String, Object?> options) {
    final script =
        '''
const options = ${jsonEncode(options)};
const connected = options.connected !== false;
const input = {tagName:'INPUT',isConnected:connected};
const before = options.leading === true ? [{tagName:'SPAN'}] : [];
const after = options.trailing === true ? [{tagName:'BUTTON'}] : [];
const wrapper = {tagName:'DIV',isConnected:connected,children:[...before,input,...after]};
input.parentElement = wrapper;
if (options.duplicateInput) wrapper.children.push({tagName:'INPUT'});
if (options.wrongParent) input.parentElement = {};
const css = values => ({display:options.display || 'block',paddingTop:values[0],paddingRight:values[1],paddingBottom:values[2],paddingLeft:values[3]});
globalThis.getComputedStyle = node => css(node === wrapper ? options.outer : options.inner);
const binding = {fieldUnitElement:wrapper,paddingSource:wrapper,frameSource:wrapper,
  complementaryPaddingSources:{kind:'text-field-wrapper-input-v1',wrapper,input,
    leadingAffixed:options.leading === true,trailingAffixed:options.trailing === true}};
if (options.wrongPart) binding.complementaryPaddingSources.wrapper = input;
if (options.wrongFlags) binding.complementaryPaddingSources.leadingAffixed = !binding.complementaryPaddingSources.leadingAffixed;
console.log(JSON.stringify(($textFieldComplementaryPaddingScript)(binding)));
''';
    final result = Process.runSync('node', ['-e', script]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
  }

  Map<String, Object?> options({bool leading = false, bool trailing = false}) =>
      {
        'leading': leading,
        'trailing': trailing,
        'outer': [
          '7.25px',
          if (trailing) '19px' else '0px',
          '11.5px',
          if (leading) '13px' else '0px',
        ],
        'inner': [
          '0px',
          if (trailing) '0px' else '19px',
          '0px',
          if (leading) '0px' else '13px',
        ],
      };

  for (final leading in [false, true]) {
    for (final trailing in [false, true]) {
      test('actual complementary parameters, affixes $leading/$trailing', () {
        final result = observe(options(leading: leading, trailing: trailing));
        expect(result['error'], isNull);
        expect(result['value'], [7.25, 19, 11.5, 13]);
        expect(result['rawCssParts'], hasLength(2));
        expect(
          result['quantityDerivation'],
          'source-complementary-wrapper-input-v1',
        );
      });
    }
  }

  test('all-zero own padding remains an observed allocation', () {
    final result = observe({
      ...options(leading: true, trailing: true),
      'outer': ['0px', '0px', '0px', '0px'],
      'inner': ['0px', '0px', '0px', '0px'],
    });
    expect(result['value'], [0, 0, 0, 0]);
  });

  for (final mutation in [
    'wrongParent',
    'wrongPart',
    'duplicateInput',
    'wrongFlags',
  ]) {
    test('changed source ownership is rejected: $mutation', () {
      expect(observe({...options(), mutation: true})['error'], isNotNull);
    });
  }

  test('overlapping own-side and vertical allocations are rejected', () {
    expect(
      observe({
        ...options(),
        'outer': ['7px', '1px', '11px', '0px'],
      })['error'],
      'TEXT_FIELD_COMPLEMENTARY_ALLOCATION_CHANGED',
    );
    expect(
      observe({
        ...options(leading: true),
        'inner': ['0px', '19px', '0px', '1px'],
      })['error'],
      'TEXT_FIELD_COMPLEMENTARY_ALLOCATION_CHANGED',
    );
    expect(
      observe({
        ...options(),
        'inner': ['1px', '19px', '0px', '13px'],
      })['error'],
      'TEXT_FIELD_COMPLEMENTARY_ALLOCATION_CHANGED',
    );
  });

  test('missing layout boxes and unresolved parameter units are rejected', () {
    expect(observe({...options(), 'connected': false})['error'], isNotNull);
    expect(
      observe({...options(), 'display': 'contents'})['error'],
      'NO_DECLARED_LAYOUT_BOX',
    );
    expect(
      observe({
        ...options(),
        'inner': ['0px', 'auto', '0px', '13px'],
      })['error'],
      'UNRESOLVED_CSS_PADDING_UNIT',
    );
  });
}
