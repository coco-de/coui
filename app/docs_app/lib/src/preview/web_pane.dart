/// 라이브 프리뷰의 Web 페인 — coui_web 컴포넌트를 in-process 로 렌더해 띄운다.
library;

import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/preview/web_render.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Web 프리뷰 페인.
///
/// 이 페인은 docs_site 의 `EmbedPage` 를 자기 프로세스에서 HTML 로 렌더한 뒤
/// [WebViewController.loadHtmlString] 으로 띄운다 — jaspr serve 도, localhost
/// 도, adb reverse 도 필요 없다. HTML 은 사이트와 같은 head(Tailwind/폰트
/// CDN·CoUI CSS 변수·테마)를 담으므로 WebView 가 CDN 을 기기 인터넷으로
/// 가져와 사이트와 동일하게 그린다.
///
/// 렌더가 불가능하거나(예: Flutter Web — jaspr 서버 렌더러가 dart:io 의존)
/// WebView 구현이 없으면 깨진 화면 대신 안내로 저하한다.
class DocsWebPane extends StatefulWidget {
  /// [component] (+선택적 [variant]) 의 Web 프리뷰를 만든다.
  const DocsWebPane({
    required this.component,
    this.variant,
    this.chainStep,
    super.key,
  });

  /// 프리뷰할 컴포넌트 슬러그 (예: `button`).
  final String component;

  /// 프리뷰할 변형 (예: `primary`). 없으면 기본 프리뷰.
  final String? variant;

  /// chain 순열 고정 step — 셔플이 값을 바꾸면 HTML 을 그 좌표로 다시
  /// 렌더한다. WebView 안에는 Dart 힙이 없어 스토어 직결이 불가능하므로,
  /// 이 페인의 chain 동기화는 스토어 구독(호스트)이 아니라 재렌더다.
  final int? chainStep;

  @override
  State<DocsWebPane> createState() => _DocsWebPaneState();
}

class _DocsWebPaneState extends State<DocsWebPane> {
  WebViewController? _controller;

  /// 마지막으로 렌더한 (컴포넌트·변형·테마) 키. 테마가 뒤집히면 값이 달라져
  /// 재렌더를 부른다.
  String? _loadedKey;

  /// 렌더/표시가 불가능하면 사유. `null` 이면 아직 실패하지 않았다.
  String? _failure;

  /// 이 호스트에 WebView 구현이 실제로 등록돼 있나?
  ///
  /// `WebViewController()` 는 등록된 플랫폼이 없으면 assert 로 죽는다. 위젯
  /// 테스트와 webview 가 없는 호스트가 정확히 그 상태라, 확인 없이 만들면
  /// Web 페인이 페이지 전체를 끌고 넘어진다 — 이 페인은 없어도 되는
  /// 부속이지 페이지를 죽일 권한이 없다.
  static bool get _hasWebViewPlatform => WebViewPlatform.instance != null;

  /// 컨트롤러가 없으면 만들어 설정한다.
  ///
  /// 필드 반영은 호출부가 `setState` 로 한다 — 그 rebuild 가 로딩 표시를
  /// [WebViewWidget] 으로 교체한다.
  WebViewController _ensureController() {
    final existing = _controller;
    if (existing != null) return existing;
    final controller = WebViewController();
    // CDN 스크립트(Tailwind)와 CoUI 클라이언트 JS 가 돌도록.
    unawaited(controller.setJavaScriptMode(.unrestricted));
    // 페인 배경과 섞이도록 투명하게.
    unawaited(controller.setBackgroundColor(const Color(0x00000000)));
    return controller;
  }

