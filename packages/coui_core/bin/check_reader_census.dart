// G3 (field emission coverage) + G4 (structural exception census) —
// "button 이 VariantStyle 20+ 필드 중 5개만 내보내는데 아무도 모른다" 를
// red 로 만드는 유일한 장치.
//
// Both gates share the AST reader (`figma_reader/`) rather than grepping —
// a line-based count of "how many MAIN Style classes are there" measured
// 132 by grep and 141 by the AST reader on the same source, and the 9-file
// gap was purely `dart format` line-wrapping (grep counts declaration
// *lines*, not declarations). A guard built on a count that formatting can
// silently change isn't a guard — it's a coin flip that happens to agree
// with baseline until someone runs `dart format`.
//
// G3 — field emission coverage: for every scalar default AND every
// dispatch-table entry the reader discovers, does `schema_v2.dart`'s
// routing actually emit it? The *denominator* deliberately includes
// dispatch-table entries (not just the ~1290 scalar `default*` fields) —
// a component's `defaultsByVariant`/`defaultsBySize` maps are where most
// of a component's actual chrome surface lives (49 dispatch tables across
// this codebase), and a gate that only counted scalars would be blind to
// exactly the "5 of 20+" failure mode this gate exists to catch.
//
// G4 — structural exception census: the fixed set of known "the reader
// can see this via AST but a name/filename-pattern tool would miss it"
// cases (enum-shaped `*_style.dart` files, off-convention dispatch names,
// private dispatch tables, multi-MAIN files, off-convention filenames).
// Recorded as an exact count, not a ceiling — growth OR shrinkage without
// updating this file's `_kG4Baseline` means the guard and reality have
// silently diverged, and either direction is worth a human looking.
//
// Usage:
//   dart run bin/check_reader_census.dart           # report only
//   dart run bin/check_reader_census.dart --ci       # exit 1 on regression
import 'dart:io';

import 'figma_reader/ast_value.dart';
import 'figma_reader/emit.dart';
import 'figma_reader/repo_reader.dart';
import 'figma_reader/schema_v2.dart';
import 'figma_reader/style_reader.dart';
import 'figma_reader/token_scale.dart';

