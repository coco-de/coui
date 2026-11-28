import 'dart:convert';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/chat/chat_accent_example.dart';
import 'package:docs_core/previews/examples/web/chat/chat_error_example.dart';
import 'package:docs_core/previews/examples/web/chat/chat_info_example.dart';
import 'package:docs_core/previews/examples/web/chat/chat_neutral_example.dart';
import 'package:docs_core/previews/examples/web/chat/chat_primary_example.dart';
import 'package:docs_core/previews/examples/web/chat/chat_secondary_example.dart';
import 'package:docs_core/previews/examples/web/chat/chat_success_example.dart';
import 'package:docs_core/previews/examples/web/chat/chat_warning_example.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show Styles, div;
import 'package:jaspr/server.dart';

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

const kDocsChatSingleBubbleSsrKind =
    'canonical-ssr-documentation-chat-bubble-v1';
const _kNamespace = 'http://www.w3.org/1999/xhtml';
const _kSvgNamespace = 'http://www.w3.org/2000/svg';
final _formatter = RegExp(r'^[\t\n\f\r ]*$');

const _kVariants = <String, coui.CoreChatBubbleVariant>{
  'neutral': coui.CoreChatBubbleVariant.neutral,
  'primary': coui.CoreChatBubbleVariant.primary,
  'secondary': coui.CoreChatBubbleVariant.secondary,
  'accent': coui.CoreChatBubbleVariant.accent,
  'info': coui.CoreChatBubbleVariant.info,
  'success': coui.CoreChatBubbleVariant.success,
  'warning': coui.CoreChatBubbleVariant.warning,
  'error': coui.CoreChatBubbleVariant.error,
};
const _kExamples = <String, Type>{
  'neutral': ChatNeutralExample,
  'primary': ChatPrimaryExample,
  'secondary': ChatSecondaryExample,
  'accent': ChatAccentExample,
  'info': ChatInfoExample,
  'success': ChatSuccessExample,
  'warning': ChatWarningExample,
  'error': ChatErrorExample,
};

// Pinned immutable public token-name catalogs. No token read/resolve callback
// is invoked. These names constrain declaration channels, never padding values.
const kDocsChatBodyTypographyRoleClasses = <String>{
  'text-display-large',
  'text-display-medium',
  'text-display-small',
  'text-headline-large',
  'text-headline-medium',
  'text-headline-small',
  'text-title-large',
  'text-title-medium',
  'text-title-small',
  'text-body-large',
  'text-body-medium',
  'text-body-small',
  'text-body-xs',
  'text-label-xl2',
  'text-label-xl',
  'text-label-large',
  'text-label-medium',
  'text-label-small',
  'text-label-xs',
  'text-code-xs',
  'text-code-sm',
  'text-code-md',
};
const kDocsChatBodyColorTokenNames = <String>{
  'surface',
  'surface-dim',
  'surface-bright',
  'surface-container-lowest',
  'surface-container-low',
  'surface-container',
  'surface-container-high',
  'surface-container-highest',
  'on-surface',
  'on-surface-variant',
  'placeholder',
  'link',
  'on-surface-subtle',
  'surface-raised',
  'surface-tint',
  'primary',
  'on-primary',
  'primary-container',
  'on-primary-container',
  'primary-fixed',
  'primary-fixed-dim',
  'on-primary-fixed',
  'on-primary-fixed-variant',
  'primary-text',
  'primary-text-large',
  'secondary',
  'on-secondary',
  'secondary-container',
  'on-secondary-container',
  'secondary-fixed',
  'secondary-fixed-dim',
  'on-secondary-fixed',
  'on-secondary-fixed-variant',
  'tertiary',
  'on-tertiary',
  'tertiary-container',
  'on-tertiary-container',
  'tertiary-fixed',
  'tertiary-fixed-dim',
  'on-tertiary-fixed',
  'on-tertiary-fixed-variant',
  'accent',
  'on-accent',
  'error',
  'on-error',
  'error-container',
  'on-error-container',
  'error-strong',
  'focus-ring',
  'primary-hover',
  'primary-pressed',
  'secondary-hover',
  'secondary-pressed',
  'error-pressed',
  'success',
  'on-success',
  'success-container',
  'on-success-container',
  'warning',
  'on-warning',
  'warning-container',
  'on-warning-container',
  'info',
  'on-info',
  'info-container',
  'on-info-container',
  'error-icon',
  'success-icon',
  'warning-icon',
  'info-icon',
  'outline',
  'outline-variant',
  'outline-subtle',
  'inverse-surface',
  'inverse-on-surface',
  'inverse-primary',
  'shadow',
  'surface-highlight',
  'scrim',
  'disabled-content',
  'disabled-container',
  'disabled-outline',
  'syntax-keyword',
  'syntax-type',
  'syntax-function',
  'syntax-string',
  'category-red',
  'on-category-red',
  'category-red-container',
  'on-category-red-container',
  'category-red-outline',
  'category-orange',
  'on-category-orange',
  'category-orange-container',
  'on-category-orange-container',
  'category-orange-outline',
  'category-yellow',
  'on-category-yellow',
  'category-yellow-container',
  'on-category-yellow-container',
  'category-yellow-outline',
  'category-green',
  'on-category-green',
  'category-green-container',
  'on-category-green-container',
  'category-green-outline',
  'category-blue',
  'on-category-blue',
  'category-blue-container',
  'on-category-blue-container',
  'category-blue-outline',
  'category-purple',
  'on-category-purple',
  'category-purple-container',
  'on-category-purple-container',
  'category-purple-outline',
  'category-pink',
  'on-category-pink',
  'category-pink-container',
  'on-category-pink-container',
  'category-pink-outline',
  'category-brown',
  'on-category-brown',
  'category-brown-container',
  'on-category-brown-container',
  'category-brown-outline',
  'category-gray',
  'on-category-gray',
  'category-gray-container',
  'on-category-gray-container',
  'category-gray-outline',
};