  /// 컴포넌트를 in-process 로 렌더해 WebView 에 싣는다.
  Future<void> _render({required bool dark}) async {
    if (!_hasWebViewPlatform) {
      _fail('WebView 를 쓸 수 없는 호스트');
      return;
    }
    // 렌더러는 예외를 삼키지 않는다 — 여기서 잡아 실제 사유를 화면에 노출한다.
    final String? html;
    try {
      html = await renderWebPreviewHtml(
        component: widget.component,
        dark: dark,
        variant: widget.variant,
        chainStep: widget.chainStep,
      );
    } on Object catch (error) {
      _fail('$error');
      return;
    }
    if (!mounted) return;
    if (html == null) {
      _fail('이 플랫폼에서는 Web 프리뷰를 렌더할 수 없습니다');
      return;
    }
    final controller = _ensureController();
    // WebView 가 아직 화면에 없어도 loadHtmlString 은 큐잉된다.
    //
    // baseUrl 을 준다 — 없으면 콘텐츠 origin 이 `about:blank`(opaque)라 폰트
    // 같은 cross-origin 리소스가 CORS 로 막혀 Pretendard 가 시스템 폰트로
    // 폴백한다. 실제 https origin 을 주면 사이트와 동일하게 CDN 폰트가 뜬다.
    // 고정폭(Geist Mono)만은 CDN 이 아니라 사이트 루트 기준 경로
    // (`/assets/packages/coui_flutter/…`)라 이 주소로 풀려 배포된 사이트에서
    // 내려받는다 — 사이트의 Flutter 판이 그리는 바로 그 파일이다.
    unawaited(
      controller
          .loadHtmlString(html, baseUrl: 'https://coui.cocode.im/')
          .catchError((Object error) {
            _fail('$error');
          }),
    );
    if (_failure == null) {
      setState(() => _controller = controller);
    }
  }

  void _fail(String reason) {
    if (!mounted || _failure == reason) return;
    setState(() => _failure = reason);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRender();
  }

  @override
  void didUpdateWidget(DocsWebPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 셔플이 chainStep 을 바꾸면 위젯 파라미터만 갱신된다 — 의존성 콜백이
    // 안 오므로 여기서도 같은 키 판정을 태운다.
    _syncRender();
  }

  /// (컴포넌트·변형·chainStep·테마) 키가 달라졌을 때만 재렌더한다.
  void _syncRender() {
    // 테마는 여기서만 읽는다 — 폴링하지 않는다. 라이트↔다크 전환이
    // didChangeDependencies 를 부르고, 그때 키가 달라져 재렌더된다.
    final dark = Theme.of(context).brightness == .dark;
    final key =
        '${widget.component}/${widget.variant ?? ''}/${widget.chainStep ?? ''}/$dark';
    if (key == _loadedKey) return;
    _loadedKey = key;
    _failure = null;
    unawaited(_render(dark: dark));
  }

  @override
  Widget build(BuildContext context) {
    // 높이는 부모(`_PreviewPane` 의 SizedBox)가 정한다 — Flutter 페인과 같은
    // 높이를 써야 정렬된다. 여기서는 상태에 맞는 위젯만 돌려주고 그게 부모
    // 높이를 채운다.
    //
    // 첫 프레임은 렌더가 비동기라 컨트롤러가 없다 — 그때 실패 안내를 띄우면
    // 성공 케이스도 순간 "표시할 수 없습니다" 가 번쩍이므로 로딩을 보인다.
    final controller = _controller;
    final failure = _failure;
    if (failure != null) return _WebPreviewUnavailable(reason: failure);
    if (controller == null) return const Center(child: Loading());
    return WebViewWidget(controller: controller);
  }
}

/// 렌더/표시가 불가능할 때 Web 페인 자리에 놓는 안내.
class _WebPreviewUnavailable extends StatelessWidget {
  const _WebPreviewUnavailable({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final currentReason = reason;

    return Center(
      child: Padding(
        padding: const .all(CoreSpace.space16),
        child: Column(
          mainAxisSize: .min,
          children: [
            const Icon(
              LucideIcons.cloudOff,
              iconStyle: CoreIconStyle(size: CoreSize.size20),
            ),
            const Gap.space8(),
            const Text(
              'Web 프리뷰를 표시할 수 없습니다',
              textAlign: .center,
            ).bodySmall.onSurfaceVariant,
            if (currentReason != null) ...[
              const Gap.space4(),
              Text(
                currentReason,
                textAlign: .center,
              ).labelSmall.onSurfaceVariant,
            ],
          ],
        ),
      ),
    );
  }
}