/// G3 ratchet — the emission *deficit* (candidate fields the reader found
/// that `schema_v2.dart` failed to route) must not exceed this. Measured
/// against the real codebase at the time this gate was written; a
/// legitimate future gap (a genuinely new unroutable type showing up)
/// updates this number in the same commit that explains why, the same way
/// every other ratchet baseline in `scripts/guards/` works.
///
/// 219 → 220 (#3777): `CoreDialogStyle.panelBoxShadow`
/// (`List<CoreShadowLayer>?`) is a new candidate `schema_v2.dart` can't
/// route — same already-accepted gap as `CorePopupStyle.boxShadow` /
/// `CoreDrawerStyle.panelBoxShadow` (0 hits for either in
/// `components.json` today; shadow stacks aren't a leaf shape the reader
/// models). The sibling `shadowBaseColor` field (`CoreColor?`) *is*
/// routable and now appears in the regenerated export — only the shadow
/// stack itself needed the bump.
///
/// 220 → 221 (#3857): `CoreSliderStyle.focusOutlineStyle`
/// (`CoreFocusOutlineStyle?`) replaced the flat `focusBorderColor` /
/// `focusBorderWidth` pair when Slider moved its keyboard ring onto the
/// composed `FocusOutline`. Nested component-style slots are not a leaf
/// shape the reader routes, so two routable flat fields became one
/// unroutable nested one — the same already-accepted gap every other
/// `CoreFocusOutlineStyle?` slot carries (button / badge / clickable /
/// dot_indicator / text_field / text_area).
///
/// 221 → 222 (#3495): `CoreScrollableClientStyle.focusOutlineStyle`
/// (`CoreFocusOutlineStyle?`) is that same nested-slot shape again — the
/// viewport became keyboard-focusable and so had to draw the shared ring,
/// which every focusable component reaches through this one slot. Nothing
/// newly unroutable appears here: it is one more instance of the gap the
/// `#3857` entry above already accepted, and unlike that one it *adds* a
/// slot rather than replacing two flat fields, so the deficit rises by one
/// instead of staying level.
///
/// 222 → 223 (#3863): `CoreRangeStyle.focusOutlineStyle` — the same move
/// for `Range`, which composes a `FocusOutline` per thumb. Same shape,
/// same reason as the `#3857` bump above.
/// 223 → 222 (#3992): `CoreTimePickerStyle.segmentFocusOutlineStyle`
/// replaced the flat `focusRingColor` / `focusRingWidth` /
/// `focusRingOffset` trio. This is the same nested-slot move as the three
/// entries above but the count goes *down*, which is worth saying out
/// loud: TimePicker's trio was one routable field (`focusRingColor`, a
/// `CoreColor` that did emit) plus two that were already pure deficit
/// (`CoreFocusRing.ringWidth` / `.ringOffset` do not resolve through the
/// token scale, so neither `double` ever reached `components.json`).
/// Three candidates carrying two deficit became one candidate carrying
/// one, so `focusRingColor` left the export and the gap shrank by one.
/// 222 → 223: `CoreCardImageStyle.frameStyle` — the flat
/// `backgroundColor` / `borderColor` / `borderRadius` trio (deprecated,
/// kept working) folded into a single nested `CoreOutlinedContainerStyle`
/// slot so the image frame composes the real `OutlinedContainer`
/// primitive instead of hand-rolling its chrome. Same nested-slot-move
/// shape as the entries above, but the deprecated trio still routes
/// (kept for back-compat), so the count only rises by the new
/// composite-typed `frameStyle` candidate itself, not by three.
///
/// 223 → 225: Chip gained its spec-confirmed `xl2` tier
/// (CoUI_Size_Token_Specification §3-4). The new entry has the same
/// arg shape as the five existing tiers, two of whose args were
/// already pure deficit per entry (`labelStyle`, a raw
/// `CoreTextStyle(fontSize:)` constructor, and the nested
/// `closeButtonStyle` `CoreButtonStyle(...)` call — neither routes
/// through the token scale), so a sixth entry adds exactly two.
///
/// 225 → 226 (#4200): `CoreDividerStyle.defaultChildAlignment`
/// (`CoreDividerChildAlignment`) lets a labelled divider put its child
/// at the reading start / centre / end. An enum default is not a leaf
/// shape the reader routes — it names a position, not a token value —
/// so it lands in `axes.other` (where the regenerated `components.json`
/// now lists the enum and its three members) rather than in `fields`.
/// This is the same already-accepted gap every other enum-typed default
/// carries: `CoreStacksStyle`'s `defaultAlignment` / `defaultFit` /
/// `defaultClipBehavior` are why that component's `fields` map is empty
/// today. One new default of that shape, so the deficit rises by exactly
/// one.
///
/// 226 → 227: `CoreNavigationBarStyle.defaultsByIndicator` adds the
/// `CoreNavigationBarIndicatorStyle` holder, a table the reader walks and
/// emits (the canvas builder reads its cells) but whose `stateLayer` cell — a
/// `CoreStateLayer` ramp, the same composite every other component's
/// `defaultStateLayer` already leaves unrouted — is not a leaf shape. One new
/// candidate of that shape, so the deficit rises by exactly one.
/// 227 → 146: the census now gives `readContracts` the actual `lib/src`
/// reference root, matching the exporter. The prior relative default pointed
/// under `packages/coui_core/packages/coui_core`, leaving the registry without
/// Core primitives and falsely counting 82 resolvable values as deficits.
///
/// 146 → 150: the Sidebar family. Seven components add `Core*Style` tables
/// the reader walks and emits; four candidates keep the same unrouted shapes
/// every other component already leaves out — composite defaults that are not
/// leaf shapes. Each is the same kind as the existing deficits, so the
/// ceiling rises by exactly the new count.
///
/// 150 → 152: `NumberInput` (#5771). `CoreNumberInputStyle` adds five
/// candidates — `defaultFieldStyle`, `defaultButtonStyle` and the three
/// `defaultsBySize` widths — and the reader emits three. The two it leaves
/// out are composite or derived values of the shapes the earlier entries
/// already accept; the exporter still ships `fieldStyle`, `buttonStyle` and
/// every width, so the canvas misses nothing. Measured on both sides of the
/// merge: 150 at its first parent, 152 at the merge.
///
/// 152 → 154: the input-family redesign. `FormattedInput` and `ObjectInput`
/// add the composed field's `variant` and `size` enum defaults
/// (`defaultSegmentInputVariant` / `defaultSegmentInputSize` and the
/// ObjectInput twins) — enums are the unroutable shape the earlier entries
/// already accept; the exporter still ships every field that has a leaf shape.
///
/// 154 → 159: `RichEditor`. `CoreRichEditorStyle` composes other components
/// and holds their styles as nested defaults (`defaultTextAreaStyle`,
/// `defaultToolbarButtonStyle`, `defaultActiveToolbarButtonStyle`,
/// `defaultTooltipStyle`, `defaultKbdStyle`) — composite defaults, the shape
/// the NumberInput entry already accepts. Its leaf defaults (colours,
/// spacings, the code text role) all emit.
///
/// 159 → 160: `OptionItem`. `CoreOptionItemStyle` adds composite defaults
/// (a state-layer ramp, the nested `Clickable` slot) of the same shape
/// `CoreMenuItemStyle` already leaves unrouted; the leaf-shaped ones (gaps,
/// sizes, radii, colours) are emitted. One new candidate of that shape, so
/// the ceiling rises by exactly one.
///
/// 160 → 161: `BottomSheet`. `CoreBottomSheetStyle.defaultCloseButtonStyle` is
/// a `CoreButtonStyle` composite — the shape `CoreSortableStyle`'s remove
/// button already leaves unrouted; the exporter still ships the field, and
/// every leaf-shaped default (colours, spacings, radii, sizes, text roles,
/// the gap) is emitted. One new candidate of that shape, so the ceiling rises
/// by exactly one.
///
/// 161 → 162: `Resizable`. `CoreResizableStyle` adds three defaults — the
/// dragging thickness, the dragging colour and the nested
/// `defaultFocusOutlineStyle` — and the nested focus-outline composite is the
/// presumed unrouted one (the shape `CoreSliderStyle.defaultFocusOutlineStyle`
/// already is); the exporter still ships `focusOutlineStyle` and both leaf
/// fields. The candidate was not isolated by name. One new candidate of that
/// shape, so the ceiling rises by exactly one.
///
/// 162 → 163: `StarRating`. `CoreStarRatingStyle` adds the group's focus ring
/// as a nested `defaultFocusOutlineStyle` — the same composite shape
/// `CoreSliderStyle.defaultFocusOutlineStyle` already is — and the exporter
/// still ships `focusOutlineStyle` (every ring field), the per-size
/// `defaultsBySize` rows (star size, spacing, value and count text roles) and
/// every colour. The candidate was not isolated by name; one new candidate of
/// that shape, so the ceiling rises by exactly one.
///
/// 163 → 164: `MultipleChoice`. `CoreMultipleChoiceStyle` adds the composed
/// chip's nested `defaultChipStyle` — a `CoreChipStyle` composite, the shape
/// `CoreBottomSheetStyle.defaultCloseButtonStyle` already is. The exporter
/// still ships the field (`chipStyle`) with the chip's own rows and every
/// leaf it carries; the unrouted candidate is the composite default itself.
/// One new candidate of that shape, so the ceiling rises by exactly one.
///
/// 164 → 165: `ToggleGroup`. `CoreToggleGroupStyle.defaultClickableStyle` is
/// the composed per-segment `Clickable`'s nested slot (`disabledOpacity: 1`) —
/// a `CoreClickableStyle` composite, the shape `CoreOptionItemStyle` and
/// `CoreFilterStyle` already leave unrouted. Isolated by name (removing it
/// returns the deficit to 164); every leaf-shaped default (colours, radii,
/// insets, the shadow, text roles, icon styles) is emitted. One new candidate
/// of that shape, so the ceiling rises by exactly one.
///
/// 165 → 166: `ColorPicker`. `CoreColorPickerStyle.defaultModeTabsStyle` is the
/// composed mode-tabs `ToggleGroup`'s nested slot — an empty
/// `CoreToggleGroupStyle` composite, the shape `CoreFilterStyle` and
/// `CoreToggleGroupStyle.defaultClickableStyle` already leave unrouted.
/// Isolated by name (removing it returns the deficit to 165); every
/// leaf-shaped default added with it (radii, handle size / ring, dash length /
/// gap, the caption text role) is emitted. One new candidate of that shape, so
/// the ceiling rises by exactly one.
///
/// 166 → 168: `Filter`. `CoreFilterStyle` adds two nested composite defaults —
/// `defaultToggleGroupStyle` (the composed segments' `CoreToggleGroupStyle`,
/// an empty partial) and `defaultDividerStyle` (a `CoreDividerStyle`) — the
/// shape `CoreMultipleChoiceStyle.defaultChipStyle` already is. The exporter
/// still ships both fields (`toggleGroupStyle`, `dividerStyle`) with the
/// nested style's own rows and every leaf it carries (the hairline's colour
/// and thickness are emitted as the divider's rows); the unrouted candidates
/// are the composite defaults themselves (not isolated by name). Two new
/// candidates of that shape, so the ceiling rises by exactly two.
///
/// 168 → 169: `TimePicker`. `CoreTimePickerStyle.defaultTriggerStyle` is the
/// read-only trigger field's nested slot (the pressed-only `stateLayer`) — a
/// `CoreTextFieldStyle` composite, the shape `CoreSelectStyle`'s
/// `defaultTriggerStyle` already leaves unrouted. The exporter still ships the
/// field (`triggerStyle`, with the field's own ramp and the `stateLayer`);
/// the unrouted candidate is the composite default itself. One
/// new candidate of that shape, so the ceiling rises by exactly one.
///
/// 169 → 170: `DatePicker`. `CoreDatePickerStyle.defaultTriggerStyle` becomes
/// the read-only trigger field's nested slot (the pressed-only `stateLayer`) —
/// the same `CoreTextFieldStyle` composite `CoreTimePickerStyle` and
/// `CoreSelectStyle` already leave unrouted. The exporter still ships the
/// field (`triggerStyle`, with the field's own ramp and the `stateLayer`); the
/// unrouted candidate is the composite default itself. One new candidate of
/// that shape, so the ceiling rises by exactly one.
///
/// 170 → 171: `RichEditor` images. `CoreRichEditorStyle` adds
/// `defaultUploadAlertStyle`, the nested slot of the `Alert` that reports an
/// upload under way or failed (and stands in for an image that cannot be
/// shown) — an empty `CoreAlertStyle` composite, the shape
/// `defaultTextAreaStyle` already is. The candidate was not isolated by name;
/// the exporter still ships the field (`uploadAlertStyle`), and every
/// leaf-shaped default added with it (the three heading text roles, the image
/// corner, height and fill) is emitted. One new candidate of that shape, so
/// the ceiling rises by exactly one.
///
/// 171 → 172: `RichEditor` toolbar rules. `CoreRichEditorStyle` adds
/// `defaultToolbarDividerStyle`, the nested slot of the `Divider` that draws
/// the line under the toolbar and the lines between its groups — an empty
/// `CoreDividerStyle` composite, the shape
/// `CoreFilterStyle.defaultDividerStyle` already is. Isolated by name:
/// listing the defaults of `CoreRichEditorStyle` shows it as the only new
/// unrouted one. The exporter still ships the field (`toolbarDividerStyle`)
/// with the divider's own rows, and every leaf-shaped default added with it
/// (the strip's fill and inset, the length of the line between groups, the
/// row spacing) is emitted. One new candidate of that shape, so the ceiling
/// rises by exactly one. The gate was already red by one before this change
/// (`main` measured 172 against 171 — a candidate an earlier change added
/// without raising the ceiling); this entry accounts for ours only.
///
/// 172 → 173 (#6016): `Filter` sizes. `CoreFilterStyle.defaultsBySize` adds
/// the `sm` row, whose `resetButtonStyle` is the nested `CoreButtonStyle`
/// slot of the reset button (26 tall at `sm`) — the shape
/// `defaultResetButtonStyle` already is, routed by the exporter as the
/// button's own rows. Isolated by count: the row's other argument
/// (`dividerHeight`) and the six arguments of the new `sm` row of
/// `CoreToggleGroupStyle.defaultsBySize` (corner, insets, segment height,
/// label roles) are all emitted. One new candidate of that shape, so the
/// ceiling rises by exactly one. The gate was already red by two before this
/// change (`main` measured 174 against 172 at f397cca06 — candidates earlier
/// changes added without raising the ceiling); this entry accounts for ours
/// only.
///
/// 173 → 175 (#6038): the two candidates the earlier entries record as
/// "already red" without naming. Isolated by measuring each merge against
/// its parent: `CoreBottomSheetStyle.defaultFooterBarStyle` (#5955, the
/// nested `CoreBottomActionBarStyle` of the footer bar) and
/// `CoreNavigationBarStyle.defaultDisabledSelectionMarkStyle` (#6003, the
/// nested `CoreBadgeStyle` of a disabled selected destination's mark). Both
/// are nested component Style slots with no field kind — the same shape as
/// the existing `default…ButtonStyle` / `default…ClickableStyle` deficits —
/// so nothing regressed in emit; the ceiling catches up by exactly two.
///
/// 175 → 182: seven nested component Style slots, each added by a change that
/// did not raise the ceiling (`main` was already at 177 against 175 when #6052
/// merged, and has been red here since). Isolated by measuring every merge
/// against its parent, with this file's `MISS` output applied to both sides:
///
/// - #6061 `NavigationMenu` (+2): `CoreNavigationMenuStyle`
///   `defaultContentTriggerButtonStyle` and `defaultOpenTriggerButtonStyle`,
///   the nested `CoreButtonStyle` of a trigger that has content and of the
///   open trigger.
/// - #6076 (+1): `CoreTimePickerStyle.defaultAmPmToggleStyle`, the nested
///   `CoreToggleGroupStyle` of the AM/PM control.
/// - #6079 `HoverCard` (+1): `CoreHoverCardStyle.defaultPanelStyle`, the
///   nested `CorePopupStyle` of the panel it now composes.
/// - #6105 `RichEditor` (+2): `defaultBlockTypeButtonStyle` and
///   `defaultBlockTypeMenuStyle`, the nested `CoreButtonStyle` and
///   `CoreDropdownMenuStyle` of the block-type dropdown.
/// - #6110 `RichEditor` (+1): `defaultSelectionToolbarPanelStyle`, the nested
///   `CorePopupStyle` of the panel that floats over a selection.
/// - #6246 `Banner` · `Toast` (+2): `defaultPlainActionButtonStyle` on each,
///   the nested `CoreButtonStyle` a `plain` action takes over the action
///   chrome — beside `defaultActionButtonStyle`, which was already a `MISS`.
/// - #6466 `CardImage` (+3): `defaultContainerStyle` and
///   `defaultDisabledContainerStyle` (the nested `CoreOutlinedContainerStyle`
///   of the card's own box, at rest and disabled) and `defaultContentStyle`
///   (the nested `CoreBasicStyle` of the text row) — beside
///   `defaultFrameStyle`, which was already a `MISS`.
///
/// All of them are nested component Style slots with no field kind — the same
/// shape as the existing `default…ButtonStyle` / `default…PanelStyle` deficits
/// — so nothing regressed in emit. Every leaf-shaped default added alongside
/// them is emitted. The ceiling catches up by exactly twelve; the next
/// change that adds a thirteenth fails here by name in the `MISS` list above
/// the count.
///
/// 187 → 189: `MockupFoldable` (+2). `CoreMockupFoldableStyle`
/// `defaultInnerDeviceStyle` and `defaultCoverDeviceStyle`, the nested
/// `CoreMockupDeviceStyle` of the two faces the component composes — the
/// open body and the cover. Isolated by name: they are the only two entries
/// of that style in the `MISS` list. Both are nested component Style slots
/// with no field kind, the shape every `default…Style` deficit above is, and
/// the exporter still ships both fields with the device's own rows. Every
/// leaf-shaped default added with them — the lengths, the colours, the
/// shade's strength, the status island's text style, the move's duration and
/// curve — is emitted, so the ceiling rises by exactly two.
///
/// This entry accounts for ours only. `main` measured 189 against 187 at
/// 449912dd65 — two candidates other changes added without raising the
/// ceiling: `CoreColorPickerStyle.defaultInlinePanelStyle` (#6508, the
/// nested `CorePopupStyle` of the inline panel) and
/// `CoreInputOtpStyle.defaultErrorValidatorHintStyle` (#6495, the nested
/// `CoreValidatorHintStyle` of the error line).
///
/// 189 → 191: those two. Both are nested component Style slots with no field
/// kind, the same shape as every entry above, and neither change dropped an
/// emitted leaf:
///
/// - (6495) `InputOtp` (+1):
///   `CoreInputOtpStyle.defaultErrorValidatorHintStyle`, the nested
///   `CoreValidatorHintStyle` of the composed error line.
/// - (6508) `ColorPicker` (+1): `CoreColorPickerStyle.defaultInlinePanelStyle`,
///   the nested `CorePopupStyle` of the inline panel the picker can now show.
///
/// 191 → 192: one more nested component Style slot with no field kind, the
/// same shape as every entry above — and no emitted leaf dropped:
///
/// - (6558) `Menubar` (+1):
///   `CoreMenubarStyle.defaultOpenTriggerButtonStyle`, the nested
///   `CoreButtonStyle` of the trigger whose menu is open (the twin of
///   `CoreNavigationMenuStyle.defaultOpenTriggerButtonStyle`).
///
/// 192 → 193: one more nested component Style slot with no field kind, the
/// same shape as every entry above — and no emitted leaf dropped:
///
/// - (6622) `Scaffold` (+1):
///   `CoreScaffoldStyle.defaultAppBarRailPopupStyle`, the nested
///   `CorePopupStyle` of the action capsules in the adaptive app-bar rail.
///
/// 193 → 195: two more nested component Style slots with no field kind, the
/// same shape as every entry above — and no emitted leaf dropped:
///
/// - `Diff` (+2): `CoreDiffStyle.defaultLabelBadgeStyle`, the nested
///   `CoreBadgeStyle` of the two label chips, and
///   `CoreDiffStyle.defaultFocusOutlineStyle`, the nested
///   `CoreFocusOutlineStyle` of the handle's ring. Both still reach the
///   canvas through the exporter's nested-slot spread; only the reader's
///   own default-constant census cannot give them a kind.
const _kG3MaxDeficit = 195;

