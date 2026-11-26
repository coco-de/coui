import 'dart:convert';

import 'package:docs_core/previews/flutter_registry.dart'
    show FlutterPreviewBuilder;
import 'package:flutter/widgets.dart';

import 'box_padding_observation.dart';

/// Immutable value-level authority already checked by the source coordinator.
/// This neither reads a private scene object nor verifies files by itself.
class SceneValueAuthority {
  SceneValueAuthority({
    required this.component,
    required this.reference,
    required this.tag,
    required this.documentPath,
    required this.documentSha256,
    required this.sourceClosureSha256,
    required this.manifestSha256,
    required this.sceneValueSha256,
  }) {
    if (component.isEmpty ||
        documentPath.isEmpty ||
        tag != 'Playground' ||
        !RegExp(r'^docs-v2-[0-9a-f]{32}$').hasMatch(reference) ||
        [
          documentSha256,
          sourceClosureSha256,
          manifestSha256,
          sceneValueSha256,
        ].any((value) => !RegExp(r'^[0-9a-f]{64}$').hasMatch(value))) {
      throw const BoxObservationError(
        'INVALID_SCENE_VALUE_AUTHORITY',
        'A frozen Playground value contract with complete hashes is required.',
      );
    }
  }

  factory SceneValueAuthority.fromJson(Map<String, Object?> json) {
    const fields = [
      'component',
      'reference',
      'tag',
      'documentPath',
      'documentSha256',
      'sourceClosureSha256',
      'manifestSha256',
      'sceneValueSha256',
    ];
    if (fields.any((field) => json[field] is! String)) {
      throw const BoxObservationError(
        'INVALID_SCENE_VALUE_AUTHORITY',
        'Missing typed source contract field.',
      );
    }
    return SceneValueAuthority(
      component: json['component']! as String,
      reference: json['reference']! as String,
      tag: json['tag']! as String,
      documentPath: json['documentPath']! as String,
      documentSha256: json['documentSha256']! as String,
      sourceClosureSha256: json['sourceClosureSha256']! as String,
      manifestSha256: json['manifestSha256']! as String,
      sceneValueSha256: json['sceneValueSha256']! as String,
    );
  }

  final String component;
  final String reference;
  final String tag;
  final String documentPath;
  final String documentSha256;
  final String sourceClosureSha256;
  final String manifestSha256;
  final String sceneValueSha256;

  Map<String, String> toJson() => {
    'component': component,
    'reference': reference,
    'tag': tag,
    'documentPath': documentPath,
    'documentSha256': documentSha256,
    'sourceClosureSha256': sourceClosureSha256,
    'manifestSha256': manifestSha256,
    'sceneValueSha256': sceneValueSha256,
  };

  bool sameValue(SceneValueAuthority other) =>
      jsonEncode(toJson()) == jsonEncode(other.toJson());
}

/// Permission for one existing tool call.
/// Only its capturing manager creates it.
class OfficialPreviewToken {
  OfficialPreviewToken._({
    required this.manager,
    required this.entryKey,
    required this.component,
    required this.variant,
    required this.builder,
    required this.authority,
  });

  final OfficialPreviewReceipts manager;
  final String entryKey;
  final String component;
  final String? variant;
  final FlutterPreviewBuilder builder;
  final SceneValueAuthority authority;
  bool _recorded = false;
}

/// A currently mounted result associated with its actual existing keyed Widget.
class ValidatedPreviewReceipt {
  ValidatedPreviewReceipt._({
    required OfficialPreviewReceipts manager,
    required _PreviewRecord record,
    required this.captureRoot,
    required this.registryResultElement,
  }) : _manager = manager,
       _record = record;

  final OfficialPreviewReceipts _manager;
  final _PreviewRecord _record;
  final Element captureRoot;
  final Element registryResultElement;

  Widget get result => _record.result;
  SceneValueAuthority get sceneValueAuthority => _record.token.authority;

  void requireCurrent() {
    _manager._requireHandle(_record.token.component, _record.token.builder);
    if (!captureRoot.mounted ||
        !registryResultElement.mounted ||
        !identical(captureRoot.widget, _record.keyedHandle) ||
        !identical(registryResultElement.widget, _record.result)) {
      throw const BoxObservationError(
        'STALE_PREVIEW_RECEIPT',
        'The receipt no longer describes the current mounted capture child.',
      );
    }
  }
}

class _PreviewRecord {
  const _PreviewRecord(this.token, this.keyedHandle, this.result);
  final OfficialPreviewToken token;
  final KeyedSubtree keyedHandle;
  final Widget result;
}

