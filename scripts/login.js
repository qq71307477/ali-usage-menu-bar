#!/usr/bin/env node

import { chromium } from 'playwright';
import { writeFileSync, existsSync, mkdirSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const LOGIN_URL = 'https://bailian.console.aliyun.com/cn-beijing/?tab=coding-plan#/efm/coding-plan-detail';

async function login() {
  let browser = null;

  try {
    console.error('[登录] 启动浏览器...');

    browser = await chromium.launch({
      headless: false,
      channel: 'chrome',
      args: ['--no-sandbox', '--disable-blink-features=AutomationControlled']
    });

    const context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    });

    // 隐藏 webdriver 特征
    await context.addInitScript(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    });

    const page = await context.newPage();

    console.error('[登录] 打开百炼控制台...');
    await page.goto(LOGIN_URL, { waitUntil: 'networkidle', timeout: 60000 });

    console.error('[登录] 请在浏览器中完成登录...');
    console.error('[登录] 登录成功后会自动检测并保存 Cookie');

    // 等待登录成功（检测 sec_token 或用量数据）
    let loggedIn = false;
    for (let i = 0; i < 60; i++) {
      await page.waitForTimeout(5000);

      // 检查是否有 sec_token
      const secToken = await page.evaluate(() => {
        if (window.ALIYUN_CONSOLE_CONFIG && window.ALIYUN_CONSOLE_CONFIG.SEC_TOKEN) {
          return window.ALIYUN_CONSOLE_CONFIG.SEC_TOKEN;
        }
        return '';
      });

      if (secToken) {
        console.error('[登录] 检测到 SEC_TOKEN，登录成功！');
        loggedIn = true;
        break;
      }

      // 检查页面是否有用量数据
      const hasData = await page.evaluate(() => {
        const text = document.body.innerText;
        return text.includes('近5小时') || text.includes('用量') || text.includes('Coding Plan');
      });

      if (hasData) {
        console.error('[登录] 检测到用量数据，登录成功！');
        loggedIn = true;
        break;
      }

      if (i % 6 === 0) {
        console.error(`[登录] 等待登录... (${Math.floor(i / 12) + 1}/5 分钟)`);
      }
    }

    if (!loggedIn) {
      console.error('[登录] 超时未检测到登录成功');
      console.log(JSON.stringify({ success: false, error: '登录超时' }));
      process.exit(1);
    }

    // 获取 Cookie
    const cookies = await context.cookies();
    const cookieString = cookies.map(c => `${c.name}=${c.value}`).join('; ');

    // 获取 sec_token
    const secToken = await page.evaluate(() => {
      if (window.ALIYUN_CONSOLE_CONFIG && window.ALIYUN_CONSOLE_CONFIG.SEC_TOKEN) {
        return window.ALIYUN_CONSOLE_CONFIG.SEC_TOKEN;
      }
      return '';
    });

    // 保存到文件
    const cookieDir = join(homedir(), 'Library', 'Application Support', 'AliUsageMenuBar');
    if (!existsSync(cookieDir)) {
      mkdirSync(cookieDir, { recursive: true });
    }

    const cookieFile = join(cookieDir, 'cookies.json');
    writeFileSync(cookieFile, JSON.stringify({
      cookies: cookieString,
      secToken: secToken
    }, null, 2));

    console.error('[登录] Cookie 已保存到:', cookieFile);
    console.log(JSON.stringify({ success: true, cookieFile }));

  } catch (error) {
    console.error('[登录] 错误:', error.message);
    console.log(JSON.stringify({ success: false, error: error.message }));
    process.exit(1);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

login();