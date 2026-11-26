/// Web-wide arithmetic sentinels for inline-CSS conversion (Epic
/// #1601 PoC).
///
/// These are not design tokens — they are unit-conversion constants
/// used uniformly across every `*_style.dart` builder. Centralising
/// them avoids the previous pattern where every component re-declared
/// `const _kRemDivisor = 16.0` (and friends) at the top of its file,
/// hiding the shared meaning behind component-local underscored
/// names.
library;

import 'package:coui_core/coui_core.dart';

/// Logical-px → rem divisor. Used in the Phase 6 rem-escape-hatch
/// inline-CSS conversion (`'${value / kRemDivisor}rem'`) for runtime
/// dimensional overrides that don't map onto a `CoreSpace` /
/// `CoreSize` token.
const double kRemDivisor = 16;

/// Opacity 0..1 → integer percentage scale. Used by the Tailwind
/// `/<pct>` opacity modifier (`'bg-primary/50'` for 0.5 opacity).
const int kPercentScale = 100;

/// Not a design token — the gap Flutter's editable text keeps between the
/// end of the text and its caret, fixed in the framework (`RenderEditable`).
///
/// Flutter lays an editable or selectable text out this gap plus the cursor
/// width wider than its glyphs, whether a caret shows or not, so a
/// `SelectableText` is that much wider than the same words in a `Text`. The
/// Web twins reserve the same room after the text, so the two boxes — and
/// whatever sits beside them — line up.
const double kEditableCaretGap = 1;

/// Not a design token — the cursor width Flutter's own `SelectableText`
/// takes when it is given none. A Web twin whose Flutter side draws the
/// framework's widget rather than CoUI's (`CodeSnippet`) reserves the caret
/// room with this width.
const double kEditableDefaultCursorWidth = 2;

/// Class marking an element as a component surface.
///
/// Carries no styling. It exists so a surface style whose boundary is a
/// shadow and nothing else can be handed a real stroke under forced
/// colours — a mode that does not paint shadows, and in which such a
/// boundary is simply absent rather than faint. The correction needs one
/// stable hook; without it every component that draws a surface would
/// have to carry its own copy.
const String kWebSurfaceMarker = 'coui-surface';

/// A surface with its own material, isolated from document material selectors.
const String kWebLocalSurfaceMarker = 'coui-material-surface';

/// Marks a surface that floats above the content layer.
///
/// Carries no styling of its own on the default preset. A style that
/// gives floating surfaces a different material scopes that material to
/// this class, which outranks the base marker rule by specificity — so a
/// preset with one material needs no rule here at all and content
/// surfaces render byte-for-byte as they did before roles existed.
const String kWebSurfaceRoleFunctional = 'coui-surface-functional';

/// Marks a surface that sits in the content layer.
///
/// Deliberately carries no CSS. It exists so the declaration is *present*
/// rather than implied by absence: a surface that forgot to choose and a
/// surface that chose content would otherwise be the same markup, and the
/// first is a bug the second is not.
const String kWebSurfaceRoleContent = 'coui-surface-content';

/// The classes that mark an element as a surface of a given kind.
///
/// Takes the role rather than defaulting it. A surface that does not
/// choose is exactly the failure the role axis exists to prevent, and a
/// required argument makes that a compile error instead of a silent
/// reading as content — the difference between a guard someone has to
/// run and one nobody can get past.
///
/// Returns both classes because the base rule is keyed on
/// [kWebSurfaceMarker]: dropping it for the role class would take the
/// forced-colours boundary correction with it.
List<String> webSurfaceMarkerFor(
  CoreSurfaceRole role, {
  CoreSurfaceStyleId? surfaceStyle,
}) => <String>[
  if (surfaceStyle == null) kWebSurfaceMarker else kWebLocalSurfaceMarker,
  if (surfaceStyle != null) 'coui-material-${surfaceStyle.name}',
  switch (role) {
    CoreSurfaceRole.functional => kWebSurfaceRoleFunctional,
    CoreSurfaceRole.content => kWebSurfaceRoleContent,
  },
];

