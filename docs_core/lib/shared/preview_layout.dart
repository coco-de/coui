/// 라이브 프리뷰 레이아웃 셋 — **단일 출처**.
///
/// 순수 Dart 다: jaspr 도 Flutter 도 import 하지 않는다. 이 셋들은 전에는
/// `components/live_preview.dart` (jaspr) 안에 private 로 있어서, 네이티브
/// Flutter 쌍둥이 (`docs_app`) 가 읽을 수 없었다 — 같은 컴포넌트를 한쪽은
/// 나란히, 한쪽은 쌓아서 그리게 되는 경로였다.
///
/// 두 셋은 **서로 다른 두 결정**을 담는다. 헷갈리기 쉬우니 주의:
/// - 변형 갤러리를 한 줄에 하나씩 놓을지 → 두 셋의 **합집합**
/// - 한 프리뷰 안에서 Web|Flutter 페인을 쌓을지 → `kDocsWideComponents` **만**
///
/// **주석의 폭은 잰 때의 값이다.** 아래 등록마다 적힌 페인 폭 — 두 칸
/// 갤러리의 104.5 · 128.5px, 나란히 놓인 페인의 266.5px, 쌓인 페인의 582px
/// — 은 본문 열이 632 · 728px 일 때 잰 것이다. 문서 셸의 본문 열은 그보다
/// 넓다(데스크톱에서 가장 좁은 열 668px, 1440px 화면에서 828px): 같은 페인이
/// 113.5 · 153.5px, 284.5px, 618px 다. 등록이 그 폭에서도 맞는지는 전수
/// 스윕(`test/registry/docs_preview_overflow_test.dart`)이 그 열로 그려서 본다.
library;

