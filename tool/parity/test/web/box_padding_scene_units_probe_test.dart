import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/web/box_padding_scene_units_probe.dart';

const BoxObservationSourceSpec _card = BoxObservationSourceSpec.wholeDocCard;

const BoxObservationSourceSpec _size = BoxObservationSourceSpec.docsSizePreview;

Future<Map<String, Object?>> _resolve(
  String fixture, {
  bool card = false,
  bool size = false,
}) async {
  final result = await Process.run('node', [
    '-e',
    '''
const resolve = ($documentationBoxSourceResolverScript);
global.getComputedStyle = () => { throw Error('Numeric CSS read is forbidden'); };
const node = (tagName, classes, children = [], href = false, attrs = {}) => {
  const names = [...classes]; names.contains = name=>names.includes(name);
  const attributes = {...attrs}; if (href) attributes.href='';
  const value = {tagName, classList:names, children, parentElement:null,
    hasAttribute:name=>Object.hasOwn(attributes,name),
    getAttribute:name=>Object.hasOwn(attributes,name) ? attributes[name] : null,
    setAttribute:(name,text)=>{attributes[name]=String(text);},
    removeAttribute:name=>{delete attributes[name];}};
  for (const child of children) child.parentElement=value;
  Object.defineProperty(value,'offsetWidth',{get(){throw Error('Layout read is forbidden');}});
  return value;
};
const source = ${jsonEncode((size
        ? _size
        : card
        ? _card
        : BoxObservationSourceSpec.docsStage).toJson())};
$fixture
const value = resolve(root, source);
console.log(JSON.stringify(value.error ? value : {
  paddingIsRoot:value.paddingSource===root, frameIsRoot:value.frameSource===root,
  unitIsRoot:value.fieldUnitElement===root,
  registryIsRoot:value.registryResultElement===root,
  registryIsParent:value.registryResultElement===root.parentElement,
  paddingIsPreview:value.paddingSource===root.children[0],
  unitIsPreview:value.fieldUnitElement===root.children[0],
  frameIsPreview:value.frameSource===root.children[0],
  authority:value.authority
}));
''',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
  return jsonDecode(result.stdout.toString()) as Map<String, Object?>;
}

// Direct sibling signature from the retained a993 read-only DOM diagnosis.
// The target subtree is not inspected and no browser result is regenerated.
const String _actualAnatomyJson = '''
{
  "tag": "DIV",
  "classes": [
    "docs-stage",
    "docs-stage--240",
    "docs-anatomy-stage"
  ],
  "connected": true,
  "specs": "container@;leading@;label@;trailing@",
  "directChildren": [
    {
      "tag": "DIV",
      "classes": [
        "docs-anatomy-target"
      ],
      "dataIndex": null,
      "ariaHidden": null,
      "markerText": null,
      "isDirectTarget": true
    },
    {
      "tag": "SPAN",
      "classes": [
        "docs-anatomy-marker",
        "is-left"
      ],
      "dataIndex": "0",
      "ariaHidden": "true",
      "markerText": "1",
      "isDirectTarget": false
    },
    {
      "tag": "SPAN",
      "classes": [
        "docs-anatomy-marker",
        "is-top"
      ],
      "dataIndex": "1",
      "ariaHidden": "true",
      "markerText": "2",
      "isDirectTarget": false
    },
    {
      "tag": "SPAN",
      "classes": [
        "docs-anatomy-marker",
        "is-top"
      ],
      "dataIndex": "2",
      "ariaHidden": "true",
      "markerText": "3",
      "isDirectTarget": false
    },
    {
      "tag": "SPAN",
      "classes": [
        "docs-anatomy-marker",
        "is-top"
      ],
      "dataIndex": "3",
      "ariaHidden": "true",
      "markerText": "4",
      "isDirectTarget": false
    }
  ]
}
''';
const String _anatomyFixture =
    '''
const observed = $_actualAnatomyJson;
const root=node(observed.tag,observed.classes,observed.directChildren.map(child=>
  node(child.tag,child.classes,[],false,{
    ...(child.dataIndex===null ? {} : {'data-index':child.dataIndex}),
    ...(child.ariaHidden===null ? {} : {'aria-hidden':child.ariaHidden})
  })
),false,{'data-docs-anatomy':observed.specs});
''';

void main() {
  test(
    'Anatomy accepts the actual target plus four generated markers',
    () async {
      final result = await _resolve(_anatomyFixture);
      expect(result['paddingIsRoot'], true);
      expect(result['frameIsRoot'], true);
      expect(result['unitIsRoot'], true);
    },
  );
  test(
    'Anatomy SSR target-only and not-yet-positioned markers stay valid',
    () async {
      final ssr = await _resolve('$_anatomyFixture\nroot.children.splice(1);');
      expect(ssr['paddingIsRoot'], true);
      final unplaced = await _resolve(
        '''
$_anatomyFixture
for(const child of root.children.slice(1)) child.classList.splice(1);
''',
      );
      expect(unplaced['paddingIsRoot'], true);
    },
  );
  test(
    'Anatomy indices preserve source holes instead of renumbering',
    () async {
      final result = await _resolve('''
$_anatomyFixture
root.setAttribute('data-docs-anatomy','container@;;label@;trailing@');
root.children.splice(2,1);
''');
      expect(result['paddingIsRoot'], true);
    },
  );
  test('Anatomy position comes from the exact last-at source side', () async {
    final result = await _resolve('''
$_anatomyFixture
root.setAttribute('data-docs-anatomy',
  'container@right;[data-part="a@b"]@right;label@;trailing@');
root.children[1].classList.splice(1,1,'is-right');
root.children[2].classList.splice(1,1,'is-right');
''');
    expect(result['paddingIsRoot'], true);
  });
  for (final (name, setup, error) in <(String, String, String)>[
    (
      'unknown sibling',
      '''
root.children.push(node('DIV',['unowned']));
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
    (
      'duplicate target',
      '''
root.children.push(node('DIV',['docs-anatomy-target']));
''',
      'DOCS_ANATOMY_SOURCE_CHANGED',
    ),
    (
      'duplicate index',
      '''
root.children[2].setAttribute('data-index','0');
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
    (
      'out of range',
      '''
root.children[4].setAttribute('data-index','4');
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
    (
      'noncanonical index',
      '''
root.children[1].setAttribute('data-index','00');
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
    (
      'empty part',
      '''
root.setAttribute('data-docs-anatomy','@;leading@;label@;trailing@');
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
    (
      'missing source spec',
      '''
root.removeAttribute('data-docs-anatomy');
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
    (
      'missing data index',
      '''
root.children[1].removeAttribute('data-index');
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
    (
      'wrong tag',
      '''
root.children[1]=node('DIV',['docs-anatomy-marker','is-left'],[],false,
  {'data-index':'0','aria-hidden':'true'});
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
    (
      'aria missing',
      '''
root.children[1].removeAttribute('aria-hidden');
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
    (
      'aria false',
      '''
root.children[1].setAttribute('aria-hidden','false');
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
    (
      'wrong side',
      '''
root.children[1].classList.splice(1,1,'is-right');
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
    (
      'extra marker class',
      '''
root.children[1].classList.push('foreign');
''',
      'DOCS_ANATOMY_MARKER_SOURCE_CHANGED',
    ),
  ]) {
    test('Anatomy rejects $name without an owner or value', () async {
      final result = await _resolve('$_anatomyFixture\n$setup');
      expect(result, {'error': error});
    });
  }

  const sizeFixture = '''
const preview = node('DIV',['docs-stage','docs-stage--hug','docs-stage--row'],[
  node('FIGURE',['docs-size-item'],[
    node('BUTTON',[]),node('FIGCAPTION',[],[node('CODE',[])])
  ])
]);
const table = node('DIV',['docs-table'],[
  node('TABLE',[],[node('THEAD',[]),node('TBODY',[])])
]);
const root=node('DIV',['docs-size-spec'],[preview,table]);
''';
  test(
    'SizeSpec keeps registry root and returns only its source preview',
    () async {
      final result = await _resolve(sizeFixture, size: true);
      expect(result['registryIsRoot'], true);
      expect(result['unitIsPreview'], true);
      expect(result['paddingIsPreview'], true);
      expect(result['frameIsPreview'], true);
      expect(result['paddingIsRoot'], false);
    },
  );
  test(
    'SizeSpec missing or duplicated branch cannot select another box',
    () async {
      final missing = await _resolve(
        '$sizeFixture\nroot.children.pop();',
        size: true,
      );
      expect(missing, {'error': 'DOCS_SIZE_SPEC_SOURCE_CHANGED'});
      final duplicate = await _resolve(
        '$sizeFixture\nroot.children[0]=table;',
        size: true,
      );
      expect(duplicate, {'error': 'DOCS_SIZE_PREVIEW_SOURCE_CHANGED'});
    },
  );
  test(
    'SizeSpec wrong table and caption routes return no owner or value',
    () async {
      final table = await _resolve(
        '$sizeFixture\ntable.children[0].children.reverse();',
        size: true,
      );
      expect(table, {'error': 'DOCS_SIZE_TABLE_SOURCE_CHANGED'});
      final caption = await _resolve(
        '$sizeFixture\npreview.children[0].children.pop();',
        size: true,
      );
      expect(caption, {'error': 'DOCS_SIZE_PREVIEW_CONTENT_CHANGED'});
    },
  );
  test(
    'SizeSpec unknown adapter is not accepted from matching classes',
    () async {
      final result = await _resolve(
        '$sizeFixture\nsource.webAdapterId="unknown";',
        size: true,
      );
      expect(result, {'error': 'BOX_SOURCE_ADAPTER_UNIT_MISMATCH'});
    },
  );

  for (final classes in ['docs-stage', 'docs-stage docs-stage--compact']) {
    test(
      'stage $classes returns the same declared references without CSS reads',
      () async {
        final result = await _resolve(
          "const root=node('DIV',${jsonEncode(classes.split(' '))});",
        );
        expect(result['paddingIsRoot'], true);
        expect(result['frameIsRoot'], true);
        expect(result['registryIsRoot'], true);
      },
    );
  }
  test('Anatomy requires its exact direct target branch', () async {
    final result = await _resolve(
      '''
const root=node('DIV',['docs-stage','docs-anatomy-stage'],[
  node('DIV',['docs-anatomy-target'])
]);
''',
    );
    expect(result['paddingIsRoot'], true);
    final missing = await _resolve(
      "const root=node('DIV',['docs-stage','docs-anatomy-stage']);",
    );
    expect(missing, {'error': 'DOCS_ANATOMY_SOURCE_CHANGED'});
  });
  for (final tag in ['DIV', 'A']) {
    test(
      'whole-card $tag returns the direct group child, not caption or preview',
      () async {
        final result = await _resolve(
          '''
const root=node('$tag',['docs-card'],[
  node('DIV',['docs-stage']),node('DIV',['docs-card-body'])
],${tag == 'A'});
node('DIV',['docs-cards'],[root]);
''',
          card: true,
        );
        expect(result['paddingIsRoot'], true);
        expect(result['unitIsRoot'], true);
        expect(result['registryIsParent'], true);
      },
    );
  }
  test(
    'missing or duplicate group membership cannot borrow a nested card',
    () async {
      final missing = await _resolve(
        '''
const root=node('DIV',['docs-card']);
node('DIV',['foreign'],[root]);
''',
        card: true,
      );
      expect(missing, {'error': 'DOCS_CARD_DIRECT_GROUP_CHANGED'});
      final duplicate = await _resolve(
        '''
const root=node('DIV',['docs-card']);
node('DIV',['docs-cards'],[root,node('DIV',['docs-card'])]);
''',
        card: true,
      );
      expect(duplicate, {'error': 'DOCS_CARD_CARDINALITY_CHANGED'});
    },
  );
  test(
    'wrong href branch fails without returning any owner or value',
    () async {
      final result = await _resolve(
        '''
const root=node('A',['docs-card']);
node('DIV',['docs-cards'],[root]);
''',
        card: true,
      );
      expect(result, {'error': 'DOCS_CARD_HREF_BRANCH_CHANGED'});
    },
  );
  test(
    'SizeSpec row and unknown adapter are not generalized to stage',
    () async {
      final row = await _resolve(
        '''
const root=node('DIV',['docs-stage','docs-stage--row']);
''',
      );
      expect(row, {'error': 'DOCS_STAGE_SOURCE_CHANGED'});
      final unknown = await _resolve(
        '''
source.nativeAdapterId='unknown';
const root=node('DIV',['docs-stage']);
''',
      );
      expect(unknown, {'error': 'BOX_SOURCE_ADAPTER_UNIT_MISMATCH'});
    },
  );
}