/// Custom property through which a surface names its own background
/// triplet, so a style preset can restate that background at a different
/// alpha without knowing which token the component chose.
///
/// A preset cannot hardcode one token: a card fills with `surface`, a
/// popover with `popover`, a tooltip with something else again. And it
/// cannot add alpha to a composed `rgb(...)` after the fact. So the
/// component publishes the *triplet* — `--coui-surface` is a bare
/// `R G B` — and the preset composes the colour itself.
///
/// Setting a custom property has no rendering effect on its own, so a
/// surface carries this whether or not any preset is active.
const String kWebSurfaceFillVar = '--coui-surface-rgb';

/// Custom property through which a surface names its fill's own alpha,
/// beside the triplet in [kWebSurfaceFillVar].
///
/// The triplet is a bare `R G B` and carries no alpha, so a preset that
/// restated it at its share erased whatever alpha the token stated: a 10%
/// tint came out at the full share, and a fill authored at opacity 0 came
/// out half-filled. The preset multiplies this by its share instead — the
/// same `token alpha × share` the Flutter twin folds with `scaleAlpha`.
///
/// Published only when the fill is translucent; an opaque fill states
/// nothing and reads the `1` every marked surface starts from. That reset is
/// what keeps a surface from inheriting a translucent ancestor's alpha
/// through custom-property inheritance.
const String kWebSurfaceFillAlphaVar = '--coui-surface-alpha';

/// Custom property through which a surface that keeps a border of its own
/// says how wide that border is, so the material's edge band reaches over it.
///
/// The band is an absolutely placed pseudo-element, and `inset: 0` is the
/// element's *padding* box: inside the border. A surface with no border
/// (a card) has none to skip, so the band lands on its outer edge — where
/// the Flutter twin's sheen is painted over the whole box. A surface that
/// keeps a transparent hairline (a field, whose style states the edge itself
/// and hides the line's colour but not its width — zeroing it would grow the
/// content box when a style swaps) would put the band one border inside,
/// leaving the outermost row of pixels bare.
///
/// The stylesheet reads it as `calc(var(--x, 0px) * -1)`, so a surface that
/// states nothing keeps `inset: 0`.
const String kWebSurfaceBleedVar = '--coui-surface-bleed';

/// The top-edge counterpart of [kWebSurfaceBleedVar], for a surface whose
/// border is drawn on its top edge only (a docked bar's hairline).
///
/// The band's top inset reads this and falls back to [kWebSurfaceBleedVar],
/// so a surface that keeps a border on every side says it once and a bar that
/// keeps one on top says only that — the band reaches over the top line and
/// stays on the box's own edge on the three sides that have no border to skip.
const String kWebSurfaceBleedTopVar = '--coui-surface-bleed-top';

/// The bottom-edge counterpart of [kWebSurfaceBleedVar], for a surface whose
/// border is drawn on its bottom edge only (a banner's rule, an app bar's
/// hairline). Read and reset the way [kWebSurfaceBleedTopVar] is.
const String kWebSurfaceBleedBottomVar = '--coui-surface-bleed-bottom';

/// Marks a marked surface that clips its own content (`overflow: hidden`) and
/// keeps a border.
///
/// The band is an absolutely placed pseudo-element, and a clip stops at the
/// padding box — so widening the band over the border the surface keeps would
/// push it into the part the clip removes, and the band would vanish instead
/// of reaching the edge. The border is a transparent spacer where a material
/// draws its own edge, so such a surface lets that material fold the spacer
/// into its padding: the box keeps its size and its content stays where it
/// was, but the padding box — the clip's edge — becomes the border box, and the
/// band at `inset: 0` is on the outer edge. See [kWebSurfaceFoldVar].
///
/// Only a transparent border can be folded: a visible one is a line, and the
/// stylesheet gives it back wherever the user asked for one (forced colours,
/// more contrast). Every other style keeps the border the component drew.
const String kWebSurfaceClipMarker = 'coui-surface-clip';

/// The border style a clipping surface keeps, as a surface that carries
/// [kWebSurfaceClipMarker] states it: its `border-style` is this variable with
/// `solid` — what it drew — as the fallback.
///
/// A material that draws its own edge sets it to `none`, which makes the
/// computed border width zero at once. That is the point of folding with the
/// style rather than the width: `border-width` is a property the stylesheet
/// transitions, so a width folded to zero would glide away over a style swap
/// while the padding that replaces it jumped, and the content would move for a
/// moment. A style change is not interpolated, so border and padding change on
/// the same frame. It is reset to unset on every marked element (a custom
/// property inherits), so a surface nested in a folded one keeps its own
/// border.
const String kWebSurfaceEdgeStyleVar = '--coui-surface-edge-style';

