import Foundation

class LoginService {
    static let shared = LoginService()

    private init() {}

    // 获取 scripts 目录路径
    private var scriptsPath: String {
        // 优先检查 .app 包内的 Resources/scripts
        if let resourcePath = Bundle.main.resourcePath {
            let appScripts = URL(fileURLWithPath: resourcePath).appendingPathComponent("scripts").path
            if FileManager.default.fileExists(atPath: appScripts) {
                return appScripts
            }
        }

        // 开发模式：检查相对路径
        let currentDir = FileManager.default.currentDirectoryPath
        let scriptsInCurrent = URL(fileURLWithPath: currentDir)
            .deletingLastPathComponent()
            .appendingPathComponent("scripts")
            .path

        if FileManager.default.fileExists(atPath: scriptsInCurrent) {
            return scriptsInCurrent
        }

        let scriptsLocal = URL(fileURLWithPath: currentDir).appendingPathComponent("scripts").path
        if FileManager.default.fileExists(atPath: scriptsLocal) {
            return scriptsLocal
        }

        return currentDir + "/scripts"
    }

    // MARK: - 打开浏览器（不等待）

    func openBrowserForLogin() async throws -> Bool {
        let loginScript = URL(fileURLWithPath: scriptsPath).appendingPathComponent("login.js").path

        guard FileManager.default.fileExists(atPath: loginScript) else {
            throw UsageError.loginFailed("找不到登录脚本: \(loginScript)")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["node", loginScript]

        print("[LoginService] 启动浏览器...")
        print("[LoginService] 脚本路径: \(loginScript)")

        try process.run()

        // 不等待，让浏览器在后台运行
        return true
    }

    // MARK: - 检查是否需要登录

    var needsLogin: Bool {
        return !CookieManager.shared.hasValidCookie
    }
}