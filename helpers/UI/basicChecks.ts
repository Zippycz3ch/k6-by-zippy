import { check } from "k6";

export async function basicChecks(page: any, response: any, testName: string) {
    const title = await page.title();
    const bodyElement = await page.$("body");

    check(page, {
        [`${testName} - body exists`]: () => bodyElement !== null,
    });
}