/// `1` where the material folds a clipping surface's border into its padding,
/// unset (read as `0`) everywhere else. Set together with
/// [kWebSurfaceEdgeStyleVar]; [kWebSurfaceClipPadVar] multiplies by it.
const String kWebSurfaceFoldVar = '--coui-surface-fold';

/// What a clipping surface's padding adds when its border is folded away: the
/// surface's border width times [kWebSurfaceFoldVar], so zero until the border
/// is folded and exactly the border's width after. Stated inline beside the
/// surface's `border-style`, and added to whatever padding the surface states —
/// or, for a surface that states none, applied by the stylesheet at no
/// specificity, so a padding the caller gives it wins.
const String kWebSurfaceClipPadVar = '--coui-surface-clip-pad';

/// Inline custom property the surface runtime writes the rim's sweep to.
///
/// The stylesheet draws the ring — its width, its mask, its position — and
/// reads the gradient from here, because the gradient's stops depend on
/// the element's own rectangle and radius, which a stylesheet cannot know.
/// The runtime measures the element and writes the sweep; a surface no
/// runtime has reached falls back to `none` and draws no rim, never a
/// wrong one.
const String kWebSurfaceRimSweepVar = '--coui-surface-rim-sweep';

/// The sweep for the dark palette, written beside [kWebSurfaceRimSweepVar]
/// only when the rim is lit from another direction there.
///
/// A theme switch writes a document attribute and rebuilds nothing, so the
/// runtime cannot re-measure when the mode changes: it writes both sweeps
/// once and the stylesheet's dark rules choose between them. Absent, the
/// dark rules fall back to [kWebSurfaceRimSweepVar], which is the same light
/// from the same direction.
const String kWebSurfaceRimSweepDarkVar = '--coui-surface-rim-sweep-dark';

/// The direction the rim is lit from in the light palette, in degrees, when
/// the stylesheet states one other than the preset's.
///
/// The per-element runtime derives the rim's sweep from the *preset's* bevel
/// — it has no way to see an app's tuning. A tuning is a build-time decision
/// here (`ThemeConfig.surfaceTunings`), so what it changes reaches the
/// runtime the way it reaches everything else: as numbers in the
/// stylesheet. This is the number the runtime would otherwise get wrong.
/// Emitted only where it differs from the preset, so an untuned sheet is the
/// sheet it always was.
const String kWebSurfaceRimAngleVar = '--coui-surface-rim-angle';

/// [kWebSurfaceRimAngleVar] for the dark palette.
const String kWebSurfaceRimAngleDarkVar = '--coui-surface-rim-angle-dark';

/// The law the rim bends light by (`CoreRefractionModel.name`), when the
/// stylesheet states one other than the preset's.
///
/// The displacement map is baked per element by the runtime, which reads
/// the preset's refraction. Same transport and same reason as
/// [kWebSurfaceRimAngleVar]: the tuned law is a number the runtime cannot
/// see, so the stylesheet states it, and only when it differs.
const String kWebSurfaceRefractionModelVar = '--coui-surface-refraction-model';

/// Custom property through which a surface's `backdrop-filter` list names its
/// frost (`CoreSurfaceFrost`): the list says `var(--coui-surface-frost,)` and
/// the property holds a reference to the style's frost document — a `data:`
/// SVG filter defined once on `:root`.
///
/// A custom property rather than the `url()` spelled in the list, so that one
/// declaration can take the term away: the high-contrast and forced-colours
/// rule sets this to `initial` with `!important`, the list's empty fallback
/// (`var(--x,)`) then drops it, and no list has to be restated per palette to
/// do it. Written by every rule that uses it, in every palette, because a
/// custom property inherits and a surface that stated none would otherwise
/// read the frost of the surface it sits in.
///
/// Written only into a sheet whose recipe states a frost, so an untuned
/// sheet is the sheet it always was.
const String kWebSurfaceFrostVar = '--coui-surface-frost';

/// [kWebSurfaceFrostVar] for the body shade (`CoreSurfaceBodyShade`).
const String kWebSurfaceShadeVar = '--coui-surface-shade';

