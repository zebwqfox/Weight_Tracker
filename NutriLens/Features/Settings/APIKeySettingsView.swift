import SwiftUI

struct APIKeySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "deepseek_api_key") ?? ""
    @State private var selectedModel: String = UserDefaults.standard.string(forKey: "deepseek_model") ?? DeepSeekModel.v4Pro.rawValue
    @State private var isKeyVisible = false
    @State private var saved = false

    private var storedKey: String { UserDefaults.standard.string(forKey: "deepseek_api_key") ?? "" }
    private var storedModel: String { UserDefaults.standard.string(forKey: "deepseek_model") ?? DeepSeekModel.v4Pro.rawValue }
    private var isDirty: Bool { apiKey != storedKey || selectedModel != storedModel }

    var body: some View {
        NavigationStack {
            Form {
                // API Key
                Section {
                    HStack {
                        if isKeyVisible {
                            TextField("sk-...", text: $apiKey)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: $apiKey)
                                .font(.system(.body, design: .monospaced))
                        }
                        Button {
                            isKeyVisible.toggle()
                        } label: {
                            Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                } header: {
                    Label("DeepSeek API Key", systemImage: "key.fill")
                } footer: {
                    Text("密钥仅存储在本设备，不会上传任何服务器。")
                }

                // Model selection
                Section {
                    ForEach(DeepSeekModel.allCases, id: \.rawValue) { model in
                        Button {
                            selectedModel = model.rawValue
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: modelIcon(model))
                                    .font(.title3)
                                    .foregroundStyle(modelColor(model))
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(model.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text(modelDescription(model))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if selectedModel == model.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                } header: {
                    Text("模型选择")
                } footer: {
                    Text("V4-Pro 精度更高，V4-Flash 响应更快，均原生支持多模态图像理解。")
                }

                // Help links
                Section {
                    Link(destination: URL(string: "https://platform.deepseek.com/api_keys")!) {
                        Label("获取 API Key", systemImage: "arrow.up.right.square")
                    }
                    Link(destination: URL(string: "https://platform.deepseek.com/docs")!) {
                        Label("DeepSeek 开发文档", systemImage: "book")
                    }
                } header: {
                    Text("帮助")
                }

                if !apiKey.isEmpty {
                    Section {
                        Button("清除 API Key", role: .destructive) {
                            apiKey = ""
                        }
                    }
                }
            }
            .navigationTitle("AI 设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        UserDefaults.standard.set(apiKey, forKey: "deepseek_api_key")
                        UserDefaults.standard.set(selectedModel, forKey: "deepseek_model")
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isDirty)
                }
            }
            .overlay {
                if saved {
                    VStack {
                        Spacer()
                        Label("已保存", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.green, in: Capsule())
                            .padding(.bottom, 40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring, value: saved)
                }
            }
        }
    }

    private func modelIcon(_ model: DeepSeekModel) -> String {
        switch model {
        case .v4Pro:   return "brain.head.profile"
        case .v4Flash: return "bolt.fill"
        }
    }

    private func modelColor(_ model: DeepSeekModel) -> Color {
        switch model {
        case .v4Pro:   return .purple
        case .v4Flash: return .orange
        }
    }

    private func modelDescription(_ model: DeepSeekModel) -> String {
        switch model {
        case .v4Pro:   return "深度多模态推理 · 高精度识别"
        case .v4Flash: return "极速响应 · 日常分析首选"
        }
    }
}

#Preview {
    APIKeySettingsView()
}
