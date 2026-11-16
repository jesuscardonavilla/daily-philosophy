import Foundation

enum ClientError: LocalizedError {
    case noKey
    case api(String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .noKey: return "No API key saved. Add one in Settings."
        case .api(let m): return m
        case .badResponse: return "The reply could not be read. Try again."
        }
    }
}

/// Minimal client for the Anthropic Messages API.
enum ClaudeClient {
    static let model = "claude-sonnet-5-5"
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    static func send(system: String, messages: [[String: String]]) async throws -> String {
        guard let key = Keychain.get() else { throw ClientError.noKey }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.timeoutInterval = 45
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 600,
            "system": system,
            "messages": messages
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw ClientError.badResponse }

        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard (200..<300).contains(http.statusCode) else {
            if let err = json?["error"] as? [String: Any], let m = err["message"] as? String {
                throw ClientError.api(m)
            }
            throw ClientError.api("The request failed (status \(http.statusCode)).")
        }

        guard let content = json?["content"] as? [[String: Any]] else { throw ClientError.badResponse }
        let text = content.compactMap { $0["text"] as? String }.joined()
        guard !text.isEmpty else { throw ClientError.badResponse }
        return text
    }
}
