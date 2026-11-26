import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_proxy_host_units_probe.dart';
import '../../src/web/box_padding_validation_viewport_units_probe.dart';
import '../../src/web/ssr_render.dart';
import '../../src/web/web_capture_backend.dart';

const _recipes = <({String component, String variant})>[
  (component: 'formatter', variant: 'default'),
  (component: 'validated', variant: 'default'),
  (component: 'validator-hint', variant: 'default'),
  (component: 'scroll-area', variant: 'default'),
  (component: 'fade-scroll', variant: 'default'),
  (component: 'fade-scroll', variant: 'horizontal'),
  (component: 'fade-scroll', variant: 'with-scrollbar'),
  (component: 'overflow-marquee', variant: 'default'),
  (component: 'hover', variant: 'shadow'),
  (component: 'kbd', variant: 'default'),
  (component: 'kbd', variant: 'combo'),
  (component: 'kbd', variant: 'four'),
];
BoxObservationSourceSpec _source(String component) => switch (component) {
  'formatter' => BoxObservationSourceSpec.textFieldContentInset,
  'validated' => BoxObservationSourceSpec.validatedLayoutHost,
  'validator-hint' => BoxObservationSourceSpec.validatorHintMessageLayoutHost,
  'scroll-area' => BoxObservationSourceSpec.scrollAreaViewportLayoutHost,
  'fade-scroll' => BoxObservationSourceSpec.fadeScrollViewportLayoutHost,
  'overflow-marquee' =>
    BoxObservationSourceSpec.overflowMarqueeViewportLayoutHost,
  'hover' => BoxObservationSourceSpec.hoverEffectHost,
  _ => BoxObservationSourceSpec.kbdKeySequenceLayoutHost,
};
Map<String, Object?> _tree(dom.Element e, List<int> path) => {
  'tagName': e.localName!.toUpperCase(),
  'attributes': {
    for (final a in e.attributes.entries) a.key.toString(): a.value,
  },
  'textContent': e.text,
  'path': path,
  'children': [
    for (var i = 0; i < e.children.length; i++)
      _tree(e.children[i], [...path, i]),
  ],
};
List<int> _path(dom.Element capture, dom.Element field) {
  final path = <int>[];
  var current = field;
  while (!identical(current, capture)) {
    final parent = current.parent!;
    path.insert(0, parent.children.indexOf(current));
    current = parent;
  }
  return path;
}

dom.Element _field(dom.Element root, String component) => switch (component) {
  'formatter' =>
    root.children.single.children
        .where((e) => e.localName != 'style')
        .single
        .children
        .single,
  'validated' || 'scroll-area' || 'overflow-marquee' => root.children.single,
  'fade-scroll' =>
    (root.classes.contains('relative') ? root : root.children.single).children
        .where((e) => e.localName != 'style')
        .single,
  _ => root,
};
typedef _Actual = ({Map<String, Object?> tree, List<int> field});
final _cache = <String, Future<_Actual>>{};
Future<_Actual> _actual(String component, String variant, String theme) =>
    _cache.putIfAbsent('$component/$variant/$theme', () async {
      final key = '$component-$variant-$theme-defaultStyle';
      final probes = captureProbes(
        key: key,
        component: component,
        variant: variant,
        flutterClassName: 'sanity-only',
      );
      final entry = MatrixEntry.fromJson({
        'component': component,
        'variant': variant,
        'theme': theme,
        'surfaceStyle': 'defaultStyle',
        'tier': 't2',
        'probes': probes.map((p) => p.toJson()).toList(),
      });
      final fragment = html.parseFragment(await renderCaptureBodyHtml(entry));
      final capture = fragment.querySelectorAll('[data-parity-key]').single;
      final root = fragment.querySelectorAll(probes.single.webSelector).single;
      expect(root, same(capture.children.single));
      final field = _field(root, component);
      return (tree: _tree(capture, []), field: _path(capture, field));
    });

