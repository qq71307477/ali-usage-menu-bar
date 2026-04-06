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

    // 等待登录成功（检测实际的用量数据）
    let loggedIn = false;
    for (let i = 0; i < 60; i++) {
      await page.waitForTimeout(5000);

      // 检查是否有登录框（如果有说明还没登录）
      const hasLoginForm = await page.evaluate(() => {
        const iframes = document.querySelectorAll('iframe');
        for (const iframe of iframes) {
          if (iframe.title === 'login' || iframe.id?.includes('login')) {
            return true;
          }
        }
        const text = document.body.innerText;
        return text.includes('立即登录') || text.includes('登录以使用');
      });

      if (hasLoginForm) {
        if (i % 6 === 0) {
          console.error(`[登录] 检测到登录界面，等待用户登录... (${Math.floor(i / 12) + 1}/5 分钟)`);
        }
        continue;
      }

      // 检查是否有 SEC_TOKEN（登录后才有）
      const secToken = await page.evaluate(() => {
        if (window.ALIYUN_CONSOLE_CONFIG && window.ALIYUN_CONSOLE_CONFIG.SEC_TOKEN) {
          return window.ALIYUN_CONSOLE_CONFIG.SEC_TOKEN;
        }
        return '';
      });

      // 检查页面是否有真实的用量数字（如百分比或配额数据）
      const hasUsageData = await page.evaluate(() => {
        const text = document.body.innerText;
        // 匹配类似 "近5小时" 和数字百分比
        return /近5小时.*\d+%/.test(text) || /近一月.*\d+%/.test(text) || /额度.*\d+/.test(text);
      });

      if (secToken && hasUsageData) {
        console.error('[登录] 检测到用量数据和 SEC_TOKEN，确认登录成功！');
        loggedIn = true;
        break;
      } else if (secToken) {
        console.error('[登录] 检测到 SEC_TOKEN，等待数据加载...');
      } else if (hasUsageData) {
        console.error('[登录] 检测到用量数据，等待 SEC_TOKEN...');
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