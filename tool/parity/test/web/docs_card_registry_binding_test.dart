import 'dart:convert';
import 'dart:io';

import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:html/dom.dart' as html;
import 'package:test/test.dart';

import '../../src/web/docs_card_registry_binding.dart';
import '../../src/web/docs_card_registry_ssr_source.dart';
import 'docs_card_registry_real_entry_test.dart' as fixture;

Map<String, Object?> _tree(html.Node node) => node is html.Element
    ? {
        'nodeType': 1,
        'namespaceURI': node.namespaceUri,
        'localName': node.localName,
        'attributes': {
          for (final a in node.attributes.entries) a.key.toString(): a.value,
        },
        'childNodes': node.nodes.map(_tree).toList(),
      }
    : {'nodeType': node.nodeType, 'data': node is html.Text ? node.data : ''};

const _kDom = '''
const from=(data,parent=null)=>{
 if(data.nodeType!==1)return {nodeType:data.nodeType,data:data.data,parentNode:parent,parentElement:parent,isConnected:true};
 const attributes={...data.attributes};
 const n={nodeType:1,namespaceURI:data.namespaceURI,localName:data.localName,parentNode:parent,parentElement:parent,isConnected:true,
 getAttribute:k=>Object.hasOwn(attributes,k)?attributes[k]:null,setAttribute:(k,v)=>{attributes[k]=v;}};
 n.childNodes=data.childNodes.map(c=>from(c,n));
 Object.defineProperty(n,'children',{get:()=>n.childNodes.filter(c=>c.nodeType===1)});
 Object.defineProperty(n,'attributes',{get:()=>Object.entries(attributes).map(([name,value])=>({name,value}))});
 return n;
};
global.location={href:'file:///owned/docs-source.html'};
let cssReads=0;global.getComputedStyle=()=>{cssReads++;throw Error('NO_CSS_IN_BINDING');};
const firstOpaque=(node,t)=>{
 for(let i=0;i<t.children.length;i++){
  const s=t.children[i],n=node.childNodes[i];
  if(Object.hasOwn(s,'opaqueNode'))return n;
  if(s.nodeType===1){const found=firstOpaque(n,s);if(found)return found;}
 }return null;
};
''';

