/// 문서 프리뷰의 높이 제약 — **단일 출처**.
///
/// 순수 Dart 다: jaspr 도 Flutter 도 import 하지 않는다. 이 값들이 전에는
/// `components/flutter_preview.dart` 안에 jaspr_flutter_embed 의
/// `ViewConstraints` 로 박혀 있어서, 네이티브 Flutter 쌍둥이 (`docs_app`) 가
/// 읽을 수 없었다 — 같은 컴포넌트를 다른 높이로 그리게 되는 경로였다.
///
/// jaspr 쪽은 이 값을 `ViewConstraints` 로 매핑하고, docs_app 은
/// `BoxConstraints` 로 매핑한다. 숫자는 한 곳에서만 산다.
///
/// ## 두 페인이 같은 높이를 쓰는 이유 — `maxHeight` 가 무대다
///
/// Web | Flutter 나란히 프리뷰에서 **두 페인은 모두 [DocsPreviewConstraints.maxHeight]
/// 높이의 무대**에 앉는다. Flutter view 는 앱 루트가 뷰를 채우므로 그 높이로
/// 풀리고, Web 페인은 같은 값을 고정 `height` 로 받는다. 콘텐츠가 짧은
/// 컴포넌트는 아래가 비지만, 두 페인의 높이가 같다는 것은 구조로 보장된다.
///
/// 높이를 콘텐츠에서 재지 않는 이유는 세 가지다:
///
/// * Flutter web view 는 `addView` 에 넘긴 `ViewConstraints` 로 크기가
///   정해지고 그 뒤로 자라지 않는다. host 요소의 높이를 바꿔도, window
///   `resize` 를 쏴도 따라오지 않는다.
/// * host 요소의 인라인 스타일은 jaspr vdom 소유라, 밖에서 써 넣은 높이는
///   다시 그리는 순간 지워진다.
/// * 한 페이지에 함께 뜬 view 들은 한 캔버스 높이로 paint 되고, 그 높이는
///   페이지에 **마지막으로 뜬 view** 의 것이다 — 프리뷰마다 다른 높이를 줄
///   수가 애초에 없다. Chrome 에서 잰 값: view 높이 [80, 200, 200] 은 캔버스가
///   셋 다 200, [200, 80, 80] 은 셋 다 80 이라 첫 view 가 아래 120 을 잃는다.
///   그래서 한 페이지에서 뒤에 오는 프리뷰(chain 패널 포함)가 앞의 것보다
///   낮으면 앞의 Flutter 페인이 잘린다.
///
/// 그래서 높이는 view 를 만들기 전에 정해야 하는데, 렌더된 콘텐츠를 재는 것은
/// **지금 상태만** 설명한다. accordion 항목을 열면 콘텐츠가 자라고, 접힌
/// 상태에 맞춘 view 는 넘친다(`BOTTOM OVERFLOWED BY 6.8 PIXELS` — Web 페인을
/// 재서 view 를 그 높이로 만드는 구현을 실제로 만들어 확인한 회귀다). tier 는
/// "이 프리뷰가 도달할 수 있는 가장 큰 상태"에 대한 사람의 추정이고,
/// 상호작용이 일어나기 전에 알 수 있는 유일한 값이다. 그러니 tier 를 조일 때는
/// 콘텐츠가 아니라 **가장 커지는 상태**(항목 펼침 · 드롭다운 열림 · 드래그
/// 이동)까지 확인한다 — 콘텐츠만 보고 조이면 위 회귀가 재발한다.
library;

/// 프리뷰 콘텐츠 둘레의 세로 여백 (논리 픽셀).
///
/// 두 페인이 같은 값을 쓴다 — Web 은 `.preview-content` 의 위아래 패딩으로
/// (`site_head.dart`), Flutter 는 임베드 안쪽 `Padding` 으로
/// (`docs_site/lib/widgets/preview_app.dart`).
const double kDocsPreviewContentInset = 8;

/// 프리뷰 하나의 높이 구간 (논리 픽셀). 너비는 제약하지 않는다.
///
/// 문서 사이트의 두 페인은 [maxHeight] 를 무대 높이로 쓴다 (라이브러리 문서
/// 참조). [minHeight] 는 Flutter view 에 넘기는 구간의 바닥이다 — 구간 안의
/// 어느 높이에서도 프리뷰가 넘치지 않아야 한다는 약속이라, 오버플로 테스트는
/// 두 끝을 다 잰다. 전수 스윕(`test/registry/docs_preview_overflow_test.dart`)은
/// 두 페인이 실제로 앉는 무대만 잰다 — 이름 붙은 등급의 바닥은 여러
/// 컴포넌트가 함께 쓰는 구간이라 컴포넌트 하나의 약속이 아니다. 전수
/// 스윕이 정한 대역은 바닥과 무대가 같은 한 높이라 두 끝이 겹친다.
class DocsPreviewConstraints {
  /// 프리뷰가 최소한 차지할 높이.
  final double minHeight;

