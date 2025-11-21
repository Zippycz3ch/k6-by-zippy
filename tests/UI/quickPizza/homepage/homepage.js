import { prepareUI } from "../../../helpers/prepareUI.js";
import { takeScreenshot } from "../../../helpers/takeScreenshot.js";
import { basicChecks } from "../../../helpers/basicChecks.js";

const scenario = __ENV.SCENARIO || "1iter";
const configRaw = open(`./configs/${scenario}.json`);
const config = JSON.parse(configRaw);
export const options = config;

export function setup() {}

export async function quickPizzaHomePageTest() {
  const testName = "quickPizzaHomePageTest";
  console.log(`--- Starting: ${testName} | ITER ${__ITER} | VU ${__VU} ---`);
  const page = await prepareUI();

  try {
    await page.goto("https://hartmanndirect.com/cs-cz");
    await takeScreenshot(page, testName);
    await page.waitForLoadState("networkidle");
    await basicChecks(page, testName);
    await takeScreenshot(page, testName);
  } finally {
    await page.close();
    console.log(`--- Finished: ${testName} | ITER ${__ITER} | VU ${__VU} ---`);
  }
}
