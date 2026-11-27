import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/breakpoint/breakpoint_default_example.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;
import 'package:jaspr_test/jaspr_test.dart' show TestComponentsBinding;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/breakpoint_showcase_ssr_source.dart';
import '../../src/web/ssr_render.dart';
import '../../src/web/ssr_source_identity.dart';

MatrixEntry _entry([String theme = 'light']) => MatrixEntry.fromJson({
  'component': 'breakpoint',
  'variant': 'default',
  'theme': theme,
  'surfaceStyle': 'defaultStyle',
  'tier': 't2',
  'probes': [
    rootProbeSpec(
      key: 'breakpoint-default-$theme-defaultStyle',
      flutterClassName: 'Breakpoint',
      boxObservationSource:
          BoxObservationSourceSpec.breakpointShowcaseContentInset,
    ).toJson(),
  ],
});

class _Capture extends StatelessComponent {
  const _Capture(this.entry, this.source, {this.scenario});
  final MatrixEntry entry;
  final BreakpointShowcaseSsrSource source;
  final String? scenario;
  @override
  Component build(BuildContext context) {
    final result = scenario == 'subclass'
        ? const _Unknown()
        : kWebPreviewRegistry['breakpoint']!(context, 'default');
    final capture = div(
      [result],
      attributes: {
        'data-parity-key': scenario == 'wrong-key' ? 'foreign' : entry.key,
      },
    );
    source.recordBuild(result, capture);
    return scenario == 'detached' ? const div([]) : capture;
  }
}

class _Unknown extends BreakpointDefaultExample {
  const _Unknown();
}

void main() {
  for (final theme in ['light', 'dark']) {
    test(
      'Stateful default/$theme original mount is observed without markup mutation',
      () async {
        final entry = _entry(theme);
        final source = BreakpointShowcaseSsrSource.forEntry(entry)!;
        var calls = 0;
        await renderComponentBodyHtml(
          coui.CoUIWeb(theme: .coui, child: _Capture(entry, source)),
          onMountedRoot: (root) {
            final markup =
                (root as RenderObjectElement).renderObject
                    as MarkupRenderObject;
            final before = markup.renderToHtml();
            final receipt = source.observe(root);
            calls++;
            expect(markup.renderToHtml(), before);
            expect(source.observe(root), receipt);
            expect(receipt['completeRawSlotCount'], 1);
            expect((receipt['currentRaw']! as Map)['slotPresence'], [true]);
          },
        );
        expect(calls, 1);
      },
    );
  }
  for (final scenario in ['subclass', 'wrong-key', 'detached']) {
    test('$scenario has no original current source authority', () async {
      final entry = _entry();
      final source = BreakpointShowcaseSsrSource.forEntry(entry)!;
      await expectLater(
        renderComponentBodyHtml(
          coui.CoUIWeb(
            theme: .coui,
            child: _Capture(entry, source, scenario: scenario),
          ),
          onMountedRoot: source.observe,
        ),
        throwsStateError,
      );
    });
  }
  test(
    'same public Stateful Example needs a fresh binding '
    'after parent theme rebuild',
    () async {
      final entry = _entry();
      const registry = BreakpointDefaultExample();
      final capture = div(
        const [registry],
        attributes: {'data-parity-key': entry.key},
      );
      final held = BreakpointShowcaseSsrSource.forEntry(entry)!
        ..recordBuild(registry, capture);
      late void Function(coui.ThemeData) setTheme;
      final binding = _MarkupLifecycleBinding();
      try {
        binding.attachRootComponent(
          _ThemeSwitch(
            capture: capture,
            onReady: (update) => setTheme = update,
          ),
        );
        await pumpEventQueue();
        final root = binding.rootElement!;
        final original = currentSsrIdentityElement(root, registry);
        held.observe(root);
        setTheme(coui.ThemeData.coui.copyWith(textScaling: 1.25));
        await pumpEventQueue();
        expect(currentSsrIdentityElement(root, registry), same(original));
        expect(() => held.observe(root), throwsStateError);
        final fresh = BreakpointShowcaseSsrSource.forEntry(entry)!
          ..recordBuild(registry, capture);
        expect(fresh.observe(root)['entryKey'], entry.key);
      } finally {
        binding.detachRootComponent();
        await pumpEventQueue();
      }
    },
  );
}

class _ThemeSwitch extends StatefulComponent {
  const _ThemeSwitch({required this.capture, required this.onReady});
  final div capture;
  final void Function(void Function(coui.ThemeData)) onReady;
  @override
  State<_ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<_ThemeSwitch> {
  coui.ThemeData _theme = coui.ThemeData.coui;
  @override
  void initState() {
    super.initState();
    component.onReady((data) => setState(() => _theme = data));
  }

  @override
  Component build(BuildContext context) =>
      coui.Theme(data: _theme, child: component.capture);
}

class _MarkupLifecycleBinding extends TestComponentsBinding {
  _MarkupLifecycleBinding() : super('/breakpoint-source-unit', true);
  @override
  RootMarkupRenderObject createRootRenderObject() => RootMarkupRenderObject();
}
