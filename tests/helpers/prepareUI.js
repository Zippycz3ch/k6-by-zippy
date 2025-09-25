import { browser } from "k6/browser";

export async function prepareUI() {
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.setViewportSize({
    width: 1920,
    height: 1080,
  });

  return page;
}
