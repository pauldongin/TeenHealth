import SwiftUI
import SwiftData
import HealthKit

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [AppUser]
    @StateObject private var notifService = NotificationService()
    @State private var showDeleteConfirm = false
    @State private var showExportAlert = false
    @State private var showWeightLog = false
    @State private var breakfastHour = 8
    @State private var lunchHour = 12
    @State private var dinnerHour = 18
    @State private var stepReminderHour = 16
    @State private var quietStart = 22
    @State private var quietEnd = 7
    @State private var notificationsEnabled = true
    @State private var leaderboardOptIn = false
    @State private var showAvatarEditor = false

    var user: AppUser? { users.first }

    var body: some View {
        NavigationStack {
            List {
                profileSection
                notificationsSection
                healthSection
                privacySection
                wellbeingSection
                accountSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showWeightLog) {
                if let user { WeightLogSheet(user: user, context: context) }
            }
            .sheet(isPresented: $showAvatarEditor) {
                if let user { AvatarEditorSheet(user: user) }
            }
            .alert("Delete All Data", isPresented: $showDeleteConfirm) {
                Button("Delete Everything", role: .destructive) { deleteAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your health data, goals, messages, and rewards. This cannot be undone.")
            }
            .alert("Data Export", isPresented: $showExportAlert) {
                Button("OK") {}
            } message: {
                Text("Your data export has been prepared. In a production app, this would download a JSON file with all your health records.")
            }
            .onAppear {
                if let user { leaderboardOptIn = user.leaderboardOptIn }
                Task { await notifService.checkStatus() }
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            if let user {
                HStack(spacing: 14) {
                    AvatarView(config: user.avatarConfig, size: 60)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.thHeadline)
                            .foregroundColor(.thText)
                        Text("Age group: \(user.ageBand)")
                            .font(.thCaption)
                            .foregroundColor(.thSubtext)
                        PointsPill(
                            points: user.points,
                            levelName: RewardEngine().currentLevel(for: user.points).name
                        )
                    }
                }
                .padding(.vertical, 4)

                Button {
                    showAvatarEditor = true
                } label: {
                    Label("Edit Avatar", systemImage: "paintbrush.fill")
                        .foregroundColor(.thPrimary)
                }
            }
        } header: {
            Text("Profile")
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                Label("Enable Reminders", systemImage: "bell.fill")
            }
            .tint(.thPrimary)
            .onChange(of: notificationsEnabled) { _, enabled in
                if enabled {
                    Task {
                        let granted = await notifService.requestPermission()
                        if granted {
                            notifService.scheduleAllDefaults(quietStart: quietStart, quietEnd: quietEnd)
                        }
                    }
                } else {
                    notifService.cancelAllReminders()
                }
            }

            if notificationsEnabled {
                ReminderTimePicker(label: "Breakfast reminder", hour: $breakfastHour) {
                    notifService.scheduleMealReminder(meal: .breakfast, hour: breakfastHour, minute: 0)
                }
                ReminderTimePicker(label: "Lunch reminder", hour: $lunchHour) {
                    notifService.scheduleMealReminder(meal: .lunch, hour: lunchHour, minute: 0)
                }
                ReminderTimePicker(label: "Dinner reminder", hour: $dinnerHour) {
                    notifService.scheduleMealReminder(meal: .dinner, hour: dinnerHour, minute: 0)
                }
                ReminderTimePicker(label: "Steps check-in", hour: $stepReminderHour) {
                    notifService.scheduleStepReminder(hour: stepReminderHour, minute: 0)
                }

                HStack {
                    Text("Quiet hours")
                        .foregroundColor(.thText)
                    Spacer()
                    Text("\(hourLabel(quietStart)) – \(hourLabel(quietEnd))")
                        .font(.thCaption)
                        .foregroundColor(.thSubtext)
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Reminders are skipped if you've already completed that action today.")
                .font(.thCaption)
        }
    }

    // MARK: - Health Section

    private var healthSection: some View {
        Section {
            Button {
                Task {
                    let service = RealHealthService()
                    try? await service.requestAuthorization()
                }
            } label: {
                Label("Connect Apple Health", systemImage: "heart.fill")
                    .foregroundColor(.thPrimary)
            }

            Button {
                showWeightLog = true
            } label: {
                Label("Log Weight", systemImage: "scalemass.fill")
                    .foregroundColor(.thPrimary)
            }
        } header: {
            Text("Health & Activity")
        } footer: {
            Text("HealthKit data stays on your device and is never sent to third-party analytics.")
                .font(.thCaption)
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section {
            Toggle(isOn: $leaderboardOptIn) {
                Label("Join Leaderboard (pseudonymous)", systemImage: "trophy")
            }
            .tint(.thPrimary)
            .onChange(of: leaderboardOptIn) { _, new in
                user?.leaderboardOptIn = new
            }

            NavigationLink {
                ConsentDetailView(user: user)
            } label: {
                Label("View Consent Records", systemImage: "doc.text")
            }

            Button {
                showExportAlert = true
            } label: {
                Label("Export My Data", systemImage: "square.and.arrow.up")
                    .foregroundColor(.thPrimary)
            }

            Button {
                showDeleteConfirm = true
            } label: {
                Label("Delete All My Data", systemImage: "trash")
                    .foregroundColor(.red)
            }
        } header: {
            Text("Privacy & Data")
        } footer: {
            Text("Your data is encrypted at rest. We never sell your data or show ads. You can delete everything at any time.")
                .font(.thCaption)
        }
    }

    // MARK: - Wellbeing Section

    private var wellbeingSection: some View {
        Section {
            Link(destination: URL(string: "https://www.crisistextline.org")!) {
                Label("Crisis Text Line", systemImage: "phone.fill")
                    .foregroundColor(.thSuccess)
            }
            NavigationLink {
                WellbeingResourcesView()
            } label: {
                Label("Wellbeing Resources", systemImage: "heart.circle.fill")
            }
        } header: {
            Text("Support & Wellbeing")
        } footer: {
            Text("You're not alone. These resources are available 24/7.")
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            HStack {
                Text("App Version")
                    .foregroundColor(.thText)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.thSubtext)
            }
            HStack {
                Text("Data Storage")
                    .foregroundColor(.thText)
                Spacer()
                Text("On-device (encrypted)")
                    .foregroundColor(.thSubtext)
            }
            Text("TeenHealth is a supplement to — not a replacement for — clinical care. Always consult your healthcare team.")
                .font(.thCaption)
                .foregroundColor(.thSubtext)
        } header: {
            Text("About")
        }
    }

    // MARK: - Helpers

    private func hourLabel(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "AM" : "PM"
        return "\(h) \(suffix)"
    }

    private func deleteAllData() {
        guard let user else { return }
        // Delete all related objects
        user.foodLogs.forEach { context.delete($0) }
        user.goals.forEach { context.delete($0) }
        user.metrics.forEach { context.delete($0) }
        user.messages.forEach { context.delete($0) }
        user.rewards.forEach { context.delete($0) }
        user.consents.forEach { context.delete($0) }
        context.delete(user)
        try? context.save()
    }
}

