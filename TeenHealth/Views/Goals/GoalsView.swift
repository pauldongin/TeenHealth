import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [AppUser]
    @StateObject private var vm = GoalsViewModel()
    @State private var showAddGoal = false
    @State private var showUpdateProgress: Goal? = nil

    var user: AppUser? { users.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.thBackground.ignoresSafeArea()

                if let user {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            if !vm.activeGoals.isEmpty {
                                activeGoalsSection(user: user)
                            }
                            if !vm.suggestions.isEmpty {
                                suggestionsSection(user: user)
                            }
                            if vm.activeGoals.isEmpty && vm.suggestions.isEmpty {
                                EmptyStateView(
                                    icon: "target",
                                    title: "No goals yet",
                                    message: "Set your first health goal to get started",
                                    buttonTitle: "Add a Goal"
                                ) { showAddGoal = true }
                                .padding(.top, 60)
                            }
                            Spacer(minLength: 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddGoal = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.thPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddGoal) {
                if let user {
                    AddGoalSheet(user: user) { title, type, target, unit in
                        vm.addCustomGoal(title: title, type: type, target: target, unit: unit, user: user, context: context)
                    }
                }
            }
            .sheet(item: $showUpdateProgress) { goal in
                UpdateProgressSheet(goal: goal) { newValue in
                    if let user {
                        vm.updateGoalProgress(goal, progress: newValue, user: user, context: context)
                    }
                }
            }
            .onAppear {
                if let user { vm.loadGoals(user: user) }
            }
        }
    }

    // MARK: - Active Goals

    private func activeGoalsSection(user: AppUser) -> some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Active Goals")
            ForEach(vm.activeGoals) { goal in
                GoalDetailCard(goal: goal, weeklyRate: vm.weeklyCompletionRate(goal: goal)) {
                    showUpdateProgress = goal
                } onPause: {
                    vm.pauseGoal(goal)
                    vm.loadGoals(user: user)
                } onDelete: {
                    vm.deleteGoal(goal, user: user, context: context)
                }
            }
        }
    }

    // MARK: - Suggestions

    private func suggestionsSection(user: AppUser) -> some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Recommended for You")
            Text("Based on research, these goals have the biggest impact on health")
                .font(.thCaption)
                .foregroundColor(.thSubtext)

            ForEach(vm.suggestions) { template in
                SuggestionCard(template: template) {
                    vm.addRecommendedGoal(template, user: user, context: context)
                }
            }
        }
    }
}

// MARK: - Goal Detail Card

struct GoalDetailCard: View {
    let goal: Goal
    let weeklyRate: Double
    var onUpdate: () -> Void
    var onPause: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                // Icon + title
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.goalColor(for: goal.type).opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: goal.type.icon)
                            .font(.system(size: 20))
                            .foregroundColor(Color.goalColor(for: goal.type))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title)
                            .font(.thHeadline)
                            .foregroundColor(.thText)
                        HStack(spacing: 6) {
                            Text("\(Int(goal.progress)) / \(Int(goal.target)) \(goal.unit)")
                                .font(.thCaption)
                                .foregroundColor(.thSubtext)
                            if goal.source == .recommended {
                                Label("Recommended", systemImage: "checkmark.seal.fill")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.thSuccess)
                            }
                        }
                    }
                }
                Spacer()
                // Completion badge
                if goal.isCompletedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.thSuccess)
                        .font(.system(size: 22))
                }
            }

            // Progress bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.goalColor(for: goal.type).opacity(0.15))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.goalColor(for: goal.type))
                            .frame(width: geo.size.width * goal.completionPercent, height: 10)
                            .animation(.spring(response: 0.5), value: goal.completionPercent)
                    }
                }
                .frame(height: 10)
                HStack {
                    Text("\(Int(goal.completionPercent * 100))% complete today")
                        .font(.thCaption)
                        .foregroundColor(.thSubtext)
                    Spacer()
                    Text("Weekly: \(Int(weeklyRate * 100))%")
                        .font(.thCaption)
                        .foregroundColor(.thSubtext)
                }
            }

            // Actions
            HStack(spacing: 10) {
                Button("Update") { onUpdate() }
                    .font(.thCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(.thPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.thPrimary.opacity(0.1))
                    .cornerRadius(20)

                Button("Pause") { onPause() }
                    .font(.thCaption)
                    .foregroundColor(.thSubtext)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.thBackground)
                    .cornerRadius(20)

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.6))
                }
            }
        }
        .padding(16)
        .thCard()
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let template: GoalsViewModel.GoalTemplate
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.goalColor(for: template.type).opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: template.type.icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color.goalColor(for: template.type))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(template.title)
                    .font(.thHeadline)
                    .foregroundColor(.thText)
                Text(template.rationale)
                    .font(.thCaption)
                    .foregroundColor(.thSubtext)
                    .lineLimit(2)
            }
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.thPrimary)
            }
        }
        .padding(16)
        .thCard()
    }
}

// MARK: - Update Progress Sheet

struct UpdateProgressSheet: View {
    let goal: Goal
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var value: Double

    init(goal: Goal, onSave: @escaping (Double) -> Void) {
        self.goal = goal
        self.onSave = onSave
        _value = State(initialValue: goal.progress)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                ZStack {
                    ProgressRing(progress: min(value / goal.target, 1.0), color: Color.goalColor(for: goal.type), size: 140, lineWidth: 14)
                    VStack(spacing: 2) {
                        Text("\(Int(value))")
                            .font(.thPoints)
                            .foregroundColor(.thText)
                        Text(goal.unit)
                            .font(.thCaption)
                            .foregroundColor(.thSubtext)
                    }
                }

                Text(goal.title)
                    .font(.thTitle)
                    .foregroundColor(.thText)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Text("Today's progress: \(Int(value)) / \(Int(goal.target)) \(goal.unit)")
                        .font(.thBody)
                        .foregroundColor(.thSubtext)

                    Slider(value: $value, in: 0...max(goal.target * 1.5, goal.target + 10), step: goal.target <= 10 ? 1 : 100)
                        .tint(Color.goalColor(for: goal.type))
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
                            Button("\(Int(fraction * 100))%") {
                                value = goal.target * fraction
                            }
                            .font(.thCaption)
                            .foregroundColor(.thPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.thPrimary.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                Button("Save Progress") {
                    onSave(value)
                    dismiss()
                }
                .buttonStyle(THButtonStyle(color: Color.goalColor(for: goal.type), isWide: true))
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .navigationTitle("Update Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Goal Sheet

struct AddGoalSheet: View {
    let user: AppUser
    let onSave: (String, GoalType, Double, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedType: GoalType = .activity
    @State private var target: Double = 30
    @State private var unit = "minutes"

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal title", text: $title)
                    Picker("Type", selection: $selectedType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                    .onChange(of: selectedType) { _, new in
                        switch new {
                        case .steps: target = 5000; unit = "steps"
                        case .hydration: target = 6; unit = "glasses"
                        case .activity: target = 30; unit = "minutes"
                        case .sleep: target = 8; unit = "hours"
                        case .logging: target = 2; unit = "meals"
                        case .nutrition: target = 1; unit = "servings"
                        }
                    }
                }
                Section("Target") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", value: $target, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(unit).foregroundColor(.secondary)
                    }
                    TextField("Unit", text: $unit)
                }
                Section {
                    Text("Note: We don't set calorie-restriction goals. Our goals focus on positive behaviors like logging, moving, and staying hydrated.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let t = title.isEmpty ? selectedType.displayName : title
                        onSave(t, selectedType, target, unit)
                        dismiss()
                    }
                    .disabled(target <= 0)
                }
            }
        }
    }
}
