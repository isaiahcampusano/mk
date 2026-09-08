import { expect, test } from "@playwright/test";

test("exported selection flow preserves roster and loadout", async ({ page }) => {
  const runtimeErrors = [];
  page.on("pageerror", (error) => runtimeErrors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") runtimeErrors.push(message.text());
  });

  await page.goto("/index.html?smoke_test=1");
  await page.waitForFunction(() => window.__mkSmoke?.stage === "character_select");
  let status = await page.evaluate(() => window.__mkSmoke);
  expect(status).toMatchObject({
    stage: "character_select",
    catalog_valid: true,
    character_count: 4,
    card_count: 4,
  });

  await page.locator("canvas").click({ position: { x: 10, y: 10 } });
  await page.keyboard.press("ArrowRight");
  await page.keyboard.press("Enter");
  await page.waitForFunction(() => window.__mkSmoke?.stage === "vehicle_select");
  status = await page.evaluate(() => window.__mkSmoke);
  expect(status).toMatchObject({
    stage: "vehicle_select",
    catalog_valid: true,
    vehicle_count: 4,
    card_count: 4,
  });

  await page.keyboard.press("ArrowRight");
  await page.keyboard.press("Enter");
  await page.waitForFunction(() => window.__mkSmoke?.stage === "race");
  status = await page.evaluate(() => window.__mkSmoke);
  expect(status).toMatchObject({
    stage: "race",
    catalog_valid: true,
    kart_count: 6,
    character_id: "rook_ember",
    vehicle_id: "slidewinder",
    model_profile: 3,
    body_size: [24, 6, 29],
    body_color: "6bdb7aff",
    driver_color: "ff6b52ff",
  });
  expect(status.top_speed).toBeCloseTo(354.1125, 3);
  expect(status.acceleration).toBeCloseTo(221.1125, 3);
  expect(status.turn_rate).toBeCloseTo(2.567375, 3);
  expect(status.drift_turn_rate).toBeCloseTo(3.99855, 3);
  expect(status.drift_min_speed).toBeCloseTo(100, 3);
  expect(runtimeErrors).toEqual([]);
});