  /// 프리뷰가 넘지 않아야 할 높이.
  final double maxHeight;

  /// 높이 구간을 만든다.
  const DocsPreviewConstraints({required this.minHeight, required this.maxHeight});
}

/// Default constraints — single-row components (buttons, inputs, toggles).
const kDocsDefaultConstraints = DocsPreviewConstraints(
  minHeight: 48,
  maxHeight: 80,
);

/// Components requiring medium height (multi-row, cards, forms).
const kDocsMediumConstraints = DocsPreviewConstraints(
  minHeight: 80,
  maxHeight: 200,
);

/// Components requiring taller height for proper rendering.
const kDocsTallConstraints = DocsPreviewConstraints(
  minHeight: 100,
  maxHeight: 400,
);

/// Components requiring extra tall height (multi-section layouts).
const kDocsExtraTallConstraints = DocsPreviewConstraints(
  minHeight: 150,
  maxHeight: 600,
);

/// Components requiring very tall height (full-page typography
/// previews, etc.).
const kDocsFullPageConstraints = DocsPreviewConstraints(
  minHeight: 200,
  maxHeight: 1800,
);

/// Components with compact height needs (badges, icons, dots).
const kDocsCompactConstraints = DocsPreviewConstraints(
  minHeight: 32,
  maxHeight: 56,
);

