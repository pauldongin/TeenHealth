import Foundation

// MARK: - Protocol

protocol CoachServiceProtocol: AnyObject {
    func fetchMessages(threadId: UUID) async -> [Message]
    func sendMessage(_ body: String, threadId: UUID, senderId: UUID, senderName: String) async throws -> Message
    func markAsRead(messageId: UUID, in messages: inout [Message]) async
}

// MARK: - Mock Coach Service

final class MockCoachService: CoachServiceProtocol {
    static let coachId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let coachName = "Coach Alex"

    private let welcomeMessages: [String] = [
        "Hey! Welcome to TeenHealth. I'm Coach Alex and I'm here to support you every step of the way. How are you feeling today? 😊",
        "Great to have you here! Let's start by getting to know each other. What's one healthy habit you already have?",
        "I checked your goals — they look solid! Remember, small consistent steps are way more powerful than big changes that don't stick. You've got this! 💪"
    ]

    private let checkInMessages: [String] = [
        "Hey, just checking in! How did your meals go today?",
        "How are you feeling after this week? Any wins you want to share?",
        "I noticed you hit your step goal yesterday — amazing! How's your energy been?",
        "Have you been sleeping well? Sleep is a huge part of staying healthy and energized.",
        "Any challenges this week? It's totally normal to have off days — let's talk through it.",
        "What's been the easiest part of your health journey lately?",
        "Remember: it's not about being perfect, it's about building a lifestyle you enjoy 🌟"
    ]

    private let responseMessages: [String] = [
        "That's really great to hear! Keep it up!",
        "I hear you — that sounds challenging. Let's think of some strategies together.",
        "Thanks for sharing that with me! How can I support you better?",
        "That's a really important insight. Have you noticed any patterns?",
        "Awesome! Small wins add up to big changes over time. 🌱",
        "I appreciate your honesty. Remember, this journey is about progress, not perfection.",
        "Great question! Let's talk about that. What feels most manageable for you right now?"
    ]

    func fetchMessages(threadId: UUID) async -> [Message] {
        try? await Task.sleep(nanoseconds: 600_000_000)
        let now = Date()
        var msgs: [Message] = []

        // Welcome message from 3 days ago
        for (i, text) in welcomeMessages.enumerated() {
            let msg = Message(
                id: UUID(),
                threadId: threadId,
                senderId: MockCoachService.coachId,
                senderName: MockCoachService.coachName,
                body: text,
                isFromCoach: true
            )
            // Backdate
            let dayOffset = -(welcomeMessages.count - i)
            msg.sentAt = Calendar.current.date(byAdding: .day, value: dayOffset, to: now) ?? now
            msg.readAt = msg.sentAt
            msgs.append(msg)
        }

        // Recent check-in
        let checkIn = Message(
            id: UUID(),
            threadId: threadId,
            senderId: MockCoachService.coachId,
            senderName: MockCoachService.coachName,
            body: checkInMessages.randomElement()!,
            isFromCoach: true
        )
        checkIn.sentAt = Calendar.current.date(byAdding: .hour, value: -2, to: now) ?? now
        msgs.append(checkIn)

        return msgs.sorted { $0.sentAt < $1.sentAt }
    }

    func sendMessage(_ body: String, threadId: UUID, senderId: UUID, senderName: String) async throws -> Message {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)

        let msg = Message(
            id: UUID(),
            threadId: threadId,
            senderId: senderId,
            senderName: senderName,
            body: body,
            isFromCoach: false
        )
        msg.sentAt = Date()

        // Simulate coach auto-reply after delay (in real app this would come via push)
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            // In a real app, this would trigger a push notification
        }

        return msg
    }

    func getCoachReply(threadId: UUID) -> Message {
        let reply = Message(
            id: UUID(),
            threadId: threadId,
            senderId: MockCoachService.coachId,
            senderName: MockCoachService.coachName,
            body: responseMessages.randomElement()!,
            isFromCoach: true
        )
        reply.sentAt = Date()
        return reply
    }

    func markAsRead(messageId: UUID, in messages: inout [Message]) async {
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            messages[idx].readAt = Date()
        }
    }
}
