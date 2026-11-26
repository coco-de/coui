import 'dart:io';

import 'package:test/test.dart';

/// Automates `cross-platform/api.md` §"파라미터 이름은 완전 동일" (verify.md
/// §7-8): the Flutter and Web `{component}.dart` constructors for the same
/// component must expose an identical `this.X`/`super.X` parameter NAME set
/// (types may differ — e.g. `FocusNode?` vs `CoreFocusNode?` — but the name
/// itself must match so call-site code reads the same on both platforms).
///
/// This walks every `{category}/{name}/{name}.dart` primary widget file under
/// both `coui_flutter` and `coui_web`, extracts the unnamed constructor's
/// parameter names, and diffs the two sets per component.

const _flutterComponentsRoot = '../packages/coui_flutter/lib/src/components';
const _webComponentsRoot = '../packages/coui_web/lib/src/components';

/// Identity parameters that are each platform's own idiom (Flutter `key` /
/// Web `id`) — explicitly exempted from name-matching by
/// `cross-platform/api.md` ("key/id 위치는 force-match 대상이 아닌 예외").
const _identityParams = {'key', 'id'};

/// Web-only DOM passthrough surface with no Flutter constructor-parameter
/// equivalent (Flutter has no named ctor param for "extra CSS classes" or
/// "raw HTML attributes" — that capability doesn't exist as a widget-level
/// slot on Flutter's side). See `cross-platform/api.md` framework-infra
/// exception and `web/web-specifics.md` passthrough surfaces.
///
/// The 8 DOM-event names below (`onChange`/`onClick`/.../`eventHandlers`)
/// come from `UiComponent`/`UiStatefulComponent`'s own constructor (verified
/// by reading `packages/coui_web/lib/src/base/ui_component.dart` and
/// `ui_stateful_component.dart`) — every Web component that extends either
/// base class forwards them via `super.X`, regardless of whether the
/// component itself was designed around them. Flutter has no equivalent
/// "any raw DOM event" passthrough on its base `Widget`/`StatefulWidget` —
/// each Flutter component defines its own specific callback names instead
/// (`onPressed`, `onChanged`, ...), so this is Web base-class infra, not a
/// per-component API surface, and is exempted the same way `classes`/`css`
/// are.
/// `tag` (verified in `packages/coui_web/lib/src/base/ui_component.dart` and
/// re-forwarded via `super.tag` by e.g. `progress.dart`/`stat.dart`/
/// `timeline.dart`) lets a Web component pick its rendered HTML tag
/// (`div`/`span`/...) — a DOM-only concept with no Flutter analogue (a
/// Flutter widget doesn't "render as a tag").
const _webOnlyStructuralParams = {
  'classes',
  'css',
  'attributes',
  'eventHandlers',
  'onChange',
  'onClick',
  'onInput',
  'onKeyDown',
  'onKeyUp',
  'onMouseEnter',
  'onMouseLeave',
  'tag',
};

/// Flutter-only framework-infrastructure parameter names explicitly
/// enumerated by `cross-platform/api.md`'s "framework-infra(메커니즘)는
/// 시그니처 대칭 제외" section as legitimate because Web already provides the
/// same *capability* through a browser-native mechanism (DOM focus/scroll,
/// native `<input>`/contenteditable editing, CSS cursor) rather than an
/// identically-named constructor parameter.
///
/// Deliberately NOT included here (per that same rule's explicit warning):
/// `inputFormatters`, `onTapOutside`/`onTapUpOutside`, `showCursor`,
/// `clearButtonSemanticLabel` — the rule calls these out BY NAME as
/// WEB-MISSING (real gaps to implement), not legitimate exceptions, even
/// though they look similar in kind. Leaving them out means they surface as
/// real test failures / `_knownMismatches` entries below instead of being
/// silently swallowed.
const _flutterOnlyFrameworkInfraParams = {
  'focusNode',
  'statesController',
  'controller',
  'scrollController',
  'scrollPhysics',
  'magnifierConfiguration',
  'contextMenuBuilder',
  'spellCheckConfiguration',
  'selectionControls',
  'selectionHeightStyle',
  'selectionWidthStyle',
  'maxLengthEnforcement',
  'undoController',
  'keyboardAppearance',
  'dragStartBehavior',
  'restorationId',
  'contentInsertionConfiguration',
  'clipBehavior',
  // `Clickable.semanticsEnabled` — Flutter merges a descendant
  // `Semantics(enabled: true)` over an ancestor `enabled: false`, so the
  // disabled announcement has to be stated on the widget itself. The Web
  // twin states it through its `attributes` passthrough (`aria-disabled`),
  // the DOM's own mechanism — same capability, no named parameter.
  'semanticsEnabled',
};

