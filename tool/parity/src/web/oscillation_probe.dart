/// Rests the pointer on a hover-opened trigger of the hydrated docs site
/// and counts what the panel does while nothing moves (#4204).
///
/// The defect this exists for: a hover-opened menu opened and closed
/// several times a second under a pointer that never moved. Nothing in CI
/// could see it — the browser tools only ever read a page, and the parity
/// harness renders a document with no event handlers and every animation
/// frozen, which removes exactly the two things such a loop needs.
///
/// The probe runs in two stages, and the first is not a formality:
///
/// 1. **The panel opens.** The pointer moves onto the trigger and the
///    panel has to appear. This is the hydration gate — jaspr emits no
///    "hydrated" signal, and a page whose handlers never attached would
///    otherwise pass stage 2 by having nothing happen at all. Here it
///    fails instead.
/// 2. **Nothing else happens.** With the pointer held still, a
///    `MutationObserver` records every change of the panel's presence and
///    of the trigger's `aria-expanded` for [_kHoldDuration]. Any
///    change fails.
///
/// What is asserted is the symptom — a state change with no input — never
/// the mechanism of the defect that prompted the probe. The next loop of
/// this kind will come from somewhere else (a leaking timer, a positioner
/// re-entering, a gap in the hover region), and counting catches all of
/// them.
///
/// Nothing here reads a pixel: presence and attributes are the same
/// answer on any rasteriser, so a hosted Linux runner and a macOS machine
/// agree.
library;

import 'dart:convert';

import 'package:puppeteer/puppeteer.dart' as pptr;

import 'docs_page.dart';
import 'pointer_dispatch.dart';

/// How long the pointer rests on the trigger while transitions are counted.
/// The defect this probe was written for cycled roughly three times a
/// second, so this window would have seen it about nine times.
const _kHoldDuration = Duration(seconds: 3);

/// How long stage 1 keeps trying to open the panel — the island may still
/// be hydrating when the page has loaded.
const _kOpenTimeout = Duration(seconds: 30);

/// How long one hover waits for the panel before the pointer is parked
/// and the hover retried. Longer than any open delay a hover menu has.
const _kOpenAttemptWait = Duration(seconds: 2);

/// Interval between presence checks while waiting for the panel.
const _kPollInterval = Duration(milliseconds: 50);

/// The self-test's rest window — the looping fixture changes state every
/// 150ms, so one second sees it several times over.
const _kSelfTestHold = Duration(seconds: 1);

/// The self-test's open window — the fixtures have nothing to hydrate, so
/// only the handler-less one ever waits it out.
const _kSelfTestOpenTimeout = Duration(seconds: 5);

/// A hover-opened trigger, the page it lives on, and how to find its panel.
class OscillationProbeSpec {
  /// Creates an [OscillationProbeSpec].
  const OscillationProbeSpec({
    required this.component,
    required this.triggerSelector,
    required this.panelSelector,
    this.variant = 'default',
  });

  /// docs_site component slug — the page is `/components/<component>/`.
  final String component;

  /// Which LivePreview on the page, by variant — the Web pane is
  /// `#web-<component>-<variant>`.
  final String variant;

  /// CSS selector, inside the Web pane, of the trigger the pointer rests
  /// on. Its `aria-expanded` is watched alongside the panel.
  final String triggerSelector;

  /// CSS selector, inside the Web pane, of the panel the trigger opens. A
  /// portaled panel is still inside the pane: every `CoUIWeb` root mounts
  /// its own overlay layers, so the lookup never reaches another preview.
  final String panelSelector;

  /// The Web pane's id on the docs page.
  String get paneId => 'web-$component-$variant';

  /// [triggerSelector], scoped to the pane.
  String get scopedTriggerSelector => '#$paneId $triggerSelector';
}

/// The hover-opened panels the nightly probe rests on.
///
/// One entry today — the menu whose oscillation the probe was written
/// for. Another component joins once this one has run stably on the
/// nightly runner.
const kOscillationProbeSpecs = <OscillationProbeSpec>[
  OscillationProbeSpec(
    component: 'navigation-menu',
    // The first trigger that owns a panel — link triggers carry no
    // `aria-expanded`, so this lands on "Products".
    triggerSelector: 'button[aria-expanded]',
    panelSelector: '[id^="co-navigation-menu-panel-"]',
  ),
];