/// Components that need full-width stacked (vertical) layout instead of
/// side-by-side columns, because they contain many rows or wide content.
const kDocsWideComponents = <String>{
  // PageHeader — side by side, each pane is narrower than the 240 text floor
  // plus the two buttons, so both would show only the wrapped arrangement.
  // Stacked, each platform gets the full width and shows the row.
  'page-header',
  // ColorPicker — the field trigger is at least 184 wide, and the default and
  // chain examples set the hex input beside it (288 and 308), wider than a
  // side-by-side pane at a 1024px viewport (266.5px); the inline panel is a
  // 274-wide box. Stacked, each platform gets the full cell width.
  'color-picker',
  // NumberInput — a fixed 90 / 114 / 138 control (the step buttons are part of
  // its width), wider than a side-by-side pane at a 1024px viewport (104.5px),
  // and the sizes example sets all three in one row. Stacked, each platform
  // gets the full width.
  'number-input',
  // BottomActionBar — a screen-width bar. In the variant gallery a
  // side-by-side pane is 128.5px wide at a 1440px viewport, too narrow for
  // the bar's xl actions (two of them share the horizontal row) and for the
  // scaffold preview, which is a whole screen; the overflow sweep fails
  // there. Stacked, each platform gets the full cell width.
  'bottom-action-bar',
  // OptionItem · OptionList — a row is a sheet-width line (label, description
  // and the end mark); a side-by-side pane at a 1024px viewport is 104.5px,
  // too narrow for it. Stacked, each platform gets the full cell width.
  'option-item',
  'option-list',
  // BottomSheet — a phone-width panel; a side-by-side pane is too narrow for
  // the header row and the bottom bar's xl action.
  'bottom-sheet',
  // Alert — the five-variant gallery's half-width side-by-side pane
  // squeezes the icon + title + body + dismiss row to per-character
  // wrapping (Flutter overflows vertically); stacked layout gives each
  // platform the full cell width.
  'alert',
  // Badge — the variant gallery's half-width side-by-side pane can't fit a
  // long pill label (e.g. "Destructive"): the badge is content-sized and
  // cannot shrink, so the Flutter Row overflows (debug stripes) while the
  // Web pill just stays a single content-sized line. Stacked layout gives
  // each platform the full cell width, keeping the badge a one-line pill on
  // both.
  'badge',
  // Tag — the hue and emphasis galleries hold a row of nine content-sized
  // tags, which cannot shrink; a half-width side-by-side pane is too narrow
  // for the row, so the Flutter Row overflows. Stacked layout gives each
  // platform the full cell width.
  'tag',
  // Sidebar — the two-pane shape is a 64 rail beside a 240 panel; a
  // half-width pane would clip the panel.
  'sidebar',
  // Breakpoint — the demo prints one long viewport-status line; the
  // half-width pane wraps it into a second line that overflows the
  // fixed-height Flutter embed. Full width keeps it a single line and
  // suits a viewport-width demo.
  'breakpoint',
  // Swiper — the interactive demo (position selector + open button)
  // wraps per-character in a half-width side-by-side pane; stacked
  // layout gives each platform the full cell width.
  'swiper',
  // RichEditor — the toolbar's first group alone is five 32 buttons (~170px),
  // wider than a side-by-side pane at a 1024px viewport (104.5px). Stacked,
  // each platform gets the full width and the strip stays on one line.
  'rich-editor',
  // SwipeActions — a list row is as wide as the list it sits in. In a
  // half-width side-by-side pane (104.5px at a 1024px viewport) the rows'
  // copy wraps until two of them outgrow the stage; stacked, each platform
  // gets the full cell width.
  'swipe-actions',
  // Banner is a full-width strip — a half-width side-by-side gallery
  // column squeezes the message to per-character wrapping (the KO demo
  // copy explodes the cell vertically); stacked layout gives each
  // platform the full cell width.
  'banner',
  // Card — the six-variant gallery's half-width side-by-side pane
  // wraps the title/body copy to per-word lines and pushes the
  // Flutter pane past its height cap; stacked layout gives each
  // platform the full cell width.
  'card',
  // Empty state centers a fit-content card whose description column
  // alone needs ~280px — a half-width variant-gallery pane (~170px of
  // content width) wraps the title and body to a word per line;
  // stacked layout gives each platform the full cell width.
  'empty-state',
  // Draggable panel — the demo canvas is a fixed 360px (chain variant
  // 240px) square, so a half-width side-by-side pane (~195px) cannot
  // contain it. The overflow is not merely clipped copy: the handle docks
  // to the canvas's right edge, which lands outside the pane, and the
  // neighbouring preview then stacks on top of it — the Web handle stops
  // receiving pointer events entirely (tap and drag both dead). Stacked
  // layout gives each platform the full cell width so the canvas fits.
  'draggable-panel',
  'drag',
  'calendar',
  // Date picker has both single (single-month) and range (two-month
  // side-by-side) variants — stacked layout keeps the wider range
  // calendar from being clipped in side-by-side gallery columns.
  'date-picker',
  // Time picker — popover content (segment row + AM/PM toggle + action
  // buttons) and dialog mode share the same wide surface as DatePicker;
  // stacked layout matches that and keeps the trigger at full preview
  // width for cross-platform parity.
  'time-picker',
  'code-diff',
  // Command — the keyboard-hint footer (↑/↓/↵ kbd chips + labels) needs
  // a wide row; stacked layout keeps it from wrapping in side-by-side
  // gallery columns.
  'command',
  // Formatted input — the credit-card mask (16 digits + 3 separators) is
  // wider than a half-width side-by-side gallery column; stacked layout
  // gives each platform full preview width so the segments don't clip.
  'formatted-input',
  // InputOtp — the cell row does not wrap; both platforms scale it down to
  // fit the pane instead (Flutter `FittedBox(scaleDown)`, Web's down-scale
  // measurer), so nothing overflows and the overflow sweep stays green while
  // the demo shrinks. With the `default,lg` gallery a two-column pane is
  // 104.5px of content at a 1024px viewport (128.5 at 1440): the ~400px lg
  // row would draw at ~26-32% and the ~300px md row beside it at ~35-43%,
  // so both land on ~14-18px cells — a size gallery that cannot show the
  // difference it exists for. Stacked, each platform gets the full cell
  // width (582 at 1024) and both sizes draw at real width.
  'input-otp',
  'description-card',
  'diff',
  // Pagination — a 7-button page row plus prev/next overflows a
  // half-width side-by-side gallery column; stacked layout gives each
  // platform the full preview width.
  'pagination',
  'scrollable-client',
  'stage-container',
  'table',
  'chat',
  'steps',
  'stepper',
  // Tree — file-explorer rows (chevron + folder icon + gaps + label)
  // need real width; a half-width side-by-side gallery column leaves
  // every label as a single-letter ellipsis and the Flutter row
  // furniture alone overflows the pane. Stacked layout gives each
  // platform the full preview width.
  'tree',
  // Join — the three-button group's intrinsic width (fixed button
  // padding + labels, ~125px) exceeds a half-width side-by-side
  // gallery pane (~116px): buttons cannot shrink, so both platforms
  // overflow (Flutter with debug stripes). Stacked layout gives each
  // platform the full preview width.
  'join',
  // Button — the `cast-motion` variant's three-button row (measured
  // content need ~159px) is the same shape as Join above, and it hits
  // the same wall: the side-by-side pane's usable content width dips as
  // low as ~105px at some viewport widths (swept 1024–1920px), so
  // "Reverse" clips off the right edge and "No shadow" wraps mid-word.
  // Every other button variant is a single short-label button that
  // already fits comfortably in a half-width pane, so this trades a
  // little extra whitespace on those variants' stacked panes for a
  // readable cast-motion row — narrower per-variant registration isn't
  // available (`kDocsWideComponents` keys on the component, not the
  // variant).
  'button',
  // Chip — the same `cast-motion` three-item row as Button above (label
  // 'Default'/'No shadow'/'Reverse', measured content need ~159px),
  // registered for the same reason: every other chip variant is a
  // single short-label chip that already fits a half-width pane.
  'chip',
  // Gap — the A/[gap]/B demo's intrinsic width (~97px) exceeds the
  // usable half-width pane (~84px after the shared 16px preview
  // padding) in the three-variant gallery: buttons cannot shrink, so
  // both platforms overflow (Flutter with debug stripes). Stacked
  // layout gives each platform the full preview width.
  'gap',
  'resizable',
  // Toast — the notification panel (message + description + corner
  // close button) is wider than a half-width side-by-side gallery
  // column, which wraps the copy to per-word lines; stacked layout
  // gives each platform the full preview width.
  'toast',
  'footer',
  'hero',
  'listing',
  'media-query',
  // Mockup — Phone defaultWidth is 320 and the other three hug a chrome
  // strip (address bar / traffic lights / line gutter) that will not
  // shrink. A half-width side-by-side pane (~149px) centre-slices the
  // Flutter embed (`Align(topCenter)`), so the frame/notch/toolbar fall
  // outside the clip and only the inner copy is visible. Stacked layout
  // gives each platform the full cell width. Height is already
  // `kDocsExtraTallConstraints` (max 600); this registration is the
  // width half. Do not lower `CoreMockupDeviceStyle.defaultWidth` to fit
  // the pane — that field is the design-system SSOT (#4767 / DDR-01).
  'mockup',
  // Child pages render the same frames the parent gallery does.
  'mockup-browser',
  'mockup-code',
  'mockup-device',
  // MockupFoldable — the open body is 480 wide, wider than a half pane.
  'mockup-foldable',
  'responsive-container',
  'responsive-grid',
  // ResponsiveRowColumn — three `Card` panels laid out as a `Row` at
  // the `tablet` tier and above overflow a half-width side-by-side
  // gallery column; stacked layout gives each platform the full
  // preview width so the row arrangement stays visible.
  'responsive-row-column',
  'window',
  // Frame — the icon + label row's intrinsic width exceeds a half-width
  // side-by-side pane: the Web flex wraps the label to two lines while
  // the Flutter Row overflows (debug stripes) — stacked layout gives
  // each platform the full cell width so both render one line.
  'frame',
  'fade-scroll',
  // Menubar — the same shape as NavigationMenu below: a horizontal
  // trigger bar, and it fails the same way. The two-variant gallery
  // splits the content row into columns and each column again into
  // Web | Flutter panes, so the embed lands somewhere in the 138–255px
  // band depending on viewport — under the File / Edit / View bar's
  // intrinsic width at every step of it. Flutter overflows the trigger
  // Row (debug stripes, "View" clipped); the Web bar spills its border
  // box silently (measured in-browser: scrollWidth 154 > clientWidth
  // 134), so the two platforms fail differently and only one of them
  // says so. Stacked layout gives each platform the full cell width.
  //
  // This fixes the WIDTH only. The dropdown also needs ~129px of
  // height, which stacking cannot give it — see menubar's entry in
  // preview_constraints.dart for that half.
  'menubar',
  'toolbar-group',
  // NavigationMenu — a horizontal trigger bar (4+ mega-menu triggers
  // with chevrons) overflows a half-width side-by-side gallery column;
  // stacked layout gives each platform the full preview width.
  'navigation-menu',
  // NavigationBar — the bar mode is a wide horizontal container with
  // icon + label destinations; stacked layout keeps it from clipping.
  'navigation-bar',
  // Tabs — a horizontal tab bar (pill / underline); the underline's
  // full-width bar overflows a half-width side-by-side gallery column,
  // so stacked layout gives each platform the full preview width.
  'tabs',
  // TabPane — the boxed tab row plus content panel overflows a
  // half-width side-by-side column; stacked layout gives full width.
  'tab-pane',
  // Text — the fourteen-facet typography gallery squeezes half-width
  // side-by-side panes to per-character wrapping (Flutter overflows
  // vertically and clips sample sentences); stacked layout gives each
  // platform the full cell width.
  'text',
  // Scaffold — a full screen-layout container with stacked header /
  // body / footer; stacked layout gives each platform full width.
  'scaffold',
  // AppBar — a full-width bar (leading button + title + trailing button)
  // in the same shape as NavigationBar above; a half-width side-by-side
  // gallery column squeezes the title between the two clusters, so
  // stacked layout gives each platform the full cell width.
  'app-bar',
  // Filter — the rail lays its items in one row that cannot shrink, wrap
  // or scroll, so a half-width pane overflows on the right: by 15px
  // (default) and 55px (chain) at standard density in a 1024px viewport's
  // 266.5px pane, by up to 119px under spacious. Stacked panes give each
  // platform the full cell width.
  'filter',
  // ToggleGroup — the track lays its segments in one row that cannot shrink,
  // wrap or scroll, so a half-width pane overflows on the right (the disabled
  // gallery holds three segments). Stacked panes give each platform the full
  // cell width.
  'toggle-group',
  // Disclosure — a group can have every disclosure open at once (opening
  // one does not close the others), and a half-width pane wraps each
  // answer line by line: all open, the group needs 532px of stage at
  // 266.5px but 376 stacked, which the tall stage holds (a two-column
  // gallery's 104.5px panes would need over 2000).
  'disclosure',
  // ── Overlays ──────────────────────────────────────────────────────
  //
  // These are here for a different reason than everything above, and the
  // difference is worth stating because it changes what "too narrow"
  // means. The entries above are content that *wraps* when the pane is
  // small — annoying, legible, recoverable.
  //
  // An overlay mounts over a viewport, and in a preview the pane **is**
  // that viewport. So a half-width pane does not wrap a dialog; it hands
  // the dialog a wrong-sized world. The scrim covers a quarter of the row
  // instead of a screen, the centring centres against that quarter, and
  // the panel's own max-width resolves against it — which is how a
  // confirm button ends up outside the pane it was centred in, rather
  // than on a second line.
  //
  // Registered as a family rather than one at a time. Every one of these
  // was unregistered until an overlay was actually opened in a gallery
  // and found clipped, and the next overlay added would have been too.
  'dialog',
  'popover',
  'tooltip',
  'drawer',
  // Its drawer variant opens a `Drawer` from a button — the same overlay
  // over the pane as above. Its sidebar rows (240 wide at most) fit either
  // way; the half-row pane (104.5px) is what they did not fit.
  'navigation-bar-item',
  'dropdown-menu',
  'context-menu',
  'hover-card',
  'select',
  'autocomplete',
};

