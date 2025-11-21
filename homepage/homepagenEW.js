import { prepareUI } from "../tests/helpers/prepareUI.js";
import { takeScreenshot } from "../tests/helpers/takeScreenshot.js";
import { basicChecks } from "../tests/helpers/basicChecks.js";
import { getTestName } from "../../../helpers/getTestName.js";
import { logTestStatus } from "../../../helpers/logTestStatus.js";

const scenario = __ENV.SCENARIO || "20iter";
export const options = JSON.parse(open(`./configs/${scenario}.json`));

export function setup() {}

export async function quickPizzaHomePageTest() {
  const testName = getTestName(options, scenario);
  const baseUrl = __ENV.QUICKPIZZA_BASE_URL;

  logTestStatus("Starting", testName);

  const page = await prepareUI();

  try {
    await page.goto(baseUrl);

    await takeScreenshot(page, `${testName}-start`);
    await page.waitForLoadState("networkidle");

    await basicChecks(page, testName);

    await takeScreenshot(page, `${testName}-end`);
  } catch (err) {
    console.error(`Error in ${testName}:`, err);
    await takeScreenshot(page, `${testName}-error`);
    throw err;
  } finally {
    await page.close();
    logTestStatus("Finished", testName);
  }
}