/// G4 — exact structural exception counts. Not a ceiling: both a rise
/// (new exception appeared uncounted) and a fall (an exception was fixed
/// but this baseline wasn't updated to shrink it) fail the gate, so this
/// number can never quietly drift from what `dart run
/// bin/check_reader_census.dart` actually reports.
///
/// 1 → 2 (off-convention dispatch names): `CoreNavigationBarStyle`'s new
/// `defaultsByMode` map is a per-mode default axis — the bar/rail/sidebar
/// item-spacing default differs by mode, not by variant/size/type/tone/
/// status/state/color, so its name doesn't match any of
/// `kConventionalDispatchNames`. The reader still discovers and classifies
/// it correctly by type (this file's whole point); this bump is purely so
/// the census stays exact.
///
/// 8 → 7 (off-convention filenames): `mockup/mockup_window_style.dart` was
/// a second MAIN Style living in the `mockup/` directory, so its filename
/// could not match `mockup_style.dart` and it counted here. The class it
/// held was retired — a window with no address bar is
/// `MockupBrowser(addressBar: null)`, not its own component — so the file
/// is gone and the exception with it. A fall, which this gate fails on for
/// the same reason it fails on a rise.
///
/// 2 → 3 (off-convention dispatch names): `CoreRadioGroupStyle`'s
/// `cardDefaultsBySize` is the `card` variant's size table — a
/// variant × size dispatch, which style-contract.md states as a nested
/// `Map<variant, Map<size, …>>`. It is flat because the Figma reader
/// buckets any `…BySize` map as a size table and cannot walk a nested one,
/// so the debt is the reader's and this count falls back when the reader
/// walks nested dispatch. It is not registered in
/// `kConventionalDispatchNames`: `card` is a value of the variant axis, not
/// an axis of its own.
///
/// 3 → 4 (off-convention dispatch names): `CoreNavigationBarStyle`'s
/// `defaultsByIndicator` is the per-indicator default axis — how the selected
/// destination is marked (a tile or colour alone) differs by
/// `CoreNavigationSelectionIndicator`, not by any of the conventional axes.
/// The reader discovers and emits it by type like `defaultsByMode`.
///
/// 4 → 5 (off-convention dispatch names): `CoreSidebarItemStyle`'s
/// `defaultsByLevel` is the per-level default axis — a row's height and type
/// role differ by `CoreSidebarItemLevel` (top / nested), not by any
/// conventional axis. The reader discovers and emits it by type like
/// `defaultsByMode`. (`CoreSidebarStyle.defaultsByType` uses a conventional
/// name and does not count.)
const _kG4Baseline = {
  'enum-shaped *_style.dart files': 4,
  'off-convention dispatch names': 5,
  'typedef-record dispatch': 0,
  'private dispatch tables': 2,
  'multi-MAIN files': 2,
  'off-convention filenames': 7,
};