/// Directories under `lib/src/components/` that hold a Flutter-interop
/// helper / formatter / context-resolver utility rather than a rendered
/// widget with a named-parameter constructor — verified by reading each
/// file: `form/image_properties` is pure `extension`s on a platform-neutral
/// `coui_core` data model (no widget class at all), `form/formatter` is
/// `InputFormatter`/`TextInputFormatters` (extends `TextInputFormatter`, not
/// a widget), `layout/breakpoint` is `Breakpoint(this.context)` — a single
/// *positional* constructor arg, not the named-param widget pattern this
/// test parses. None of these are part of the cross-platform named-
/// properties API surface this test guards.
const _nonWidgetUtilityComponents = {
  'form/image_properties',
  'form/formatter',
  'layout/breakpoint',
};

/// Maps `category/name` → primary widget file, for one platform root.
Map<String, File> _collectPrimaryFiles(String root) {
  final result = <String, File>{};
  final rootDir = Directory(root);
  if (!rootDir.existsSync()) return result;

  for (final categoryDir in rootDir.listSync().whereType<Directory>()) {
    final category = categoryDir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    for (final componentDir in categoryDir.listSync().whereType<Directory>()) {
      final name = componentDir.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final key = '$category/$name';
      if (_nonWidgetUtilityComponents.contains(key)) continue;
      final file = File('${componentDir.path}/$name.dart');
      if (file.existsSync()) {
        result[key] = file;
      }
    }
  }
  return result;
}

/// First public (non-underscore) top-level class name declared in [source] —
/// the unified widget class (private helper classes like
/// `_CardInteractiveWrapper` are declared later in the same file and skipped).
String? _primaryClassName(String source) {
  final regex = RegExp(
    r'class\s+([A-Z][A-Za-z0-9_]*)\s*(?:<[^{]*>)?\s*(?:extends|implements|with|\{)',
  );
  for (final match in regex.allMatches(source)) {
    final name = match.group(1)!;
    if (!name.startsWith('_')) return name;
  }
  return null;
}

/// Splits a `{ ... }` constructor parameter block into its individual
/// comma-separated parameter segments, respecting nesting depth of
/// `()`/`<>`/`[]`/`{}` — a plain top-level `.split(',')` breaks on generic
/// types (`List<Component>? children`) and function-type params
/// (`void Function(bool)? onFocus`), both of which contain internal commas
/// or parens that aren't parameter separators.
List<String> _splitTopLevelParams(String paramBlock) {
  final segments = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < paramBlock.length; i++) {
    final c = paramBlock[i];
    if ('([{<'.contains(c)) depth++;
    if (')]}>'.contains(c)) depth--;
    if (c == ',' && depth == 0) {
      segments.add(paramBlock.substring(start, i));
      start = i + 1;
    }
  }
  final tail = paramBlock.substring(start).trim();
  if (tail.isNotEmpty) segments.add(tail);
  return segments;
}

/// Extracts the parameter NAME from a single constructor-parameter segment,
/// covering both syntaxes this codebase uses:
///   - shorthand `this.x` / `super.x` (name = the identifier after the dot)
///   - a plain typed param assigned via initializer list, e.g. Web `Card`'s
///     `Component? child` (paired with `: _child = child` — used so the
///     public getter can wrap a private backing field). Here the name is the
///     LAST bare identifier before the (optional) default value, since Dart
///     parameter syntax is always `[required] Type name [= default]`.
/// Returns null for a blank/comment-only segment.
String? _paramName(String rawSegment) {
  var segment = rawSegment.trim();
  if (segment.isEmpty) return null;

  // Drop a top-level ` = default` (depth-aware so a default value containing
  // its own `=` inside brackets, e.g. `= CoreX.defaultY(a: 1)`, isn't cut
  // mid-expression — only a depth-0 `=` ends the type/name and starts the
  // default).
  var depth = 0;
  for (var i = 0; i < segment.length; i++) {
    final c = segment[i];
    if ('([{<'.contains(c)) depth++;
    if (')]}>'.contains(c)) depth--;
    if (c == '=' &&
        depth == 0 &&
        (i == 0 || segment[i - 1] != '=') &&
        (i + 1 >= segment.length || segment[i + 1] != '=' && segment[i + 1] != '>')) {
      segment = segment.substring(0, i);
      break;
    }
  }
  segment = segment.trim();
  if (segment.isEmpty) return null;

  final thisOrSuper = RegExp(
    r'(?:this|super)\.([a-zA-Z_][a-zA-Z0-9_]*)\s*$',
  ).firstMatch(segment);
  if (thisOrSuper != null) return thisOrSuper.group(1);

  segment = segment.replaceFirst(RegExp(r'^required\s+'), '');
  final trailingIdentifier = RegExp(
    r'([a-zA-Z_][a-zA-Z0-9_]*)\s*$',
  ).firstMatch(segment);
  return trailingIdentifier?.group(1);
}

