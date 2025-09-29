import 'package:core/core.dart' hide UseCase;
import 'package:flutter/material.dart';
import 'package:coui_widgetbook/foundation/group.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// ConfirmationDialog 유즈케이스
@UseCase(name: 'Dialog', type: ConfirmationDialog, path: '[Component]')
Widget buildWidgetbookButtonUseCase(BuildContext context) {
  return WidgetbookGroup(
    label: '다이얼로그',
    children: [
      WidgetbookDialog(
        dialog: ConfirmationDialog(
          message: context.i10n.common_dialog.min_update.message,
          positiveButtonText: context.i10n.common_dialog.min_update.positive,
          title: context.i10n.common_dialog.min_update.title,
        ),
        label: '강제 업데이트 안내',
      ),
      WidgetbookDialog(
        dialog: ConfirmationDialog(
          message: context.i10n.common_dialog.latest_update.message,
          negativeButtonText: context.i10n.common_dialog.latest_update.negative,
          positiveButtonText: context.i10n.common_dialog.latest_update.positive,
          title: context.i10n.common_dialog.latest_update.title,
        ),
        label: '업데이트 안내',
      ),
      WidgetbookDialog(
        dialog: ConfirmationDialog(
          alignment: CrossAxisAlignment.center,
          message: context.i10n.common_dialog.marketing.message,
          negativeButtonText: context.i10n.common_dialog.marketing.negative,
          positiveButtonText: context.i10n.common_dialog.marketing.positive,
          title: context.i10n.common_dialog.marketing.title,
          titleWidget: Assets.images.alertImage.image(height: 100),
        ),
        label: '마케팅 이벤트 수신 동의',
      ),
      WidgetbookDialog(
        dialog: ConfirmationDialog(
          footer: context.i10n.settings.dialog.marketing.contents(
            date: DateFormat('yyyy년 MM월 dd일').format(DateTime.now()),
          ),
          positiveButtonText: context.i10n.settings.dialog.marketing.positive,
          title: context.i10n.settings.dialog.marketing.title(
            agree: context.knobs.boolean(label: '동의여부') ? '동의' : '거부',
          ),
        ),
        label: '마케팅 이벤트 수신 동의',
      ),
      WidgetbookDialog(
        dialog: ConfirmationDialog(
          message: context.i10n.common_dialog.no_internet_connection.message,
          positiveButtonText:
              context.i10n.common_dialog.no_internet_connection.positive,
          title: context.i10n.common_dialog.no_internet_connection.title,
        ),
        label: '인터넷 연결 유실',
      ),
      WidgetbookDialog(
        dialog: ConfirmationDialog(
          message: context.i10n.withdraw.dialog.alert.contents,
          positiveButtonText: context.i10n.withdraw.dialog.alert.positive,
          title: context.i10n.withdraw.dialog.alert.title,
        ),
        label: '탈퇴하기',
      ),
    ],
  );
}

/// WidgetbookDialog 위젯
class WidgetbookDialog extends StatelessWidget {
  /// WidgetbookDialog 생성자
  const WidgetbookDialog({
    required this.label,
    required this.dialog,
    super.key,
  });

  /// 라벨
  final String label;

  /// 다이얼로그
  final ConfirmationDialog dialog;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Insets.xxSmall),
      child: Column(
        children: [
          Text(label, style: context.textTheme.titleMedium),
          Gap.xxSmall(),
          dialog,
        ],
      ),
    );
  }
}
