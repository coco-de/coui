import 'dart:math';

import 'package:core/core.dart' hide UseCase;
import 'package:flutter/material.dart';
import 'package:coui_widgetbook/foundation/group.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Spacing 유즈케이스
@UseCase(name: 'Spacing', type: Insets, path: '[Foundation]')
Widget buildWidgetbookSpacingUseCase(BuildContext context) {
  return const WidgetbookGroup(
    label: 'Spacing',
    children: [
      _WidgetbookSpacing(label: 'zero', spacing: Insets.zero),
      _WidgetbookSpacing(label: 'xxSmall', spacing: Insets.xxSmall),
      _WidgetbookSpacing(label: 'xSmall', spacing: Insets.xSmall),
      _WidgetbookSpacing(label: 'small', spacing: Insets.small),
      _WidgetbookSpacing(label: 'medium', spacing: Insets.medium),
      _WidgetbookSpacing(label: 'large', spacing: Insets.large),
      _WidgetbookSpacing(label: 'xLarge', spacing: Insets.xLarge),
      _WidgetbookSpacing(label: 'xxLarge', spacing: Insets.xxLarge),
      _WidgetbookSpacing(label: 'xxxLarge', spacing: Insets.xxxLarge),
    ],
  );
}

/// LineContainer 위젯
class LineContainer extends StatelessWidget {
  /// LineContainer 생성자
  const LineContainer({
    super.key,
    this.lineWidth = 2.0,
    this.lineSpacing = 5.0,
  });

  /// 선 너비
  final double lineWidth;

  /// 선 간격
  final double lineSpacing;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: LinePainter(lineSpacing: lineSpacing, lineWidth: lineWidth),
      ),
    );
  }
}

/// LinePainter 위젯
class LinePainter extends CustomPainter {
  /// LinePainter 생성자
  LinePainter({required this.lineWidth, required this.lineSpacing});

  /// 선 너비
  final double lineWidth;

  /// 선 간격
  final double lineSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE93EB0)
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (
      var x = -max(size.width, size.height);
      x <= max(size.width, size.height) * 2;
      x += lineSpacing
    ) {
      path
        ..moveTo(x, 0)
        ..lineTo(x + size.height, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// WidgetbookSpacing 위젯
class _WidgetbookSpacing extends StatelessWidget {
  /// _WidgetbookSpacing 생성자
  const _WidgetbookSpacing({required this.spacing, required this.label});

  /// 라벨
  final String label;

  /// 간격
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theColor = context.colorScheme.primary;

    return Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: Insets.large),
        Expanded(child: Text(spacing.toString())),
        const SizedBox(width: Insets.large),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  color: theColor,
                ),
                height: Insets.large,
                width: Insets.large,
              ),
              SizedBox(
                height: Insets.large,
                width: spacing,
                child: const LineContainer(),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  color: theColor,
                ),
                height: Insets.large,
                width: Insets.large,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
