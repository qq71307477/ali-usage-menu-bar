import SwiftUI
import Foundation

@available(macOS 12.0, *)
@MainActor
class UsageViewModel: ObservableObject {
    @Published var usageData: UsageData?
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastUpdated: Date?
    @Published var showLoginPrompt = false

    init() {
        // 初始化时自动刷新
        refresh()
    }

    // MARK: - 刷新数据

    func refresh() {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        Task {
            do {
                // 检查是否需要登录
                if LoginService.shared.needsLogin {
                    self.error = "请先登录"
                    self.showLoginPrompt = true
                    self.isLoading = false
                    return
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
                    self.error = "登录已过期，请重新登录"
                    self.showLoginPrompt = true
                default:
                    self.error = error.errorDescription
                }
            } catch {
                self.error = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    // MARK: - 登录后刷新

    func refreshAfterLogin() async {
        do {
            let data = try await UsageAPIClient.shared.fetchUsage()
            self.usageData = data
            self.lastUpdated = data.lastUpdated
            self.error = nil
            self.showLoginPrompt = false

            if let quota = data.quotaInfo {
                AppDelegate.shared?.updateStatusItem(
                    fiveHour: quota.fiveHourPercent,
                    week: quota.weekPercent,
                    month: quota.monthPercent
                )
            }
        } catch {
            self.error = "获取数据失败: \(error.localizedDescription)"
        }
    }

    // MARK: - 清除数据

    func clearData() {
        usageData = nil
        lastUpdated = nil
        error = nil
        // 重置菜单栏显示
        AppDelegate.shared?.updateStatusItem(fiveHour: 0, week: 0, month: 0)
    }
}