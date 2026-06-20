import SwiftUI
import SwiftData

// MARK: - Profile Tab (Progress + Learn + Settings in one place)

struct ProfileTab: View {
    @Query private var users: [AppUser]
    var user: AppUser? { users.first }

    var body: some View {
        NavigationStack {
            List {
                // ── Avatar header ──────────────────────────────────────
                if let user {
                    HStack(spacing: 16) {
                        AvatarView(config: user.avatarConfig, size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName.capitalized)
                                .font(.thTitle)
                                .foregroundColor(.thText)
                            Text("Age \(user.ageBand) · \(user.points) pts")
                                .font(.thCaption)
                                .foregroundColor(.thSubtext)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.thCard)
                }

                // ── Navigation links ───────────────────────────────────
                Section {
                    NavigationLink {
                        ProgressTabView()
                    } label: {
                        Label("Progress & Badges", systemImage: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.thText)
                    }

                    NavigationLink {
                        LearnView()
                    } label: {
                        Label("Learn", systemImage: "book.fill")
                            .foregroundColor(.thText)
                    }
                }
                .listRowBackground(Color.thCard)

                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                            .foregroundColor(.thText)
                    }
                }
                .listRowBackground(Color.thCard)
            }
            .scrollContentBackground(.hidden)
            .background(Color.thBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

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
                    Label("Coach", systemImage: "message.fill")
                }
                .badge(coachVM.unreadCount > 0 ? coachVM.unreadCount : 0)

            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
        }
        .tint(.thPrimary)
    }
}
