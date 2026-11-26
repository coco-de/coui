# Zero-width FocusOutline verification

Base: a3e03ede073af406a99ccd72e1768002f58f4700. Flutter SDK 3.47.5.

Flutter Border.all(width: 0) uses a device-pixel hairline. With align: 0, the zero-width rounded border is painted on the child boundary instead of disappearing; its anti-aliasing can extend outside the box. The SDK rounded-border paint path explicitly uses drawRRect with strokeWidth 0. TextField activeDecoration is a separate inside stroke and does not cause this zero-width ring.

The FocusOutline resolver now emits BorderStyle.none when its resolved width is zero. Positive widths retain solid strokes. The widget forwards that paint-ready style. Gap bands, focus opacity animation, geometry and layout are preserved. Web already emits var(--coui-stroke-width-0), whose theme value is 0px, so no Web runtime change is necessary.

## Evidence

- Before correction: transparent-child pixel tests found 524 painted pixels for rectangle and 464 for circle at explicit width 0; both tests failed. Existing three band tests passed.
- After correction: FocusOutline and TextField functional/pixel tests pass, including zero-width rectangle/circle, positive default ring, custom radius, focus state, layout, and explicitly painted gap band preservation.
- Web FocusOutline resolver tests: 8 pass; explicit zero width resolves to the zero CSS stroke token for both shapes.
- All 47 existing CI golden comparisons pass without baseline changes. The existing FocusOutline macOS golden also passes.
- Targeted analyzer and diff whitespace checks run before commit.

The fix does not change default positive-width focus indicators or hide focus globally. Apps can still intentionally suppress a ring per instance and retain a visible active field boundary. Pixel verification used Flutter test rendering; browser visual review is separate.

## Preset render-tree contract

Official CI run 40475257707 reported 275 passing and 20 failing preset snapshot checks. All failures were the intended zero-width border style changing from solid to none, rather than geometry or color changes. The documented `UPDATE_PRESET_SNAPSHOTS=1 flutter test test/theme/preset_snapshot/preset_render_snapshot_test.dart` path regenerated the four preset JSON contracts.

A recursive old/new JSON comparison confirms exactly 112 leaf changes: 28 in each of defaultStyle, neoBrutalism, claymorphism and neumorphism. Every changed leaf is a border-side style solid→none whose existing width is 0. No widths, colors, radii, node counts, or other values changed. The five affected composed surfaces are chip-input, formatted-input, input-otp, object-input and phone-input. These snapshot examples have transparent zero-width borders; the visible opaque hairline defect is covered by the dedicated pixel tests above. Pixel golden baselines remain unchanged.

Regeneration and the subsequent ordinary comparison each pass all 295 preset tests. This contract update records the intentional implementation change rather than relaxing the assertion, excluding a preset, or increasing a tolerance. Reviewers can inspect all four JSON diffs in this PR.
