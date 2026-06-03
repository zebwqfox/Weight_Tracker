import SwiftUI
import VisionKit
import AVFoundation

struct QRScannerView: View {
    @State private var viewModel = QRScannerViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera scanner
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerRepresentable(viewModel: viewModel)
                        .ignoresSafeArea()
                } else {
                    simulatorPlaceholder
                }

                // Overlay UI
                VStack {
                    Spacer()
                    scannerOverlay
                    Spacer()
                    bottomControls
                }
            }
            .navigationTitle("扫码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $viewModel.showOAuthSheet) {
                OAuthLoginView(
                    code: viewModel.scannedCode ?? "",
                    appName: viewModel.lastScannedAppName,
                    domain: viewModel.lastScannedDomain,
                    onComplete: { viewModel.resetScan() }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var scannerOverlay: some View {
        ZStack {
            // Dimmed corners
            Color.black.opacity(0.4)
                .mask(
                    ZStack {
                        Rectangle()
                        RoundedRectangle(cornerRadius: 20)
                            .frame(width: 260, height: 260)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                )
                .ignoresSafeArea()

            // Scan frame
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white, lineWidth: 3)
                .frame(width: 260, height: 260)
                .overlay(alignment: .topLeading) {
                    cornerMark.padding(6)
                }
                .overlay(alignment: .topTrailing) {
                    cornerMark.rotationEffect(.degrees(90)).padding(6)
                }
                .overlay(alignment: .bottomLeading) {
                    cornerMark.rotationEffect(.degrees(-90)).padding(6)
                }
                .overlay(alignment: .bottomTrailing) {
                    cornerMark.rotationEffect(.degrees(180)).padding(6)
                }

            // Scan line animation
            ScanLineView()
                .frame(width: 260, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private var cornerMark: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(.tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }

    private var bottomControls: some View {
        HStack(spacing: 40) {
            Button {
                viewModel.torchOn.toggle()
            } label: {
                Image(systemName: viewModel.torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(.ultraThinMaterial, in: Circle())
            }

            VStack(spacing: 6) {
                Image(systemName: "qrcode")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text("将二维码置于框内")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Button {
                // Photo library scan
            } label: {
                Image(systemName: "photo.on.rectangle")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.bottom, 50)
    }

    private var simulatorPlaceholder: some View {
        ZStack {
            Color.black
            VStack(spacing: 20) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.5))
                Text("摄像头在模拟器中不可用")
                    .foregroundStyle(.white.opacity(0.7))
                Button("模拟扫描") {
                    viewModel.handleScannedCode("https://example.com/oauth/device?code=ABCD-1234")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - DataScanner Representable

struct DataScannerRepresentable: UIViewControllerRepresentable {
    let viewModel: QRScannerViewModel

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr, .pdf417, .aztec])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Toggle torch
        if viewModel.torchOn {
            try? uiViewController.captureSession?.beginConfiguration()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let viewModel: QRScannerViewModel

        init(viewModel: QRScannerViewModel) {
            self.viewModel = viewModel
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard viewModel.isScanning else { return }
            if let item = addedItems.first {
                switch item {
                case .barcode(let barcode):
                    if let value = barcode.payloadStringValue {
                        viewModel.handleScannedCode(value)
                    }
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Scan Line Animation

struct ScanLineView: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .tint.opacity(0.8), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: offset)
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: true)) {
                        offset = geo.size.height - 4
                    }
                }
        }
    }
}

#Preview {
    QRScannerView()
}