/// One state change seen while the pointer rested.
class OscillationChange {
  /// Creates an [OscillationChange].
  const OscillationChange({
    required this.atMs,
    required this.subject,
    required this.value,
  });

  /// Parses the page-side JSON.
  factory OscillationChange.fromJson(Map<String, Object?> json) =>
      OscillationChange(
        atMs: (json['atMs']! as num).toInt(),
        subject: json['subject']! as String,
        value: json['value']! as String,
      );

  /// Milliseconds after the count started.
  final int atMs;

  /// What changed — `panel` or `aria-expanded`.
  final String subject;

  /// The new state — `present` / `absent` for the panel, the attribute
  /// value for `aria-expanded`.
  final String value;

  @override
  String toString() => '$subject→$value @${atMs}ms';
}

/// What one run saw.
class OscillationObservation {
  /// Creates an [OscillationObservation].
  const OscillationObservation({
    required this.opened,
    this.openAttempts = 0,
    this.changes = const [],
    this.panelPresentAtEnd = false,
    this.problem,
  });

  /// Whether stage 1 saw the panel appear.
  final bool opened;

  /// Hovers it took to open the panel (or tried, when it never opened).
  final int openAttempts;

  /// Every change recorded while the pointer rested, in order.
  final List<OscillationChange> changes;

  /// Whether the panel was still mounted when the count ended.
  final bool panelPresentAtEnd;

  /// A structural defect found before anything could be measured (no pane,
  /// no trigger with an area to rest on).
  final String? problem;
}

/// The verdict for [observation]: one line per failure, empty when the
/// panel opened and then held still for [hold].
///
/// Pure, so the VM suite can hold the verdict to the cases that matter —
/// above all that a run in which **nothing happened** is a failure, not a
/// pass.
List<String> oscillationFailures(
  OscillationObservation observation, {
  Duration hold = _kHoldDuration,
}) {
  final problem = observation.problem;
  if (problem != null) return [problem];
  if (!observation.opened) {
    const unopened =
        'resting the pointer on the trigger never opened the panel — the '
        'island did not hydrate or its pointer handlers are not attached, '
        'so stage 2 measured nothing';
    return ['stage 1: $unopened (${observation.openAttempts} hovers)'];
  }
  final failures = <String>[];
  final changes = observation.changes;
  if (changes.isNotEmpty) {
    failures.add(
      'stage 2: ${changes.length} state changes while the pointer rested '
      'still for ${hold.inMilliseconds}ms — ${changes.join(', ')}',
    );
  } else if (!observation.panelPresentAtEnd) {
    // Unreachable with a working observer — a panel that left must have
    // been recorded leaving. Reported rather than assumed.
    failures.add(
      'stage 2: the panel was gone after ${hold.inMilliseconds}ms but no '
      'change was recorded — the observer missed it',
    );
  }

  return failures;
}

/// The outcome of one spec.
class OscillationProbeResult {
  /// Creates an [OscillationProbeResult].
  const OscillationProbeResult({
    required this.spec,
    required this.observation,
    required this.failures,
  });

  /// The spec played.
  final OscillationProbeSpec spec;

  /// What the run saw.
  final OscillationObservation observation;

  /// [oscillationFailures] of [observation].
  final List<String> failures;

  /// Whether the panel opened once and then held still.
  bool get passed => failures.isEmpty;
}

/// Opens `/components/<component>/` under [baseUrl] in [page] and runs
/// [spec] against it.
Future<OscillationProbeResult> runOscillationProbe(
  pptr.Page page, {
  required Uri baseUrl,
  required OscillationProbeSpec spec,
  Duration hold = _kHoldDuration,
  Duration openTimeout = _kOpenTimeout,
}) async {
  await loadDocsComponentPage(
    page,
    baseUrl: baseUrl,
    component: spec.component,
  );

  return await runOscillationProbeOnLoadedPage(
    page,
    spec: spec,
    hold: hold,
    openTimeout: openTimeout,
  );
}