const _runtime = r'''
const node=(data,parent=null)=>{
 const attrs={...data.attributes},classes=(attrs.class??'').split(/\s+/).filter(Boolean);
 const e={tagName:data.tagName,path:data.path,attributes:attrs,parentElement:parent,
  textContent:data.textContent??'',isConnected:true,
  getAttribute:n=>attrs[n]??null,hasAttribute:n=>Object.hasOwn(attrs,n),
  classList:{contains:n=>classes.includes(n),[Symbol.iterator]:function*(){yield*classes;}}};
 e._list=data.children.map(c=>node(c,e));
 Object.defineProperty(e,'children',{get:()=>e._list});
 e.contains=other=>e===other || e._list.some(c=>c.contains(other));
 for(const n of ['offsetWidth','offsetHeight','clientWidth','clientHeight'])
  Object.defineProperty(e,n,{get(){throw Error('Numeric owner selection forbidden');}});
 return e;
};
global.document=new Proxy({},{get(){throw Error('Global owner search forbidden');}});
global.getComputedStyle=()=>{throw Error('CSS owner selection forbidden');};
''';
Future<Map<String, Object?>> _resolve(
  Map<String, Object?> tree,
  String component, {
  String mutation = '',
}) async {
  final resolver = component == 'hover'
      ? proxyHostBoxSourceResolverScript
      : validationViewportBoxSourceResolverScript;
  final program =
      '''
$_runtime
const capture=node(${jsonEncode(tree)}),root=capture.children[0];
const source=${jsonEncode(_source(component).toJson())};
const resolve=($resolver);
$mutation
const r=resolve(root,source);
let out=r.error?r:{registry:r.registryResultElement.path,
 field:r.fieldUnitElement.path,padding:r.paddingSource.path,frame:r.frameSource.path,
 hasValue:Object.hasOwn(r,'value'),foreign:(r.foreignSeats??[]).map(n=>n.path)};
if(!r.error && r.complementaryPaddingSources){
 const p=r.complementaryPaddingSources;
 out.complementary={kind:p.kind,wrapper:p.wrapper.path,input:p.input.path,
  leadingAffixed:p.leadingAffixed,trailingAffixed:p.trailingAffixed,
  wrapperStyle:p.wrapper.getAttribute('style'),inputStyle:p.input.getAttribute('style')};
}
console.log(JSON.stringify(out));
''';
  final result = await Process.run('node', ['-e', program]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return (jsonDecode(result.stdout.toString()) as Map).cast<String, Object?>();
}

typedef _AffixFixture = ({Map<String, Object?> tree, String themeCss});
Future<_AffixFixture> _affixFixture(bool leading, bool trailing) async {
  final document = await renderComponentToDocumentHtml(
    coui.Component.fragment([
      coui.Component.element(
        tag: 'style',
        attributes: const {'data-fixture-theme': ''},
        children: [coui.RawText(coui.ThemeConfig.defaults().cssVariables)],
      ),
      coui.CoUIWeb(
        theme: coui.ThemeData.coui,
        child: coui.div(
          [
            coui.div([
              coui.TextField(
                placeholder: const coui.Text('placeholder'),
                prefix: leading
                    ? const coui.div([
                        coui.Text('prefix'),
                      ], styles: coui.Styles(raw: {'padding': '71px'}))
                    : null,
                suffix: trailing
                    ? const coui.div([
                        coui.Text('suffix'),
                      ], styles: coui.Styles(raw: {'padding': '83px'}))
                    : null,
                textFieldStyle: const coui.CoreTextFieldStyle(
                  padding: coui.CoreEdgeInsets.only(
                    top: 3,
                    right: 17,
                    bottom: 5,
                    left: 29,
                  ),
                ),
              ),
            ], styles: const coui.Styles(raw: {'width': '280px'})),
          ],
          attributes: const {
            'data-parity-key': 'formatter-default-light-defaultStyle',
          },
        ),
      ),
    ]),
  );
  final parsed = html.parse(document);
  final capture = parsed.querySelector('[data-parity-key]')!;
  final themeCss = parsed
      .querySelectorAll('style[data-fixture-theme]')
      .single
      .text;
  return (tree: _tree(capture, []), themeCss: themeCss);
}

List<double> _declaredPadding(String style, String themeCss) {
  final declaration = style
      .split(';')
      .map((s) => s.trim())
      .singleWhere((s) => s.startsWith('padding:'))
      .substring('padding:'.length)
      .trim();
  final values = declaration.split(RegExp(r'\s+')).map((s) {
    var literal = s;
    final variable = RegExp(r'^var\((--[a-zA-Z0-9-]+)\)$').firstMatch(s);
    if (variable != null) {
      final name = RegExp.escape(variable.group(1)!);
      final declarations = RegExp(
        '(?:^|[;{])\\s*$name\\s*:\\s*([^;{}]+)',
      ).allMatches(themeCss).toList();
      if (declarations.length != 1) {
        throw StateError('Missing or ambiguous emitted fixture CSS: $s');
      }
      literal = declarations.single.group(1)!.trim();
    }
    if (literal.endsWith('rem')) {
      return double.parse(literal.substring(0, literal.length - 3)) * 16;
    }
    if (literal.endsWith('px')) {
      return double.parse(literal.substring(0, literal.length - 2));
    }
    if (literal == '0') {
      return 0.0;
    }
    throw StateError('Unsupported actual SSR padding unit: $literal');
  }).toList();
  return switch (values.length) {
    1 => List.filled(4, values[0]),
    2 => [values[0], values[1], values[0], values[1]],
    3 => [values[0], values[1], values[2], values[1]],
    4 => values,
    _ => throw StateError('Invalid actual SSR padding'),
  };
}

void main() {
  for (final recipe in _recipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '${recipe.component}/${recipe.variant}/$theme actual SSR canonical unit',
        () async {
          final actual = await _actual(recipe.component, recipe.variant, theme);
          final r = await _resolve(actual.tree, recipe.component);
          expect(r['error'], isNull);
          expect(r['registry'], [0]);
          for (final name in ['field', 'padding', 'frame']) {
            expect(r[name], actual.field);
          }
          expect(r['hasValue'], false);
          if (recipe.component == 'formatter') {
            final p = r['complementary']! as Map;
            expect(p['wrapper'], actual.field);
            expect(p['leadingAffixed'], false);
            expect(p['trailingAffixed'], false);
          }
        },
      );
    }
    test(
      '${recipe.component}/${recipe.variant} unknown tuple and changed source rejected',
      () async {
        final actual = await _actual(recipe.component, recipe.variant, 'light');
        for (final mutation in [
          'source.schemaVersion=99;',
          'source.quantityId="unknown";',
          'capture._list.push(root);',
          'root.parentElement=null;',
          'root.tagName="SECTION";',
          'root._list=[];',
        ]) {
          expect(
            (await _resolve(
              actual.tree,
              recipe.component,
              mutation: mutation,
            ))['error'],
            isNotNull,
            reason: mutation,
          );
        }
      },
    );
    test(
      '${recipe.component}/${recipe.variant} foreign interiors and CSS do not select owner',
      () async {
        final actual = await _actual(recipe.component, recipe.variant, 'light');
        final before = await _resolve(actual.tree, recipe.component);
        final after = await _resolve(
          actual.tree,
          recipe.component,
          mutation: '''
const first=resolve(root,source),field=first.fieldUnitElement;
root.attributes.style='padding:999px';field.attributes.style='padding:333px';
const foreign=first.foreignSeats?.[0] ??
 (source.logicalUnitId==='hover-generated-effect-host'?root._list[0]:null);
if(foreign){foreign.attributes.style='padding:777px';
 foreign._list.push(node({tagName:'DIV',attributes:{class:'relative co-om'},
  textContent:'foreign',path:[99],children:[]},foreign));}
''',
        );
        expect(after['error'], isNull);
        for (final n in ['registry', 'field', 'padding', 'frame']) {
          expect(after[n], before[n]);
        }
        expect(after['hasValue'], false);
      },
    );
  }
  for (final flags in [
    (false, false),
    (true, false),
    (false, true),
    (true, true),
  ]) {
    test(
      'actual SSR complementary parameters, asymmetric padding $flags',
      () async {
        final fixture = await _affixFixture(flags.$1, flags.$2);
        final tree = fixture.tree;
        final r = await _resolve(tree, 'formatter');
        expect(r['error'], isNull);
        final p = r['complementary']! as Map;
        expect(p['kind'], 'text-field-wrapper-input-v1');
        expect(p['wrapper'], r['frame']);
        expect(p['input'], isNot(p['wrapper']));
        expect(p['leadingAffixed'], flags.$1);
        expect(p['trailingAffixed'], flags.$2);
        // Actual SSR inline parameters, not browser-computed CSS measurements.
        final wrapper = _declaredPadding(
          p['wrapperStyle']! as String,
          fixture.themeCss,
        );
        final inputStyle = p['inputStyle']! as String;
        final input = _declaredPadding(inputStyle, fixture.themeCss);
        expect(
          () => _declaredPadding(inputStyle, ''),
          throwsStateError,
        );
        expect(
          () => _declaredPadding(inputStyle, fixture.themeCss * 2),
          throwsStateError,
        );
        expect(wrapper, [
          3.0,
          if (flags.$2) 17.0 else 0.0,
          5.0,
          if (flags.$1) 29.0 else 0.0,
        ]);
        expect(input, [
          0.0,
          if (flags.$2) 0.0 else 17.0,
          0.0,
          if (flags.$1) 0.0 else 29.0,
        ]);
        expect(List.generate(4, (i) => wrapper[i] + input[i]), [
          3.0,
          17.0,
          5.0,
          29.0,
        ]);
        const bindingCode =
            'const b=resolve(root,source).complementaryPaddingSources;';
        for (final mutation in [
          '$bindingCode b.wrapper._list.push(b.input);',
          '$bindingCode b.input.parentElement=root;',
          '$bindingCode b.input.tagName="TEXTAREA";',
          '''
$bindingCode
const w=b.wrapper;w._list=w._list.filter(n=>n!==b.input);
''',
        ]) {
          expect(
            (await _resolve(tree, 'formatter', mutation: mutation))['error'],
            isNotNull,
          );
        }
      },
    );
  }
  test(
    'Marquee has exactly one original child, never an invented clone',
    () async {
      final actual = await _actual('overflow-marquee', 'default', 'light');
      final r = await _resolve(
        actual.tree,
        'overflow-marquee',
        mutation: '''
const first=resolve(root,source),track=first.fieldUnitElement._list[1];
track._list.push(node({tagName:'DIV',attributes:{},textContent:'copy',path:[99],children:[]},track));
''',
      );
      expect(r['error'], 'MARQUEE_SINGLE_CHILD_MULTIPLICITY_CHANGED');
    },
  );
  test(
    'Kbd ordered keys must preserve the current whole name',
    () async {
      final actual = await _actual('kbd', 'combo', 'light');
      expect(
        (await _resolve(
          actual.tree,
          'kbd',
          mutation: 'root._list.reverse();',
        ))['error'],
        'KBD_CURRENT_ORDERED_KEYS_CHANGED',
      );
    },
  );
}
