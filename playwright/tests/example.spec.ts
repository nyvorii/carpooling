import { test, expect } from '@playwright/test';


test('debug', async ({ page }) => {
  
  page.on('console', msg => console.log('LOG:', msg.text()));

  await page.goto('http://localhost:8080/');
  await page.pause();
});