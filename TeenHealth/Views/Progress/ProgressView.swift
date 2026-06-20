import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [AppUser]
    @StateObject private var vm = ProgressViewModel()
    @State private var showLeaderboard = false

    var user: AppUser? { users.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.thBackground.ignoresSafeArea()

                if let user {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            levelCard(user: user)
                            weeklyActivityChart
                            weeklyLogsChart
                            if !vm.weightTrend.isEmpty {
                                weightTrendCard
                            }
                            badgesSection(user: user)
                            Spacer(minLength: 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLeaderboard = true
                    } label: {
                        Image(systemName: "trophy")
                            .foregroundColor(.thGold)
                    }
                }
            }
            .sheet(isPresented: $showLeaderboard) {
                if let user { LeaderboardView(user: user) }
            }
            .task {
                if let user { await vm.loadData(user: user) }
            }
        }
    }

    // MARK: - Level Card

    private func levelCard(user: AppUser) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.thPrimary, .thAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    Text(vm.currentLevelInfo?.emoji ?? "🌱")
                        .font(.system(size: 38))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.currentLevelInfo?.name ?? "Seedling")
                        .font(.thTitle)
                        .foregroundColor(.thText)
                    Text("Level \(vm.currentLevelInfo?.level ?? 0)")
                        .font(.thCaption)
                        .foregroundColor(.thSubtext)
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.thGold)
                            .font(.system(size: 12))
                        Text("\(user.points) points")
                            .font(.thHeadline)
                            .foregroundColor(.thText)
                    }
                }
                Spacer()
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Progress to next level")
                        .font(.thCaption)
                        .foregroundColor(.thSubtext)
                    Spacer()
                    Text("\(Int(vm.levelProgress * 100))%")
                        .font(.thCaption)
                        .fontWeight(.bold)
                        .foregroundColor(.thPrimary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.thPrimary.opacity(0.15))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [.thPrimary, .thAccent], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * vm.levelProgress, height: 10)
                            .animation(.spring(response: 0.6), value: vm.levelProgress)
                    }
                }
                .frame(height: 10)
                if let next = vm.currentLevelInfo {
                    Text("Next: \(next.nextThreshold - user.points) pts to reach \(nextLevelName(current: next.level))")
                        .font(.thCaption)
                        .foregroundColor(.thSubtext)
                }
            }

            // Streak badge
            HStack {
                StreakBadge(streak: user.currentStreak)
                Spacer()
                Text("\(user.rewards.filter { $0.kind == .badge }.count) badges earned")
                    .font(.thCaption)
                    .foregroundColor(.thSubtext)
            }
        }
        .padding(20)
        .thCard()
    }

    private func nextLevelName(current: Int) -> String {
        let levels = RewardEngine.levels
        if current + 1 < levels.count { return levels[current + 1].name }
        return "Max Level"
    }

    // MARK: - Weekly Activity Chart

    private var weeklyActivityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Weekly Steps")
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(vm.weeklySteps.enumerated()), id: \.offset) { idx, steps in
                    VStack(spacing: 4) {
                        Text("\(Int(steps / 1000))k")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.thSubtext)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(steps >= 5000 ? Color.thAccent : Color.thBorder)
                            .frame(height: max(barHeight(steps, max: vm.weeklySteps.max() ?? 10000), 4))
                        Text(vm.weekdayLabels()[safe: idx] ?? "")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.thSubtext)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
            .animation(.spring(response: 0.5), value: vm.weeklySteps)

            HStack {
                Circle().fill(Color.thAccent).frame(width: 8, height: 8)
                Text("Goal met (5,000+)").font(.thCaption).foregroundColor(.thSubtext)
                Spacer()
                Circle().fill(Color.thBorder).frame(width: 8, height: 8)
                Text("Below goal").font(.thCaption).foregroundColor(.thSubtext)
            }
        }
        .padding(16)
        .thCard()
    }

    // MARK: - Weekly Logs Chart

    private var weeklyLogsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Meals Logged Per Day")
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(vm.weeklyLogs.enumerated()), id: \.offset) { idx, logs in
                    VStack(spacing: 4) {
                        Text("\(logs)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.thSubtext)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(logs >= 2 ? Color.thEnergy : Color.thBorder)
                            .frame(height: max(CGFloat(logs) * 20, 4))
                        Text(vm.weekdayLabels()[safe: idx] ?? "")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.thSubtext)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
        .padding(16)
        .thCard()
    }

    // MARK: - Weight Trend

    private var weightTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Weight Trend")
            Text("Weight data shared privately with your coach only")
                .font(.thCaption)
                .foregroundColor(.thSubtext)
            HStack(alignment: .bottom, spacing: 6) {
                let maxW = vm.weightTrend.max() ?? 80
                let minW = max((vm.weightTrend.min() ?? 50) - 2, 0)
                let range = maxW - minW
                ForEach(Array(vm.weightTrend.enumerated()), id: \.offset) { idx, weight in
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", weight))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.thSubtext)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.thPrimary.opacity(0.6))
                            .frame(height: range > 0 ? max(CGFloat((weight - minW) / range) * 80, 4) : 40)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
            Text("Log your weight weekly in Settings")
                .font(.thCaption)
                .foregroundColor(.thSubtext)
        }
        .padding(16)
        .thCard()
    }

    // MARK: - Badges

    private func badgesSection(user: AppUser) -> some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Badges")
            let badgeDefs = vm.allBadgeDefinitions()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(badgeDefs, id: \.0) { key, def in
                    let earned = vm.hasBadge(key: key, user: user)
                    BadgeTile(def: def, earned: earned)
                }
            }
        }
    }

    // MARK: - Helpers

    private func barHeight(_ value: Double, max: Double) -> CGFloat {
        guard max > 0 else { return 4 }
        return CGFloat(value / max) * 80
    }
}

