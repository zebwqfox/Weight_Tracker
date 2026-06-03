import SwiftUI
import VisionKit

@Observable
class QRScannerViewModel {
    var scannedCode: String?
    var showOAuthSheet = false
    var isScanning = true
    var torchOn = false
    var lastScannedDomain: String = ""
    var lastScannedAppName: String = ""
    var lastScannedLogoURL: String?

    func handleScannedCode(_ code: String) {
        scannedCode = code
        isScanning = false

        // Extract domain/app name from the QR code URL
        if let url = URL(string: code) {
            lastScannedDomain = url.host ?? code
            lastScannedAppName = inferAppName(from: url)
        } else {
            lastScannedDomain = code
            lastScannedAppName = "未知应用"
        }

        showOAuthSheet = true
    }

    func resetScan() {
        scannedCode = nil
        isScanning = true
        showOAuthSheet = false
    }

    private func inferAppName(from url: URL) -> String {
        let host = url.host ?? ""
        // Remove www. prefix
        let cleaned = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        // Get the main domain name
        let parts = cleaned.split(separator: ".")
        if let main = parts.first {
            return main.capitalized + " 账户"
        }
        return cleaned
    }
}
