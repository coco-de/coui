import 'package:coui_web/coui_web.dart';

import 'site_theme_names.dart';

/// Names shown in the header, in the order they are offered.
///
/// The label is kept separate from `id.name` on purpose: the attribute
/// value is a code identifier the stylesheet keys off, and letting a
/// display string double as that key is how the two drift apart.
const _kOptions = <({CoreSurfaceStyleId id, String label})>[
  (id: CoreSurfaceStyleId.defaultStyle, label: 'Default'),
  (id: CoreSurfaceStyleId.neoBrutalism, label: 'Neo-brutalism'),
  (id: CoreSurfaceStyleId.liquidGlass, label: 'Liquid Glass'),
  (id: CoreSurfaceStyleId.neumorphism, label: 'Neumorphism'),
  (id: CoreSurfaceStyleId.claymorphism, label: 'Claymorphism'),
];

/// Header control that switches the whole page's surface style.
///
/// Renders a trigger plus a hidden panel of options, and nothing else.
/// The behaviour — restoring the stored choice before first paint,
/// opening and closing the panel, writing the document attribute on
/// click, and marking which option is current — lives in the page's
/// inline script, next to the sidebar-scroll and preview-tab handlers
/// that work the same way.
///
/// It is there rather than here because this site renders statically:
/// a component's `events:` map is a server-side closure and never
/// reaches the browser, so a handler written here would compile, ship
/// its markup, and silently do nothing. Making this a `@client` island
/// would attach the handler, but only once the client bundle has
/// loaded — and the *restore* has to happen before first paint or every
/// navigation flashes the default style before snapping to the chosen
/// one. The theme toggle already carries that split for the same
/// reason: an island for the click, a pre-paint inline script for the
/// initial value.
///
/// ## Why a panel rather than five buttons in a row
///
/// Five labelled buttons were ~370px of the header — the widest thing
/// in it, and the reason the section navigation had no room. Collapsed
/// to a trigger the same control costs one button's width, and the
/// current style is still readable without opening it because the
/// trigger shows its name.
///
/// ## Why this is not a CoUI `Popover`
///
/// Two reasons, and the first is the same one the whole control
/// already carries: `Popover` is stateful, so it would only work once
/// the client bundle loads. The second is recorded below — this
/// control is deliberately drawn in the site's own chrome rather than
/// CoUI tokens, and a CoUI panel would restyle itself with the very
/// preset the panel exists to choose.
///
/// Sized and coloured like the site's own chrome rather than through
/// CoUI tokens: the presets rewrite those tokens, and a control that
/// restyles itself as you switch is hard to aim at. It is the one
/// element on the page that has to stay recognisable across all five.
///
/// Each option carries its own value in `data-style-option`, so the
/// script reads the clicked button's attribute rather than holding a
/// second copy of the option list.
class SurfaceStyleSwitcher extends StatelessComponent {
  /// Creates the switcher.
  const SurfaceStyleSwitcher({super.key});

  /// Options worth showing — the default, plus any style whose recipe
  /// actually states something.
  ///
  /// A style with a neutral recipe would render identically to the
  /// default, and an option that visibly does nothing reads as a broken
  /// control rather than as an unfinished style.
  static List<({CoreSurfaceStyleId id, String label})> get offered => _kOptions
      .where(
        (o) =>
            o.id == CoreSurfaceStyleId.defaultId ||
            !CoreSurfaceRecipe.of(o.id).colorConstraint.isIdentity ||
            !CoreSurfaceRecipe.of(o.id).geometry.isIdentity ||
            !CoreSurfaceRecipe.of(o.id).typography.isIdentity ||
            CoreSurfaceRecipe.of(o.id).surface != null,
      )
      .toList();

  /// The label the trigger shows before the script runs.
  ///
  /// The script replaces it with the restored choice on load. Spelling
  /// the default here means the trigger is answerable in the frame
  /// before that, rather than reading as an empty control.
  static String get defaultLabel => _kOptions.firstWhere((o) => o.id == CoreSurfaceStyleId.defaultId).label;

  @override
  Component build(BuildContext context) {
    final options = offered;
    if (options.length < 2) return const Component.fragment([]);

    return Component.element(
      tag: 'div',
      attributes: const {'class': 'surface-style-switcher'},
      children: [
        Component.element(
          tag: 'button',
          attributes: const {
            'type': 'button',
            'data-style-trigger': '',
            'aria-haspopup': 'true',
            'aria-expanded': 'false',
            'aria-label': 'Surface style',
          },
          children: [
            Component.element(
              tag: 'span',
              attributes: const {'data-style-current': ''},
              children: [Component.text(defaultLabel)],
            ),
            // An inline glyph rather than `Icon`: that renders an
            // `<iconify-icon>` which needs its script to have loaded,
            // and this control has to be legible in the first frame.
            Component.element(
              tag: 'span',
              attributes: const {
                'class': 'surface-style-caret',
                'aria-hidden': 'true',
              },
              children: [Component.text('▾')],
            ),
          ],
        ),
        Component.element(
          tag: 'div',
          attributes: const {
            'class': 'surface-style-panel',
            'data-style-panel': '',
            'role': 'group',
            'aria-label': 'Surface style',
            'hidden': '',
          },
          children: [
            for (final option in options)
              Component.element(
                tag: 'button',
                attributes: {
                  'type': 'button',
                  'data-style-option': option.id.name,
                  'data-style-label': option.label,
                  // Which one is current is a pressed state, not a
                  // selection within a list: each button toggles the
                  // whole document rather than picking an item out of
                  // a set. The script keeps this in sync; the default
                  // is marked here so the control is answerable before
                  // the script runs.
                  'aria-pressed': '${option.id == CoreSurfaceStyleId.defaultId}',
                },
                children: [Component.text(option.label)],
              ),
          ],
        ),
      ],
    );
  }
}

