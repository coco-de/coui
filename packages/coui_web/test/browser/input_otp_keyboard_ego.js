// Prepend OTP_TASK_SPACE (numeric owned space) and OTP_FIXTURE_URL (local
// fixture with its Flutter embed excluded) before running via ego-browser.
const task = await taskSpace(OTP_TASK_SPACE);
const page = task.page('p1');
await page.goto(OTP_FIXTURE_URL);
await page.waitForTimeout(4000);
const state = () => page.evaluate(() => ({
  value: document.activeElement.value,
  start: document.activeElement.selectionStart,
  end: document.activeElement.selectionEnd,
}));
const check = (ok, message) => {
  if (!ok) throw new Error(message);
  console.log(`PASS: ${message}`);
};
const field = await page.evaluate(() => {
  const form = document.querySelector('#editing-otp-form');
  const inputs = form.querySelectorAll('input');
  const cells = [...form.querySelectorAll('[data-otp-cell]')];
  const box = cells[1].getBoundingClientRect();
  return {
    inputCount: inputs.length,
    autocomplete: inputs[0].autocomplete,
    label: inputs[0].getAttribute('aria-label'),
    hiddenCells: cells.every((cell) => cell.getAttribute('aria-hidden') === 'true'),
    x: box.x + box.width / 2,
    y: box.y + box.height / 2,
  };
});
check(field.inputCount === 1 && field.autocomplete === 'one-time-code' && !!field.label && field.hiddenCells,
  'one labelled OTP input and decorative visual cells');
await page.mouse.click(field.x, field.y);
let selected = await state();
check(selected.start === 1 && selected.end === 2, 'pointer selects the second digit');
await page.keyboard.press('ArrowLeft');
await page.waitForTimeout(100);
selected = await state();
check(selected.start === 1 && selected.end === 1, 'left arrow collapses selection at its beginning');
await page.keyboard.press('ArrowRight');
await page.waitForTimeout(100);
selected = await state();
check(selected.start === 2 && selected.end === 2 && selected.value === '123456',
  'right arrow moves the caret without changing the value');