/// Records operation I/O without invoking, wrapping or replacing any builder.
///
/// The coordinator retains the exact existing `builder(variant)` call between
/// authorize and record. An external caller supplying that call's real return
/// value is an explicit audited tool trust boundary, not cryptographic proof.
class OfficialPreviewReceipts {
  OfficialPreviewReceipts.capture({
    required Map<String, FlutterPreviewBuilder> registry,
    required this.epoch,
  }) : _registry = registry,
       _handles = Map.unmodifiable(registry) {
    if (epoch.isEmpty) {
      throw const BoxObservationError('INVALID_RECEIPT_EPOCH', 'Empty epoch.');
    }
  }

  final String epoch;
  final Map<String, FlutterPreviewBuilder> _registry;
  final Map<String, FlutterPreviewBuilder> _handles;
  final Map<KeyedSubtree, _PreviewRecord> _records = Map.identity();

  void _requireHandle(String component, FlutterPreviewBuilder builder) {
    final official = _handles[component];
    if (official == null ||
        !identical(official, builder) ||
        !identical(_registry[component], official)) {
      throw const BoxObservationError(
        'OFFICIAL_PREVIEW_HANDLE_CHANGED',
        'Only the capture-start official component handle is authorized.',
      );
    }
  }

  OfficialPreviewToken authorize({
    required String entryKey,
    required String component,
    required String? variant,
    required FlutterPreviewBuilder builder,
    required SceneValueAuthority sceneValueAuthority,
  }) {
    _requireHandle(component, builder);
    if (entryKey.isEmpty ||
        sceneValueAuthority.component != component ||
        sceneValueAuthority.reference != variant) {
      throw const BoxObservationError(
        'PREVIEW_RECEIPT_ARGUMENT_MISMATCH',
        'The original operation arguments must match the declared scene.',
      );
    }
    return OfficialPreviewToken._(
      manager: this,
      entryKey: entryKey,
      component: component,
      variant: variant,
      builder: builder,
      authority: sceneValueAuthority,
    );
  }

  void record({
    required OfficialPreviewToken token,
    required KeyedSubtree keyedHandle,
    required Widget result,
  }) {
    if (!identical(token.manager, this) ||
        token._recorded ||
        _records.containsKey(keyedHandle)) {
      throw const BoxObservationError(
        'DUPLICATE_OR_FOREIGN_PREVIEW_RECORD',
        'A token and an existing keyed Widget each identify one operation.',
      );
    }
    _requireHandle(token.component, token.builder);
    if (!identical(keyedHandle.child, result)) {
      throw const BoxObservationError(
        'PREVIEW_RESULT_KEYED_CHILD_MISMATCH',
        'Record the result placed into that actual existing keyed Widget.',
      );
    }
    token._recorded = true;
    _records[keyedHandle] = _PreviewRecord(token, keyedHandle, result);
  }

  ValidatedPreviewReceipt requireMounted({
    required Element captureRoot,
    required String entryKey,
    required String component,
    required String? variant,
    required String epoch,
    required SceneValueAuthority sceneValueAuthority,
  }) {
    final keyed = captureRoot.widget;
    final record = keyed is KeyedSubtree ? _records[keyed] : null;
    if (record == null) {
      throw const BoxObservationError(
        'MISSING_MOUNTED_PREVIEW_RECEIPT',
        'The actual mounted keyed Widget has no operation receipt.',
      );
    }
    final token = record.token;
    _requireHandle(component, token.builder);
    if (this.epoch != epoch ||
        token.entryKey != entryKey ||
        token.component != component ||
        token.variant != variant ||
        !token.authority.sameValue(sceneValueAuthority)) {
      throw const BoxObservationError(
        'PREVIEW_RECEIPT_AUTHORITY_CHANGED',
        'Epoch, original arguments and frozen scene hashes must still match.',
      );
    }
    final children = <Element>[];
    captureRoot.visitChildren(children.add);
    final resultElement = requireOneBoxOwner(children, 'actual keyed result');
    if (!identical(resultElement.widget, record.result)) {
      throw const BoxObservationError(
        'PREVIEW_RESULT_KEYED_CHILD_MISMATCH',
        'The current direct child is not the recorded return object.',
      );
    }
    return ValidatedPreviewReceipt._(
      manager: this,
      record: record,
      captureRoot: captureRoot,
      registryResultElement: resultElement,
    )..requireCurrent();
  }
}
