import 'dart:io';
import 'dart:typed_data';

/// The same synthetic image for both capture engines. These captures compare
/// chrome and layout, and must not compare a photo against a grey placeholder.
Uint8List loadParityNetworkImageBytes() {
  var directory = Directory.current.absolute;
  while (true) {
    final fixture = File(
      '${directory.path}/test/parity/fixtures/network-image.png',
    );
    if (fixture.existsSync()) return fixture.readAsBytesSync();
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('The shared parity network-image fixture is missing.');
    }
    directory = parent;
  }
}