// This property-name union covers only the pinned normal bubble builder,
// typography inline emitter and surface-fill emitter. Other channels are
// unproved. Values remain original declarations, never padding/owner evidence.
const _kBodyStyleKeys = {
  'padding',
  'border-radius',
  'color',
  'max-width',
  'background-color',
  'font-size',
  'font-weight',
  'line-height',
  '--coui-leading',
  'letter-spacing',
  'font-family',
  '--coui-surface-rgb',
  '--coui-surface-alpha',
};

/// Passive exact16 source recorder. Shared dispatch/publication is separate.
/// Neither this class nor its observer calls a registry/build/style resolver.
class DocsChatSingleBubbleSsrSource implements CurrentSsrBoxSource {
  DocsChatSingleBubbleSsrSource._(this.entry);

  static DocsChatSingleBubbleSsrSource? forEntry(MatrixEntry entry) {
    const expected = BoxObservationSourceSpec.docsChatSingleBubble;
    final claims = entry.probes.any(
      (p) =>
          p.boxObservationSource?.logicalUnitId == expected.logicalUnitId ||
          p.boxObservationSource?.nativeAdapterId == expected.nativeAdapterId ||
          p.boxObservationSource?.webAdapterId == expected.webAdapterId,
    );
    if (!claims) return null;
    if (entry.component != 'chat' ||
        !_kVariants.containsKey(entry.variant) ||
        !const {'light', 'dark'}.contains(entry.theme.name) ||
        entry.surfaceStyle.name != 'defaultStyle' ||
        entry.probes.length != 1 ||
        entry.probes.single.role != 'root' ||
        entry.probes.single.boxObservationSource != expected ||
        entry.key != 'chat-${entry.variant}-${entry.theme.name}-defaultStyle') {
      throw _changed('exact predeclared16 and tuple, not arbitrary Chat');
    }
    return DocsChatSingleBubbleSsrSource._(entry);
  }

  final MatrixEntry entry;
  Component? _result;
  div? _capture;
  Element? _root;
  _Read? _live;
  bool _completed = false;

  @override
  void recordBuild(Component result, div capture) {
    if (_result != null ||
        result.runtimeType != _kExamples[entry.variant] ||
        capture.children.length != 1 ||
        !identical(capture.children.single, result)) {
      throw _changed('one exact original Example and capture declaration');
    }
    _result = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    if (_live != null) throw _changed('one actual normal mount');
    final before = _read(root);
    final after = _read(root);
    _sameRead(before, after);
    _root = root;
    _live = before;
    return const {'docsChatAwaitingActualNormalBody': true};
  }