/// The progress of a panel that is opening or closing, as a number from `0`
/// (not there) to `1` (there).
///
/// Registered with `@property` (`overlay_host.dart`) so a keyframe can walk it
/// — an unregistered custom property would flip at the half way point — and
/// registered as **not inherited**: only the element that is animating reads
/// it. Its descendants see `1`, so a surface inside a fading panel never fades
/// a second time with it, and the browser does not restyle the whole subtree
/// of a panel on every frame of its fade.
///
/// A glass panel (one that draws a backdrop pass) does not fade by its
/// opacity: a backdrop filter under an opacity reads only the layer the
/// opacity saved, and the layer holds nothing. It reads this number instead
/// and gives up its terms one by one (`CoreSurfaceDissolve`), which is what the
/// stylesheet's fade rules for a panel state.
const String kFadeProgressVar = '--coui-fade';

/// How long a fading panel's own animation plays.
const String kFadeDurationVar = '--coui-fade-dur';

/// The curve a fading panel's own animation plays on.
const String kFadeEasingVar = '--coui-fade-ease';

/// The side of its animation the layers a fading panel draws hold on to:
/// `backwards` while it opens, `forwards` while it closes.
const String kFadeFillVar = '--coui-fade-fill';

/// The name of the keyframes every fading panel plays: the progress.
///
/// A panel plays the progress and then three animations that its rules name.
/// The three are the choice: a panel that draws no backdrop pass fades by its
/// **opacity** ([kFadeOpacityAnimationVar]) and plays nothing else; one that
/// draws a pass fades by its terms, and plays the keyframes that take its
/// shadow and edge ([kFadePaintAnimationVar]) and its content and decoration
/// layers ([kFadeLayerAnimationVar]) from where they stand to where they
/// started, in place of its opacity.
///
/// The choice is a name and not a length of zero: an animation of no length
/// that holds its end would apply the end keyframe at once, and the end of a
/// fade out is a panel that is not there. A slot a panel does not play is
/// given [kFadeNoAnimation].
///
/// The fade root states the three for a panel with no pass, and the rule that
/// gives a surface its pass states them again for a panel that has one
/// ([kFadeGlassPaintNameVar] and [kFadeGlassLayerNameVar] hold the names for
/// the direction the root is fading). Every rule that drops the pass states
/// the first answer back with `!important`.
const String kFadeProgressAnimationVar = '--coui-fade-progress';

/// The name of no animation, for the slots of a fade that a panel does not
/// play. Not the CSS keyword `none`: inside the `animation` shorthand that
/// word is also a fill mode, and `none 200ms ease both` would give `both`
/// to the name. This names keyframes that are not defined, which the browser
/// does not play.
const String kFadeNoAnimation = 'co-fade-none';

/// The keyframes a panel that draws no pass plays in place of nothing: its
/// opacity.
const String kFadeOpacityAnimationVar = '--coui-fade-opacity';

/// The keyframes a panel that draws a pass plays on its shadow and edge.
const String kFadePaintAnimationVar = '--coui-fade-paint';

/// The keyframes a panel that draws a pass plays on its content and on what it
/// draws on its pseudo-elements.
const String kFadeLayerAnimationVar = '--coui-fade-layer';

/// The name of the opacity keyframes for the direction the fade root is
/// fading.
const String kFadeOpacityNameVar = '--coui-fade-opacity-name';

/// The name of the shadow-and-edge keyframes for the direction the fade root
/// is fading.
const String kFadeGlassPaintNameVar = '--coui-fade-glass-paint';

/// The name of the content-and-decoration keyframes for the direction the fade
/// root is fading.
const String kFadeGlassLayerNameVar = '--coui-fade-glass-layer';

/// The motion box of a panel the popover engine places: its child is the panel
/// that fades, and the box itself only scales.
const String kFadeBoxClass = 'coui-fade-box';

/// A panel that is its own motion box (the dialog's): it scales and fades.
const String kFadePanelClass = 'coui-fade-panel';

/// The custom property that holds a surface's whole `backdrop-filter` list
/// while the surface is a panel that fades.
///
/// The refraction runtime appends its bend to the surface's own filter list
/// and writes the result inline, where it outranks the stylesheet. Writing the
/// list as it was computed at that moment would freeze whatever the fade had
/// reached; writing `var(--coui-surface-pass) url(#…)` keeps the list the
/// stylesheet states, which moves with the fade.
const String kWebSurfacePassVar = '--coui-surface-pass';

