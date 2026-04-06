import SwiftUI
import Foundation

@available(macOS 12.0, *)
@MainActor
class UsageViewModel: ObservableObject {
    @Published var usageData: UsageData?
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastUpdated: Date?
    @Published var isLoggingIn = false

    // MARK: - 刷新数据

    func refresh() {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        Task {
            do {
                // 检查是否需要登录
                if LoginService.shared.needsLogin {
                    throw UsageError.cookieExpired
                }

                let data = try await UsageAPIClient.shared.fetchUsage()
                self.usageData = data
                self.lastUpdated = data.lastUpdated
                self.error = nil

                // 更新菜单栏显示
                if let quota = data.quotaInfo {
                    AppDelegate.shared?.updateStatusItem(
                        fiveHour: quota.fiveHourPercent,
                        week: quota.weekPercent,
                        month: quota.monthPercent
                    )
                }
            } catch let error as UsageError {
                switch error {
                case .cookieExpired, .missingCookie:
                    // 尝试重新登录
                    await attemptRelogin()
                default:
                    self.error = error.errorDescription
                }
            } catch {
                self.error = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    // MARK: - 重新登录

    private func attemptRelogin() async {
        guard let (username, password) = getCredentials() else {
            self.error = "请先配置账号密码"
            self.isLoading = false
            return
        }

        isLoggingIn = true
        error = "登录已过期，正在重新登录..."

        do {
            let success = try await LoginService.shared.performLogin(username: username, password: password)
            if success {
                // 重新获取数据
                let data = try await UsageAPIClient.shared.fetchUsage()
                self.usageData = data
                self.lastUpdated = data.lastUpdated
                self.error = nil

                if let quota = data.quotaInfo {
                    AppDelegate.shared?.updateStatusItem(
                        fiveHour: quota.fiveHourPercent,
                        week: quota.weekPercent,
                        month: quota.monthPercent
                    )
                }
            } else {
                self.error = "登录失败，请检查账号密码"
            }
        } catch {
            self.error = "登录失败: \(error.localizedDescription)"
        }

        isLoggingIn = false
    }

    // MARK: - 获取保存的凭证

    private func getCredentials() -> (String, String)? {
        guard let username = UserDefaults.standard.string(forKey: "aliyunUsername"),
              let password = UserDefaults.standard.string(forKey: "aliyunPassword"),
              !username.isEmpty, !password.isEmpty else {
            return nil
        }
        return (username, password)
    }
}