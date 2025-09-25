const counters = {};

export async function takeScreenshot(page, functionName) {
  const vu = __VU;
  const iter = __ITER;

  if (!counters[functionName]) {
    counters[functionName] = 1;
  }

  const count = counters[functionName]++;
  const folder = `/screenshots/${functionName}/VU${vu}/Inter${iter}`;

  await page.screenshot({ path: `${folder}/screenshot_${count}_${functionName}.png` });
}
