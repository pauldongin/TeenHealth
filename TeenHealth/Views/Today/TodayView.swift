import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [AppUser]
    @StateObject private var vm = TodayViewModel()
    @StateObject private var logVM = LogViewModel()
    @State private var showQuickLog = false
    @State private var showToast = false
    @State private var toastMessage = ""

    var user: AppUser? { users.first }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.thBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        coachPromptCard
                        goalsSection
                        quickStatsRow
                        todayTimelineSection
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .bottom) {
                quickLogButton
            }
            .overlay(alignment: .top) {
                if showToast {
                    ToastView(message: toastMessage, icon: "star.fill", color: .thGold)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showQuickLog) {
                QuickLogSheet(user: user!) { mealType, items in
                    logVM.quickLog(mealType: mealType, items: items, user: user!, context: context)
                    vm.refreshTodayLogs(user: user!)
                    vm.refreshGoals(user: user!)
                    showToast(logVM.logSuccessMessage)
                }
            }
            .task {
                if let user {
                    await vm.loadData(user: user)
                    vm.refreshTodayLogs(user: user)
                    vm.refreshGoals(user: user)
                    logVM.refreshLogs(user: user)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.thTitle)
                    .foregroundColor(.thText)
                if let user {
                    Text(user.displayName.capitalized)
                        .font(.thDisplay)
                        .foregroundColor(.thPrimary)
                }
            }
            Spacer()
            if let user {
                VStack(spacing: 8) {
                    AvatarView(config: user.avatarConfig, size: 52)
                    StreakBadge(streak: user.currentStreak)
                }
            }
        }
        .padding(.top, 12)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<21: return "Good evening,"
        default:     return "Hey,"
        }
    }

    // MARK: - Coach Prompt

    private var coachPromptCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.thPrimary, .thAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 46, height: 46)
                Text("AC")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.thSuccess)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(Color.thCard, lineWidth: 2))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Coach Alex")
                        .font(.thCaption)
                        .fontWeight(.bold)
                        .foregroundColor(.thText)
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 10))
                        .foregroundColor(.thSuccess)
                }
                Text(vm.coachPrompt)
                    .font(.thBody)
                    .foregroundColor(.thSubtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .thCard()
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Today's Goals")
            if vm.activeGoals.isEmpty {
                Text("No active goals. Head to Goals to add some!")
                    .font(.thBody)
                    .foregroundColor(.thSubtext)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(vm.activeGoals) { goal in
                        GoalRingCard(goal: goal)
                    }
                }
            }
        }
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            StatPill(
                icon: "figure.walk",
                value: vm.isLoadingHealth ? "--" : "\(Int(vm.steps))",
                label: "Steps",
                color: .thAccent
            )
            StatPill(
                icon: "bolt.fill",
                value: vm.isLoadingHealth ? "--" : "\(Int(vm.activeEnergy)) kcal",
                label: "Active",
                color: .thEnergy
            )
            StatPill(
                icon: "moon.zzz.fill",
                value: vm.isLoadingHealth ? "--" : String(format: "%.1fh", vm.sleepHours),
                label: "Sleep",
                color: Color(hex: "#A29BFE")
            )
        }
    }

    // MARK: - Today Timeline

    private var todayTimelineSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Today's Log")
            if vm.todayLogs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 36))
                        .foregroundColor(.thBorder)
                    Text("No meals logged yet today")
                        .font(.thBody)
                        .foregroundColor(.thSubtext)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .thCard()
            } else {
                VStack(spacing: 1) {
                    ForEach(vm.todayLogs) { log in
                        FoodLogRow(log: log)
                    }
                }
                .thCard()
            }
        }
    }

    // MARK: - Quick Log Button

    private var quickLogButton: some View {
        Button {
            if user != nil { showQuickLog = true }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Log a Meal")
                    .font(.thHeadline)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [.thEnergy, .thPrimary], startPoint: .leading, endPoint: .trailing))
            )
            .shadow(color: .thPrimary.opacity(0.35), radius: 14, y: 5)
        }
        .padding(.bottom, 20)
    }

    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring()) { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
    }
}

// MARK: - Goal Ring Card

struct GoalRingCard: View {
    let goal: Goal