/// Extracts every parameter name from the first unnamed, brace-delimited
/// (`{ ... }`, i.e. all-named-params) constructor of [className] in
/// [source]. Returns null if no such constructor is found (e.g. a purely
/// positional constructor — none observed in this codebase's unified
/// components, but handled defensively).
List<String>? _constructorParamNames(String source, String className) {
  // `(?:const\s+)?ClassName(` immediately followed by whitespace* then `{`
  // is a constructor DECLARATION (Dart's named-parameter-block syntax);
  // a call site (`return ClassName(x: y)`) never has `{` right after `(`,
  // and a named constructor (`ClassName.icon(`) never matches `ClassName(`
  // directly (the `.` breaks the match) — both are naturally excluded.
  final ctorRegex = RegExp('(?:const\\s+)?${RegExp.escape(className)}\\s*\\(');

  for (final match in ctorRegex.allMatches(source)) {
    var i = match.end;
    while (i < source.length && source[i].trim().isEmpty) {
      i++;
    }
    if (i >= source.length || source[i] != '{') continue;

    var depth = 1;
    final start = i + 1;
    var j = start;
    while (j < source.length && depth > 0) {
      if (source[j] == '{') depth++;
      if (source[j] == '}') depth--;
      j++;
    }
    final paramBlock = source.substring(start, j - 1);
    final names = _splitTopLevelParams(
      paramBlock,
    ).map(_paramName).whereType<String>().toList();
    if (names.isNotEmpty) return names;
  }
  return null;
}

/// Components without a same-name-and-category twin on the other platform —
/// tracked separately from parameter-parity mismatches (that's the
/// "single-platform component = 미구현" gap owned by
/// `core/style-contract.md`'s naming rules, not a signature drift).
Set<String> _onlyIn(Map<String, Set<String>> a, Map<String, Set<String>> b) =>
    a.keys.toSet().difference(b.keys.toSet());

