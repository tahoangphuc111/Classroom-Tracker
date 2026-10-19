import Foundation
#if canImport(AppKit)
import AppKit
#endif


public final class SafeSocketHandle: @unchecked Sendable {
    private var fd: Int32
    private let lock = NSLock()
    private var isClosed = false

    public init(fd: Int32) {
        self.fd = fd
    }

    public var rawDescriptor: Int32 {
        lock.lock()
        defer { lock.unlock() }
        return isClosed ? -1 : fd
    }

    public func close() {
        lock.lock()
        defer { lock.unlock() }
        guard !isClosed, fd >= 0 else { return }
        isClosed = true
        Darwin.close(fd)
        fd = -1
    }
}

public struct ActiveLoopbackServer: Sendable {
    public let serverFd: Int32
    public let port: Int
    public let handle: SafeSocketHandle

    public init(serverFd: Int32, port: Int, handle: SafeSocketHandle? = nil) {
        self.serverFd = serverFd
        self.port = port
        self.handle = handle ?? SafeSocketHandle(fd: serverFd)
    }
}

public final class LoopbackOAuthServer: @unchecked Sendable {
    public static let shared = LoopbackOAuthServer()
    private init() {}

    public func startServer() throws -> ActiveLoopbackServer {
        let serverFd = socket(AF_INET, SOCK_STREAM, 0)
        guard serverFd >= 0 else {
            throw NSError(domain: "LoopbackOAuthServer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không thể tạo socket cục bộ"])
        }

        var opt: Int32 = 1
        setsockopt(serverFd, SOL_SOCKET, SO_REUSEADDR, &opt, socklen_t(MemoryLayout<Int32>.size))
        #if os(macOS) || os(iOS)
        var nosigpipe: Int32 = 1
        setsockopt(serverFd, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, socklen_t(MemoryLayout<Int32>.size))
        #endif

        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        address.sin_port = in_port_t(0).bigEndian

        let bindResult = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(serverFd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult == 0 else {
            Darwin.close(serverFd)
            throw NSError(domain: "LoopbackOAuthServer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Không thể bind socket tới 127.0.0.1"])
        }

