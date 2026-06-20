import Foundation
import UserNotifications

final class NotificationService: ObservableObject {
    @Published var isAuthorized: Bool = false

    private var quietStart: Int = 22  // 10 PM
    private var quietEnd: Int = 7     // 7 AM

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { isAuthorized = granted }
            return granted
        } catch {
            return false
        }
    }

    func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Quiet Hours

    func setQuietHours(start: Int, end: Int) {
        quietStart = start
        quietEnd = end
    }

    private func isQuietHour(_ hour: Int) -> Bool {
        if quietStart > quietEnd {
            return hour >= quietStart || hour < quietEnd
        }
        return hour >= quietStart && hour < quietEnd
    }

    // MARK: - Schedule Meal Reminder

    func scheduleMealReminder(meal: MealType, hour: Int, minute: Int) {
        guard !isQuietHour(hour) else { return }

        let id = "meal_\(meal.rawValue)"
        let content = UNMutableNotificationContent()
        content.title = "Time to log \(meal.displayName)!"
        content.body = mealReminderBody(for: meal)
        content.sound = .default
        content.categoryIdentifier = "MEAL_LOG"
        content.userInfo = ["mealType": meal.rawValue]

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func mealReminderBody(for meal: MealType) -> String {
        switch meal {
        case .breakfast: return "Start your day strong! Log what you had for breakfast. 🌅"
        case .lunch:     return "Midday check-in! What did you have for lunch? 🥗"
        case .dinner:    return "Evening check-in! Log your dinner to keep your streak going. 🌙"
        case .snack:     return "Had a snack? Log it to keep track of your day! 🍎"
        }
    }

    // MARK: - Schedule Step Reminder

    func scheduleStepReminder(hour: Int, minute: Int) {
        guard !isQuietHour(hour) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Keep moving! 🚶"
        content.body = "Check your step count for today. Every step counts toward your goal!"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "step_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Weekly Weigh-In

    func scheduleWeighInReminder(weekday: Int, hour: Int) {
        guard !isQuietHour(hour) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Weekly weigh-in 📊"
        content.body = "Track your progress! Logging your weight helps your coach support you better."
        content.sound = .default

        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weigh_in", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Streak Reminder

    func scheduleStreakReminder(hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Don't lose your streak! 🔥"
        content.body = "You're on a roll — log something today to keep it going."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "streak_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel

    func cancelReminder(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Suppress if Already Logged

    func suppressMealReminderIfLogged(meal: MealType, todayLogs: [FoodLog]) {
        let calendar = Calendar.current
        let alreadyLogged = todayLogs.contains {
            $0.mealType == meal && calendar.isDateInToday($0.timestamp)
        }
        if alreadyLogged {
            cancelReminder(id: "meal_\(meal.rawValue)")
            // Reschedule for tomorrow (next repeat will auto-trigger)
            scheduleMealReminder(meal: meal, hour: meal.defaultHour, minute: 0)
        }
    }

    // MARK: - Schedule All Defaults

    func scheduleAllDefaults(quietStart: Int = 22, quietEnd: Int = 7) {
        setQuietHours(start: quietStart, end: quietEnd)
        scheduleMealReminder(meal: .breakfast, hour: 8, minute: 0)
        scheduleMealReminder(meal: .lunch, hour: 12, minute: 30)
        scheduleMealReminder(meal: .dinner, hour: 18, minute: 30)
        scheduleStepReminder(hour: 16, minute: 0)
        scheduleWeighInReminder(weekday: 2, hour: 9)  // Monday 9 AM
        scheduleStreakReminder(hour: 20)
    }
}