/// Known, currently-existing parameter-name mismatches — populated from an
/// actual audit run of this test (2026-07-20), NOT guessed. Each entry
/// names the component, which side has the extra/differently-named param,
/// and why. New net-new mismatches NOT listed here fail the test — this is
/// a regression ratchet against the *current* state, not a blanket
/// allowlist, and NOT every entry below is a "legitimate, by-design"
/// exception — several are honestly-tracked, unresolved gaps against
/// `cross-platform/api.md` that should eventually be fixed. Distinguishing
/// which is which is noted per entry.
///
/// Format: `'category/name': {webOnly: {...}, flutterOnly: {...}}`.
const Map<String, ({Set<String> webOnly, Set<String> flutterOnly})> _knownMismatches = {
  // ── Rule-justified exceptions (verified against a specific rule) ──
  //
  // `core/style-contract.md`: "WEB-EXTRA(예: card children — Web 만) 제거는
  // destructive 이므로 보류" — this is the exact case the rule names. Web
  // additionally accepts a `List<Component>? children` for fully-custom
  // layouts alongside the Flutter-parity `child` slot (which already
  // matches and so isn't in this diff).
  'layout/card': (webOnly: {'children'}, flutterOnly: {}),

  // `widget/interaction.md`: "CSS cursor 로 그 capability 를 native 제공" —
  // Web's Clickable-equivalent expresses hover cursor via CSS `cursor-*`
  // classes (part of chrome/Style), not a `mouseCursor` constructor param;
  // Flutter's `MouseCursor` type has no browser-native equivalent object.
  //
  // `semanticsButton` is the Flutter side of a capability Web already has,
  // through a parameter that is itself Web-only. A composing component that
  // is a more specific control (checkbox, switch, tab) must be announced as
  // that control rather than as a button. Web reaches it by letting caller
  // `attributes` override the default `role="button"` — `attributes` is in
  // `_webOnlyStructuralParams` above, so the two are the same capability
  // seen from each platform's mechanism. Flutter has no attribute map, so
  // its override is this flag.
  //
  // Giving Web a `semanticsButton` bool as well would be worse, not better:
  // a control would then have two ways to decide its role, with no defined
  // precedence, and the bool could only say "not a button" — never what the
  // control actually is, which is the part a screen reader needs.
  //
  // `onPressedChange` exists so a Flutter consumer (`Button`'s
  // press-squash shadow) can imperatively swap `BoxDecoration` on press,
  // because Flutter has no ambient "currently pressed" query the way CSS
  // `:active` is queryable purely via a selector. Web's `Clickable`
  // deliberately keeps press visuals browser-native — its own doc comment
  // states "Press / focus VISUALS are browser-native (`:active` /
  // `:focus-visible`) — no Dart state, no re-render" — and Web's `Button`
  // already renders the identical press-squash effect through a scoped
  // `:active` rule (`kControlShadowPressMarker` in `button_style.dart`),
  // with no callback involved. Adding a Dart `onPressedChange` callback to
  // Web's `Clickable` would not close a capability gap, it would reintroduce
  // the Dart-driven re-render `widget/interaction.md` calls out as the Web
  // anti-pattern for hover/press state.
  //
  // `engageOnHover` (#4404, S3) opts a Flutter `Clickable` instance into
  // reading hover as an additional trigger for the `pressedTranslate` /
  // `pressedBoxShadow` shift-and-fade pair, alongside press. Flutter needs
  // a Dart-side flag because that pair is per-instance Dart state with no
  // ambient "hovered or pressed" query, and only Button/Chip's cast-motion
  // styles want the pair to react to hover at all — every other Clickable
  // consumer (checkbox, toggle, ...) must not gain a new hover-triggered
  // shift just because one control opted in. Web reaches the identical
  // pairing with a single global CSS rule keyed on `:hover, :active` —
  // no per-component Dart flag, and no way for a component to opt out
  // short of not carrying the cast marker at all — so it has no
  // constructor-parameter equivalent to expose.
  'infra/clickable': (
    webOnly: {},
    flutterOnly: {
      'mouseCursor',
      'semanticsButton',
      'onPressedChange',
      'engageOnHover',
    },
  ),

  // Self-documenting Flutter-only bridge params (literally prefixed
  // `flutter*` in the source) for `ScrollableDetails`/ambient
  // `PrimaryScrollController` — Flutter-specific scroll-view wiring
  // mechanisms with no DOM concept to name identically on Web.
  'layout/scrollable_client': (
    webOnly: {},
    flutterOnly: {'flutterVerticalDetails', 'flutterHorizontalDetails', 'primary'},
  ),

  // `core/design-tokens.md` HTML `name` attribute (form field identity,
  // Web-only DOM concept, analogous to the already-exempted `id`) vs
  // Flutter-only `direction` (layout axis) — tracked as two independent,
  // one-sided gaps rather than a false "cancel-out" pair.
  'form/star_rating': (webOnly: {'name'}, flutterOnly: {'direction'}),

  // ── Honestly-tracked, UNRESOLVED gaps (not blessed as correct) ──
  //
  // `text_field`/`text_area`: most of this list mirrors Flutter's native
  // `EditableText` surface 1:1. Some names ARE legitimate framework-infra
  // (native `<input>`/contenteditable already covers the capability) but
  // several — `inputFormatters`, `onTap`, `onTapOutside`, `showCursor` —
  // are explicitly called out by `cross-platform/api.md` as WEB-MISSING
  // (real gaps), not exceptions. This entry is a snapshot of the current
  // (incomplete) state, tracked here so NEW drift beyond it still fails —
  // it is not a claim that the gap is acceptable.
  'form/text_field': (
    webOnly: {},
    flutterOnly: {
      'obscuringCharacter',
      'enableSuggestions',
      'enableInteractiveSelection',
      'enableIMEPersonalizedLearning',
      'stylusHandwritingEnabled',
      'cursorOpacityAnimates',
      'strutStyle',
      'skipInputFeatureFocusTraversal',
      'groupId',
    },
  ),
  'form/text_area': (
    webOnly: {'cols'},
    flutterOnly: {
      'obscureText',
      'obscuringCharacter',
      'autocorrect',
      'enableSuggestions',
      'enableInteractiveSelection',
      'enableIMEPersonalizedLearning',
      'stylusHandwritingEnabled',
      'onHeightChanged',
      'onWidthChanged',
      'showCursor',
      'cursorOpacityAnimates',
      'textDirection',
      'keyboardType',
      'textInputAction',
      'textCapitalization',
      'inputFormatters',
      'onEditingComplete',
      'onTap',
      'onTapOutside',
      'autofillHints',
    },
  ),

  // `form/radio_group`: Flutter supports an uncontrolled-mode
  // `initialValue`; Web's `RadioGroup` doesn't yet.
  'form/radio_group': (webOnly: {}, flutterOnly: {'initialValue'}),

  // `form/phone_input`: large two-sided divergence — Web exposes a
  // lower-level `countryCode`/`dialCode`/`number` triple while Flutter
  // exposes a richer higher-level API (`initialCountry`/`filterPlusCode`/
  // `countries`/`phoneInputStyle`/...). Needs a real redesign pass to
  // reconcile, not a one-line fix.
  'form/phone_input': (
    webOnly: {'countryCode', 'dialCode', 'number'},
    flutterOnly: {
      'initialCountry',
      'initialNumber',
      'initialValue',
      'onChanged',
      'filterPlusCode',
      'onlyNumber',
      'placeholder',
      'countries',
      'enabled',
      'phoneInputStyle',
    },
  ),

  // `layout/hidden` / `navigation/switcher`: Flutter-only `curve` (a
  // `Curve` object). `widget/interaction.md` requires equal animation
  // *duration* tokens on Web (already true via CSS transitions) but
  // doesn't mandate an identically-named per-instance easing override —
  // still tracked here as an open question rather than silently accepted.
  'layout/hidden': (webOnly: {}, flutterOnly: {'curve'}),
  'navigation/switcher': (webOnly: {}, flutterOnly: {'curve'}),

  // `layout/scaffold`: Flutter-only `resizeToAvoidBottomInset` (mirrors
  // Flutter's own `Scaffold` keyboard-inset behavior); Web pages reflow
  // for the on-screen keyboard/viewport natively via CSS, so there's
  // currently no equivalent toggle on the Web side.
  'layout/scaffold': (webOnly: {}, flutterOnly: {'resizeToAvoidBottomInset'}),

  // `display/carousel`: large Flutter-only surface — Web's carousel is a
  // materially simpler implementation today. Needs a real feature-parity
  // pass (per `core/style-contract.md`'s default-A "완전 호환" mandate),
  // not a quick fix.
  'display/carousel': (
    webOnly: {},
    flutterOnly: {
      'itemBuilder',
      'transition',
      'alignment',
      'autoplayReverse',
      'autoplaySpeed',
      'curve',
      'direction',
      'disableDraggingVelocity',
      'disableOverheadScrolling',
      'draggable',
      'durationBuilder',
      'reverse',
      'sizeConstraint',
      'speed',
      'waitOnStart',
    },
  ),

  // `overlay/tooltip`: Flutter-only `waitDuration`/`showDuration`/
  // `minDuration` — matches the "Behavior timing config" Resolved category
  // in `web/web-specifics.md`, but that's an internal resolver artifact;
  // whether Web's Tooltip should expose the same three ctor params (vs.
  // fixed internal timings) is an open design question, not yet resolved.
  'overlay/tooltip': (
    webOnly: {},
    flutterOnly: {'waitDuration', 'showDuration', 'minDuration'},
  ),

  // `overlay/dialog`: the two platforms currently implement DIFFERENT
  // levels of API under the same name — Web's `Dialog` is the unified
  // named-properties composition widget (`title`/`content`/`actions`/...),
  // while Flutter's `Dialog` here mirrors the native `showDialog()`/
  // `DialogRoute` surface (`barrierDismissible`/`transitionBuilder`/...).
  // This is a real architecture mismatch needing a dedicated reconciliation
  // pass, not a param rename.
  'overlay/dialog': (
    webOnly: {
      'title',
      'content',
      'leading',
      'trailing',
      'actions',
      'open',
      'onClose',
      'dialogStyle',
    },
    flutterOnly: {
      'anchorPoint',
      'barrierColorFallback',
      'barrierColorBuilder',
      'barrierDismissible',
      'barrierLabel',
      'builder',
      'data',
      'fullScreen',
      'settings',
      'themes',
      'transitionBuilder',
      'transitionDuration',
      'traversalEdgeBehavior',
      'useSafeArea',
    },
  ),
};

