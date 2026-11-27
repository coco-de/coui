// Protocol controls only. Real typed client provenance is tested on Root Ego.
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/box_padding_observation_probe.dart';
import '../../src/web/client_box_source_protocol.dart';
import '../../src/web/computed_style_probe.dart';

typedef _Actual = ({MatrixEntry entry, Map<String, Object?> capture});
Map<String, Object?> _div(Map<String, String> attrs, List<Object?> children) =>
    {
      'nodeType': 1,
      'namespaceURI': 'http://www.w3.org/1999/xhtml',
      'localName': 'div',
      'attributes': attrs,
      'childNodes': children,
    };
_Actual _actual(String theme) {
  final key = 'stage-container-default-$theme-defaultStyle';
  final entry = MatrixEntry.fromJson({
    'component': 'stage-container',
    'variant': 'default',
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': captureProbes(
      key: key,
      component: 'stage-container',
      variant: 'default',
      flutterClassName: 'StageContainer',
    ).map((p) => p.toJson()).toList(),
  });
  return (
    entry: entry,
    capture: _div(
      {'data-parity-key': key},
      [
        _div(
          {'id': 'actual-stage', 'class': 'w-full'},
          [
            _div(
              {'class': 'w-full'},
              [
                _div(
                  {'class': 'opaque'},
                  [
                    {'nodeType': 3, 'data': 'foreign callback content'},
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

const _kRuntime = r'''

const from=(data,parent=null)=>{
 if(data.nodeType!==1){const node={nodeType:data.nodeType,data:data.data,nodeValue:data.data,parentNode:parent,parentElement:parent,isConnected:true};Object.defineProperty(node,'textContent',{get:()=>node.data,set:value=>{node.data=value;node.nodeValue=value;}});return node;}
 const attrs={...data.attributes};
 const node={nodeType:1,namespaceURI:data.namespaceURI,localName:data.localName,
  tagName:data.localName.toUpperCase(),parentNode:parent,parentElement:parent,isConnected:true,style:{},
  getAttribute:name=>Object.hasOwn(attrs,name)?attrs[name]:null,
  hasAttribute:name=>Object.hasOwn(attrs,name),
  setAttribute:(name,value)=>{attrs[name]=value;},removeAttribute:name=>{delete attrs[name];}};
 node.childNodes=data.childNodes.map(child=>from(child,node));
 node.cloneNode=()=>from(data,node.parentElement);
 Object.defineProperty(node,'children',{get:()=>node.childNodes.filter(child=>child.nodeType===1)});
 Object.defineProperty(node,'attributes',{configurable:true,get:()=>Object.entries(attrs).map(([name,value])=>({name,value}))});
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
global.location={href:'file:///owned/stage-callback-source.html'};
global.window={__coui_parity_color_keys__:new Set()};
global.Node={TEXT_NODE:3};
global.NodeFilter={SHOW_TEXT:4};
let cssReads=0;
global.getComputedStyle=node=>{cssReads++;return {
 display:'block',visibility:'visible',position:'static',overflowX:'visible',overflowY:'visible',clip:'auto',opacity:'1',
 paddingTop:node===padding?'2px':'901px',paddingRight:node===padding?'3px':'902px',
 paddingBottom:node===padding?'5px':'903px',paddingLeft:node===padding?'7px':'904px',
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
  String phase = '',
}) async {
  final selector = actual.entry.probes.single.webSelector;
  final descriptor = clientBoxSourceDescriptor(
    actual.entry,
    additiveBoxObservations: true,
  )!;
  final actualBox =
      '(request) => { ownPhase=true; '
      'return ($boxPaddingObservationScript)(request); }';
  final sampler = legacyOnly
      ? '(request) => ($computedStyleProbeScript)(request.selector)'
      : combined
      ? sourceValidatedComputedStyleAndBoxScript(actualBox)
      : boxPaddingObservationScript;
  final program =
      '''
$_kRuntime
const capture=from(${jsonEncode(actual.capture)}),root=capture.children[0],padding=root.children[0],body=padding.children[0];
const selector=${jsonEncode(selector)};
global.CustomEvent=class {constructor(type,options){this.type=type;this.detail=options.detail;}};
global.document={querySelector:sel=>sel===selector?root:null,querySelectorAll:sel=>sel===selector?[root]:[],
 createTreeWalker:node=>{const queue=[];const visit=n=>{for(const c of n.childNodes){if(c.nodeType===3)queue.push(c);else if(c.nodeType===1)visit(c);}};visit(node);return {nextNode:()=>queue.shift()||null};}};
const request={requested:true,selector,layoutSelector:selector,
 source:${jsonEncode(actual.entry.probes.single.boxObservationSource!.toJson())},
 currentClientBoxSource:${jsonEncode(descriptor)}};
const own=node=>({namespaceURI:node.namespaceURI,localName:node.localName,
 attributes:Object.fromEntries(Array.from(node.attributes).map(a=>[a.name,a.value]))});
const receipt={...request.currentClientBoxSource,currentRaw:{kind:'current-client-stage-callback-padding-v1',
 quantityBoundary:'original-stage-frame-to-opaque-callback-content',callbackReexecuted:false,bodyInteriorIsSourceAuthority:false,
 capture:own(capture),frame:own(root),paddingOwner:own(padding),opaqueRoot:{namespaceURI:body.namespaceURI,localName:body.localName},
 ownedNodeOrder:['capture','frame','paddingOwner','opaqueRoot']},completeRawSlotCount:1,rawOrderFromPublicProducerLists:true,harnessURL:location.href};
let typedOK=true,eventRequests=0,typedReads=0,ownPhase=false,respond=true;
let reply={receipt,capture,layoutRoot:root,paddingOwner:padding,opaqueRoot:body,
 validateCurrentBinding:observed=>{typedReads++;return typedOK&&observed===originalReply&&originalReply.receipt===receipt;}};
const originalReply=reply;
capture.dispatchEvent=event=>{eventRequests++;if(respond)event.detail.response=reply;};
const originalCSS=getComputedStyle;let fired=false;
const mutate=()=>{$mutation};
const phase=${jsonEncode(phase)};
if(phase){global.getComputedStyle=node=>{
 if(!fired&&((phase==='legacy'&&!ownPhase)||(phase==='own'&&ownPhase&&node===padding))){fired=true;mutate();}
 return originalCSS(node);};}else{mutate();}
let observed,error;
try{observed=JSON.parse(($sampler)(request));}catch(e){error=String(e);}
console.log(JSON.stringify({observed,error,cssReads,eventRequests,typedReads,mutationFired:fired}));
''';
  final directory = await Directory.systemTemp.createTemp(
    'coui-parity-stage-client-node-',
  );
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

void main() {
  for (final theme in ['light', 'dark']) {
    test(
      'Stage client protocol $theme preserves frame and reads only inner CSS',
      () async {
        final actual = _actual(theme);
        final legacy = await _sample(actual, legacyOnly: true);
        final current = await _sample(actual, combined: true);
        expect(current['error'], isNull);
        final row = current['observed']! as Map;
        expect(row['legacy'], legacy['observed']);
        expect((row['box']! as Map)['status'], 'source-complete');
        expect((row['box']! as Map)['value'], [2, 3, 5, 7]);
        expect((row['box']! as Map)['ownerIsLayoutRoot'], false);
        expect((row['box']! as Map)['clientDomWholeTreeValidated'], false);
        expect((row['box']! as Map)['clientOwnedPrefixValidated'], true);
        expect(current['eventRequests'], 2);
        expect(current['typedReads']! as int, greaterThanOrEqualTo(3));
      },
    );
  }
  final initial = <String, String>{
    'missing client descriptor': 'delete request.currentClientBoxSource;',
    'wrong client kind': 'request.currentClientBoxSource.kind="foreign";',
    'SSR fallback forbidden':
        'request.requiredCurrentSsrKind="canonical-ssr-stage-callback-v1";',
    'missing typed responder': 'respond=false;',
    'false typed authority': 'typedOK=false;',
    'initial cloned reply rejected': 'reply={...reply};',
    'wrong source tuple': 'request.source.webAdapterId="foreign";',
    'extra source field': 'request.source.extra=true;',
    'receipt wrong kind': 'receipt.kind="foreign";',
    'receipt missing own record': 'delete receipt.currentRaw.paddingOwner;',
    'receipt wrong quantity': 'receipt.currentRaw.quantityBoundary="foreign";',
    'receipt incomplete raw roster': 'receipt.completeRawSlotCount=0;',
    'response stale frame': 'reply.layoutRoot=root.cloneNode();',
    'unrecorded formatter text':
        'capture.childNodes.unshift(from({nodeType:3,data:" "},capture));',
    'duplicate frame selector': 'document.querySelectorAll=()=>[root,root];',
    'convenient inner selector': 'document.querySelectorAll=()=>[padding];',
    'own attrs mismatch': 'padding.setAttribute("data-changed","yes");',
  };
  for (final c in initial.entries) {
    test('Stage client rejects before CSS ${c.key}', () async {
      final row = await _sample(
        _actual('light'),
        combined: true,
        mutation: c.value,
      );
      expect(row['error'], isNotNull);
      expect(row['cssReads'], 0);
    });
  }
  final held = <String, String>{
    'typed rebuild with same DOM': 'typedOK=false;',
    'receipt source clone': 'receipt.source={...receipt.source};',
    'nested owned record clone':
        'receipt.currentRaw.frame={...receipt.currentRaw.frame};',
    'descriptor clone':
        'request.currentClientBoxSource={...request.currentClientBoxSource};',
    'source clone': 'request.source={...request.source};',
    'selector mutation': 'request.selector="foreign";',
    'owned attr mutation': 'padding.setAttribute("data-changed","yes");',
    'opaque root detached': 'body.isConnected=false;',
    'typed validator replacement': 'reply.validateCurrentBinding=()=>true;',
  };
  for (final phase in ['legacy', 'own']) {
    for (final c in held.entries) {
      test('Stage client holds ${c.key} during real $phase CSS', () async {
        final health = await _sample(_actual('light'), combined: true);
        expect(health['error'], isNull);
        final row = await _sample(
          _actual('light'),
          combined: true,
          mutation: c.value,
          phase: phase,
        );
        expect(row['mutationFired'], true);
        expect(
          row['error'],
          contains(
            phase == 'legacy'
                ? 'STAGE_CALLBACK_BINDING_CHANGED_DURING_LEGACY_READ'
                : 'STAGE_CALLBACK_BINDING_CHANGED_DURING_BOX_READ',
          ),
        );
      });
    }
  }
  test('Stage client ignores the entire opaque root interior', () async {
    final row = await _sample(
      _actual('light'),
      mutation: '''
Object.defineProperty(body,'attributes',{get:()=>{throw new Error('foreign attrs read');}});
Object.defineProperty(body,'childNodes',{get:()=>{throw new Error('foreign children read');}});
Object.defineProperty(body,'textContent',{get:()=>{throw new Error('foreign text read');}});
Object.defineProperty(body,'outerHTML',{get:()=>{throw new Error('foreign serialization');}});
''',
    );
    expect(row['error'], isNull);
    expect((row['observed']! as Map)['status'], 'source-complete');
  });
}