/// Read the same component and reference roots as the exporter when run
/// from the coui_core package directory (the CI and test working directory).
RepoReadResult readCensusRepo() => readContracts(
  repoRoot: '.',
  contractsRoot: 'lib/src/component/contracts',
  referenceRoot: 'lib/src',
);

void main(List<String> args) {
  final ci = args.contains('--ci');

  final repo = readCensusRepo();
  final tokens = resolveNamespaces(repoRoot: '.', srcRoot: 'lib/src');
  final ctx = EmitContext(
    tokenScale: tokens,
    classRegistry: repo.resolutionRegistry,
  );

  final g3 = _computeG3(ctx, repo.classesByName);
  final g4 = _computeG4(repo.classesByName);

  var failed = false;

  stdout
    ..writeln('=== G3 — field emission coverage ===')
    ..writeln(
      '  candidates: ${g3.candidates}  emitted: ${g3.emitted}  '
      'deficit: ${g3.deficit}  (max $_kG3MaxDeficit)',
    );
  if (g3.deficit > _kG3MaxDeficit) {
    failed = true;
    stdout.writeln(
      '  ❌ deficit ${g3.deficit} exceeds baseline $_kG3MaxDeficit — a '
      'field the reader can see is no longer being emitted. If this is a '
      'genuine new unroutable type, raise _kG3MaxDeficit in this file and '
      'say why in the commit; if not, something regressed in emit.dart / '
      'schema_v2.dart.',
    );
  } else if (g3.deficit < _kG3MaxDeficit) {
    stdout.writeln(
      '  ✅ below baseline — lower _kG3MaxDeficit to ${g3.deficit} to '
      'hold the gain.',
    );
  } else {
    stdout.writeln('  ✅ at baseline.');
  }

  stdout.writeln('=== G4 — structural exception census ===');
  for (final key in _kG4Baseline.keys) {
    final actual = g4[key] ?? 0;
    final expected = _kG4Baseline[key]!;
    final match = actual == expected;
    if (!match) failed = true;
    stdout.writeln(
      '  ${match ? '✅' : '❌'} $key: $actual (expected $expected)',
    );
  }
  final unexpectedKeys = g4.keys.toSet().difference(_kG4Baseline.keys.toSet());
  if (unexpectedKeys.isNotEmpty) {
    failed = true;
    stdout.writeln('  ❌ unbaselined categories reported: $unexpectedKeys');
  }

  if (failed) {
    stdout.writeln('\n❌ reader-census gate failed.');
    if (ci) exit(1);
  } else {
    stdout.writeln('\n✔ reader-census gate passed.');
  }
}

