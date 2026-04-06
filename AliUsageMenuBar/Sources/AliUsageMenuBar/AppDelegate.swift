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
}

extension Notification.Name {
    static let refreshUsage = Notification.Name("refreshUsage")
    static let clearUsageData = Notification.Name("clearUsageData")
}