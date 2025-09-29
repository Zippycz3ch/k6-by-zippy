import { prepareUI } from "../../../helpers/prepareUI.js";
import { takeScreenshot } from "../../../helpers/takeScreenshot.js";
import { basicChecks } from "../../../helpers/basicChecks.js";

const scenario = __ENV.SCENARIO || "1iter";
export const options = JSON.parse(open(`./configs/${scenario}.json`));

export function setup() {}

export async function hartmannPrevenceTest() {
  const testName = "hartmannPrevenceTest";
  console.log(`--- Starting: ${testName} | ITER ${__ITER} | VU ${__VU} ---`);
  const page = await prepareUI();

  await page.goto(`${__ENV.K6_BASE_URL_HARTMANB2C}/nase-specializace/prevence-rizik`);
  await takeScreenshot(page, testName);
  await page.waitForLoadState("networkidle");
  await takeScreenshot(page, testName);
  await basicChecks(page, testName);

  await page.close();
  console.log(`--- Finished: ${testName} | ITER ${__ITER} | VU ${__VU} ---`);
}