void main() {
  late Map<String, Set<String>> flutterParams;
  late Map<String, Set<String>> webParams;
  late Map<String, String> parseErrors;

  setUpAll(() {
    final flutterFiles = _collectPrimaryFiles(_flutterComponentsRoot);
    final webFiles = _collectPrimaryFiles(_webComponentsRoot);
    flutterParams = {};
    webParams = {};
    parseErrors = {};

    for (final entry in flutterFiles.entries) {
      final source = entry.value.readAsStringSync();
      final className = _primaryClassName(source);
      if (className == null) {
        parseErrors['flutter/${entry.key}'] = 'no public class found';
        continue;
      }
      final names = _constructorParamNames(source, className);
      if (names == null) {
        parseErrors['flutter/${entry.key}'] = 'no brace-delimited constructor found for $className';
        continue;
      }
      // Only `_identityParams` is stripped here — the framework-infra /
      // web-structural exemption sets are applied later, at diff time, so
      // a name present on BOTH sides (e.g. Web's `focusNode: CoreFocusNode?`
      // matching Flutter's `focusNode: FocusNode?`) still cancels out via
      // set difference instead of being one-sidedly hidden and creating a
      // phantom mismatch on the other side.
      flutterParams[entry.key] = {...names}..removeAll(_identityParams);
    }

    for (final entry in webFiles.entries) {
      final source = entry.value.readAsStringSync();
      final className = _primaryClassName(source);
      if (className == null) {
        parseErrors['web/${entry.key}'] = 'no public class found';
        continue;
      }
      final names = _constructorParamNames(source, className);
      if (names == null) {
        parseErrors['web/${entry.key}'] = 'no brace-delimited constructor found for $className';
        continue;
      }
      webParams[entry.key] = {...names}..removeAll(_identityParams);
    }
  });

  test('every primary widget file parses to a non-empty parameter set', () {
    expect(
      parseErrors,
      isEmpty,
      reason:
          'Parser could not extract constructor params (fix the parser or '
          'the component):\n${parseErrors.entries.map((e) => '${e.key}: ${e.value}').join('\n')}',
    );
  });

  test(
    'components present on both platforms expose identical parameter names',
    () {
      final shared = flutterParams.keys.toSet().intersection(
        webParams.keys.toSet(),
      );
      final failures = <String>[];

      for (final component in shared) {
        final flutter = flutterParams[component]!;
        final web = webParams[component]!;
        final known = _knownMismatches[component];
        final knownWebOnly = known?.webOnly ?? const {};
        final knownFlutterOnly = known?.flutterOnly ?? const {};

        // Exemption sets are applied only to the asymmetric remainder, so a
        // name present on both sides always cancels out via `difference`
        // first — see the comment in `setUpAll` for why this must be
        // computed here rather than stripped from the raw collected sets.
        final webOnly = web.difference(flutter).difference(_webOnlyStructuralParams).difference(knownWebOnly);
        final flutterOnly = flutter
            .difference(web)
            .difference(_flutterOnlyFrameworkInfraParams)
            .difference(knownFlutterOnly);

        if (webOnly.isNotEmpty || flutterOnly.isNotEmpty) {
          failures.add(
            '$component: webOnly=$webOnly, flutterOnly=$flutterOnly',
          );
        }
      }

      expect(
        failures,
        isEmpty,
        reason:
            'Unexpected constructor parameter-name mismatches '
            '(cross-platform/api.md — names must match even when types '
            'differ). If a mismatch is a deliberate, rule-justified '
            'exception, add it to `_knownMismatches` with a comment citing '
            'the rule:\n${failures.join('\n')}',
      );
    },
  );

  test(
    'reports components that exist on only one platform (not a signature '
    'mismatch — tracked as a naming/creation gap instead)',
    () {
      final flutterOnly = _onlyIn(flutterParams, webParams);
      final webOnly = _onlyIn(webParams, flutterParams);
      // ignore: avoid_print
      print(
        'Flutter-only components (${flutterOnly.length}): '
        '${(flutterOnly.toList()..sort()).join(', ')}\n'
        'Web-only components (${webOnly.length}): '
        '${(webOnly.toList()..sort()).join(', ')}',
      );
      // Informational only — single-platform components are a creation gap
      // (core/style-contract.md: "한쪽에만 있는 컴포넌트 = 미구현"), not a
      // parameter-parity violation, so this test never fails on them.
    },
  );

  test('coverage sanity — both platforms yield a substantial component set', () {
    expect(flutterParams.length, greaterThanOrEqualTo(100));
    expect(webParams.length, greaterThanOrEqualTo(100));
  });
}
