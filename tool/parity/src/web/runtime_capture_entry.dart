/// Real client execution for previews whose final state cannot exist in SSR.
library;

import 'dart:convert';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/internal/preview/web_scene.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:jaspr/client.dart' as client show runApp;

import 'client_stage_callback_source.dart';
import 'client_visual_value_source.dart';
import 'current_client_box_source.dart';

void main() {
  final config = (jsonDecode(Uri.decodeComponent(Uri.base.fragment)) as Map)
      .cast<String, Object?>();
  client.runApp(runtimeCaptureApp(config));
}

/// The exact client harness, also mountable by browser contract tests.
Component runtimeCaptureApp(Map<String, Object?> config) {
  final observer =
      ClientStageCallbackSource.fromConfig(config) ??
      ClientVisualValueSource.fromConfig(config);
  return Component.fragment([
    Style(styles: docsContentTheme().styles),
    CoUIWeb(
      theme: .coui,
      child: observer == null
          ? _CaptureStage(config)
          : _ObservedCaptureStage(config, observer),
    ),
  ]);
}

class _CaptureStage extends StatelessComponent {
  const _CaptureStage(this.config);

  final Map<String, Object?> config;

  @override
  Component build(BuildContext context) {
    return _buildCaptureStage(config, context);
  }
}

class _ObservedCaptureStage extends StatefulComponent {
  const _ObservedCaptureStage(this.config, this.observer);

  final Map<String, Object?> config;
  final CurrentClientBoxSource observer;

  @override
  State<_ObservedCaptureStage> createState() => _ObservedCaptureStageState();
}

class _ObservedCaptureStageState extends State<_ObservedCaptureStage> {
  int _buildGeneration = 0;

  @override
  Component build(BuildContext context) {
    final capture = _buildCaptureStage(component.config, context);
    component.observer.recordBuild(capture.children.single, capture);
    final generation = ++_buildGeneration;
    context.binding.addPostFrameCallback(() {
      if (mounted && generation == _buildGeneration) {
        component.observer.arm(
          context as Element,
          isMounted: () => mounted && generation == _buildGeneration,
        );
      }
    });
    return capture;
  }

  @override
  void didUpdateComponent(covariant _ObservedCaptureStage oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!identical(oldComponent.observer, component.observer)) {
      oldComponent.observer.dispose();
      _buildGeneration++;
    }
  }

  @override
  void dispose() {
    _buildGeneration++;
    component.observer.dispose();
    super.dispose();
  }
}

div _buildCaptureStage(Map<String, Object?> config, BuildContext context) {
  final component = config['component']! as String;
  final variant = config['variant']! as String;
  final scene = config['scene'] == null
      ? null
      : DocsScene.fromJson((config['scene']! as Map).cast());
  if (scene != null && scene.reference != variant) {
    throw StateError('Documentation scene input/reference mismatch');
  }
  return div(
    [
      if (scene != null)
        docsSceneHost(scene, renderWebScene(scene))
      else
        kWebPreviewRegistry[component]!(
          context,
          variant == 'default' ? null : variant,
        ),
    ],
    attributes: {
      'data-parity-key': config['key']! as String,
      if (scene != null) 'data-parity-client-key': config['key']! as String,
    },
    styles: Styles(
      raw: {'display': 'flex', 'width': '${config['width']}px'},
    ),
  );
}
