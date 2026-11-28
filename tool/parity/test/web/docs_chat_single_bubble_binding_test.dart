// Authored source only; mocked DOM is made from the already returned normal
// HTML for protocol controls. The production recorder never serializes it.
import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as html;
import 'package:test/test.dart';

import '../../src/web/docs_chat_single_bubble_binding.dart';
import '../../src/web/docs_chat_single_bubble_ssr_source.dart';
import 'docs_chat_single_bubble_real_entry_test.dart' as fixture;

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

List<int> _path(html.Node root, html.Node child) {
  final reversed = <int>[];
  var current = child;
  while (!identical(current, root)) {
    final parent = current.parentNode!;
    reversed.add(parent.nodes.indexOf(current));
    current = parent;
  }
  return reversed.reversed.toList();
}

const _kDom = '''
const from=(d,parent=null)=>{
 if(d.nodeType!==1)return {nodeType:d.nodeType,data:d.data,parentNode:parent,parentElement:parent,isConnected:true};
 const a={...d.attributes},n={nodeType:1,namespaceURI:d.namespaceURI,localName:d.localName,parentNode:parent,parentElement:parent,isConnected:true,
 getAttribute:k=>Object.hasOwn(a,k)?a[k]:null,setAttribute:(k,v)=>{a[k]=v;}};
 n.childNodes=d.childNodes.map(c=>from(c,n));
 Object.defineProperty(n,'attributes',{configurable:true,get:()=>Object.entries(a).map(([name,value])=>({name,value}))});
 return n;
};
global.location={href:'file:///owned/chat-source.html'};
let cssReads=0,selectorReads=0;
global.getComputedStyle=()=>{cssReads++;throw Error('NO_CSS_IN_BINDING');};
''';

const _kBodyPair = '''
const raw=request.currentSsrSource.currentRaw;
let bodyNode=capture,bodyTree=raw.capture;
for(let level=0;level<3;level++){
 const i=bodyTree.children.findIndex(c=>c.nodeType===1);
 if(i<0)throw Error('HEALTHY_DIRECT_BODY_ROUTE_REQUIRED');
 bodyNode=bodyNode.childNodes[i];bodyTree=bodyTree.children[i];
}
const replaceClass=value=>{
 raw.bodyDeclaration.class=value;bodyTree.attributes.class=value;bodyNode.setAttribute('class',value);
};
''';