// MARK: - Badge Tile

struct BadgeTile: View {
    let def: BadgeDefinition
    let earned: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(earned ? Color(hex: def.color).opacity(0.2) : Color.thBorder.opacity(0.3))
                    .frame(width: 60, height: 60)
                Image(systemName: def.icon)
                    .font(.system(size: 26))
                    .foregroundColor(earned ? Color(hex: def.color) : .thBorder)
                if !earned {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.thBorder)
                        .clipShape(Circle())
                        .offset(x: 20, y: 20)
                }
            }
            Text(def.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(earned ? .thText : .thSubtext)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(earned ? Color.thCard : Color.thBackground)
        .cornerRadius(14)
        .shadow(color: earned ? Color.black.opacity(0.06) : .clear, radius: 6, y: 2)
    }
}

// MARK: - Leaderboard

struct LeaderboardView: View {
    let user: AppUser
    @Environment(\.dismiss) private var dismiss

    // Pseudonymous mock leaderboard
    private let leaderboardEntries: [(String, String, Int, String)] = [
        ("🌟", "StarRunner42", 2840, "Champion"),
        ("⚡", "FlashWalker7", 2100, "Champion"),
        ("🔥", "HealthHero99", 1750, "Achiever"),
        ("💪", "ActiveAlex", 1420, "Achiever"),
        ("🌱", "GreenGoals", 980, "Grower"),
        ("🚀", "StepMaster", 760, "Grower"),
        ("✨", "WellnessKid", 540, "Sprout")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Privacy notice
                HStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.thPrimary)
                    Text("Pseudonymous only — no real names shown")
                        .font(.thCaption)
                        .foregroundColor(.thSubtext)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.thPrimary.opacity(0.08))

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(leaderboardEntries.enumerated()), id: \.offset) { idx, entry in
                            HStack(spacing: 14) {
                                Text("\(idx + 1)")
                                    .font(.thHeadline)
                                    .foregroundColor(idx < 3 ? .thGold : .thSubtext)
                                    .frame(width: 24)
                                Text(entry.0)
                                    .font(.title3)
                                Text(entry.1)
                                    .font(.thBody)
                                    .foregroundColor(.thText)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(entry.2) pts")
                                        .font(.thHeadline)
                                        .foregroundColor(.thPrimary)
                                    Text(entry.3)
                                        .font(.thCaption)
                                        .foregroundColor(.thSubtext)
                                }
                            }
                            .padding(14)
                            .background(idx < 3 ? Color.thGold.opacity(0.08) : Color.thCard)
                            .cornerRadius(12)
                        }

                        // User's own entry
                        Divider().padding(.vertical, 8)
                        HStack(spacing: 14) {
                            Text("You")
                                .font(.thHeadline)
                                .foregroundColor(.thPrimary)
                                .frame(width: 24)
                            Text("😊")
                            Text(user.displayName)
                                .font(.thBody)
                                .foregroundColor(.thText)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(user.points) pts")
                                    .font(.thHeadline)
                                    .foregroundColor(.thPrimary)
                                Text(RewardEngine().currentLevel(for: user.points).name)
                                    .font(.thCaption)
                                    .foregroundColor(.thSubtext)
                            }
                        }
                        .padding(14)
                        .background(Color.thPrimary.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.thPrimary, lineWidth: 1.5))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Array safe subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
