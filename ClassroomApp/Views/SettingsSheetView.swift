import SwiftUI

struct SettingsSheetView: View {
    @ObservedObject var authService: GoogleOAuthService
    @ObservedObject var apiService: ClassroomAPIService
    @ObservedObject var reminderService: EveningReminderService
    @ObservedObject var updateService: AppUpdateService

    @Binding var isPresented: Bool
    @Binding var showLogoutConfirmation: Bool
    @Binding var isDemoMode: Bool
    @Binding var clientIdInput: String
    @Binding var clientSecretInput: String
    @Binding var isAdvancedSettingsExpanded: Bool

    let onRefreshData: () -> Void
    let onAutoSelectFirstItem: () -> Void
    let onTriggerHaptic: () -> Void
    let onShowToast: (String, String?, String, Color) -> Void
    let onStartGoogleLogin: () -> Void

    var body: some View {
        #if os(macOS)
        VStack(spacing: 0) {
            headerBar
            Divider()
            formContent
            Divider()
            footerBar
        }
        .frame(minWidth: 540, idealWidth: 580, maxWidth: 640, minHeight: 520, idealHeight: 600, maxHeight: 720)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .appleLiquidGlassSurface(style: .regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous)) {
                    Color.platformWindowBackground
                }
        }
        .confirmationDialog(
            "Đăng xuất khỏi Google?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Đăng xuất và xóa cache", role: .destructive) {
                authService.signOut(includePersonalNotes: false)
                ClassroomStorage.shared.clearAllData(includePersonalNotes: false)
                isDemoMode = false
                onRefreshData()
                onAutoSelectFirstItem()
                isPresented = false
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Bạn có chắc chắn muốn đăng xuất tài khoản Google? Dữ liệu bài tập offline trên thiết bị sẽ được xóa.")
        }
        #else
        NavigationStack {
            formContent
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .navigationTitle("Cài đặt")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .confirmationDialog(
                    "Đăng xuất khỏi Google?",
                    isPresented: $showLogoutConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Đăng xuất và xóa cache", role: .destructive) {
                        authService.signOut(includePersonalNotes: false)
                        ClassroomStorage.shared.clearAllData(includePersonalNotes: false)
                        isDemoMode = false
                        onRefreshData()
                        onAutoSelectFirstItem()
                        isPresented = false
                    }
                    Button("Hủy", role: .cancel) {}
                } message: {
                    Text("Bạn có chắc chắn muốn đăng xuất tài khoản Google? Dữ liệu bài tập offline trên thiết bị sẽ được xóa.")
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Xong") {
                            onTriggerHaptic()
                            isPresented = false
                        }
                        .buttonStyle(SpringPressButtonStyle(scale: 0.92, pressedOpacity: 0.88))
                        .keyboardShortcut(.defaultAction)
                        .fontWeight(.semibold)
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground {
            Rectangle()
                .fill(.ultraThinMaterial)
                .appleLiquidGlassSurface(style: .regular, in: Rectangle()) {
                    Color.platformWindowBackground.opacity(0.85)
                }
        }
        #endif
    }

    #if os(macOS)
    private var headerBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Color.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Cài đặt")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.platformTextPrimary)
                    Text("Tài khoản, báo bài buổi tối và cấu hình hệ thống")
                        .font(.system(size: 13.5))
                        .foregroundStyle(Color.platformTextSecondary)
                }
            }

            Spacer()

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.secondary.opacity(0.75))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .help("Đóng cửa sổ cài đặt (Esc)")
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .background(Color.platformSubtleFill.opacity(0.15))
    }

    private var footerBar: some View {
        HStack {
            Text("Nhấn phím Esc để đóng nhanh")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.secondary)

            Spacer()

            Button("Xong") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(Color.platformSubtleFill.opacity(0.2))
    }
    #endif

    private var formContent: some View {
        Form {
                Section {
                    if authService.isAuthenticated {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.blue)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(authService.currentUserName ?? "Tài khoản Google")
                                    .font(.system(size: 15.5, weight: .semibold))
                                    .foregroundStyle(.primary)

                                Text(authService.currentUserEmail ?? "Không rõ")
                                    .font(.system(size: 13.5))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)

                        Button {
                            Task {
                                onTriggerHaptic()
                                await apiService.syncAll()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    onRefreshData()
                                }
                                if let error = apiService.syncErrorMessage {
                                    onShowToast(
                                        "Đồng bộ thất bại",
                                        error,
                                        "exclamationmark.triangle.fill",
                                        .red
                                    )
                                } else {
                                    onShowToast(
                                        "Đồng bộ hoàn tất!",
                                        "Đã cập nhật dữ liệu mới nhất từ Classroom",
                                        "checkmark.circle.fill",
                                        .green
                                    )
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .rotationEffect(.degrees(apiService.isSyncing ? 360 : 0))
                                    .animation(
                                        apiService.isSyncing
                                            ? .linear(duration: 0.9).repeatForever(autoreverses: false)
                                            : .default,
                                        value: apiService.isSyncing
                                    )
                                Text(apiService.isSyncing ? "Đang đồng bộ..." : "Đồng bộ bài tập ngay")
                            }
                        }
                        .buttonStyle(SpringPressButtonStyle(scale: 0.96))
                        .disabled(apiService.isSyncing)

                        Button("Đăng xuất", role: .destructive) {
                            onTriggerHaptic()
                            showLogoutConfirmation = true
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Chưa kết nối tài khoản Google Classroom")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)

                            Text("Đăng nhập để đồng bộ bài tập và hạn chót từ các lớp học của bạn.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)

                        Button {
                            onTriggerHaptic()
                            isPresented = false
                            onStartGoogleLogin()
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.key.fill")
                                Text("Đăng nhập bằng Google")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SpringPressButtonStyle(scale: 0.96))
                    }
                } header: {
                    Label("Tài khoản", systemImage: "person.crop.circle")
                }

                Section {
                    Toggle("Nhắc nhở mỗi tối", isOn: Binding(
                        get: { reminderService.isEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let granted = await reminderService.requestAuthorization()
                                    if granted {
                                        reminderService.isEnabled = true
                                    } else {
                                        reminderService.isEnabled = false
                                        onShowToast(
                                            "Chưa cấp quyền thông báo",
                                            "Vui lòng bật quyền Thông báo trong Cài đặt hệ thống để nhận báo bài",
                                            "bell.slash",
                                            .orange
                                        )
                                    }
                                }
                            } else {
                                reminderService.isEnabled = false
                            }
                        }
                    ))
                    .toggleStyle(.switch)

                    if reminderService.isEnabled {
                        DatePicker(
                            "Giờ báo bài",
                            selection: Binding(
                                get: {
                                    var c = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: Date())
                                    c.hour = reminderService.reminderHour
                                    c.minute = reminderService.reminderMinute
                                    return Calendar.autoupdatingCurrent.date(from: c) ?? Date()
                                },
                                set: { newDate in
                                    let comps = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: newDate)
                                    reminderService.setReminderTime(hour: comps.hour ?? 20, minute: comps.minute ?? 0)
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        #if os(macOS)
                        .datePickerStyle(.stepperField)
                        #endif

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Xem trước thông báo:")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text(reminderService.previewNotificationText())
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.platformSubtleFill)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Label("Báo bài buổi tối", systemImage: "moon.stars.fill")
                } footer: {
                    Text("Ứng dụng tự động thông báo tóm tắt các bài tập cần nộp vào ngày mai để bạn chuẩn bị tập vở và soạn cặp.")
                }

                Section {
                    HStack {
                        Text("Phiên bản hiện tại:")
                        Spacer()
                        Text("v\(updateService.currentVersion)")
                            .foregroundStyle(.secondary)
                    }

                    if !updateService.statusMessage.isEmpty {
                        Text(updateService.statusMessage)
                            .font(.caption2)
                            .foregroundStyle(updateService.updateAvailable ? .blue : .secondary)
                    }

                    if updateService.updateAvailable {
                        Button {
                            Task {
                                await updateService.downloadAndInstall()
                            }
                        } label: {
                            HStack {
                                if updateService.isDownloading {
                                    ProgressView().controlSize(.small)
                                    Text("Đang tải bản cập nhật...")
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Cập nhật lên v\(updateService.latestVersion) ngay")
                                }
                            }
                        }
                        .disabled(updateService.isDownloading)
                    } else {
                        Button {
                            Task {
                                await updateService.checkForUpdates(isUserInitiated: true)
                            }
                        } label: {
                            HStack {
                                if updateService.isChecking {
                                    ProgressView().controlSize(.small)
                                    Text("Đang kiểm tra...")
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Kiểm tra bản cập nhật mới")
                                }
                            }
                        }
                        .disabled(updateService.isChecking)
                    }
                } header: {
                    Label("Cập nhật ứng dụng", systemImage: "arrow.triangle.2.circlepath")
                }

                Section {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { isAdvancedSettingsExpanded },
                            set: { newValue in
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                    isAdvancedSettingsExpanded = newValue
                                }
                            }
                        ),
                        content: {
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Dữ liệu thử nghiệm")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Text("Dùng để kiểm tra giao diện và thẻ bài tập khi không có dữ liệu thật.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Button("Nạp lại dữ liệu mẫu (Hôm nay & mai)") {
                                        onTriggerHaptic()
                                        ClassroomStorage.shared.saveCourses(ClassroomStorage.mockCourses)
                                        ClassroomStorage.shared.saveCoursework(ClassroomStorage.mockCoursework)
                                        onRefreshData()
                                        onAutoSelectFirstItem()
                                        onShowToast(
                                            "Đã nạp lại dữ liệu mẫu!",
                                            "Bao gồm các bài tập mẫu cho hôm nay & ngày mai",
                                            "sparkles",
                                            .purple
                                        )
                                    }
                                    .buttonStyle(SpringPressButtonStyle(scale: 0.96))
                                    .font(.system(size: 12))
                                }

                                Divider()

                                #if os(macOS)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("GitHub Token (Tùy chọn)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Text("Chỉ cần thiết nếu kiểm tra bản cập nhật từ kho lưu trữ GitHub riêng tư.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    TextField("GitHub Personal Access Token", text: Binding(
                                        get: { updateService.githubToken },
                                        set: { updateService.githubToken = $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                                }

                                Divider()
                                #endif

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Cấu hình Google Client ID riêng")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Text("Ứng dụng đã có sẵn Google Client ID mặc định. Người dùng thông thường không cần chỉnh sửa phần này.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Client ID:")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        TextField("Google Client ID", text: $clientIdInput)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 12, design: .monospaced))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Client Secret (Tùy chọn):")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        SecureField("Google Client Secret", text: $clientSecretInput)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.system(size: 12, design: .monospaced))
                                    }

                                    HStack {
                                        Button("Khôi phục mặc định") {
                                            clientIdInput = GoogleOAuthService.bundledClientId
                                             clientSecretInput = GoogleOAuthService.bundledClientSecret
                                            authService.configuredClientId = GoogleOAuthService.bundledClientId
                                            authService.configuredClientSecret = GoogleOAuthService.bundledClientSecret
                                            onShowToast(
                                                "Đã khôi phục Client ID mặc định",
                                                nil,
                                                "arrow.counterclockwise",
                                                .blue
                                            )
                                        }
                                        .font(.system(size: 12))

                                        Spacer()

                                        Button("Lưu Client ID riêng") {
                                            authService.configuredClientId = clientIdInput
                                            authService.configuredClientSecret = clientSecretInput
                                            onShowToast(
                                                "Đã lưu cấu hình Client ID",
                                                nil,
                                                "checkmark.circle.fill",
                                                .green
                                            )
                                        }
                                        .font(.system(size: 12, weight: .semibold))
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.vertical, 6)
                        },
                        label: {
                            Label("Tùy chọn nâng cao", systemImage: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .medium))
                        }
                    )
                } header: {
                    Text("Dành cho nhà phát triển")
                }

                Section {
                    HStack {
                        Label("Hệ điều hành", systemImage: "apple.logo")
                        Spacer()
                        Text(AppleOSDetector.currentOSDescription)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Giao diện Liquid Glass", systemImage: "sparkles")
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppleOSDetector.supportsLiquidGlass ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(AppleOSDetector.supportsLiquidGlass ? "Hoạt động" : "Tương thích")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppleOSDetector.supportsLiquidGlass ? Color.green : Color.secondary)
                        }
                    }
                } header: {
                    Label("Thiết bị & Hệ thống", systemImage: "cpu")
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
    }
