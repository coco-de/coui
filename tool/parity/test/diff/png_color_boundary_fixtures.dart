// Synthetic controls for issue6620. Original P3/sRGB profile bytes remain
// in png_color_profile_fixtures.dart. These curves are independently evaluated
// by existing LittleCMS2.17 floating PCS; no target RGB clipping is performed.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'png_color_profile_fixtures.dart';

Uint8List samplePng({
  required int bits,
  required int colorType,
  required List<int> channels,
  Uint8List? profile,
  bool srgb = false,
}) {
  final header = Uint8List(13);
  ByteData.sublistView(header)
    ..setUint32(0, 16)
    ..setUint32(4, 16);
  header[8] = bits;
  header[9] = colorType;
  final samples = [for (var x = 0; x < 16; x++) ...channels];
  final row = <int>[0]; // PNG filterNone.
  if (bits == 16) {
    for (final v in samples) {
      row.addAll([v >> 8, v & 255]);
    }
  } else if (bits == 8) {
    row.addAll(samples);
  } else {
    for (var i = 0; i < samples.length; i += 8 ~/ bits) {
      var packed = 0;
      for (var j = 0; j < 8 ~/ bits; j++) {
        packed |= samples[i + j] << (8 - bits * (j + 1));
      }
      row.add(packed);
    }
  }
  final bytes = Uint8List.fromList([
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    ...pngChunk('IHDR', header),
    if (profile != null)
      ...pngChunk(
        'iCCP',
        Uint8List.fromList([
          ...'Synthetic fixture'.codeUnits,
          0,
          0,
          ...ZLibCodec().encode(profile),
        ]),
      ),
    if (srgb) ...pngChunk('sRGB', Uint8List.fromList([0])),
    if (colorType == 3)
      ...pngChunk('PLTE', Uint8List.fromList([0, 0, 0, 200, 40, 60])),
    ...pngChunk(
      'IDAT',
      Uint8List.fromList(
        ZLibCodec().encode([
          for (var y = 0; y < 16; y++) ...row,
        ]),
      ),
    ),
    ...pngChunk('IEND', Uint8List(0)),
  ]);
  return bytes;
}

