import { prepareUI } from "/helpers/UI/prepareUI.ts";
import { takeScreenshot } from "/helpers/UI/takeScreenshot.ts";
import { basicChecks } from "/helpers/UI/basicChecks.ts";

export const options = {
    setupTimeout: "1m",
    thresholds: {
        checks: ["rate>0.99"],
        browser_web_vital_fcp: ["p(90) < 1800"],
        browser_web_vital_lcp: ["p(90) < 2500"],
        browser_web_vital_ttfb: ["p(90) < 800"],
        browser_web_vital_cls: ["p(90) < 0.250"],
    },
    scenarios: {
        default: {
            executor: "shared-iterations",
            vus: 1,
            iterations: 10,
            maxDuration: "5m",
            exec: "test",
            options: {
                browser: {
                    type: "chromium",
                },
            },
        },
    },
};

export function setup() { }

export async function test() {
    const baseUrl = __ENV.BASEURL;
    const path = "/";
    const url = `${baseUrl}${path}`;
    const testName = "sample-home";

    console.log(`[UI TEST] Full URL: ${url}`);
    console.log(`--- Starting: ${testName} | url: ${url} | ITER ${__ITER} | VU ${__VU} ---`);
    const page = await prepareUI();

    const res = await page.goto(url);

    await takeScreenshot(page, testName);
    await page.waitForLoadState("networkidle");
    await takeScreenshot(page, testName);
    await basicChecks(page, res, testName);
    await page.close();

    console.log(`--- Finished: ${testName} | ITER ${__ITER} | VU ${__VU} ---`);
}
