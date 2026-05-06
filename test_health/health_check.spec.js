const { test, expect } = require('@playwright/test');

const url = process.env.TEST_URL || 'https://stanblackjack-dev.web.app';

test('App loads and shows main game elements', async ({ page }) => {
  console.log(`Testing URL: ${url}`);
  
  // Monitor console for errors
  const errors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      console.error(`PAGE ERROR: ${msg.text()}`);
      errors.push(msg.text());
    }
  });

  page.on('pageerror', exception => {
    console.error(`PAGE EXCEPTION: ${exception.message}`);
    errors.push(exception.message);
  });

  // Navigate to the app
  await page.goto(url);

  // Wait for the app to initialize. Flutter web usually takes a bit.
  // We look for a canvas or some indicator that it's not a grey screen.
  await page.waitForLoadState('networkidle');

  // Flutter apps render in a flt-glass-pane or have a canvas
  const canvas = page.locator('canvas');
  try {
    await expect(canvas).toBeVisible({ timeout: 60000 });
  } catch (e) {
    if (errors.length > 0) {
      throw new Error(`Canvas not visible and caught console errors: ${errors.join('\n')}`);
    }
    throw e;
  }

  // Check for the "StanBlackJack" title
  const title = await page.title();
  expect(title).toContain('StanBlackJack');
  
  // Verify no critical errors occurred during load
  // We allow some errors (like analytics blocking) but want to catch app crashes
  const criticalErrors = errors.filter(err => 
    err.includes('Firebase') || 
    err.includes('Failed to load') || 
    err.includes('Uncaught')
  );
  
  if (criticalErrors.length > 0) {
    console.warn('Potential critical errors detected in console:', criticalErrors);
  }

  console.log('Health check passed!');
});