  Map<String, Object?> completeWithSerializedBody(String actualBody) {
    final live = _live;
    final root = _root;
    if (live == null || root == null || _completed) {
      throw _changed('one actual normal completion');
    }
    _sameRead(live, _read(root));
    final parsed = html.parseFragment(actualBody);
    final captures = parsed
        .querySelectorAll('[data-parity-key]')
        .where((e) => e.attributes['data-parity-key'] == entry.key);
    if (captures.length != 1) throw _changed('unique actual response capture');
    final raw = Map<String, Object?>.of(live.raw);
    raw['capture'] = _complete(
      captures.single,
      raw['capture']! as Map<String, Object?>,
      raw['opaqueFrontiers']! as List<Map<String, Object?>>,
    );
    _completed = true;
    return {
      'kind': kDocsChatSingleBubbleSsrKind,
      'entryKey': entry.key,
      'source': BoxObservationSourceSpec.docsChatSingleBubble.toJson(),
      'currentRaw': raw,
    };
  }

  _Read _read(Element root) {
    final result = _result;
    final capture = _capture;
    if (result == null || capture == null) {
      throw _changed('recorded normal build');
    }
    final held = <Object?>[result, capture];
    final frontiers = <Map<String, Object?>>[];
    final reader = _Reader(held, frontiers);
    final cap = reader.owned(_captureElement(root, capture), 'div');
    if (capture.attributes?['data-parity-key'] != entry.key ||
        cap.children.length != 1) {
      throw _changed('original keyed capture');
    }
    final example = cap.children.single;
    if (example.runtimeType != StatelessElement ||
        !identical(example.component, result) ||
        example.component.runtimeType != _kExamples[entry.variant]) {
      throw _changed('normal exact original Example Element');
    }
    final chatElement = _sole(example);
    if (chatElement.runtimeType != StatelessElement ||
        chatElement.component.runtimeType != coui.Chat) {
      throw _changed('normal exact public Chat factory');
    }
    final chat = chatElement.component as coui.Chat;
    if (chat.alignment != coui.CoreChatAlignment.start ||
        chat.avatar != null ||
        chat.header != null ||
        chat.footer != null ||
        chat.chatStyle != null) {
      throw _changed('original single no-slot Chat');
    }
    _originalUiInputs(chat);
    final row = reader.owned(_sole(chatElement), 'div');
    _plain(row, 'flex w-full justify-start');
    if (row.children.length != 1) throw _changed('whole one-column row');
    final column = reader.owned(row.children.single, 'div');
    _plain(column, 'flex flex-col w-full items-start min-w-0');
    if (column.children.length != 1) throw _changed('whole one-scope column');
    final scopeElement = column.children.single;
    if (scopeElement.runtimeType != InheritedElement ||
        scopeElement.component.runtimeType != coui.ChatAlignmentScope) {
      throw _changed('normal public alignment scope');
    }
    final scope = scopeElement.component as coui.ChatAlignmentScope;
    if (scope.alignment != chat.alignment ||
        !identical(scope.child, chat.bubble)) {
      throw _changed('original public scope forwards actual bubble');
    }
    final bubbleElement = _sole(scopeElement);
    if (bubbleElement.runtimeType != StatelessElement ||
        !identical(bubbleElement.component, chat.bubble) ||
        bubbleElement.component.runtimeType != coui.ChatBubble) {
      throw _changed('normal exact supplied ChatBubble');
    }
    final bubble = bubbleElement.component as coui.ChatBubble;
    if (bubble.variant != _kVariants[entry.variant] ||
        bubble.alignment != null ||
        bubble.tail != null ||
        bubble.chatBubbleStyle != null) {
      throw _changed('original explicit variant and raw nullable inputs');
    }
    _originalUiInputs(bubble);
    final themePadding = _themePadding(bubbleElement, bubble.variant!, held);
    final body = reader.owned(_sole(bubbleElement), 'div');
    final bodyInput = body.element.component as div;
    if (bodyInput.id != null ||
        bodyInput.attributes != null ||
        bodyInput.events != null ||
        body.children.length != 1 ||
        !identical(body.children.single.component, bubble.child)) {
      throw _changed('original direct no-tail body and opaque child');
    }
    if (!_bodyClassChannels(bodyInput.classes)) {
      throw _changed('unproved normal body class channels');
    }
    final styles = bodyInput.styles?.properties;
    if (styles == null ||
        !styles.keys.every(_kBodyStyleKeys.contains) ||
        !const {
          'padding',
          'border-radius',
          'color',
          'max-width',
        }.every(styles.containsKey)) {
      throw _changed('complete original body style channels');
    }
    held.addAll([
      example,
      chatElement,
      chat,
      chat.bubble,
      scopeElement,
      scope,
      scope.child,
      bubbleElement,
      bubble,
      bubble.child,
    ]);
    final bodyTree = reader.tree(body, [
      reader.opaque(body, 0, 'bubble-child'),
    ]);
    final columnTree = reader.tree(column, [bodyTree]);
    return _Read(held, {
      'kind': 'current-documentation-chat-bubble-raw-v1',
      'variant': entry.variant,
      'quantityBoundary': 'own-bubble-body-only',
      'opaqueInteriorsRead': false,
      'rawParameters': {
        'chatAlignment': 'start',
        'bubbleVariant': entry.variant,
        'bubbleAlignment': null,
        'bubbleTail': null,
        'instanceStyle': null,
        'instanceCss': null,
        'scopeAlignment': 'start',
        'scopeChildIsOriginalBubble': true,
        'themePadding': themePadding,
      },
      'bodyDeclaration': {
        'class': bodyInput.classes,
        'styles': Map<String, String>.of(styles),
      },
      'opaqueFrontiers': frontiers,
      'capture': reader.tree(cap, [
        reader.tree(row, [columnTree]),
      ]),
    });
  }
}

