import Foundation
import AppKit

public final class AppUpdateService: ObservableObject {
    public static let shared = AppUpdateService()

    @Published public var isChecking: Bool = false
    @Published public var isDownloading: Bool = false
    @Published public var updateAvailable: Bool = false
    @Published public var latestVersion: String = ""
    @Published public var releaseNotes: String = ""
    @Published public var downloadProgress: Double = 0.0
    @Published public var statusMessage: String = ""

    private let repoOwner = "tahoangphuc111"
    private let repoName = "Classroom-Tracker"
    private let tokenKey = "com.phucta.classroomwidget.github_token"

    private var latestAssetId: Int? = nil
    private var latestDownloadUrl: URL? = nil

    public var githubToken: String {
        get {
            UserDefaults.standard.string(forKey: tokenKey) ?? "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"
        }
        set {
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: tokenKey)
        }
    }

    public var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private init() {}

    @MainActor
    public func checkForUpdates(isUserInitiated: Bool = false) async {
        guard !isChecking else { return }
        isChecking = true
        statusMessage = "Đang kiểm tra bản cập nhật..."

        defer {
            isChecking = false
        }

        guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else {
            statusMessage = "URL cập nhật không hợp lệ."
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let token = githubToken
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                statusMessage = "Không thể kết nối đến máy chủ cập nhật."
                return
            }

            if httpResponse.statusCode == 404 || httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                if isUserInitiated {
                    statusMessage = "Không thể truy cập repo. Vui lòng kiểm tra lại GitHub Token."
                }
                return
            }

            guard httpResponse.statusCode == 200 else {
                statusMessage = "Lỗi kiểm tra cập nhật (\(httpResponse.statusCode))."
                return
            }

            let release = try JSONDecoder().decode(GitHubReleaseResponse.self, from: data)
            let remoteVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let isNewer = isVersion(remoteVersion, newerThan: currentVersion)

            let pkgAsset = release.assets.first(where: { $0.name.hasSuffix(".pkg") })
            self.latestAssetId = pkgAsset?.id
            self.latestDownloadUrl = pkgAsset.flatMap { URL(string: $0.browserDownloadUrl) }

            if isNewer && (self.latestAssetId != nil || self.latestDownloadUrl != nil) {
                self.updateAvailable = true
                self.latestVersion = remoteVersion
                self.releaseNotes = release.body ?? ""
                self.statusMessage = "Đã có bản cập nhật mới v\(remoteVersion)!"
            } else {
                self.updateAvailable = false
                self.statusMessage = "Bạn đang dùng phiên bản mới nhất (v\(currentVersion))."
            }
        } catch {
            if isUserInitiated {
                statusMessage = "Không thể kiểm tra: \(error.localizedDescription)"
            }
        }
    }

    @MainActor
    public func downloadAndInstall() async {
        guard !isDownloading else { return }
        isDownloading = true
        downloadProgress = 0.0
        statusMessage = "Đang tải bản cập nhật..."

        defer {
            isDownloading = false
        }

        let downloadUrl: URL
        var request: URLRequest

        if let assetId = latestAssetId {
            downloadUrl = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/assets/\(assetId)")!
            request = URLRequest(url: downloadUrl)
            request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
            let token = githubToken
            if !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        } else if let fallbackUrl = latestDownloadUrl {
            downloadUrl = fallbackUrl
            request = URLRequest(url: downloadUrl)
        } else {
            statusMessage = "Không tìm thấy tệp cài đặt .pkg trong bản phát hành."
            return
        }

        do {
            let (tempLocalUrl, response) = try await URLSession.shared.download(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                statusMessage = "Lỗi tải file cài đặt."
                return
            }

            let destinationUrl = FileManager.default.temporaryDirectory.appendingPathComponent("ClassroomTracker.pkg")
            try? FileManager.default.removeItem(at: destinationUrl)
            try FileManager.default.moveItem(at: tempLocalUrl, to: destinationUrl)

            statusMessage = "Đã tải xong! Đang mở trình cài đặt..."
            NSWorkspace.shared.open(destinationUrl)
        } catch {
            statusMessage = "Lỗi khi tải cập nhật: \(error.localizedDescription)"
        }
    }

    private func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(parts1.count, parts2.count)

        for i in 0..<maxCount {
            let num1 = i < parts1.count ? parts1[i] : 0
            let num2 = i < parts2.count ? parts2[i] : 0
            if num1 > num2 { return true }
            if num1 < num2 { return false }
        }
        return false
    }
}

private struct GitHubReleaseResponse: Codable {
    let tagName: String
    let body: String?
    let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case assets
    }
}

private struct GitHubReleaseAsset: Codable {
    let id: Int
    let name: String
    let browserDownloadUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case browserDownloadUrl = "browser_download_url"
    }
}
