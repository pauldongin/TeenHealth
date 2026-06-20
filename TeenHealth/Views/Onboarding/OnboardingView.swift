import SwiftUI
import SwiftData
import UIKit

private func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil, from: nil, for: nil
    )
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage = 0
    @State private var displayName: String = ""
    @State private var ageBand: String = "15-17"
    @State private var selectedAvatar: AvatarConfig = .default
    @State private var parentName: String = ""
    @State private var parentConsentGiven: Bool = false
    @State private var teenAssentGiven: Bool = false
    @State private var shakeButton: Bool = false

    private let totalPages = 5

    var body: some View {
        ZStack {
            // Background — tap anywhere to dismiss keyboard
            LinearGradient(
                colors: [Color.thPrimary.opacity(0.08), Color.thAccent.opacity(0.05), Color.thBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { dismissKeyboard() }

            VStack(spacing: 0) {
                // ── Progress dots ──────────────────────────────────────
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.thPrimary : Color.thBorder)
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 8)

                // ── Page content — NO TabView, no swipe ───────────────
                Group {
                    switch currentPage {
                    case 0: WelcomePage()
                    case 1: ConsentPage(
                                parentName: $parentName,
                                parentConsentGiven: $parentConsentGiven,
                                teenAssentGiven: $teenAssentGiven
                            )
                    case 2: ProfilePage(displayName: $displayName, ageBand: $ageBand)
                    case 3: AvatarPage(avatarConfig: $selectedAvatar)
                    default: GoalsIntroPage()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.28), value: currentPage)

                // ── Navigation buttons — fixed at bottom, above keyboard ─
                HStack(spacing: 12) {
                    // Back
                    if currentPage > 0 {
                        Button {
                            withAnimation { currentPage -= 1 }
                        } label: {
                            Text("Back")
                                .font(.thHeadline)
                                .foregroundColor(.thSubtext)
                                .frame(width: 80)
                                .padding(.vertical, 16)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(14)
                        }
                    }

                    // Continue / Let's Go
                    Button {
                        if canProceed {
                            dismissKeyboard()
                            if currentPage == totalPages - 1 {
                                completeOnboarding()
                            } else {
                                withAnimation { currentPage += 1 }
                            }
                        } else {
                            // Shake to signal required fields missing
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                                shakeButton = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                shakeButton = false
                            }
                        }
                    } label: {
                        Text(currentPage == totalPages - 1 ? "Let's Go! 🚀" : "Continue")
                            .font(.thHeadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canProceed ? Color.thPrimary : Color.thBorder)
                            .cornerRadius(14)
                    }
                    .offset(x: shakeButton ? 8 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                // ✅ Stays above keyboard — doesn't get hidden under it
                .background(Color.thBackground.ignoresSafeArea(edges: .bottom))
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
    }

    // ── Validation per page ──────────────────────────────────────────
    private var canProceed: Bool {
        switch currentPage {
        case 1: return !parentName.trimmingCharacters(in: .whitespaces).isEmpty
                    && parentConsentGiven
                    && teenAssentGiven
        case 2: return displayName.trimmingCharacters(in: .whitespaces).count >= 2
        default: return true
        }
    }

    private func completeOnboarding() {
        let user = AppUser(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            ageBand: ageBand,
            role: .teen,
            avatarConfig: selectedAvatar
        )
        user.hasCompletedOnboarding = true
        context.insert(user)

        let parentConsent = Consent(userId: user.id, type: .parentalConsent, grantedBy: parentName)
        let teenAssent = Consent(userId: user.id, type: .teenAssent, grantedBy: user.displayName)
        context.insert(parentConsent)
        context.insert(teenAssent)
        user.consents.append(parentConsent)
        user.consents.append(teenAssent)

        let goalsVM = GoalsViewModel()
        goalsVM.generateStarterGoals(for: user, context: context)

        try? context.save()
        hasCompletedOnboarding = true
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.thPrimary, .thAccent], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 140, height: 140)
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.white)
            }
            .shadow(color: .thPrimary.opacity(0.3), radius: 20)

            VStack(spacing: 12) {
                Text("Welcome to TeenHealth")
                    .font(.thDisplay)
                    .foregroundColor(.thText)
                    .multilineTextAlignment(.center)

                Text("Your daily companion for building healthier habits — at your own pace, in your own way.")
                    .font(.thBody)
                    .foregroundColor(.thSubtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 14) {
                FeatureRow(icon: "fork.knife", color: .thEnergy, text: "Log meals in seconds")
                FeatureRow(icon: "figure.walk", color: .thAccent, text: "Track your activity automatically")
                FeatureRow(icon: "message.fill", color: .thPrimary, text: "Chat with your health coach")
                FeatureRow(icon: "star.fill", color: .thGold, text: "Earn rewards for healthy habits")
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: icon).foregroundColor(color).font(.system(size: 15, weight: .semibold))
            }
            Text(text).font(.thBody).foregroundColor(.thText)
            Spacer()
        }
    }
}

