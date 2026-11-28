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
  const recipes = <({String component, String variant, int depth})>[
    (component: 'code-diff', variant: 'default', depth: 2),
    (component: 'command', variant: 'default', depth: 1),
    (component: 'command', variant: 'scrollable', depth: 1),
    (component: 'command', variant: 'empty', depth: 1),
    (component: 'fieldset', variant: 'default', depth: 2),
    (component: 'fieldset', variant: 'outlined', depth: 2),
    (component: 'fieldset', variant: 'plain', depth: 2),
    (component: 'item-picker', variant: 'default', depth: 1),
    (component: 'mockup-browser', variant: 'default', depth: 3),
    (component: 'object-input', variant: 'default', depth: 1),
  ];
  for (final recipe in recipes) {
    for (final theme in ParityTheme.values) {
      test(
        '${recipe.component}/${recipe.variant}/${theme.name} dispatches the actual SSR frame',
        () async {
          final key =
              '${recipe.component}-${recipe.variant}-'
              '${theme.name}-defaultStyle';
          final probe = captureProbes(
            key: key,
            component: recipe.component,
            variant: recipe.variant,
            flutterClassName: 'sanity-only',
          ).single;
          final entry = MatrixEntry(
            component: recipe.component,
            variant: recipe.variant,
            theme: theme,
            surfaceStyle: .defaultId,
            tier: ParityTier.t1,
            probes: [probe],
          );
          final body = await renderCaptureBodyHtml(entry);
          final fragment = html.parseFragment(body);
          final captures = fragment.querySelectorAll('[data-parity-key]');
          expect(captures, hasLength(1));
          expect(captures.single.attributes['data-parity-key'], key);
          expect(captures.single.children, hasLength(1));
          // Actual emitted DOM structure is consumed by the real pure sampler.
          // The CSS shim only records which reference is read; this is not a
          // browser/computed-style or paint assertion.
          final nodeProgram =
              '''
const observe = ($boxPaddingObservationScript);
const node = (data,parent=null) => {
  const attrs=data.attributes, names=(attrs.class ?? '').split(/\\s+/);
  names.contains=name=>names.includes(name);
  const value={tagName:data.tagName,classList:names,path:data.path,isConnected:true,parentElement:parent,
    getAttribute:name=>attrs[name] ?? null,hasAttribute:name=>Object.hasOwn(attrs,name)};
  value.children=data.children.map(child=>node(child,value));
  value.contains=other=>value.children.some(child=>child===other || child.contains(other));
  return value;
};
const capture=node(${jsonEncode(_tree(captures.single, const []))});
const root=capture.children[0], cssOwners=[];
global.document={querySelectorAll:selector=>selector===${jsonEncode(probe.webSelector)} ? [root] : []};
global.getComputedStyle=owner=>{cssOwners.push(owner.path);return {display:'block',paddingTop:'1px',paddingRight:'2px',paddingBottom:'3px',paddingLeft:'4px'};};
const actual=JSON.parse(observe({requested:true,selector:${jsonEncode(probe.webSelector)},layoutSelector:${jsonEncode(probe.webSelector)},source:${jsonEncode(probe.boxObservationSource!.toJson())}}));
console.log(JSON.stringify({actual,cssOwners}));
''';
          final directory = await Directory.systemTemp.createTemp(
            'coui-parity-node-',
          );
          late final ProcessResult result;
          try {
            final file = File('${directory.path}/probe.cjs');
            await file.writeAsString(nodeProgram);
            result = await Process.run('node', [file.path]);
          } finally {
            await directory.delete(recursive: true);
          }
          expect(result.exitCode, 0, reason: result.stderr.toString());
          final data = jsonDecode(result.stdout.toString()) as Map;
          final actual = data['actual']! as Map;
          expect(actual['status'], 'source-complete');
          expect(actual['source'], probe.boxObservationSource!.toJson());
          expect(actual['canonicalComparisonEligible'], isFalse);
          expect(data['cssOwners'], [List<int>.filled(recipe.depth, 0)]);
          expect(actual['ownerIsLayoutRoot'], recipe.depth == 1);
        },
      );
    }
  }
}
