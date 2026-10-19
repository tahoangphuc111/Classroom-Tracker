import Foundation
import CryptoKit
import Security
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif


import AuthenticationServices

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

    private static let tokenUserDefaultsKey = "secure_oauth_tokens_cache"
    private var inMemoryTokens: OAuthTokens?

    private let scopes = [
        "openid",
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/userinfo.profile",
        "https://www.googleapis.com/auth/classroom.courses.readonly",
        "https://www.googleapis.com/auth/classroom.coursework.me.readonly",
        "https://www.googleapis.com/auth/classroom.student-submissions.me.readonly",
        "email",
        "profile"
    ]

    private var pendingCodeVerifier: String?
    private var pendingRedirectUri: String?
    private var lastRedeemedAuthCode: String?
    private var inFlightAuthCodes = Set<String>()
    private static let pendingVerifierKey = "cached_pending_oauth_verifier"

    private func savePendingVerifier(_ verifier: String) {
        self.pendingCodeVerifier = verifier
        UserDefaults.standard.set(verifier, forKey: Self.pendingVerifierKey)
    }

    private func loadPendingVerifier() -> String? {
        if let memory = pendingCodeVerifier, !memory.isEmpty {
            return memory
        }
        return UserDefaults.standard.string(forKey: Self.pendingVerifierKey)
    }

    private func clearPendingVerifier() {
        self.pendingCodeVerifier = nil
        UserDefaults.standard.removeObject(forKey: Self.pendingVerifierKey)
    }

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
            if self.currentUserEmail == nil {
                Task { [weak self] in
                    await self?.fetchUserInfo()
                }
            }
        } else {
            self.isAuthenticated = false
        }
    }

    public func startSignIn() async throws {
        self.authErrorMessage = nil
        let clientId = configuredClientId
        guard !clientId.isEmpty else {
            throw NSError(
                domain: "GoogleOAuthService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Vui lòng nhập Google Client ID trong phần Cài Đặt."]
            )
        }

        let verifier = generateCodeVerifier()
        savePendingVerifier(verifier)

        #if os(iOS)
        try await signInWithWebSession(clientId: clientId, verifier: verifier)
        #elseif os(macOS)
        do {
            try await signInWithWebSession(clientId: clientId, verifier: verifier)
        } catch {
            let isCanceled: Bool = {
                if let authError = error as? ASWebAuthenticationSessionError, authError.code == .canceledLogin {
                    return true
                }
                let nsError = error as NSError
                if (nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" && nsError.code == 1) ||
                   (nsError.domain == "GoogleOAuthService" && nsError.code == 499) {
                    return true
                }
                return false
            }()
            if isCanceled {
                throw error
            }
            try await signInWithLoopback(clientId: clientId, verifier: verifier)
        }
        #endif
    }

    @discardableResult
    public func handleIncomingURL(_ url: URL) async -> Bool {
        let scheme = url.scheme?.lowercased() ?? ""
        guard scheme == "classroomwidget" || scheme == "classroomtracker" || scheme.hasPrefix("com.googleusercontent.apps.") else {
            return false
        }

        var code: String?
        var error: String?

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            code = components.queryItems?.first(where: { $0.name == "code" })?.value
            error = components.queryItems?.first(where: { $0.name == "error" })?.value
        }

        // Fallback thủ công nếu URLComponents thất bại do ký tự đặc biệt
        if code == nil && error == nil {
            let queryString: String
            if let q = url.query {
                queryString = q
            } else if let qIdx = url.absoluteString.firstIndex(of: "?") {
                queryString = String(url.absoluteString[url.absoluteString.index(after: qIdx)...])
            } else {
                queryString = ""
            }

            if !queryString.isEmpty {
                for pair in queryString.components(separatedBy: "&") {
                    let parts = pair.components(separatedBy: "=")
                    if parts.count >= 2 {
                        let key = parts[0]
                        let val = parts[1...].joined(separator: "=").removingPercentEncoding ?? parts[1]
                        if key == "code" && code == nil {
                            code = val
                        } else if key == "error" && error == nil {
                            error = val
                        }
                    }
                }
            }
        }

        if let error {
            self.authErrorMessage = "Đăng nhập Google thất bại: \(error)"
            return false
        }

        if let code {
            if code == lastRedeemedAuthCode || inFlightAuthCodes.contains(code) {
                if self.isAuthenticated {
                    await ClassroomAPIService.shared.syncAll()
                    ClassroomStorage.shared.notifyWidgetReload()
                    return true
                }
                return false
            }

            inFlightAuthCodes.insert(code)
            defer { inFlightAuthCodes.remove(code) }

            let clientId = configuredClientId
            let verifier = self.pendingCodeVerifier ?? loadPendingVerifier() ?? ""

            // Hỗ trợ cả redirectUri của Loopback lẫn Custom URI scheme nếu người dùng dùng Custom Client ID (classroomwidget://oauth-callback)
            let redirectUri: String
            if let pending = self.pendingRedirectUri, !pending.isEmpty {
                redirectUri = pending
            } else if scheme.hasPrefix("com.googleusercontent.apps.") {
                redirectUri = "\(scheme):/oauth2redirect/google"
            } else {
                redirectUri = "classroomwidget://oauth-callback"
            }

            do {
                try await exchangeCodeForTokens(code: code, verifier: verifier, clientId: clientId, redirectUri: redirectUri)
                self.lastRedeemedAuthCode = code
                self.pendingRedirectUri = nil
                clearPendingVerifier()
                self.isAuthenticated = true
                await fetchUserInfo()
                await ClassroomAPIService.shared.syncAll()
                ClassroomStorage.shared.notifyWidgetReload()
                return true
            } catch {
                print("Lỗi đổi token trong handleIncomingURL: \(error.localizedDescription)")
                self.authErrorMessage = "Lỗi xác thực Google: \(error.localizedDescription)"
                return false
            }
        }

        let hostOrPath = (url.host ?? "") + url.path
        if hostOrPath.contains("auth-complete") || hostOrPath.contains("oauth-callback") {
            if self.isAuthenticated {
                await fetchUserInfo()
                await ClassroomAPIService.shared.syncAll()
                ClassroomStorage.shared.notifyWidgetReload()
                return true
            }
        }

        return false
    }

    #if os(iOS) || os(macOS)
    private func signInWithWebSession(clientId: String, verifier: String) async throws {
        let reversedClientId = clientId.components(separatedBy: ".").reversed().joined(separator: ".")
        let redirectUri = "\(reversedClientId):/oauth2redirect/google"
        let callbackScheme = reversedClientId

        let challenge = generateCodeChallenge(from: verifier)

        guard var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth") else {
            throw NSError(domain: "GoogleOAuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không thể tạo URL xác thực."])
        }
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "select_account consent")
        ]

        guard let authURL = components.url else {
            throw NSError(domain: "GoogleOAuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không thể tạo URL xác thực."])
        }

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let contextProvider = WebAuthPresentationContextProvider()
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { url, error in
                _ = contextProvider
                if let error {
                    if let authError = error as? ASWebAuthenticationSessionError, authError.code == .canceledLogin {
                        continuation.resume(throwing: NSError(
                            domain: "GoogleOAuthService",
                            code: 499,
                            userInfo: [NSLocalizedDescriptionKey: "Đã hủy đăng nhập Google."]
                        ))
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }

                guard let url else {
                    continuation.resume(throwing: NSError(
                        domain: "GoogleOAuthService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Không nhận được phản hồi từ Google."]
                    ))
                    return
                }

                continuation.resume(returning: url)
            }

            session.presentationContextProvider = contextProvider
            session.prefersEphemeralWebBrowserSession = false

            guard session.start() else {
                continuation.resume(throwing: NSError(
                    domain: "GoogleOAuthService",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Không thể mở trình xác thực đăng nhập Google."]
                ))
                return
            }
        }

        guard let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw NSError(domain: "GoogleOAuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "URL phản hồi không hợp lệ."])
        }

        if let oauthError = urlComponents.queryItems?.first(where: { $0.name == "error" })?.value {
            throw NSError(domain: "GoogleOAuthService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Đăng nhập Google thất bại: \(oauthError)"])
        }

        guard let code = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NSError(domain: "GoogleOAuthService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy mã xác thực Google."])
        }

        try await exchangeCodeForTokens(code: code, verifier: verifier, clientId: clientId, redirectUri: redirectUri)
        self.lastRedeemedAuthCode = code
        self.pendingRedirectUri = nil
        clearPendingVerifier()
        self.isAuthenticated = true
        await fetchUserInfo()
        await ClassroomAPIService.shared.syncAll()
        ClassroomStorage.shared.notifyWidgetReload()
    }
    #endif

    #if os(macOS)
    private func signInWithLoopback(clientId: String, verifier: String) async throws {
        let server = try LoopbackOAuthServer.shared.startServer()
        let loopbackRedirectUri = "http://127.0.0.1:\(server.port)"
        self.pendingRedirectUri = loopbackRedirectUri

        let challenge = generateCodeChallenge(from: verifier)

        guard var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth") else {
            throw NSError(domain: "GoogleOAuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không thể tạo URL xác thực."])
        }
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: loopbackRedirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "select_account consent")
        ]

        guard let authURL = components.url else {
            throw NSError(domain: "GoogleOAuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Không thể tạo URL xác thực."])
        }

        NSWorkspace.shared.open(authURL)

        let code = try await LoopbackOAuthServer.shared.waitForAuthorizationCode(server: server)
        try await exchangeCodeForTokens(code: code, verifier: verifier, clientId: clientId, redirectUri: loopbackRedirectUri)
        self.lastRedeemedAuthCode = code
        self.pendingRedirectUri = nil
        clearPendingVerifier()
        self.isAuthenticated = true
        await fetchUserInfo()
        await ClassroomAPIService.shared.syncAll()
        ClassroomStorage.shared.notifyWidgetReload()
    }
    #endif

    private static let formUrlAllowedCharacters: CharacterSet = {
        var characters = CharacterSet.alphanumerics
        characters.insert(charactersIn: "-._*")
        return characters
    }()

    private static func urlFormEncode(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: formUrlAllowedCharacters) ?? string
    }

    public func signOut() {
        deleteTokensFromKeychain()
        ClassroomStorage.shared.clearAllData()
        self.isAuthenticated = false
        self.currentUserEmail = nil
        self.currentUserName = nil
        self.currentUserAvatar = nil
        self.lastRedeemedAuthCode = nil
        clearPendingVerifier()
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
            "grant_type": "authorization_code",
            "redirect_uri": redirectUri
        ]

        let trimmedVerifier = verifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedVerifier.isEmpty {
            bodyParams["code_verifier"] = trimmedVerifier
        }

        let clientSecret = configuredClientSecret
        if !clientSecret.isEmpty {
            bodyParams["client_secret"] = clientSecret
        }

        let bodyString = bodyParams.map { "\(Self.urlFormEncode($0.key))=\(Self.urlFormEncode($0.value))" }.joined(separator: "&")
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

        if let idToken = tokenResponse.idToken, let payload = decodeJWTPayload(idToken) {
            if let email = payload["email"] as? String {
                self.currentUserEmail = email
                ClassroomStorage.shared.saveUserEmail(email)
            }
            if let name = payload["name"] as? String {
                self.currentUserName = name
            }
            if let picture = payload["picture"] as? String {
                self.currentUserAvatar = picture
            }
        }
    }

    private var refreshTask: Task<String, Error>?

    public func getValidAccessToken() async throws -> String {
        guard let tokens = loadTokensFromKeychain() else {
            throw NSError(domain: "GoogleOAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Chưa đăng nhập Google."])
        }

        if !tokens.isExpired {
            return tokens.accessToken
        }

        if let activeTask = refreshTask {
            return try await activeTask.value
        }

        let task = Task<String, Error> { @MainActor [weak self] () -> String in
            guard let self else {
                throw NSError(domain: "GoogleOAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Dịch vụ xác thực không khả dụng."])
            }
            defer { self.refreshTask = nil }

            guard let currentTokens = self.loadTokensFromKeychain(),
                  let refreshToken = currentTokens.refreshToken else {
                self.signOut()
                throw NSError(domain: "GoogleOAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Hết hạn phiên đăng nhập, vui lòng đăng nhập lại."])
            }

            let clientId = self.configuredClientId
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

            let clientSecret = self.configuredClientSecret
            if !clientSecret.isEmpty {
                bodyParams["client_secret"] = clientSecret
            }

            let bodyString = bodyParams.map { "\(Self.urlFormEncode($0.key))=\(Self.urlFormEncode($0.value))" }.joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "GoogleOAuthService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Không nhận được phản hồi từ Google."])
            }

            if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 {
                self.signOut()
                self.authErrorMessage = "Phiên đăng nhập đã hết hạn hoặc bị hủy trên Google. Vui lòng đăng nhập lại."
                throw NSError(domain: "GoogleOAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Phiên đăng nhập đã hết hạn hoặc bị hủy trên Google. Vui lòng đăng nhập lại."])
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "GoogleOAuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Không thể làm mới token (\(httpResponse.statusCode))."])
            }

            let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
            let newTokens = OAuthTokens(
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken ?? refreshToken,
                expiresIn: tokenResponse.expiresIn,
                expiresAt: Date().addingTimeInterval(Double(tokenResponse.expiresIn))
            )

            self.saveTokensToKeychain(tokens: newTokens)
            return newTokens.accessToken
        }

        self.refreshTask = task
        return try await task.value
    }

    public func fetchUserInfo() async {
        do {
            let accessToken = try await getValidAccessToken()
            guard let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo") else { return }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                let userInfo = try JSONDecoder().decode(GoogleUserInfo.self, from: data)
                self.currentUserEmail = userInfo.email
                self.currentUserName = userInfo.name
                self.currentUserAvatar = userInfo.picture
                ClassroomStorage.shared.saveUserEmail(userInfo.email)
            } else {
                // Fallback to openidconnect userinfo
                if let oidcUrl = URL(string: "https://openidconnect.googleapis.com/v1/userinfo") {
                    var oidcRequest = URLRequest(url: oidcUrl)
                    oidcRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    let (oidcData, oidcResponse) = try await URLSession.shared.data(for: oidcRequest)
                    if let oidcHttp = oidcResponse as? HTTPURLResponse, (200...299).contains(oidcHttp.statusCode) {
                        let userInfo = try JSONDecoder().decode(GoogleUserInfo.self, from: oidcData)
                        self.currentUserEmail = userInfo.email
                        self.currentUserName = userInfo.name
                        self.currentUserAvatar = userInfo.picture
                        ClassroomStorage.shared.saveUserEmail(userInfo.email)
                    }
                }
            }
        } catch {
            print("Lỗi lấy user info: \(error.localizedDescription)")
        }
    }

    private func decodeJWTPayload(_ jwt: String) -> [String: Any]? {
        let parts = jwt.components(separatedBy: ".")
        guard parts.count >= 2 else { return nil }
        var base64 = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
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

    private var allTokenDirectories: [URL] {
        ClassroomStorage.sharedStorageDirectories
    }

    private func saveTokensToKeychain(tokens: OAuthTokens) {
        self.inMemoryTokens = tokens
        ClassroomStorage.shared.saveUserLoggedIn(true)
        guard let data = try? JSONEncoder().encode(tokens) else { return }

        UserDefaults.standard.set(data, forKey: Self.tokenUserDefaultsKey)
        for ud in ClassroomStorage.shared.allUserDefaults {
            ud.set(data, forKey: Self.tokenUserDefaultsKey)
        }

        for dir in allTokenDirectories {
            let fileURL = dir.appendingPathComponent("cached_oauth_tokens.json")
            try? FileManager.default.removeItem(at: fileURL)
        }

        deleteKeychainOnly()

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "google_tokens",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif
        var status = SecItemAdd(query as CFDictionary, nil)
        #if os(macOS)
        if status != errSecSuccess {
            var legacyQuery = query
            legacyQuery.removeValue(forKey: kSecUseDataProtectionKeychain as String)
            status = SecItemAdd(legacyQuery as CFDictionary, nil)
        }
        #endif
    }

    private func loadTokensFromKeychain() -> OAuthTokens? {
        if let memory = inMemoryTokens, !memory.accessToken.isEmpty {
            return memory
        }

        // Keychain -> UserDefaults -> app group suites -> shared disk cache
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "google_tokens",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        var status = SecItemCopyMatching(query as CFDictionary, &item)
        #if os(macOS)
        if status != errSecSuccess {
            query[kSecUseDataProtectionKeychain as String] = true
            status = SecItemCopyMatching(query as CFDictionary, &item)
        }
        #endif
        if status == errSecSuccess, let data = item as? Data {
            if let decoded = try? JSONDecoder().decode(OAuthTokens.self, from: data) {
                self.inMemoryTokens = decoded
                return decoded
            }
        }

        if let data = UserDefaults.standard.data(forKey: Self.tokenUserDefaultsKey),
           let decoded = try? JSONDecoder().decode(OAuthTokens.self, from: data) {
            self.inMemoryTokens = decoded
            return decoded
        }

        for ud in ClassroomStorage.shared.allUserDefaults {
            if let data = ud.data(forKey: Self.tokenUserDefaultsKey),
               let decoded = try? JSONDecoder().decode(OAuthTokens.self, from: data) {
                self.inMemoryTokens = decoded
                return decoded
            }
        }

        for dir in allTokenDirectories {
            let fileURL = dir.appendingPathComponent("cached_oauth_tokens.json")
            if let data = try? Data(contentsOf: fileURL),
               let decoded = try? JSONDecoder().decode(OAuthTokens.self, from: data) {
                try? FileManager.default.removeItem(at: fileURL)
                self.inMemoryTokens = decoded
                return decoded
            }
        }

        return nil
    }

    private func deleteKeychainOnly() {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "google_tokens"
        ]
        #if os(macOS)
        query[kSecUseDataProtectionKeychain as String] = true
        #endif
        SecItemDelete(query as CFDictionary)
        #if os(macOS)
        query.removeValue(forKey: kSecUseDataProtectionKeychain as String)
        SecItemDelete(query as CFDictionary)
        #endif
    }

    private func deleteTokensFromKeychain() {
        self.inMemoryTokens = nil
        UserDefaults.standard.removeObject(forKey: Self.tokenUserDefaultsKey)
        for ud in ClassroomStorage.shared.allUserDefaults {
            ud.removeObject(forKey: Self.tokenUserDefaultsKey)
        }
        for dir in allTokenDirectories {
            let fileURL = dir.appendingPathComponent("cached_oauth_tokens.json")
            try? FileManager.default.removeItem(at: fileURL)
        }
        deleteKeychainOnly()
    }
}

private struct OAuthTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    let idToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case idToken = "id_token"
    }
}

private final class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    #if os(iOS)
    @MainActor
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow } ?? scenes.flatMap { $0.windows }.first
        return window ?? ASPresentationAnchor()
    }
    #elseif os(macOS)
    @MainActor
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let keyWindow = NSApplication.shared.keyWindow {
            return keyWindow
        }
        if let mainWindow = NSApplication.shared.mainWindow {
            return mainWindow
        }
        if let visibleWindow = NSApplication.shared.windows.first(where: { $0.isVisible && $0.canBecomeKey }) {
            return visibleWindow
        }
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }
    #endif
}