// MARK: - Consent Page

struct ConsentPage: View {
    @Binding var parentName: String
    @Binding var parentConsentGiven: Bool
    @Binding var teenAssentGiven: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Invisible full-width tap area at top to dismiss keyboard
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 1)
                    .contentShape(Rectangle())
                    .onTapGesture { dismissKeyboard() }


                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.thPrimary)
                    Text("Privacy & Consent")
                        .font(.thTitle)
                        .foregroundColor(.thText)
                    Text("Your privacy matters. We need a parent or guardian to review this with you.")
                        .font(.thBody)
                        .foregroundColor(.thSubtext)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("What we collect")
                        .font(.thHeadline)
                        .foregroundColor(.thText)

                    PrivacyRow(icon: "fork.knife", text: "Meal logs you enter")
                    PrivacyRow(icon: "figure.walk", text: "Activity data from your phone (with your permission)")
                    PrivacyRow(icon: "message", text: "Messages with your coach")
                    PrivacyRow(icon: "xmark.circle", text: "We never sell your data or show ads")
                    PrivacyRow(icon: "trash", text: "You can delete all your data anytime")
                }
                .padding(20)
                .thCard()
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Parent / Guardian")
                        .font(.thHeadline)
                        .foregroundColor(.thText)

                    TextField("Parent/Guardian Full Name", text: $parentName)
                        .textContentType(.name)
                        .font(.thBody)
                        .padding()
                        .background(Color.thBackground)
                        .cornerRadius(12)
                        .submitLabel(.done)
                        .onSubmit { dismissKeyboard() }

                    ConsentToggle(
                        isOn: $parentConsentGiven,
                        text: "I, the parent/guardian named above, consent to my child using this app and understand how their data is used."
                    )
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Agreement")
                        .font(.thHeadline)
                        .foregroundColor(.thText)

                    ConsentToggle(
                        isOn: $teenAssentGiven,
                        text: "I understand how the app works and agree to use it as a supplement to my medical care — not a replacement."
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .padding(.top, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct PrivacyRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.thPrimary)
                .font(.system(size: 14))
                .frame(width: 20)
            Text(text).font(.thBody).foregroundColor(.thText)
            Spacer()
        }
    }
}

