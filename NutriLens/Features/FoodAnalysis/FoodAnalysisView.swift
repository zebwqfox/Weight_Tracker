import SwiftUI
import PhotosUI

struct FoodAnalysisView: View {
    @State private var viewModel = FoodAnalysisViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero card
                    photoSelectionCard

                    // Meal type picker
                    if viewModel.selectedImage != nil {
                        mealTypePicker
                        analyzeButton
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("拍照分析")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("设置") {
                        showSettings = true
                    }
                    .buttonStyle(.borderless)
                }
            }
            .sheet(isPresented: $showSettings) {
                APIKeySettingsView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.showResult) {
                if let info = viewModel.nutritionInfo {
                    FoodResultView(
                        nutrition: info,
                        image: viewModel.selectedImage,
                        mealType: viewModel.mealType,
                        onSave: { viewModel.reset() }
                    )
                }
            }
            .alert("分析失败", isPresented: $viewModel.showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(viewModel.error ?? "未知错误")
            }
            .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
                Task { await viewModel.loadImage(from: newItem) }
            }
        }
    }

    private var photoSelectionCard: some View {
        VStack(spacing: 16) {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            viewModel.selectedImage = nil
                            viewModel.selectedPhotoItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                        }
                        .padding(12)
                    }
            } else {
                emptyPhotoPlaceholder
            }
        }
    }

    private var emptyPhotoPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("拍摄或选择今天的餐食")
                .font(.title3)
                .fontWeight(.semibold)

            Text("AI 将识别菜品并计算热量")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                Button {
                    viewModel.showCamera = true
                } label: {
                    Label("拍照", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.quaternary, lineWidth: 2)
        )
        .fullScreenCover(isPresented: $viewModel.showCamera) {
            CameraPickerView(image: $viewModel.selectedImage)
                .ignoresSafeArea()
        }
    }

    private var mealTypePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("餐食类型")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FoodEntry.mealTypes, id: \.self) { type in
                        Button(type) {
                            viewModel.mealType = type
                        }
                        .buttonStyle(.bordered)
                        .tint(viewModel.mealType == type ? Color.accentColor : Color.secondary)
                        .fontWeight(viewModel.mealType == type ? .semibold : .regular)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var analyzeButton: some View {
        Button {
            Task { await viewModel.analyze() }
        } label: {
            Group {
                if viewModel.isAnalyzing {
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("AI 分析中...")
                    }
                } else {
                    Label("开始分析", systemImage: "sparkles")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isAnalyzing)
        .controlSize(.large)
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    FoodAnalysisView()
        .modelContainer(for: [FoodEntry.self], inMemory: true)
}