final class _G3Result {
  const _G3Result(this.candidates, this.emitted);
  final int candidates;
  final int emitted;
  int get deficit => candidates - emitted;
}

_G3Result _computeG3(
  EmitContext ctx,
  Map<String, DiscoveredClass> classesByName,
) {
  var candidates = 0;
  var emitted = 0;

  for (final cls in classesByName.values) {
    if (!cls.implementsCoreStyle) continue;
    final fieldTypeByJsonKey = <String, String>{
      for (final f in cls.instanceFields) jsonKeyFor(f.name): f.typeSource,
    };

    for (final member in cls.staticMembers) {
      if (member.isPrivate) continue;
      final isDispatch = member.typeSource.startsWith('Map<');

      if (isDispatch) {
        final mapValue = member.value;
        if (mapValue is! MapValue) continue;
        for (final entry in mapValue.entries) {
          final call = entry.value;
          if (call is! CallValue) continue;
          candidates += call.namedArgs.length;
          final valueClassName = call.owner ?? call.callee;
          final valueClass = classesByName[valueClassName];
          final valueFieldTypeByJsonKey = <String, String>{
            if (valueClass != null)
              for (final f in valueClass.instanceFields)
                jsonKeyFor(f.name): f.typeSource,
          };
          for (final arg in call.namedArgs.entries) {
            final jsonKey = jsonKeyFor(arg.key);
            final typeSource = valueFieldTypeByJsonKey[jsonKey];
            final kind = typeSource == null ? null : fieldKindOf(typeSource);
            if (kind == null) continue;
            final leaf = emitByKind(
              ctx,
              kind,
              arg.value,
              currentClass: cls.name,
            );
            if (leaf != null) {
              emitted++;
            } else {
              stderr.writeln(
                'MISS ${cls.name}.${member.name}[${entry.key}].${arg.key}',
              );
            }
          }
          for (final arg in call.namedArgs.entries) {
            final t = valueFieldTypeByJsonKey[jsonKeyFor(arg.key)];
            if (t == null || fieldKindOf(t) == null) {
              stderr.writeln(
                'MISS ${cls.name}.${member.name}[${entry.key}].${arg.key} '
                '(no kind)',
              );
            }
          }
        }
        continue;
      }

      final jsonKey = jsonKeyFor(member.name);
      final typeSource = fieldTypeByJsonKey[jsonKey];
      if (typeSource == null) continue; // Not an overridable slot.
      candidates++;
      final kind = fieldKindOf(typeSource);
      if (kind == null) {
        stderr.writeln('MISS ${cls.name}.${member.name} (no kind)');
        continue;
      }
      final leaf = emitByKind(
        ctx,
        kind,
        member.value,
        currentClass: cls.name,
      );
      if (leaf != null) {
        emitted++;
      } else {
        stderr.writeln('MISS ${cls.name}.${member.name}');
      }
    }
  }

  return _G3Result(candidates, emitted);
}

