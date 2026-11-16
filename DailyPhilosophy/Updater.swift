import Foundation

/// Lets the app pull the newest index.html from the GitHub repo, so content changes
/// don't need an Xcode rebuild. A downloaded copy is ignored once you install a newer build.
enum Updater {
    static let remote = URL(string: "https://raw.githubusercontent.com/jesuscardonavilla/daily-philosophy/main/DailyPhilosophy/Resources/index.html")!

    private static var file: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("index-remote.html")
    }

    static let remoteVersion = URL(string: "https://raw.githubusercontent.com/jesuscardonavilla/daily-philosophy/main/DailyPhilosophy/Resources/version.json")!

    private static func parseVersion(_ data: Data) -> Int? {
        ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["version"] as? Int
    }

    private static var bundledVersion: Int {
        guard let url = Bundle.main.url(forResource: "version", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return 0 }
        return parseVersion(data) ?? 0
    }

    /// Version of the page currently shown.
    static var installedVersion: Int {
        if let url = activeURL(), url == file {
            return UserDefaults.standard.integer(forKey: "dp.remoteVersion")
        }
        return bundledVersion
    }

    /// True when GitHub has a newer version than the one on screen.
    static func updateAvailable() async -> Bool {
        var req = URLRequest(url: remoteVersion)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 15
        guard let (data, response) = try? await URLSession.shared.data(for: req),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let remote = parseVersion(data) else { return false }
        return remote > installedVersion
    }

    static var bundled: URL? { Bundle.main.url(forResource: "index", withExtension: "html") }

    private static var bundleStamp: Double {
        guard let url = bundled,
              let date = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
        else { return 0 }
        return date.timeIntervalSince1970
    }

    /// The page to show: the downloaded copy if it belongs to this build, else the bundled one.
    static func activeURL() -> URL? {
        let fm = FileManager.default
        if fm.fileExists(atPath: file.path) {
            if UserDefaults.standard.double(forKey: "dp.bundleStamp") == bundleStamp { return file }
            try? fm.removeItem(at: file)
        }
        return bundled
    }

    static func reset() {
        try? FileManager.default.removeItem(at: file)
    }

    static func fetch() async throws {
        var req = URLRequest(url: remote)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 30
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClientError.api("Could not reach GitHub. Check your connection.")
        }
        guard data.count > 100_000,
              let text = String(data: data, encoding: .utf8),
              text.contains("daily-philosophy-v1") else {
            throw ClientError.api("The downloaded file didn't look right, so nothing was changed.")
        }
        // Record which version this is, if GitHub tells us.
        var vReq = URLRequest(url: remoteVersion)
        vReq.cachePolicy = .reloadIgnoringLocalCacheData
        vReq.timeoutInterval = 15
        var version = 0
        if let (vData, _) = try? await URLSession.shared.data(for: vReq) { version = parseVersion(vData) ?? 0 }
        try data.write(to: file, options: .atomic)
        UserDefaults.standard.set(bundleStamp, forKey: "dp.bundleStamp")
        UserDefaults.standard.set(version, forKey: "dp.remoteVersion")
    }
}