/// 서페이스 스타일을 복원하고, 바꾸고, 지금 것을 표시하는 스크립트.
///
/// `<head>` 에 인라인으로 있어야 한다. 복원은 프리셋 규칙이 읽는 문서 속성을
/// 쓰는데, 그것을 페인트 뒤에 하면 페이지를 옮길 때마다 기본 스타일이 먼저
/// 그려졌다가 고른 스타일로 바뀐다. 밝기의 첫 값이 island 가 아니라 인라인
/// 스크립트인 것과 같은 이유다.
///
/// 유효한 이름은 여기 적지 않고 enum 에서 읽는다 — 스타일이 추가되거나
/// 이름이 바뀌었을 때 이 스크립트가 어떤 규칙도 읽지 않는 값을 받아들이거나,
/// 이제 있는 값을 거절하는 일이 없다.
String get kSurfaceStyleScript =>
    '(function(){'
    'var K="coui-surface-style",A="$kSurfaceStyleAttribute";'
    'var D="${CoreSurfaceStyleId.defaultId.name}";'
    'var V={${SurfaceStyleSwitcher.offered.map((o) => '${o.id.name}:1').join(',')}};'
    // 기본값은 자기 이름을 쓰는 대신 속성을 지운다 — 기본 규칙이 이미 그것을
    // 그리고, 이름을 남기면 "스타일 없음" 이 두 가지로 적힌다.
    'function write(v){var d=document.documentElement;'
    'if(v===D||!V[v])d.removeAttribute(A);'
    'else d.setAttribute(A,v)}'
    // 패널 열고 닫기. `hidden` 속성 하나가 상태다 — 클래스와 속성 두 벌을
    // 두면 둘이 갈린다.
    'function panel(){'
    'return document.querySelector("[data-style-panel]")}'
    'function setOpen(o){'
    'var p=panel(),'
    't=document.querySelector("[data-style-trigger]");'
    'if(!p||!t)return;'
    'if(o)p.removeAttribute("hidden");'
    'else p.setAttribute("hidden","");'
    't.setAttribute("aria-expanded",String(o))}'
    'function mark(){'
    'var v=document.documentElement.getAttribute(A)||D,'
    'b=document.querySelectorAll("[data-style-option]"),cur=null;'
    'for(var i=0;i<b.length;i++){'
    'var on=b[i].getAttribute("data-style-option")===v;'
    'b[i].setAttribute("aria-pressed",String(on));'
    'if(on)cur=b[i].getAttribute("data-style-label")}'
    // 트리거 라벨은 옵션 버튼에서 읽는다. 스크립트가 라벨 목록을 따로 들면
    // 그게 두 번째 사본이 되고, 이름을 고칠 때 한쪽만 바뀐다.
    'var l=document.querySelector("[data-style-current]");'
    'if(l&&cur)l.textContent=cur}'
    'try{var s=localStorage.getItem(K);if(s)write(s);'
    'var q=new URL(location.href).searchParams,r=q.get("style"),m=q.get("theme");'
    'if(r&&V[r]){write(r);localStorage.setItem(K,r)}'
    'if(m==="light"||m==="dark"){localStorage.setItem("$kSiteThemeStorageKey",m);'
    'document.documentElement.setAttribute("$kSiteThemeAttribute",m)}'
    '}'
    'catch(e){}'
    // 버튼은 head 시점에 아직 없다 — 생긴 뒤에 눌림 상태를 맞춘다.
    'if(document.readyState==="loading")'
    'document.addEventListener("DOMContentLoaded",mark);'
    'else mark();'
    // 위임한다 — 컨트롤은 서버가 그리고 페이지마다 다시 그려지므로, 요소마다
    // 묶으면 낡는다.
    'document.addEventListener("click",function(e){'
    'var t=e.target;if(!t||!t.closest)return;'
    'if(t.closest("[data-style-trigger]")){'
    'var p=panel();'
    'setOpen(!!(p&&p.hasAttribute("hidden")));return}'
    'var b=t.closest("[data-style-option]");'
    // 패널 밖 클릭은 닫는다. 패널 안이지만 옵션이 아닌 자리(여백)는 그대로 둔다.
    'if(!b){'
    'if(!t.closest("[data-style-panel]"))setOpen(false);'
    'return}'
    'var v=b.getAttribute("data-style-option");'
    'if(!v||!V[v])return;'
    'write(v);'
    'try{localStorage.setItem(K,v)}catch(e2){}'
    'mark();setOpen(false)'
    '});'
    'document.addEventListener("keydown",function(e){'
    'if(e.key==="Escape")setOpen(false)'
    '})'
    '})()';