/// 컴포넌트별 제약 오버라이드.
///
/// Components not listed here use [kDefaultConstraints].
///
/// 한 높이(`minHeight == maxHeight`) 대역의 값은 전수 스윕
/// (`test/registry/docs_preview_overflow_test.dart`)이 잰 필요 높이 —
/// 콘텐츠 + 위아래 인셋 — 의 세 밀도 · 두 본문 열(632 · 728px) 최댓값에
/// 16 을 더해 16 단위로 올린 값이다. 더한 16 은 Web 페인의 글자 metric 이
/// 몇 px 다를 몫이다. 줄마다 괄호에 적은 수가 그 필요 높이다. 스윕이 지금
/// 그리는 열(668 · 828px)은 값을 잰 열보다 넓고, 스윕은 그 열에서 모든
/// 프리뷰가 여기 적힌 높이에 들어가는지를 본다.
const kDocsPreviewConstraints = <String, DocsPreviewConstraints>{
  // The playground's Flutter pane sits in a stage as tall as its control
  // column — the largest Button (xl2, 64) or a TextField with a label,
  // description and error has to fit without the view clipping it.
  'button/playground': kDocsMediumConstraints,
  'text-field/playground': kDocsMediumConstraints,
  // Playgrounds whose tallest option is taller than the component's own
  // stage: a vertical Divider between two items, an xl2 Avatar, a 48px Icon.
  'avatar/playground': kDocsMediumConstraints,
  'divider/playground': kDocsMediumConstraints,
  'icon/playground': kDocsDefaultConstraints,
  // Loading and Progress stand in the compact stage elsewhere. Their
  // playgrounds reach past it: an xl2 Loading (48, on a 64 box in the
  // inverse tone) and a Progress with its label and caption rows.
  'loading/playground': kDocsMediumConstraints,
  'progress/playground': kDocsMediumConstraints,
  'form-field': kDocsMediumConstraints,
  'formatter': kDocsDefaultConstraints,
  'scrollview': kDocsMediumConstraints,
  // A control-sized demo outgrows the default stage only under spacious
  // density — its insets move a rung up the space scale (84).
  'clickable': DocsPreviewConstraints(minHeight: 112, maxHeight: 112),
  'focus-outline': DocsPreviewConstraints(minHeight: 112, maxHeight: 112),
  'outlined-container': DocsPreviewConstraints(
    minHeight: 112,
    maxHeight: 112,
  ),
  'subfocus': kDocsTallConstraints,
  'form-label': kDocsCompactConstraints,
  'validated': kDocsMediumConstraints,
  // Text field's error variant adds an error line under the 40px field
  // — the default 80px cap overflows the Flutter embed by 2px, so the
  // base entry stays medium for it (and for the `chain` variant, which
  // gets its own medium floor from the chain-lower-bound rule below
  // regardless of this base). The bare `default` variant has no error
  // line and is a single field — 40px (the `md` control row) at standard
  // density, 48 under spacious, where the row moves a rung up the control
  // ladder. Both panes sit on this entry's `maxHeight` stage, so giving it
  // medium's room would leave ~150px of empty stage under the field;
  // `text-field/default` gives that variant the default stage instead. The
  // compact one (56) held the standard field but not the spacious one (64).
  'text-field': kDocsMediumConstraints,
  'text-field/default': kDocsDefaultConstraints,
  'validator-hint': kDocsCompactConstraints,
  'aspect-ratio-box': kDocsMediumConstraints,
  'text-block': kDocsMediumConstraints,
  // The chain adds a blockquote under the default's heading and paragraph;
  // a half-width pane wraps the three, and spacious spreads them past the
  // medium stage (204).
  'text-block/chain': DocsPreviewConstraints(minHeight: 224, maxHeight: 224),
  'definition-list': kDocsTallConstraints,
  // Overlay / modal components — need tall height.
  'dialog': kDocsTallConstraints,
  'draggable-panel': kDocsTallConstraints,
  'toast': kDocsTallConstraints,
  'drawer': kDocsTallConstraints,
  'command': kDocsTallConstraints,
  // Chain (T1) stacks *two* full Command panels (combo instance + withStyle
  // instance) — unlike menubar's chain-lower-bound rule, a single Command
  // panel already clears kDocsMediumConstraints on its own, so the generic
  // "chain floor" in docsPreviewConstraintsFor never kicks in here. Measured
  // (headless Chrome, both panels + Gap.space12): Web pane scrollHeight
  // ~675px, Flutter pane overflowed the 400px band by 262px (needs ~662px).
  // Content is static (query text doesn't reflow item count), so — unlike
  // menubar's collapsed/open split — min and max don't need to span a wide
  // behavioral range; both are sized to clear the measured content with
  // headroom for text-metric variance across browsers.
  'command/chain': DocsPreviewConstraints(minHeight: 700, maxHeight: 800),
  // The default palette — search field, two groups and the keyboard-hint
  // footer — grows a rung per row under spacious (443).
  'command/default': DocsPreviewConstraints(minHeight: 464, maxHeight: 464),
  // The palette trigger — one control-ladder row (40, 48 under spacious).
  'command-search': kDocsDefaultConstraints,
  // Eyebrow, title and description beside (or above) a row of buttons.
  'page-header': kDocsMediumConstraints,
  // One title row with a small action, space8 under it.
  'panel-header': kDocsDefaultConstraints,
  // The tallest state is the scaffold preview — a header, a scrolling body
  // and the bar. The default preview alone (a note over a 56 and a 48
  // action) already outgrows the Medium stage under the density sweep. The
  // views on one page paint at one canvas height, so the bar's own previews
  // share the tier: a shorter tier after a taller one clips the taller
  // pane.
  'bottom-action-bar': kDocsTallConstraints,
  // OptionItem — a 52px row; the variants with a description are two lines
  // and stand taller than the default stage.
  'option-item': kDocsDefaultConstraints,
  'option-item/multiple': kDocsMediumConstraints,
  'option-item/disabled': kDocsMediumConstraints,
  // OptionList — three stacked rows.
  'option-list': kDocsTallConstraints,
  // BottomSheet — a phone-width panel: handle, header, three option rows and
  // the bottom bar stack past the tall tier.
  'bottom-sheet': kDocsExtraTallConstraints,
  'popover': kDocsTallConstraints,
  'popup': kDocsMediumConstraints,
  // Two panels (combo + withStyle) over a gap (268).
  'popup/chain': DocsPreviewConstraints(minHeight: 288, maxHeight: 288),
  'tooltip': kDocsTallConstraints,

  // Multi-section / layout components.
  'stepper': kDocsTallConstraints,
  'accordion': kDocsTallConstraints,
  // Two accordions (combo + withStyle), each with its first answer open.
  // Opening another answer closes the open one, and in a half-width pane
  // no answer runs a line longer than the first, so the first state is
  // also the tallest (524 under spacious).
  'accordion/chain': DocsPreviewConstraints(minHeight: 544, maxHeight: 544),
  'collapsible': kDocsTallConstraints,
  'disclosure': kDocsTallConstraints,
  'join': kDocsMediumConstraints,
  'basic': kDocsMediumConstraints,
  // Two instances over a gap; the second one's copy wraps in a half-width
  // pane (219 under spacious).
  'basic/chain': DocsPreviewConstraints(minHeight: 240, maxHeight: 240),
  'dock': kDocsMediumConstraints,
  'footer': kDocsExtraTallConstraints,
  'frame': kDocsMediumConstraints,
  'hero': kDocsTallConstraints,
  'hidden': kDocsMediumConstraints,
  'listing': kDocsTallConstraints,
  // A row is two lines of copy over the action cells, and an opened row keeps
  // its height — the scope example stacks two of them over a divider.
  'swipe-actions': kDocsMediumConstraints,
  'tabs': kDocsTallConstraints,
  'tab-pane': kDocsMediumConstraints,
  // The chain example stacks two panes over a 12px gap, each pane's content
  // padded `space20` — the stage's insets take 16, and the spacious Flutter
  // stack measures 248 (`docs_preview_overflow_test`), so the band leaves it
  // 8 to spare. A density moves the padding and the gap a rung each way; the
  // Web example's padding class is re-pointed too. The two panes share one
  // stage, so the band clears the larger. The stack is static — nothing
  // opens or grows it — so the band is a single height: a wider one would
  // only add empty stage under the standard stack.
  'tab-pane/chain': DocsPreviewConstraints(minHeight: 272, maxHeight: 272),
  'calendar': kDocsExtraTallConstraints,
  'date-picker': kDocsExtraTallConstraints,
  // Range picker variants render two months side-by-side, so they
  // need extra height for the dialog mode (full calendar visible
  // through the modal) and breathing room for the popover too.
  'date-picker/range': kDocsFullPageConstraints,
  'date-picker/range_dialog': kDocsFullPageConstraints,
  'time-picker': kDocsExtraTallConstraints,
  'color-picker': kDocsExtraTallConstraints,
  'chat': kDocsExtraTallConstraints,
  'table': kDocsTallConstraints,
  'scrollable-client': kDocsTallConstraints,
  'stack-layout': kDocsMediumConstraints,
  'stage-container': kDocsMediumConstraints,
  // OutlinedContainer(600px) + Gap + PrimaryButton → 700px 필요.
  'window': DocsPreviewConstraints(minHeight: 150, maxHeight: 700),
  'window-panel': kDocsMediumConstraints,
  'tree': kDocsTallConstraints,
  'mask': kDocsMediumConstraints,
  'media-query': kDocsMediumConstraints,
  // The phone body at `CoreMockupDeviceStyle.defaultWidth` (320) stands
  // 9:19.5 — a 304-wide screen is 659 tall, 675 with the rail and bezel —
  // which is past the extra-tall ceiling, and phone is the default
  // variant. The tablet (299:433, 454 tall at that width), the phone's
  // landscape pose (156 tall) and the browser, code and window mockups
  // still fit under 600.
  'mockup': kDocsFullPageConstraints,
  'mockup-browser': kDocsExtraTallConstraints,
  'mockup-code': kDocsExtraTallConstraints,
  'mockup-device': kDocsFullPageConstraints,
  // Flat is a 256-wide body with a 240x480 screen (496 tall).
  'mockup-device/flat': kDocsExtraTallConstraints,
  // The flat body (496 tall) inside a card's padding.
  'mockup-device/screen-brightness': kDocsExtraTallConstraints,
  // The open body at `CoreMockupFoldableStyle.defaultWidth` (480) is the
  // tablet on its side, about 338 tall; the default and angle examples
  // add a row of controls under it.
  'mockup-foldable': kDocsExtraTallConstraints,
  'mockup/tablet': kDocsExtraTallConstraints,
  'mockup/landscape': kDocsExtraTallConstraints,
  'mockup/browser': kDocsExtraTallConstraints,
  'mockup/code': kDocsExtraTallConstraints,
  'mockup/window': kDocsExtraTallConstraints,
  'mockup/chain': kDocsExtraTallConstraints,
  'carousel': kDocsTallConstraints,
  // A strip: its own padding around a 56 (`md`: 72) thumbnail beside the
  // title and description — 80 tall at compact before the docs insets —
  // and the dots are the carousel's, not this component's. The padding
  // moves a rung with the density and the copy wraps in a half-width pane
  // (128 for the default strip under spacious, 202 for `md`).
  'carousel-banner': DocsPreviewConstraints(minHeight: 144, maxHeight: 144),
  'carousel-banner/md': DocsPreviewConstraints(minHeight: 224, maxHeight: 224),
  'resizable': kDocsTallConstraints,

  // Form components with popups — extra tall for dropdown visibility.
  'select': kDocsExtraTallConstraints,
  'autocomplete': kDocsExtraTallConstraints,
  'context-menu': kDocsExtraTallConstraints,
  'dropdown-menu': kDocsExtraTallConstraints,
  // Menubar rests short and opens tall, so its floor has to fit the
  // dropdown rather than the collapsed bar — measuring the rest state
  // would fit the bar and clip the menu (see the library doc).
  //
  // Both panes render on maxHeight, so a 100px floor is not what the
  // browser renders — this is closing a
  // hole in the declared band, not a stripe anyone has seen. But the
  // band is a promise: any height in it should render. The dropdown
  // needs ~129px, and at kDocsTallConstraints' 100px floor all three
  // menus overflow the Popup column by up to 29px. This floor clears
  // 129 with room for mobile text scaling (129 * 1.25 = 162).
  'toolbar-group': DocsPreviewConstraints(minHeight: 140, maxHeight: 200),
  'menubar': DocsPreviewConstraints(minHeight: 180, maxHeight: 400),
  'navigation-menu': kDocsExtraTallConstraints,

  // Hover — wraps a single card child; medium height.
  'hover': kDocsMediumConstraints,
  // Card — title + content + footer needs more height.
  'card': kDocsTallConstraints,
  'card-image': kDocsExtraTallConstraints,

  // Form components — medium height.
  'form': kDocsTallConstraints,
  'fieldset': kDocsTallConstraints,
  // Two fieldsets over a gap (388 under spacious).
  'fieldset/chain': DocsPreviewConstraints(minHeight: 416, maxHeight: 416),
  'radio-group': kDocsTallConstraints,
  'text-area': kDocsMediumConstraints,
  // Two text areas over a gap (262).
  'text-area/chain': DocsPreviewConstraints(minHeight: 288, maxHeight: 288),
  // RichEditor — the toolbar strip over a box that grows from 80 to 240
  // before it scrolls.
  'rich-editor': kDocsTallConstraints,

  // FAB — expanded state snapshot needs more height.
  'fab': kDocsMediumConstraints,

  // Navigation components.
  // The choice row wraps to a second line in a half-width pane once
  // spacious widens its items (124).
  'multiple-choice': DocsPreviewConstraints(minHeight: 144, maxHeight: 144),
  'navigation-bar': kDocsTallConstraints,
  // The tallest state is the drawer preview opened: inside the Flutter pane
  // the panel stacks its title row over three sidebar rows (36 each, 44
  // under spacious) and overflowed a 200 stage by 33 — the Drawer page
  // sizes its open panel with the same tier. The default (four rows) and
  // chain previews share it: the views on one page paint at one canvas
  // height, and a shorter tier after a taller one clips the taller pane.
  'navigation-bar-item': kDocsTallConstraints,
  // The sidebar scrolls when its stage is shorter than its items, so a
  // short stage hides the last destinations without overflowing — the two
  // sections, the count and the footer reach 357 under spacious.
  'navigation-bar/sidebar': DocsPreviewConstraints(
    minHeight: 360,
    maxHeight: 360,
  ),
  'scaffold': kDocsTallConstraints,
  // AppBar — the tallest variant (`medium`) is a 112px two-row bar; the
  // default 80px cap would clip its bottom-aligned title, and medium
  // (200px) fits every variant with room for the elevated cast.
  'app-bar': kDocsMediumConstraints,
  // The foldable and glass previews draw the bar inside a 384px-tall device
  // mockup (`AppBarFoldableExample`), 400px with the stage insets — the tall
  // tier holds it exactly; the bar's own 200px tier would clip the device.
  'app-bar/foldable': kDocsTallConstraints,
  'app-bar/glass': kDocsTallConstraints,
  // ThemeController — a swatch is button + label gap + one labelMedium
  // line: `md` is 40 + 6 + ~15 ≈ 61px, which the default 80px cap would
  // hold, but the `chain` preview enlarges the button to 64 (≈ 85px) and
  // the four-swatch default row wraps to a second line (≈ 130px) in a
  // half-width pane. Medium (200px) fits both without clipping.
  'theme-controller': kDocsMediumConstraints,
  // Switcher example = 6rem viewport box + Gap + a row of view buttons
  // (~168px). The default 80px cap clipped the Web pane to nothing and
  // overflowed the Flutter pane; medium (200px) fits the whole example.
  'switcher': kDocsTallConstraints,
  // IndexedSwitcher example = the same 6rem viewport box + Gap + a row of
  // destination buttons as Switcher's, so it takes the same tier.
  'indexed-switcher': kDocsTallConstraints,
  'menu': kDocsTallConstraints,
  // MenuItem — one 40px row (default / critical) fits the default tier;
  // the lg row with a description line grows past it, so that variant
  // takes medium.
  'menu-item': kDocsDefaultConstraints,
  'menu-item/description': kDocsMediumConstraints,
  'steps': kDocsTallConstraints,
  // StepItem — four 32px rows (one per status) stacked in the default
  // example fit the medium tier; the chain example is one row.
  'step-item': kDocsMediumConstraints,
  'timeline': kDocsTallConstraints,
  'breadcrumb': kDocsDefaultConstraints,
  'pagination': kDocsDefaultConstraints,
  'swap': kDocsDefaultConstraints,
  // A toggle and its label in a two-column gallery's 104.5px pane: the
  // label wraps under spacious (82).
  'toggle': DocsPreviewConstraints(minHeight: 112, maxHeight: 112),

  // File input — drop zone with icon, label, button, and hint text.
  'file-input': kDocsTallConstraints,
  // Two drop zones over a gap (480 under spacious).
  'file-input/chain': DocsPreviewConstraints(minHeight: 496, maxHeight: 496),

  // Typography preview — content has no internal scroll.
  // All text variants share the same kTallConstraints (max 400) so
  // every Flutter view in the gallery starts at the same viewport
  // height. Without this, gallery views with different per-variant
  // constraints all paint to the smallest first-frame canvas size,
  // clipping content in the larger ones (Flutter Web canvas size is
  // locked after the first paint). Variants with content smaller than
  // 400 simply leave empty space; variants with larger content
  // (typography-weight, colors-surface) overflow the way Flutter
  // normally would.
  'text': kDocsTallConstraints,
  'text/typography-display': kDocsTallConstraints,
  'text/typography-headline': kDocsTallConstraints,
  'text/typography-title': kDocsTallConstraints,
  'text/typography-body': kDocsTallConstraints,
  'text/typography-weight': kDocsTallConstraints,
  'text/typography-primitive': kDocsTallConstraints,
  'text/colors-brand': kDocsTallConstraints,
  'text/colors-status': kDocsTallConstraints,
  'text/colors-surface': kDocsTallConstraints,
  'text/modifiers': kDocsTallConstraints,
  'text/wrap': kDocsTallConstraints,
  'text/textstyle': kDocsTallConstraints,
  'text/rich': kDocsTallConstraints,

  // Form components with chips/multi-input — medium height.
  'chip-input': kDocsMediumConstraints,
  // Extra-tall so the portal-mounted country dropdown (below the field) is
  // not clipped by the Flutter preview embed's bounded canvas.
  'phone-input': kDocsExtraTallConstraints,
  'input-otp': kDocsMediumConstraints,
  'star-rating': kDocsDefaultConstraints,
  'range': kDocsDefaultConstraints,
  'item-picker': kDocsTallConstraints,
  // The chain example stacks two full pickers — title, search field and
  // five rows each — over a 12px gap, against the 384 the tall stage leaves
  // inside its insets. A density moves the stack a rung of padding, row and
  // gap each way, and the spacious stack stands 648px on the Flutter pane.
  // Static, as `tab-pane/chain` is, so one height that clears the spacious
  // stack in either pane.
  'item-picker/chain': DocsPreviewConstraints(minHeight: 672, maxHeight: 672),
  'multi-answer-card': kDocsMediumConstraints,
  'formatted-input': kDocsDefaultConstraints,
  // The verify field adds a hint line under the input (82 under spacious).
  'formatted-input/verify': DocsPreviewConstraints(
    minHeight: 112,
    maxHeight: 112,
  ),
  'number-input': kDocsMediumConstraints,
  'object-input': kDocsDefaultConstraints,
  'switch-field': kDocsMediumConstraints,
  'slider': kDocsDefaultConstraints,

  // Sortable — drag items need space.
  'drag': kDocsTallConstraints,
  'sortable': kDocsTallConstraints,

  // Display components.
  'code-snippet': kDocsTallConstraints,
  'hover-gallery': kDocsTallConstraints,
  'hover-card': kDocsTallConstraints,
  'swiper': kDocsTallConstraints,
  'refresh-trigger': kDocsTallConstraints,
  'countdown': kDocsDefaultConstraints,
  'number-ticker': kDocsDefaultConstraints,
  'overflow-marquee': kDocsDefaultConstraints,
  'responsive-container': kDocsMediumConstraints,
  'responsive-grid': kDocsTallConstraints,
  // Rows of cells whose gutters move with the density (436).
  'responsive-grid/default': DocsPreviewConstraints(
    minHeight: 464,
    maxHeight: 464,
  ),
  'responsive-row-column': kDocsTallConstraints,
  'empty-state': kDocsTallConstraints,
  'fade-scroll': kDocsTallConstraints,
  'tracker': kDocsMediumConstraints,
  'category-breakdown': kDocsTallConstraints,
  'trend-chart': kDocsTallConstraints,
  // Header, chart and legend; the legend wraps in a half-width pane and
  // spacious spreads the rows (452).
  'trend-chart/default': DocsPreviewConstraints(
    minHeight: 468,
    maxHeight: 468,
  ),
  'stat': kDocsMediumConstraints,
  // Label, value with its unit, change and description rows; spacious
  // spreads the four gaps (201).
  'stat/default': DocsPreviewConstraints(minHeight: 220, maxHeight: 220),
  'stat/outlined': DocsPreviewConstraints(minHeight: 220, maxHeight: 220),
  // The playground can show the same four rows.
  'stat/playground': DocsPreviewConstraints(minHeight: 220, maxHeight: 220),
  // Two stat cards over a gap (314 under spacious).
  'stat/chain': DocsPreviewConstraints(minHeight: 330, maxHeight: 330),
  'description-card': DocsPreviewConstraints(
    minHeight: 150,
    maxHeight: 1200,
  ),
  'chip-group': kDocsMediumConstraints,
  'code-diff': kDocsTallConstraints,
  // The before/after frame fills width at 16/9. The docs content column
  // caps at 1280px, so the frame tops out around 720px tall — give it
  // room to grow to that (both panes) instead of clipping the bottom.
  'diff': DocsPreviewConstraints(minHeight: 200, maxHeight: 800),
  'scroll-area': kDocsMediumConstraints,
  // A fixed-height scroll area plus the insets is 208 — the medium stage
  // squeezed it by 8px.
  'scroll-area/chain': DocsPreviewConstraints(minHeight: 224, maxHeight: 224),
  'scrollbar': kDocsMediumConstraints,
  'skeleton': kDocsMediumConstraints,
  'loading-region': kDocsMediumConstraints,
  'alert': kDocsTallConstraints,
  'banner': kDocsTallConstraints,
  // Two avatars at 44 and 56 fit the default stage on their own, but this
  // preview sits below the page's chain panel, and the views on one page
  // paint at the last view's canvas height — a default stage here would
  // clip the chain pane above it (the chain floor is medium).
  'avatar/diameter': kDocsMediumConstraints,

  // Compact components — less height needed.
  'badge': kDocsCompactConstraints,
  // The hue and emphasis galleries wrap a row of nine tags; under the
  // spacious density the row takes a second line, which outgrows the
  // Compact stage. The views on one page paint at one canvas height, so
  // every Tag preview shares the tier.
  'tag': kDocsMediumConstraints,
  // The disabled gallery stacks two groups (2 x 38 + a 12 gap), which
  // outgrows the single-row stage; the views on one page paint at one
  // canvas height, so every ToggleGroup preview shares the tier.
  'toggle-group': kDocsMediumConstraints,
  // The disabled gallery stacks two filters (2 x 38 + a 12 gap), which
  // outgrows the single-row stage; every Filter preview shares the tier.
  'filter': kDocsMediumConstraints,
  // A sidebar is a full-height column — the examples stand it 640 tall so
  // the body has rows to scroll past the fixed top and bottom.
  'sidebar': kDocsFullPageConstraints,
  // The playground draws it 560 tall (320 collapsed), 576 with the insets;
  // the full-page tier would leave an 1800 Flutter pane around it.
  'sidebar/playground': kDocsExtraTallConstraints,
  // The Mockup playgrounds switch frames up to a 320-wide phone, 675 tall
  // with its insets 691; the full-page tier would leave an 1800 Flutter pane.
  'mockup/playground': kDocsTallConstraints,
  'mockup-device/playground': DocsPreviewConstraints(minHeight: 704, maxHeight: 704),
  'kbd': kDocsCompactConstraints,
  'label': kDocsCompactConstraints,
  'divider': kDocsCompactConstraints,
  // Three dots plus padding and preview inset need 88px at spacious density.
  'dot-indicator/vertical': DocsPreviewConstraints(minHeight: 88, maxHeight: 88),
  'dot-indicator': kDocsCompactConstraints,
  'status': kDocsCompactConstraints,
  'validation-badge': kDocsCompactConstraints,
  'disclosure-badge': kDocsCompactConstraints,
  'loading': kDocsCompactConstraints,
  'progress': kDocsCompactConstraints,
  // The radial variant renders a 64px ring (+8px embed padding each
  // side = 80px total). Under the bar variants' compact stage (56) the
  // Flutter pane squeezes the ring down to fit while the Web pane clips
  // it instead — different sizes AND offsets. Give the radial pane
  // exactly the room it needs so neither side shrinks or clips.
  'progress/radial': kDocsDefaultConstraints,
  // Four 6px bars with three 8px gaps (48px; 60px under the spacious
  // density, where the gaps grow to 12) overflow the compact stage once the
  // embed padding is added. The labelled bar — a 13px label row, the bar and
  // a 12px caption, an 8px gap each side (≈58px) — reaches ≈66px under the
  // spacious density, past the default stage too.
  'progress/tone': kDocsDefaultConstraints,
  'progress/labelled': kDocsMediumConstraints,
  // Link / SelectableText — the compact 56px cap clipped the sample:
  // the selectable paragraph wraps to four lines in a half-width pane
  // (its lower lines were cut mid-glyph, reading as a phantom scroll)
  // and the link underline / focus ring sat flush against the cap. Both
  // panes take the whole stage, so a one-line copy leaves the rest of
  // it empty — the price of never clipping the wrapped paragraph.
  'link': kDocsDefaultConstraints,
  'selectable-text': kDocsMediumConstraints,
  'icon': kDocsCompactConstraints,
  'indicator': kDocsDefaultConstraints,
  'gap': kDocsMediumConstraints,
  'chip': kDocsCompactConstraints,
  // Two rows of chips (plain + primary) and the gap between them — the
  // gap and the chip rows move with the density (96 under spacious).
  'chip/selected': DocsPreviewConstraints(minHeight: 112, maxHeight: 112),
  // Three captioned rows (outlined / filled / outlined on a grey `Card`) —
  // 200px of content on Flutter, which is the medium tier's whole cap. The
  // Web side lays the same rows out through CSS and has no slack against it,
  // so it takes the tall tier instead of riding the cap.
  'chip/variant': kDocsTallConstraints,
  // One row of `md` pills — a pill rounds the ends but keeps the row's
  // height, so it takes the default chip's compact stage (48 with the
  // insets under every density; the row grows only sideways).
  'chip/shape': kDocsCompactConstraints,
  // Single-line `width=… tier=… coreBreakpoint=…` readout — no slots to
  // grow into, but its box's insets move with the density (82 under
  // spacious).
  'breakpoint': DocsPreviewConstraints(minHeight: 112, maxHeight: 112),
};

