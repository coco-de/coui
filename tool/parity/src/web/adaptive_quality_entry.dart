/// Client fixture for the adaptive-quality probe: the shipped `CoUIWeb` with
/// `adaptiveQuality` stated from page script, over a few glass surfaces, so a
/// real Chrome can show what the governor does to a real page.
///
/// Nothing in this file re-implements the feature. The feed that listens for
/// motion and asks for frames, the sampler that judges them, the governor
/// behind it, the attribute `CoUIWeb` writes on the document, the stylesheet
/// rules that attribute switches and the refraction host that adds and takes
/// away the bend are all the shipped ones; the page only states the terms and
/// reports what it saw. The surfaces carry the library's own marker classes,
/// so the stylesheet and the host reach them the way they reach a card.
///
/// Page API (all on `window`; `couiQualityOptions` is read once, when the
/// script runs, so a test states it in the page it loads):
///
///   couiQualityOptions      a JSON object: `stated` (the terms —
///                           `forced`, `initial`, `lowest`, `allowStepUp`,
///                           `targetFrameRate` and a `tuning` object of the
///                           numbers to override, or null to state nothing)
///                           and `surfaces` (how many glass surfaces to draw)
///   couiQualityState(json)  states other terms (a JSON `stated` object), or
///                           none when given null
///   couiQualityChanges()    a JSON array of every change `onQualityChanged`
///                           heard, in order
///   couiQualityTier()       the tier `AdaptiveQualityScope` publishes, as the
///                           last build of a subtree below it saw it
///   couiQualityHold()       opens a hold through the scope; returns how many
///                           are open
///   couiQualityRelease()    releases the most recent one
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiQualityOptions')
external JSString? get _options;
@JS('couiQualityState')
external set _state(JSFunction value);
@JS('couiQualityChanges')
external set _changes(JSFunction value);
@JS('couiQualityTier')
external set _tier(JSFunction value);
@JS('couiQualityHold')
external set _hold(JSFunction value);
@JS('couiQualityRelease')
external set _release(JSFunction value);

void main() => client.runApp(const _Root());

/// The terms an object of page script states, or none.
CoreAdaptiveQuality? _parse(
  Object? value,
  void Function(CoreQualityChange change) onChanged,
) {
  if (value is! Map<String, Object?>) return null;

  CoreQualityTier? tier(Object? name) =>
      name == null ? null : CoreQualityTier.values.byName(name as String);
  final tuning = (value['tuning'] as Map<String, Object?>?) ?? const {};
  double seconds(String key, double fallback) =>
      (tuning[key] as num?)?.toDouble() ?? fallback;
  int count(String key, int fallback) =>
      (tuning[key] as num?)?.toInt() ?? fallback;

  return CoreAdaptiveQuality(
    forced: tier(value['forced']),
    initialQuality: tier(value['initial']),
    lowest: tier(value['lowest']),
    allowStepUp: value['allowStepUp'] != false,
    targetFrameRate: (value['targetFrameRate'] as num?)?.toDouble(),
    tuning: CoreQualityTuning(
      skipSeconds: seconds('skipSeconds', CoreQualityTuning.defaultSkipSeconds),
      warmupSeconds: seconds(
        'warmupSeconds',
        CoreQualityTuning.defaultWarmupSeconds,
      ),
      windowSeconds: seconds(
        'windowSeconds',
        CoreQualityTuning.defaultWindowSeconds,
      ),
      cooldownSeconds: seconds(
        'cooldownSeconds',
        CoreQualityTuning.defaultCooldownSeconds,
      ),
      settleSeconds: seconds(
        'settleSeconds',
        CoreQualityTuning.defaultSettleSeconds,
      ),
      sampleGraceSeconds: seconds(
        'sampleGraceSeconds',
        CoreQualityTuning.defaultSampleGraceSeconds,
      ),
      degradeWindows: count(
        'degradeWindows',
        CoreQualityTuning.defaultDegradeWindows,
      ),
      recoverWindows: count(
        'recoverWindows',
        CoreQualityTuning.defaultRecoverWindows,
      ),
      probationWindows: count(
        'probationWindows',
        CoreQualityTuning.defaultProbationWindows,
      ),
      maxBackoffDoublings: count(
        'maxBackoffDoublings',
        CoreQualityTuning.defaultMaxBackoffDoublings,
      ),
    ),
    onQualityChanged: onChanged,
  );
}

class _Root extends StatefulComponent {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  final List<Map<String, Object?>> _heard = [];
  final List<CoreQualityHold> _holds = [];
  CoreAdaptiveQuality? _stated;
  int _surfaces = 4;
  CoreQualityTier _seen = CoreQualityTier.defaultTier;
  BuildContext? _below;

  void _handleRecord(CoreQualityChange change) => _heard.add({
    'from': change.from.name,
    'to': change.to.name,
    'reason': change.reason.name,
    'percentileMs': change.percentileMillis,
    'frames': change.framesMeasured,
    'budgetMs': change.budgetMillis,
  });

  @override
  void initState() {
    super.initState();
    final raw = _options?.toDart;
    final options = raw == null
        ? const <String, Object?>{}
        : jsonDecode(raw) as Map<String, Object?>;
    _surfaces = (options['surfaces'] as num?)?.toInt() ?? _surfaces;
    _stated = _parse(options['stated'], _handleRecord);

    _state = ((JSString? json) {
      final stated = json == null
          ? null
          : _parse(jsonDecode(json.toDart), _handleRecord);
      setState(() => _stated = stated);
    }).toJS;
    _changes = (() => jsonEncode(_heard).toJS).toJS;
    _tier = (() => _seen.name.toJS).toJS;
    _hold = (() {
      final below = _below;
      if (below != null) {
        _holds.add(AdaptiveQualityScope.holdMeasurement(below));
      }

      return _holds.length;
    }).toJS;
    _release = (() {
      if (_holds.isNotEmpty) _holds.removeLast().release();

      return _holds.length;
    }).toJS;
  }

  @override
  Component build(BuildContext context) => CoUIWeb(
    theme: .coui,
    adaptiveQuality: _stated,
    child: _Surfaces(
      count: _surfaces,
      onBuilt: (context, tier) {
        _below = context;
        _seen = tier;
      },
    ),
  );
}

/// Glass surfaces over a striped background, so a blur has something to
/// sample, and a reader of the scope to record what it was told.
class _Surfaces extends StatelessComponent {
  const _Surfaces({required this.count, required this.onBuilt});

  final int count;
  final void Function(BuildContext context, CoreQualityTier tier) onBuilt;

  @override
  Component build(BuildContext context) {
    onBuilt(context, AdaptiveQualityScope.of(context));

    return div([
      const div(
        [],
        id: 'bg',
        styles: Styles(
          raw: {
            'position': 'fixed',
            'inset': '0',
            'background':
                'repeating-linear-gradient(90deg, #000 0 12px, #fff 12px 24px)',
          },
        ),
      ),
      for (var i = 0; i < count; i++)
        div(
          const [],
          id: 's$i',
          classes: '$kWebSurfaceMarker $kWebSurfaceRoleFunctional',
          styles: Styles(
            raw: {
              'position': 'fixed',
              'left': '${20 + (i % 4) * 100}px',
              'top': '${20 + (i ~/ 4) * 80}px',
              'width': '90px',
              'height': '60px',
              'border-radius': '16px',
              // The fill every component publishes from the token it chose;
              // without it `background-color` is invalid.
              '--coui-surface-rgb': 'var(--coui-surface)',
            },
          ),
        ),
    ]);
  }
}
