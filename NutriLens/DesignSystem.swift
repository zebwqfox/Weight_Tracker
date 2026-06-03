import SwiftUI
import UIKit

// MARK: - Design Tokens

enum DS {
    // Corner radii
    static let cardRadius: CGFloat = 24
    static let innerRadius: CGFloat = 16
    static let pillRadius: CGFloat = 14

    // Spacing
    static let spacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 22
    static let cardPadding: CGFloat = 20
}

// MARK: - Brand Palette
//
// Defined on `ShapeStyle where Self == Color` (mirroring how SwiftUI exposes
// built-in colors like `.red`). This makes the leading-dot form resolve in
// every style context — `.foregroundStyle(.brand)`, `.tint(.brand)`,
// `.fill(.brand)`, etc. — while `Color.brand` also stays valid for direct use
// and gradient literals. Declaring them here (and only here) avoids a
// duplicate-symbol clash with a plain `extension Color`.

extension ShapeStyle where Self == Color {
    /// Primary brand green
    static var brand: Color { Color(red: 0.16, green: 0.74, blue: 0.46) }
    static var brandDeep: Color { Color(red: 0.08, green: 0.55, blue: 0.42) }

    /// Functional accents
    static var calorie: Color { Color(red: 1.0, green: 0.55, blue: 0.26) }   // orange
    static var calorieDeep: Color { Color(red: 0.98, green: 0.40, blue: 0.34) }
    static var protein: Color { Color(red: 0.30, green: 0.56, blue: 0.98) }  // blue
    static var carb: Color { Color(red: 1.0, green: 0.70, blue: 0.28) }      // amber
    static var fat: Color { Color(red: 0.98, green: 0.80, blue: 0.30) }      // yellow
    static var fiber: Color { Color(red: 0.36, green: 0.78, blue: 0.50) }    // green

    /// Adaptive surfaces
    static var canvas: Color { Color(uiColor: .systemGroupedBackground) }
    static var card: Color { Color(uiColor: .secondarySystemGroupedBackground) }
}

// MARK: - Gradients

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [Color.brand, Color.brandDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let calorie = LinearGradient(
        colors: [Color.calorie, Color.calorieDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let oauth = LinearGradient(
        colors: [Color(red: 0.36, green: 0.42, blue: 0.96), Color(red: 0.58, green: 0.36, blue: 0.96)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func soft(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.85), color],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - Card Style

struct CardModifier: ViewModifier {
    var padding: CGFloat = DS.cardPadding
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.card, in: RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

extension View {
    func card(padding: CGFloat = DS.cardPadding) -> some View {
        modifier(CardModifier(padding: padding))
    }

    /// A soft screen background gradient used behind scroll content.
    func screenBackground() -> some View {
        background(
            LinearGradient(
                colors: [Color.canvas, Color.canvas, Color.brand.opacity(0.04)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let systemImage: String
    var tint: Color = .brand

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
}

// MARK: - Pill Tag

struct PillTag: View {
    let text: String
    var color: Color = .brand

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}