Future<Map<String, Object?>> sample(
  fixture.ChatFixture actual, {
  String before = '',
  String after = '',
}) async {
  final receipt = {
    ...actual.receipt!,
    'harnessURL': 'file:///owned/chat-source.html',
  };
  final program =
      '''
$_kDom
const capture=from(${jsonEncode(_tree(actual.capture))});
let registry=capture;for(const i of ${jsonEncode(_path(actual.capture, actual.owner))})registry=registry.childNodes[i];
const selector=${jsonEncode(actual.entry.probes.single.webSelector)};
global.document={querySelectorAll:s=>{selectorReads++;return s===selector?[registry]:[];}};
const request={requested:true,selector,layoutSelector:selector,
 source:${jsonEncode(actual.entry.probes.single.boxObservationSource!.toJson())},
 requiredCurrentSsrKind:${jsonEncode(kDocsChatSingleBubbleSsrKind)},currentSsrSource:${jsonEncode(receipt)}};
$before
const result=($docsChatSingleBubbleRequestBindingScript)(request);
const initially=result.validateCurrentBinding?.()??null;
$after
console.log(JSON.stringify({applied:result.applied,error:result.error,initially,
 after:result.validateCurrentBinding?.()??null,cssReads,selectorReads}));
''';
  final directory = Directory.systemTemp.createTempSync('docs-chat-binding-');
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

void main() {
  for (final variant in fixture.kChatVariants) {
    for (final theme in ['light', 'dark']) {
      test('actual original binding / $variant / $theme', () async {
        final result = await sample(
          await fixture.renderChatFixture(variant, theme),
        );
        expect(result['applied'], true);
        expect(result['initially'], true);
        expect(result['after'], true);
        expect(result['cssReads'], 0);
      });
    }
  }

  test('actual nondefault typography/color channel binding', () async {
    final actual = await fixture.renderChatFixture(
      'neutral',
      'light',
      themeData: fixture.nondefaultChannelTheme(),
    );
    final result = await sample(actual);
    expect(result['applied'], true);
    expect(result['initially'], true);
    expect(result['after'], true);
    expect(result['cssReads'], 0);
  });

  const forgeries = <String, String>{
    'padding utility': "replaceClass(raw.bodyDeclaration.class+' p-0');",
    'layout utility': "replaceClass(raw.bodyDeclaration.class+' flex');",
    'unknown typography':
        "replaceClass('inline-block relative "
        'text-unregistered-role bg-primary coui-surface '
        "coui-surface-content');",
    'unknown background':
        "replaceClass('inline-block relative text-body-large "
        'bg-unregistered-color coui-surface '
        "coui-surface-content');",
    'duplicate role':
        "replaceClass('inline-block relative text-body-large "
        "text-code-md bg-primary');",
    'text color without role':
        "replaceClass('inline-block relative text-on-primary bg-primary');",
    'functional surface':
        "replaceClass('inline-block relative text-body-large "
        "bg-primary coui-surface coui-surface-functional');",
    'incomplete surface pair':
        "replaceClass('inline-block relative text-body-large "
        "bg-primary coui-surface');",
    'fractional opacity spelling':
        "replaceClass('inline-block relative text-body-large bg-primary/2.5');",
    'noncanonical opacity spelling':
        "replaceClass('inline-block relative text-body-large bg-primary/00');",
    'reordered channels':
        "replaceClass('inline-block relative bg-primary text-body-large');",
  };
  for (final control in forgeries.entries) {
    test('joint DOM/raw body-class forgery / ${control.key}', () async {
      final actual = await fixture.renderChatFixture('neutral', 'light');
      final result = await sample(
        actual,
        before: '$_kBodyPair\n${control.value}',
      );
      expect(
        result['error'],
        'DOCS_CHAT_ORIGINAL_BODY_DECLARATION_CHANNELS_REQUIRED',
      );
      expect(result['selectorReads'], 0);
      expect(result['cssReads'], 0);
    });
  }

  test(
    'strict false returns before poisoned source/receipt/selector getters',
    () async {
      final actual = await fixture.renderChatFixture('neutral', 'light');
      final result = await sample(
        actual,
        before: '''
request.requested=false;
for(const key of ['source','currentSsrSource','requiredCurrentSsrKind','selector','layoutSelector'])
 Object.defineProperty(request,key,{get:()=>{throw Error('UNREQUESTED_GETTER_REPLAY');}});
''',
      );
      expect(result['applied'], false);
      expect(result['selectorReads'], 0);
      expect(result['cssReads'], 0);
    },
  );

  test('claimed malformed request fails closed before selectors', () async {
    final actual = await fixture.renderChatFixture('neutral', 'light');
    final result = await sample(actual, before: "request.requested='true';");
    expect(result['error'], 'DOCS_CHAT_STRICT_REQUESTED_FLAG_REQUIRED');
    expect(result['selectorReads'], 0);
  });

  test('owned-only binding ignores opaque interiors and attributes', () async {
    final actual = await fixture.renderChatFixture('neutral', 'light');
    final result = await sample(
      actual,
      after:
          '''
$_kBodyPair
const i=bodyTree.children.findIndex(c=>Object.hasOwn(c,'opaqueNode'));
if(i<0)throw Error('HEALTHY_OPAQUE_FRONTIER_REQUIRED');
const foreign=bodyNode.childNodes[i];
for(const key of ['attributes','childNodes','children','data'])
 Object.defineProperty(foreign,key,{configurable:true,get:()=>{throw Error('OPAQUE_INTERIOR_READ');}});
''',
    );
    expect(result['initially'], true);
    expect(result['after'], true);
    expect(result['cssReads'], 0);
  });

  test(
    'replacement of opaque outer reference invalidates held binding',
    () async {
      final actual = await fixture.renderChatFixture('neutral', 'light');
      final result = await sample(
        actual,
        after:
            '''
$_kBodyPair
const i=bodyTree.children.findIndex(c=>Object.hasOwn(c,'opaqueNode'));
if(i<0)throw Error('HEALTHY_OPAQUE_FRONTIER_REQUIRED');
const old=bodyNode.childNodes[i];
const replacement={nodeType:old.nodeType,namespaceURI:old.namespaceURI,localName:old.localName,
 parentNode:bodyNode,parentElement:bodyNode,isConnected:true};
bodyNode.childNodes[i]=replacement;old.isConnected=false;
''',
      );
      expect(result['initially'], true);
      expect(result['after'], false);
    },
  );

  test('replacement of raw padding chain invalidates held binding', () async {
    final actual = await fixture.renderChatFixture('neutral', 'light');
    final result = await sample(
      actual,
      after: '''
const p=request.currentSsrSource.currentRaw.rawParameters;
p.themePadding={...p.themePadding};
''',
    );
    expect(result['initially'], true);
    expect(result['after'], false);
  });
}