Future<Map<String, Object?>> _sample(
  fixture.DocsFrameFixture actual, {
  String before = '',
  String after = '',
}) async {
  final source = actual.entry.probes.single.boxObservationSource!.toJson();
  final receipt = actual.receipt == null
      ? null
      : {...actual.receipt!, 'harnessURL': 'file:///owned/docs-source.html'};
  final route = docsCardRegistrySceneRoute(actual.entry, actual.scene);
  final program =
      '''
$_kDom
const capture=from(${jsonEncode(_tree(actual.capture))});
const ownerTree=${jsonEncode(_tree(actual.owner))};
const find=n=>n.nodeType===1&&JSON.stringify(Array.from(n.attributes).map(a=>[a.name,a.value]))===JSON.stringify(Object.entries(ownerTree.attributes))?n:
 n.nodeType===1?n.childNodes.map(find).find(Boolean):null;
const owner=find(capture),selector=${jsonEncode(actual.entry.probes.single.webSelector)};
let selectorReads=0;
global.document={querySelectorAll:s=>{selectorReads++;return s===selector?[owner]:[];}};
const request={requested:true,selector,layoutSelector:selector,source:${jsonEncode(source)},
 documentationSceneTag:${jsonEncode(actual.scene.tag)},documentationSceneRoute:${jsonEncode(route)},
 requiredCurrentSsrKind:${jsonEncode(requiredDocsCardRegistrySsrKind(actual.entry, actual.scene))},currentSsrSource:${jsonEncode(receipt)}};
$before
const result=($docsCardRegistryRequestBindingScript)(request);
const initially=result.validateCurrentBinding?.()??null;
$after
console.log(JSON.stringify({applied:result.applied,error:result.error,initially,after:result.validateCurrentBinding?.()??null,cssReads,
 fieldIsOwner:result.fieldUnitElement===owner,paddingIsOwner:result.paddingSource===owner,selectorReads}));
''';
  final directory = Directory.systemTemp.createTempSync('docs-source-binding-');
  try {
    final file = File('${directory.path}/fixture.cjs')
      ..writeAsStringSync(program);
    final result = await Process.run(
      Platform.environment['PARITY_NODE'] ?? 'node',
      [file.path],
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    return (jsonDecode(result.stdout as String) as Map).cast<String, Object?>();
  } finally {
    directory.deleteSync(recursive: true);
  }
}

const _kOwnedPair = '''
const raw=request.currentSsrSource.currentRaw;
const pairFor=classes=>{
 const visit=(node,t)=>{
  if(t.attributes?.class===classes||(classes==='docs-stage not-content'&&t.attributes?.class?.startsWith('docs-stage ')))return {node,tree:t};
  for(let i=0;i<t.children.length;i++){
   if(t.children[i].nodeType===1){const found=visit(node.childNodes[i],t.children[i]);if(found)return found;}
  }return null;
 };return visit(capture,raw.capture);
};
''';

void main() {
  final svgScene = readDocsScenes('avatar').singleWhere(
    (s) => s.reference == 'docs-v2-63b2a10b59591e46f2d0201badbf8d67',
  );
  final moreScene = readDocsScenes('kbd').singleWhere(
    (s) => s.reference == 'docs-v2-49fefef3cd11b31e6724e311026e5e94',
  );
  final jointForgeries = <String, String>{
    'owned wrapper around stage preview': '''
const stage=pairFor('docs-stage not-content'),i=stage.tree.children.findIndex(c=>Object.hasOwn(c,'opaqueNode'));
if(i<0)throw Error('ACTUAL_PREVIEW_FRONTIER_REQUIRED');
const original=stage.node.childNodes[i],source=stage.tree.children[i];
const wrapper=from({nodeType:1,namespaceURI:'http://www.w3.org/1999/xhtml',localName:'div',attributes:{},childNodes:[]},stage.node);
wrapper.childNodes=[original];original.parentNode=wrapper;original.parentElement=wrapper;
stage.node.childNodes[i]=wrapper;
stage.tree.children[i]={nodeType:1,namespaceURI:'http://www.w3.org/1999/xhtml',localName:'div',attributes:{},children:[source]};
''',
    'title frontier moved into body with global order preserved': '''
const head=pairFor('docs-card-head'),body=pairFor('docs-card-body'),indices=[];
for(let i=0;i<head.tree.children.length;i++)if(Object.hasOwn(head.tree.children[i],'opaqueNode'))indices.push(i);
if(indices.length!==1)throw Error('ACTUAL_TITLE_FRONTIER_REQUIRED');
const i=indices[0],source=head.tree.children.splice(i,1)[0],node=head.node.childNodes.splice(i,1)[0];
body.tree.children.unshift(source);body.node.childNodes.unshift(node);node.parentNode=body.node;node.parentElement=body.node;
''',
    'nonformatter owned text': '''
const stage=pairFor('docs-stage not-content');
stage.tree.children.push({ownedText:'forged owned text'});
stage.node.childNodes.push(from({nodeType:3,data:'forged owned text'},stage.node));
''',
    'owned frame style in both DOM and receipt': '''
owner.setAttribute('style','padding: 91px');
const stage=pairFor('docs-stage not-content');stage.tree.attributes.style='padding: 91px';
''',
  };
  for (final control in jointForgeries.entries) {
    test('closed factory rejects joint forgery: ${control.key}', () async {
      final actual = control.key == 'owned frame style in both DOM and receipt'
          ? await fixture.renderDocsFrameFixture(
              'button',
              readDocsScenes('button').firstWhere((s) => s.tag == 'Preview'),
            )
          : await fixture.renderDocsFrameFixture('avatar', svgScene);
      final sampled = await _sample(
        actual,
        before: '$_kOwnedPair\n${control.value}',
      );
      printOnFailure('JOINT_FORGERY ${control.key}: ${jsonEncode(sampled)}');
      expect(sampled['cssReads'], 0);
      expect(
        sampled['error'],
        'DOCS_FRAME_EXACT_FACTORY_OWNED_GRAMMAR_CHANGED',
      );
      expect(sampled['selectorReads'], 0);
    });
  }

  for (final (component, scene) in fixture.documentationBranchFixtures()) {
    test('closed factory accepts original ${scene.reference}', () async {
      final actual = await fixture.renderDocsFrameFixture(component, scene);
      final sampled = await _sample(actual);
      expect(sampled['error'], isNull);
      expect(sampled['initially'], true);
      expect(sampled['after'], true);
      expect(sampled['cssReads'], 0);
    });
  }

  test(
    'closed factory accepts original eligible more and arrow branch',
    () async {
      final actual = await fixture.renderDocsFrameFixture('kbd', moreScene);
      final raw = actual.receipt!['currentRaw']! as Map;
      final frontiers = raw['opaqueFrontiers']! as List;
      expect(
        frontiers.map((f) => (f as Map)['purpose']),
        containsAllInOrder(['more-label', 'arrow-label']),
      );
      final sampled = await _sample(actual);
      expect(sampled['error'], isNull);
      expect(sampled['initially'], true);
      expect(sampled['after'], true);
      expect(sampled['cssReads'], 0);
    },
  );

  for (final classes in [
    'docs manual',
    'content',
    'docs-cards not-content',
    'docs-card docs-card--preview',
    'docs-stage not-content',
    'docs-card-eyebrow',
    'docs-card-head',
    'docs-card-body',
    'docs-card-more',
    'site-arrow',
  ]) {
    test('closed factory rejects extra owned attribute on $classes', () async {
      final scene = switch (classes) {
        'docs-card-eyebrow' => readDocsScenes('button').firstWhere(
          (s) => s.tag == 'Card' && s.attributes['eyebrow'] != null,
        ),
        'docs-card-more' || 'site-arrow' => moreScene,
        _ => svgScene,
      };
      final actual = await fixture.renderDocsFrameFixture(
        scene == svgScene
            ? 'avatar'
            : classes == 'docs-card-more' || classes == 'site-arrow'
            ? 'kbd'
            : 'button',
        scene,
      );
      final sampled = await _sample(
        actual,
        before:
            '''
$_kOwnedPair
const target=pairFor(${jsonEncode(classes)});
if(!target)throw Error('ACTUAL_OWNED_FACTORY_NODE_REQUIRED');
target.tree.attributes['data-forged-own']='forged';
target.node.setAttribute('data-forged-own','forged');
''',
      );
      expect(
        sampled['error'],
        'DOCS_FRAME_EXACT_FACTORY_OWNED_GRAMMAR_CHANGED',
      );
      expect(sampled['selectorReads'], 0);
      expect(sampled['cssReads'], 0);
    });
  }

  test('original SVG frontier binds without inspecting its interior', () async {
    final actual = await fixture.renderDocsFrameFixture('avatar', svgScene);
    final sampled = await _sample(actual);
    expect(sampled['error'], isNull);
    expect(sampled['initially'], true);
    expect(sampled['after'], true);
    expect(sampled['cssReads'], 0);
  });

  for (final control in ['wrong SVG namespace', 'non-svg as SVG']) {
    test('closed namespace rejects $control before selector/CSS', () async {
      final actual = await fixture.renderDocsFrameFixture('avatar', svgScene);
      final mutation = control == 'wrong SVG namespace'
          ? '''
request.currentSsrSource.currentRaw.opaqueFrontiers[0].nodes[0].namespaceURI='http://www.w3.org/1999/xhtml';
'''
          : '''
const foreign=firstOpaque(capture,request.currentSsrSource.currentRaw.capture);
foreign.localName='div';
request.currentSsrSource.currentRaw.opaqueFrontiers[0].nodes[0].localName='div';
''';
      final sampled = await _sample(
        actual,
        before:
            '''
$mutation
document.querySelectorAll=()=>{throw Error('NAMESPACE_REJECTION_MUST_PRECEDE_SELECTOR');};
''',
      );
      expect(sampled['error'], 'DOCS_FRAME_OPAQUE_ROSTER_CHANGED');
      expect(sampled['cssReads'], 0);
    });
  }

  test('SVG outer replacement invalidates the held binding', () async {
    final actual = await fixture.renderDocsFrameFixture('avatar', svgScene);
    final sampled = await _sample(
      actual,
      after: '''
const foreign=firstOpaque(capture,request.currentSsrSource.currentRaw.capture);
if(foreign.localName!=='svg'||foreign.namespaceURI!=='http://www.w3.org/2000/svg')throw Error('SVG_CONTROL_REQUIRED');
const parent=foreign.parentNode;parent.childNodes[parent.childNodes.indexOf(foreign)]={...foreign};
''',
    );
    expect(sampled['error'], isNull);
    expect(sampled['initially'], true);
    expect(sampled['after'], false);
    expect(sampled['cssReads'], 0);
  });

  test('SVG attributes and interior remain opaque', () async {
    final actual = await fixture.renderDocsFrameFixture('avatar', svgScene);
    final sampled = await _sample(
      actual,
      after: '''
const foreign=firstOpaque(capture,request.currentSsrSource.currentRaw.capture);
if(foreign.localName!=='svg'||foreign.namespaceURI!=='http://www.w3.org/2000/svg')throw Error('SVG_CONTROL_REQUIRED');
foreign.setAttribute('data-unrelated','opaque-svg');
Object.defineProperty(foreign,'childNodes',{get:()=>{throw Error('OPAQUE_SVG_INTERIOR_READ');}});
''',
    );
    expect(sampled['error'], isNull);
    expect(sampled['initially'], true);
    expect(sampled['after'], true);
    expect(sampled['cssReads'], 0);
  });

  test(
    'strict false returns before any source receipt or route getter',
    () async {
      final scene = readDocsScenes(
        'button',
      ).firstWhere((s) => s.tag == 'Preview');
      final actual = await fixture.renderDocsFrameFixture('button', scene);
      final sampled = await _sample(
        actual,
        before: '''
request.requested=false;
for(const key of ['source','currentSsrSource','documentationSceneTag','documentationSceneRoute','requiredCurrentSsrKind']){
 Object.defineProperty(request,key,{get:()=>{throw Error('UNREQUESTED_SOURCE_GETTER_READ');}});
}
''',
      );
      expect(sampled['error'], isNull);
      expect(sampled['applied'], false);
      expect(sampled['cssReads'], 0);
    },
  );

  for (final flag in ['undefined', 'null', '"true"', '1']) {
    test('claimed malformed requested=$flag fails closed', () async {
      final scene = readDocsScenes(
        'button',
      ).firstWhere((s) => s.tag == 'Preview');
      final actual = await fixture.renderDocsFrameFixture('button', scene);
      final sampled = await _sample(actual, before: 'request.requested=$flag;');
      expect(sampled['error'], 'DOCS_FRAME_STRICT_REQUESTED_FLAG_REQUIRED');
      expect(sampled['cssReads'], 0);
    });
  }

  test(
    'eligible Preview cannot strip its requirement and relabel Anatomy',
    () async {
      final scene = readDocsScenes(
        'button',
      ).firstWhere((s) => s.tag == 'Preview');
      final actual = await fixture.renderDocsFrameFixture('button', scene);
      final sampled = await _sample(
        actual,
        before: '''
request.documentationSceneTag='Anatomy';
request.documentationSceneRoute.sceneTag='Anatomy';
request.requiredCurrentSsrKind=null;request.currentSsrSource=null;
''',
      );
      expect(sampled['error'], 'DOCS_FRAME_ANATOMY_HOLD_NORMAL_ROUTE_CHANGED');
      expect(sampled['cssReads'], 0);
    },
  );

  test('actual original Anatomy route stays explicitly unproved', () async {
    final scene = readDocsScenes(
      'button',
    ).firstWhere((s) => s.tag == 'Anatomy');
    final actual = await fixture.renderDocsFrameFixture('button', scene);
    expect(actual.receipt, isNull);
    expect(actual.observations, 0);
    final sampled = await _sample(actual);
    expect(sampled['error'], isNull);
    expect(sampled['applied'], false);
    expect(sampled['cssReads'], 0);
  });

  for (final tag in ['Card', 'Preview', 'VariantRow']) {
    test(
      '$tag binds the real completed original response without CSS',
      () async {
        final scene = readDocsScenes('button').firstWhere((s) => s.tag == tag);
        final actual = await fixture.renderDocsFrameFixture('button', scene);
        final sampled = await _sample(actual);
        expect(sampled['error'], isNull);
        expect(sampled['applied'], true);
        expect(sampled['initially'], true);
        expect(sampled['after'], true);
        expect(sampled['fieldIsOwner'], true);
        expect(sampled['paddingIsOwner'], true);
        expect(sampled['cssReads'], 0);
      },
    );
  }

  final malformed = <String, String>{
    'missing eligible receipt': 'request.currentSsrSource=null;',
    'wrong actual route': 'request.documentationSceneTag="Anatomy";',
    'lost original scene':
        'delete request.currentSsrSource.currentRaw.originalSceneInput;',
    'lost raw frontier':
        'request.currentSsrSource.currentRaw.opaqueFrontiers.pop();',
    'extra own occurrence': 'capture.childNodes.push(capture.children[0]);',
    'changed public frame parameter':
        'owner.setAttribute("style","padding: 91px");',
    'foreign branch':
        'request.currentSsrSource.currentRaw.sceneTag="SizeSpec";',
  };
  for (final testCase in malformed.entries) {
    test('rejects ${testCase.key} before any CSS', () async {
      final scene = readDocsScenes('button').firstWhere((s) => s.tag == 'Card');
      final actual = await fixture.renderDocsFrameFixture('button', scene);
      final sampled = await _sample(actual, before: testCase.value);
      expect(sampled['error'], isNotNull);
      expect(sampled['cssReads'], 0);
    });
  }

  final held = <String, String>{
    'own attribute': 'owner.setAttribute("data-stale","yes");',
    'own reorder': 'owner.childNodes.reverse();',
    'same-value receipt replacement':
        'request.currentSsrSource=JSON.parse(JSON.stringify('
        'request.currentSsrSource));',
    'wire receipt nested object':
        'request.currentSsrSource.currentRaw.originalSceneInput.attributes='
        '{...request.currentSsrSource.currentRaw.'
        'originalSceneInput.attributes};',
    'selector': 'request.layoutSelector="other";',
    'detached owner': 'owner.isConnected=false;',
    'opaque outer replacement': '''
 const foreign=firstOpaque(capture,request.currentSsrSource.currentRaw.capture);
 const parent=foreign.parentNode;parent.childNodes[parent.childNodes.indexOf(foreign)]={...foreign};''',
  };
  for (final testCase in held.entries) {
    test('retains held ${testCase.key} across sampler phases', () async {
      final scene = readDocsScenes('button').firstWhere((s) => s.tag == 'Card');
      final actual = await fixture.renderDocsFrameFixture('button', scene);
      final sampled = await _sample(actual, after: testCase.value);
      expect(sampled['error'], isNull);
      expect(sampled['initially'], true);
      expect(sampled['after'], false);
      expect(sampled['cssReads'], 0);
    });
  }

  test('foreign element interior stays opaque', () async {
    final scene = readDocsScenes('button').firstWhere((s) => s.tag == 'Card');
    final actual = await fixture.renderDocsFrameFixture('button', scene);
    final sampled = await _sample(
      actual,
      after: '''
const foreign=firstOpaque(capture,request.currentSsrSource.currentRaw.capture);
if(foreign.nodeType!==1)throw Error('POSITIVE_REQUIRES_ELEMENT_FRONTIER');
foreign.setAttribute('data-unrelated','opaque');
Object.defineProperty(foreign,'childNodes',{get:()=>{throw Error('FOREIGN_INTERIOR_READ');}});
''',
    );
    expect(sampled['initially'], true);
    expect(sampled['after'], true);
    expect(sampled['cssReads'], 0);
  });
}