/// Runs [spec] against whatever [page] has loaded — the docs page, or a
/// self-test fixture.
Future<OscillationProbeResult> runOscillationProbeOnLoadedPage(
  pptr.Page page, {
  required OscillationProbeSpec spec,
  Duration hold = _kHoldDuration,
  Duration openTimeout = _kOpenTimeout,
}) async {
  await page.bringToFront();
  final observation = await _observe(page, spec, hold, openTimeout);

  return OscillationProbeResult(
    spec: spec,
    observation: observation,
    failures: oscillationFailures(observation, hold: hold),
  );
}

Future<OscillationObservation> _observe(
  pptr.Page page,
  OscillationProbeSpec spec,
  Duration hold,
  Duration openTimeout,
) async {
  // Stage 1 — open it. Park, hover, wait; again until the deadline. A
  // fresh hover each time, because an island that hydrates while the
  // pointer is already resting on the trigger never sees a `mouseenter`.
  final deadline = DateTime.now().add(openTimeout);
  var attempts = 0;
  var opened = false;
  while (!opened && DateTime.now().isBefore(deadline)) {
    await parkPointer(page);
    final landed = await hoverElement(page, spec.scopedTriggerSelector);
    attempts++;
    if (!landed) {
      final paneFound = await page.evaluate<bool>(
        '(id) => !!document.getElementById(id)',
        args: [spec.paneId],
      );
      if (!paneFound) {
        return OscillationObservation(
          opened: false,
          openAttempts: attempts,
          problem: 'no `#${spec.paneId}` on /components/${spec.component}/',
        );
      }
      // The pane is there but the trigger is not laid out yet — keep
      // waiting rather than failing on a page still settling.
      await Future<void>.delayed(_kPollInterval);
      continue;
    }
    final waitUntil = DateTime.now().add(_kOpenAttemptWait);
    while (DateTime.now().isBefore(waitUntil)) {
      if (await _panelPresent(page, spec)) {
        opened = true;
        break;
      }
      await Future<void>.delayed(_kPollInterval);
    }
  }
  if (!opened) {
    final triggerFound = await page.evaluate<bool>(
      '(sel) => !!document.querySelector(sel)',
      args: [spec.scopedTriggerSelector],
    );
    return OscillationObservation(
      opened: false,
      openAttempts: attempts,
      problem: triggerFound
          ? null
          : 'no `${spec.triggerSelector}` with an area in `#${spec.paneId}`',
    );
  }

  // Stage 2 — the pointer stays exactly where stage 1 left it.
  await page.evaluate<void>(
    '''
(paneId, triggerSelector, panelSelector) => {
  const pane = document.getElementById(paneId);
  const trigger = pane.querySelector(triggerSelector);
  const panelPresent = () => !!pane.querySelector(panelSelector);
  const start = performance.now();
  const state = {
    panel: panelPresent(),
    expanded: trigger ? trigger.getAttribute('aria-expanded') : null,
    changes: [],
  };
  const at = () => Math.round(performance.now() - start);
  // One read per batch: a portal re-creates its node on every render, and
  // a remove + re-add inside one batch is a re-render, not a close.
  state.observer = new MutationObserver(() => {
    const panel = panelPresent();
    if (panel !== state.panel) {
      state.panel = panel;
      state.changes.push({
        atMs: at(), subject: 'panel', value: panel ? 'present' : 'absent'});
    }
    const expanded = trigger ? trigger.getAttribute('aria-expanded') : null;
    if (expanded !== state.expanded) {
      state.expanded = expanded;
      state.changes.push({
        atMs: at(), subject: 'aria-expanded', value: String(expanded)});
    }
  });
  state.observer.observe(pane, {
    childList: true, subtree: true,
    attributes: true, attributeFilter: ['aria-expanded'],
  });
  window.__couiOscillationProbe = state;
}''',
    args: [spec.paneId, spec.triggerSelector, spec.panelSelector],
  );
  await Future<void>.delayed(hold);
  final json = await page.evaluate<String>(
    '''
() => {
  const state = window.__couiOscillationProbe;
  state.observer.disconnect();
  return JSON.stringify({changes: state.changes, panel: state.panel});
}''',
  );
  final result = jsonDecode(json) as Map<String, Object?>;

  return OscillationObservation(
    opened: true,
    openAttempts: attempts,
    changes: [
      for (final change in result['changes']! as List<Object?>)
        OscillationChange.fromJson(change! as Map<String, Object?>),
    ],
    panelPresentAtEnd: result['panel']! as bool,
  );
}