Uint8List pngChunk(String name, Uint8List payload) {
  final bytes = Uint8List(payload.length + 12);
  final data = ByteData.sublistView(bytes)..setUint32(0, payload.length);
  bytes
    ..setRange(4, 8, name.codeUnits)
    ..setRange(8, 8 + payload.length, payload);
  var crc = 0xffffffff;
  for (final b in bytes.sublist(4, 8 + payload.length)) {
    crc ^= b;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  data.setUint32(8 + payload.length, crc ^ 0xffffffff);
  return bytes;
}

Uint8List curveProfile(String hex) {
  final curve = Uint8List.fromList([
    for (var at = 0; at < hex.length; at += 2)
      int.parse(hex.substring(at, at + 2), radix: 16),
  ]);
  final source = p3Profile();
  final data = ByteData.sublistView(source);
  final count = data.getUint32(128);
  final table = BytesBuilder()..add(source.sublist(0, 132));
  final body = BytesBuilder();
  for (var i = 0; i < count; i++) {
    final at = 132 + 12 * i;
    final name = String.fromCharCodes(source.sublist(at, at + 4));
    final value = ['rTRC', 'gTRC', 'bTRC'].contains(name)
        ? curve
        : source.sublist(
            data.getUint32(at + 4),
            data.getUint32(at + 4) + data.getUint32(at + 8),
          );
    final tag = Uint8List(12)..setRange(0, 4, name.codeUnits);
    ByteData.sublistView(tag)
      ..setUint32(4, 132 + 12 * count + body.length)
      ..setUint32(8, value.length);
    table.add(tag);
    body
      ..add(value)
      ..add(List.filled((4 - value.length % 4) % 4, 0));
  }
  final result = Uint8List.fromList([
    ...table.takeBytes(),
    ...body.takeBytes(),
  ]);
  ByteData.sublistView(result).setUint32(0, result.length);
  return result;
}

// Independent LCMS2.17 -> XYZ D50 + normative CSS Color4 extended-sRGB
// reference results. Tolerance is a transform test precision, not a pixel
// comparison threshold. Both transfer-function branches are exercised.
final List<Map<String, dynamic>> curveOracle =
    (jsonDecode(
              '''[{"name":"identity","curveHex":"637572760000000000000000","vectors":[{"rgb":[0,0,0],"expected":[0.0,0.0,0.0],"xyz":[0.0,0.0,0.0]},{"rgb":[1,10,20],"expected":[-13.00687165403742,56.846833590133826,81.33927944017603],"xyz":[0.025795013986567028,0.033314785139850756,0.06315828598928874]},{"rgb":[25,26,27],"expected":[87.7993018440204,89.95425660470566,91.72575876780273],"xyz":[0.09690869247890532,0.10127611147879634,0.08721924105486778]},{"rgb":[64,128,192],"expected":[121.93398235372045,189.61022062351782,228.8842432868453],"xyz":[0.3941597994298718,0.45814187609494184,0.6113511020976148]},{"rgb":[255,255,255],"expected":[254.96693302175478,255.0089030044736,255.0160653935192],"xyz":[0.9642181489698487,0.9999999997671694,0.8252105559631673]}]},{"name":"gamma2","curveHex":"6375727600000000000000010200","vectors":[{"rgb":[0,0,0],"expected":[0.0,0.0,0.0],"xyz":[0.0,0.0,0.0]},{"rgb":[1,10,20],"expected":[-1.0791966872521475,5.278265272985117,19.25965232895609],"xyz":[0.0014236276502987977,0.001477892427557137,0.004889484391981114]},{"rgb":[25,26,27],"expected":[24.512383543515032,26.160995103780312,27.53794321004891],"xyz":[0.009748097774320286,0.010261115505656448,0.009219040119035071]},{"rgb":[64,128,192],"expected":[39.13801656870163,139.4323838470803,203.674215413163],"xyz":[0.19510285871660926,0.227360653566393,0.4551672920820238]},{"rgb":[255,255,255],"expected":[254.96693302175478,255.0089030044736,255.0160653935192],"xyz":[0.9642181489698487,0.9999999997671694,0.8252105559631673]}]},{"name":"table5","curveHex":"6375727600000000000000050000100040009000ffff","vectors":[{"rgb":[0,0,0],"expected":[0.0,0.0,0.0],"xyz":[0.0,0.0,0.0]},{"rgb":[1,10,20],"expected":[-3.3380334467997623,25.763678995615685,39.495828702718306],"xyz":[0.0064490161256003375,0.00833305760203018,0.015789895592632774]},{"rgb":[25,26,27],"expected":[43.115691480497894,44.33910830174308,45.329014778967505],"xyz":[0.024228035511271173,0.025323643433949883,0.021808125721491933]},{"rgb":[64,128,192],"expected":[39.33826169248293,139.55692190783014,203.78852949521644],"xyz":[0.19548718360169914,0.22781095978643862,0.4557607068704783]},{"rgb":[255,255,255],"expected":[254.96693302175478,255.0089030044736,255.0160653935192],"xyz":[0.9642181489698487,0.9999999997671694,0.8252105559631673]}]},{"name":"para0","curveHex":"70617261000000000000000000020000","vectors":[{"rgb":[0,0,0],"expected":[0.0,0.0,0.0],"xyz":[0.0,0.0,0.0]},{"rgb":[1,10,20],"expected":[-1.0791966872521475,5.278265272985117,19.25965232895609],"xyz":[0.0014236276502987977,0.001477892427557137,0.004889484391981114]},{"rgb":[25,26,27],"expected":[24.512383543515032,26.160995103780312,27.53794321004891],"xyz":[0.009748097774320286,0.010261115505656448,0.009219040119035071]},{"rgb":[64,128,192],"expected":[39.13801656870163,139.4323838470803,203.674215413163],"xyz":[0.19510285871660926,0.227360653566393,0.4551672920820238]},{"rgb":[255,255,255],"expected":[254.96693302175478,255.0089030044736,255.0160653935192],"xyz":[0.9642181489698487,0.9999999997671694,0.8252105559631673]}]},{"name":"para1","curveHex":"7061726100000000000100000002000000010000ffffe666","vectors":[{"rgb":[0,0,0],"expected":[0.0,0.0,0.0],"xyz":[0.0,0.0,0.0]},{"rgb":[1,10,20],"expected":[0.0,0.0,0.0],"xyz":[0.0,0.0,0.0]},{"rgb":[25,26,27],"expected":[-0.00283763345286592,0.01311996800581159,0.12396975802533743],"xyz":[6.541971053833362e-06,4.94421287713237e-06,2.7244860484748612e-05]},{"rgb":[64,128,192],"expected":[-22.816887019393544,113.73062264340939,179.77268371142424],"xyz":[0.12590944866474274,0.14572789925864527,0.341142694123846]},{"rgb":[255,255,255],"expected":[232.35505892542082,232.3935042502133,232.4000640620056],"xyz":[0.7810061013333325,0.8099890136509202,0.6684114863901414]}]},{"name":"para2","curveHex":"7061726100000000000200000002000000010000ffffe6660000051f","vectors":[{"rgb":[0,0,0],"expected":[38.68265846634196,38.690885252453015,38.69228778383112],"xyz":[0.019288482119037553,0.020004272689106983,0.016507736903719206]},{"rgb":[1,10,20],"expected":[38.68265846634196,38.690885252453015,38.69228778383112],"xyz":[0.019288482119037553,0.020004272689106983,0.016507736903719206]},{"rgb":[25,26,27],"expected":[38.681712686940664,38.6952559693936,38.73357614916113],"xyz":[0.01929502362898461,0.020009216073901825,0.016534981398592663]},{"rgb":[64,128,192],"expected":[27.87812924775427,119.88278832624833,183.27786780559376],"xyz":[0.14519793264639702,0.16573217939821916,0.35765042543971504]},{"rgb":[255,255,255],"expected":[234.87237930060238,234.91121697623842,234.91785522205663],"xyz":[0.8002945853149868,0.8299932788895603,0.6849192773097457]}]},{"name":"para3","curveHex":"706172610000000000030000000200000001000000000000000033330000199a","vectors":[{"rgb":[0,0,0],"expected":[0.0,0.0,0.0],"xyz":[0.0,0.0,0.0]},{"rgb":[1,10,20],"expected":[-2.6535437817843874,22.218773003500278,34.74418070861993],"xyz":[0.0051589240086258314,0.006662855235965992,0.012631463858241432]},{"rgb":[25,26,27],"expected":[40.481416285566354,25.478000872127613,27.235760123092522],"xyz":[0.014897025118969509,0.012671920824871563,0.009208516334524575]},{"rgb":[64,128,192],"expected":[39.13801656870163,139.4323838470803,203.674215413163],"xyz":[0.19510285871660926,0.227360653566393,0.4551672920820238]},{"rgb":[255,255,255],"expected":[254.96693302175478,255.0089030044736,255.0160653935192],"xyz":[0.9642181489698487,0.9999999997671694,0.8252105559631673]}]},{"name":"para4","curveHex":"706172610000000000040000000200000001000000000000000033330000199a0000028f00000148","vectors":[{"rgb":[0,0,0],"expected":[15.565573021393968,15.570190950169952,15.570978298840338],"xyz":[0.0048257987321420615,0.00500488281133471,0.004130082048199313]},{"rgb":[1,10,20],"expected":[13.478818348074867,30.22928804283882,40.40549964692963],"xyz":[0.009984722740767893,0.01166773758164652,0.016761546372094926]},{"rgb":[25,26,27],"expected":[44.35252459940958,38.91935397323778,39.985984076499385],"xyz":[0.0219637231350589,0.021463027544683655,0.01746134265232513]},{"rgb":[64,128,192],"expected":[48.73734441406781,141.8640419395646,205.17397768254],"xyz":[0.20473975454706306,0.23735515690759712,0.46341483974401854]},{"rgb":[255,255,255],"expected":[256.0838610861433,256.1260097305025,256.13321117561446],"xyz":[0.973855000097501,1.0099944733065058,0.8334581632288973]}]}]''',
            )
            as List)
        .cast<Map<String, dynamic>>();
final List<Map<String, dynamic>> srgbOracle =
    (jsonDecode(
              '''[{"rgb":[0,127,51],"expected":[-0.08568483220469475,127.00494382399721,50.988553537838634]},{"rgb":[255,0,0],"expected":[254.99054995731095,0.06767758899111148,-0.040259848730431765]},{"rgb":[128,128,128],"expected":[127.99013865052895,128.00606867554217,127.98288580867262]}]''',
            )
            as List)
        .cast<Map<String, dynamic>>();
