import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Interprets source PNG colour samples in extended sRGB coordinates.
///
/// PNG3 colour-chunk precedence and ICC.1:2022 matrix/TRC decoding are
/// format interpretation. No source pixels, alpha, or comparison thresholds
/// are changed. Untagged PNGs retain the tool's existing unmanaged numeric
/// channel convention (8-bit inputs use sRGB units); their physical source
/// gamut remains unknown, and other depths retain their original units.
/// Unsupported declarations fail explicitly instead of masquerading as it.
class PngColorSpace {
  PngColorSpace._(this._profile, this._sampleMaximum);

  /// Reads the declared colour space without changing or decoding pixels.
  factory PngColorSpace.fromPng(Uint8List bytes) {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 33 ||
        List.generate(8, (i) => bytes[i] == signature[i]).contains(false)) {
      throw const FormatException('Invalid PNG signature or header');
    }
    final view = ByteData.sublistView(bytes);
    final chunks = <String, Uint8List>{};
    var at = 8;
    var sawData = false;
    while (at + 12 <= bytes.length) {
      final size = view.getUint32(at);
      if (size > bytes.length - at - 12) {
        throw const FormatException('Truncated PNG chunk');
      }
      final name = String.fromCharCodes(bytes.sublist(at + 4, at + 8));
      if (at == 8 && (name != 'IHDR' || size != 13)) {
        throw const FormatException('Invalid PNG IHDR');
      }
      if (const {
        'IHDR',
        'cICP',
        'iCCP',
        'sRGB',
        'gAMA',
        'cHRM',
      }.contains(name)) {
        if (chunks.containsKey(name) || sawData) {
          throw FormatException('Duplicate or misplaced PNG $name');
        }
        if (_crc(bytes, at + 4, at + 8 + size) !=
            view.getUint32(at + 8 + size)) {
          throw FormatException('Invalid PNG $name checksum');
        }
        chunks[name] = Uint8List.sublistView(bytes, at + 8, at + 8 + size);
      }
      if (name == 'IDAT') sawData = true;
      at += size + 12;
      if (name == 'IEND') break;
    }
    final header = chunks['IHDR']!;
    // Indexed samples address an 8-bit palette; grayscale/direct samples
    // retain package:image's original channel range on the unmanaged path.
    final maximum = header[9] == 3 ? 255 : (1 << header[8]) - 1;
    // cICP outranks embedded ICC. HDR/video transforms are not implemented;
    // a lower-priority profile cannot silently turn these into SDR samples.
    if (chunks.containsKey('cICP')) {
      throw const FormatException('Unsupported PNG cICP colour encoding');
    }
    final iccp = chunks['iCCP'];
    if (iccp != null) {
      if (maximum != 255) {
        throw const FormatException('Unsupported ICC PNG sample depth');
      }
      if (header[9] == 0 || header[9] == 4) {
        throw const FormatException(
          'Unsupported grayscale ICC colour encoding',
        );
      }
      final zero = iccp.indexOf(0);
      if (zero < 1 ||
          zero > 79 ||
          zero + 2 >= iccp.length ||
          iccp[zero + 1] != 0) {
        throw const FormatException('Invalid PNG iCCP header');
      }
      final Uint8List profile;
      try {
        profile = Uint8List.fromList(
          ZLibCodec().decode(iccp.sublist(zero + 2)),
        );
      } on FormatException catch (error) {
        throw FormatException('Invalid compressed PNG iCCP: $error');
      }
      return PngColorSpace._(_MatrixProfile(profile), maximum);
    }
    final srgb = chunks['sRGB'];
    if (srgb != null) {
      if (srgb.length != 1 || srgb[0] > 3) {
        throw const FormatException('Invalid PNG sRGB declaration');
      }
      return PngColorSpace._(null, maximum);
    }
    if (chunks.containsKey('gAMA') || chunks.containsKey('cHRM')) {
      throw const FormatException('Unsupported PNG gAMA/cHRM source transform');
    }
    return PngColorSpace._(null, maximum);
  }

  final _MatrixProfile? _profile;
  final int _sampleMaximum;
  final _cache = <int, List<double>>{};

  /// Rejects mixed units only when an ICC transform requires 8-bit units.
  ///
  /// Two unmanaged inputs keep their prior raw arithmetic at every depth;
  /// no implicit 16-bit normalization is introduced by profile decoding.
  void requireCompatible(PngColorSpace other) {
    if ((_profile != null || other._profile != null) &&
        (_sampleMaximum != 255 || other._sampleMaximum != 255)) {
      throw const FormatException('Unsupported mixed ICC PNG sample depths');
    }
  }

  /// RGB in extended 8-bit sRGB units for supported ICC comparisons.
  ///
  /// Wider-gamut colours can be negative or exceed255. Quantizing/clipping
  /// them would erase genuine differences. Alpha is deliberately absent.
  /// Unmanaged comparisons preserve their original channel units instead.
  List<double> rgb(num red, num green, num blue) {
    final profile = _profile;
    if (profile == null) {
      return [red.toDouble(), green.toDouble(), blue.toDouble()];
    }
    final key = (red.toInt() << 16) | (green.toInt() << 8) | blue.toInt();
    final cached = _cache[key];
    if (cached != null) return cached;
    final value = _extendedSrgb(
      profile.xyz([red / 255, green / 255, blue / 255]),
    );
    // Bound the acceleration cache; reaching the bound changes no arithmetic.
    if (_cache.length < 4096) _cache[key] = value;
    return value;
  }
}

