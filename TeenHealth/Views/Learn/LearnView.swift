import SwiftUI

struct LearnView: View {
    @State private var selectedCategory: LearnCategory = .all
    @State private var bookmarkedIds: Set<String> = []
    @State private var selectedArticle: LearnArticle? = nil

    enum LearnCategory: String, CaseIterable {
        case all = "All"
        case nutrition = "Nutrition"
        case activity = "Activity"
        case sleep = "Sleep"
        case mentalHealth = "Wellbeing"
        case hydration = "Hydration"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .nutrition: return "leaf.fill"
            case .activity: return "figure.run"
            case .sleep: return "moon.zzz.fill"
            case .mentalHealth: return "heart.fill"
            case .hydration: return "drop.fill"
            }
        }

        var color: Color {
            switch self {
            case .all: return .thPrimary
            case .nutrition: return Color(hex: "#55EFC4")
            case .activity: return Color(hex: "#4ECDC4")
            case .sleep: return Color(hex: "#A29BFE")
            case .mentalHealth: return Color(hex: "#FF6B9D")
            case .hydration: return Color(hex: "#45B7D1")
            }
        }
    }

    var filteredArticles: [LearnArticle] {
        if selectedCategory == .all { return LearnContent.articles }
        return LearnContent.articles.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.thBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Category filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(LearnCategory.allCases, id: \.self) { cat in
                                    CategoryChip(
                                        category: cat,
                                        isSelected: selectedCategory == cat
                                    )
                                    .onTapGesture { selectedCategory = cat }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Featured article
                        if let featured = filteredArticles.first {
                            FeaturedArticleCard(article: featured, isBookmarked: bookmarkedIds.contains(featured.id)) {
                                selectedArticle = featured
                            } onBookmark: {
                                toggleBookmark(featured.id)
                            }
                            .padding(.horizontal, 20)
                        }

                        // Article grid
                        VStack(spacing: 12) {
                            ForEach(filteredArticles.dropFirst()) { article in
                                ArticleCard(article: article, isBookmarked: bookmarkedIds.contains(article.id)) {
                                    selectedArticle = article
                                } onBookmark: {
                                    toggleBookmark(article.id)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Wellbeing resources
                        wellbeingSection
                            .padding(.horizontal, 20)

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedArticle) { article in
                ArticleDetailView(article: article, isBookmarked: bookmarkedIds.contains(article.id)) {
                    toggleBookmark(article.id)
                }
            }
        }
    }

    private func toggleBookmark(_ id: String) {
        if bookmarkedIds.contains(id) { bookmarkedIds.remove(id) }
        else { bookmarkedIds.insert(id) }
    }

    private var wellbeingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Need Support?")
            VStack(spacing: 10) {
                WellbeingResourceRow(
                    icon: "phone.fill",
                    color: .thSuccess,
                    title: "Crisis Text Line",
                    subtitle: "Text HOME to 741741 (US) — free, 24/7",
                    action: {}
                )
                WellbeingResourceRow(
                    icon: "heart.circle.fill",
                    color: Color(hex: "#FF6B9D"),
                    title: "Talk to Your Coach",
                    subtitle: "Send a message in the Coach tab — they're here for you",
                    action: {}
                )
                WellbeingResourceRow(
                    icon: "person.2.fill",
                    color: .thPrimary,
                    title: "Tell a Trusted Adult",
                    subtitle: "A parent, school counselor, or doctor can help",
                    action: {}
                )
            }
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: LearnView.LearnCategory
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.system(size: 12))
            Text(category.rawValue)
                .font(.thCaption)
                .fontWeight(.semibold)
        }
        .foregroundColor(isSelected ? .white : .thText)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isSelected ? category.color : Color.thCard)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? category.color : Color.thBorder))
    }
}

// MARK: - Featured Article Card

struct FeaturedArticleCard: View {
    let article: LearnArticle
    let isBookmarked: Bool
    var onTap: () -> Void
    var onBookmark: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: [article.category.color, article.category.color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 140)
                        .overlay(
                            Image(systemName: article.category.icon)
                                .font(.system(size: 60, weight: .ultraLight))
                                .foregroundColor(.white.opacity(0.25))
                                .offset(x: 20, y: 10)
                        )
                    Button(action: onBookmark) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                            .padding(10)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(article.category.rawValue, systemImage: article.category.icon)
                            .font(.thCaption)
                            .foregroundColor(article.category.color)
                        Spacer()
                        Text(article.readTime)
                            .font(.thCaption)
                            .foregroundColor(.thSubtext)
                    }
                    Text(article.title)
                        .font(.thHeadline)
                        .foregroundColor(.thText)
                    Text(article.summary)
                        .font(.thBody)
                        .foregroundColor(.thSubtext)
                        .lineLimit(2)
                }
            }
        }
        .thCard()
    }
}

// MARK: - Article Card

