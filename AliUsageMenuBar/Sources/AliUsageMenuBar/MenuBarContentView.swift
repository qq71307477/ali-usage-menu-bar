import SwiftUI

@available(macOS 12.0, *)
struct MenuBarContentView: View {
    @StateObject private var viewModel = UsageViewModel()
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack(spacing: 6) {
                Text("阿里云百炼")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                }

                if let lastUpdated = viewModel.lastUpdated {
                    Text(lastUpdated, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Button { viewModel.refresh() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)

                Button { NSApp.terminate(nil) } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            ScrollView {
                VStack(spacing: 8) {
                    // 错误提示
                    if let error = viewModel.error {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            Spacer()
                            Button("重试") { viewModel.refresh() }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                        .padding(6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }

                    // 用量数据
                    if let data = viewModel.usageData, let quota = data.quotaInfo {
                        // 套餐信息
                        HStack {
                            Text(data.planName)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                            if let days = data.remainingDays {
                                Text("剩余 \(days) 天")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)

                        // 近5小时
                        QuotaRow(
                            title: "近5小时",
                            percent: quota.fiveHourPercent,
                            used: quota.per5HourUsedQuota ?? 0,
                            total: quota.per5HourTotalQuota ?? 0
                        )

                        // 近一周
                        QuotaRow(
                            title: "近一周",
                            percent: quota.weekPercent,
                            used: quota.perWeekUsedQuota ?? 0,
                            total: quota.perWeekTotalQuota ?? 0
                        )

                        // 近一月
                        QuotaRow(
                            title: "近一月",
                            percent: quota.monthPercent,
                            used: quota.perBillMonthUsedQuota ?? 0,
                            total: quota.perBillMonthTotalQuota ?? 0
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
        }
        .frame(width: 280)
        .onAppear { viewModel.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .refreshUsage)) { _ in
            viewModel.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clearUsageData)) { _ in
            viewModel.clearData()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

@available(macOS 12.0, *)
struct QuotaRow: View {
    let title: String
    let percent: Double
    let used: Int
    let total: Int

    var progressColor: Color {
        if percent >= 90 { return .red }
        else if percent >= 70 { return .orange }
        else { return .green }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(used)/\(total)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(String(format: "%.0f%%", percent))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(progressColor)
            }

            ProgressView(value: min(percent, 100), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .frame(height: 4)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}