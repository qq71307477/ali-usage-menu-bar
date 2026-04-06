# 阿里云百炼 Coding Plan 用量监控

macOS 菜单栏应用，监控阿里云百炼 Coding Plan API 用量百分比。

## 功能

- 菜单栏实时显示近5小时用量百分比
- 点击图标查看详细用量（周/月）
- 每5分钟自动刷新数据
- 启动时自动获取最新用量
- Playwright + Chrome 自动登录
- Cookie 持久化存储
- 支持退出登录重新授权
- 应用退出时自动清理后台进程

## 系统要求

- macOS 12.0+ (Monterey)
- Node.js 18+
- Chrome 浏览器

## 安装

### 1. 安装依赖

```bash
cd scripts
npm install
npx playwright install chromium
```

### 2. 构建 .app 包

```bash
cd AliUsageMenuBar
swift build -c release
./build-app.sh
```

### 3. 安装到 Applications

```bash
cp -r ".build/阿里云百炼用量.app" /Applications/
codesign --force --deep --sign - "/Applications/阿里云百炼用量.app"
```

或直接双击 `.build/阿里云百炼用量.app` 运行。

## 使用方法

1. 打开应用，菜单栏显示用量百分比
2. 点击图标查看详细用量信息
3. 首次使用需点击"打开浏览器登录"
4. 在浏览器中完成阿里云账号登录
5. 登录成功后点击"我已登录完成"
6. 数据自动刷新显示

## 数据存储

Cookie 保存在：`~/Library/Application Support/AliUsageMenuBar/cookies.json`

有效期约12小时，过期后需重新登录。

## 开发

```bash
cd AliUsageMenuBar
swift build
swift run
```

## 工作原理

1. **登录流程**：Playwright 打开 Chrome 浏览器，用户手动登录后自动提取 Cookie 和 SEC_TOKEN
2. **数据获取**：通过 HTTP API 直接请求用量数据（无需浏览器）
3. **定时刷新**：每5分钟自动更新，启动时立即获取最新数据
4. **进程管理**：应用退出时自动清理残留的 login.js 进程