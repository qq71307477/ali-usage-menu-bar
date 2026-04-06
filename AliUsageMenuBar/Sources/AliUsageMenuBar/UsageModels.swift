import Foundation

// MARK: - API 响应模型

struct APIResponse<T: Codable>: Codable {
    let code: String
    let data: T?
    let success: Bool?
    let errorMsg: String?
}

struct CodingPlanData: Codable {
    let DataV2: DataV2Response?
}

struct DataV2Response: Codable {
    let data: CodingPlanInstanceData?
    let success: Bool?
}

struct CodingPlanInstanceData: Codable {
    let codingPlanInstanceInfos: [CodingPlanInstanceInfo]?
    let userId: String?
}

struct CodingPlanInstanceInfo: Codable {
    let codingPlanQuotaInfo: CodingPlanQuotaInfo?
    let instanceId: String?
    let instanceName: String?
    let instanceType: String?
    let remainingDays: Int?
    let status: String?
}

struct CodingPlanQuotaInfo: Codable {
    // 近5小时
    let per5HourUsedQuota: Int?
    let per5HourTotalQuota: Int?
    let per5HourQuotaNextRefreshTime: TimeInterval?

    // 近一周
    let perWeekUsedQuota: Int?
    let perWeekTotalQuota: Int?
    let perWeekQuotaNextRefreshTime: TimeInterval?

    // 近一月（账单月）
    let perBillMonthUsedQuota: Int?
    let perBillMonthTotalQuota: Int?
    let perBillMonthQuotaNextRefreshTime: TimeInterval?

    // 计算百分比
    var fiveHourPercent: Double {
        guard let used = per5HourUsedQuota, let total = per5HourTotalQuota, total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }

    var weekPercent: Double {
        guard let used = perWeekUsedQuota, let total = perWeekTotalQuota, total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }

    var monthPercent: Double {
        guard let used = perBillMonthUsedQuota, let total = perBillMonthTotalQuota, total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }
}

// MARK: - 应用内使用的数据模型

struct UsageData {
    let quotaInfo: CodingPlanQuotaInfo?
    let planName: String
    let remainingDays: Int?
    let lastUpdated: Date

    init(from instance: CodingPlanInstanceInfo) {
        self.quotaInfo = instance.codingPlanQuotaInfo
        self.planName = instance.instanceName ?? "Coding Plan"
        self.remainingDays = instance.remainingDays
        self.lastUpdated = Date()
    }
}

// MARK: - 错误类型

enum UsageError: Error, LocalizedError {
    case missingCredentials
    case missingCookie
    case cookieExpired
    case loginRequired
    case loginFailed(String)
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodeError(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "请先配置阿里云账号和密码"
        case .missingCookie:
            return "未找到登录状态，请重新登录"
        case .cookieExpired:
            return "登录已过期"
        case .loginRequired:
            return "需要重新登录"
        case .loginFailed(let msg):
            return "登录失败: \(msg)"
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "服务器响应无效"
        case .httpError(let statusCode, let message):
            return "HTTP 错误 \(statusCode): \(message ?? "未知错误")"
        case .decodeError(let detail):
            return "数据解析失败: \(detail)"
        }
    }
}