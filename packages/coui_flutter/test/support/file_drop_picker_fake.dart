import 'package:file_drop/file_drop.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives the native picker and lazy content reads through their method channel.
final class FileDropPickerFake {
  Future<PickedFileFixture?> singleResult = Future.value();
  Future<List<PickedFileFixture>> multipleResult = Future.value([]);
  int singleCalls = 0;
  int multipleCalls = 0;
  List<String>? allowedExtensions;

  final _files = <String, PickedFileFixture>{};

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(DesktopDrop.channel, _handle);
    addTearDown(
      () => messenger.setMockMethodCallHandler(DesktopDrop.channel, null),
    );
  }

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'openFile':
        singleCalls++;
        _readFilters(call);
        final file = await singleResult;
        return file == null ? null : _encode(file);
      case 'openFiles':
        multipleCalls++;
        _readFilters(call);
        return (await multipleResult).map(_encode).toList();
      case 'statContentUri':
        final file = _file(call);
        return {'exists': true, 'length': file.bytes.length};
      case 'readContentUri':
        final file = _file(call);
        file.reads++;
        return file.bytes;
      default:
        throw MissingPluginException(call.method);
    }
  }

  PickedFileFixture _file(MethodCall call) =>
      _files[(call.arguments as Map<Object?, Object?>)['uri']]!;

  void _readFilters(MethodCall call) {
    final groups =
        (call.arguments as Map<Object?, Object?>)['acceptedTypeGroups']
            as List<Object?>?;
    if (groups == null || groups.isEmpty) {
      allowedExtensions = null;
      return;
    }
    final group = groups.single! as Map<Object?, Object?>;
    allowedExtensions = (group['extensions'] as List<Object?>?)?.cast<String>();
  }

  Map<String, Object> _encode(PickedFileFixture file) {
    final uri = Uri(
      scheme: 'content',
      host: 'coui.test',
      pathSegments: [file.name],
    ).toString();
    _files[uri] = file;
    return {'uri': uri, 'name': file.name, 'length': file.bytes.length};
  }
}

final class PickedFileFixture {
  PickedFileFixture(this.name, List<int> bytes)
    : bytes = Uint8List.fromList(bytes);

  final String name;
  final Uint8List bytes;
  int reads = 0;
}
