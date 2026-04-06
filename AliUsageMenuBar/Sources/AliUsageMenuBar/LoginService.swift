import Foundation

class LoginService {
    static let shared = LoginService()

    private init() {}

    // 获取 scripts 目录路径
    private var scriptsPath: String {
        // 优先检查 .app 包内的 Resources/scripts
        if let resourcePath = Bundle.main.resourcePath {
            let appScripts = URL(fileURLWithPath: resourcePath).appendingPathComponent("scripts").path
            print("[LoginService] 检查 Bundle resourcePath: \(appScripts)")
            if FileManager.default.fileExists(atPath: appScripts) {
                print("[LoginService] ✅ 找到 scripts: \(appScripts)")
                return appScripts
            }
        }

        // 检查 .app 包的可执行文件目录上一级的 Resources/scripts
        let bundlePath = Bundle.main.bundlePath
        let resourcesScripts = URL(fileURLWithPath: bundlePath)
            .appendingPathComponent("Contents")
            .appendingPathComponent("Resources")
            .appendingPathComponent("scripts")
            .path
        print("[LoginService] 检查 bundle Contents/Resources/scripts: \(resourcesScripts)")
        if FileManager.default.fileExists(atPath: resourcesScripts) {
            print("[LoginService] ✅ 找到 scripts: \(resourcesScripts)")
            return resourcesScripts
        }

        // 开发模式：检查相对路径
        let currentDir = FileManager.default.currentDirectoryPath
        print("[LoginService] 当前目录: \(currentDir)")

        let scriptsInCurrent = URL(fileURLWithPath: currentDir)
            .deletingLastPathComponent()
            .appendingPathComponent("scripts")
            .path

        if FileManager.default.fileExists(atPath: scriptsInCurrent) {
            print("[LoginService] ✅ 找到 scripts (开发模式): \(scriptsInCurrent)")
            return scriptsInCurrent
        }

        let scriptsLocal = URL(fileURLWithPath: currentDir).appendingPathComponent("scripts").path
        if FileManager.default.fileExists(atPath: scriptsLocal) {
            print("[LoginService] ✅ 找到 scripts (当前目录): \(scriptsLocal)")
            return scriptsLocal
        }

        // 最后尝试硬编码路径
        let hardcodedPath = "/Applications/阿里云百炼用量.app/Contents/Resources/scripts"
        if FileManager.default.fileExists(atPath: hardcodedPath) {
            print("[LoginService] ✅ 找到 scripts (硬编码): \(hardcodedPath)")
            return hardcodedPath
        }

        print("[LoginService] ❌ 未找到 scripts 目录")
        return currentDir + "/scripts"
    }

    // MARK: - 打开浏览器（不等待）

    func openBrowserForLogin() async throws -> Bool {
        let loginScript = URL(fileURLWithPath: scriptsPath).appendingPathComponent("login.js").path

        print("[LoginService] 登录脚本路径: \(loginScript)")

        guard FileManager.default.fileExists(atPath: loginScript) else {
            print("[LoginService] ❌ 找不到登录脚本")
            throw UsageError.loginFailed("找不到登录脚本: \(loginScript)")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["node", loginScript]

        print("[LoginService] 启动浏览器...")

        try process.run()

        print("[LoginService] ✅ 浏览器进程已启动")
        return true
    }

    // MARK: - 检查是否需要登录

    var needsLogin: Bool {
        return !CookieManager.shared.hasValidCookie
    }
}