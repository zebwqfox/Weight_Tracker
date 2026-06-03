import Foundation
import UIKit

enum AIAnalysisError: LocalizedError {
    case noAPIKey
    case imageEncodingFailed
    case networkError(Error)
    case invalidResponse(Int)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "请在设置中配置 DeepSeek API Key"
        case .imageEncodingFailed: return "图片处理失败"
        case .networkError(let e): return "网络错误：\(e.localizedDescription)"
        case .invalidResponse(let code): return "服务器响应无效（\(code)）"
        case .parseError(let msg): return "解析失败：\(msg)"
        }
    }
}

actor AIAnalysisService {
    static let shared = AIAnalysisService()

    private let endpoint = "https://api.deepseek.com/v1/chat/completions"

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "deepseek_api_key") ?? ""
    }

    private var currentModel: String {
        DeepSeekModel.stored.rawValue
    }

    func analyzeFood(image: UIImage) async throws -> NutritionInfo {
        guard !apiKey.isEmpty else { throw AIAnalysisError.noAPIKey }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AIAnalysisError.imageEncodingFailed
        }
        let base64Image = imageData.base64EncodedString()

        let prompt = """
        请仔细分析这张食物照片，识别所有菜品并估算热量。
        请只返回以下JSON格式，不要包含任何其他文字或markdown标记：
        {
          "totalCalories": 总热量数值,
          "dishes": [
            {
              "name": "菜品名称",
              "calories": 热量数值,
              "portion": "分量描述（如：一碗、半份）",
              "emoji": "对应emoji"
            }
          ],
          "protein": 蛋白质克数,
          "carbohydrates": 碳水化合物克数,
          "fat": 脂肪克数,
          "fiber": 膳食纤维克数,
          "healthScore": 健康评分1到10的整数,
          "suggestion": "简短的饮食建议（中文，50字以内）"
        }
        热量单位千卡(kcal)，营养素单位克(g)。
        """

        let requestBody: [String: Any] = [
            "model": currentModel,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIAnalysisError.invalidResponse(0)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AIAnalysisError.invalidResponse(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw AIAnalysisError.invalidResponse(0)
        }

        let jsonText = extractJSON(from: text)
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw AIAnalysisError.parseError("无法解析 JSON 文本")
        }

        do {
            return try JSONDecoder().decode(NutritionInfo.self, from: jsonData)
        } catch {
            throw AIAnalysisError.parseError(error.localizedDescription)
        }
    }

    private func extractJSON(from text: String) -> String {
        var cleaned = text
        if let start = cleaned.range(of: "```json"),
           let end = cleaned.range(of: "```", range: start.upperBound..<cleaned.endIndex) {
            cleaned = String(cleaned[start.upperBound..<end.lowerBound])
        } else if let start = cleaned.range(of: "```"),
                  let end = cleaned.range(of: "```", range: start.upperBound..<cleaned.endIndex) {
            cleaned = String(cleaned[start.upperBound..<end.lowerBound])
        }
        if let start = cleaned.firstIndex(of: "{"),
           let end = cleaned.lastIndex(of: "}") {
            return String(cleaned[start...end])
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
