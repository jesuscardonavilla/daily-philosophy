import Foundation

/// Keeps the app's progress (thinkers met, notes, chats) as one JSON file on the phone.
enum Store {
    private static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("daily-philosophy-state.json")
    }

    /// Returns the saved state if it is a valid JSON object, otherwise nil.
    static func loadJSON() -> String? {
        guard let data = try? Data(contentsOf: url),
              (try? JSONSerialization.jsonObject(with: data)) is [String: Any],
              let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }

    static func saveJSON(_ json: String) {
        guard let data = json.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) is [String: Any] else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }
}
