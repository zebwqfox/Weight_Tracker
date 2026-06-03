import SwiftUI

struct OAuthLoginView: View {
    let code: String
    let appName: String
    let domain: String
    let onComplete: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var authState: AuthState = .pending
    @State private var showDetails = false

    enum AuthState {
        case pending, authorizing, approved, denied
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main content
                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        deviceSection
                        permissionsSection
                        if showDetails {
                            detailsSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 20)
                }

                // Action buttons
                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                    .background(.background)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                        onComplete()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .overlay {
                if authState == .authorizing {
                    loadingOverlay
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 16) {
            // App icon placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)

                Image(systemName: "globe")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("登录此设备？")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(appName) 正在请求授权登录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var deviceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("设备信息", systemImage: "iphone")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Image(systemName: "iphone.gen3")
                    .font(.title)
                    .foregroundStyle(.tint)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(UIDevice.current.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("iOS \(UIDevice.current.systemVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("刚刚扫描")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Spacer()

                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.green)
            }
            .padding(14)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("授权内容", systemImage: "lock.shield")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                PermissionRow(
                    icon: "person.fill",
                    color: .blue,
                    title: "访问你的账户信息",
                    description: "姓名和头像"
                )
                Divider().padding(.leading, 52)
                PermissionRow(
                    icon: "envelope.fill",
                    color: .orange,
                    title: "查看邮件地址",
                    description: "用于账户验证"
                )
                Divider().padding(.leading, 52)
                PermissionRow(
                    icon: "clock.fill",
                    color: .purple,
                    title: "保持登录状态",
                    description: "30天内免重新登录"
                )
            }
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("技术详情", systemImage: "info.circle")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "来源", value: domain)
                DetailRow(label: "授权码", value: String(code.suffix(16)))
                DetailRow(label: "协议", value: "OAuth 2.0 Device Flow")
                DetailRow(label: "过期时间", value: "15 分钟")
            }
            .padding(14)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var primaryButtonStyle: AnyShapeStyle {
        authState == .approved ? AnyShapeStyle(Color.brand) : AnyShapeStyle(LinearGradient.oauth)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                authorize()
            } label: {
                Group {
                    if authState == .approved {
                        Label("授权成功", systemImage: "checkmark.circle.fill")
                    } else {
                        Text("授权登录此设备")
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(primaryButtonStyle, in: RoundedRectangle(cornerRadius: DS.innerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            }
            .disabled(authState != .pending)

            Button {
                withAnimation { authState = .denied }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    dismiss()
                    onComplete()
                }
            } label: {
                Text("拒绝")
                    .font(.headline)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: DS.innerRadius, style: .continuous))
            }
            .disabled(authState != .pending)

            Button {
                withAnimation(.spring) { showDetails.toggle() }
            } label: {
                Text(showDetails ? "收起详情" : "查看详情")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.4)
                    .tint(.white)

                Text("正在授权...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - Actions

    private func authorize() {
        withAnimation {
            authState = .authorizing
        }
        // Simulate OAuth handshake
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                authState = .approved
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dismiss()
                onComplete()
            }
        }
    }
}

// MARK: - Supporting Views

struct PermissionRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

#Preview {
    OAuthLoginView(
        code: "https://example.com/oauth/device?code=ABCD-1234",
        appName: "Example 账户",
        domain: "example.com",
        onComplete: {}
    )
}
