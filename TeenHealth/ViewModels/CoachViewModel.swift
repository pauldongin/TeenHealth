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

    private let coachService: MockCoachContentProvider
    private let rewardEngine: RewardEngine

    init(
        coachService: MockCoachContentProvider = MockCoachContentProvider(),
        rewardEngine: RewardEngine = RewardEngine()
    ) {
        self.coachService = coachService
        self.rewardEngine = rewardEngine
    }

    func loadMessages(user: AppUser, context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        if user.messages.isEmpty {
            let mockBodies = await coachService.fetchMessageBodies(threadId: threadId)

            for body in mockBodies {
                let msg = Message(
                    threadId: threadId,
                    senderId: UUID(),
                    senderName: "Coach",
                    body: body,
                    isFromCoach: true
                )

                context.insert(msg)
                user.messages.append(msg)
            }
        }

        refreshMessages(from: user)
    }

    func sendMessage(user: AppUser, context: ModelContext) async {
        let body = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        messageText = ""

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

        coachIsTyping = true
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        coachIsTyping = false

        let replyBody = coachService.getCoachReplyBody(threadId: threadId)

        let coachReply = Message(
            threadId: threadId,
            senderId: UUID(),
            senderName: "Coach",
            body: replyBody,
            isFromCoach: true
        )

        context.insert(coachReply)
        user.messages.append(coachReply)
        refreshMessages(from: user)
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

struct MockCoachContentProvider {
    func fetchMessageBodies(threadId: UUID) async -> [String] {
        try? await Task.sleep(nanoseconds: 500_000_000)

        return [
            "Welcome! I’m your teen health coach.",
            "Pick one small goal for today.",
            "Logging a meal, taking a walk, or swapping one drink all count."
        ]
    }

    func getCoachReplyBody(threadId: UUID) -> String {
        return "Nice check-in. Keep today focused on one small win."
    }
}
