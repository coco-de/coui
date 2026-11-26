import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

/// Size-axis regression net — issue #3773.
///
/// Every other golden test in this directory sweeps *variants*, not
/// *sizes* — before this file, 18 golden files existed and exactly one
/// (`avatar_golden_test.dart`) rendered a non-default size, and even
/// that one scenario alone. Changing `CoreButtonStyle.defaultsBySize`
/// (or any of the other 13 `defaultsBySize` owners in `coui_core`)
/// produced zero compile errors, zero test failures, and one silent
/// product-wide visual change.
///
/// This file renders **every size member** of **every contract that
/// owns a `defaultsBySize` map** in one dedicated golden per component.
/// Because each `for (final size in CoreXxxSize.values)` loop reads the
/// enum's `.values` rather than a hand-written list, a size member added
/// later is picked up automatically — either its pixels differ (caught
/// by the golden diff) or its `defaultsBySize[size]!` lookup throws
/// (caught by the test itself failing to build). Either way, a
/// `defaultsBySize` edit — a member added, a member's value changed —
/// can no longer land silently.
///
/// Coverage is scoped to the contracts that actually own a
/// `defaultsBySize` map (Badge / Button / Checkbox / Chip /
/// DescriptionCard / Dock / Fab / Loading / RadioGroup / Status /
/// TextArea / TextField / Toggle / ValidationBadge / Tabs (#3885, Epic K
/// axis 8-2) / InputOtp) — not the ~140 component library.
/// Components without a size axis have nothing here to regress.
/// `CoreComponentSize.xl2` exists but TextArea has no confirmed 2xl spec
/// value (CoUI_Size_Token_Specification §3-5 leaves it pending census).
/// Its `defaultsBySize` map intentionally has no `xl2` entry, so rendering
/// `xl2` here would throw on the `defaultsBySize[size]!` lookup inside the
/// resolver. Badge has no `xl2` row either, but its resolver reads `xl2` as
/// `xl`, so it renders the full ladder — the `xl2` scenario pins that
/// fallback. Chip and Loading gained spec-confirmed xl2 tiers (§3-4) and
/// render the full ladder too.
const Set<CoreComponentSize> _unregulatedXl2 = {CoreComponentSize.xl2};

/// Determinate fill fraction used by the `Progress` size-axis scenarios —
/// midway so the fill bar reads clearly at every track thickness.
const _kProgressHalfValue = 0.5;

/// Partially filled `InputOtp` value for the size-axis scenarios — '1' '2'
/// '3' '4' as codepoints. Four of six cells, so the digit glyph, the
/// separator after the third cell and the empty-cell chrome all show at
/// every size.
const _kInputOtpPartialValue = [49, 50, 51, 52];

