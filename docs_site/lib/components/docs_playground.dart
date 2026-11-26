/// 컴포넌트 페이지(v2 템플릿)의 플레이그라운드 — 무대 · 컨트롤 · 코드.
///
/// ```md
/// <Playground component="button" />
/// ```
///
/// ```text
/// div.docs-playground
///   ├─ div.docs-playground-main
///   │    ├─ div.docs-playground-stage
///   │    │    ├─ ToggleGroup               // Jaspr Web · Flutter · 나란히
///   │    │    └─ div.docs-playground-panes  // 웹 팬 · Flutter 팬
///   │    └─ div.docs-playground-controls    // spec 의 컨트롤
///   └─ DocsCode                             // 속성에서 만든 코드
/// ```
///
/// 컨트롤 · 미리보기 · 코드가 하나의 속성 묶음(`playground_spec.dart`)에서
/// 나온다. Flutter 팬은 같은 Dart 힙의 스토어(`playground_store.dart`)로
/// 속성을 받는다 — 컨트롤을 바꾸면 두 팬이 같은 속성으로 다시 그린다.
///
/// Flutter 팬은 처음 고를 때 만들고, 다른 플랫폼으로 바꿔도 지우지 않고
/// 숨긴다 — 임베드를 다시 만들면 Flutter 앱이 처음부터 다시 뜬다.
library;

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/internal/preview/web_playground_view.dart';
import 'package:docs_core/shared/playground_spec.dart';
import 'package:docs_core/shared/playground_store.dart';

export 'package:docs_core/internal/preview/web_playground_view.dart' show DocsPlaygroundPlatform;

import 'docs_code.dart';
import 'flutter_preview.dart';

/// 무대에서 고를 수 있는 플랫폼.

/// 플레이그라운드 아일랜드.
@client
class DocsPlayground extends StatefulComponent {
  /// [component] 는 문서 슬러그, [panelId] 는 페이지에서 유일한 id.
  const DocsPlayground({required this.component, required this.panelId, super.key});

  /// 문서 슬러그 — `kDocsPlaygrounds` 의 키.
  final String component;

  /// 스토어 · 임베드 id 의 키.
  final String panelId;

  @override
  State<DocsPlayground> createState() => _DocsPlaygroundState();
}

class _DocsPlaygroundState extends State<DocsPlayground> {
  late Map<String, String> _props;
  DocsPlaygroundPlatform _platform = DocsPlaygroundPlatform.web;
  bool _flutterMounted = false;

  DocsPlaygroundSpec? get _spec => kDocsPlaygrounds[component.component];

  @override
  void initState() {
    super.initState();
    _props = {...?_spec?.initial};
  }

  void _setProps(Map<String, String> props) {
    setState(() => _props = props);
    playgroundStore.set(component.panelId, props);
  }

  void _setPlatform(DocsPlaygroundPlatform platform) {
    setState(() {
      _platform = platform;
      if (platform != DocsPlaygroundPlatform.web) _flutterMounted = true;
    });
  }

  @override
  Component build(BuildContext context) {
    final spec = _spec;
    if (spec == null) return const Component.empty();
    final showWeb = _platform != DocsPlaygroundPlatform.flutter;
    final showFlutter = _platform != DocsPlaygroundPlatform.web;

    // 아일랜드는 페이지의 테마 밖에서 깨어난다 — 미리보기 팬(`WebPreview`)과
    // 같이 `CoUIWeb` 이 테마와 언어를 준다. 제목은 데스크톱 크기로 고정한다.
    return buildWebPlaygroundRoot(_body(spec, showWeb: showWeb, showFlutter: showFlutter));
  }

  Component _body(
    DocsPlaygroundSpec spec, {
    required bool showWeb,
    required bool showFlutter,
  }) => buildWebPlaygroundView(
    componentName: component.component,
    spec: spec,
    props: _props,
    platform: _platform,
    showWeb: showWeb,
    showFlutter: showFlutter,
    flutterContent: _flutterMounted
        ? FlutterPreviewContent(component: component.component, variant: kPlaygroundVariant, panelId: component.panelId)
        : null,
    codeView: _codeView(spec),
    onSetProps: _setProps,
    onSetPlatform: _setPlatform,
  );

  /// 고른 플랫폼의 코드. 나란히 볼 때 두 플랫폼의 코드가 같으면 하나를,
  /// 다르면([DocsPlaygroundSpec.webCode]) 둘을 위아래로 보인다.
  Component _codeView(DocsPlaygroundSpec spec) {
    Component block(DocsCodePlatform platform, {String? title}) => DocsCode(
      source: spec.codeFor(platform, _props, spec.label),
      language: 'dart',
      title: title ?? platform.label,
    );
    return switch (_platform) {
      DocsPlaygroundPlatform.web => block(DocsCodePlatform.web),
      DocsPlaygroundPlatform.flutter => block(DocsCodePlatform.flutter),
      DocsPlaygroundPlatform.both when spec.codeDiffersByPlatform => Component.fragment([
        block(DocsCodePlatform.flutter),
        block(DocsCodePlatform.web),
      ]),
      DocsPlaygroundPlatform.both => block(DocsCodePlatform.flutter, title: 'Flutter · Jaspr Web'),
    };
  }
}
