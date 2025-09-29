import 'package:flutter/widgets.dart';

/// WidgetbookGroup 위젯
class WidgetbookGroup extends StatelessWidget {
  /// WidgetbookGroup 생성자
  const WidgetbookGroup({
    required this.label,
    required this.children,
    super.key,
  });

  /// 라벨
  final String label;

  /// 자식 위젯
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textTheme.headlineSmall,
              textAlign: TextAlign.start,
            ),
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
