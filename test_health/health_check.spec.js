const { test, expect } = require('@playwright/test');

const url = process.env.TEST_URL || 'https://stanblackjack-dev.web.app';

test('App loads and shows main game elements', async ({ page }) => {
  console.log(`Testing URL: ${url}`);
  
  // Navigate to the app
  await page.goto(url);

  // Wait for the app to initialize. Flutter web usually takes a bit.
  // We look for a canvas or some indicator that it's not a grey screen.
  await page.waitForLoadState('networkidle');

  // Flutter apps render in a flt-glass-pane or have a canvas
  const canvas = page.locator('canvas');
  await expect(canvas).toBeVisible({ timeout: 45000 });

  // In Flutter Web, we can't always easily find text in the DOM if it's rendered in canvas
  // but if semantics is enabled, we can.
  // For a basic health check, checking for the canvas and no errors is a good start.
  // Let's also check for the "StanBlackJack" title if it exists in the DOM
  const title = await page.title();
  expect(title).toContain('StanBlackJack');
  
  console.log('Health check passed!');
});
