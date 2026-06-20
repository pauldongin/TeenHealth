import Foundation
import SwiftData

// MARK: - Reward Actions

enum RewardAction {
    case foodLog
    case streakDay
    case goalHit
    case perfectDay
    case weekStreak
    case weeklyWeighIn
    case firstLog
    case waterGoal
    case activityGoal
}

// MARK: - Badge Definitions

struct BadgeDefinition {
    let name: String
    let icon: String
    let description: String
    let color: String
}

// MARK: - Level Definition

struct LevelInfo {
    let level: Int
    let name: String
    let emoji: String
    let minPoints: Int
    let nextThreshold: Int
    let color: String
}

// MARK: - Reward Engine

final class RewardEngine: ObservableObject {

    // MARK: Points Table
    static let pointsTable: [RewardAction: Int] = [
        .foodLog: 10,
        .streakDay: 5,
        .goalHit: 20,
        .perfectDay: 50,
        .weekStreak: 100,
        .weeklyWeighIn: 15,
        .firstLog: 25,
        .waterGoal: 15,
        .activityGoal: 20
    ]

    // MARK: Levels
    static let levels: [LevelInfo] = [
        LevelInfo(level: 0, name: "Seedling",  emoji: "🌱", minPoints: 0,    nextThreshold: 100,  color: "#A8E6CF"),
        LevelInfo(level: 1, name: "Sprout",    emoji: "🌿", minPoints: 100,  nextThreshold: 300,  color: "#56CB8F"),
        LevelInfo(level: 2, name: "Grower",    emoji: "🌳", minPoints: 300,  nextThreshold: 700,  color: "#26A65B"),
        LevelInfo(level: 3, name: "Achiever",  emoji: "⭐", minPoints: 700,  nextThreshold: 1500, color: "#F9CA24"),
        LevelInfo(level: 4, name: "Champion",  emoji: "🏆", minPoints: 1500, nextThreshold: 3000, color: "#F0932B"),
        LevelInfo(level: 5, name: "Legend",    emoji: "✨", minPoints: 3000, nextThreshold: 9999, color: "#6C5CE7")
    ]

    // MARK: Badges
    static let badges: [String: BadgeDefinition] = [
        "first_log": BadgeDefinition(
            name: "First Step",
            icon: "star.fill",
            description: "Logged your very first meal. The journey begins!",
            color: "#F9CA24"
        ),
        "week_warrior": BadgeDefinition(
            name: "Week Warrior",
            icon: "flame.fill",
            description: "Kept a 7-day logging streak. That's consistency!",
            color: "#FF6B35"
        ),
        "goal_crusher": BadgeDefinition(
            name: "Goal Crusher",
            icon: "target",
            description: "Hit 10 goals total. You mean business!",
            color: "#4ECDC4"
        ),
        "hydration_hero": BadgeDefinition(
            name: "Hydration Hero",
            icon: "drop.fill",
            description: "Hit your water goal 5 days in a row. Stay hydrated!",
            color: "#45B7D1"
        ),
        "active_life": BadgeDefinition(
            name: "Active Life",
            icon: "figure.run",
            description: "Reached 5,000+ steps 3 days in a row. Keep moving!",
            color: "#A29BFE"
        ),
        "month_master": BadgeDefinition(
            name: "Month Master",
            icon: "calendar.badge.checkmark",
            description: "30-day logging streak. Incredible dedication!",
            color: "#6C5CE7"
        ),
        "perfect_week": BadgeDefinition(
            name: "Perfect Week",
            icon: "checkmark.seal.fill",
            description: "Hit all goals every day for a full week!",
            color: "#55EFC4"
        ),
        "coach_connect": BadgeDefinition(
            name: "Coach Connect",
            icon: "message.fill",
            description: "Sent your first message to your coach.",
            color: "#FDCB6E"
        )
    ]

    // MARK: - Methods

    func awardPoints(for action: RewardAction, user: AppUser, context: ModelContext) -> Int {
        let pts = Self.pointsTable[action] ?? 0
        user.points += pts

        let reward = Reward(
            id: UUID(),
            userId: user.id,
            kind: .points,
            value: pts
        )
        context.insert(reward)
        user.rewards.append(reward)

        // Check for level up
        checkLevelUp(user: user, context: context)

        return pts
    }

    private func checkLevelUp(user: AppUser, context: ModelContext) {
        let newLevel = currentLevel(for: user.points).level
        if newLevel > user.level {
            user.level = newLevel
            let levelReward = Reward(id: UUID(), userId: user.id, kind: .level, value: newLevel)
            context.insert(levelReward)
            user.rewards.append(levelReward)
        }
    }

    func checkAndAwardBadges(for user: AppUser, context: ModelContext) -> [Reward] {
        var newBadges: [Reward] = []
        let existingBadgeNames = user.rewards.filter { $0.kind == .badge }.compactMap { $0.badgeName }

        // First log badge
        if !existingBadgeNames.contains("first_log") && !user.foodLogs.isEmpty {
            let badge = makeBadge(name: "first_log", userId: user.id, context: context)
            user.rewards.append(badge)
            newBadges.append(badge)
        }

        // Week warrior (7-day streak)
        if !existingBadgeNames.contains("week_warrior") && user.currentStreak >= 7 {
            let badge = makeBadge(name: "week_warrior", userId: user.id, context: context)
            user.rewards.append(badge)
            newBadges.append(badge)
        }

        // Month master (30-day streak)
        if !existingBadgeNames.contains("month_master") && user.currentStreak >= 30 {
            let badge = makeBadge(name: "month_master", userId: user.id, context: context)
            user.rewards.append(badge)
            newBadges.append(badge)
        }

        // Goal crusher (10 goals hit)
        let completedGoals = user.goals.filter { $0.isCompletedToday }.count
        if !existingBadgeNames.contains("goal_crusher") && completedGoals >= 10 {
            let badge = makeBadge(name: "goal_crusher", userId: user.id, context: context)
            user.rewards.append(badge)
            newBadges.append(badge)
        }

        // Coach connect
        if !existingBadgeNames.contains("coach_connect") && !user.messages.filter({ !$0.isFromCoach }).isEmpty {
            let badge = makeBadge(name: "coach_connect", userId: user.id, context: context)
            user.rewards.append(badge)
            newBadges.append(badge)
        }

        return newBadges
    }

    private func makeBadge(name: String, userId: UUID, context: ModelContext) -> Reward {
        let def = Self.badges[name]
        let reward = Reward(
            id: UUID(),
            userId: userId,
            kind: .badge,
            value: 0,
            badgeName: def?.name ?? name,
            badgeIcon: def?.icon ?? "star.fill"
        )
        context.insert(reward)
        return reward
    }

    func currentLevel(for points: Int) -> LevelInfo {
        var result = Self.levels[0]
        for level in Self.levels {
            if points >= level.minPoints { result = level }
        }
        return result
    }

    func progressToNextLevel(points: Int) -> Double {
        let current = currentLevel(for: points)
        let range = Double(current.nextThreshold - current.minPoints)
        let progress = Double(points - current.minPoints)
        guard range > 0 else { return 1.0 }
        return min(progress / range, 1.0)
    }

    func totalGoalsHitAllTime(user: AppUser) -> Int {
        // Count rewards of type .points for goalHit action — approximate via count
        user.rewards.filter { $0.kind == .points && $0.value == Self.pointsTable[.goalHit] }.count
    }
}