// Exact channel order of buildBubbleClassName: fixed layout pair, optional
// emitTypography role (+ optional token color), optional emitColor background,
// and the complete content-surface pair. Unknown channels stay unproved.
bool _bodyClassChannels(String? value) {
  if (value == null) return false;
  final tokens = value.split(' ');
  if (tokens.length < 2 ||
      tokens[0] != 'inline-block' ||
      tokens[1] != 'relative') {
    return false;
  }
  var at = 2;
  final role =
      at < tokens.length &&
      kDocsChatBodyTypographyRoleClasses.contains(tokens[at]);
  if (role) at++;
  if (role && at < tokens.length && _bodyColorChannel(tokens[at], 'text-')) {
    at++;
  }
  if (at < tokens.length && _bodyColorChannel(tokens[at], 'bg-')) at++;
  if (at < tokens.length && tokens[at] == coui.kWebSurfaceMarker) {
    if (at + 1 >= tokens.length ||
        tokens[at + 1] != coui.kWebSurfaceRoleContent) {
      return false;
    }
    at += 2;
  }
  return at == tokens.length;
}

bool _bodyColorChannel(String value, String prefix) {
  if (!value.startsWith(prefix)) return false;
  final parts = value.substring(prefix.length).split('/');
  if (parts.isEmpty || !kDocsChatBodyColorTokenNames.contains(parts.first)) {
    return false;
  }
  if (parts.length == 1) return true;
  if (parts.length != 2) return false;
  final alpha = parts[1];
  // Only the documented 0..1 opacity channel's canonical integer 0..99
  // spelling. No alpha/color conversion or semantic value comparison.
  return alpha.isNotEmpty &&
      alpha.length <= 2 &&
      (alpha == '0' || alpha[0] != '0') &&
      alpha.codeUnits.every((c) => c >= 48 && c <= 57);
}

void _sameRead(_Read a, _Read b) {
  if (!_identicalList(a.held, b.held) ||
      jsonEncode(a.raw) != jsonEncode(b.raw)) {
    throw _changed('same actual source, relevant parameters and normal roster');
  }
}

void _originalUiInputs(coui.UiComponent input) {
  // Never call componentAttributes/events/rootClasses: these are computed
  // forwarding methods, including a virtual configureAttributes callback.
  // UiComponent's pinned constructor substitutes this exact canonical const
  // map. Any custom map is unproved before keys/length/entries/[] are touched.
  if (!identical(
    input.eventHandlers,
    const <String, List<coui.UiEventHandler>>{},
  )) {
    throw _changed(
      'unproved event-handler Map provenance; no collection lookup',
    );
  }
  if (input.id != null ||
      input.classes != null ||
      input.css != null ||
      input.userAttributes != null ||
      input.onChange != null ||
      input.onClick != null ||
      input.onInput != null ||
      input.onKeyDown != null ||
      input.onKeyUp != null ||
      input.onMouseEnter != null ||
      input.onMouseLeave != null) {
    throw _changed('original public raw UiComponent forwarding inputs');
  }
}

