// Run with ego-browser nodejs < rtl-transition-check.mjs after serving the
// baseline and fixed integrated preview builds at ports 19477 and 19478.
// Outputs trusted pointer events and selection after an immediate RTL switch.
const task = await taskSpace('CoUI RTL transition verification');
const page = task.page('p1');
const evidence = [];
for (const mode of ['before', 'after']) {
  for (let iteration = 0; iteration < 3; iteration++) {
    await page.mouse.move(200, 500);
    await page.goto(`http://127.0.0.1:${mode === 'before' ? 19477 : 19478}/`);
    await new Promise((resolve) => setTimeout(resolve, 1300));
    const target = await page.evaluate(() => {
      const group = document.querySelectorAll('[role=tablist]')[0];
      window.__pointerEvents = [];
      for (const type of ['pointerdown', 'pointerup', 'click']) {
        document.addEventListener(type, (event) => {
          window.__pointerEvents.push({
            type: event.type,
            target: event.target.closest('[role=tab]')?.getAttribute('aria-label') ?? null,
          });
        }, true);
      }
      document.documentElement.dir = 'rtl';
      const dot = group.querySelectorAll('[role=tab]')[1].firstElementChild;
      const rect = dot.getBoundingClientRect();
      return {
        x: rect.x + rect.width / 2,
        y: rect.y + rect.height / 2,
        rects: [...group.querySelectorAll('[role=tab]>div')].map((element) => {
          const box = element.getBoundingClientRect();
          return { x: box.x, width: box.width };
        }),
      };
    });
    await page.mouse.click(target.x, target.y, { label: 'RTL first dot selection' });
    await new Promise((resolve) => setTimeout(resolve, 300));
    const result = await page.evaluate(() => ({
      selected: [...document.querySelectorAll('[role=tablist]')[0].querySelectorAll('[role=tab]')]
        .findIndex((element) => element.hasAttribute('aria-current')) + 1,
      events: window.__pointerEvents,
    }));
    evidence.push({ mode, iteration, ...target, ...result });
  }
}
console.log(JSON.stringify(evidence, null, 2));
await task.finish({ keep: [] });
