import { prepareUI } from "/helpers/UI/prepareUI.ts";
import { takeScreenshot } from "/helpers/UI/takeScreenshot.ts";
import { basicChecks } from "/helpers/UI/basicChecks.ts";

const scenario = __ENV.SCENARIO;
const configPath = `./configs/${scenario}.json`;
const configRaw = open(configPath);
const config = JSON.parse(configRaw);
export const options = config;

export function setup() {}

export async function test() {
  const baseUrl = __ENV.BASEURL;
  const path = __ENV.path || "/";
  const testName = __ENV.testName;
  const url = `${baseUrl}${path}`;

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
