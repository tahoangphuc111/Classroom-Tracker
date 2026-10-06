import Foundation
#if canImport(AppKit)
import AppKit
#endif


public struct ActiveLoopbackServer {
    public let serverFd: Int32
    public let port: Int
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
            close(serverFd)
            throw NSError(domain: "LoopbackOAuthServer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Không thể bind socket tới 127.0.0.1"])
        }

        var actualAddress = sockaddr_in()
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        withUnsafeMutablePointer(to: &actualAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(serverFd, $0, &len)
            }
        }
        let port = Int(UInt16(bigEndian: actualAddress.sin_port))

        guard listen(serverFd, 1) == 0 else {
            close(serverFd)
            throw NSError(domain: "LoopbackOAuthServer", code: -3, userInfo: [NSLocalizedDescriptionKey: "Không thể lắng nghe kết nối"])
        }

        return ActiveLoopbackServer(serverFd: serverFd, port: port)
    }

    public func waitForAuthorizationCode(server: ActiveLoopbackServer, timeoutSeconds: Int = 180) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
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

                    if let queryStart = requestString.range(of: "GET /")?.upperBound,
                       let queryEnd = requestString.range(of: " HTTP/")?.lowerBound {
                        let pathAndQuery = String(requestString[queryStart..<queryEnd])
                        let fullUrlString = "http://127.0.0.1:\(port)/\(pathAndQuery)"
                        if let components = URLComponents(string: fullUrlString) {
                            authCode = components.queryItems?.first(where: { $0.name == "code" })?.value
                            oauthError = components.queryItems?.first(where: { $0.name == "error" })?.value
                        }
                    }

                    if let oauthError {
                        let errorHtml = """
                        <!DOCTYPE html>
                        <html lang="vi">
                        <head><meta charset="utf-8"><title>Đăng nhập không thành công</title></head>
                        <body style="font-family:sans-serif;background:#0f172a;color:#f8fafc;display:flex;align-items:center;justify-content:center;height:100vh;">
                          <div style="background:#1e293b;padding:32px;border-radius:16px;text-align:center;">
                            <h2 style="color:#ef4444;">Đăng nhập bị từ chối (\(oauthError))</h2>
                            <p style="color:#94a3b8;">Bạn có thể đóng tab này và thử lại trong ứng dụng.</p>
                          </div>
                        </body></html>
                        """
                        let errorResponse = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(errorHtml.utf8.count)\r\nConnection: close\r\n\r\n\(errorHtml)"
                        _ = errorResponse.withCString { send(clientFd, $0, strlen($0), 0) }
                        close(clientFd)
                        close(serverFd)
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

                        close(clientFd)
                        close(serverFd)
                        continuation.resume(returning: authCode)
                        return
                    }

                    close(clientFd)
                }

                close(serverFd)
                continuation.resume(throwing: NSError(domain: "LoopbackOAuthServer", code: -4, userInfo: [NSLocalizedDescriptionKey: "Hết thời gian chờ đăng nhập (Timeout). Vui lòng thử lại."]))
            }
        }
    }
}
