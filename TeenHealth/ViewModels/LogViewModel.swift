import Foundation
import SwiftData
import UIKit
import Combine

@MainActor
final class LogViewModel: ObservableObject {
    @Published var todayLogs: [FoodLog] = []
    @Published var recentFoods: [String] = []
    @Published var favoriteLogs: [FoodLog] = []
    @Published var showCamera: Bool = false
    @Published var capturedImage: UIImage? = nil
    @Published var selectedMealType: MealType = .breakfast
    @Published var searchText: String = ""
    @Published var searchResults: [String] = []
    @Published var showLogForm: Bool = false
    @Published var logSuccessMessage: String = ""
    @Published var showSuccess: Bool = false

    private let rewardEngine: RewardEngine

    // Sample food database (real app would use USDA API)
    private let foodDatabase: [String] = [
        "Apple", "Banana", "Orange", "Grapes", "Strawberries",
        "Chicken breast", "Salmon", "Tuna", "Eggs", "Greek yogurt",
        "Brown rice", "Quinoa", "Oatmeal", "Whole wheat bread", "Sweet potato",
        "Broccoli", "Spinach", "Carrot", "Tomato", "Avocado",
        "Almonds", "Walnuts", "Peanut butter", "Hummus",
        "Milk", "Cheese", "Tofu", "Lentils", "Black beans",
        "Mixed salad", "Veggie wrap", "Chicken sandwich", "Fruit smoothie",
        "Pasta", "Pizza", "Burger", "Fries", "Rice and beans",
        "Soda", "Juice", "Water", "Tea", "Coffee",
        "Granola bar", "Crackers", "Chips", "Cookie", "Ice cream"
    ]

    init(rewardEngine: RewardEngine = RewardEngine()) {
        self.rewardEngine = rewardEngine
        selectedMealType = currentMealType()
    }

    func currentMealType() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<11: return .breakfast
        case 11..<15: return .lunch
        case 17..<21: return .dinner
        default: return .snack
        }
    }

    func refreshLogs(user: AppUser) {
        let calendar = Calendar.current
        todayLogs = user.foodLogs
            .filter { calendar.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp > $1.timestamp }
        favoriteLogs = user.foodLogs.filter { $0.isFavorite }.sorted { $0.timestamp > $1.timestamp }
        buildRecentFoods(user: user)
    }

    private func buildRecentFoods(user: AppUser) {
        let recent = user.foodLogs
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(30)
            .flatMap { $0.items }
        var seen = Set<String>()
        recentFoods = recent.filter { seen.insert($0).inserted }.prefix(10).map { $0 }
    }

    func search(_ text: String) {
        if text.isEmpty {
            searchResults = Array(foodDatabase.prefix(8))
        } else {
            searchResults = foodDatabase.filter { $0.lowercased().contains(text.lowercased()) }
        }
    }

    func quickLog(mealType: MealType, items: [String], user: AppUser, context: ModelContext) {
        let log = FoodLog(
            userId: user.id,
            mealType: mealType,
            items: items
        )
        context.insert(log)
        user.foodLogs.append(log)

        // Award points
        let pts = rewardEngine.awardPoints(for: .foodLog, user: user, context: context)
        if user.foodLogs.count == 1 {
            _ = rewardEngine.awardPoints(for: .firstLog, user: user, context: context)
        }

        let newBadges = rewardEngine.checkAndAwardBadges(for: user, context: context)
        let badgeText = newBadges.isEmpty ? "" : " + Badge: \(newBadges.first?.badgeName ?? "")!"
        logSuccessMessage = "+\(pts) points\(badgeText)"
        showSuccess = true

        refreshLogs(user: user)
        updateLoggingGoalProgress(user: user, context: context)
    }

    func photoLog(mealType: MealType, image: UIImage, note: String, user: AppUser, context: ModelContext) {
        let imagePath = saveImage(image)
        let log = FoodLog(
            userId: user.id,
            mealType: mealType,
            photoPath: imagePath,
            note: note.isEmpty ? nil : note
        )
        context.insert(log)
        user.foodLogs.append(log)

        let pts = rewardEngine.awardPoints(for: .foodLog, user: user, context: context)
        logSuccessMessage = "Photo logged! +\(pts) points"
        showSuccess = true

        refreshLogs(user: user)
        updateLoggingGoalProgress(user: user, context: context)
    }

    func repeatLog(_ log: FoodLog, user: AppUser, context: ModelContext) {
        let newLog = FoodLog(
            userId: user.id,
            mealType: log.mealType,
            photoPath: log.photoPath,
            items: log.items,
            portion: log.portion,
            note: log.note
        )
        context.insert(newLog)
        user.foodLogs.append(newLog)

        let pts = rewardEngine.awardPoints(for: .foodLog, user: user, context: context)
        logSuccessMessage = "Logged again! +\(pts) points"
        showSuccess = true

        refreshLogs(user: user)
    }

    func deleteLog(_ log: FoodLog, user: AppUser, context: ModelContext) {
        context.delete(log)
        user.foodLogs.removeAll { $0.id == log.id }
        refreshLogs(user: user)
    }

    func toggleFavorite(_ log: FoodLog) {
        log.isFavorite.toggle()
    }

    private func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FoodLogs")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let fileURL = url.appendingPathComponent(filename)
        try? data.write(to: fileURL)
        return fileURL.path
    }

    private func updateLoggingGoalProgress(user: AppUser, context: ModelContext) {
        let calendar = Calendar.current
        let todayCount = Double(user.foodLogs.filter { calendar.isDateInToday($0.timestamp) }.count)
        if let goal = user.goals.first(where: { $0.type == .logging && $0.status == .active }) {
            goal.progress = todayCount
            if goal.isCompletedToday {
                _ = rewardEngine.awardPoints(for: .goalHit, user: user, context: context)
            }
        }
    }
}
