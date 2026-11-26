/// Internal selection semantics shared by documentation and capture.
library;

import 'dart:convert';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';

enum PreviewSelectionKind { empty, demo, example, props }

class PreviewSelection {
  const PreviewSelection._(this.kind, {this.component, this.name, this.props = const {}, this.label});

  factory PreviewSelection.attributes(Map<String, String> attributes, {Map<String, String> extraProps = const {}}) {
    if (attributes['demo'] case final demo?) {
      return PreviewSelection._(PreviewSelectionKind.demo, name: demo);
    }
    final component = attributes['component'];
    if (component == null) return const PreviewSelection._(PreviewSelectionKind.empty);
    if (attributes['example'] case final example?) {
      return PreviewSelection._(PreviewSelectionKind.example, component: component, name: example);
    }
    return PreviewSelection.properties(component, {
      ...parsePreviewProps(attributes['props']),
      ...extraProps,
    }, attributes['label']);
  }

  factory PreviewSelection.properties(String component, Map<String, String> props, String? label) => PreviewSelection._(
    PreviewSelectionKind.props,
    component: component,
    props: Map.unmodifiable(props),
    label: label,
  );

  factory PreviewSelection.playground(String component, {Map<String, String>? props}) {
    final spec = kDocsPlaygrounds[component];
    if (spec == null) throw StateError('No playground for "$component"');
    return PreviewSelection.properties(component, props ?? spec.initial, spec.label);
  }

  factory PreviewSelection.fromJson(Map<String, Object?> json) => PreviewSelection._(
    PreviewSelectionKind.values.byName(json['kind']! as String),
    component: json['component'] as String?,
    name: json['name'] as String?,
    props: (json['props']! as Map).cast<String, String>(),
    label: json['label'] as String?,
  );

  final PreviewSelectionKind kind;
  final String? component;
  final String? name;
  final Map<String, String> props;
  final String? label;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'component': component,
    'name': name,
    'props': {for (final key in props.keys.toList()..sort()) key: props[key]},
    'label': label,
  };

  String get identity => jsonEncode(toJson());
}
