import SwiftUI

@available(macOS 12.0, *)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("aliyunUsername") private var username: String = ""
    @AppStorage("aliyunPassword") private var password: String = ""
    @State private var showPassword = false
    @State private var isTesting = false
    @State private var testResult: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("配置")
                .font(.headline)

            Form {
                Section("阿里云账号") {
                    TextField("手机号", text: $username)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        if showPassword {
                            TextField("密码", text: $password)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("密码", text: $password)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Button(action: testLogin) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("登录中...")
                            } else {
                                Text("测试登录")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(username.isEmpty || password.isEmpty || isTesting)
                    .buttonStyle(.borderedProminent)

                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(result.contains("成功") ? .green : .red)
                    }
                }
            }
            .padding()

            HStack {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.escape)

                Spacer()

                Button("保存") { dismiss() }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 350, height: 300)
    }

    private func testLogin() {
        isTesting = true
        testResult = nil

        Task {
            do {
                let success = try await LoginService.shared.performLogin(username: username, password: password)
                await MainActor.run {
                    testResult = success ? "登录成功！" : "登录失败"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = "登录失败: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}