Map<String, Object?> _themePadding(
  Element bubble,
  coui.CoreChatBubbleVariant variant,
  List<Object?> held,
) {
  // Public ancestor/field reads only. No Theme.of/maybeOf dependency call,
  // style resolver, raw-value conversion or private State inspection.
  var current = bubble.parent;
  while (current != null) {
    held.add(current);
    if (current.component is coui.Theme) {
      if (current.runtimeType != InheritedElement ||
          current.component.runtimeType != coui.Theme) {
        throw _changed('unproved nearest public Theme factory');
      }
      final theme = current.component as coui.Theme;
      final data = theme.data;
      if (data.runtimeType != coui.ThemeData) {
        throw _changed('unproved public ThemeData fields');
      }
      final components = data.coreComponentTheme;
      if (components != null &&
          components.runtimeType != coui.CoreComponentTheme) {
        throw _changed('unproved raw component-theme field owner');
      }
      final bubbleTheme = components?.chatBubble;
      if (bubbleTheme != null &&
          bubbleTheme.runtimeType != coui.CoreChatBubbleTheme) {
        throw _changed('unproved raw bubble-theme field owner');
      }
      final base = bubbleTheme?.style;
      final variants = bubbleTheme?.variantStyles;
      // A custom Map can run user code in []/containsKey. The closed canonical
      // tool Theme has no variant override map. Until its normal source origin
      // is authenticated, a non-null map is explicitly unproved, never read or
      // collapsed to null. This observer does not replay that lookup.
      if (variants != null) {
        throw _changed('unproved selected variant Map provenance; no lookup');
      }
      if (base != null && base.runtimeType != coui.CoreChatBubbleStyle) {
        throw _changed('unproved selected public base padding field owner');
      }
      final basePadding = base?.padding;
      if (basePadding != null &&
          basePadding.runtimeType != coui.CoreEdgeInsets) {
        throw _changed('unproved immutable raw padding parameter');
      }
      // Actual scope/field-chain refs and padding/null facts only. No whole
      // style/map identity or unrelated aliases are a padding premise.
      held.addAll([
        current.component,
        data,
        components,
        bubbleTheme,
        base != null,
        basePadding,
      ]);
      return {
        'themeElement': identityHashCode(current),
        'themeData': identityHashCode(data),
        'componentThemePresent': components != null,
        'bubbleThemePresent': bubbleTheme != null,
        'baseStylePresent': base != null,
        'basePadding': basePadding == null
            ? null
            : identityHashCode(basePadding),
        'variantMapPresent': false,
        'selectedEntryPresent': false,
        'selectedStylePresent': false,
        'selectedPadding': null,
      };
    }
    current = current.parent;
  }
  throw _changed('unproved: no authentic nearest public Theme');
}

void _plain(_Owned node, String classes) {
  final input = node.element.component as div;
  if (input.classes != classes ||
      input.id != null ||
      input.styles != null ||
      input.attributes != null ||
      input.events != null) {
    throw _changed('exact generated row/column declaration');
  }
}

class _Read {
  _Read(this.held, this.raw);
  final List<Object?> held;
  final Map<String, Object?> raw;
}

typedef _Declaration = ({
  String tag,
  String? id,
  String? classes,
  Styles? styles,
  Map<String, String>? attributes,
  Map<String, EventCallback>? events,
  List<Component> children,
});
_Declaration _declaration(Component input) {
  if (input.runtimeType != div) throw _changed('closed owned div factory');
  final d = input as div;
  return (
    tag: 'div',
    id: d.id,
    classes: d.classes,
    styles: d.styles,
    attributes: d.attributes,
    events: d.events,
    children: d.children,
  );
}

class _Owned {
  _Owned(this.element, this.dom, this.render, this.children, this.attributes);
  final Element element;
  final Element dom;
  final MarkupRenderElement render;
  final List<Element> children;
  final Map<String, String> attributes;
}

class _Reader {
  _Reader(this.held, this.frontiers);
  final List<Object?> held;
  final List<Map<String, Object?>> frontiers;
  final Set<MarkupRenderObject> _used = Set.identity();

