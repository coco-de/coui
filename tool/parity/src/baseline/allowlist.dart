import 'dart:io';

import 'package:yaml/yaml.dart';

import 'parity_signal.dart';

/// `allowlist.yaml` 의 한 항목 — "이 변경은 의도된 것" 이라는 승인 기록.
class AllowlistEntry {
  const AllowlistEntry({
    required this.key,
    required this.signal,
    required this.fingerprint,
    required this.reason,
    required this.expires,
  });

  /// 매트릭스 키 — 예: `dialog-default-dark-neoBrutalism`.
  final String key;

  /// 이 승인이 적용되는 신호.
  final ParitySignal signal;

  /// 승인된 산출물의 sha256.
  ///
  /// 승인은 "이 키를 앞으로 무시하라" 가 아니라 "정확히 이 결과물을 승인한다"
  /// 이다. 지문을 고정하지 않으면 한 번 승인된 키가 이후의 진짜 회귀까지
  /// 조용히 통과시킨다.
  final String fingerprint;

  /// 왜 승인했는지 — 리포트에 그대로 실린다.
  final String reason;

  /// 승인이 유효한 마지막 날(UTC 날짜).
  ///
  /// 이 날짜가 지나면 실패로 전환된다. 예외가 영구 방치되지 않게 하는 장치다.
  final DateTime expires;

  /// [now] 시점에 만료됐는가.
  ///
  /// [expires] 당일까지는 유효하고 그 다음 날부터 만료다. 시각이 아니라
  /// **날짜만** 비교하므로 러너의 시간대에 따라 판정이 흔들리지 않는다.
  bool isExpiredAt(DateTime now) {
    final utcNow = now.toUtc();
    final today = DateTime.utc(utcNow.year, utcNow.month, utcNow.day);

    return today.isAfter(expires);
  }
}

/// `test/parity/allowlist.yaml` 을 읽어들인 승인 목록.
///
/// 파싱은 **엄격하다** — 형식이 깨진 항목을 조용히 건너뛰면 승인이 사라진
/// 채로 게이트가 통과해버리고, 그건 승인 누락보다 발견이 늦다.
class Allowlist {
  const Allowlist._(this._entries);

  /// 파일에서 읽는다.
  ///
  /// 파일이 없으면 [empty] — 승인이 0건이라는 뜻이고, 그건 전부 엄격 판정하는
  /// 안전한 쪽이다.
  factory Allowlist.fromFile(File file) {
    if (!file.existsSync()) {
      return empty;
    }

    return Allowlist.parse(file.readAsStringSync(), origin: file.path);
  }

  /// YAML 원문을 파싱한다. [origin] 은 오류 메시지에 쓰는 파일 경로다.
  factory Allowlist.parse(String source, {required String origin}) {
    final document = loadYaml(source);
    if (document == null) {
      return empty;
    }
    if (document is! YamlMap) {
      throw FormatException('$origin: 최상위가 맵이어야 한다 (entries: 키 필요).');
    }

    final rawEntries = document['entries'];
    if (rawEntries == null) {
      return empty;
    }
    if (rawEntries is! YamlList) {
      throw FormatException('$origin: `entries` 는 리스트여야 한다.');
    }

    final parsed = <AllowlistEntry>[
      for (var index = 0; index < rawEntries.length; index++)
        _parseEntry(rawEntries[index], origin: origin, index: index),
    ];

    _rejectDuplicates(parsed, origin: origin);

    return Allowlist._(parsed);
  }

  /// 승인 0건. 파일이 아예 없을 때의 값이기도 하다(= 전부 엄격 판정).
  static const Allowlist empty = Allowlist._(<AllowlistEntry>[]);

  final List<AllowlistEntry> _entries;

  /// 등록된 모든 승인.
  Iterable<AllowlistEntry> get entries => _entries;

  /// (key, signal) 로 등록된 승인 전부.
  ///
  /// 여럿일 수 있다 — Flutter 와 Web 은 같은 변경이라도 산출물 지문이 다르므로
  /// 플랫폼마다 한 항목씩 등록된다.
  List<AllowlistEntry> entriesFor(String key, ParitySignal signal) =>
      <AllowlistEntry>[
        for (final entry in _entries)
          if (entry.key == key && entry.signal == signal) entry,
      ];

  static AllowlistEntry _parseEntry(
    Object? raw, {
    required String origin,
    required int index,
  }) {
    final where = '$origin: entries[$index]';
    if (raw is! YamlMap) {
      throw FormatException('$where 는 맵이어야 한다.');
    }

    final signalName = _requireString(raw, 'signal', where);
    final signal = ParitySignal.tryParse(signalName);
    if (signal == null) {
      throw FormatException(
        '$where 의 signal 이 `$signalName` 이다. '
        '허용값: ${ParitySignal.wireNames}.',
      );
    }

    return AllowlistEntry(
      key: _requireString(raw, 'key', where),
      signal: signal,
      fingerprint: _requireString(raw, 'fingerprint', where),
      reason: _requireString(raw, 'reason', where),
      expires: _parseExpires(raw['expires'], where),
    );
  }

  static String _requireString(YamlMap map, String field, String where) {
    final value = map[field];
    if (value is! String || value.isEmpty) {
      throw FormatException('$where 에 `$field` 문자열이 필요하다.');
    }

    return value;
  }

  /// `expires` 를 UTC 자정으로 정규화한다.
  ///
  /// YAML 구현에 따라 `2026-11-01` 이 문자열로도 `DateTime` 으로도 올 수 있어
  /// 둘 다 받는다. 어느 쪽이든 시각은 버리고 날짜만 쓴다.
  static DateTime _parseExpires(Object? raw, String where) {
    if (raw is DateTime) {
      return DateTime.utc(raw.year, raw.month, raw.day);
    }
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateTime.utc(parsed.year, parsed.month, parsed.day);
      }
    }

    throw FormatException(
      '$where 의 `expires` 는 YYYY-MM-DD 날짜여야 한다 (받은 값: $raw).',
    );
  }

  /// 같은 (key, signal, fingerprint) 가 두 번 등록되면 던진다.
  ///
  /// 중복은 대개 승격을 두 번 돌린 흔적이고, 그중 하나만 만료일을 갱신하면
  /// 어느 쪽이 이기는지가 파일 순서에 달리게 된다.
  static void _rejectDuplicates(
    List<AllowlistEntry> entries, {
    required String origin,
  }) {
    final seen = <String>{};
    for (final entry in entries) {
      final identity =
          '${entry.key}|${entry.signal.wireName}|${entry.fingerprint}';
      if (!seen.add(identity)) {
        throw FormatException(
          '$origin: 중복 항목 — key `${entry.key}`, '
          'signal `${entry.signal.wireName}`, 같은 fingerprint 가 두 번 등록됐다.',
        );
      }
    }
  }
}
