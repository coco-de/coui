// Prepend OTP_TASK_SPACE (numeric agent-owned space ID) and OTP_FIXTURE_URL
// (local docs fixture URL) declarations before running with ego-browser nodejs.
const task = await taskSpace(OTP_TASK_SPACE);
const page = task.page('p1');
await page.goto(OTP_FIXTURE_URL);
await page.waitForTimeout(5000);
await page.evaluate(() => {
  // Docs also embeds a live Flutter preview, which otherwise steals focus.
  document.querySelectorAll('flutter-view').forEach((element) => element.remove());
  document.querySelectorAll('#default-otp-form, #editing-otp-form').forEach((form) => {
    form.addEventListener('submit', (event) => event.preventDefault());
  });
});
const state = async (type) => page.evaluate((type) => {
  const form = document.querySelector(`#${type}-otp-form`);
  const input = form.querySelector('input');
  return {
    input: input.value,
    visible: form.innerText.split('\n').filter((s) => /^\d$/.test(s)).join(''),
    submitted: document.querySelector(`#${type}-submitted`).innerText,
    rect: input.getBoundingClientRect().toJSON(),
  };
}, type);
const check = (condition, description) => {
  if (!condition) throw new Error(description);
  console.log(`PASS: ${description}`);
};
const submit = async (type) => {
  await page.click(`#${type}-otp-form button`);
  await page.waitForTimeout(100);
  return state(type);
};
const clickSecond = async (rect) => page.mouse.click(rect.x + 70, rect.y + rect.height / 2);
let current = await submit('default');
check(current.input === '123456' && current.visible === current.input && current.submitted === current.input, 'default initial value and submission');
await clickSecond(current.rect);
check(await page.evaluate(() => document.activeElement.selectionStart) === 6, 'default click stays at tail');
await page.keyboard.press('Backspace');
current = await submit('default');
check(current.input === '12345' && current.visible === current.input && current.submitted === current.input, 'default delete and submission');
await clickSecond(current.rect);
await page.keyboard.type('9');
current = await submit('default');
check(current.input === '123459' && current.visible === current.input && current.submitted === current.input, 'default retry and submission');
current = await submit('editing');
check(current.input === '123456' && current.visible === current.input && current.submitted === current.input, 'editing initial value and submission');
await clickSecond(current.rect);
await page.keyboard.type('9');
current = await submit('editing');
check(current.input === '193456' && current.visible === current.input && current.submitted === current.input, 'editing replacement and submission');
await clickSecond(current.rect);
await page.keyboard.press('Backspace');
current = await submit('editing');
check(current.input === '13456' && current.visible === current.input && current.submitted === current.input, 'editing delete and submission');
await clickSecond(current.rect);
await page.keyboard.type('9');
current = await submit('editing');
check(current.input === '19456' && current.visible === current.input && current.submitted === current.input, 'editing retry and submission');
