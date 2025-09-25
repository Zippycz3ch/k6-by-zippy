import { prepareUI } from "../../../helpers/prepareUI.js";
import { takeScreenshot } from "../../../helpers/takeScreenshot.js";
import { basicChecks } from "../../../helpers/basicChecks.js";

const scenario = __ENV.SCENARIO || "1iter";
export const options = JSON.parse(open(`./configs/${scenario}.json`));

export function setup() {}

export async function quickPizzaHomePageTest() {
  const testName = "quickPizzaHomePageTest";
  console.log(`--- Starting: ${testName} | ITER ${__ITER} | VU ${__VU} ---`);
  const page = await prepareUI();

  try {
    await page.goto("http://host.docker.internal:3333");
    await takeScreenshot(page, testName);
    await page.waitForLoadState("networkidle");
    await takeScreenshot(page, testName);
await basicChecks(page, testName);
  } catch (err) {    console.error(`${testName} failed:`, err);
  } finally {
    await page.close();
    console.log(`--- Finished: ${testName} | ITER ${__ITER} | VU ${__VU} ---`);
  }
}