        var actualAddress = sockaddr_in()
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        let getSockNameResult = withUnsafeMutablePointer(to: &actualAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(serverFd, $0, &len)
            }
        }
        guard getSockNameResult == 0 else {
            Darwin.close(serverFd)
            throw NSError(domain: "LoopbackOAuthServer", code: -3, userInfo: [NSLocalizedDescriptionKey: "Không thể lấy thông tin cổng kết nối"])
        }
        let port = Int(UInt16(bigEndian: actualAddress.sin_port))

        guard listen(serverFd, 10) == 0 else {
            Darwin.close(serverFd)
            throw NSError(domain: "LoopbackOAuthServer", code: -4, userInfo: [NSLocalizedDescriptionKey: "Không thể lắng nghe kết nối"])
        }

        let handle = SafeSocketHandle(fd: serverFd)
        return ActiveLoopbackServer(serverFd: serverFd, port: port, handle: handle)
    }

    public func waitForAuthorizationCode(server: ActiveLoopbackServer, timeoutSeconds: Int = 180) async throws -> String {
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let serverFd = server.serverFd
                    let port = server.port

                    let startTime = Date()

                    while Date().timeIntervalSince(startTime) < Double(timeoutSeconds) {
                        var pfd = pollfd(fd: serverFd, events: Int16(POLLIN), revents: 0)
                        let pollRes = poll(&pfd, 1, 1000)
                        if pollRes < 0 {
                            if errno == EINTR { continue }
                            break
                        }
                        if pollRes == 0 {
                            continue
                        }

                        var clientAddress = sockaddr_in()
                        var clientLen = socklen_t(MemoryLayout<sockaddr_in>.size)
                        let clientFd = withUnsafeMutablePointer(to: &clientAddress) {
                            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                                accept(serverFd, $0, &clientLen)
                            }
                        }

                        guard clientFd >= 0 else {
                            continue
                        }

                        #if os(macOS) || os(iOS)
                        var clientNoSigPipe: Int32 = 1
                        setsockopt(clientFd, SOL_SOCKET, SO_NOSIGPIPE, &clientNoSigPipe, socklen_t(MemoryLayout<Int32>.size))
                        #endif

                        var buffer = [CChar](repeating: 0, count: 4096)
                        let bytesRead = recv(clientFd, &buffer, buffer.count - 1, 0)
                    if bytesRead <= 0 {
                        close(clientFd)
                        continue
                    }

                    let requestString = String(cString: buffer)

                    if requestString.contains("GET /favicon.ico") {
                        let notFoundResponse = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
                        _ = notFoundResponse.withCString { send(clientFd, $0, strlen($0), 0) }
                        close(clientFd)
                        continue
                    }

                    var authCode: String?
                    var oauthError: String?

                    // Tách chính xác request URI giữa "GET " và " HTTP/"
                    if let uriStart = requestString.range(of: "GET ")?.upperBound,
                       let uriEnd = requestString.range(of: " HTTP/")?.lowerBound,
                       uriStart < uriEnd {
                        let rawUri = String(requestString[uriStart..<uriEnd])
                        let uri = rawUri.hasPrefix("/") ? rawUri : "/" + rawUri
                        let fullUrlString = "http://127.0.0.1:\(port)\(uri)"

                        if let components = URLComponents(string: fullUrlString) {
                            authCode = components.queryItems?.first(where: { $0.name == "code" })?.value
                            oauthError = components.queryItems?.first(where: { $0.name == "error" })?.value
                        }

                        // Fallback parse query params nếu URLComponents trả về nil hoặc bị lỗi do ký tự đặc biệt
                        if authCode == nil && oauthError == nil {
                            let queryString: String
                            if let qIndex = uri.firstIndex(of: "?") {
                                queryString = String(uri[uri.index(after: qIndex)...])
                            } else {
                                queryString = uri
                            }

                            for param in queryString.components(separatedBy: "&") {
                                let parts = param.components(separatedBy: "=")
                                if parts.count >= 2 {
                                    let key = parts[0]
                                    let val = parts[1...].joined(separator: "=").removingPercentEncoding ?? parts[1]
                                    if key == "code" && authCode == nil {
                                        authCode = val
                                    } else if key == "error" && oauthError == nil {
                                        oauthError = val
                                    }
                                }
                            }
                        }
                    }

                    if let oauthError {
                        let errorHtml = """
                        <!DOCTYPE html>
                        <html lang="vi">
                        <head>
                          <meta charset="utf-8">
                          <meta name="viewport" content="width=device-width, initial-scale=1">
                          <title>Classroom Tracker - Đăng nhập không thành công</title>
                          <style>
                            body {
                              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                              background: #0f172a;
                              color: #f8fafc;
                              display: flex;
                              align-items: center;
                              justify-content: center;
                              height: 100vh;
                              margin: 0;
                            }
                            .card {
                              background: #1e293b;
                              padding: 40px 32px;
                              border-radius: 20px;
                              box-shadow: 0 20px 40px rgba(0,0,0,0.6);
                              text-align: center;
                              max-width: 400px;
                              border: 1px solid rgba(255,255,255,0.08);
                            }
                            h1 { color: #ef4444; font-size: 22px; margin: 0 0 10px 0; }
                            p { color: #94a3b8; font-size: 14px; line-height: 1.6; margin: 0 0 20px 0; }
                            .badge {
                              display: inline-block;
                              background: #dc2626;
                              color: white;
                              padding: 8px 18px;
                              border-radius: 999px;
                              font-weight: 600;
                              font-size: 13px;
                            }
                          </style>
                        </head>
                        <body>
                          <div class="card">
                            <div style="margin-bottom: 16px;">
                              <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:inline-block;"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
                            </div>
                            <h1>Đăng nhập không thành công</h1>
                            <p>Đăng nhập bị từ chối (\(oauthError)). Bạn có thể đóng tab này và thử lại trong ứng dụng.</p>
                            <div class="badge">Đã hủy hoặc có lỗi</div>
                            <script>
                              setTimeout(function() {
                                window.location.href = "classroomwidget://auth-complete?error=" + encodeURIComponent("\(oauthError)");
                              }, 800);
                            </script>
                            <div style="margin-top: 18px;">
                              <a href="classroomwidget://auth-complete?error=\(oauthError)" style="color: #ef4444; font-size: 13px; text-decoration: underline;">Quay lại Classroom Tracker</a>
                            </div>
                          </div>
                        </body>
                        </html>
                        """
                        let errorResponse = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(errorHtml.utf8.count)\r\nConnection: close\r\n\r\n\(errorHtml)"
                        _ = errorResponse.withCString { send(clientFd, $0, strlen($0), 0) }
                        Darwin.close(clientFd)
                        server.handle.close()
                        continuation.resume(throwing: NSError(domain: "LoopbackOAuthServer", code: -7, userInfo: [NSLocalizedDescriptionKey: "Đăng nhập Google bị hủy: \(oauthError)"]))
                        return
                    }

                    if let authCode {
                        let html = """
                        <!DOCTYPE html>
                        <html lang="vi">
                        <head>
                          <meta charset="utf-8">
                          <meta name="viewport" content="width=device-width, initial-scale=1">
                          <title>Classroom Tracker - Đăng nhập thành công</title>
                          <style>
                            body {
                              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                              background: #0f172a;
                              color: #f8fafc;
                              display: flex;
                              align-items: center;
                              justify-content: center;
                              height: 100vh;
                              margin: 0;
                            }
                            .card {
                              background: #1e293b;
                              padding: 40px 32px;
                              border-radius: 20px;
                              box-shadow: 0 20px 40px rgba(0,0,0,0.6);
                              text-align: center;
                              max-width: 400px;
                              border: 1px solid rgba(255,255,255,0.08);
                            }
                            h1 { color: #38bdf8; font-size: 22px; margin: 0 0 10px 0; }
                            p { color: #94a3b8; font-size: 14px; line-height: 1.6; margin: 0 0 20px 0; }
                            .badge {
                              display: inline-block;
                              background: #0284c7;
                              color: white;
                              padding: 8px 18px;
                              border-radius: 999px;
                              font-weight: 600;
                              font-size: 13px;
                            }
                          </style>
                        </head>
                        <body>
                          <div class="card">
                            <div style="margin-bottom: 16px;">
                              <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:inline-block;"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
                            </div>
                            <h1>Kết nối thành công!</h1>
                            <p>Tài khoản Google Classroom của bạn đã kết nối thành công với Classroom Tracker.</p>
                            <div class="badge">Bạn có thể đóng tab này</div>
                            <script>
                              setTimeout(function() {
                                window.location.href = "classroomwidget://auth-complete";
                              }, 400);
                            </script>
                            <div style="margin-top: 18px;">
                              <a href="classroomwidget://auth-complete" style="color: #38bdf8; font-size: 13px; text-decoration: underline;">Mở ứng dụng Classroom Tracker</a>
                            </div>
                          </div>
                        </body>
                        </html>
                        """

                        let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(html.utf8.count)\r\nConnection: close\r\n\r\n\(html)"
                        _ = response.withCString { send(clientFd, $0, strlen($0), 0) }

                        Darwin.close(clientFd)
                        server.handle.close()
                        #if canImport(AppKit)
                        DispatchQueue.main.async {
                            NSApplication.shared.activate(ignoringOtherApps: true)
                        }
                        #endif
                        continuation.resume(returning: authCode)
                        return
                    }

                    Darwin.close(clientFd)
                }

                let wasCancelled = server.handle.rawDescriptor == -1
                server.handle.close()
                if wasCancelled {
                    continuation.resume(throwing: CancellationError())
                } else {
                    continuation.resume(throwing: NSError(domain: "LoopbackOAuthServer", code: -4, userInfo: [NSLocalizedDescriptionKey: "Hết thời gian chờ đăng nhập (Timeout). Vui lòng thử lại."]))
                }
            }
        }
    } onCancel: {
        server.handle.close()
    }
}
}

