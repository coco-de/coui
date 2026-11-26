// Unmodified embedded profile fixtures. Source P3 profile is Google Inc.2016;
// sRGB profile is LCMS2.17's standard matrix profile. Independent reference
// colours are retained in issue6620's external LCMS oracle, not computed here.
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

Uint8List p3Profile() => base64Decode(
  'AAACCAAAAAAEMAAAbW50clJHQiBYWVogB+AAAQABAAAAAAAAYWNzcAAAAAAAAAAA'
  'AAAAAAAAAAAAAAAAAAAAAAAAAAEAAPbWAAEAAAAA0y0AAAAAAAAAAAAAAAAAAAAA'
  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJZGVzYwAAAPAAAABk'
  'clhZWgAAAVQAAAAUZ1hZWgAAAWgAAAAUYlhZWgAAAXwAAAAUd3RwdAAAAZAAAAAU'
  'clRSQwAAAaQAAAAoZ1RSQwAAAaQAAAAoYlRSQwAAAaQAAAAoY3BydAAAAcwAAAA8'
  'bWx1YwAAAAAAAAABAAAADGVuVVMAAABGAAAAHABEAGkAcwBwAGwAYQB5ACAAUAAz'
  'ACAARwBhAG0AdQB0ACAAdwBpAHQAaAAgAHMAUgBHAEIAIABUAHIAYQBuAHMAZgBl'
  'AHIAAFhZWiAAAAAAAACD3gAAPb7///+7WFlaIAAAAAAAAEq+AACxNgAACrlYWVog'
  'AAAAAAAAKDsAABEMAADIzVhZWiAAAAAAAAD21gABAAAAANMtcGFyYQAAAAAABAAA'
  'AAJmZgAA8qcAAA1ZAAAT0AAAClsAAAAAAAAAAG1sdWMAAAAAAAAAAQAAAAxlblVT'
  'AAAAIAAAABwARwBvAG8AZwBsAGUAIABJAG4AYwAuACAAMgAwADEANg==',
);
Uint8List srgbProfile() => base64Decode(
  'AAACTGxjbXMEQAAAbW50clJHQiBYWVogB+oACwAXAA4AJwADYWNzcEFQUEwAAAAA'
  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAPbWAAEAAAAA0y1sY21zAAAAAAAAAAAAAAAA'
  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALZGVzYwAAAQgAAAA2'
  'Y3BydAAAAUAAAABMd3RwdAAAAYwAAAAUY2hhZAAAAaAAAAAsclhZWgAAAcwAAAAU'
  'YlhZWgAAAeAAAAAUZ1hZWgAAAfQAAAAUclRSQwAAAggAAAAgZ1RSQwAAAggAAAAg'
  'YlRSQwAAAggAAAAgY2hybQAAAigAAAAkbWx1YwAAAAAAAAABAAAADGVuVVMAAAAa'
  'AAAAHABzAFIARwBCACAAYgB1AGkAbAB0AC0AaQBuAABtbHVjAAAAAAAAAAEAAAAM'
  'ZW5VUwAAADAAAAAcAE4AbwAgAGMAbwBwAHkAcgBpAGcAaAB0ACwAIAB1AHMAZQAg'
  'AGYAcgBlAGUAbAB5WFlaIAAAAAAAAPbWAAEAAAAA0y1zZjMyAAAAAAABDEIAAAXe'
  '///zJQAAB5MAAP2Q///7of///aIAAAPcAADAblhZWiAAAAAAAABvoAAAOPUAAAOQ'
  'WFlaIAAAAAAAACSfAAAPhAAAtsNYWVogAAAAAAAAYpcAALeHAAAY2XBhcmEAAAAA'
  'AAMAAAACZmYAAPKnAAANWQAAE9AAAApbY2hybQAAAAAAAwAAAACj1wAAVHsAAEzN'
  'AACZmgAAJmYAAA9c',
);

Uint8List profilePng(List<int> rgba, {Uint8List? profile, bool srgb = false}) {
  final image = img.Image(width: 16, height: 16, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(rgba[0], rgba[1], rgba[2], rgba[3]));
  if (profile != null) {
    image.iccProfile = img.IccProfile(
      'ICC fixture',
      img.IccProfileCompression.none,
      profile,
    );
  }
  final png = Uint8List.fromList(img.encodePng(image));
  return srgb ? withChunk(png, 'sRGB', Uint8List.fromList([0])) : png;
}

Uint8List withChunk(Uint8List png, String name, Uint8List payload) {
  final chunk = Uint8List(12 + payload.length);
  final view = ByteData.sublistView(chunk)..setUint32(0, payload.length);
  chunk
    ..setRange(4, 8, name.codeUnits)
    ..setRange(8, 8 + payload.length, payload);
  var crc = 0xffffffff;
  for (final byte in chunk.sublist(4, 8 + payload.length)) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  view.setUint32(8 + payload.length, crc ^ 0xffffffff);
  // After IHDR, before the existing colour/sample chunks.
  return Uint8List.fromList([
    ...png.sublist(0, 33),
    ...chunk,
    ...png.sublist(33),
  ]);
}

Uint8List unsupportedCurveProfile() {
  final bytes = p3Profile();
  final view = ByteData.sublistView(bytes);
  final n = view.getUint32(128);
  for (var i = 0; i < n; i++) {
    final at = 132 + 12 * i;
    final name = String.fromCharCodes(bytes.sublist(at, at + 4));
    if (name == 'rTRC') {
      view.setUint16(view.getUint32(at + 4) + 8, 99);
      return bytes;
    }
  }
  throw StateError('Profile fixture has no rTRC');
}
