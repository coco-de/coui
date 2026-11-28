import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../src/normalize/css_value_parsers.dart';
import '../../src/web/computed_style_probe.dart';

// Exercise the exported production sampler, including its actual chrome walk.
// This CSSOM surrogate tests ownership/predicate logic, not browser rendering.
Future<void> _observe(
  String shadow, {
  required bool childPaint,
  String fill = 'rgba(0, 0, 0, 0)',
  int childCount = 1,
  bool noChrome = false,
}) async {
  final script =
      '''
const assert = require('node:assert/strict');
function element(children=[]) {
  const node={nodeType:1,tagName:'DIV',children,childNodes:children,style:{},
    getAttribute:()=>null,hasAttribute:()=>false,
    querySelectorAll:()=>[],getBoundingClientRect:()=>({width:123,height:75})};
  node.classList=[];node.classList.contains=()=>false;
  for(const child of children) child.parentElement=node;
  return node;
}
'''
      'const childCount=$childCount;\n'
      '''
const child=element(),root=element(childCount===1?[child]:[child,element()]);
global.NodeFilter={SHOW_TEXT:4};
global.document={querySelector:()=>root,styleSheets:[],
  createTreeWalker:()=>({nextNode:()=>null})};
'''
      'const shadow=${jsonEncode(shadow)};\n'
      'const fill=${jsonEncode(fill)};\n'
      '''
global.getComputedStyle=node=>({display:'block',visibility:'visible',position:'static',
  clip:'auto',overflowX:'visible',overflowY:'visible',
  backgroundColor:node===root?fill:'rgb(12, 34, 56)',
  borderTopWidth:'0px',borderRightWidth:'0px',borderBottomWidth:'0px',borderLeftWidth:'0px',
  borderTopColor:'rgba(0, 0, 0, 0)',borderRightColor:'rgba(0, 0, 0, 0)',
  borderBottomColor:'rgba(0, 0, 0, 0)',borderLeftColor:'rgba(0, 0, 0, 0)',
  borderTopLeftRadius:node===root?'9999px':'7px',
  borderTopRightRadius:node===root?'9999px':'7px',
  borderBottomRightRadius:node===root?'9999px':'7px',
  borderBottomLeftRadius:node===root?'9999px':'7px',
  paddingTop:node===root?'91px':'3px',paddingRight:'4px',paddingBottom:'5px',paddingLeft:'6px',
  outlineWidth:'2px',outlineStyle:'solid',outlineColor:'rgba(64, 65, 67, 0)',outlineOffset:'2px',
  boxShadow:node===root?shadow:'none',opacity:node===root?'0.65':'1'});
'''
      'const sample=($computedStyleProbeScript);\n'
      'const childPaint=$childPaint;\n'
      'const noChrome=$noChrome;\n'
      '''
const value=JSON.parse(sample('#root'));
assert.equal(value.backgroundColor,noChrome?'rgba(0, 0, 0, 0)':childPaint?'rgb(12, 34, 56)':fill);
assert.equal(value.borderTopLeftRadius,noChrome?'0px':childPaint?'7px':'9999px');
assert.equal(value.paddingTop,noChrome?'0px':childPaint?'3px':'91px');
assert.equal(value.boxShadow,noChrome||childPaint?'none':shadow);
// Paint lookup never changes the original root geometry or opacity owner.
assert.equal(value.widthPx,123);assert.equal(value.heightPx,75);assert.equal(value.opacity,'0.65');
console.log(JSON.stringify({passed:true}));
''';
  final directory = await Directory.systemTemp.createTemp('chrome-shadow-');
  try {
    final file = File('${directory.path}/probe.cjs');
    await file.writeAsString(script);
    final result = await Process.run(
      Platform.environment['PARITY_NODE'] ?? 'node',
      [file.path],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(jsonDecode((result.stdout as String).trim()), {'passed': true});
  } finally {
    await directory.delete(recursive: true);
  }
}

void main() {
  const transparentColors = [
    'rgba(255, 255, 255, 0)',
    'rgba(22, 23, 24, 0)',
    'rgb(255 255 255 / 0)',
    'rgba(10%, 20%, 30%, 0%)',
    'rgb(10% 20% 30% / 0%)',
    'hsl(30deg 20% 30% / 0%)',
    'color(display-p3 1 0.5 0 / 0)',
    'oklch(60% 0.2 30 / 0%)',
    'transparent',
  ];
  for (final color in transparentColors) {
    test('fully transparent $color does not own chrome', () async {
      // Match the existing parser's alpha contract without RGB conversion.
      expect(cssColorIsFullyTransparent(color), isTrue);
      await _observe('$color 0px 0px 0px 2px', childPaint: true);
    });
  }
  test('none retains the existing child chrome route', () {
    return _observe('none', childPaint: true);
  });
  test('transparent inset and comma-separated shadows do not own chrome', () {
    return _observe(
      'inset rgba(255, 255, 255, 0) 0px 0px 3px 2px, '
      '0px 0px 4px 1px rgb(0 0 0 / 0%)',
      childPaint: true,
    );
  });
  test('a real fill still owns chrome with transparent shadows', () {
    return _observe(
      'rgba(0, 0, 0, 0) 0px 0px 3px 2px',
      fill: 'rgb(91, 82, 73)',
      childPaint: false,
    );
  });
  test('the existing modern fill predicate remains unchanged', () {
    return _observe('none', fill: 'rgb(0 0 0 / 0)', childPaint: false);
  });
  test('two genuine child chrome branches remain ambiguous', () {
    return _observe(
      'rgba(0, 0, 0, 0) 0px 0px 3px 2px',
      childPaint: false,
      childCount: 2,
      noChrome: true,
    );
  });
  const paintedOrUnknown = [
    'rgba(0, 0, 0, 0.0004) 0px 0px 3px 2px',
    'rgb(0 0 0 / 0.01%) 0px 0px 3px 2px',
    'rgb(0 0 0 / 1e-999) 0px 0px 3px 2px',
    'inset rgb(0, 0, 0) 0px 0px 3px 2px',
    'rgba(0, 0, 0, 0) 0px 0px 3px, rgb(0 0 0 / 1) 0px 0px 4px',
    'rgb(0 0 0 / 1) 0px 0px 4px, rgba(0, 0, 0, 0) 0px 0px 3px',
    'color(unknown-space 0 0 0 / 0) 0px 0px 3px',
    'var(--unknown-shadow-color) 0px 0px 3px',
    'rgb(0 0 0 / invalid) 0px 0px 3px',
    'rgba(0, 0, 0, 0) unresolved-length 0px 3px',
    '0px 0px 3px',
  ];
  for (final shadow in paintedOrUnknown) {
    test('real or unresolved paint is retained: $shadow', () {
      return _observe(shadow, childPaint: false);
    });
  }
}