  _Owned owned(Element element, String tag) {
    final input = _declaration(element.component);
    if (element.runtimeType != StatelessElement || input.tag != tag) {
      throw _changed('normal public typed $tag element');
    }
    final dom = _sole(element);
    if (dom.runtimeType != DomElement ||
        dom.component.runtimeType != DomComponent ||
        dom is! RenderObjectElement ||
        dom.renderObject is! MarkupRenderElement) {
      throw _changed('normal public DomComponent/DomElement factory');
    }
    final declaration = dom.component as DomComponent;
    final render = dom.renderObject as MarkupRenderElement;
    if (declaration.tag != tag ||
        declaration.id != input.id ||
        declaration.classes != input.classes ||
        !identical(declaration.styles, input.styles) ||
        !_mapEquals(declaration.attributes, input.attributes) ||
        !_mapEquals(declaration.events, input.events) ||
        !identical(declaration.children, input.children) ||
        render.tag != tag ||
        render.id != input.id ||
        render.classes != input.classes ||
        !_mapEquals(render.attributes, input.attributes) ||
        !_mapEquals(render.styles, input.styles?.properties)) {
      throw _changed('complete public $tag forwarding');
    }
    final children = _ordered(dom, input.children);
    final renderChildren = render.children.toList();
    final targets = [for (final child in children) child.slot.target];
    if (renderChildren.length != targets.length ||
        targets.indexed.any(
          (e) =>
              e.$2 == null ||
              !identical(e.$2!.renderObject, renderChildren[e.$1]) ||
              !identical(renderChildren[e.$1].parent, render),
        )) {
      throw _changed(
        'public slot targets cover the whole immediate render roster',
      );
    }
    // Keep stable parameter objects and copied property values.
    // Styles.properties
    // may allocate a new map, so its getter result is not an alias requirement.
    held
      ..addAll([
        element,
        element.component,
        dom,
        declaration,
        render,
        input.styles,
        input.children,
        ...input.children,
        ...children,
        declaration.attributes,
        declaration.events,
        render.attributes,
        ...targets,
        ...renderChildren,
        for (final child in children) child.slot,
        for (final e
            in declaration.events?.entries ??
                <MapEntry<String, EventCallback>>[]) ...[e.key, e.value],
      ])
      ..add(input.attributes);
    if (!identical(input.attributes, declaration.attributes) ||
        !identical(input.events, declaration.events)) {
      throw _changed('raw own div map forwarding');
    }
    final attributes = <String, String>{
      if (render.id != null) 'id': render.id!,
      if (render.classes?.isNotEmpty == true) 'class': render.classes!,
      if (render.styles?.isNotEmpty == true)
        'style': render.styles!.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('; '),
      ...?render.attributes,
    };
    return _Owned(element, dom, render, children, attributes);
  }

  Map<String, Object?> opaque(_Owned parent, int ordinal, String purpose) {
    final child = parent.children[ordinal];
    final target = child.slot.target;
    if (target == null || target.renderObject is! MarkupRenderObject) {
      throw _changed('actual public opaque slot target');
    }
    held.addAll([
      child,
      child.component,
      child.slot,
      target,
      target.renderObject,
    ]);
    // The public normal slot target supplies the first render object without
    // visiting any opaque Element children. Only transparent render fragments
    // are flattened; element attributes/text/interiors are never read.
    final roots = <MarkupRenderObject>[];
    void flatten(MarkupRenderObject render) {
      if (render is MarkupRenderFragment) {
        held.add(render);
        render.children.forEach(flatten);
      } else {
        roots.add(render);
      }
    }

    flatten(target.renderObject as MarkupRenderObject);
    final nodes = <Map<String, Object?>>[];
    for (final render in roots) {
      if (!_used.add(render)) throw _changed('disjoint supplied render roots');
      held.add(render);
      nodes.add(switch (render) {
        MarkupRenderElement(:final tag) => {
          'nodeType': 1,
          // Every opaque root here is inserted under a verified owned HTML
          // element. The pinned normal HTML parser enters SVG only for this
          // public root tag; no opaque attribute or descendant is inspected.
          'namespaceURI': tag == 'svg' ? _kSvgNamespace : _kNamespace,
          'localName': tag,
        },
        MarkupRenderText(rawHtml: false) => {'nodeType': 3},
        _ => throw _changed('unambiguous opaque top-level node kind'),
      });
    }
    final index = frontiers.length;
    frontiers.add({'index': index, 'purpose': purpose, 'nodes': nodes});
    return {'opaqueFrontier': index};
  }

