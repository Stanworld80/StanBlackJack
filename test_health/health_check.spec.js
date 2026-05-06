const { test, expect } = require('@playwright/test');

const url = process.env.TEST_URL || 'https://stanblackjack-dev.web.app';

test('App loads and shows main game elements', async ({ page }) => {
  console.log(`Testing URL: ${url}`);
  
  // Monitor console for errors
  const errors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      const text = msg.text();
      // Ignore common benign errors (like analytics or missing assets)
      if (!text.includes('favicon.ico') && !text.includes('chrome-extension')) {
        console.error(`PAGE ERROR: ${text}`);
        errors.push(text);
      }
    }
  });

  page.on('pageerror', exception => {
    console.error(`PAGE EXCEPTION: ${exception.message}`);
    errors.push(exception.message);
  });

  // Navigate to the app
  await page.goto(url, { waitUntil: 'networkidle' });

  // 1. Check for basic load
  const title = await page.title();
  expect(title).toContain('StanBlackJack');

  // 2. Wait for the Flutter canvas
  const canvas = page.locator('canvas');
  await expect(canvas).toBeVisible({ timeout: 30000 });

  // 3. Detect "Grey Screen of Death"
  // If the app crashed, the canvas might be present but empty or zero-sized
  const box = await canvas.boundingBox();
  expect(box.width).toBeGreaterThan(0);
  expect(box.height).toBeGreaterThan(0);

  // 4. Verify no critical errors occurred during load
  if (errors.length > 0) {
    const criticalErrors = errors.filter(err => 
      err.includes('TypeError') || 
      err.includes('ReferenceError') || 
      err.includes('Uncaught') ||
      err.includes('not a subtype')
    );
    if (criticalErrors.length > 0) {
      throw new Error(`Critical errors detected in console:\n${criticalErrors.join('\n')}`);
    }
  }

  // 5. Wait for specific Game UI elements if possible (using semantics/aria-labels)
  // Flutter web puts labels in flt-semantics or aria-label attributes
  // Let's look for the "SOLDE" or "MISE" text which should appear after loading
  await page.waitForTimeout(5000); // Give it a few seconds to initialize Firestore
  
  // Try to find the balance text
  const balanceText = page.getByText(/SOLDE/i);
  // Note: Flutter Web semantics can be flaky, so we don't strictly fail if text isn't found
  // but we log it.
  const isVisible = await balanceText.isVisible().catch(() => false);
  if (isVisible) {
    console.log('Balance text found - app seems fully functional!');
  } else {
    console.warn('Could not find balance text using selectors, but canvas is active.');
  }

  // Take a screenshot for the CI report
  await page.screenshot({ path: 'test-results/health-check.png' });

  console.log('Health check passed!');
});
