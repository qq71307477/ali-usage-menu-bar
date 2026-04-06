# 阿里云百炼 Coding Plan 用量监控

macOS 菜单栏应用，监控阿里云百炼 Coding Plan API 用量。

## 功能

- 显示近5小时/周/月用量百分比
- 自动刷新（5分钟间隔）
- Playwright 自动登录（有头模式）
- Cookie 持久化，过期自动重新登录

## 系统要求

- macOS 12.0+ (Monterey)
- Node.js 18+

## 构建

```bash
cd AliUsageMenuBar
swift build
swift run
```

## 配置

1. 点击设置按钮
2. 输入阿里云手机号和密码
3. 点击"测试登录"，浏览器会打开让你完成登录
4. 后续自动使用保存的 Cookie

## 工作原理

1. 首次使用：打开浏览器登录，保存 Cookie 到本地
2. 日常使用：直接 HTTP 请求获取用量（无需浏览器）
3. Cookie 过期：自动打开浏览器重新登录