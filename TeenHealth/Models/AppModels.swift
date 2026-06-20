import Foundation
import SwiftData

// MARK: - Enums

enum UserRole: String, Codable {
    case teen, caregiver, coach
}

enum GoalType: String, Codable, CaseIterable {
    case logging, steps, hydration, activity, sleep, nutrition

    var icon: String {
        switch self {
        case .logging: return "fork.knife"
        case .steps: return "figure.walk"
        case .hydration: return "drop.fill"
        case .activity: return "heart.fill"
        case .sleep: return "moon.zzz.fill"
        case .nutrition: return "leaf.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .logging: return "#FF6B35"
        case .steps: return "#4ECDC4"
        case .hydration: return "#45B7D1"
        case .activity: return "#F7DC6F"
        case .sleep: return "#A29BFE"
        case .nutrition: return "#55EFC4"
        }
    }

    var displayName: String {
        switch self {
        case .logging: return "Meal Logging"
        case .steps: return "Daily Steps"
        case .hydration: return "Hydration"
        case .activity: return "Activity"
        case .sleep: return "Sleep"
        case .nutrition: return "Nutrition"
        }
    }
}

enum GoalStatus: String, Codable {
    case active, completed, paused
}

enum GoalSource: String, Codable {
    case recommended, custom
}

enum MealType: String, Codable, CaseIterable {
    case breakfast, lunch, dinner, snack

    var icon: String {
        switch self {
        case .breakfast: return "sun.horizon.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.circle.fill"
        }
    }

    var displayName: String { rawValue.capitalized }

    var timeRange: String {
        switch self {
        case .breakfast: return "6–10 AM"
        case .lunch: return "11 AM–2 PM"
        case .dinner: return "5–9 PM"
        case .snack: return "Anytime"
        }
    }

    var defaultHour: Int {
        switch self {
        case .breakfast: return 8
        case .lunch: return 12
        case .dinner: return 18
        case .snack: return 15
        }
    }
}

enum MetricType: String, Codable {
    case steps, activeEnergy, weight, bmi, waterGlasses, sleepHours
}

enum MetricSource: String, Codable {
    case healthkit, manual
}

enum RewardKind: String, Codable {
    case points, badge, level
}

enum ConsentType: String, Codable {
    case parentalConsent, teenAssent, healthKitSteps, healthKitEnergy, healthKitWeight, dataSharing
}

// MARK: - Avatar Config

struct AvatarConfig: Codable {
    var emoji: String           // e.g. "😊"
    var backgroundColor: String // hex

    static var `default`: AvatarConfig {
        .init(emoji: "😊", backgroundColor: "#6C5CE7")
    }

    var encoded: String {
        (try? String(data: JSONEncoder().encode(self), encoding: .utf8)) ?? "{}"
    }

    static func decode(_ string: String) -> AvatarConfig {
        guard let data = string.data(using: .utf8),
              let config = try? JSONDecoder().decode(AvatarConfig.self, from: data)
        else { return .default }
        return config
    }
}

// MARK: - SwiftData Models

@Model
final class AppUser {
    var id: UUID
    var displayName: String
    var ageBand: String
    var roleRaw: String
    var avatarConfigJSON: String
    var cohortId: String?
    var createdAt: Date
    var points: Int
    var level: Int
    var hasCompletedOnboarding: Bool
    var leaderboardOptIn: Bool

    @Relationship(deleteRule: .cascade) var goals: [Goal] = []
    @Relationship(deleteRule: .cascade) var foodLogs: [FoodLog] = []
    @Relationship(deleteRule: .cascade) var metrics: [Metric] = []
    @Relationship(deleteRule: .cascade) var rewards: [Reward] = []
    @Relationship(deleteRule: .cascade) var consents: [Consent] = []
    @Relationship(deleteRule: .cascade) var messages: [Message] = []

    var role: UserRole {
        get { UserRole(rawValue: roleRaw) ?? .teen }
        set { roleRaw = newValue.rawValue }
    }

    var avatarConfig: AvatarConfig {
        get { AvatarConfig.decode(avatarConfigJSON) }
        set { avatarConfigJSON = newValue.encoded }
    }