/// Components whose variant-gallery items take the full content row
/// (one item per row, like the single-preview layout) while keeping the
/// Web | Flutter panes side-by-side. Use when the component itself is
/// narrow enough for a half-row pane but the gallery's two-column item
/// grid would shrink each preview to half the width the single-preview
/// page used to give it.
const kDocsFullRowGalleryComponents = <String>{
  'text-field',
  // A two-column gallery leaves each pane 104.5px of content at a 1024px
  // viewport (128.5 at 1440). These overflowed there: a key combo, a
  // definition row or a banner strip runs out of width, and a link, a menu
  // item, a donut or a trend chart wraps until it is taller than its stage
  // (a three-word link takes three lines). One item per row gives each the
  // single-preview width with the two panes still side by side (measured
  // by `test/registry/docs_preview_overflow_test.dart`).
  'carousel',
  'carousel-banner',
  'category-breakdown',
  'definition-list',
  'kbd',
  'link',
  'menu-item',
  // A stat card is a KPI tile (272px in the redesign it comes from); at half
  // a gallery row its 32px figure and unit run out of width.
  'stat',
  'step-item',
  'trend-chart',
  // A card tile's indicator, title and description, and a text area's
  // footer action, need the single-preview width: at 104.5px the three
  // tiles wrap their descriptions until they stand 684px on the 400px tall
  // stage, and the footer's button overflows the box on the right.
  'radio-group',
  'text-area',
  // The example stands in a 256px box (`CoreSpace.space256`), and three
  // variants in the two-column grid leave each pane 113.5px of content at
  // a 1280px viewport: the box clamps to ~81px and the legend, the
  // description and the fields wrap into a sliver. One item per row gives
  // it the single-preview pane (284.5px) it was drawn for.
  'fieldset',
};

