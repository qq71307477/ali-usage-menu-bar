import SwiftUI

@available(macOS 12.0, *)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var loginStep: LoginStep = .idle
    @State private var loginResult: String?

    enum LoginStep {
        case idle
        case waitingBrowser
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("阿里云百炼登录")
                .font(.headline)

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
        .frame(width: 320, height: 280)
    }

    private func openBrowser() {
        loginStep = .waitingBrowser
        loginResult = nil

        // 后台启动浏览器，不等待结果
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
            // 从浏览器 Cookie 文件加载
            if CookieManager.shared.loadFromFile() {
                await MainActor.run {
                    loginResult = "登录成功！"
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
}