    var currentStreak: Int {
        guard !foodLogs.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        let sortedLogs = foodLogs.sorted { $0.timestamp > $1.timestamp }

        while true {
            let hasLog = sortedLogs.contains { calendar.isDate($0.timestamp, inSameDayAs: checkDate) }
            if hasLog {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    init(
        id: UUID = UUID(),
        displayName: String,
        ageBand: String = "15-17",
        role: UserRole = .teen,
        avatarConfig: AvatarConfig = .default,
        cohortId: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.ageBand = ageBand
        self.roleRaw = role.rawValue
        self.avatarConfigJSON = avatarConfig.encoded
        self.cohortId = cohortId
        self.createdAt = Date()
        self.points = 0
        self.level = 0
        self.hasCompletedOnboarding = false
        self.leaderboardOptIn = false
    }
}

@Model
final class Goal {
    var id: UUID
    var userId: UUID
    var title: String
    var typeRaw: String
    var target: Double
    var unit: String
    var cadence: String
    var progress: Double
    var statusRaw: String
    var sourceRaw: String
    var createdAt: Date
    var weeklyProgressJSON: String

    var type: GoalType {
        get { GoalType(rawValue: typeRaw) ?? .logging }
        set { typeRaw = newValue.rawValue }
    }

    var status: GoalStatus {
        get { GoalStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var source: GoalSource {
        get { GoalSource(rawValue: sourceRaw) ?? .recommended }
        set { sourceRaw = newValue.rawValue }
    }

    var weeklyProgress: [Double] {
        get {
            guard let data = weeklyProgressJSON.data(using: .utf8),
                  let arr = try? JSONDecoder().decode([Double].self, from: data)
            else { return Array(repeating: 0, count: 7) }
            return arr
        }
        set {
            weeklyProgressJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    var completionPercent: Double {
        guard target > 0 else { return 0 }
        return min(progress / target, 1.0)
    }

    var isCompletedToday: Bool { completionPercent >= 1.0 }

    init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        type: GoalType,
        target: Double,
        unit: String,
        cadence: String = "daily",
        source: GoalSource = .recommended
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.typeRaw = type.rawValue
        self.target = target
        self.unit = unit
        self.cadence = cadence
        self.progress = 0
        self.statusRaw = GoalStatus.active.rawValue
        self.sourceRaw = source.rawValue
        self.createdAt = Date()
        self.weeklyProgressJSON = "[]"
    }
}

@Model
final class FoodLog {
    var id: UUID
    var userId: UUID
    var timestamp: Date
    var mealTypeRaw: String
    var photoPath: String?
    var itemsJSON: String
    var portion: String?
    var note: String?
    var isFavorite: Bool

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .snack }
        set { mealTypeRaw = newValue.rawValue }
    }

    var items: [String] {
        get {
            guard let data = itemsJSON.data(using: .utf8),
                  let arr = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return arr
        }
        set {
            itemsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    var displayItems: String {
        items.isEmpty ? "Meal logged" : items.joined(separator: ", ")
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        timestamp: Date = Date(),
        mealType: MealType,
        photoPath: String? = nil,
        items: [String] = [],
        portion: String? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp
        self.mealTypeRaw = mealType.rawValue
        self.photoPath = photoPath
        self.itemsJSON = (try? String(data: JSONEncoder().encode(items), encoding: .utf8)) ?? "[]"
        self.portion = portion
        self.note = note
        self.isFavorite = false
    }
}

@Model
final class Metric {
    var id: UUID
    var userId: UUID
    var typeRaw: String
    var value: Double
    var timestamp: Date
    var sourceRaw: String

    var type: MetricType {
        get { MetricType(rawValue: typeRaw) ?? .steps }
        set { typeRaw = newValue.rawValue }
    }

    var source: MetricSource {
        get { MetricSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), userId: UUID, type: MetricType, value: Double, source: MetricSource = .manual) {
        self.id = id
        self.userId = userId
        self.typeRaw = type.rawValue
        self.value = value
        self.timestamp = Date()
        self.sourceRaw = source.rawValue
    }
}

@Model
final class Message {
    var id: UUID
    var threadId: UUID
    var senderId: UUID
    var senderName: String
    var body: String
    var sentAt: Date
    var readAt: Date?
    var isFromCoach: Bool

    init(
        id: UUID = UUID(),
        threadId: UUID,
        senderId: UUID,
        senderName: String,
        body: String,
        isFromCoach: Bool = false
    ) {
        self.id = id
        self.threadId = threadId
        self.senderId = senderId
        self.senderName = senderName
        self.body = body
        self.sentAt = Date()
        self.readAt = nil
        self.isFromCoach = isFromCoach
    }
}

@Model
final class Reward {
    var id: UUID
    var userId: UUID
    var kindRaw: String
    var value: Int
    var badgeName: String?
    var badgeIcon: String?
    var awardedAt: Date

    var kind: RewardKind {
        get { RewardKind(rawValue: kindRaw) ?? .points }
        set { kindRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), userId: UUID, kind: RewardKind, value: Int, badgeName: String? = nil, badgeIcon: String? = nil) {
        self.id = id
        self.userId = userId
        self.kindRaw = kind.rawValue
        self.value = value
        self.badgeName = badgeName
        self.badgeIcon = badgeIcon
        self.awardedAt = Date()
    }
}

@Model
final class Consent {
    var id: UUID
    var userId: UUID
    var typeRaw: String
    var grantedBy: String
    var grantedAt: Date
    var isGranted: Bool

    var type: ConsentType {
        get { ConsentType(rawValue: typeRaw) ?? .teenAssent }
        set { typeRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), userId: UUID, type: ConsentType, grantedBy: String, isGranted: Bool = true) {
        self.id = id
        self.userId = userId
        self.typeRaw = type.rawValue
        self.grantedBy = grantedBy
        self.grantedAt = Date()
        self.isGranted = isGranted
    }
}
