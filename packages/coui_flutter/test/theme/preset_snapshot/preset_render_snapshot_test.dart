// #4355 — the four non-glass presets render identically across this
// Project, checked rather than asserted.
//
// ## What this fixes in place
//
// `docs/surface-preset-axis.md` and every issue under this Epic repeat the
// same sentence: the role axis and the material values reach `liquidGlass`
// and leave `defaultStyle`/`neoBrutalism`/`claymorphism`/`neumorphism`
// alone, because those four state no material and so have nothing for the
// axis to interpret. That is true of the design. It is not, on its own,
// evidence about the render — a component restructured to *carry* its role
// can change what it paints under a preset that states nothing, and the
// design argument would still read as sound.
//
// So this file captures what each of the 71 surfaces actually puts into the
// render tree under each of the four presets, and fails when that moves.
//
// ## Why it lands before the restructure, not after
//
// #4348/#4349 change the structure of 51 components. A net woven after they
// land records their output as the baseline and can never say whether they
// moved anything. The baseline has to predate the change it is meant to
// hold still — which is the whole reason this item exists at this point in
// the sequence rather than at the end.
//
// ## Updating the baselines
//
//     UPDATE_PRESET_SNAPSHOTS=1 flutter test \
//       test/theme/preset_snapshot/preset_render_snapshot_test.dart
//
// Run from `packages/coui_flutter/`. A rewrite is a decision, not a fix:
// the diff is the description of what a change did to four presets that
// were supposed to be untouched, and it belongs in the PR that caused it.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../../parity/parity_network_image_stub.dart';
import 'preset_surface_capture.dart';
import 'preset_surface_list.dart';

/// The presets this snapshot holds still.
///
/// Written out rather than derived from "states no material". Deriving it
/// would make the guarded set a function of the very field a leak would
/// change: a material written into `neoBrutalism` would drop that preset
/// out of the set, and the suite would pass over three presets while
/// reporting green. The completeness test below keeps the list honest in
/// the other direction — a new preset cannot quietly stay uncovered.
const List<CoreSurfaceStyleId> kNonGlassPresets = [
  CoreSurfaceStyleId.defaultStyle,
  CoreSurfaceStyleId.neoBrutalism,
  CoreSurfaceStyleId.claymorphism,
  CoreSurfaceStyleId.neumorphism,
];

/// The one preset that does state a material, and so is not held still by
/// this file — it is what the Project is changing.
const CoreSurfaceStyleId kGlassPreset = CoreSurfaceStyleId.liquidGlass;

/// Logical view height. `flutter_test`'s 600px default clamps components
/// whose natural height exceeds it (`window`'s example is ~648px) into a
/// `RenderFlex overflowed` that kills the capture; the same 1200 the parity
/// capture uses for the same reason. Width is left alone — nothing here
/// measures natural width, so widening it would only move layout.
const double _kViewportHeightLogicalPx = 1200;

/// How long a tree is given to settle before the capture reads it.
const Duration _kSettleTimeout = Duration(seconds: 3);

/// Whether this run rewrites the baselines instead of checking them.
bool get _updating => Platform.environment['UPDATE_PRESET_SNAPSHOTS'] == '1';

/// Survey slug → preview-registry key.
///
/// The glass survey keeps the name it judged (`hero-section`). The public
/// block and [kFlutterPreviewRegistry] use `hero`. The baseline keys stay
/// on the survey slug so a rename does not reshoot four preset files.
String _previewKey(String surveySlug) => switch (surveySlug) {
  'hero-section' => 'hero',
  _ => surveySlug,
};

/// `neoBrutalism` → `neo_brutalism`, so a baseline filename reads the same
/// way every other file in this repo does.
String _fileStem(CoreSurfaceStyleId id) =>
    id.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

File _baselineFile(Directory repoRoot, CoreSurfaceStyleId id) => File(
  '${repoRoot.path}/packages/coui_flutter/test/theme/preset_snapshot/'
  'baselines/${_fileStem(id)}.json',
);

