import SwiftUI

// MARK: - TypingIndicatorView

/// Animated "typing..." bubble shown when the partner is composing a message.
/// Three dots bounce in sequence (iMessage / WhatsApp style).
struct TypingIndicatorView: View {
    let partnerName: String
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(MatchaTokens.Colors.textSecondary)
                        .frame(width: 6, height: 6)
                        .offset(y: animationPhase == index ? -4 : 0)
                        .animation(
                            .easeInOut(duration: 0.35)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(MatchaTokens.Colors.surface, in: BubbleShape())
            .overlay(
                BubbleShape()
                    .strokeBorder(MatchaTokens.Colors.outline.opacity(0.5), lineWidth: 0.5)
            )

            Text("\(partnerName) is typing")
                .font(.caption2.weight(.medium))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, 4)
        .onAppear { animationPhase = 2 }
        .accessibilityLabel("\(partnerName) is typing a message")
    }
}

// MARK: - Bubble Shape

private struct BubbleShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return RoundedRectangle(cornerRadius: 16, style: .continuous)
            .path(in: insetRect)
    }

    func inset(by amount: CGFloat) -> BubbleShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

// MARK: - TypingStateManager

/// Lightweight polling-based typing indicator.
/// Sends typing events when the local user types, polls for partner typing state.
@MainActor
@Observable
final class TypingStateManager {
    var isPartnerTyping = false

    private let chatId: String
    private var sendTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    private var lastTypingSent: Date = .distantPast

    init(chatId: String) {
        self.chatId = chatId
    }

    /// Call when user types a character. Debounces to avoid spamming the API.
    func localUserTyped() {
        guard !chatId.isEmpty else { return }
        let now = Date()
        guard now.timeIntervalSince(lastTypingSent) > 3 else { return }
        lastTypingSent = now

        sendTask?.cancel()
        sendTask = Task {
            try? await NetworkService.shared.requestVoid(
                .POST, path: "/chats/\(chatId)/typing"
            )
        }
    }

    /// Start polling partner typing state. Call on appear.
    func startPolling() {
        guard !chatId.isEmpty else { return }
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollOnce()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    /// Stop polling. Call on disappear.
    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
        isPartnerTyping = false
    }

    private func pollOnce() async {
        guard !chatId.isEmpty else { return }
        do {
            let response: TypingStatusResponse = try await NetworkService.shared.request(
                .GET, path: "/chats/\(chatId)/typing"
            )
            isPartnerTyping = response.isTyping
        } catch {
            isPartnerTyping = false
        }
    }
}

private struct TypingStatusResponse: Decodable {
    let isTyping: Bool
}
