import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

/// 사이드바 스크롤을 페이지 이동 너머로 이어 준다.
///
/// 이 사이트는 정적 생성이라 사이드바 링크는 전체 페이지 로드이고, 사이드바
/// (`.docs-sidebar`)는 로드마다 `scrollTop` 0 으로 새로 그려진다. 이전
/// 페이지에서 저장한 위치를 `sessionStorage` 에서 읽어 되돌린다.
///
/// 위치는 탭마다 따로 기억한다 — 탭이 다르면 사이드바의 목록이 다르므로,
/// 한 탭에서 내려 둔 위치를 다른 탭에 되돌리면 엉뚱한 줄이 맨 위에 온다.
///
/// **복원은 사이드바 요소 바로 뒤에서 동기로 한다.** `DOMContentLoaded` 에서 하면
/// 안 된다 — 그 이벤트는 `defer` 스크립트(클라이언트 번들 포함)가 다 실행될 때까지
/// 기다리는데, 그것들이 느리면 브라우저가 복원 전에 사이드바를 맨 위로 먼저 그린다.
/// 더 나쁜 건 그 틈에 링크를 누르면 떠나는 페이지의 저장이 아직 복원 안 된 `0` 으로
/// 정상 저장값을 덮어쓴다는 점이다. 요소가 파싱된 직후에 복원하면 첫 페인트 전에
/// 끝나고, 저장 리스너를 복원 뒤에 달아 그 덮어쓰기가 구조적으로 일어나지 않는다.
class SidebarScrollRestore extends StatelessComponent {
  const SidebarScrollRestore({super.key});

  @override
  Component build(BuildContext context) {
    return Component.element(tag: 'script', children: [RawText(kSidebarScrollScript)]);
  }
}

/// `sessionStorage` 키의 앞머리 — 뒤에 탭의 id 가 붙는다.
const kSidebarScrollKey = 'coui-sidebar-scroll';

/// 스크롤을 이어 주는 요소 — 문서 레이아웃의 사이드바.
const kSidebarScrollSelector = '.docs-sidebar';

/// 복원 → 저장 순서로 한 번 실행되는 인라인 스크립트.
///
/// 저장소 접근은 전부 `try` 안이다 — 저장소가 막힌 환경(서드파티 쿠키 차단 등)에서
/// `sessionStorage` 접근이 던지면 스크립트 전체가 죽는다.
const kSidebarScrollScript =
    '''
(function(){
var e=document.querySelector("$kSidebarScrollSelector");
if(!e)return;
var s=document.getElementById("docs-shell"),K="$kSidebarScrollKey:"+((s&&s.getAttribute("data-docs-tab"))||"");
try{var v=sessionStorage.getItem(K);if(v!==null)e.scrollTop=parseFloat(v)||0}catch(_){}
function save(){try{sessionStorage.setItem(K,String(e.scrollTop))}catch(_){}}
var t=0;
e.addEventListener("scroll",function(){if(t)return;t=requestAnimationFrame(function(){t=0;save()})},{passive:true});
addEventListener("pagehide",save);
addEventListener("beforeunload",save)
})()
''';
