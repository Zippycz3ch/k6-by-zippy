import { prepareUI } from "/helpers/prepareUI.js";
import { takeScreenshot } from "/helpers/takeScreenshot.js";
import { basicChecks } from "/helpers/basicChecks.js";

const scenario = __ENV.SCENARIO;
const testType = __ENV.testType;
const project = __ENV.project;
const configPath = `./${testType}/configs/${scenario}.json`;
const configRaw = open(configPath);
const config = JSON.parse(configRaw);
export const options = config;

export function setup() {}

export async function test() {
  const url = __ENV.url;
  const testName = __ENV.testName;

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
