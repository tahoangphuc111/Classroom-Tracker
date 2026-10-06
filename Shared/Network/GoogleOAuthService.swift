import Foundation
import CryptoKit
import Security
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif


public struct OAuthTokens: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: Int
    public let expiresAt: Date

    public var isExpired: Bool {
        Date().addingTimeInterval(60) >= expiresAt
    }
}

public struct GoogleUserInfo: Codable, Sendable {
    public let email: String
    public let name: String?
    public let picture: String?
}

@MainActor
public final class GoogleOAuthService: NSObject, ObservableObject {
    public static let shared = GoogleOAuthService()

    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var currentUserEmail: String? = nil
    @Published public private(set) var currentUserName: String? = nil
    @Published public private(set) var currentUserAvatar: String? = nil
    @Published public var authErrorMessage: String? = nil

    public static let bundledClientId = "1024991814751-qs4rkg9pa09r092lp083l3e9gk6e3mru.apps.googleusercontent.com"
    public static let bundledClientSecret = "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"

    public static let defaultClientIdKey = "google_oauth_client_id"
    public static let defaultClientSecretKey = "google_oauth_client_secret"

    private let scopes = [
        "https://www.googleapis.com/auth/classroom.courses.readonly",
        "https://www.googleapis.com/auth/classroom.coursework.me.readonly",
        "https://www.googleapis.com/auth/classroom.student-submissions.me.readonly",
        "email",
        "profile"
    ]

    private override init() {
        super.init()
        checkStoredAuthentication()
    }

    public var configuredClientId: String {
        get {
            let stored = UserDefaults.standard.string(forKey: Self.defaultClientIdKey)
            if let stored, !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return stored
            }
            return Self.bundledClientId
        }
        set {
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Self.defaultClientIdKey)
        }
    }

    public var configuredClientSecret: String {
        get {
            let stored = UserDefaults.standard.string(forKey: Self.defaultClientSecretKey)
            if let stored, !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return stored
            }
            return Self.bundledClientSecret
        }
        set {
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Self.defaultClientSecretKey)
        }
    }

    public func checkStoredAuthentication() {
        if let tokens = loadTokensFromKeychain(), !tokens.accessToken.isEmpty {
            self.isAuthenticated = true
            self.currentUserEmail = ClassroomStorage.shared.loadUserEmail()
        } else {
            self.isAuthenticated = false
        }
    }

    public func startSignIn() async throws {
        let clientId = configuredClientId
        guard !clientId.isEmpty else {
            throw NSError(
                domain: "GoogleOAuthService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Vui lòng nhập Google Client ID trong phần Cài Đặt."]
            )
        }

        let server = try LoopbackOAuthServer.shared.startServer()
        let loopbackRedirectUri = "http://127.0.0.1:\(server.port)"

        let verifier = generateCodeVerifier()
        let challenge = generateCodeChallenge(from: verifier)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: loopbackRedirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let authURL = components.url else {
            throw NSError(domain: "GoogleOAuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không thể tạo URL xác thực."])
        }

        #if os(macOS)
        NSWorkspace.shared.open(authURL)
        #elseif os(iOS)
        await MainActor.run {
            UIApplication.shared.open(authURL)
        }
        #endif

        #if os(iOS)
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskId = await MainActor.run {
            UIApplication.shared.beginBackgroundTask(withName: "GoogleOAuthLoopback") {
                if backgroundTaskId != .invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTaskId)
                    backgroundTaskId = .invalid
                }
            }
        }
        defer {
            if backgroundTaskId != .invalid {
                let taskToEnd = backgroundTaskId
                DispatchQueue.main.async {
                    UIApplication.shared.endBackgroundTask(taskToEnd)
                }
            }
        }
        #endif

        let code = try await LoopbackOAuthServer.shared.waitForAuthorizationCode(server: server)

        try await exchangeCodeForTokens(code: code, verifier: verifier, clientId: clientId, redirectUri: loopbackRedirectUri)

        await fetchUserInfo()
    }

    public func signOut() {
        deleteTokensFromKeychain()
        ClassroomStorage.shared.saveUserEmail(nil)
        self.isAuthenticated = false
        self.currentUserEmail = nil
        self.currentUserName = nil
        self.currentUserAvatar = nil
        ClassroomStorage.shared.notifyWidgetReload()
    }

    private func exchangeCodeForTokens(code: String, verifier: String, clientId: String, redirectUri: String) async throws {
        guard let tokenURL = URL(string: "https://oauth2.googleapis.com/token") else { return }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyParams: [String: String] = [
            "client_id": clientId,
            "code": code,
            "code_verifier": verifier,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUri
        ]

        let clientSecret = configuredClientSecret
        if !clientSecret.isEmpty {
            bodyParams["client_secret"] = clientSecret
        }

        let bodyString = bodyParams.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown token error"
            throw NSError(domain: "GoogleOAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Lỗi đổi token: \(errorText)"])
        }

        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        let tokens = OAuthTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresIn: tokenResponse.expiresIn,
            expiresAt: Date().addingTimeInterval(Double(tokenResponse.expiresIn))
        )

        saveTokensToKeychain(tokens: tokens)
        self.isAuthenticated = true
    }

    public func getValidAccessToken() async throws -> String {
        guard var tokens = loadTokensFromKeychain() else {
            throw NSError(domain: "GoogleOAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Chưa đăng nhập Google."])
        }

        if !tokens.isExpired {
            return tokens.accessToken
        }

        guard let refreshToken = tokens.refreshToken else {
            throw NSError(domain: "GoogleOAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Hết hạn phiên đăng nhập, vui lòng đăng nhập lại."])
        }

        let clientId = configuredClientId
        guard let tokenURL = URL(string: "https://oauth2.googleapis.com/token") else {
            throw NSError(domain: "GoogleOAuthService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Lỗi URL"])
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyParams: [String: String] = [
            "client_id": clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]

        let clientSecret = configuredClientSecret
        if !clientSecret.isEmpty {
            bodyParams["client_secret"] = clientSecret
        }

        let bodyString = bodyParams.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "GoogleOAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Không thể làm mới token."])
        }

        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        let newTokens = OAuthTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken ?? refreshToken,
            expiresIn: tokenResponse.expiresIn,
            expiresAt: Date().addingTimeInterval(Double(tokenResponse.expiresIn))
        )

        saveTokensToKeychain(tokens: newTokens)
        return newTokens.accessToken
    }

    public func fetchUserInfo() async {
        do {
            let accessToken = try await getValidAccessToken()
            guard let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo") else { return }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            let userInfo = try JSONDecoder().decode(GoogleUserInfo.self, from: data)

            self.currentUserEmail = userInfo.email
            self.currentUserName = userInfo.name
            self.currentUserAvatar = userInfo.picture
            ClassroomStorage.shared.saveUserEmail(userInfo.email)
        } catch {
            print("Lỗi lấy user info: \(error.localizedDescription)")
        }
    }

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private let keychainService = "com.phucta.classroomwidget.tokens"

    private func saveTokensToKeychain(tokens: OAuthTokens) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        deleteTokensFromKeychain()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "google_tokens",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadTokensFromKeychain() -> OAuthTokens? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "google_tokens",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(OAuthTokens.self, from: data)
    }

    private func deleteTokensFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "google_tokens"
        ]
        SecItemDelete(query as CFDictionary)
    }
}

private struct OAuthTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}
