import SwiftUI
import UIKit

// MARK: - Color Palette

extension Color {
    // Primary brand colors — vibrant but not childish
    static let thPrimary    = Color(hex: "#6C5CE7")   // Purple
    static let thAccent     = Color(hex: "#00CEC9")   // Teal
    static let thEnergy     = Color(hex: "#FF6B35")   // Orange
    static let thSuccess    = Color(hex: "#00B894")   // Green
    static let thWarning    = Color(hex: "#FDCB6E")   // Amber
    static let thGold       = Color(hex: "#F9CA24")   // Gold (badges)
    // Darker page background so white cards pop with clear contrast
    static let thBackground = Color(UIColor.systemGroupedBackground)
    static let thCard       = Color(UIColor.systemBackground)
    // Use system label colors → auto adapts to light/dark mode
    static let thText       = Color(UIColor.label)
    static let thSubtext    = Color(UIColor.secondaryLabel)
    static let thBorder     = Color(UIColor.separator)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }

    static func goalColor(for type: GoalType) -> Color {
        Color(hex: type.colorHex)
    }
}

// MARK: - Typography

extension Font {
    static let thDisplay = Font.system(size: 32, weight: .bold, design: .rounded)
    static let thTitle   = Font.system(size: 22, weight: .bold, design: .rounded)
    static let thHeadline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let thBody    = Font.system(size: 15, weight: .regular, design: .rounded)
    static let thCaption = Font.system(size: 12, weight: .medium, design: .rounded)
    static let thPoints  = Font.system(size: 28, weight: .heavy, design: .rounded)
}

// MARK: - Card Modifier

struct THCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.thCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 3)
    }
}

extension View {
    func thCard() -> some View { modifier(THCard()) }
}

// MARK: - Gradient Button Style

struct THButtonStyle: ButtonStyle {
    var color: Color = .thPrimary
    var isWide: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.thHeadline)
            .foregroundColor(.white)
            .padding(.horizontal, isWide ? 0 : 24)
            .padding(.vertical, 14)
            .frame(maxWidth: isWide ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(configuration.isPressed ? color.opacity(0.8) : color)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double   // 0.0 – 1.0
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Streak Badge

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(.thEnergy)
                .font(.system(size: 14, weight: .bold))
            Text("\(streak) day\(streak == 1 ? "" : "s")")
                .font(.thCaption)
                .fontWeight(.bold)
                .foregroundColor(.thText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.thEnergy.opacity(0.12))
        .cornerRadius(20)
    }
}

// MARK: - Points Pill

struct PointsPill: View {
    let points: Int
    let levelName: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundColor(.thGold)
                .font(.system(size: 12))
            Text("\(points) pts")
                .font(.thCaption)
                .fontWeight(.bold)
                .foregroundColor(.thText)
            Text("·")
                .foregroundColor(.thSubtext)
            Text(levelName)
                .font(.thCaption)
                .foregroundColor(.thPrimary)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.thPrimary.opacity(0.08))
        .cornerRadius(20)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See all"

    var body: some View {
        HStack {
            Text(title)
                .font(.thHeadline)
                .foregroundColor(.thText)
            Spacer()
            if let action {
                Button(actionLabel, action: action)
                    .font(.thCaption)
                    .foregroundColor(.thPrimary)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var onButton: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.thPrimary.opacity(0.5))
            Text(title)
                .font(.thHeadline)
                .foregroundColor(.thText)
            Text(message)
                .font(.thBody)
                .foregroundColor(.thSubtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let title = buttonTitle, let action = onButton {
                Button(title, action: action)
                    .buttonStyle(THButtonStyle())
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Toast Notification

struct ToastView: View {
    let message: String
    let icon: String
    var color: Color = .thSuccess

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16, weight: .semibold))
            Text(message)
                .font(.thBody)
                .fontWeight(.semibold)
                .foregroundColor(.thText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Avatar View (emoji-based, high quality)

struct AvatarView: View {
    let config: AvatarConfig
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: config.backgroundColor), Color(hex: config.backgroundColor).opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            Text(config.emoji)
                .font(.system(size: size * 0.52))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color(hex: config.backgroundColor).opacity(0.35), lineWidth: max(size * 0.03, 1.5))
        )
    }
}

