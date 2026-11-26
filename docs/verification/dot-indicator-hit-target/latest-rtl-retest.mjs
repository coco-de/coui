const task = await taskSpace(40);
const page = task.page('p1');
const evidence = [];
for (let i = 0; i < 3; i++) {
  await page.mouse.move(200,500);
  await page.goto('http://127.0.0.1:19479/');
  await new Promise(r => setTimeout(r,1300));
  const target = await page.evaluate(() => {
    document.documentElement.dir = 'rtl';
    const group = document.querySelectorAll('[role=tablist]')[0];
    const dot = group.querySelectorAll('[role=tab]')[1].firstElementChild;
    const rect = dot.getBoundingClientRect();
    return {x:rect.x+rect.width/2,y:rect.y+rect.height/2,transition:getComputedStyle(dot).transitionProperty};
  });
  await page.mouse.click(target.x,target.y,{label:'RTL first selection'});
  await new Promise(r => setTimeout(r,300));
  const selected = await page.evaluate(() => [...document.querySelectorAll('[role=tablist]')[0].querySelectorAll('[role=tab]')].findIndex(e => e.hasAttribute('aria-current'))+1);
  evidence.push({target,selected});
}
console.log(JSON.stringify(evidence));
