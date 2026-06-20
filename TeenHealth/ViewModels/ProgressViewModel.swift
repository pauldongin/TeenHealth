import Foundation
import SwiftData
import Combine

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published var weeklySteps: [Double] = []
    @Published var weeklyLogs: [Int] = []
    @Published var badges: [Reward] = []
    @Published var recentRewards: [Reward] = []
    @Published var currentLevelInfo: LevelInfo?
    @Published var levelProgress: Double = 0
    @Published var latestWeight: Double? = nil
    @Published var weightTrend: [Double] = []

    private let rewardEngine: RewardEngine
    private let healthService: HealthServiceProtocol

    init(rewardEngine: RewardEngine = RewardEngine(), healthService: HealthServiceProtocol = MockHealthService()) {
        self.rewardEngine = rewardEngine
        self.healthService = healthService
    }

    func loadData(user: AppUser) async {
        // Level info
        currentLevelInfo = rewardEngine.currentLevel(for: user.points)
        levelProgress = rewardEngine.progressToNextLevel(points: user.points)

        // Badges
        badges = user.rewards.filter { $0.kind == .badge }.sorted { $0.awardedAt > $1.awardedAt }

        // Recent rewards
        recentRewards = user.rewards.sorted { $0.awardedAt > $1.awardedAt }.prefix(10).map { $0 }

        // Weekly steps (mock from HealthKit or generate from metrics)
        weeklySteps = buildWeeklySteps(user: user)

        // Weekly logs
        weeklyLogs = buildWeeklyLogs(user: user)

        // Weight trend
        weightTrend = buildWeightTrend(user: user)
        latestWeight = weightTrend.last
    }

    private func buildWeeklySteps(user: AppUser) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return 0 }
            let dayMetrics = user.metrics.filter {
                $0.type == .steps && calendar.isDate($0.timestamp, inSameDayAs: day)
            }
            return dayMetrics.first?.value ?? Double.random(in: 2000...10000)
        }
    }

    private func buildWeeklyLogs(user: AppUser) -> [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return 0 }
            return user.foodLogs.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }.count
        }
    }

    private func buildWeightTrend(user: AppUser) -> [Double] {
        let weightMetrics = user.metrics
            .filter { $0.type == .weight }
            .sorted { $0.timestamp < $1.timestamp }
            .suffix(8)
            .map { $0.value }
        if weightMetrics.isEmpty {
            // Show nothing if no weight logged
            return []
        }
        return weightMetrics
    }

    func weekdayLabels() -> [String] {
        let calendar = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
                .map { formatter.string(from: $0) }
        }
    }

    func allBadgeDefinitions() -> [(String, BadgeDefinition)] {
        RewardEngine.badges.sorted { $0.key < $1.key }
    }

    func hasBadge(key: String, user: AppUser) -> Bool {
        let defName = RewardEngine.badges[key]?.name ?? key
        return user.rewards.contains { $0.kind == .badge && $0.badgeName == defName }
    }
}
