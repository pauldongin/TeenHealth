import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var users: [AppUser]
    @StateObject private var coachVM = CoachViewModel()

    var user: AppUser? { users.first }

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }

            LogView()
                .tabItem {
                    Label("Log", systemImage: "fork.knife")
                }

            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }

            CoachView()
                .tabItem {
                    Label("Coach", systemImage: "message.badge.filled.fill")
                }
                .badge(coachVM.unreadCount > 0 ? coachVM.unreadCount : 0)

            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.thPrimary)
    }
}
