"""Regression tests for composition expressed through shared builder helpers."""

import importlib.util
import pathlib
import tempfile
import textwrap
import unittest
from unittest import mock

PATH = pathlib.Path(__file__).with_name('figma_composition_parity.py')
SPEC = importlib.util.spec_from_file_location('composition_guard', PATH)
assert SPEC is not None and SPEC.loader is not None
GUARD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GUARD)


class BuilderCompositionTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.builders = pathlib.Path(directory.name)
        patch = mock.patch.object(GUARD, 'PLUGIN', str(self.builders))
        patch.start()
        self.addCleanup(patch.stop)

    def scan(self, source):
        (self.builders / 'overlay.ts').write_text(
            textwrap.dedent(source), encoding='utf-8'
        )
        return GUARD.satisfied_by_builder().get('HoverCard', set())

    def test_imported_popup_helper_call_credits_popup(self):
        for call in (
            'popupInstance(page)',
            'popupInstance(page, panelStyle.padding)',
            'popupInstance \n(page, panelStyle.padding)',
        ):
            with self.subTest(call=call):
                children = self.scan(
                    "import { popupInstance } from './primitives-chrome';\n"
                    'function buildHoverCard(page) {\n'
                    f'  return {call};\n'
                    '}\n'
                )
                self.assertIn('Popup', children)

    def test_popup_credit_follows_local_helper_calls(self):
        children = self.scan('''
            import { popupInstance } from './primitives-chrome';
            function panel(page) {
              return popupInstance(page, panelStyle.padding);
            }
            function card(page) {
              return panel(page);
            }
            function buildHoverCard(page) {
              return card(page);
            }
        ''')
        self.assertIn('Popup', children)

    def test_comments_do_not_credit_popup(self):
        children = self.scan('''
            function buildHoverCard(page) {
              // popupInstance(page, panelStyle.padding);
              /* instanceOf(page, 'Popup');
                 popupInstance(page); */
              return page;
            }
        ''')
        self.assertNotIn('Popup', children)

    def test_needs_import_and_helper_reference_do_not_credit_popup(self):
        children = self.scan('''
            import { popupInstance } from './primitives-chrome';
            function buildHoverCard(page) {
              const createPopup = popupInstance;
              return page;
            }
            const ENTRIES = [
              { name: 'HoverCard', build: buildHoverCard, needs: ['Popup'] },
            ];
        ''')
        self.assertNotIn('Popup', children)

    def test_similarly_named_calls_do_not_credit_popup(self):
        children = self.scan('''
            function buildHoverCard(page) {
              mypopupInstance(page);
              popupInstanceForPreview(page);
            }
        ''')
        self.assertNotIn('Popup', children)

    def test_unused_helper_does_not_credit_builder(self):
        children = self.scan('''
            function unusedPanel(page) {
              return popupInstance(page);
            }
            function buildHoverCard(page) {
              return page;
            }
        ''')
        self.assertNotIn('Popup', children)

    def test_direct_instances_still_credit_children(self):
        children = self.scan('''
            async function buildHoverCard(page) {
              instanceOf(page, 'Popup', popupVariantName(padding));
              instanceOf(page, 'Button');
            }
        ''')
        self.assertTrue({'Popup', 'Button'} <= children)

    def test_existing_shared_helper_credits_remain_valid(self):
        for call, child in (
            ('hostedDivider(page, lk)', 'Divider'),
            ('setSlotIcon(page, slot, glyph)', 'Icon'),
            ('makeIcon(page, lk)', 'Icon'),
            ('gapSpacer(lk, gap)', 'Gap'),
            ('applyFormRowChrome(row, lk, style)', 'Gap'),
            ('pinAbsolute(parent, child, x, y)', 'Stacks'),
            ('overlayGlyph(parent, glyph, x, y)', 'Stacks'),
            ('iconSlot(lk, name, glyph, color, size)', 'Stacks'),
            ('addFocusRing(parent, lk, style)', 'FocusOutline'),
        ):
            with self.subTest(call=call):
                children = self.scan(
                    '\nfunction buildHoverCard(page) {\n'
                    f'  {call};\n'
                    '}\n'
                )
                self.assertIn(child, children)

    def test_imported_positioning_reference_does_not_credit_stacks(self):
        for helper in ('overlayGlyph', 'iconSlot'):
            with self.subTest(helper=helper):
                children = self.scan(
                    f"import {{ {helper} }} from '../drawing-helper';\n"
                    f'function buildHoverCard(page) {{ return {helper}; }}\n'
                )
                self.assertNotIn('Stacks', children)


if __name__ == '__main__':
    unittest.main()
