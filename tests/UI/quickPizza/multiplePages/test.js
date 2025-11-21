import { prepareUI } from "../../../helpers/prepareUI.js";
import { takeScreenshot } from "../../../helpers/takeScreenshot.js";
import { basicChecks } from "../../../helpers/basicChecks.js";

const scenario = __ENV.SCENARIO || "1iter";
const configRaw = open(`./configs/${scenario}.json`);
const config = JSON.parse(configRaw);
export const options = config;

export function setup() {}

export async function test() {
  const urlPath = __ENV.urlPath || "/";
  const testName = __ENV.testName;

  console.log(`--- Starting: ${testName} | urlPath: ${urlPath} | ITER ${__ITER} | VU ${__VU} ---`);
  const page = await prepareUI();

  const res = await page.goto(__ENV.QUICKPIZZA_BASE_URL + urlPath);
  await page.waitForLoadState("networkidle");
  await takeScreenshot(page, testName);
  await basicChecks(page, res, testName);
  await page.close();

  console.log(`--- Finished: ${testName} | ITER ${__ITER} | VU ${__VU} ---`);
}
