import SwiftUI
import SwiftData

@main
struct TeenHealthApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                AppUser.self,
                Goal.self,
                FoodLog.self,
                Metric.self,
                Message.self,
                Reward.self,
                Consent.self
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .none,
                cloudKitDatabase: .none  // No CloudKit — HealthKit data never goes to iCloud
            )
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            // Schema migration failed — wipe the store and start fresh
            // (only happens during development when models change)
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            let schema = Schema([AppUser.self, Goal.self, FoodLog.self, Metric.self, Message.self, Reward.self, Consent.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, groupContainer: .none, cloudKitDatabase: .none)
            modelContainer = (try? ModelContainer(for: schema, configurations: config))
                ?? { fatalError("SwiftData unrecoverable: \(error)") }()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(modelContainer)
        }
    }
}

// MARK: - Root View (Onboarding gate)

struct RootView: View {
    @Query private var users: [AppUser]
    @State private var hasCompletedOnboarding: Bool = false

    var body: some View {
        ZStack {
            // True edge-to-edge background — covers Dynamic Island & home indicator
            Color.thBackground.ignoresSafeArea(.all)

            if let user = users.first, user.hasCompletedOnboarding {
                ContentView()
                    .onAppear {
                        Task {
                            let service = NotificationService()
                            let granted = await service.requestPermission()
                            if granted { service.scheduleAllDefaults() }
                        }
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .onChange(of: hasCompletedOnboarding) { _, completed in
                        if completed {
                            Task {
                                let service = NotificationService()
                                let granted = await service.requestPermission()
                                if granted { service.scheduleAllDefaults() }
                            }
                        }
                    }
            }
        }
    }
}
