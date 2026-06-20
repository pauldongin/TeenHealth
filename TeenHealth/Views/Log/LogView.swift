import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [AppUser]
    @StateObject private var vm = LogViewModel()
    @State private var showAddLog = false
    @State private var selectedLog: FoodLog? = nil
    @State private var showToast = false
    @State private var toastMessage = ""

    var user: AppUser? { users.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.thBackground.ignoresSafeArea()

                if let user {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            streakHeader(user: user)
                            todaySection(user: user)
                            if !vm.favoriteLogs.isEmpty {
                                favoriteSection(user: user)
                            }
                            Spacer(minLength: 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Food Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddLog = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.thPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddLog) {
                if let user {
                    AddLogView(user: user) { mealType, items, photo, note in
                        if let image = photo {
                            vm.photoLog(mealType: mealType, image: image, note: note, user: user, context: context)
                        } else {
                            vm.quickLog(mealType: mealType, items: items, user: user, context: context)
                        }
                        showToastMsg(vm.logSuccessMessage)
                    }
                }
            }
            .overlay(alignment: .top) {
                if showToast {
                    ToastView(message: toastMessage, icon: "star.fill", color: .thGold)
                        .padding(.top, 100)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .onAppear {
                if let user { vm.refreshLogs(user: user) }
            }
            .onChange(of: showAddLog) { _, new in
                if !new, let user { vm.refreshLogs(user: user) }
            }
        }
    }

    // MARK: - Streak Header

    private func streakHeader(user: AppUser) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.thCaption)
                    .foregroundColor(.thSubtext)
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.thEnergy)
                        .font(.system(size: 22, weight: .bold))
                    Text("\(user.currentStreak) days")
                        .font(.thTitle)
                        .foregroundColor(.thText)
                }
            }
            Spacer()
            weekDotRow(user: user)
        }
        .padding(16)
        .thCard()
    }

    private func weekDotRow(user: AppUser) -> some View {
        let calendar = Calendar.current
        struct DayDot: Identifiable {
            let id: Int
            let label: String
            let logged: Bool
        }
        let days: [DayDot] = (0..<7).reversed().enumerated().map { idx, offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let label = String(calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1].prefix(1).uppercased())
            let logged = user.foodLogs.contains { calendar.isDate($0.timestamp, inSameDayAs: date) }
            return DayDot(id: idx, label: label, logged: logged)
        }
        return HStack(spacing: 6) {
            ForEach(days) { dot in
                VStack(spacing: 4) {
                    Circle()
                        .fill(dot.logged ? Color.thEnergy : Color.thBorder)
                        .frame(width: 10, height: 10)
                    Text(dot.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.thSubtext)
                }
            }
        }
    }

    // MARK: - Today Section

    private func todaySection(user: AppUser) -> some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Today")
            if vm.todayLogs.isEmpty {
                EmptyStateView(
                    icon: "fork.knife.circle",
                    title: "Nothing logged yet",
                    message: "Tap + to record your first meal of the day",
                    buttonTitle: "Log a Meal"
                ) {
                    showAddLog = true
                }
                .thCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(vm.todayLogs) { log in
                        DetailedLogRow(log: log) {
                            vm.repeatLog(log, user: user, context: context)
                            showToastMsg("Logged again! +10 points")
                        } onDelete: {
                            vm.deleteLog(log, user: user, context: context)
                        } onFavorite: {
                            vm.toggleFavorite(log)
                        }
                        if log.id != vm.todayLogs.last?.id {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
                .thCard()
            }
        }
    }

    // MARK: - Favorites Section

    private func favoriteSection(user: AppUser) -> some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Favorites")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.favoriteLogs.prefix(5)) { log in
                        FavoriteLogCard(log: log) {
                            vm.repeatLog(log, user: user, context: context)
                            showToastMsg("Logged again! +10 points")
                        }
                    }
                }
            }
        }
    }

    private func showToastMsg(_ message: String) {
        toastMessage = message
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
    }
}

// MARK: - Detailed Log Row

struct DetailedLogRow: View {
    let log: FoodLog
    var onRepeat: () -> Void
    var onDelete: () -> Void
    var onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Meal icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.thPrimary.opacity(0.1))
                    .frame(width: 44, height: 44)
                if let path = log.photoPath, let img = UIImage(contentsOfFile: path) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    Image(systemName: log.mealType.icon)
                        .foregroundColor(.thPrimary)
                        .font(.system(size: 18))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(log.mealType.displayName)
                        .font(.thHeadline)
                        .foregroundColor(.thText)
                    if log.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.system(size: 10))
                    }
                }
                if !log.displayItems.isEmpty {
                    Text(log.displayItems)
                        .font(.thCaption)
                        .foregroundColor(.thSubtext)
                        .lineLimit(1)
                }
                if let note = log.note, !note.isEmpty {
                    Text(note)
                        .font(.thCaption)
                        .foregroundColor(.thSubtext)
                        .italic()
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(log.timestamp, format: .dateTime.hour().minute())
                    .font(.thCaption)
                    .foregroundColor(.thSubtext)
                HStack(spacing: 8) {
                    Button(action: onRepeat) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                            .foregroundColor(.thAccent)
                    }
                    Button(action: onFavorite) {
                        Image(systemName: log.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 13))
                            .foregroundColor(.pink)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Favorite Log Card

struct FavoriteLogCard: View {
    let log: FoodLog
    let onRepeat: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let path = log.photoPath, let img = UIImage(contentsOfFile: path) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 130, height: 80)
                    .clipped()
                    .cornerRadius(10)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.thPrimary.opacity(0.1))
                        .frame(width: 130, height: 80)
                    Image(systemName: log.mealType.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.thPrimary)
                }
            }
            Text(log.mealType.displayName)
                .font(.thCaption)
                .fontWeight(.semibold)
                .foregroundColor(.thText)
            if !log.displayItems.isEmpty {
                Text(log.displayItems)
                    .font(.system(size: 10))
                    .foregroundColor(.thSubtext)
                    .lineLimit(1)
            }
            Button(action: onRepeat) {
                Label("Log again", systemImage: "arrow.clockwise")
                    .font(.thCaption)
                    .foregroundColor(.thPrimary)
            }
        }
        .frame(width: 130)
        .padding(12)
        .thCard()
    }
}

