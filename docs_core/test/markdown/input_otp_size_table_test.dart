@TestOn('vm')
library;

import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart'
    show CoreColor, CoreInputOtpSize, CoreInputOtpStyle, CoreTextStyle, CoreTypography;
import 'package:test/test.dart';

/// Holds the InputOtp page's size table to the rows it describes.
///
/// The rows live in one place, `CoreInputOtpStyle.defaultsBySize`, and fall
/// through to the `default*` constants for every field a row leaves empty
/// (`md` is empty). The STYLE_TABLE generator does not read `defaultsBySize`,
/// so the page's table is a hand-written copy — and a copy drifts unless
/// something compares it.
///
/// What this does **not** check: whether the prose around the table is true
/// beyond the one claim tested below. That is review's.
void main() {
  final file = File('content/components/input-otp.md');

  /// The table under the size heading: row label → one cell per size, in the
  /// header's column order.
  (List<String>, Map<String, List<String>>) table() {
    final lines = file.readAsLinesSync();
    final start = lines.indexWhere((l) => l.startsWith('### 크기별 세부 값'));
    expect(start, isNot(-1), reason: 'size section heading moved');

    List<String> cells(String line) => [
      for (final cell in line.split('|').skip(1).toList()..removeLast()) cell.trim(),
    ];

    final tableLines = [
      for (final line in lines.skip(start + 1).takeWhile((l) => !l.startsWith('#')))
        if (line.startsWith('|')) line,
    ];
    expect(tableLines.length, greaterThan(2), reason: 'size table missing');

    final sizes = [
      for (final cell in cells(tableLines.first).skip(1)) RegExp(r'^`(\w+)`$').firstMatch(cell)!.group(1)!,
    ];
    final rows = <String, List<String>>{
      for (final line in tableLines.skip(2)) cells(line).first: cells(line).skip(1).toList(),
    };
    return (sizes, rows);
  }

  String kebab(String camel) => camel.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '-${m.group(0)!.toLowerCase()}',
  );

  int weight(String word) =>
      int.tryParse(word) ??
      const {
        'Regular': 400,
        'Medium': 500,
        'SemiBold': 600,
        'Bold': 700,
      }[word]!;

  CoreTextStyle roleStyle(CoreTextStyle style) => style.token!.read(CoreTypography.coui);

  test('every size column matches CoreInputOtpStyle.defaultsBySize', () {
    expect(file.existsSync(), isTrue);
    final (sizes, rows) = table();
    final ladder = CoreInputOtpStyle.defaultsBySize;

    expect(
      sizes.toSet(),
      ladder.keys.map((s) => s.name).toSet(),
      reason: 'the table and the ladder list different sizes',
    );
    expect(
      rows.keys.toSet(),
      {
        '칸',
        '모서리',
        '숫자',
        '커서',
        '가림 점',
        '칸 사이',
        '빈 칸',
        '채운 칸',
        '호버 보더',
        '활성 칸 보더',
        '보더 두께',
      },
      reason: 'the table rows changed — update this test with them',
    );

    for (final (column, sizeName) in sizes.indexed) {
      final size = CoreInputOtpSize.values.byName(sizeName);
      final row = ladder[size]!;
      String cell(String label) => rows[label]![column];

      // 칸 — width × height, as both resolvers fall back.
      final cellBox = RegExp(r'^(\d+) × (\d+)$').firstMatch(cell('칸'))!;
      expect(
        double.parse(cellBox.group(1)!),
        row.cellSize ?? CoreInputOtpStyle.defaultCellSize,
        reason: '$sizeName cell width',
      );
      expect(
        double.parse(cellBox.group(2)!),
        row.cellHeight ?? row.cellSize ?? CoreInputOtpStyle.defaultCellHeight,
        reason: '$sizeName cell height',
      );

      // 모서리 — one radius on all four corners.
      final radius = row.borderRadius ?? CoreInputOtpStyle.defaultBorderRadius;
      expect(
        {
          radius.topLeft,
          radius.topRight,
          radius.bottomLeft,
          radius.bottomRight,
        },
        {double.parse(cell('모서리'))},
        reason: '$sizeName corner',
      );

      // 숫자 — role, its size, and the weight the merged slot draws.
      final digit = RegExp(
        r'^`(\w+)` (\d+) · (\w+)$',
      ).firstMatch(cell('숫자'))!;
      final digitStyle = CoreInputOtpStyle.defaultTextStyle.merge(
        row.textStyle,
      );
      expect(
        digitStyle.token!.name,
        kebab(digit.group(1)!),
        reason: '$sizeName digit role',
      );
      expect(
        double.parse(digit.group(2)!),
        roleStyle(digitStyle).fontSize,
        reason: '$sizeName digit size',
      );
      expect(
        weight(digit.group(3)!),
        digitStyle.fontWeight ?? roleStyle(digitStyle).fontWeight,
        reason: '$sizeName digit weight',
      );

      // 커서 — width × height.
      final caret = RegExp(r'^(\d+) × (\d+)$').firstMatch(cell('커서'))!;
      expect(
        double.parse(caret.group(1)!),
        row.caretWidth ?? CoreInputOtpStyle.defaultCaretWidth,
        reason: '$sizeName caret width',
      );
      expect(
        double.parse(caret.group(2)!),
        row.caretHeight ?? CoreInputOtpStyle.defaultCaretHeight,
        reason: '$sizeName caret height',
      );

      expect(
        double.parse(cell('가림 점')),
        row.obscuredDotSize ?? CoreInputOtpStyle.defaultObscuredDotSize,
        reason: '$sizeName obscured dot',
      );
      expect(
        double.parse(cell('칸 사이')),
        row.cellSpacing ?? CoreInputOtpStyle.defaultCellSpacing,
        reason: '$sizeName cell spacing',
      );

      // Cell chrome — the default variant, as both resolvers fold it. `없음`
      // is the transparent border.
      String colour(CoreColor c) => c == CoreColor.transparent ? '없음' : '`${c.token!.name}`';
      String doc(String cellText) => cellText.replaceAllMapped(
        RegExp(r'`(\w+)`'),
        (m) => '`${kebab(m.group(1)!)}`',
      );
      final emptyFill = row.backgroundColor ?? CoreInputOtpStyle.defaultBackgroundColor;
      final emptyBorder = row.borderColor ?? CoreInputOtpStyle.defaultBorderColor;
      final filledFill = row.filledBackgroundColor ?? CoreInputOtpStyle.defaultFilledBackgroundColor;
      final filledBorder = row.filledBorderColor ?? CoreInputOtpStyle.defaultFilledBorderColor;
      expect(
        doc(cell('빈 칸')),
        '${colour(emptyFill)} · ${colour(emptyBorder)}',
        reason: '$sizeName empty cell',
      );
      expect(
        doc(cell('채운 칸')),
        '${colour(filledFill)} · ${colour(filledBorder)}',
        reason: '$sizeName filled cell',
      );
      expect(
        doc(cell('호버 보더')),
        colour(row.hoverBorderColor ?? CoreInputOtpStyle.defaultHoverBorderColor),
        reason: '$sizeName hover border',
      );
      // 활성 칸 보더 — the active cell's edge, empty or filled.
      expect(
        doc(cell('활성 칸 보더')),
        colour(row.focusBorderColor ?? CoreInputOtpStyle.defaultFocusBorderColor),
        reason: '$sizeName active cell border',
      );
      expect(
        double.parse(cell('보더 두께')),
        row.borderWidth ?? CoreInputOtpStyle.defaultBorderWidth,
        reason: '$sizeName border width',
      );
    }
  });

  // The prose under the table says the row floor follows the cell, and that
  // `lg` states its own cell height (so restating only `cellSize` there keeps
  // the 64) — both rest on what the rows state.
  test('the row floor follows the cell and lg states its own cell height', () {
    for (final MapEntry(key: size, value: row) in CoreInputOtpStyle.defaultsBySize.entries) {
      expect(
        row.height ?? CoreInputOtpStyle.defaultHeight,
        row.cellHeight ?? row.cellSize ?? CoreInputOtpStyle.defaultCellHeight,
        reason: '${size.name} row floor',
      );
    }
    expect(CoreInputOtpStyle.defaultsBySize[CoreInputOtpSize.lg]!.cellHeight, isNotNull);
  });
}
