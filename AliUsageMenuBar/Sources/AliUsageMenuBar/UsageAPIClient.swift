import Foundation

@available(macOS 12.0, *)
class UsageAPIClient {
    static let shared = UsageAPIClient()

    private static let baseURL = "https://bailian-cs.console.aliyun.com/data/api.json"
    private static let apiName = "zeldaEasy.broadscope-bailian.codingPlan.queryCodingPlanInstanceInfoV2"

    private init() {}

    // MARK: - 获取用量数据

    func fetchUsage() async throws -> UsageData {
        // 检查 Cookie
        guard let (cookie, secToken) = CookieManager.shared.getCookie() else {
            throw UsageError.missingCookie
        }

        if CookieManager.shared.isCookieExpired {
            throw UsageError.cookieExpired
        }

        // 构建请求 URL
        let urlString = "\(Self.baseURL)?action=BroadScopeAspnGateway&product=sfm_bailian&api=\(Self.apiName)&_v=undefined"

        guard let url = URL(string: urlString) else {
            throw UsageError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("https://bailian.console.aliyun.com", forHTTPHeaderField: "Origin")
        request.setValue("https://bailian.console.aliyun.com/cn-beijing/?tab=coding-plan", forHTTPHeaderField: "Referer")
        request.setValue(cookie, forHTTPHeaderField: "Cookie")

        // 构建请求体
        let params = buildRequestBody(secToken: secToken)
        request.httpBody = params.data(using: .utf8)

        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UsageError.invalidResponse
        }

        // 检查 HTTP 状态码
        guard httpResponse.statusCode == 200 else {
            // 401/403 表示 Cookie 过期
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                CookieManager.shared.clearCookie()
                throw UsageError.cookieExpired
            }
            let message = String(data: data, encoding: .utf8)
            throw UsageError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        // 解析响应
        return try parseResponse(data)
    }

    // MARK: - 构建请求体

    private func buildRequestBody(secToken: String) -> String {
        let params: [String: Any] = [
            "Api": Self.apiName,
            "V": "1.0",
            "Data": [
                "queryCodingPlanInstanceInfoRequest": [
                    "commodityCode": "sfm_codingplan_public_cn",
                    "onlyLatestOne": true
                ],
                "cornerstoneParam": [
                    "protocol": "V2",
                    "console": "ONE_CONSOLE",
                    "productCode": "p_efm",
                    "switchUserType": 3,
                    "domain": "bailian.console.aliyun.com",
                    "consoleSite": "BAILIAN_ALIYUN",
                    "xsp_lang": "zh-CN"
                ]
            ]
        ]

        guard let paramsJson = try? JSONSerialization.data(withJSONObject: params),
              let paramsString = String(data: paramsJson, encoding: .utf8) else {
            return ""
        }

        let encodedParams = paramsString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? paramsString

        return "params=\(encodedParams)&region=cn-beijing&sec_token=\(secToken)"
    }

    // MARK: - 解析响应

    private func parseResponse(_ data: Data) throws -> UsageData {
        do {
            let response = try JSONDecoder().decode(APIResponse<CodingPlanData>.self, from: data)

            guard response.code == "200",
                  let codingPlanData = response.data,
                  let dataV2 = codingPlanData.DataV2,
                  let instanceData = dataV2.data,
                  let instances = instanceData.codingPlanInstanceInfos,
                  let firstInstance = instances.first else {
                throw UsageError.decodeError("响应结构不符合预期")
            }

            return UsageData(from: firstInstance)
        } catch let error as DecodingError {
            throw UsageError.decodeError("JSON 解析失败: \(error)")
        }
    }
}