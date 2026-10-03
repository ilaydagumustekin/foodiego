import SwiftUI
import UIKit

enum Theme {
    /// Grass green — the app's main color.
    static let primary = Color(hex: "43A047")
    /// Darker green for confirmations and pressed states.
    static let green = Color(hex: "2E7D32")
    /// Warm yellow used for highlights ("%30 İndirim", "Sepete Git").
    static let accent = Color(hex: "FFC83D")
    static let red = Color(hex: "E53935")
    static let background = Color(hex: "F5F6F8")
    static let field = Color(hex: "F1F2F5")
    static let secondaryText = Color(hex: "8A8F98")
}

extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}

extension Double {
    private static let tlFormat = FloatingPointFormatStyle<Double>.Currency(code: "TRY").locale(Locale(identifier: "tr_TR"))

    var tl: String { formatted(Self.tlFormat) }
}

extension View {
    /// White rounded card with a soft shadow — the base of most surfaces in the app.
    func card(radius: CGFloat = 18) -> some View {
        background(RoundedRectangle(cornerRadius: radius).fill(.white))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

struct SectionHeader: View {
    let title: String
    var actionTitle = "Tümünü Gör"
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title).font(.title3.weight(.semibold))
            Spacer()
            if let action {
                Button(action: action) {
                    HStack(spacing: 2) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right").font(.caption.weight(.bold))
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.primary)
                }
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 14).fill(color))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

/// Rounded search field used on the home and category screens.
struct SearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.secondaryText)
            TextField(placeholder, text: $text)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.field))
    }
}

/// Horizontal filter chips ("Tümü", category names…).
struct ChipBar: View {
    let titles: [String]
    @Binding var selection: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                    Button {
                        withAnimation(.snappy) { selection = index }
                    } label: {
                        Text(title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(selection == index ? .white : .primary)
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(Capsule().fill(selection == index ? Theme.primary : .white))
                            .overlay(Capsule().stroke(Color.black.opacity(selection == index ? 0 : 0.06)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Small transient confirmation shown at the top of the screen.
struct Toast: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Capsule().fill(Theme.green))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}
