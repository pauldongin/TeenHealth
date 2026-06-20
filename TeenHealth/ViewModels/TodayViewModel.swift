import Foundation
import SwiftData
import Combine

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var steps: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var sleepHours: Double = 0
    @Published var todayLogs: [FoodLog] = []
    @Published var activeGoals: [Goal] = []
    @Published var coachPrompt: String = ""
    @Published var showRewardAnimation: Bool = false
    @Published var lastRewardMessage: String = ""
    @Published var isLoadingHealth: Bool = false

    private let healthService: HealthServiceProtocol
    private let rewardEngine: RewardEngine

    private let coachPrompts = [
        "How are your energy levels today? Try to get outside for a short walk! 🚶",
        "Remember: every meal you log is a win, no matter what it is. Keep it up! 🌟",
        "Great job staying consistent! Your coach is proud of your effort. 💪",
        "Try drinking a glass of water right now. Small habits = big results! 💧",
        "Check in with yourself: how are you feeling today, really? 🧠",
        "Movement doesn't have to be intense — even a 10-min walk makes a difference! 👟",
        "You're making progress every single day. Keep going! 🌱"
    ]

    init(healthService: HealthServiceProtocol = MockHealthService(), rewardEngine: RewardEngine = RewardEngine()) {
        self.healthService = healthService
        self.rewardEngine = rewardEngine
        self.coachPrompt = coachPrompts.randomElement()!
    }

    func loadData(user: AppUser) async {
        isLoadingHealth = true
        async let stepsTask = healthService.fetchTodaySteps()
        async let energyTask = healthService.fetchTodayActiveEnergy()
        async let sleepTask = healthService.fetchSleepHours()

        steps = await stepsTask
        activeEnergy = await energyTask
        sleepHours = await sleepTask
        isLoadingHealth = false

        // Update step goal progress
        updateStepGoalProgress(user: user)
    }

    func refreshTodayLogs(user: AppUser) {
        let calendar = Calendar.current
        todayLogs = user.foodLogs.filter { calendar.isDateInToday($0.timestamp) }
    }

    func refreshGoals(user: AppUser) {
        activeGoals = user.goals.filter { $0.status == .active }
    }

    private func updateStepGoalProgress(user: AppUser) {
        if let stepGoal = user.goals.first(where: { $0.type == .steps && $0.status == .active }) {
            stepGoal.progress = steps
        }
    }

    func loggedMealsToday(user: AppUser) -> Set<MealType> {
        let calendar = Calendar.current
        let todayLogs = user.foodLogs.filter { calendar.isDateInToday($0.timestamp) }
        return Set(todayLogs.map { $0.mealType })
    }

    func stepProgress(goal: Goal) -> Double {
        guard goal.target > 0 else { return 0 }
        return min(steps / goal.target, 1.0)
    }
}