/// 컴포넌트(+선택 변형)의 프리뷰 제약 조회 — Web 팬·Flutter 팬 **공용
/// 단일 출처**. 두 팬이 같은 함수를 불러야 세로가 어긋나지 않는다.
///
/// 조회 순서: `component/variant` 명시 키 → (chain 변형이면 컴포넌트
/// 제약과 chain 하한 중 큰 쪽) → component → 기본값.
///
/// chain 하한: chain 예제는 T1 저작 규약상 2-인스턴스(combo 체인 +
/// withStyle full-control)라 단일-행 기본(80px)이 구조적으로 부족하다 —
/// 명시 키 없이도 최소 medium 을 보장해 프리뷰 클리핑을 막는다. 컴포넌트
/// 자체 제약이 더 크면(tall/extra-tall 류) 그쪽이 이긴다.
DocsPreviewConstraints docsPreviewConstraintsFor(
  String component,
  String? variant,
) {
  final explicit = variant != null ? kDocsPreviewConstraints['$component/$variant'] : null;
  if (explicit != null) return explicit;

  final base = kDocsPreviewConstraints[component] ?? kDocsDefaultConstraints;
  if (variant == 'chain' && base.maxHeight < kDocsMediumConstraints.maxHeight) {
    return kDocsMediumConstraints;
  }
  return base;
}