struct ConsentToggle: View {
    @Binding var isOn: Bool
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.thPrimary)
            Text(text)
                .font(.thBody)
                .foregroundColor(.thText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Profile Page

struct ProfilePage: View {
    @Binding var displayName: String
    @Binding var ageBand: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            // Tap background to dismiss keyboard
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 1)
                .contentShape(Rectangle())
                .onTapGesture { dismissKeyboard() }
            VStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.thPrimary)
                Text("Tell us about you")
                    .font(.thTitle)
                    .foregroundColor(.thText)
                Text("This helps us personalize your experience")
                    .font(.thBody)
                    .foregroundColor(.thSubtext)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("What should we call you?")
                    .font(.thHeadline)
                    .foregroundColor(.thText)

                TextField("Your first name or nickname", text: $displayName)
                    .textContentType(.givenName)
                    .font(.thBody)
                    .padding()
                    .background(Color.thBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.thBorder))
                    .submitLabel(.done)
                    .onSubmit { dismissKeyboard() }

                Text("Age group")
                    .font(.thHeadline)
                    .foregroundColor(.thText)

                HStack(spacing: 12) {
                    ForEach(["13-14", "15-17"], id: \.self) { band in
                        Button {
                            ageBand = band
                        } label: {
                            VStack(spacing: 4) {
                                Text(band)
                                    .font(.thHeadline)
                                Text("years old")
                                    .font(.thCaption)
                            }
                            .foregroundColor(ageBand == band ? .white : .thText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(ageBand == band ? Color.thPrimary : Color.thBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ageBand == band ? Color.thPrimary : Color.thBorder))
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }
}

// MARK: - Avatar Page

struct AvatarPage: View {
    @Binding var avatarConfig: AvatarConfig

    // Emoji organized by vibe
    let emojiCategories: [(String, [String])] = [
        ("Faces", ["😊", "😎", "🤩", "😄", "🥳", "😜", "🤓", "😏", "🥸", "🤠", "😺", "🦸"]),
        ("Active", ["🏃", "🚴", "🏊", "🧘", "💪", "🤸", "⛹️", "🏋️", "🤾", "🧗", "🏄", "🤺"]),
        ("Animals", ["🦊", "🐼", "🐯", "🦁", "🐨", "🐸", "🐬", "🦋", "🐺", "🦅", "🐙", "🦄"]),
        ("Chill", ["🌟", "🌈", "🎵", "🎨", "🎮", "📚", "🌙", "☀️", "🌊", "🌸", "🍀", "⚡"])
    ]

    let bgColors: [(String, String)] = [
        ("#6C5CE7", "Purple"),
        ("#0984E3", "Blue"),
        ("#00B894", "Green"),
        ("#E17055", "Orange"),
        ("#D63031", "Red"),
        ("#FDCB6E", "Yellow"),
        ("#2D3436", "Dark"),
        ("#00CEC9", "Teal")
    ]

    @State private var selectedCategory = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Text("Choose your avatar")
                    .font(.thTitle)
                    .foregroundColor(.thText)
                    .padding(.top, 20)

                // ── Live preview ──────────────────────────────────────
                AvatarView(config: avatarConfig, size: 120)
                    .shadow(color: Color(hex: avatarConfig.backgroundColor).opacity(0.4), radius: 20, y: 8)
                    .animation(.spring(response: 0.3), value: avatarConfig.emoji)
                    .animation(.spring(response: 0.3), value: avatarConfig.backgroundColor)

                // ── Category picker ───────────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(emojiCategories.enumerated()), id: \.offset) { i, cat in
                            Button { selectedCategory = i } label: {
                                Text(cat.0)
                                    .font(.thCaption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedCategory == i ? .white : .thText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == i ? Color.thPrimary : Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // ── Emoji grid ────────────────────────────────────────
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(emojiCategories[selectedCategory].1, id: \.self) { emoji in
                        let selected = avatarConfig.emoji == emoji
                        Text(emoji)
                            .font(.system(size: 36))
                            .frame(width: 54, height: 54)
                            .background(
                                Circle()
                                    .fill(selected
                                          ? Color(hex: avatarConfig.backgroundColor)
                                          : Color(UIColor.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                Circle()
                                    .stroke(selected ? Color(hex: avatarConfig.backgroundColor) : Color.clear, lineWidth: 3)
                            )
                            .scaleEffect(selected ? 1.1 : 1.0)
                            .animation(.spring(response: 0.2), value: selected)
                            .onTapGesture { avatarConfig.emoji = emoji }
                    }
                }
                .padding(.horizontal, 24)

                Divider().padding(.horizontal, 24)

                // ── Background color ──────────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    Text("Background Color")
                        .font(.thHeadline)
                        .foregroundColor(.thText)
                        .padding(.horizontal, 24)

                    HStack(spacing: 14) {
                        ForEach(bgColors, id: \.0) { hex, label in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(avatarConfig.backgroundColor == hex
                                                    ? Color.white : Color.clear, lineWidth: 3)
                                    )
                                    .overlay(
                                        avatarConfig.backgroundColor == hex
                                        ? Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                        : nil
                                    )
                                    .shadow(color: Color(hex: hex).opacity(0.4), radius: 6, y: 3)
                                    .scaleEffect(avatarConfig.backgroundColor == hex ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.2), value: avatarConfig.backgroundColor)
                                Text(label)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.thSubtext)
                            }
                            .onTapGesture { avatarConfig.backgroundColor = hex }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Goals Intro Page

struct GoalsIntroPage: View {
    let goals = [
        ("fork.knife", Color.thEnergy, "Log 2 meals/day", "The most impactful habit in the research"),
        ("figure.walk", Color.thAccent, "5,000 steps/day", "Movement that fits your lifestyle"),
        ("drop.fill", Color.thPrimary, "6 glasses of water", "Hydration supports energy & focus")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 48))
                    .foregroundColor(.thPrimary)
                Text("Your Starter Goals")
                    .font(.thTitle)
                    .foregroundColor(.thText)
                Text("We've set up 3 research-backed goals to kick things off. You can adjust them anytime.")
                    .font(.thBody)
                    .foregroundColor(.thSubtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 14) {
                ForEach(goals, id: \.0) { icon, color, title, subtitle in
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(color.opacity(0.15)).frame(width: 48, height: 48)
                            Image(systemName: icon).foregroundColor(color).font(.system(size: 20))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title).font(.thHeadline).foregroundColor(.thText)
                            Text(subtitle).font(.thCaption).foregroundColor(.thSubtext)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.thSuccess)
                    }
                    .padding(16)
                    .thCard()
                }
            }
            .padding(.horizontal, 24)

            Text("Remember: this app is a supplement to your clinical care — not a replacement. Always work with your healthcare team.")
                .font(.thCaption)
                .foregroundColor(.thSubtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}