/// Attribute the browser build writes on `<html>` when this browser does not
/// draw an SVG filter named in `backdrop-filter` ([kWebSvgBackdropOff]).
///
/// The frost and the body shade are two such filters, and a browser that does
/// not draw them draws nothing for the whole list that names one — the
/// surface's own blur and saturation included. The sheet therefore carries a
/// rule keyed on this attribute that takes the two terms out of every list,
/// and what is left is the glass the list would have drawn without them.
/// Written once per page, from the same answer the refraction reads, so the
/// two cannot disagree about one browser.
///
/// It is the second route, not the only one: a layer that was drawn from a
/// list naming a filter keeps its missing blur when the list is corrected
/// afterwards, so for WebKit the sheet takes the terms out from the first
/// paint by a feature query that needs no script. The attribute reaches what
/// the query cannot name (Gecko) and the surfaces created after it is written.
const String kWebSvgBackdropAttribute = 'data-coui-svg-backdrop';

/// The value of [kWebSvgBackdropAttribute] on a browser that does not draw an
/// SVG filter named in `backdrop-filter`.
const String kWebSvgBackdropOff = 'off';

/// Marker class that extends where an element accepts a pointer, without
/// changing what it draws or how much room it takes.
///
/// WCAG 2.2 `2.5.8` asks for a 24×24 pointer target. Raising the drawn
/// size of every small control to meet it would redesign the kit; this
/// raises only the region that accepts a pointer, and the element looks
/// exactly the same.
///
/// The rule lives once, globally, and the browser does the measuring —
/// `max(100%, 24px)`. That is why this is a class and not a per-instance
/// rule: a component would otherwise have to know its own rendered size
/// in Dart to write the rule, and a chip's height comes from its content
/// rather than from any field a resolver could read.
const String kWebTouchTargetMarker = 'coui-touch-target';

/// Custom property a [kWebTouchTargetMarker] element states to raise its own
/// pointer floor above the WCAG minimum — the marker's global rule reads it
/// and falls back to `CoreTouchTarget.minimum` where nothing states it.
///
/// A navigation destination states its 48: the floor is still one global
/// rule and the browser still does the measuring, only the number moves.
const String kWebTouchTargetVar = '--coui-touch-target';

/// Marker class for a control whose rest `box-shadow` came from
/// `Button`'s shadow resolver — either the injected `--coui-control-
/// shadow` (`merged.boxShadow == null`, a plain button) or a caller-
/// stated one (`Fab`'s own elevation). `Button` carries it unconditionally
/// — every instance qualifies, since a plain button's shadow is always
/// either its own or the style's injected one.
///
/// The press-squash effect this drives (`ThemeConfig
/// ._controlShadowPressRule` — `:active` hides the shadow and travels the
/// control by the distance the active style throws shadows) is a single
/// global rule, not one scoped per style: a second `[data-coui-style="X"]`
/// selector here would be more specific than a plain one, which is
/// exactly the specificity floor the high-contrast preference is built
/// to clear over every style rule (`preset_vs_high_contrast_test.dart`).
/// So which style is active speaks only through *values* the rule reads
/// — `--coui-control-shadow-press` / `--coui-control-shadow-offset-x/y`
/// — each undefined (falling to a no-op fallback) under a style that
/// states no `CoreSurfaceGeometryConstraint.shadowOffsetAdd`
/// (`ThemeConfig.surfaceStyleGeometryBlock`), so a control's own rest
/// shadow (real or "nothing") is untouched by pressing it under every
/// style but the one that means to touch it.
///
/// That rule is also the control's **sole** `transition` declaration —
/// see [kControlChromeDurationVar] for why a control may not state one of
/// its own.
const String kControlShadowPressMarker = 'coui-control-shadow-press';

