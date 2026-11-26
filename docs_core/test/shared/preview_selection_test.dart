import 'dart:io';

import 'package:docs_core/shared/playground_spec.dart';
import 'package:docs_core/shared/size_spec.dart';
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/internal/preview/selection.dart';
import 'package:docs_core/internal/preview/web_scene.dart';
import 'package:jaspr_content/jaspr_content.dart' as content;
import 'package:markdown/markdown.dart' as markdown;
import 'package:test/test.dart';

void main() {
  test('frontmatter and indented code are not visible scenes', () {
    const source = '''
---
title: '<Preview component="unknown" />'
description: |
  <Card component="unknown" />
---

    <Preview component="unknown" />

<Preview component="button" label="Visible" />
''';
    final scenes = visibleDocsScenes(source, sourcePath: 'page.md');
    expect(scenes, hasLength(1));
    expect(scenes.single.selections.single.component, 'button');
    expect(scenes.single.selections.single.label, 'Visible');
  });

  test('visible attributes match the installed Jaspr parser, including comments and quoted entities', () {
    const source = '''
<!--
<Preview component="unknown" label="Hidden" />
-->
```html
<!-- this comment is an illustrative code fragment
```
<Cards>
<Card component="button" props="variant=outline" label="A &quot;quote&quot; &amp; &#39;single&#39; &#x1F642;" />
<Card component='button' label='Double "quote"' />
</Cards>
''';
    final document = markdown.Document(
      blockSyntaxes: content.MarkdownParser.defaultBlockSyntaxes,
      extensionSet: markdown.ExtensionSet.gitHubWeb,
    );
    final actual = <Map<String, String>>[];
    void visit(List<content.Node> nodes) {
      for (final node in nodes) {
        if (node is content.ElementNode) {
          if (node.tag == 'Card') actual.add(node.attributes);
          visit(node.children ?? const []);
        }
      }
    }

    visit(content.MarkdownParser.buildNodes(document.parse(source)));
    final scenes = visibleDocsScenes(source, sourcePath: 'page.md');
    expect(scenes, hasLength(2));
    expect(scenes.map((scene) => scene.attributes), actual);
    expect(scenes.first.selections.single.label, 'A "quote" & \'single\' 🙂');
  });

  test('whole Card descriptors keep raw Native input and standalone source layout', () {
    const source = """
<Cards>
<Card component="button" title="First">

A **clear** label.

</Card>
<Card component="button" title="Second">

A different label.

</Card>
</Cards>
""";
    final scenes = visibleDocsScenes(source, sourcePath: 'page.md');
    expect(scenes.map((scene) => scene.cardIndex), [0, 0]);
    expect(scenes.first.nativeCardBody, '\nA **clear** label.\n');
    expect(scenes.first.toJson()['captureUnit'], 'whole-card');
    expect(scenes.first.flutterOwnerType, 'FlutterDocsCardView');
    expect(() => DocsScene.fromJson({...scenes.first.toJson()}..remove('captureUnit')), throwsFormatException);
    final first = scenes.first;
    final roundTrip = DocsScene.fromJson(first.toJson());
    expect(roundTrip.reference, first.reference);
    expect(roundTrip.cardBody.map((node) => node.innerText).join(), contains('A clear label.'));
    final changed = visibleDocsScenes(source.replaceFirst('clear', 'specific'), sourcePath: 'page.md').first;
    expect(changed.reference, isNot(first.reference));
  });

  test('hidden Card candidates cannot invalidate visible inputs', () {
    const hidden = '''
<!--
<Card component="unknown" />
-->

    <Card component="unknown" />

```html
<Card component="unknown" />
```
''';
    final previewOnly = visibleDocsScenes(
      '$hidden\n<Preview component="button" label="Visible" />',
      sourcePath: 'page.md',
    );
    expect(previewOnly, hasLength(1));
    expect(previewOnly.single.tag, 'Preview');
    final withCard = visibleDocsScenes('''
$hidden
<Card component="button" title="Visible">

Real **Native** Markdown input.

</Card>
''', sourcePath: 'page.md');
    expect(withCard, hasLength(1));
    expect(withCard.single.nativeCardBody, '\nReal **Native** Markdown input.\n');
  });

  test('standalone Card deduplication ignores its former group position', () {
    final scenes = visibleDocsScenes('''
<Cards>
<Card component="button" label="Same" />
<Card component="button" label="Same" />
</Cards>
''', sourcePath: 'page.md');
    expect(scenes, hasLength(1));
    expect(scenes.single.origins, hasLength(2));
    expect(scenes.single.cardIndex, 0);
  });

  test('custom body nodes are accepted only by their actual view boundary', () {
    final card = visibleDocsScenes('''
<Card component="button">
<AnatomyItem part="container">Invalid inside Card.</AnatomyItem>
</Card>
''', sourcePath: 'page.md').single;
    expect(() => renderWebScene(card), throwsStateError);
    final anatomy = visibleDocsScenes('''
<Anatomy component="button">
<AnatomyItem part="container" name="Container">Valid description.</AnatomyItem>
</Anatomy>
''', sourcePath: 'page.md').single;
    expect(() => renderWebScene(anatomy), returnsNormally);
    final nested = visibleDocsScenes('''
<Anatomy component="button">
<AnatomyItem part="container"><AnatomyItem part="label">Invalid nested custom node.</AnatomyItem></AnatomyItem>
</Anatomy>
''', sourcePath: 'page.md').single;
    expect(() => renderWebScene(nested), throwsStateError);
  });

  test('the visible selector wins over unrelated attributes and extra props', () {
    final demo = PreviewSelection.attributes(
      {
        'demo': 'button/anatomy',
        'component': 'text-field',
        'example': 'error',
        'props': 'size=xs',
      },
      extraProps: {'size': 'lg'},
    );
    expect(demo.kind, PreviewSelectionKind.demo);
    expect(demo.name, 'button/anatomy');
    expect(demo.component, isNull);
    expect(demo.props, isEmpty);
    final example = PreviewSelection.attributes({'component': 'button', 'example': 'card', 'props': 'variant=plain'});
    expect(example.kind, PreviewSelectionKind.example);
    expect(example.name, 'card');
    expect(example.props, isEmpty);
    final props = PreviewSelection.attributes(
      {'component': 'button', 'props': 'size=xs;enabled;href=a=b', 'label': 'Save'},
      extraProps: {'size': 'lg'},
    );
    expect(props.props, {'size': 'lg', 'enabled': 'true', 'href': 'a=b'});
    expect(props.label, 'Save');
  });

  test('nested live nodes are captured but illustrative fenced examples are not', () {
    const source = '''
```dart
<Preview component="button" example="card" />
```
<Cards columns="2">
<Card component='button' props='variant=outline' label='Save'>
Use this.
</Card>
<Card demo=button/anatomy />
</Cards>
''';
    final scenes = visibleDocsScenes(source, sourcePath: 'page.md');
    expect(scenes, hasLength(2));
    expect(scenes[0].selections.single.props, {'variant': 'outline'});
    expect(scenes[0].selections.single.label, 'Save');
    expect(scenes[1].selections.single.name, 'button/anatomy');
    expect(scenes.every((scene) => scene.origins.single.startsWith('page.md:')), isTrue);
  });

  test('cold playground and size rows use the current original definitions', () {
    final scenes = visibleDocsScenes('''
<Playground component="button" />
<SizeSpec component="text-field" props="size=xs;placeholder=Mail" />
''', sourcePath: 'page.md');
    final spec = kDocsPlaygrounds['button']!;
    expect(scenes[0].selections.single.props, spec.initial);
    expect(scenes[0].selections.single.label, spec.label);
    expect(
      scenes[1].selections.map((selection) => selection.props['size']),
      docsSizeSpecFor('text-field')!.rows.map((row) => row.size.name),
    );
    expect(scenes[1].selections.every((selection) => selection.props['placeholder'] == 'Mail'), isTrue);
  });

  test('references keep all inputs and cannot fall back to an old default', () {
    final first = visibleDocsScenes(
      '<Preview component="button" props="variant=outline" label="A" />',
      sourcePath: 'a.md',
    ).single;
    final changed = visibleDocsScenes(
      '<Preview component="button" props="variant=outline" label="B" />',
      sourcePath: 'a.md',
    ).single;
    expect(first.reference, startsWith(docsScenePrefix));
    expect(first.reference, isNot(changed.reference));
    expect(DocsScene.fromJson(first.toJson()).reference, first.reference);
    final duplicate = visibleDocsScenes('''
<Preview component="button" props="variant=outline" label="A" />
<Preview component="button" props="variant=outline" label="A" />
''', sourcePath: 'a.md');
    expect(duplicate, hasLength(1));
    expect(duplicate.single.origins, hasLength(2));
    final directory = Directory.systemTemp.createTempSync('docs-scene-reference-');
    addTearDown(() => directory.deleteSync(recursive: true));
    File(
      '${directory.path}/button.md',
    ).writeAsStringSync('<Preview component="button" props="variant=outline" label="B" />');
    expect(() => resolveDocsScene('button', first.reference, contentDir: directory.path), throwsStateError);
    expect(() => visibleDocsScenes('<Playground component="unknown" />', sourcePath: 'a.md'), throwsStateError);
    expect(() => visibleDocsScenes('<SizeSpec component="unknown" />', sourcePath: 'a.md'), throwsStateError);
  });
}
