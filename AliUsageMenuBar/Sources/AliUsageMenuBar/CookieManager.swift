import Foundation

class CookieManager {
    static let shared = CookieManager()

    private let cookieKey = "aliyunCookies"
    private let secTokenKey = "aliyunSecToken"
    private let savedAtKey = "aliyunCookieSavedAt"

    private init() {}

    // MARK: - 保存 Cookie

    func saveCookie(_ cookieString: String, secToken: String) {
        UserDefaults.standard.set(cookieString, forKey: cookieKey)
        UserDefaults.standard.set(secToken, forKey: secTokenKey)
        UserDefaults.standard.set(Date(), forKey: savedAtKey)
        UserDefaults.standard.synchronize()
    }

    // MARK: - 读取 Cookie

    func getCookie() -> (cookie: String, secToken: String)? {
        guard let cookie = UserDefaults.standard.string(forKey: cookieKey),
              let secToken = UserDefaults.standard.string(forKey: secTokenKey),
              !cookie.isEmpty, !secToken.isEmpty else {
            return nil
        }
        return (cookie, secToken)
    }

    // MARK: - 检查是否有效

    var hasValidCookie: Bool {
        guard getCookie() != nil else { return false }
        return !isCookieExpired
    }

    var isCookieExpired: Bool {
        guard let savedAt = UserDefaults.standard.object(forKey: savedAtKey) as? Date else {
            return true
        }
        // Cookie 默认 12 小时后过期
        return Date().timeIntervalSince(savedAt) > 43200
    }

    // MARK: - 清除 Cookie

    func clearCookie() {
        UserDefaults.standard.removeObject(forKey: cookieKey)
        UserDefaults.standard.removeObject(forKey: secTokenKey)
        UserDefaults.standard.removeObject(forKey: savedAtKey)
        UserDefaults.standard.synchronize()
    }

    // MARK: - Cookie 文件路径（与 Node.js 脚本共享）

    static var cookieFilePath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AliUsageMenuBar")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("cookies.json").path
    }

    // MARK: - 从文件加载（Node.js 脚本写入）

    func loadFromFile() -> Bool {
        let path = Self.cookieFilePath
        guard FileManager.default.fileExists(atPath: path),
              let data = FileManager.default.contents(atPath: path) else {
            return false
        }

        struct CookieFileData: Codable {
            let cookies: String
            let secToken: String
        }

        guard let json = try? JSONDecoder().decode(CookieFileData.self, from: data) else {
            return false
        }

        saveCookie(json.cookies, secToken: json.secToken)
        return true
    }
}