/// Custom property through which a control names the clock its *chrome*
/// transition runs on — the border radius / padding / border width /
/// colour group that Flutter's `AnimatedContainer` interpolates on
/// `CoreButtonStyle.animationDuration`.
///
/// The clock is per-instance but the declaration that reads it is global,
/// and that split is the point. `transition` is a single shorthand: the
/// press half (`transform` / `box-shadow` on a 50ms clock, from
/// `ThemeConfig._controlShadowPressRule`) and the chrome half have to be
/// written by **one** declaration or the later one silently resets the
/// earlier one's `transition-property`. Two class-level rules on the same
/// element are equally specific, so which one survives would come down to
/// stylesheet source order — and an inline `transition` on the control
/// would beat both. Either way one half dies without a compile error, a
/// warning, or a visible difference until someone presses the control.
///
/// So the control states no `transition` at all. It publishes this
/// duration and the shared rule composes both halves around it, exactly
/// as `--coui-control-shadow-press` lets that rule read a per-style value
/// it cannot select on. The rule's own `0s` fallback keeps a control that
/// never sets this from animating its chrome, so the property list costs
/// nothing where nothing states a clock.
///
/// The value routes through `durationMsCss` (token step →
/// `var(--coui-duration-N)`), which is what puts the chrome transition
/// inside reach of `@media (prefers-reduced-motion:reduce)`.
const String kControlChromeDurationVar = '--coui-control-chrome-duration';

/// Custom property through which a control names the clock its
/// engage-squash pair (the shadow hide and the travel,
/// `ThemeConfig._controlShadowPressRule`) runs on — Flutter's mirror is
/// `CoreButtonStyle.castHideDuration` / `CoreChipStyle.castHideDuration`
/// (#4407).
///
/// Same shape as [kControlChromeDurationVar] and for the same reason: the
/// shared rule is the control's *sole* `transition` declaration, so a
/// per-instance override cannot ride its own `transition` (that would
/// replace the shorthand's whole property list, silently dropping
/// whichever half — chrome or engage — the control does not restate).
/// The control publishes this custom property instead and the shared rule
/// reads it with `var(<this>, <token fallback>)`, so a control that never
/// overrides the default costs nothing (the fallback resolves) and one
/// that does reaches the rule without a second `transition` declaration
/// to fight over.
///
/// The value routes through `durationMsCss` too, so an override that
/// lands on a token step still reaches `@media
/// (prefers-reduced-motion:reduce)` the same way the default does.
const String kControlEngageDurationVar = '--coui-control-engage-duration';

/// Multiplier for off-scale transition durations under reduced motion.
const String kTransitionMotionFactorVar = '--coui-transition-motion-factor';

/// Marker class for a control that shrinks while pressed —
/// `CoreButtonStyle.pressedScale`, the Web half of the Flutter button's
/// `Clickable.pressedScale`.
///
/// Carried only when the control states a shrink and has feedback on, so
/// a control that says "no shrink" gains no rule at all. The effect is
/// one global rule (`ThemeConfig._controlPressScaleRule`) for the same
/// reason [kControlShadowPressMarker]'s is: a per-style selector would
/// out-rank the high-contrast specificity floor, so which style is
/// active speaks only through [kControlPressShrinkVar]'s value.
///
/// The rule writes the standalone `scale` property, not `transform`, so
/// a control positioned by a transform keeps its position while pressed
/// — the hazard [kControlShadowPressMarker]'s rule already moved its own
/// travel to `translate` for.
const String kControlPressScaleMarker = 'coui-control-press-scale';

/// Custom property through which a control states how far it shrinks
/// while pressed — the resolved `CoreButtonStyle.pressedScale`, inline.
const String kControlPressScaleVar = '--coui-control-press-scale';

/// Custom property a surface style uses to say "a casting control
/// engages by moving, not by shrinking" — `0` turns the press shrink off,
/// `1` (the fallback) leaves it on.
///
/// Written by `ThemeConfig.surfaceStyleGeometryBlock` exactly where it
/// writes a non-zero `--coui-control-shadow-offset-x/y`, and restored to
/// `1` inline by a control that casts nothing (it has no shadow to move
/// into, so the shrink is its only press signal). That pair reproduces
/// the Flutter resolver's condition term for term: the shrink is pinned
/// to `1.0` exactly when the style states a travel *and* this control
/// has a shadow to travel into.
const String kControlPressShrinkVar = '--coui-control-press-shrink';

/// Marks a surface that takes the style's injected cast at rest.
///
/// The cast is a variable reference, so it cannot ride a preset Tailwind
/// utility — the obvious emit is inline. But an inline declaration
/// outranks every selector, including the `hover:shadow-*` class a
/// hoverable surface uses for its elevation feedback, so inlining the
/// cast on a hoverable surface trades that feedback away. Riding a class
/// instead puts the two on the same footing and lets specificity decide:
/// `hover:shadow-*` is two class-level selectors to this marker's one, so
/// it wins while hovered and this wins at rest. That is the behaviour
/// both cases want, from one mechanism rather than two.
///
/// Only for surfaces that resolve to *no* shadow of their own. A surface
/// that authored one, or that resolves to an elevation class, states its
/// own rest value and must not carry this.
const String kControlShadowRestMarker = 'coui-control-shadow-rest';