  Map<String, Object?> tree(_Owned node, List<Map<String, Object?>> children) =>
      {
        'nodeType': 1,
        'namespaceURI': _kNamespace,
        'localName': node.render.tag,
        'attributes': node.attributes,
        'children': children,
      };
}

Element _captureElement(Element root, Component capture) {
  final matches = <Element>[];
  void visit(Element element) {
    if (identical(element.component, capture)) {
      matches.add(element);
      return; // All opaque bubble content is below this boundary.
    }
    element.visitChildren(visit);
  }

  visit(root);
  if (matches.length != 1) throw _changed('unique actual capture occurrence');
  return matches.single;
}

List<Element> _children(Element element) {
  final out = <Element>[];
  element.visitChildren(out.add);
  return out;
}

Element _sole(Element element) {
  final children = _children(element);
  if (children.length != 1) throw _changed('one normal generated edge');
  return children.single;
}

List<Element> _ordered(Element element, List<Component> inputs) {
  final children = _children(element);
  if (children.length != inputs.length ||
      (Set<Element>.identity()..addAll(children)).length != children.length ||
      children.indexed.any(
        (e) =>
            !identical(e.$2.parent, element) ||
            !identical(e.$2.component, inputs[e.$1]),
      )) {
    throw _changed('complete ordered original child roster');
  }
  return children;
}

bool _identicalList(List<Object?> a, List<Object?> b) =>
    a.length == b.length && a.indexed.every((e) => identical(e.$2, b[e.$1]));
bool _mapEquals(Map<Object?, Object?>? a, Map<Object?, Object?>? b) =>
    a == null || b == null
    ? a == null && b == null
    : a.length == b.length &&
          a.keys.every((k) => b.containsKey(k) && a[k] == b[k]);
StateError _changed(String reason) =>
    StateError('DOCS_CHAT_SOURCE_CHANGED: $reason');

Map<String, Object?> _shape(html_dom.Node node) => node is html_dom.Element
    ? {
        'nodeType': 1,
        'namespaceURI': node.namespaceUri,
        'localName': node.localName,
      }
    : {'nodeType': node.nodeType};
Map<String, Object?> _complete(
  html_dom.Element actual,
  Map<String, Object?> expected,
  List<Map<String, Object?>> frontiers,
) {
  final attributes = <String, String>{
    for (final a in actual.attributes.entries) a.key.toString(): a.value,
  };
  if (actual.localName != expected['localName'] ||
      actual.namespaceUri != expected['namespaceURI'] ||
      !_mapEquals(attributes, expected['attributes']! as Map)) {
    throw _changed('exact actual normal own element');
  }
  var at = 0;
  final children = <Map<String, Object?>>[];
  void formatting() {
    while (at < actual.nodes.length &&
        actual.nodes[at] is html_dom.Text &&
        _formatter.hasMatch((actual.nodes[at] as html_dom.Text).data)) {
      children.add({'ownedText': (actual.nodes[at++] as html_dom.Text).data});
    }
  }

  for (final raw in expected['children']! as List) {
    final child = raw as Map<String, Object?>;
    if (child['opaqueFrontier'] case final int i) {
      final nodes = frontiers[i]['nodes']! as List<Map<String, Object?>>;
      for (final (j, shape) in nodes.indexed) {
        if (shape['nodeType'] != 3) formatting();
        if (at == actual.nodes.length ||
            !_mapEquals(_shape(actual.nodes[at]), shape)) {
          throw _changed('complete actual normal opaque frontier');
        }
        children.add({'opaqueNode': i, 'frontierNode': j});
        at++;
      }
    } else {
      formatting();
      if (at == actual.nodes.length || actual.nodes[at] is! html_dom.Element) {
        throw _changed('missing actual normal own child');
      }
      children.add(
        _complete(actual.nodes[at++] as html_dom.Element, child, frontiers),
      );
    }
  }
  formatting();
  if (at != actual.nodes.length) {
    throw _changed('extra actual normal own child');
  }
  return {...expected, 'children': children};
}