struct ArticleCard: View {
    let article: LearnArticle
    let isBookmarked: Bool
    var onTap: () -> Void
    var onBookmark: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(article.category.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: article.category.icon)
                        .font(.system(size: 22))
                        .foregroundColor(article.category.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.thHeadline)
                        .foregroundColor(.thText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack {
                        Text(article.category.rawValue)
                            .font(.thCaption)
                            .foregroundColor(article.category.color)
                        Text("·")
                            .foregroundColor(.thSubtext)
                        Text(article.readTime)
                            .font(.thCaption)
                            .foregroundColor(.thSubtext)
                    }
                }
                Spacer()
                Button(action: onBookmark) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isBookmarked ? .thPrimary : .thBorder)
                        .font(.system(size: 16))
                }
            }
            .padding(14)
            .thCard()
        }
    }
}

// MARK: - Wellbeing Resource Row

struct WellbeingResourceRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: icon).foregroundColor(color).font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.thHeadline).foregroundColor(.thText)
                    Text(subtitle).font(.thCaption).foregroundColor(.thSubtext).lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.thBorder)
                    .font(.system(size: 13))
            }
            .padding(14)
            .thCard()
        }
    }
}

// MARK: - Article Detail View

struct ArticleDetailView: View {
    let article: LearnArticle
    let isBookmarked: Bool
    var onBookmark: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header image area
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [article.category.color, article.category.color.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(height: 180)
                            .overlay(
                                Image(systemName: article.category.icon)
                                    .font(.system(size: 80, weight: .ultraLight))
                                    .foregroundColor(.white.opacity(0.2))
                                    .offset(x: 30, y: 10)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Label(article.category.rawValue, systemImage: article.category.icon)
                                .font(.thCaption)
                                .foregroundColor(.white.opacity(0.9))
                            Text(article.title)
                                .font(.thTitle)
                                .foregroundColor(.white)
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 20)

                    // Meta
                    HStack {
                        Label(article.readTime, systemImage: "clock")
                            .font(.thCaption)
                            .foregroundColor(.thSubtext)
                        Spacer()
                        Text("Non-judgmental · Evidence-based")
                            .font(.thCaption)
                            .foregroundColor(.thSubtext)
                    }
                    .padding(.horizontal, 20)

                    // Summary
                    Text(article.summary)
                        .font(.thBody)
                        .foregroundColor(.thSubtext)
                        .padding(.horizontal, 20)

                    Divider().padding(.horizontal, 20)

                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(article.sections) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.heading)
                                    .font(.thHeadline)
                                    .foregroundColor(.thText)
                                Text(section.body)
                                    .font(.thBody)
                                    .foregroundColor(.thText)
                                    .lineSpacing(4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Key takeaway
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.thGold)
                        Text(article.keyTakeaway)
                            .font(.thBody)
                            .foregroundColor(.thText)
                            .italic()
                    }
                    .padding(16)
                    .background(Color.thGold.opacity(0.1))
                    .cornerRadius(14)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onBookmark) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? .thPrimary : .thText)
                    }
                }
            }
        }
    }
}

// MARK: - Learn Content Data

struct LearnArticle: Identifiable {
    let id: String
    let title: String
    let category: LearnView.LearnCategory
    let summary: String
    let readTime: String
    let sections: [ArticleSection]
    let keyTakeaway: String
}

struct ArticleSection: Identifiable {
    let id = UUID()
    let heading: String
    let body: String
}

