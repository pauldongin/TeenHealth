import Foundation
import SwiftData
import Combine

@MainActor
final class CoachViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText: String = ""
    @Published var isLoading: Bool = false
    @Published var threadId: UUID = UUID()
    @Published var coachIsTyping: Bool = false
    @Published var unreadCount: Int = 0
    @Published var errorMessage: String? = nil

    private let groq = GroqCoachService()
    private let rewardEngine: RewardEngine

    init(rewardEngine: RewardEngine = RewardEngine()) {
        self.rewardEngine = rewardEngine
    }

    func loadMessages(user: AppUser, context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        // First launch: send a personalised greeting via AI
        if user.messages.isEmpty {
            let greeting = "Hey \(user.displayName.capitalized)! I'm Coach Alex 👋 I'm here to help you build healthy habits at your own pace. What's one thing you want to work on this week?"
            let msg = Message(
                threadId: threadId,
                senderId: UUID(),
                senderName: "Coach Alex",
                body: greeting,
                isFromCoach: true
            )
            context.insert(msg)
            user.messages.append(msg)
        }

        refreshMessages(from: user)
    }

    func sendMessage(user: AppUser, context: ModelContext) async {
        let body = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        messageText = ""
        errorMessage = nil

        // Save user message
        let userMessage = Message(
            threadId: threadId,
            senderId: user.id,
            senderName: user.displayName,
            body: body,
            isFromCoach: false
        )
        context.insert(userMessage)
        user.messages.append(userMessage)
        refreshMessages(from: user)

        if user.messages.filter({ !$0.isFromCoach }).count == 1 {
            _ = rewardEngine.checkAndAwardBadges(for: user, context: context)
        }

        // Show typing indicator while waiting for Groq
        coachIsTyping = true

        do {
            let replyText = try await groq.reply(to: body, history: messages)
            coachIsTyping = false

            let coachReply = Message(
                threadId: threadId,
                senderId: UUID(),
                senderName: "Coach Alex",
                body: replyText,
                isFromCoach: true
            )
            context.insert(coachReply)
            user.messages.append(coachReply)
            refreshMessages(from: user)
        } catch {
            coachIsTyping = false
            // Fallback message if API fails
            let fallback = Message(
                threadId: threadId,
                senderId: UUID(),
                senderName: "Coach Alex",
                body: "Sorry, I'm having trouble connecting right now. Try again in a moment! 😊",
                isFromCoach: true
            )
            context.insert(fallback)
            user.messages.append(fallback)
            refreshMessages(from: user)
        }
    }

    func markAllRead(user: AppUser) {
        let now = Date()

        for msg in user.messages where msg.isFromCoach && msg.readAt == nil {
            msg.readAt = now
        }

        refreshMessages(from: user)
    }

    private func refreshMessages(from user: AppUser) {
        messages = user.messages.sorted { $0.sentAt < $1.sentAt }
        unreadCount = messages.filter { $0.isFromCoach && $0.readAt == nil }.count
    }
}

