import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/web_capture_backend.dart';

Map<String, Object?> _tree(dom.Element element, List<int> path) => {
  'tagName': element.localName!.toUpperCase(),
  'attributes': {
    for (final entry in element.attributes.entries)
      entry.key.toString(): entry.value,
  },
  'path': path,
  'children': [
    for (var i = 0; i < element.children.length; i++)
      _tree(element.children[i], [...path, i]),
  ],
};

void main() {
  const recipes = <String, List<String>>{
    'banner': [
      'default',
      'info',
      'warning',
      'destructive',
      'success',
      'solid',
      'narrow',
    ],
    'description-card': [
      'default',
      'filled',
      'ghost',
      'vertical',
      'space-between',
      'placeholder',
    ],
    'formatted-input': [
      'default',
      'korean-phone',
      'credit-card',
      'date',
      'verify',
    ],
    'frame': ['default', 'column', 'dashed', 'elevated'],
  };
  for (final family in recipes.entries) {
    test('${family.key} does not grant an unaudited variant a source unit', () {
      final probe = captureProbes(
        key: 'unknown',
        component: family.key,
        variant: 'unaudited-source',
        flutterClassName: 'sanity-only',
      ).single;
      expect(probe.boxObservationSource, isNull);
      expect(probe.fields, isNotEmpty);
    });
    for (final variant in family.value) {
      for (final theme in ParityTheme.values) {
        test(
          '${family.key}/$variant/${theme.name} SSR dispatches its actual frame',
          () async {
            final key = '${family.key}-$variant-${theme.name}-defaultStyle';
            final probe = captureProbes(
              key: key,
              component: family.key,
              variant: variant,
              flutterClassName: 'sanity-only',
            ).single;
            final body = await renderCaptureBodyHtml(
              MatrixEntry(
                component: family.key,
                variant: variant,
                theme: theme,
                surfaceStyle: .defaultId,
                tier: ParityTier.t1,
                probes: [probe],
              ),
            );
            final captures = html
                .parseFragment(body)
                .querySelectorAll('[data-parity-key]');
            expect(captures, hasLength(1));
            expect(captures.single.attributes['data-parity-key'], key);
            expect(captures.single.children, hasLength(1));
            // The real sampler consumes actual SSR references. This CSS shim
            // only identifies the DOM owner read, not browser paint.
            final result = await Process.run('node', [
              '-e',
              '''
const observe=($boxPaddingObservationScript);
const node=(data,parent=null)=>{
  const attrs=data.attributes,names=(attrs.class??'').split(/\\s+/);names.contains=name=>names.includes(name);
  const value={tagName:data.tagName,classList:names,path:data.path,isConnected:true,parentElement:parent,
    getAttribute:name=>attrs[name]??null,hasAttribute:name=>Object.hasOwn(attrs,name)};
  value.children=data.children.map(child=>node(child,value));
  value.contains=other=>value===other||value.children.some(child=>child.contains(other));
  return value;
};
const capture=node(${jsonEncode(_tree(captures.single, const []))}),root=capture.children[0],cssOwners=[];
global.document={querySelectorAll:()=>[root]};
global.getComputedStyle=owner=>{cssOwners.push(owner.path);return {display:'block',paddingTop:'1px',paddingRight:'2px',paddingBottom:'3px',paddingLeft:'4px'};};
const actual=JSON.parse(observe({requested:true,selector:${jsonEncode(probe.webSelector)},layoutSelector:${jsonEncode(probe.webSelector)},source:${jsonEncode(probe.boxObservationSource!.toJson())}}));
console.log(JSON.stringify({actual,cssOwners}));
''',
            ]);
            expect(result.exitCode, 0, reason: '${result.stderr}');
            final output = jsonDecode(result.stdout.toString()) as Map;
            final actual = output['actual']! as Map;
            expect(actual['status'], 'source-complete', reason: '$actual');
            expect(actual['source'], probe.boxObservationSource!.toJson());
            expect(actual['canonicalComparisonEligible'], isFalse);
            expect(output['cssOwners'], [
              if (family.key == 'banner' && variant == 'narrow')
                [0, 0]
              else
                [0],
            ]);
          },
        );
      }
    }
  }
}
