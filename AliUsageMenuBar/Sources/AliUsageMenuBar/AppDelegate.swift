import SwiftUI
import AppKit

@available(macOS 12.0, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    var statusItem: NSStatusItem!
    var popover = NSPopover()
    var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "--"
            button.action = #selector(togglePopover(_:))
        }

        let contentView = MenuBarContentView()
        popover.contentSize = NSSize(width: 280, height: 240)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        // 每 5 分钟自动刷新
        refreshTimer = Timer(timeInterval: 300, repeats: true) { _ in
            NotificationCenter.default.post(name: .refreshUsage, object: nil)
        }
        RunLoop.main.add(refreshTimer!, forMode: .common)

        // 启动后立即刷新数据
        Task { [weak self] in
            guard let self = self else { return }
            await self.fetchAndUpdateUsage()
        }
    }

    private func fetchAndUpdateUsage() async {
        guard let (cookie, secToken) = CookieManager.shared.getCookie() else {
            print("[AppDelegate] 没有 Cookie")
            return
        }

        do {
            let data = try await UsageAPIClient.shared.fetchUsage()
            if let quota = data.quotaInfo {
                await MainActor.run {
                    self.updateStatusItem(
                        fiveHour: quota.fiveHourPercent,
                        week: quota.weekPercent,
                        month: quota.monthPercent
                    )
                }
            }
        } catch {
            print("[AppDelegate] 获取数据失败: \(error)")
        }
    }

    func updateStatusItem(fiveHour: Double, week: Double, month: Double) {
        guard let button = statusItem.button else { return }
        // 只显示近5小时用量
        button.title = String(format: "%.0f%%", fiveHour)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            hidePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func hidePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 清理所有后台 login.js 进程
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["pkill", "-f", "login.js"]
        try? process.run()
        process.waitUntilExit()
        print("[AppDelegate] 应用退出，已清理后台进程")
    }
}

extension Notification.Name {
    static let refreshUsage = Notification.Name("refreshUsage")
    static let clearUsageData = Notification.Name("clearUsageData")
}