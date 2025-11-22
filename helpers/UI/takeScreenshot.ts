const counters: Record<string, number> = {};

export async function takeScreenshot(page: any, functionName: string) {
    const vu = __VU;
    const iter = __ITER;
    const project = __ENV.project || "unknown";

    if (!counters[functionName]) {
        counters[functionName] = 1;
    }

    const count = counters[functionName]++;
    const folder = `/screenshots/${project}/${functionName}/VU${vu}/Inter${iter}`;

    await page.screenshot({ path: `${folder}/screenshot_${count}_${functionName}.png` });
}
