import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/computed_style_probe.dart';
import '../../src/web/web_capture_backend.dart';

typedef _Actual = ({
  MatrixEntry entry,
  Map<String, Object?> receipt,
  Map<String, Object?> capture,
});
final _cache = <String, Future<_Actual>>{};
Map<String, Object?> _tree(dom.Node node) => node is dom.Element
    ? {
        'nodeType': node.nodeType,
        'namespaceURI': node.namespaceUri,
        'localName': node.localName,
        'attributes': {
          for (final a in node.attributes.entries) a.key.toString(): a.value,
        },
        'childNodes': node.nodes.map(_tree).toList(),
      }
    : {
        'nodeType': node.nodeType,
        'data': node is dom.Text
            ? node.data
            : node is dom.Comment
            ? node.data
            : '',
      };
Future<_Actual> _actual(String component, String variant, String theme) =>
    _cache.putIfAbsent('$component/$variant/$theme', () async {
      final key = '$component-$variant-$theme-defaultStyle';
      final entry = MatrixEntry.fromJson({
        'component': component,
        'variant': variant,
        'theme': theme,
        'surfaceStyle': 'defaultStyle',
        'tier': 't2',
        'probes': captureProbes(
          key: key,
          component: component,
          variant: variant,
          flutterClassName: 'original-public-type',
        ).map((p) => p.toJson()).toList(),
      });
      final receipts = <Map<String, Object?>>[];
      final body = await renderCaptureBodyHtml(
        entry,
        onCurrentBoxSource: receipts.add,
      );
      expect(receipts, hasLength(1));
      expect(
        receipts.single.containsKey('error'),
        false,
        reason: '${receipts.single}',
      );
      final fragment = html.parseFragment(body);
      final capture = fragment.querySelectorAll('[data-parity-key]').single;
      expect(
        fragment.querySelectorAll(entry.probes.single.webSelector),
        hasLength(1),
      );
      final raw = receipts.single['currentRaw']! as Map;
      final count = component == 'tree'
          ? 0
          : component == 'media-query'
          ? 2
          : 3;
      expect(raw['rawSeats'], hasLength(count));
      expect(receipts.single['completeRawSlotCount'], count);
      return (entry: entry, receipt: receipts.single, capture: _tree(capture));
    });