/// The material fields the fold writes onto a theme.
///
/// Captured beside the render because the two answer different halves of
/// the same question. The render says what reached paint *today*; this says
/// what the preset offered, which a component may not consume yet. A
/// material stated on a non-glass preset that nothing currently reads would
/// otherwise sit in the recipe invisibly until some later component started
/// honouring it — a regression already merged, waiting.
Map<String, Object?> _themeMaterialJson(ThemeData theme) => {
  'surfaceOpacity': theme.surfaceOpacity,
  'surfaceBlur': theme.surfaceBlur,
  'surfaceSaturation': theme.surfaceSaturation,
  'surfaceBackdropBrightness': theme.surfaceBackdropBrightness,
  'surfaceSheen': theme.surfaceSheen?.toString(),
  'surfaceDrawsOwnEdge': theme.surfaceDrawsOwnEdge,
  'surfaceRefraction': theme.surfaceRefraction?.toString(),
  'functionalSurface': theme.functionalSurface?.toString(),
  'nestedSurfaces': theme.nestedSurfaces?.toString(),
  'overlayMorph': theme.overlayMorph?.toString(),
};

/// The same fold `CoUIApp` performs — never a re-derivation of it.
///
/// `applySurfaceStyle`'s own doc comment names the failure a second
/// implementation causes: the harness answers differently from the app and
/// the divergence it was built to catch is the one it cannot see.
/// `CoreThemePresets.light` rather than `const ThemeData()` because a
/// preset with a `colorConstraint` reads real ARGB and throws on the
/// tokenised default.
ThemeData _styledTheme(CoreSurfaceStyleId style) => applySurfaceStyle(
  ThemeData.fromCore(CoreThemePresets.light),
  surfaceStyle: style,
  highContrast: false,
);

/// Serialises a baseline with one line per chrome node.
///
/// Fully-indented JSON put these files at ~18,500 lines each, which is a
/// baseline nobody reads and therefore a diff nobody checks. One line per
/// node is ~800 — small enough to scan, and it keeps the granularity that
/// matters: a node whose fill alpha moved shows up as that node's line
/// changing, next to the surface it belongs to. The parse is unaffected
/// (`jsonDecode` does not care about whitespace), so the comparison above
/// reads the same values either way.
String encodeBaseline(Map<String, Object?> data) {
  final buffer = StringBuffer('{\n');
  final surfaces = data['surfaces']! as Map<String, Object?>;
  for (final key in data.keys.where((k) => k != 'surfaces')) {
    buffer.writeln('  ${jsonEncode(key)}: ${jsonEncode(data[key])},');
  }
  buffer.writeln('  "surfaces": {');
  var remaining = surfaces.length;
  for (final entry in surfaces.entries) {
    final value = entry.value! as Map<String, Object?>;
    final nodes = value['nodes']! as List<Object?>;
    buffer
      ..writeln('    ${jsonEncode(entry.key)}: {')
      ..writeln('      "settled": ${jsonEncode(value['settled'])},')
      ..writeln('      "nodes": [');
    for (var i = 0; i < nodes.length; i++) {
      final comma = i == nodes.length - 1 ? '' : ',';
      buffer.writeln('        ${jsonEncode(nodes[i])}$comma');
    }
    buffer
      ..writeln('      ]')
      ..writeln('    }${--remaining == 0 ? '' : ','}');
  }
  buffer
    ..writeln('  }')
    ..writeln('}');

  return buffer.toString();
}

