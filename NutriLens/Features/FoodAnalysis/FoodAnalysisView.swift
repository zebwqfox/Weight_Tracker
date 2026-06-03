import SwiftUI
import PhotosUI

struct FoodAnalysisView: View {
    @State private var viewModel = FoodAnalysisViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.sectionSpacing) {
                    photoSection
                    if viewModel.selectedImage != nil {
                        mealTypePicker
                        analyzeButton
                    }
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, DS.spacing)
                .padding(.top, 8)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("拍照分析")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.brand)
                    }
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
                Task { @MainActor in await viewModel.loadImage(from: newItem) }
            }
        }
    }

    // MARK: - Photo Section

    @ViewBuilder
    private var photoSection: some View {
        if let image = viewModel.selectedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Button {
                        withAnimation {
                            viewModel.selectedImage = nil
                            viewModel.selectedPhotoItem = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(12)
                }
                .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
        } else {
            emptyPhotoPlaceholder
        }
    }

    private var emptyPhotoPlaceholder: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(LinearGradient.brand)
            }
            .padding(.top, 8)

            VStack(spacing: 6) {
                Text("拍摄今天的餐食")
                    .font(.title3.weight(.semibold))
                Text("AI 将识别菜品并精准计算热量")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.showCamera = true
                } label: {
                    Label("拍照", systemImage: "camera.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: DS.pillRadius, style: .continuous))
                }

                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    Label("相册", systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.brand)
                        .background(Color.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: DS.pillRadius, style: .continuous))
                }
            }
            .padding(.top, 4)
        }
        .padding(24)
        .card()
        .fullScreenCover(isPresented: $viewModel.showCamera) {
            CameraPickerView(image: $viewModel.selectedImage)
                .ignoresSafeArea()
        }
    }

    // MARK: - Meal Type Picker

    private var mealTypePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "餐食类型", systemImage: "clock.fill")
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FoodEntry.mealTypes, id: \.self) { type in
                        let selected = viewModel.mealType == type
                        Button {
                            withAnimation(.snappy) { viewModel.mealType = type }
                        } label: {
                            Text(type)
                                .font(.subheadline.weight(selected ? .semibold : .regular))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .foregroundStyle(selected ? .white : Color.primary)
                                .background {
                                    if selected {
                                        Capsule().fill(LinearGradient.brand)
                                    } else {
                                        Capsule().fill(Color.card)
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Analyze Button

    private var analyzeButton: some View {
        Button {
            Task { @MainActor in await viewModel.analyze() }
        } label: {
            Group {
                if viewModel.isAnalyzing {
                    HStack(spacing: 10) {
                        ProgressView().tint(.white)
                        Text("AI 分析中…")
                    }
                } else {
                    Label("开始分析", systemImage: "sparkles")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: DS.innerRadius, style: .continuous))
            .shadow(color: Color.brand.opacity(0.35), radius: 12, y: 5)
        }
        .disabled(viewModel.isAnalyzing)
        .opacity(viewModel.isAnalyzing ? 0.85 : 1)
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

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

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