// Reused accepted Node DOM/CSS transport. Numeric CSS sentinels discriminate
// original root ownership from supplied foreign padding; they are no browser or
// design values. The ordinary SSR response supplies all actual DOM structure.
const _kRuntime = r'''

const from=(data,parent=null)=>{
 if(data.nodeType!==1){
  const n={nodeType:data.nodeType,data:data.data,parentNode:parent,parentElement:parent,isConnected:true};
  Object.defineProperty(n,'textContent',{get:()=>n.data,set:value=>{n.data=value;}});
  Object.defineProperty(n,'nodeValue',{get:()=>n.data,set:value=>{n.data=value;}});
  return n;
 }
 const attrs={...data.attributes};
 const node={nodeType:1,namespaceURI:data.namespaceURI,localName:data.localName,
  tagName:data.localName.toUpperCase(),parentNode:parent,parentElement:parent,isConnected:true,style:{},
  getAttribute:name=>Object.hasOwn(attrs,name)?attrs[name]:null,
  hasAttribute:name=>Object.hasOwn(attrs,name),
  setAttribute:(name,value)=>{attrs[name]=value;},removeAttribute:name=>{delete attrs[name];}};
 node.childNodes=data.childNodes.map(child=>from(child,node));
 node.cloneNode=()=>from(data,node.parentElement);
 Object.defineProperty(node,'textContent',{get:()=>node.childNodes.map(c=>c.textContent||'').join('')});
 Object.defineProperty(node,'children',{get:()=>node.childNodes.filter(child=>child.nodeType===1)});
 Object.defineProperty(node,'attributes',{get:()=>Object.entries(attrs).map(([name,value])=>({name,value}))});
 Object.defineProperty(node,'classList',{get:()=>{
  const names=(attrs.class||'').split(/[\t\n\f\r ]+/).filter(Boolean);
  names.contains=name=>names.includes(name);return names;
 }});
 node.querySelectorAll=selector=>selector==='input, textarea'?[]:
  node.children.flatMap(child=>[child,...child.querySelectorAll('*')]);
 node.contains=other=>node===other||node.children.some(child=>child.contains(other));
 node.getBoundingClientRect=()=>({x:0,y:0,left:0,top:0,right:137,bottom:59,width:137,height:59});
 return node;
};
global.location={href:'file:///owned/public-wrapper-source.html'};
global.window={__coui_parity_color_keys__:new Set()};
global.Node={TEXT_NODE:3};
global.NodeFilter={SHOW_TEXT:4};
let cssReads=0;
global.getComputedStyle=node=>{cssReads++;return {
 display:'block',visibility:'visible',position:'static',overflowX:'visible',overflowY:'visible',clip:'auto',opacity:'1',
 paddingTop:node===root?'2px':'901px',paddingRight:node===root?'3px':'902px',
 paddingBottom:node===root?'5px':'903px',paddingLeft:node===root?'7px':'904px',
 fontFamily:'unit-font',fontWeight:'400',fontSize:'14px',lineHeight:'20px',letterSpacing:'0px',color:'rgb(1, 2, 3)',
 backgroundColor:'rgba(0, 0, 0, 0)',borderTopColor:'rgb(1, 2, 3)',
 borderTopWidth:'0px',borderRightWidth:'0px',borderBottomWidth:'0px',borderLeftWidth:'0px',
 borderTopLeftRadius:'0px',borderTopRightRadius:'0px',borderBottomRightRadius:'0px',borderBottomLeftRadius:'0px',
 boxShadow:'none',outlineWidth:'0px',outlineStyle:'none',outlineColor:'rgb(1, 2, 3)',outlineOffset:'0px'
};};

''';
Future<Map<String, Object?>> _sample(
  _Actual actual, {
  bool combined = false,
  bool legacyOnly = false,
  String mutation = '',
  String? boxScript,
}) async {
  final selector = actual.entry.probes.single.webSelector;
  final receipt = {
    ...actual.receipt,
    'harnessURL': 'file:///owned/public-wrapper-source.html',
  };
  final program =
      '''
$_kRuntime
const capture=from(${jsonEncode(actual.capture)}),root=capture.children[0];
const selector=${jsonEncode(selector)};
let matches=[root];
global.document={querySelector:sel=>sel===selector?root:null,
 querySelectorAll:sel=>sel===selector?matches:[],
 createTreeWalker:node=>{const queue=[];const visit=n=>{for(const c of n.childNodes){if(c.nodeType===3)queue.push(c);else if(c.nodeType===1)visit(c);}};visit(node);return {nextNode:()=>queue.shift()||null};}};
const request={requested:true,selector,layoutSelector:selector,
 source:${jsonEncode(actual.entry.probes.single.boxObservationSource!.toJson())},
 currentSsrSource:${jsonEncode(receipt)},requiredCurrentSsrKind:'canonical-ssr-public-wrapper-v1'};
$mutation
let observed,error;
try{observed=JSON.parse((${legacyOnly
          ? '(request) => ($computedStyleProbeScript)(request.selector)'
          : combined
          ? boxScript == null
                ? computedStyleAndBoxObservationScript
                : sourceValidatedComputedStyleAndBoxScript(boxScript)
          : boxPaddingObservationScript})(request));}
catch(e){error=String(e);}
console.log(JSON.stringify({observed,error,cssReads,
 heldOriginalRootAttached:root.isConnected&&capture.isConnected&&root.parentElement===capture&&capture.children[0]===root}));
''';
  final directory = await Directory.systemTemp.createTemp('coui-parity-node-');
  try {
    final file = File('${directory.path}/probe.cjs');
    await file.writeAsString(program);
    final result = await Process.run(
      Platform.environment['PARITY_NODE'] ?? 'node',
      [file.path],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
  } finally {
    await directory.delete(recursive: true);
  }
}

const _kRecipes = [
  ('tree', 'default'),
  ('tree', 'selected'),
  ('tree', 'trailing'),
  ('media-query', 'default'),
  ('swipe-actions', 'default'),
];
void main() {
  for (final (component, variant) in _kRecipes) {
    for (final theme in ['light', 'dark']) {
      test(
        '$component/$variant/$theme actual root CSS and legacy invariant',
        () async {
          final actual = await _actual(component, variant, theme);
          final standalone = await _sample(actual);
          expect(standalone['error'], isNull);
          final box = standalone['observed']! as Map;
          expect(box['status'], 'source-complete', reason: '$standalone');
          expect(box['value'], [2, 3, 5, 7]);
          expect(box['ownerIsLayoutRoot'], true);
          final legacy = await _sample(actual, legacyOnly: true);
          final combined = await _sample(actual, combined: true);
          expect(combined['error'], isNull, reason: '$combined');
          final both = combined['observed']! as Map;
          expect(both['legacy'], legacy['observed']);
          expect((both['box']! as Map)['value'], [2, 3, 5, 7]);
        },
      );
    }
    final invalid = <String, String>{
      'missing receipt': 'delete request.currentSsrSource;',
      'missing both receipt and requirement':
          'delete request.currentSsrSource;delete '
          'request.requiredCurrentSsrKind;',
      'foreign receipt kind': "request.currentSsrSource.kind='foreign';",
      'missing requirement': 'delete request.requiredCurrentSsrKind;',
      'null key without capture key':
          'request.currentSsrSource.entryKey=null;'
          "capture.removeAttribute('data-parity-key');",
      'empty key with empty capture':
          "request.currentSsrSource.entryKey='';"
          "capture.setAttribute('data-parity-key','');",
      'missing header key': 'delete request.currentSsrSource.entryKey;',
      'extra header field': 'request.currentSsrSource.foreign=true;',
      'wrong quantity': "request.source.quantityId='foreign';",
      'wrong requirement': "request.requiredCurrentSsrKind='foreign';",
      'wrong URL': "request.currentSsrSource.harnessURL='file:///foreign';",
      'owner retarget keeping old root': 'matches=[root.cloneNode()];',
      'duplicate selector retaining old root':
          'matches=[root,root.cloneNode()];',
      'extra initial ASCII capture text':
          "capture.childNodes.push(from({nodeType:3,data:' '},capture));",
      'extra initial ASCII owned text':
          "root.childNodes.push(from({nodeType:3,data:' '},root));",
      'anonymous capture text':
          "capture.childNodes.push(from({nodeType:3,data:'foreign'},capture));",
      'anonymous capture NBSP':
          'capture.childNodes.push(from({nodeType:3,'
          'data:String.fromCharCode(160)},capture));',
      'anonymous capture comment':
          "capture.childNodes.push(from({nodeType:8,data:'foreign'},capture));",
      'extra generated root child':
          'root.childNodes.push(from({nodeType:1,'
          "namespaceURI:root.namespaceURI,localName:'div',"
          'attributes:{},childNodes:[]},root));',
      'missing generated root child': 'root.childNodes.pop();',
      'changed owned attributes': "root.setAttribute('data-foreign','yes');",
    };
    for (final entry in invalid.entries) {
      test('$component ${entry.key} rejects before CSS', () async {
        final actual = await _actual(component, variant, 'light');
        final sampled = await _sample(actual, mutation: entry.value);
        expect(sampled['cssReads'], 0, reason: '$sampled');
        expect(
          sampled['error'] != null ||
              (sampled['observed']! as Map)['status'] == 'incomplete',
          true,
          reason: '$sampled',
        );
        expect(sampled['heldOriginalRootAttached'], true);
      });
    }
    for (final phase in ['CSS', 'post-box']) {
      test(
        '$component normal formatter Text mutation $phase rejects',
        () async {
          final actual = await _actual(component, variant, 'light');
          final change = const <String>[
            'const text=capture.childNodes.find(n=>n.nodeT',
            'ype===3)||root.childNodes.find(n=>n.nodeType===3);',
            "if(!text)throw new Error('missing real normal ",
            "formatting fixture');text.textContent+=' ';",
          ].join();
          final sampled = await _sample(
            actual,
            combined: phase == 'post-box',
            mutation: phase == 'CSS'
                ? <String>[
                    'const originalCSS=getComputedStyle;',
                    'global.getComputedStyle=n=>{const s=originalCSS(n);',
                    "Object.defineProperty(s,'paddingTop',{get:()",
                    "=>{$change return '2px';}});return s;};",
                  ].join()
                : '',
            boxScript: phase == 'post-box'
                ? '(request)=>{$change return '
                      "JSON.stringify({status:'source-complete',value:[2,"
                      '3,5,7]});}'
                : null,
          );
          expect(
            sampled['error'] != null ||
                (sampled['observed']! as Map)['status'] == 'incomplete',
            true,
            reason: '$sampled',
          );
          expect(sampled['heldOriginalRootAttached'], true);
          expect(
            '${sampled['error']}',
            isNot(contains('missing real normal formatting fixture')),
          );
        },
      );
    }
    for (final stage in ['standalone', 'legacy', 'post-box']) {
      test(
        '$component selector mutation $stage keeps old root '
        'attached but rejects',
        () async {
          final actual = await _actual(component, variant, 'light');
          final sampled = await _sample(
            actual,
            combined: stage != 'standalone',
            mutation: stage == 'post-box'
                ? ''
                : '''
const originalCSS=getComputedStyle;
global.getComputedStyle=n=>{const style=originalCSS(n);Object.defineProperty(style,'paddingTop',{get:()=>{matches=[root,root.cloneNode()];return '2px';}});return style;};
''',
            boxScript: stage == 'post-box'
                ? '''(request)=>{matches=[root,root.cloneNode()];return JSON.stringify({status:'source-complete',value:[2,3,5,7]});}'''
                : null,
          );
          expect(
            sampled['error'] != null ||
                (sampled['observed']! as Map)['status'] == 'incomplete',
            true,
            reason: '$sampled',
          );
          expect(sampled['heldOriginalRootAttached'], true);
        },
      );
    }
    for (final change in <String, String>{
      'equal source replacement': 'request.source={...request.source};',
      'equal nested raw replacement':
          'request.currentSsrSource.currentRaw={...reque'
          'st.currentSsrSource.currentRaw};',
      'equal nested graph replacement':
          'request.currentSsrSource.currentRaw.generated'
          'Tree={...request.currentSsrSource.currentRaw.'
          'generatedTree};',
      'new same-owner selector':
          "request.selector='same-owner';document.querySelectorAll=()=>[root];",
      'request no longer requested': 'request.requested=false;',
      'requirement changed': "request.requiredCurrentSsrKind='foreign';",
    }.entries) {
      test('$component held ${change.key} rejects during CSS', () async {
        final actual = await _actual(component, variant, 'light');
        final sampled = await _sample(
          actual,
          mutation:
              """
const originalCSS=getComputedStyle;
global.getComputedStyle=n=>{const style=originalCSS(n);Object.defineProperty(style,'paddingTop',{get:()=>{${change.value}return '2px';}});return style;};
""",
        );
        expect(
          sampled['error'] != null ||
              (sampled['observed']! as Map)['status'] == 'incomplete',
          true,
          reason: '$sampled',
        );
        expect(sampled['heldOriginalRootAttached'], true);
      });
    }
    test(
      '$component opaque descendant mutation stays inside its whole boundary',
      () async {
        final actual = await _actual(component, variant, 'light');
        final target = component == 'tree'
            ? "root.children.find(n=>n.tagName!=='STYLE')"
            : component == 'media-query'
            ? "root.children.find(n=>n.tagName==='DIV').children[0]"
            : "root.children.find(n=>n.hasAttribute('data-sw"
                  "ipe-row')).children[0]";
        final sampled = await _sample(
          actual,
          mutation:
              '''
const opaque=$target,originalCSS=getComputedStyle;
global.getComputedStyle=n=>{opaque.childNodes.push(from({nodeType:3,data:'foreign-inner-change'},opaque));return originalCSS(n);};
''',
        );
        expect(sampled['error'], isNull);
        expect(
          (sampled['observed']! as Map)['status'],
          'source-complete',
          reason: '$sampled',
        );
      },
    );
    if (component != 'tree') {
      test('$component complete raw seat map cannot omit an input', () async {
        final sampled = await _sample(
          await _actual(component, variant, 'light'),
          mutation: 'request.currentSsrSource.currentRaw.rawSeats.pop();',
        );
        expect(sampled['cssReads'], 0);
        expect((sampled['observed']! as Map)['status'], 'incomplete');
      });
    }
  }
}
