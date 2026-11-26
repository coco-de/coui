import 'package:coui_web/coui_web.dart';

class TreeDefaultExample extends StatelessComponent {
  const TreeDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Tree(
      nodes: const [
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
