import Foundation

class LoginService {
    static let shared = LoginService()

    private init() {}

    // 获取 scripts 目录路径
    private var scriptsPath: String {
        // 开发时使用相对路径
        let currentDir = FileManager.default.currentDirectoryPath
        let scriptsInCurrent = URL(fileURLWithPath: currentDir)
            .deletingLastPathComponent()
            .appendingPathComponent("scripts")
            .path

        if FileManager.default.fileExists(atPath: scriptsInCurrent) {
            return scriptsInCurrent
        }

        // 尝试当前目录下的 scripts
        let scriptsLocal = URL(fileURLWithPath: currentDir).appendingPathComponent("scripts").path
        if FileManager.default.fileExists(atPath: scriptsLocal) {
            return scriptsLocal
        }

        return currentDir + "/scripts"
    }

    // MARK: - 执行登录

    func performLogin(username: String, password: String) async throws -> Bool {
        let loginScript = URL(fileURLWithPath: scriptsPath).appendingPathComponent("login.js").path

        guard FileManager.default.fileExists(atPath: loginScript) else {
            throw UsageError.loginFailed("找不到登录脚本: \(loginScript)")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["node", loginScript, username, password]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        print("[LoginService] 执行登录脚本...")

        try process.run()
        process.waitUntilExit()

        // 读取输出
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if let errorOutput = String(data: errorData, encoding: .utf8), !errorOutput.isEmpty {
            print("[LoginService] \(errorOutput)")
        }

        guard process.terminationStatus == 0 else {
            throw UsageError.loginFailed("登录脚本执行失败")
        }

        // 解析输出
        guard let output = String(data: outputData, encoding: .utf8),
              let jsonData = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw UsageError.loginFailed("无法解析登录结果")
        }

        guard let success = json["success"] as? Bool, success else {
            let error = json["error"] as? String ?? "未知错误"
            throw UsageError.loginFailed(error)
        }

        // 从 Cookie 文件加载
        if CookieManager.shared.loadFromFile() {
            print("[LoginService] 登录成功")
            return true
        }

        throw UsageError.loginFailed("无法保存登录状态")
    }

    // MARK: - 检查是否需要登录

    var needsLogin: Bool {
        return !CookieManager.shared.hasValidCookie
    }
}