/// Marks a surface whose rest elevation rides a `shadow-*` class and
/// whose hover elevation rides a `hover:shadow-*` class, so the style's
/// surface rim (`--coui-surface-rim`) is appended to both.
///
/// The rim cannot ride the surface inline: an inline `box-shadow`
/// outranks the `hover:shadow-*` class and freezes the hover-elevation
/// change. It cannot ride an ID-scoped rule either — an ID out-ranks the
/// hover class the same way. What the two elevation classes actually
/// vary is `--tw-shadow`; the `box-shadow` each declares is just
/// Tailwind's composition of that variable with the ring layers. So the
/// rule this marker selects restates that same composition with the rim
/// as one more layer, and the hover class keeps working by changing the
/// one variable the composition reads.
///
/// Only for a surface that resolves to an elevation class. A surface
/// with no rest shadow does not carry it — a rim decorates a surface
/// that casts, it does not raise a flat one (the Flutter side gates
/// `resolveSurfaceRim` on the same condition).
const String kSurfaceRimLiftMarker = 'coui-surface-rim-lift';

/// Marker class for a surface that draws no border of its own and takes
/// the active style's contributed one.
///
/// The border twin of [kControlShadowRestMarker], and it rides a class
/// for the same reason: which style is active speaks only through a
/// *value* (`--coui-control-border`), undefined under every style that
/// contributes none, so the rule falls through to a genuine `0` width
/// there and carrying the marker costs nothing.
///
/// Carried unconditionally by the surfaces that qualify, not toggled per
/// instance — a surface that authors its own border does not wear this
/// at all, because the contributed boundary is for the empty case only.
const String kControlBorderMarker = 'coui-control-border';

/// `animation-name` for the global `Skeleton` pulse `@keyframes` (defined
/// once in `ThemeConfig.cssVariables`).
///
/// Shared between the keyframes' own definition and every `Skeleton`
/// node's inline `animation-name` so the two cannot name-drift apart —
/// each name lives in one constant instead of being retyped as a literal
/// in both files.
const String kSkeletonPulseAnimationName = 'co-skeleton-pulse';

/// `animation-name` of the `Skeleton` keyframes that hold the resting end —
/// `--pulse-from` at every point — run in place of the pulse under reduced
/// motion (`CoreReducedMotion.runsPlaceholderPulse`).
///
/// A held keyframe rather than `animation: none` or a paused pulse: with no
/// animation the node falls back to its class fill, the PEAK, and a pulse
/// paused when the setting turns on freezes wherever it happened to be.
const String kSkeletonRestAnimationName = 'co-skeleton-rest';

/// CSS custom property every `Skeleton` node's inline `animation-name` reads
/// (`var(--coui-skeleton-pulse, co-skeleton-pulse)`).
///
/// The pulse is emitted inline, which no stylesheet rule outranks, so the
/// reduced-motion media query reaches it the way it reaches every other
/// duration: by overriding a variable on `:root`, here to
/// [kSkeletonRestAnimationName].
const String kSkeletonPulseNameVar = '--coui-skeleton-pulse';

/// Marker `Clickable` toggles directly on its root DOM node (no
/// `setState` — see `ResolvedClickable`'s doc on why press/focus state
/// detection stays browser-native) so keyboard activation gets the same
/// press affordance a pointer gets for free from `:active`.
///
/// The browser attaches `:active` on keyboard activation only to a
/// native `<button>`, never to `<div role="button">` — the element
/// `Clickable` renders, because it wraps arbitrary content and a native
/// `<button>` around another interactive element is invalid HTML. So
/// Space/Enter drive this marker by hand instead, and the global press
/// rule (`coui_web.dart`) matches it alongside `:active`, reading the
/// exact same `--coui-press-scale` / `--coui-press-x` / `--coui-press-y`
/// / `--coui-press-shadow` custom properties either trigger already
/// sets inline — only the trigger differs, so per-instance values never
/// need a second, scoped copy of the rule.
const String kClickableKeyPressedMarker = 'coui-clickable-key-pressed';