enum LearnContent {
    static let articles: [LearnArticle] = [
        LearnArticle(
            id: "nutrition_1",
            title: "Why Food Logging Actually Works",
            category: .nutrition,
            summary: "Research shows that simply paying attention to what you eat — without restriction — is one of the most powerful tools for building healthier habits.",
            readTime: "3 min",
            sections: [
                ArticleSection(heading: "The science behind it",
                    body: "Multiple clinical trials have found that people who track their meals, even casually, tend to make more balanced choices — not because they're counting calories, but because the act of logging creates awareness. You start noticing patterns you never saw before."),
                ArticleSection(heading: "It's not about restriction",
                    body: "Food logging in TeenHealth is never about limiting what you eat. It's about building a picture of your day. Did you have breakfast? Did you drink enough water? These patterns matter more than any single meal."),
                ArticleSection(heading: "How to make it stick",
                    body: "Log quickly. A photo works just as well as a detailed breakdown. The goal is consistency over completeness. Three taps to log a meal — that's all it takes.")
            ],
            keyTakeaway: "Logging what you eat — even imperfectly — is the single most research-backed habit you can build."
        ),
        LearnArticle(
            id: "activity_1",
            title: "Movement That Actually Fits Your Life",
            category: .activity,
            summary: "You don't need a gym membership or intense workouts. Research shows that everyday movement adds up to big health benefits over time.",
            readTime: "3 min",
            sections: [
                ArticleSection(heading: "Any movement counts",
                    body: "Walking to school, dancing in your room, shooting hoops, taking the stairs — all of it counts. The WHO recommends 60 minutes of movement per day for teens, but any amount is better than none."),
                ArticleSection(heading: "Steps are a great starting point",
                    body: "Your TeenHealth app tracks steps automatically. A goal of 5,000–8,000 steps per day is realistic for most teens and linked to meaningful health benefits in research."),
                ArticleSection(heading: "Find what you enjoy",
                    body: "The best workout is the one you'll actually do. If you hate running, don't run. Try swimming, biking, team sports, yoga, or even long walks with music. Enjoyment drives consistency.")
            ],
            keyTakeaway: "Find movement you enjoy. Consistency over intensity — always."
        ),
        LearnArticle(
            id: "sleep_1",
            title: "Sleep: The Habit You Might Be Ignoring",
            category: .sleep,
            summary: "Sleep affects your weight, mood, energy, and hunger hormones more than almost any other lifestyle factor.",
            readTime: "4 min",
            sections: [
                ArticleSection(heading: "Why sleep and weight are connected",
                    body: "When you don't get enough sleep, your body produces more ghrelin (the hunger hormone) and less leptin (the fullness hormone). This means you feel hungrier than usual — especially for high-calorie foods. It's biology, not willpower."),
                ArticleSection(heading: "How much do teens need?",
                    body: "The American Academy of Sleep Medicine recommends 8–10 hours per night for teens aged 13–18. Most teens get 6–7 hours. Even one extra hour can meaningfully improve energy, focus, and mood."),
                ArticleSection(heading: "Simple sleep habits",
                    body: "Try consistent bedtimes, reducing screen time 30 min before bed (blue light delays your sleep signal), keeping your room cool and dark, and avoiding caffeine after 3 PM.")
            ],
            keyTakeaway: "Getting enough sleep helps regulate hunger and energy — it's one of the most underrated health habits."
        ),
        LearnArticle(
            id: "hydration_1",
            title: "Water: The Simplest Health Habit",
            category: .hydration,
            summary: "Many teens mistake thirst for hunger. Staying hydrated improves energy, focus, and can reduce unnecessary snacking.",
            readTime: "2 min",
            sections: [
                ArticleSection(heading: "How much water do you need?",
                    body: "Most teens need 6–8 cups (1.5–2 liters) of water per day, more if you're active or it's hot. Aim to have a drink with every meal and sip throughout the day."),
                ArticleSection(heading: "Thirst vs. hunger",
                    body: "Your body uses the same signal for mild dehydration as it does for hunger. Before reaching for a snack, try drinking a glass of water and waiting 10 minutes."),
                ArticleSection(heading: "Making it easier",
                    body: "Keep a water bottle with you. Track glasses in the app. Flavor it with lemon, mint, or berries if plain water is boring. Replace one sugary drink per day with water for a simple, high-impact habit.")
            ],
            keyTakeaway: "Drink water before you feel thirsty — by then, you're already mildly dehydrated."
        ),
        LearnArticle(
            id: "mental_1",
            title: "Your Mindset Is Part of Your Health",
            category: .mentalHealth,
            summary: "Stress, emotions, and mental health deeply affect eating habits and activity. This app is designed to support your whole self — not just your body.",
            readTime: "4 min",
            sections: [
                ArticleSection(heading: "Emotional eating is normal",
                    body: "Eating for comfort, stress, or boredom happens to almost everyone. The goal isn't to stop it completely but to notice it, without judgment. Awareness is the first step."),
                ArticleSection(heading: "Body image and self-respect",
                    body: "TeenHealth never weighs your worth by your weight. Your value isn't determined by a number on a scale. This app is about building habits that make you feel good — energy, focus, strength — not about reaching a specific body shape."),
                ArticleSection(heading: "When to seek support",
                    body: "If you're feeling hopeless, having thoughts of self-harm, or feeling out of control around food, please reach out to a trusted adult, your coach, or a crisis resource. You don't have to handle this alone.")
            ],
            keyTakeaway: "Your mental health matters as much as your physical health. Be kind to yourself."
        ),
        LearnArticle(
            id: "nutrition_2",
            title: "Swapping, Not Restricting",
            category: .nutrition,
            summary: "Small substitutions can make a big difference without making you feel deprived. Here are research-backed swaps that actually work.",
            readTime: "3 min",
            sections: [
                ArticleSection(heading: "The swap approach",
                    body: "Instead of cutting foods out, try replacing one item at a time. Swap one sugary drink for water. Add a vegetable to a meal you already love. Choose fruit instead of a packaged snack sometimes. Small steps, big impact over time."),
                ArticleSection(heading: "High-impact swaps",
                    body: "Sugary drinks → water or sparkling water. White bread → whole wheat. Chips → nuts or fruit. Processed snacks → yogurt or hummus. These aren't rules — they're options when you want them."),
                ArticleSection(heading: "No food is off-limits",
                    body: "Labeling foods as 'good' or 'bad' can create unhealthy relationships with eating. All foods can fit into a healthy lifestyle. The goal is overall patterns, not perfection at every meal.")
            ],
            keyTakeaway: "Add and swap — don't restrict. Progress beats perfection every time."
        )
    ]
}
