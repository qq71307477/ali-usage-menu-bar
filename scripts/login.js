#!/usr/bin/env node

import { chromium } from 'playwright';
import { writeFileSync, existsSync, mkdirSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const LOGIN_URL = 'https://bailian.console.aliyun.com/cn-beijing/?tab=coding-plan';

// 账号密码参数（可选，用于提示用户）
const username = process.argv[2] || process.env.ALIYUN_USERNAME || '';
const password = process.argv[3] || process.env.ALIYUN_PASSWORD || '';

async function login() {
  let browser = null;

  try {
    console.error('[登录] 启动浏览器...');

    browser = await chromium.launch({
      headless: false,
      channel: 'chrome',  // 使用本机安装的 Chrome
      args: [
        '--no-sandbox',
        '--disable-blink-features=AutomationControlled'
      ]
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
    await page.goto(LOGIN_URL, { waitUntil: 'domcontentloaded', timeout: 30000 });
    await page.waitForTimeout(3000);

    // 检查是否需要登录
    const needsLogin = await checkNeedsLogin(page);

    if (needsLogin) {
      console.error('[登录] 请在浏览器中手动完成登录（包括验证码）...');
      console.error('[登录] 登录成功后会自动提取 Cookie');

      // 等待登录完成（最多 5 分钟）
      for (let i = 0; i < 30; i++) {
        await page.waitForTimeout(10000);
        if (!await checkNeedsLogin(page)) {
          console.error('[登录] 检测到登录成功！');
          break;
        }
        if (i % 3 === 0) {
          console.error(`[登录] 等待登录完成... (${Math.floor(i / 6) + 1}/5 分钟)`);
        }
      }
    }

    // 获取 Cookie
    const cookies = await context.cookies();
    const cookieString = cookies.map(c => `${c.name}=${c.value}`).join('; ');

    // 从页面获取 sec_token
    const secToken = await page.evaluate(() => {
      if (window.ALIYUN_CONSOLE_CONFIG && window.ALIYUN_CONSOLE_CONFIG.SEC_TOKEN) {
        return window.ALIYUN_CONSOLE_CONFIG.SEC_TOKEN;
      }
      return '';
    });

    // 保存到文件（与 Swift 共享）
    const cookieFile = join(homedir(), 'Library', 'Application Support', 'AliUsageMenuBar', 'cookies.json');
    const cookieDir = join(homedir(), 'Library', 'Application Support', 'AliUsageMenuBar');

    if (!existsSync(cookieDir)) {
      mkdirSync(cookieDir, { recursive: true });
    }

    writeFileSync(cookieFile, JSON.stringify({
      cookies: cookieString,
      secToken: secToken
    }, null, 2));

    console.error('[登录] Cookie 已保存');

    // 输出 JSON 供 Swift 读取
    console.log(JSON.stringify({
      success: true,
      cookieFile: cookieFile
    }));

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

async function checkNeedsLogin(page) {
  try {
    const loginIframe = await page.$('iframe[title="login"]');
    if (loginIframe) return true;

    const bodyText = await page.evaluate(() => document.body.innerText);
    if (bodyText.includes('登录以使用') || bodyText.includes('立即登录')) {
      return true;
    }

    // 检查是否有用量数据
    if (bodyText.includes('近5小时用量')) {
      return false;
    }

    return true;
  } catch {
    return true;
  }
}

login();