import { browser } from 'k6/experimental/browser';
import { check } from 'k6';

export const options = {
    scenarios: {
        ui: {
            executor: 'constant-vus',
            exec: 'browsertest',
            vus: 4,
            duration: '30s',
            gracefulStop: '0s',
            options: {
                browser: {
                    type: 'chromium',
                },
            },
        },
    },
    thresholds: {
        checks: ["rate==1.0"]
    }
}

export async function browsertest() {
    const context = browser.newContext();
    const page = context.newPage();

    try {
        await page.goto('https://test.k6.io/my_messages.php');

        page.locator('input[name="login"]').type('admin');
        page.locator('input[name="password"]').type('123');

        const submitButton = page.locator('input[type="submit"]');

        await Promise.all([page.waitForNavigation(), submitButton.click()]);

        check(page, {
            'header': p => p.locator('h2').textContent() == 'Welcome, admin!',
        });
    } finally {
        page.close();
    }
}