    private var isDone: Bool { goal.isCompletedToday }
    private var goalColor: Color { isDone ? .thSuccess : Color.goalColor(for: goal.type) }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                ProgressRing(
                    progress: min(goal.completionPercent, 1.0),
                    color: goalColor,
                    size: 68,
                    lineWidth: 8
                )
                if isDone {
                    // Completed: show checkmark
                    ZStack {
                        Circle()
                            .fill(Color.thSuccess.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.thSuccess)
                    }
                } else {
                    Image(systemName: goal.type.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(goalColor)
                }
            }
            VStack(spacing: 2) {
                Text(goal.title)
                    .font(.thCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(isDone ? .thSuccess : .thText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(isDone ? "Done! 🎉" : "\(Int(goal.progress)) / \(Int(goal.target)) \(goal.unit)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isDone ? .thSuccess : .thSubtext)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(isDone ? Color.thSuccess.opacity(0.08) : Color.thCard)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isDone ? Color.thSuccess : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.thText)
            Text(label)
                .font(.thCaption)
                .foregroundColor(.thSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .thCard()
    }
}

// MARK: - Food Log Row

struct FoodLogRow: View {
    let log: FoodLog

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: log.mealType == .breakfast ? "#FFF3E0" : log.mealType == .lunch ? "#E8F5E9" : log.mealType == .dinner ? "#EDE7F6" : "#E3F2FD"))
                    .frame(width: 42, height: 42)
                Image(systemName: log.mealType.icon)
                    .foregroundColor(mealColor(log.mealType))
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(log.mealType.displayName)
                    .font(.thHeadline)
                    .foregroundColor(.thText)
                Text(log.photoPath != nil ? "Photo logged" : log.displayItems)
                    .font(.thCaption)
                    .foregroundColor(.thSubtext)
                    .lineLimit(1)
            }
            Spacer()
            Text(log.timestamp, format: .dateTime.hour().minute())
                .font(.thCaption)
                .foregroundColor(.thSubtext)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    func mealColor(_ type: MealType) -> Color {
        switch type {
        case .breakfast: return Color(hex: "#FF9800")
        case .lunch:     return Color(hex: "#4CAF50")
        case .dinner:    return Color(hex: "#7E57C2")
        case .snack:     return Color(hex: "#29B6F6")
        }
    }
}

// MARK: - Quick Log Sheet

struct QuickLogSheet: View {
    let user: AppUser
    let onLog: (MealType, [String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeal: MealType = .snack
    @State private var selectedItems: Set<String> = []
    @State private var customItem: String = ""
    @State private var showCamera = false
    @State private var capturedImage: UIImage? = nil
    @State private var note: String = ""

    private let recentItems = ["Apple", "Banana", "Chicken", "Rice", "Salad", "Sandwich", "Yogurt", "Oatmeal", "Pasta", "Soup"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Meal type picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What meal is this?")
                            .font(.thHeadline)
                            .foregroundColor(.thText)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(MealType.allCases, id: \.self) { meal in
                                    MealTypeChip(meal: meal, isSelected: selectedMeal == meal)
                                        .onTapGesture { selectedMeal = meal }
                                }
                            }
                        }
                    }

                    // Photo option
                    Button {
                        showCamera = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                            VStack(alignment: .leading) {
                                Text("Take a Photo")
                                    .font(.thHeadline)
                                Text("Fastest way to log — just snap it!")
                                    .font(.thCaption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(colors: [.thEnergy, Color(hex: "#FF8C42")], startPoint: .leading, endPoint: .trailing))
                        )
                    }

                    if capturedImage != nil {
                        Image(uiImage: capturedImage!)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
                            .cornerRadius(14)
                    }

                    // Quick picks
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick picks")
                            .font(.thHeadline)
                            .foregroundColor(.thText)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(recentItems, id: \.self) { item in
                                FoodChip(name: item, isSelected: selectedItems.contains(item)) {
                                    if selectedItems.contains(item) {
                                        selectedItems.remove(item)
                                    } else {
                                        selectedItems.insert(item)
                                    }
                                }
                            }
                        }
                    }

                    // Note field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a note (optional)")
                            .font(.thHeadline)
                            .foregroundColor(.thText)
                        TextField("How did this meal make you feel?", text: $note, axis: .vertical)
                            .lineLimit(2...4)
                            .font(.thBody)
                            .padding()
                            .background(Color.thBackground)
                            .cornerRadius(12)
                    }

                    // Log button
                    Button("Log \(selectedMeal.displayName)") {
                        onLog(selectedMeal, Array(selectedItems))
                        dismiss()
                    }
                    .buttonStyle(THButtonStyle(color: .thPrimary, isWide: true))
                    .disabled(selectedItems.isEmpty && capturedImage == nil)
                }
                .padding(20)
            }
            .navigationTitle("Log a Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(capturedImage: $capturedImage)
        }
    }
}

struct MealTypeChip: View {
    let meal: MealType
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: meal.icon)
                .font(.system(size: 13))
            Text(meal.displayName)
                .font(.thCaption)
                .fontWeight(.semibold)
        }
        .foregroundColor(isSelected ? .white : .thText)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isSelected ? Color.thPrimary : Color.thBackground)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.thPrimary : Color.thBorder))
    }
}

struct FoodChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(name)
                    .font(.thBody)
                    .foregroundColor(isSelected ? .white : .thText)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.thPrimary : Color.thBackground)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.thPrimary : Color.thBorder))
        }
    }
}

// MARK: - Camera View Wrapper

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
