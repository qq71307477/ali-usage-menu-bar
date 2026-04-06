import SwiftUI

@available(macOS 12.0, *)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoggingIn = false
    @State private var loginResult: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("阿里云百炼登录")
                .font(.headline)

            VStack(spacing: 12) {
                Text("点击下方按钮打开浏览器进行登录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("登录成功后 Cookie 会自动保存")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: performLogin) {
                HStack {
                    if isLoggingIn {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("等待登录...")
                    } else {
                        Image(systemName: "person.badge.key")
                        Text("打开浏览器登录")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .disabled(isLoggingIn)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

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
        .frame(width: 320, height: 260)
    }

    private func performLogin() {
        isLoggingIn = true
        loginResult = nil

        Task {
            do {
                let success = try await LoginService.shared.performLogin(username: "", password: "")
                await MainActor.run {
                    if success {
                        loginResult = "登录成功！"
                        // 延迟关闭
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            dismiss()
                        }
                    } else {
                        loginResult = "登录失败"
                    }
                    isLoggingIn = false
                }
            } catch {
                await MainActor.run {
                    loginResult = "登录失败: \(error.localizedDescription)"
                    isLoggingIn = false
                }
            }
        }
    }
}