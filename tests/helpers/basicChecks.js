import { check } from "k6";

export async function basicChecks(page, testName) {
  const content = await page.content();
  const titleMatch = content.match(/<title>(.*?)<\/title>/i);
  const title = titleMatch ? titleMatch[1] : "";
  const bodyExists = /<body[^>]*>.*<\/body>/is.test(content);

  check(page, {
    [`-${testName} - page content is not null`]: () => content !== null && content.length > 0,
    [`-${testName} - <title> exists and is not empty`]: () => title.length > 0,
    [`-${testName} - <body> exists`]: () => bodyExists,
  });
}
