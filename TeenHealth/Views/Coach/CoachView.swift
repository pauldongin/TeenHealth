import SwiftUI
import SwiftData
import UIKit

// Globally force-dismiss the keyboard — works no matter which view holds focus
private func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil, from: nil, for: nil
    )
}

struct CoachView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [AppUser]
    @StateObject private var vm = CoachViewModel()
    @FocusState private var inputFocused: Bool

    var user: AppUser? { users.first }

    var body: some View {
        NavigationStack {
            ZStack {
                // Invisible full-screen tap target — dismisses keyboard on any tap outside input
                Color.thBackground
                    .ignoresSafeArea(.all)
                    .contentShape(Rectangle())
                    .onTapGesture { dismissKeyboard() }

                if let user {
                    VStack(spacing: 0) {
                        coachHeader
                        Divider()
                        messagesScrollView
                        Divider()
                        inputBar(user: user)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Coach")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if let user {
                    await vm.loadMessages(user: user, context: context)
                    vm.markAllRead(user: user)
                }
            }
        }
    }

    // MARK: - Coach Header

    private var coachHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.thPrimary, .thAccent], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                Text("AC")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.thSuccess)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Coach Alex")
                    .font(.thHeadline)
                    .foregroundColor(.thText)
                Text("Your personal health coach")
                    .font(.thCaption)
                    .foregroundColor(.thSubtext)
            }
            Spacer()
            VStack(spacing: 2) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 14))
                    .foregroundColor(.thSuccess)
                Text("Secure")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.thSuccess)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.thCard)
    }

    // MARK: - Messages

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if vm.isLoading {
                        ProgressView().padding(40)
                    } else if vm.messages.isEmpty {
                        Text("No messages yet. Say hello to your coach!")
                            .font(.thBody)
                            .foregroundColor(.thSubtext)
                            .padding(40)
                    } else {
                        ForEach(vm.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if vm.coachIsTyping {
                            TypingIndicator()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            // Swipe down on messages to dismiss keyboard
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: vm.messages.count) { _, _ in
                if let last = vm.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: vm.coachIsTyping) { _, _ in
                withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
            }
        }
    }

    // MARK: - Input Bar

    private func inputBar(user: AppUser) -> some View {
        HStack(spacing: 12) {
            TextField("Message your coach...", text: $vm.messageText, axis: .vertical)
                .lineLimit(1...4)
                .font(.thBody)
                .focused($inputFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(22)
                .submitLabel(.send)
                .onSubmit {
                    Task { await vm.sendMessage(user: user, context: context) }
                }
                // ✅ "Done" button appears above keyboard — most reliable dismiss
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            dismissKeyboard()
                            inputFocused = false
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.thPrimary)
                    }
                }

            Button {
                Task { await vm.sendMessage(user: user, context: context) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(
                        vm.messageText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? .thBorder : .thPrimary
                    )
            }
            .disabled(vm.messageText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemBackground))
        .safeAreaPadding(.bottom)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message

    var isFromCoach: Bool { message.isFromCoach }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCoach {
                coachAvatar
            } else {
                Spacer(minLength: 60)
            }

            VStack(alignment: isFromCoach ? .leading : .trailing, spacing: 4) {
                if isFromCoach {
                    Text("Coach Alex")
                        .font(.thCaption)
                        .foregroundColor(.thSubtext)
                }
                Text(message.body)
                    .font(.thBody)
                    .foregroundColor(isFromCoach ? .thText : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromCoach ? Color.thCard : Color.thPrimary)
                    .cornerRadius(18, corners: isFromCoach
                        ? [.topLeft, .topRight, .bottomRight]
                        : [.topLeft, .topRight, .bottomLeft])
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 1)

                Text(message.sentAt, format: .dateTime.hour().minute())
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.thSubtext)
            }

            if !isFromCoach {
                userAvatar
            } else {
                Spacer(minLength: 60)
            }
        }
    }

    private var coachAvatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.thPrimary, .thAccent], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 28, height: 28)
            Text("AC")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var userAvatar: some View {
        Circle()
            .fill(Color.thEnergy.opacity(0.2))
            .frame(width: 28, height: 28)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.thEnergy)
            )
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.thPrimary, .thAccent], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Text("AC")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
            }
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.thSubtext)
                        .frame(width: 7, height: 7)
                        .offset(y: animate ? -4 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: animate)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.thCard)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
            Spacer()
        }
        .id("typing")
        .onAppear { animate = true }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
