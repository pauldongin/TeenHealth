import Foundation
import SwiftData
import Combine

@MainActor
final class GoalsViewModel: ObservableObject {
    @Published var activeGoals: [Goal] = []
    @Published var showAddGoal: Bool = false
    @Published var suggestions: [GoalTemplate] = []

    private let rewardEngine: RewardEngine

    struct GoalTemplate: Identifiable {
        let id = UUID()
        let title: String
        let type: GoalType
        let target: Double
        let unit: String
        let description: String
        let rationale: String
    }

    // Evidence-based starter goals (non-restrictive, SMART)
    static let recommendedTemplates: [GoalTemplate] = [
        GoalTemplate(
            title: "Log 2 meals per day",
            type: .logging,
            target: 2,
            unit: "meals",
            description: "Track at least 2 meals each day",
            rationale: "Self-monitoring is the #1 habit shown to improve health outcomes"
        ),
        GoalTemplate(
            title: "Reach 5,000 steps daily",
            type: .steps,
            target: 5000,
            unit: "steps",
            description: "Get at least 5,000 steps every day",
            rationale: "Regular movement boosts energy and supports a healthy weight"
        ),
        GoalTemplate(
            title: "Drink 6 glasses of water",
            type: .hydration,
            target: 6,
            unit: "glasses",
            description: "Stay hydrated with 6+ glasses of water daily",
            rationale: "Proper hydration helps regulate hunger and energy levels"
        ),
        GoalTemplate(
            title: "Swap 1 sugary drink for water",
            type: .nutrition,
            target: 1,
            unit: "swaps",
            description: "Replace one sugary drink with water today",
            rationale: "Reducing sugary drinks is one of the highest-impact dietary changes"
        ),
        GoalTemplate(
            title: "30 min of activity",
            type: .activity,
            target: 30,
            unit: "minutes",
            description: "Be active for 30 minutes — any activity counts!",
            rationale: "WHO recommends 60 min/day for teens; 30 is a great starting point"
        ),
        GoalTemplate(
            title: "Sleep 8–10 hours",
            type: .sleep,
            target: 8,
            unit: "hours",
            description: "Aim for a full night of quality sleep",
            rationale: "Sleep is critical for healthy metabolism and appetite regulation"
        )
    ]

    init(rewardEngine: RewardEngine = RewardEngine()) {
        self.rewardEngine = rewardEngine
    }

    func loadGoals(user: AppUser) {
        activeGoals = user.goals.filter { $0.status == .active }
        buildSuggestions(user: user)
    }

    private func buildSuggestions(user: AppUser) {
        let existingTypes = Set(user.goals.map { $0.type })
        suggestions = Self.recommendedTemplates.filter { !existingTypes.contains($0.type) }
    }

    func addRecommendedGoal(_ template: GoalTemplate, user: AppUser, context: ModelContext) {
        let goal = Goal(
            userId: user.id,
            title: template.title,
            type: template.type,
            target: template.target,
            unit: template.unit,
            source: .recommended
        )
        context.insert(goal)
        user.goals.append(goal)
        loadGoals(user: user)
    }

    func addCustomGoal(title: String, type: GoalType, target: Double, unit: String, user: AppUser, context: ModelContext) {
        let goal = Goal(
            userId: user.id,
            title: title,
            type: type,
            target: target,
            unit: unit,
            source: .custom
        )
        context.insert(goal)
        user.goals.append(goal)
        loadGoals(user: user)
    }

    func updateGoalProgress(_ goal: Goal, progress: Double, user: AppUser, context: ModelContext) {
        let wasComplete = goal.isCompletedToday
        goal.progress = progress
        if !wasComplete && goal.isCompletedToday {
            _ = rewardEngine.awardPoints(for: .goalHit, user: user, context: context)
        }
    }

    func pauseGoal(_ goal: Goal) {
        goal.status = .paused
    }

    func resumeGoal(_ goal: Goal) {
        goal.status = .active
    }

    func deleteGoal(_ goal: Goal, user: AppUser, context: ModelContext) {
        context.delete(goal)
        user.goals.removeAll { $0.id == goal.id }
        loadGoals(user: user)
    }

    func generateStarterGoals(for user: AppUser, context: ModelContext) {
        // Generate 3 recommended goals for new users
        let starters = [
            Self.recommendedTemplates[0],  // Log 2 meals
            Self.recommendedTemplates[1],  // 5000 steps
            Self.recommendedTemplates[2]   // 6 glasses water
        ]
        for template in starters {
            let goal = Goal(
                userId: user.id,
                title: template.title,
                type: template.type,
                target: template.target,
                unit: template.unit,
                source: .recommended
            )
            context.insert(goal)
            user.goals.append(goal)
        }
    }

    func weeklyCompletionRate(goal: Goal) -> Double {
        let weekly = goal.weeklyProgress
        guard !weekly.isEmpty else { return 0 }
        let met = weekly.filter { p in p >= goal.target }.count
        return Double(met) / Double(weekly.count)
    }
}