// MARK: - Add Log View

struct AddLogView: View {
    let user: AppUser
    let onSave: (MealType, [String], UIImage?, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeal: MealType = .snack
    @State private var logMethod: LogMethod = .quickPick
    @State private var selectedItems: Set<String> = []
    @State private var searchText = ""
    @State private var searchResults: [String] = []
    @State private var capturedImage: UIImage? = nil
    @State private var showCamera = false
    @State private var note = ""

    enum LogMethod: String, CaseIterable {
        case photo = "Photo"
        case quickPick = "Quick Pick"
        case search = "Search"
    }

    private let foodDatabase: [String] = [
        "Apple", "Banana", "Orange", "Grapes", "Strawberries",
        "Chicken breast", "Salmon", "Tuna", "Eggs", "Greek yogurt",
        "Brown rice", "Quinoa", "Oatmeal", "Whole wheat bread", "Sweet potato",
        "Broccoli", "Spinach", "Carrot", "Tomato", "Avocado",
        "Almonds", "Walnuts", "Peanut butter", "Hummus",
        "Milk", "Cheese", "Tofu", "Lentils", "Black beans",
        "Mixed salad", "Veggie wrap", "Chicken sandwich", "Fruit smoothie",
        "Pasta", "Pizza", "Burger", "Fries", "Rice and beans"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Meal type
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(MealType.allCases, id: \.self) { meal in
                                MealTypeChip(meal: meal, isSelected: selectedMeal == meal)
                                    .onTapGesture { selectedMeal = meal }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Method picker
                    Picker("Method", selection: $logMethod) {
                        ForEach(LogMethod.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    Group {
                        switch logMethod {
                        case .photo:     photoContent
                        case .quickPick: quickPickContent
                        case .search:    searchContent
                        }
                    }
                    .padding(.horizontal, 20)

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)").font(.thHeadline)
                        TextField("How was this meal? Any notes?", text: $note, axis: .vertical)
                            .lineLimit(2...4)
                            .font(.thBody)
                            .padding()
                            .background(Color.thBackground)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)

                    Button("Save Log") {
                        onSave(selectedMeal, Array(selectedItems), capturedImage, note)
                        dismiss()
                    }
                    .buttonStyle(THButtonStyle(color: .thPrimary, isWide: true))
                    .padding(.horizontal, 20)
                    .disabled(selectedItems.isEmpty && capturedImage == nil)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Log a Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var photoContent: some View {
        VStack(spacing: 12) {
            if let img = capturedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(14)
                    .overlay(alignment: .topTrailing) {
                        Button { capturedImage = nil } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .padding(8)
                    }
            }
            Button {
                showCamera = true
            } label: {
                Label(capturedImage == nil ? "Take Photo" : "Retake Photo", systemImage: "camera.fill")
                    .font(.thHeadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.thEnergy)
                    .cornerRadius(14)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(capturedImage: $capturedImage)
        }
    }

    private var quickPickContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select foods").font(.thHeadline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(foodDatabase.prefix(20), id: \.self) { item in
                    FoodChip(name: item, isSelected: selectedItems.contains(item)) {
                        if selectedItems.contains(item) { selectedItems.remove(item) }
                        else { selectedItems.insert(item) }
                    }
                }
            }
        }
    }

    private var searchContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Search foods...", text: $searchText)
                .font(.thBody)
                .padding()
                .background(Color.thBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.thBorder))
                .onChange(of: searchText) { _, new in
                    searchResults = new.isEmpty
                        ? Array(foodDatabase.prefix(8))
                        : foodDatabase.filter { $0.lowercased().contains(new.lowercased()) }
                }
                .onAppear {
                    searchResults = Array(foodDatabase.prefix(8))
                }

            ForEach(searchResults, id: \.self) { item in
                HStack {
                    Text(item).font(.thBody).foregroundColor(.thText)
                    Spacer()
                    if selectedItems.contains(item) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.thPrimary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.thBackground)
                .cornerRadius(10)
                .onTapGesture {
                    if selectedItems.contains(item) { selectedItems.remove(item) }
                    else { selectedItems.insert(item) }
                }
                Divider()
            }
        }
    }
}
