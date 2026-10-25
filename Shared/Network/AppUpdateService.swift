import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

@MainActor
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
    private let etagKey = "com.phucta.classroomwidget.github_etag"
    private let lastCheckKey = "com.phucta.classroomwidget.last_update_check"
    private nonisolated static let jsonDecoder = JSONDecoder()

    private var latestAssetId: Int? = nil
    private var latestDownloadUrl: URL? = nil

    public var githubToken: String {
        get {
            UserDefaults.standard.string(forKey: tokenKey) ?? ""
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

        if !isUserInitiated {
            let lastCheck = UserDefaults.standard.double(forKey: lastCheckKey)
            if lastCheck > 0 && Date().timeIntervalSince1970 - lastCheck < 14400 {
                return
            }
        }

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
        request.setValue("ClassroomTracker/\(currentVersion) (Macintosh; Apple Silicon)", forHTTPHeaderField: "User-Agent")

        let token = githubToken
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let savedEtag = UserDefaults.standard.string(forKey: etagKey), !savedEtag.isEmpty {
            request.setValue(savedEtag, forHTTPHeaderField: "If-None-Match")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                statusMessage = "Không thể kết nối đến máy chủ cập nhật."
                return
            }

            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCheckKey)

            if httpResponse.statusCode == 304 {
                self.updateAvailable = false
                self.statusMessage = "Bạn đang dùng phiên bản mới nhất (v\(currentVersion))."
                return
            }

            if httpResponse.statusCode == 403 {
                if token.isEmpty {
                    if isUserInitiated {
                        statusMessage = "Đã vượt hạn mức kiểm tra của GitHub (60 lần/giờ). Vui lòng thử lại sau."
                    }
                } else if isUserInitiated {
                    statusMessage = "GitHub Token không có quyền truy cập repo này."
                }
                return
            }

            if httpResponse.statusCode == 404 || httpResponse.statusCode == 401 {
                if isUserInitiated {
                    statusMessage = "Không tìm thấy bản phát hành hoặc cần Token truy cập repo riêng tư."
                }
                return
            }

            guard httpResponse.statusCode == 200 else {
                statusMessage = "Lỗi kiểm tra cập nhật (\(httpResponse.statusCode))."
                return
            }

            if let newEtag = httpResponse.value(forHTTPHeaderField: "ETag") {
                UserDefaults.standard.set(newEtag, forKey: etagKey)
            }

            let release = try Self.jsonDecoder.decode(GitHubReleaseResponse.self, from: data)
            let remoteVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let isNewer = isVersion(remoteVersion, newerThan: currentVersion)

            let pkgAsset = release.assets.first(where: { $0.name.hasSuffix(".pkg") })
            self.latestAssetId = pkgAsset?.id
            self.latestDownloadUrl = pkgAsset.flatMap { URL(string: $0.browserDownloadUrl) }

            #if os(iOS)
            let canUpdate = isNewer
            #else
            let canUpdate = isNewer && (self.latestAssetId != nil || self.latestDownloadUrl != nil)
            #endif

            if canUpdate {
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

        #if os(iOS)
        if let releaseUrl = URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases/latest") {
            await UIApplication.shared.open(releaseUrl)
        }
        return
        #else
        isDownloading = true
        downloadProgress = 0.0
        statusMessage = "Đang tải bản cập nhật..."

        defer {
            isDownloading = false
        }

        let downloadUrl: URL
        var request: URLRequest

        let token = githubToken
        if !token.isEmpty,
           let assetId = latestAssetId,
           let constructedUrl = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/assets/\(assetId)") {
            downloadUrl = constructedUrl
            request = URLRequest(url: downloadUrl)
            request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let fallbackUrl = latestDownloadUrl {
            downloadUrl = fallbackUrl
            request = URLRequest(url: downloadUrl)
        } else {
            statusMessage = "Không tìm thấy tệp cài đặt .pkg trong bản phát hành."
            return
        }

        request.setValue("ClassroomTracker/\(currentVersion) (Macintosh; Apple Silicon)", forHTTPHeaderField: "User-Agent")

        do {
            let (tempLocalUrl, response) = try await URLSession.shared.download(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                statusMessage = "Lỗi tải file cài đặt."
                return
            }

            let fileManager = FileManager.default
            let downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
            let destinationUrl = (downloadsDirectory ?? fileManager.temporaryDirectory).appendingPathComponent("ClassroomTracker.pkg")

            try? fileManager.removeItem(at: destinationUrl)
            try fileManager.moveItem(at: tempLocalUrl, to: destinationUrl)

            let opened = NSWorkspace.shared.open(destinationUrl)
            if opened {
                statusMessage = "Đã tải xong! Đang mở trình cài đặt..."
            } else {
                NSWorkspace.shared.activateFileViewerSelecting([destinationUrl])
                statusMessage = "Đã lưu tệp cài đặt vào thư mục Downloads. Vui lòng mở tệp để cài đặt."
            }
        } catch {
            statusMessage = "Lỗi khi tải cập nhật: \(error.localizedDescription)"
        }
        #endif
    }

    private func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        func parseVersion(_ raw: String) -> (numbers: [Int], isPreRelease: Bool) {
            let lower = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let isPre = lower.contains("beta") || lower.contains("alpha") || lower.contains("rc") || lower.contains("preview")

            var clean = lower
            if clean.hasPrefix("v") { clean.removeFirst() }

            let tokens = clean.components(separatedBy: CharacterSet.decimalDigits.inverted)
            let numbers = tokens.compactMap { Int($0) }
            return (numbers, isPre)
        }

        let (remoteNums, remotePre) = parseVersion(v1)
        let (currNums, currPre) = parseVersion(v2)

        let maxCount = max(remoteNums.count, currNums.count)
        for i in 0..<maxCount {
            let num1 = i < remoteNums.count ? remoteNums[i] : 0
            let num2 = i < currNums.count ? currNums[i] : 0
            if num1 > num2 { return true }
            if num1 < num2 { return false }
        }

        if currPre && !remotePre {
            return true
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
