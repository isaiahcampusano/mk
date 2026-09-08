import { defineConfig } from "@playwright/test";

export default defineConfig({
  timeout: 60_000,
  expect: { timeout: 30_000 },
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI
    ? [["github"], ["html", { open: "never", outputFolder: ".artifacts/playwright-report" }]]
    : "list",
  outputDir: ".artifacts/test-results",
  use: {
    baseURL: "http://127.0.0.1:8060",
    viewport: { width: 1280, height: 720 },
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
  },
  webServer: {
    command: "node tests/web_server.mjs",
    url: "http://127.0.0.1:8060/index.html",
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