/// Web previews that state the width their Flutter twin already fills, as
/// `'<component>/<variant>'` (`default` is the unnamed variant).
///
/// A Flutter preview lays its example out under loose constraints in a
/// centre: a widget is as wide as its content unless it fills what it is
/// given (`Column(crossAxisAlignment: stretch)`, a `Center`, a `Table`). The
/// Web preview stage centres its example in a flex column
/// (`align-items: center`), where *every* root is content-sized — a block
/// root that fills its parent in a real app included. So the same example is
/// 800 wide on the Flutter side and 213 / 287 / 415 on the Web side, and the
/// difference is the stage's, not the component's.
///
/// The components are left as they are: a block container that does not fix
/// its own width is what a Web consumer expects (it fills a block parent and
/// the caller states anything else), and `w-full` on the root would change a
/// flex row's siblings, a centred column and a horizontal margin in an app.
/// The stage states it instead — [docsPreviewFillsWidth] is read by the Web
/// preview registry, which both the docs site and the parity harness build
/// their Web side from, so the two cannot disagree.
///
/// Only previews whose Flutter side *fills* belong here. A content-sized one
/// (a `Button`, a stacked `DefinitionList`) must stay content-sized.
const kDocsFillWidthPreviews = <String>{
  // Alert — the example stacks its alerts in a `Column(stretch)`.
  'alert/text-only',
  // AppBar — the device preview's Scaffold fills its available width.
  'app-bar/foldable',
  'app-bar/glass',
  // CodeDiff — the box holds a `Column(stretch)` of full-width rows.
  'code-diff/default',
  // DefinitionList — the `Table` fills; the description track is the rest.
  'definition-list/columns',
  // Disclosure — a `Column(stretch)` root.
  'disclosure/default',
  'disclosure/chain',
  // EmptyState — a `Center`, which fills the width it is given.
  'empty-state/default',
  'empty-state/large',
  'empty-state/failure',
  'empty-state/success',
  // These Flutter roots centre a capped body in the full stage width.
  'mockup/phone',
  'mockup/tablet',
  'mockup/landscape',
  'mockup-device/default',
  'mockup-device/flat',
  // The foldable's Align centres its fixed body in the available width.
  // The angle example explicitly bounds its whole preview instead.
  'mockup-foldable/default',
  'mockup-foldable/half-open',
  'mockup-foldable/closed',
  'responsive-container/default',
  // MultiAnswerCard — each card fills its column.
  'multi-answer-card/default',
  // SwipeActions — the example stacks its rows in a `Column(stretch)`.
  'swipe-actions/scope',
  // Swiper — the examples explicitly make the whole stage the swipe area.
  'swiper/default',
  'swiper/sheet',
  // Timeline — a `Column(stretch)` root.
  'timeline/default',
};

/// Whether the Web preview of [component] / [variant] states the width its
/// Flutter twin fills. A `null` [variant] is the default one.
bool docsPreviewFillsWidth(String component, String? variant) =>
    kDocsFillWidthPreviews.contains('$component/${variant ?? 'default'}');