void main() {
  group('Size axis golden — defaultsBySize regression net (#3773)', () {
    goldenTest(
      'Badge — every CoreComponentSize',
      fileName: 'size_axis_badge',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreComponentSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                Badge(size: size, child: const Text('New')),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'Button — every CoreComponentSize',
      fileName: 'size_axis_button',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreComponentSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                Button(size: size, onPressed: () {}, child: const Text('Go')),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'Checkbox — every CoreComponentSize',
      fileName: 'size_axis_checkbox',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreComponentSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                Checkbox(
                  checked: true,
                  onChanged: null,
                  size: size,
                  label: 'Accept',
                ),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'Chip — every CoreChipSize',
      fileName: 'size_axis_chip',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreChipSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(Chip(label: 'Chip', size: size)),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'DescriptionCard — every CoreDescriptionCardSize',
      fileName: 'size_axis_description_card',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 550),
        children: [
          for (final size in CoreDescriptionCardSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                DescriptionCard(
                  size: size,
                  title: 'Order',
                  rows: const [
                    DescriptionRow(label: 'ID', value: 'ORD-1'),
                    DescriptionRow(label: 'Total', value: r'$10.00'),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'Dock — every CoreDockSize',
      fileName: 'size_axis_dock',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreDockSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                Dock(
                  size: size,
                  items: const [
                    CoreDockItemData<Widget>(
                      icon: Icon(LucideIcons.house),
                      label: 'Home',
                      isActive: true,
                    ),
                    CoreDockItemData<Widget>(
                      icon: Icon(LucideIcons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'Fab — every CoreFabSize',
      fileName: 'size_axis_fab',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreFabSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                Fab(size: size, trigger: const Icon(LucideIcons.plus)),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'Loading — every CoreComponentSize',
      fileName: 'size_axis_loading',
      // `pumpOnce` — every `Loading` variant starts a repeating
      // `AnimationController` (`..repeat()`) in `initState`, so the
      // default `onlyPumpAndSettle` pump action never observes a
      // settled frame (mirrors `loading_golden_test.dart`).
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreComponentSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(Loading(componentSize: size)),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'Progress — every CoreProgressSize',
      fileName: 'size_axis_progress',
      builder: () => GoldenTestGroup(
        // `Progress` always contains a `LayoutBuilder` (both the
        // determinate and indeterminate branches) — `LayoutBuilder`
        // refuses intrinsic-dimension queries, so `GoldenTestGroup`'s
        // default `IntrinsicColumnWidth` needs a *tight* width
        // constraint to short-circuit before it recurses into the
        // child (mirrors `progress_golden_test.dart`). `disableAnimation`
        // renders the determinate fill on the first frame without a
        // repeating `AnimationController`, so no `pumpBeforeTest` override
        // is needed here.
        scenarioConstraints: const BoxConstraints.tightFor(width: 300),
        children: [
          for (final size in CoreProgressSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                Progress(
                  value: _kProgressHalfValue,
                  disableAnimation: true,
                  size: size,
                ),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'RadioGroup — every CoreComponentSize',
      fileName: 'size_axis_radio_group',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreComponentSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                RadioGroup<String>(
                  size: size,
                  value: 'a',
                  options: const [(value: 'a', label: 'Option A')],
                ),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'Status — every CoreStatusSize',
      fileName: 'size_axis_status',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreStatusSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(Status(size: size)),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'TextArea — every CoreComponentSize',
      fileName: 'size_axis_text_area',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreComponentSize.values)
            if (!_unregulatedXl2.contains(size))
              GoldenTestScenario(
                name: size.name,
                child: buildGoldenTestApp(
                  TextArea(size: size, initialValue: 'Hello'),
                ),
              ),
        ],
      ),
    ).ignore();

    goldenTest(
      'TextField — every CoreComponentSize',
      fileName: 'size_axis_text_field',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreComponentSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                TextField(size: size, initialValue: 'Hello'),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'Toggle — every CoreComponentSize',
      fileName: 'size_axis_toggle',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreComponentSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                Toggle(value: true, onChanged: null, size: size),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'ValidationBadge — every CoreValidationBadgeSize',
      fileName: 'size_axis_validation_badge',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreValidationBadgeSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                ValidationBadge(
                  label: 'Has digit',
                  state: CoreValidationState.valid,
                  size: size,
                ),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'Tabs — every CoreTabsSize',
      fileName: 'size_axis_tabs',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          for (final size in CoreTabsSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                Tabs.labels(
                  labels: const ['One', 'Two'],
                  selectedIndex: 0,
                  size: size,
                ),
              ),
            ),
        ],
      ),
    ).ignore();

    goldenTest(
      'InputOtp — every CoreInputOtpSize',
      fileName: 'size_axis_input_otp',
      builder: () => GoldenTestGroup(
        // Wider than the other scenarios: a six-cell `lg` row is ~412px, and
        // under a 400 cap the widget's own scale-down fit would shrink it —
        // the golden would then pin a smaller cell than `lg` draws.
        scenarioConstraints: const BoxConstraints(maxWidth: 480),
        children: [
          for (final size in CoreInputOtpSize.values)
            GoldenTestScenario(
              name: size.name,
              child: buildGoldenTestApp(
                InputOtp(
                  initialValue: _kInputOtpPartialValue,
                  size: size,
                ),
              ),
            ),
        ],
      ),
    ).ignore();
  });
}
