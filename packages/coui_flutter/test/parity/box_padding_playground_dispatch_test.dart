import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart' as c;
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/markdown/repo_root.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/manifest/capture_probes.dart';
import '../../../../tool/parity/src/source/playground_value_authority.dart';
import '../helpers/test_app.dart';
import 'box_padding_paired.dart';
import 'box_padding_preview_receipts.dart';
import 'parity_matrix_entry.dart';

void main() {
  const components = [
    'button',
    'text-field',
    'text-area',
    'select',
    'checkbox',
    'toggle',
    'radio-group',
    'badge',
    'gap',
    'tabs',
    'dialog',
    'alert',
  ];
  final scenes = [
    for (final component in components)
      (
        component: component,
        scene: readDocsScenes(component).singleWhere(
          (value) => value.tag == 'Playground',
        ),
      ),
  ];
  final root = findRepoRoot();
  for (var index = 0; index < scenes.length; index++) {
    final (:component, :scene) = scenes[index];
    for (final dark in [false, true]) {
      testWidgets(
        'actual $component Playground dark=$dark '
        'reaches the paired reader through its mounted operation',
        (tester) async {
          final temporary = Directory.systemTemp.createTempSync(
            'playground-manifest-',
          );
          addTearDown(() => temporary.deleteSync(recursive: true));
          final manifest = File('${temporary.path}/manifest.json')
            ..writeAsStringSync(
              jsonEncode({
                'entries': [
                  {
                    'key': 'entry',
                    'component': component,
                    'variant': scene.reference,
                  },
                ],
              }),
            );
          final authority = SceneValueAuthority.fromJson(
            readPlaygroundValueAuthority(
              sourceRoot: root,
              manifestFile: manifest,
              entryKey: 'entry',
              component: component,
              reference: scene.reference,
            ),
          );
          final manager = OfficialPreviewReceipts.capture(
            registry: kFlutterPreviewRegistry,
            epoch: 'capture-$index-$dark',
          );
          final builder = kFlutterPreviewRegistry[component]!;
          final token = manager.authorize(
            entryKey: 'entry',
            component: component,
            variant: scene.reference,
            builder: builder,
            sceneValueAuthority: authority,
          );
          // Exactly the same official call and existing wrapper as capture.
          final result = builder(scene.reference);
          final key = GlobalKey();
          final handle = KeyedSubtree(key: key, child: result);
          manager.record(token: token, keyedHandle: handle, result: result);
          await tester.pumpWidget(
            buildTestApp(
              handle,
              theme: c.ThemeData.fromCore(
                dark ? c.CoreThemePresets.dark : c.CoreThemePresets.light,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final captureRoot = key.currentContext! as Element;
          final receipt = manager.requireMounted(
            captureRoot: captureRoot,
            entryKey: 'entry',
            component: component,
            variant: scene.reference,
            epoch: manager.epoch,
            sceneValueAuthority: authority,
          );
          final source = captureProbes(
            key: 'entry',
            component: component,
            variant: scene.reference,
            flutterClassName: scene.flutterOwnerType,
            docsScene: scene,
          ).single;
          final probe = ParityProbeSpec(
            role: source.role,
            flutterFinder: source.flutterFinder,
            fields: source.fields.map((field) => field.name).toSet(),
            boxObservationSource: source.boxObservationSource!.toJson(),
          );
          Map<Object?, Object?> observed({
            ValidatedPreviewReceipt? operation,
          }) =>
              (observePairedNativePadding(
                        key: 'entry',
                        probes: [probe],
                        captureRoot: captureRoot,
                        registryResult: result,
                        legacyRootOmitted: false,
                        previewReceipt: operation,
                      )['byRole']!
                      as Map)['root']!
                  as Map;
          final missing = observed();
          expect(missing['error'], 'MISSING_MOUNTED_PREVIEW_RECEIPT');
          expect(missing.containsKey('value'), isFalse);
          final actual = observed(operation: receipt);
          expect(actual['status'], 'source-complete', reason: '$actual');
          expect(actual['sourceReaderId'], 'declared-no-own-padding-v1');
          expect(actual['quantityKind'], 'declaredNoOwnPadding');
          expect(actual['value'], [0.0, 0.0, 0.0, 0.0]);
          expect(actual['sceneValueAuthority'], authority.toJson());
          expect(actual['privateSceneObjectIdentityClaim'], isFalse);
          expect(actual['canonicalComparisonEligible'], isFalse);
        },
      );
    }
  }
}
