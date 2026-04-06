import SwiftUI

@available(macOS 12.0, *)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var loginStep: LoginStep = .idle
    @State private var loginResult: String?
    @State private var isLoggedIn: Bool = false

    enum LoginStep {
        case idle
        case waitingBrowser
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("阿里云百炼登录")
                .font(.headline)

            if isLoggedIn {
                // 已登录状态
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已登录")
                            .foregroundColor(.green)
                    }
                    .font(.subheadline)

                    Text("Cookie 有效期约 12 小时")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: logout) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("退出登录")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.red)

            } else {
                // 未登录状态
                switch loginStep {
                case .idle:
                    VStack(spacing: 12) {
                        Text("点击下方按钮打开浏览器进行登录")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Button(action: openBrowser) {
                        HStack {
                            Image(systemName: "safari")
                            Text("打开浏览器登录")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                case .waitingBrowser:
                    VStack(spacing: 12) {
                        Text("请在浏览器中完成登录")
                            .font(.subheadline)
                            .foregroundColor(.orange)

                        Text("登录成功后点击下方按钮")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button(action: confirmLogin) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("我已登录完成")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
                }
            }

            if let result = loginResult {
                Text(result)
                    .font(.caption)
                    .foregroundColor(result.contains("成功") ? .green : .red)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button("关闭") { dismiss() }
                .keyboardShortcut(.escape)
        }
        .padding(24)
        .frame(width: 320, height: 300)
        .onAppear {
            isLoggedIn = CookieManager.shared.hasValidCookie
        }
    }

    private func openBrowser() {
        loginStep = .waitingBrowser
        loginResult = nil

        Task {
            do {
                _ = try await LoginService.shared.openBrowserForLogin()
            } catch {
                await MainActor.run {
                    loginResult = "打开浏览器失败: \(error.localizedDescription)"
                    loginStep = .idle
                }
            }
        }
    }

    private func confirmLogin() {
        loginResult = "正在保存登录状态..."

        Task {
            if CookieManager.shared.loadFromFile() {
                await MainActor.run {
                    loginResult = "登录成功！"
                    isLoggedIn = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            } else {
                await MainActor.run {
                    loginResult = "未检测到登录信息，请确保在浏览器中完成登录"
                }
            }
        }
    }

    private func logout() {
        // 清除 Cookie
        CookieManager.shared.clearCookie()

        // 删除 Cookie 文件
        let cookiePath = CookieManager.cookieFilePath
        try? FileManager.default.removeItem(atPath: cookiePath)

        isLoggedIn = false
        loginResult = "已退出登录"
        loginStep = .idle
    }
}