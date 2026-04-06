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
        print("[UsageViewModel] init() 被调用，准备刷新")
        refresh()
    }

    // MARK: - 刷新数据

    func refresh() {
        print("[UsageViewModel] refresh() 被调用, isLoading=\(isLoading)")
        guard !isLoading else { return }

        isLoading = true
        error = nil

        Task {
            print("[UsageViewModel] 开始获取数据...")
            do {
                // 检查是否需要登录
                if LoginService.shared.needsLogin {
                    print("[UsageViewModel] 需要登录")
                    self.error = "请先登录"
                    self.showLoginPrompt = true
                    self.isLoading = false
                    return
                }

                let data = try await UsageAPIClient.shared.fetchUsage()
                print("[UsageViewModel] 获取数据成功: \(data.planName)")
                self.usageData = data
                self.lastUpdated = data.lastUpdated
                self.error = nil

                // 更新菜单栏显示
                if let quota = data.quotaInfo {
                    print("[UsageViewModel] 更新菜单栏: 5h=\(quota.fiveHourPercent)%")
                    AppDelegate.shared?.updateStatusItem(
                        fiveHour: quota.fiveHourPercent,
                        week: quota.weekPercent,
                        month: quota.monthPercent
                    )
                }
            } catch let error as UsageError {
                print("[UsageViewModel] 错误: \(error)")
                switch error {
                case .cookieExpired, .missingCookie:
                    self.error = "登录已过期，请重新登录"
                    self.showLoginPrompt = true
                default:
                    self.error = error.errorDescription
                }
            } catch {
                print("[UsageViewModel] 其他错误: \(error)")
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