void main() {
  final repoRoot = findRepoRoot();
  final slugs = readSurfaceSlugs(repoRoot);

  // Captured per preset as the entries run; written once at the end when
  // updating, compared entry by entry when not.
  final captured = <CoreSurfaceStyleId, Map<String, Object?>>{
    for (final preset in kNonGlassPresets) preset: <String, Object?>{},
  };

  group('coverage is what the survey says it is', () {
    test('every non-glass preset is named, and only glass is left out', () {
      // A fifth preset added without a decision would otherwise be
      // uncovered and silent. Failing here forces the decision to be
      // written down — either into `kNonGlassPresets` or, if it states a
      // material, beside `kGlassPreset`.
      final uncovered = CoreSurfaceStyleId.values
          .where((id) => !kNonGlassPresets.contains(id))
          .toSet();
      expect(
        uncovered,
        {kGlassPreset},
        reason:
            '이 스냅샷이 덮지 않는 프리셋은 재질을 진술하는 것 하나뿐이어야 한다. '
            'CoreSurfaceStyleId 에 프리셋이 늘었다면 kNonGlassPresets 에 넣거나 '
            '재질을 진술한다는 판단을 kGlassPreset 옆에 적어라.',
      );
    });

    test('the guarded presets state no material', () {
      // The premise the whole Project rests on, stated where it can fail.
      // If this breaks, the four presets are no longer "non-glass" and the
      // render baselines below are holding still something that changed
      // meaning.
      for (final preset in kNonGlassPresets) {
        final recipe = CoreSurfaceRecipe.presets[preset];
        expect(recipe, isNotNull, reason: '$preset 의 레시피가 없다');
        expect(
          [recipe!.surface, recipe.functionalSurface],
          everyElement(isNull),
          reason:
              '${preset.name} 이 재질을 진술한다 — 이 파일이 "비-유리" 로 다루는 '
              '전제가 깨졌다. 의도한 변경이면 kNonGlassPresets 에서 빼고 그 이유를 '
              '적어라.',
        );
      }
    });

    test('every surveyed surface has a preview builder', () {
      final missing = slugs
          .where(
            (slug) => !kFlutterPreviewRegistry.containsKey(_previewKey(slug)),
          )
          .toList();
      expect(
        missing,
        isEmpty,
        reason:
            '$missing 이 kFlutterPreviewRegistry 에 없다 — 서베이와 프리뷰 '
            '레지스트리가 갈렸다. 렌더할 수 없는 표면은 이 그물의 구멍이다.',
      );
    });
  });

  group('every non-glass preset renders what its baseline says', () {
    // Rendered once for the whole file, then re-applied per entry.
    // `debugNetworkImageHttpClientProvider` must be set *and unset inside
    // every single `testWidgets` body* — the binding asserts every painting
    // debug global is back to default the instant a callback returns, and
    // a `setUpAll`-only version fails the entry after the first.
    late Uint8List imageBytes;
    setUpAll(() async {
      imageBytes = await renderParityStubImageBytes();
    });

    for (final preset in kNonGlassPresets) {
      final baselineFile = _baselineFile(repoRoot, preset);
      Map<String, Object?>? baseline;
      if (!_updating) {
        if (!baselineFile.existsSync()) {
          // No baseline is not "nothing to compare" — it is a net with a
          // hole. One failing test per preset says so, rather than 71
          // quietly-skipped entries.
          test('${preset.name}: baseline missing', () {
            fail(
              '${baselineFile.path} 가 없다 — UPDATE_PRESET_SNAPSHOTS=1 로 '
              '기준선을 만들어라. 기준선 없는 스냅샷은 아무것도 고정하지 않는다.',
            );
          });
          continue;
        }
        baseline =
            jsonDecode(baselineFile.readAsStringSync()) as Map<String, Object?>;
      }

      final baselineSurfaces =
          baseline?['surfaces'] as Map<String, Object?>? ?? const {};

      test('${preset.name}: the fold states no material on the theme', () {
        final actual = _themeMaterialJson(_styledTheme(preset));
        captured[preset]!['themeMaterial'] = actual;
        if (_updating) return;
        expect(
          actual,
          baseline!['themeMaterial'],
          reason:
              '${preset.name} 의 테마 재질 필드가 기준선과 다르다 — 아직 아무 '
              '컴포넌트도 읽지 않아 렌더에는 안 보이더라도, 진술된 재질은 이미 '
              '레시피에 들어와 있다.',
        );
      });

      test('${preset.name}: the baseline covers exactly the surveyed set', () {
        if (_updating) return;
        expect(
          baselineSurfaces.keys.toSet(),
          slugs.toSet(),
          reason:
              '기준선이 덮는 표면 집합이 서베이와 다르다 — 표면이 추가/제거됐다면 '
              'UPDATE_PRESET_SNAPSHOTS=1 로 다시 찍고 그 diff 를 PR 에 설명해라.',
        );
      });

      for (final slug in slugs) {
        testWidgets('${preset.name}/$slug', (tester) async {
          await runParityEntryWithStubbedNetwork(imageBytes, () async {
            tester.view.physicalSize = Size(
              tester.view.physicalSize.width,
              _kViewportHeightLogicalPx * tester.view.devicePixelRatio,
            );
            addTearDown(tester.view.reset);

            // Cleared before the entry's own mount. Element reconciliation
            // will otherwise treat a same-shaped tree as an *update* of the
            // previous entry's still-mounted subtree, and the previous
            // component's chrome leaks into this one's capture with nothing
            // raised — the trap `flutter_capture_matrix_test.dart` measured
            // directly and documents at length.
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpWidget(
              Theme(
                data: _styledTheme(preset),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  // `Overlay` because an entry that autofocuses a text
                  // field needs one ancestor; `Center(…Factor: 1)` between
                  // it and the content because `Overlay` force-tight-sizes
                  // its children to the viewport, which would give every
                  // component the same 800×600 layout.
                  child: material.Material(
                    color: material.Colors.transparent,
                    child: material.Overlay(
                      initialEntries: [
                        material.OverlayEntry(
                          builder: (_) => Center(
                            widthFactor: 1,
                            heightFactor: 1,
                            child: kFlutterPreviewRegistry[_previewKey(slug)]!(
                              null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            // A bounded settle. `pumpAndSettle`'s own default timeout is
            // ten minutes, which at 284 entries is not a slow suite but a
            // stuck CI job. Everything in the catalogue settles today; the
            // fallback exists so an indeterminate animation added later
            // degrades to a fixed-phase capture rather than a hang, and
            // says so in the entry.
            var settled = true;
            try {
              final _ = await tester.pumpAndSettle(
                const Duration(milliseconds: 100),
                EnginePhase.sendSemanticsUpdate,
                _kSettleTimeout,
              );
            } on FlutterError {
              settled = false;
              await tester.pump(const Duration(milliseconds: 16));
            }

            final nodes = captureSurfaceChrome(tester);
            // Zero chrome nodes means the walk found nothing to compare —
            // a preview that failed to build, or a capture whose node kinds
            // stopped matching. Either way an empty entry would compare
            // equal to an empty baseline forever.
            expect(
              nodes,
              isNotEmpty,
              reason:
                  '$slug 이 chrome 노드를 하나도 내지 않았다 — 프리뷰가 빌드되지 '
                  '않았거나 캡처가 더 이상 이 트리의 노드를 알아보지 못한다.',
            );

            final entry = {'settled': settled, 'nodes': nodes};
            final surfaces =
                captured[preset]!.putIfAbsent(
                      'surfaces',
                      () => <String, Object?>{},
                    )
                    as Map<String, Object?>;
            surfaces[slug] = entry;
            if (_updating) return;

            expect(
              jsonDecode(jsonEncode(entry)),
              baselineSurfaces[slug],
              reason:
                  '${preset.name}/$slug 의 렌더가 기준선과 다르다. 이 프리셋은 '
                  '재질을 진술하지 않으므로 이 Project 가 바꿀 것이 없어야 한다 — '
                  '바뀌었다면 그 이유를 PR 에 적고 기준선을 다시 찍어라.',
            );
          });
        });
      }
    }
  });

  tearDownAll(() {
    if (!_updating) return;
    for (final preset in kNonGlassPresets) {
      final data = captured[preset]!;
      final surfaces = (data['surfaces'] as Map<String, Object?>?) ?? {};
      // A run where some entry failed would otherwise write a baseline with
      // that surface simply absent, and the next run would compare a
      // 70-surface baseline against a 70-surface set and report green — a
      // hole locked in by the very command meant to close one.
      final missing = slugs.where((s) => !surfaces.containsKey(s)).toList();
      if (missing.isNotEmpty) {
        throw StateError(
          '${preset.name} 의 표면 ${missing.length}개가 캡처되지 않아 기준선을 '
          '쓰지 않는다: $missing — 실패한 항목을 먼저 고쳐라. 부분 기준선은 '
          '구멍을 통과로 굳힌다.',
        );
      }
      final sorted = {for (final slug in slugs) slug: surfaces[slug]};
      _baselineFile(repoRoot, preset).writeAsStringSync(
        encodeBaseline({
          'preset': preset.name,
          'brightness': 'light',
          'variant': 'default',
          'surfaceCount': sorted.length,
          'themeMaterial': data['themeMaterial'],
          'surfaces': sorted,
        }),
      );
    }
  });
}