Map<String, int> _computeG4(Map<String, DiscoveredClass> classesByName) {
  final counts = <String, int>{};

  // enum-shaped *_style.dart files — files matching the *_style.dart glob
  // that declare no class at all (readCompilationUnit finds classes only;
  // an enum-only file yields an empty list for every class in that file,
  // which we detect by file path, not by class).
  final styleFilesWithNoClass = <String>{};
  final classFilePaths = classesByName.values.map((c) => c.filePath).toSet();
  final root = Directory('lib/src/component/contracts');
  for (final f in root.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('_style.dart')) continue;
    if (!classFilePaths.contains(f.path)) styleFilesWithNoClass.add(f.path);
  }
  counts['enum-shaped *_style.dart files'] = styleFilesWithNoClass.length;

  // The blessed set of semantic axis names a `defaultsBy*` dispatch may
  // key on. A name outside this set is counted as off-convention, so a
  // new axis is registered here rather than absorbed into the baseline
  // count — the baseline is for debt, and a legitimate axis is not debt.
  // `defaultsByKind` was added for `DisclosureBadge`, whose public API
  // is `kind:` (`CoreDisclosureKind`); naming the dispatch after any
  // other axis would split the name from the parameter it dispatches on.
  const kConventionalDispatchNames = {
    'defaultsByVariant',
    'defaultsBySize',
    'defaultsByType',
    'defaultsByTone',
    'defaultsByStatus',
    'defaultsByState',
    'defaultsByColor',
    'defaultsByKind',
    // `defaultsBySelection` dispatches `OptionItem` on `selection:`
    // (`CoreOptionItemSelection`) — how a chosen row says it is chosen, a
    // shape axis, not debt.
    'defaultsBySelection',
    // `defaultsByPresentation` dispatches `Command` on `presentation:`
    // (`CoreCommandPresentation`) — a shape axis, not debt.
    'defaultsByPresentation',
    // `defaultsByDevice` dispatches `MockupDevice` on `device:`
    // (`CoreMockupDevice`) — the device kind a mockup draws, not debt.
    'defaultsByDevice',
    // `defaultsByFinish` dispatches `MockupDevice` on `finish:`
    // (`CoreMockupDeviceFinish`) — a picture of hardware or a plain frame,
    // a shape axis next to `device`, not debt.
    'defaultsByFinish',
    // `defaultsByLayout` dispatches `DefinitionList` on `layout:`
    // (`CoreDefinitionLayout`) — a shape axis, not debt.
    'defaultsByLayout',
    // `defaultsByForm` dispatches `Badge` on `form:` (`CoreBadgeForm`) —
    // what a badge holds (a word, a number, nothing), not debt.
    'defaultsByForm',
    // `defaultsByShape` dispatches `Avatar` on `shape:` (`CoreAvatarShape`)
    // — a disc or a rounded tile, not debt.
    'defaultsByShape',
    // `defaultsByEmphasis` dispatches `Tag` on `emphasis:`
    // (`CoreTagEmphasis`) — how loud a tag is (subtle / bold), not debt.
    'defaultsByEmphasis',
  };
  var offConventionDispatch = 0;
  var typedefRecordDispatch = 0;
  var privateDispatch = 0;
  final mainFilesSeen = <String, int>{};
  var offConventionFilenames = 0;

  for (final cls in classesByName.values) {
    for (final member in cls.staticMembers) {
      final isDispatch = member.typeSource.startsWith('Map<');
      if (!isDispatch) continue;
      if (member.isPrivate) {
        privateDispatch++;
        continue;
      }
      if (!kConventionalDispatchNames.contains(member.name)) {
        offConventionDispatch++;
      }
      // A dispatch whose *declared value type* is a record literal
      // (`Map<K, ({...})>`) rather than a named class is the
      // typedef-record shape style-contract.md bans — #3752 promoted the
      // last two instances (validation_badge) to classes, so this should
      // read 0. This checks the Map's declared type parameter, not each
      // entry's value shape — a legitimate scalar dispatch
      // (`Map<Size, double>`) or a same-class shared-constant reference
      // (`CoreTextFieldVariant.error: defaultErrorVariant`) both have
      // non-`CallValue` entries without being typedef records at all.
      if (member.typeSource.contains('({')) typedefRecordDispatch++;
    }

    if (!cls.implementsCoreStyle) continue;
    mainFilesSeen[cls.filePath] = (mainFilesSeen[cls.filePath] ?? 0) + 1;

    final parts = cls.filePath.split('/');
    final dirName = parts[parts.length - 2];
    final fileName = parts.last;
    if (fileName != '${dirName}_style.dart') offConventionFilenames++;
  }

  counts['off-convention dispatch names'] = offConventionDispatch;
  counts['typedef-record dispatch'] = typedefRecordDispatch;
  counts['private dispatch tables'] = privateDispatch;
  counts['multi-MAIN files'] = mainFilesSeen.values.where((n) => n > 1).length;
  counts['off-convention filenames'] = offConventionFilenames;

  return counts;
}