int _crc(Uint8List bytes, int first, int end) {
  var crc = 0xffffffff;
  for (var at = first; at < end; at++) {
    crc ^= bytes[at];
    for (var i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  return crc ^ 0xffffffff;
}

typedef _Curve = double Function(double);

class _MatrixProfile {
  _MatrixProfile(Uint8List bytes) {
    if (bytes.length < 132) {
      throw const FormatException('Truncated ICC profile');
    }
    final view = ByteData.sublistView(bytes);
    int uint(int at) => view.getUint32(at);
    String text(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));
    if (uint(0) != bytes.length ||
        text(36) != 'acsp' ||
        !{2, 4}.contains(bytes[8]) ||
        !{'mntr', 'scnr'}.contains(text(12)) ||
        text(16) != 'RGB ' ||
        text(20) != 'XYZ ') {
      throw const FormatException('Unsupported ICC RGB matrix profile');
    }
    const pcsWhite = [0.9642, 1.0, 0.8249];
    for (var i = 0; i < 3; i++) {
      if ((view.getInt32(68 + i * 4) / 65536 - pcsWhite[i]).abs() > 1 / 65536) {
        throw const FormatException('Unsupported ICC PCS white point');
      }
    }
    final count = uint(128);
    if (count > (bytes.length - 132) ~/ 12) {
      throw const FormatException('ICC tag table exceeds profile');
    }
    final tags = <String, Uint8List>{};
    for (var i = 0; i < count; i++) {
      final at = 132 + i * 12;
      final start = uint(at + 4);
      final size = uint(at + 8);
      if (start < 132 + count * 12 ||
          size < 8 ||
          start > bytes.length - size ||
          tags.containsKey(text(at))) {
        throw const FormatException('Invalid ICC tag range');
      }
      tags[text(at)] = Uint8List.sublistView(bytes, start, start + size);
    }
    // ICC.1:2022 8.10 gives these transforms precedence over matrix/TRC.
    // They require a fuller CMM, not an accidental matrix fallback.
    if (tags.keys.any(
          (s) => RegExp(r'^[AB]2[AB]\d|^[BD]2[BD]\d').hasMatch(s),
        ) ||
        tags.containsKey('cicp')) {
      throw const FormatException('Unsupported ICC LUT/HDR transform');
    }
    Uint8List required(String name) =>
        tags[name] ??
        (throw FormatException('Required ICC matrix tag missing: $name'));
    List<double> xyz(String name) {
      final tag = required(name);
      if (tag.length != 20 ||
          String.fromCharCodes(tag.sublist(0, 4)) != 'XYZ ') {
        throw FormatException('Invalid ICC XYZ tag: $name');
      }
      final data = ByteData.sublistView(tag);
      return List.generate(3, (i) => data.getInt32(8 + i * 4) / 65536);
    }

    _columns = [xyz('rXYZ'), xyz('gXYZ'), xyz('bXYZ')];
    _curves = [
      'rTRC',
      'gTRC',
      'bTRC',
    ].map((name) => _curve(required(name))).toList();
    // Every possible8-bit device sample is validated before a CLI loads the
    // image. An undefined curve cannot later escape its per-role infra catch.
    for (final curve in _curves) {
      for (var value = 0; value < 256; value++) {
        if (!curve(value / 255).isFinite) {
          throw const FormatException('Undefined ICC source curve');
        }
      }
    }
  }

  late final List<List<double>> _columns;
  late final List<_Curve> _curves;

  List<double> xyz(List<double> rgb) {
    final linear = List.generate(3, (i) => _curves[i](rgb[i]));
    return List.generate(
      3,
      (j) => List.generate(
        3,
        (i) => _columns[i][j] * linear[i],
      ).reduce((a, b) => a + b),
    );
  }

  static _Curve _curve(Uint8List tag) {
    if (tag.length < 12) throw const FormatException('Truncated ICC curve');
    final data = ByteData.sublistView(tag);
    final type = String.fromCharCodes(tag.sublist(0, 4));
    if (type == 'curv') {
      final count = data.getUint32(8);
      if (count > (tag.length - 12) ~/ 2) {
        throw const FormatException('Truncated ICC curve samples');
      }
      if (count == 0) return (v) => v;
      if (count == 1) {
        final gamma = data.getUint16(12) / 256;
        if (gamma <= 0) throw const FormatException('Invalid ICC gamma');
        return (v) => math.pow(v, gamma).toDouble();
      }
      final values = List.generate(
        count,
        (i) => data.getUint16(12 + i * 2) / 65535,
      );
      return (v) {
        final pos = v * (count - 1);
        final low = pos.floor();
        if (low == count - 1) return values.last;
        return values[low] + (values[low + 1] - values[low]) * (pos - low);
      };
    }
    if (type != 'para') {
      throw const FormatException('Unsupported ICC curve type');
    }
    final fn = data.getUint16(8);
    const counts = [1, 3, 4, 5, 7];
    if (fn >= counts.length || tag.length < 12 + 4 * counts[fn]) {
      throw const FormatException('Unsupported ICC parametric curve');
    }
    final p = List.generate(
      counts[fn],
      (i) => data.getInt32(12 + i * 4) / 65536,
    );
    if (p[0] <= 0 ||
        (fn > 0 && p[1] <= 0) ||
        (fn >= 3 && (p[4] < 0 || p[4] > 1 || p[1] * p[4] + p[2] < 0))) {
      throw const FormatException('Invalid ICC curve parameters');
    }
    return (v) {
      final double y;
      if (fn == 0) {
        y = math.pow(v, p[0]).toDouble();
      } else if (fn <= 2) {
        final bias = fn == 2 ? p[3] : 0.0;
        y = v >= -p[2] / p[1]
            ? math.pow(p[1] * v + p[2], p[0]).toDouble() + bias
            : bias;
      } else {
        y = v >= p[4]
            ? math.pow(p[1] * v + p[2], p[0]).toDouble() + (fn == 4 ? p[5] : 0)
            : p[3] * v + (fn == 4 ? p[6] : 0);
      }
      if (!y.isFinite) throw const FormatException('Undefined ICC curve');
      // Mandatory source TRC range, ICC.1:2022 10.18. This is not target
      // gamut clipping; wider-gamut XYZ and output RGB remain unbounded.
      return y.clamp(0.0, 1.0);
    };
  }
}

List<double> _multiply(List<List<double>> matrix, List<double> vector) => matrix
    .map(
      (row) =>
          List.generate(3, (i) => row[i] * vector[i]).reduce((a, b) => a + b),
    )
    .toList();

List<double> _extendedSrgb(List<double> xyzD50) {
  // Standard Bradford D50->D65 and sRGB matrices / extended transfer:
  // https://www.w3.org/TR/css-color-4/#color-conversion-code
  final xyzD65 = _multiply([
    [0.955473421488075, -0.02309845494876471, 0.06325924320057072],
    [-0.0283697093338637, 1.0099953980813041, 0.021041441191917323],
    [0.012314014864481998, -0.020507649298898964, 1.330365926242124],
  ], xyzD50);
  final linear = _multiply([
    [12831 / 3959, -329 / 214, -1974 / 3959],
    [-851781 / 878810, 1648619 / 878810, 36519 / 878810],
    [705 / 12673, -2585 / 12673, 705 / 667],
  ], xyzD65);
  return linear.map((v) {
    final encoded = v.abs() > 0.0031308
        ? v.sign * (1.055 * math.pow(v.abs(), 1 / 2.4) - 0.055)
        : 12.92 * v;
    return encoded * 255;
  }).toList();
}