// MARK: - Reminder Time Picker

struct ReminderTimePicker: View {
    let label: String
    @Binding var hour: Int
    var onSave: () -> Void

    let hours = Array(0..<24)

    var body: some View {
        HStack {
            Text(label).foregroundColor(.thText)
            Spacer()
            Picker("Hour", selection: $hour) {
                ForEach(hours, id: \.self) { h in
                    Text(hourLabel(h)).tag(h)
                }
            }
            .pickerStyle(.menu)
            .tint(.thPrimary)
            .onChange(of: hour) { _, _ in onSave() }
        }
    }

    func hourLabel(_ h: Int) -> String {
        let hour = h % 12 == 0 ? 12 : h % 12
        return "\(hour) \(h < 12 ? "AM" : "PM")"
    }
}

// MARK: - Weight Log Sheet

struct WeightLogSheet: View {
    let user: AppUser
    let context: ModelContext

    @Environment(\.dismiss) private var dismiss
    @State private var weightKg: Double = 65
    @State private var useKg = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight Entry") {
                    Picker("Unit", selection: $useKg) {
                        Text("kg").tag(true)
                        Text("lbs").tag(false)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("0", value: $weightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(useKg ? "kg" : "lbs")
                    }
                }
                Section {
                    Text("Your weight is private and shared only with your coach.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let kgValue = useKg ? weightKg : weightKg * 0.453592
                        let metric = Metric(userId: user.id, type: .weight, value: kgValue, source: .manual)
                        context.insert(metric)
                        user.metrics.append(metric)
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Consent Detail View

struct ConsentDetailView: View {
    let user: AppUser?

    var body: some View {
        List {
            if let user {
                ForEach(user.consents) { consent in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(consent.type.rawValue.camelCaseToWords)
                                .font(.thHeadline)
                            Spacer()
                            Image(systemName: consent.isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(consent.isGranted ? .thSuccess : .red)
                        }
                        Text("By: \(consent.grantedBy)")
                            .font(.thCaption)
                            .foregroundColor(.thSubtext)
                        Text(consent.grantedAt, style: .date)
                            .font(.thCaption)
                            .foregroundColor(.thSubtext)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Consent Records")
    }
}

// MARK: - Wellbeing Resources View

struct WellbeingResourcesView: View {
    var body: some View {
        List {
            Section("Crisis Support") {
                Link("Crisis Text Line: Text HOME to 741741", destination: URL(string: "sms:741741")!)
                Link("988 Suicide & Crisis Lifeline: Call 988", destination: URL(string: "tel:988")!)
            }
            Section("Eating & Body Image") {
                Text("National Eating Disorders Association (NEDA): 1-800-931-2237")
                Text("NEDA Crisis Text Line: Text NEDA to 741741")
            }
            Section("Teen Support") {
                Text("Teen Line: 1-800-852-8336 (6–10 PM PT nightly)")
                Text("Boys Town National Hotline: 1-800-448-3000")
            }
            Section("In-App") {
                Text("Message your coach in the Coach tab — they're here for you.")
                Text("If you're in immediate danger, call 911 or go to your nearest emergency room.")
            }
        }
        .navigationTitle("Wellbeing Resources")
    }
}

// MARK: - Avatar Editor Sheet

struct AvatarEditorSheet: View {
    let user: AppUser
    @Environment(\.dismiss) private var dismiss
    @State private var config: AvatarConfig

    init(user: AppUser) {
        self.user = user
        _config = State(initialValue: user.avatarConfig)
    }

    var body: some View {
        NavigationStack {
            AvatarPage(avatarConfig: $config)
                .navigationTitle("Edit Avatar")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            user.avatarConfig = config
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - String Extension

extension String {
    var camelCaseToWords: String {
        var result = ""
        for char in self {
            if char.isUppercase && !result.isEmpty {
                result += " "
            }
            result += String(char)
        }
        return result.capitalized
    }
}
