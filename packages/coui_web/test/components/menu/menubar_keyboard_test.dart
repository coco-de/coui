// `role="menubar"` promises the WAI-ARIA menubar keys (#3968 · #4154): the
// bar is one tab stop and Left/Right walk its triggers. This pins what the
// markup needs for that — exactly one trigger at `tabindex="0"`, each
// carrying a roving marker — and that the bar still states its axis.
//
// The key → index arithmetic is pinned in `base/roving_focus_test.dart`;
// the live keydown dispatch is not — `universal_web`'s `KeyboardEvent.key`
// throws on the VM this suite runs on.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

void main() {
  testServer('the menubar is one tab stop — the first trigger — and every '
      'trigger carries a roving marker', (tester) async {
    tester.pumpComponent(
      _host(
        Menubar(
          menus: [
            CoreMenubarMenu(
              label: 'File',
              entries: [CoreMenubarEntry.action(label: 'New', onSelect: () {})],
            ),
            CoreMenubarMenu(
              label: 'Edit',
              entries: [
                CoreMenubarEntry.action(label: 'Undo', onSelect: () {}),
              ],
            ),
            CoreMenubarMenu(
              label: 'View',
              entries: [
                CoreMenubarEntry.action(label: 'Zoom', onSelect: () {}),
              ],
            ),
          ],
        ),
      ),
    );
    final document = (await tester.request('/')).document!;
    final bar = document.querySelector('[role="menubar"]')!;
    final triggers = bar.querySelectorAll('[role="menuitem"]');

    expect(bar.attributes['aria-orientation'], 'horizontal');
    expect(triggers.map((e) => e.attributes['tabindex']), ['0', '-1', '-1']);
    expect(
      triggers.map((e) => e.attributes['data-roving-item']!.split(':').last),
      ['0', '1', '2'],
    );
  });
}
