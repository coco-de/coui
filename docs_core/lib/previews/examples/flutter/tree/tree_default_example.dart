import 'package:coui_flutter/coui_flutter.dart';

class TreeDefaultExample extends StatelessWidget {
  const TreeDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tree(
      nodes: [
        CoreTreeNode(
          label: '문서',
          expanded: true,
          children: [
            CoreTreeNode(label: '이력서.pdf'),
            CoreTreeNode(label: '자기소개서.pdf'),
          ],
        ),
        CoreTreeNode(
          label: '이미지',
          children: [
            CoreTreeNode(label: '사진.png'),
            CoreTreeNode(label: '배너.jpg'),
          ],
        ),
        CoreTreeNode(label: 'README.md'),
      ],
    );
  }
}