Future<bool> _panelPresent(pptr.Page page, OscillationProbeSpec spec) =>
    page.evaluate<bool>(
      '(paneId, sel) => { const pane = document.getElementById(paneId); '
      'return !!pane && !!pane.querySelector(sel); }',
      args: [spec.paneId, spec.panelSelector],
    );

/// How a self-test fixture behaves under a resting pointer.
enum OscillationFixture {
  /// Opens on hover and stays open — the probe must pass.
  steady,

  /// Opens on hover, then keeps closing and reopening by itself — the
  /// probe must fail stage 2.
  oscillating,

  /// Has no handlers at all, like an island that never hydrated — the
  /// probe must fail stage 1, not pass stage 2 by default.
  inert,
}

/// The spec the self-test fixtures are built for.
const kOscillationFixtureSpec = OscillationProbeSpec(
  component: 'fixture',
  triggerSelector: 'button[aria-expanded]',
  panelSelector: '[id^="fixture-panel"]',
);

/// A page that answers to [kOscillationFixtureSpec] and behaves as
/// [fixture] says.
///
/// The oscillating fixture loops on a timer once opened rather than
/// reproducing any particular mechanism — what it proves is that the
/// counter sees a loop, and the probe must catch loops whatever drives
/// them.
String oscillationFixtureHtml(OscillationFixture fixture) {
  final script = switch (fixture) {
    .inert => '',
    .steady || .oscillating =>
      '''
<script>
  const pane = document.getElementById('${kOscillationFixtureSpec.paneId}');
  const trigger = pane.querySelector('button');
  let panel = null;
  const open = () => {
    if (panel) return;
    panel = document.createElement('div');
    panel.id = 'fixture-panel';
    panel.textContent = 'panel';
    pane.appendChild(panel);
    trigger.setAttribute('aria-expanded', 'true');
  };
  const close = () => {
    if (!panel) return;
    panel.remove();
    panel = null;
    trigger.setAttribute('aria-expanded', 'false');
  };
  trigger.addEventListener('mouseenter', () => {
    open();
    ${fixture == OscillationFixture.oscillating ? '''
    if (!window.loop) {
      window.loop = setInterval(() => (panel ? close() : open()), 150);
    }''' : ''}
  });
</script>''',
  };

  return '''
<!doctype html>
<html><body style="margin:0">
<div id="${kOscillationFixtureSpec.paneId}" style="padding:200px">
  <button aria-expanded="false" style="width:120px;height:40px">Open</button>
</div>
$script
</body></html>''';
}

/// Plays the probe against every [OscillationFixture] and returns one line
/// per fixture whose verdict is not the one it exists to produce — empty
/// when the detector is alive.
///
/// A quiet probe reads the same whether the menu held still or the
/// observer never ran; this is the run that tells them apart.
Future<List<String>> oscillationSelfTestFailures(
  pptr.Browser browser, {
  Duration hold = _kSelfTestHold,
  Duration openTimeout = _kSelfTestOpenTimeout,
}) async {
  final failures = <String>[];
  for (final fixture in OscillationFixture.values) {
    final page = await browser.newPage();
    try {
      await page.setContent(oscillationFixtureHtml(fixture));
      final result = await runOscillationProbeOnLoadedPage(
        page,
        spec: kOscillationFixtureSpec,
        hold: hold,
        openTimeout: openTimeout,
      );
      final observation = result.observation;
      final ok = switch (fixture) {
        .steady => result.passed,
        .oscillating => observation.opened && observation.changes.isNotEmpty,
        .inert => !observation.opened && observation.problem == null,
      };
      if (!ok) {
        failures.add(
          '${fixture.name}: expected the probe to '
          '${fixture == OscillationFixture.steady ? 'pass' : 'fail'}, got '
          '${result.passed ? 'a pass' : result.failures.join('; ')}',
        );
      }
    } finally {
      await page.close();
    }
  }

  return failures;
}
