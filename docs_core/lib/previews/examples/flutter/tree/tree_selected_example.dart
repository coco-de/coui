import 'package:coui_flutter/coui_flutter.dart';

class TreeSelectedExample extends StatelessWidget {
  const TreeSelectedExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tree(
      nodes: [
        CoreTreeNode(
          label: '문서',
          expanded: true,
          children: [
            CoreTreeNode(label: '이력서.pdf', selected: true),
            CoreTreeNode(label: '자기소개서.pdf'),
          ],
        ),
        CoreTreeNode(
          label: '이미지',
          children: [
            CoreTreeNode(label: '사진.png'),
          ],
        ),
      ],
    );
  }
}
