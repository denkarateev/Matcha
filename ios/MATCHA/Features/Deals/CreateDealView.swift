import SwiftUI

// MARK: - CreateDealView

struct CreateDealView: View {
    let partnerName: String
    let partnerId: String
    let repository: any MatchaRepository
    var onSend: @MainActor () async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var dealType: DealType = .barter
    @State private var youOffer: String = ""
    @State private var youReceive: String = ""
    @State private var showTemplates = true

    private struct DealTemplate: Identifiable {
        let id = UUID()
        let emoji: String
        let title: String
        let offer: String
        let receive: String
    }

    // Role-based templates
    private var templates: [DealTemplate] {
        // TODO: detect role from AppState; for now show both
        return [
            DealTemplate(emoji: "🍽", title: "Dinner collab", offer: "Dinner for 2 + drinks", receive: "1 Reel + 3 Stories"),
            DealTemplate(emoji: "🏨", title: "Hotel stay", offer: "2-night stay + spa", receive: "Video review + 5 Stories"),
            DealTemplate(emoji: "☕️", title: "Cafe visit", offer: "Brunch for 2", receive: "3 Stories + 1 post"),
            DealTemplate(emoji: "🎉", title: "Event coverage", offer: "VIP pass + table", receive: "Live Stories + Reel"),
            DealTemplate(emoji: "💆", title: "Spa experience", offer: "Full spa day", receive: "1 Reel + review"),
        ]
    }
    @State private var placeName: String = ""
    @State private var guests: DealGuests = .solo
    @State private var scheduledDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var hasDate = false
    @State private var hasContentDeadline = false
    @State private var contentDeadline: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isSending = false
    @State private var apiError: String?
    @FocusState private var focused: Field?

    private enum Field: Hashable { case offer, receive, place }

    private var isValid: Bool {
        !youOffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Partner header
                    partnerHeader

                    // Quick templates
                    if showTemplates && youOffer.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Quick start")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(MatchaTokens.Colors.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(templates) { tpl in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                youOffer = tpl.offer
                                                youReceive = tpl.receive
                                                showTemplates = false
                                            }
                                        } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(tpl.emoji)
                                                    .font(.title3)
                                                Text(tpl.title)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                                                Text(tpl.offer)
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 110)
                                            .padding(10)
                                            .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 0.5)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    // Type
                    typeRow

                    // You offer
                    fieldSection(title: "You offer", placeholder: "e.g. Dinner for 2 + sunset table", text: $youOffer, field: .offer)

                    // You receive
                    fieldSection(title: "You receive", placeholder: "e.g. 1 Reel + 3 Stories, tagged", text: $youReceive, field: .receive)

                    // Place
                    fieldSection(title: "Place", placeholder: "Canggu Beach Club, lobby...", text: $placeName, field: .place, optional: true)

                    // Guests
                    guestsRow

                    // Date toggle + picker
                    dateRow

                    // Content deadline
                    if hasDate {
                        deadlineRow
                    }

                    // Error
                    if let apiError {
                        Text(apiError)
                            .font(.system(size: 13))
                            .foregroundStyle(MatchaTokens.Colors.danger)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(MatchaTokens.Colors.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Send
                    sendButton

                    Color.clear.frame(height: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(MatchaTokens.Colors.background.ignoresSafeArea())
            .navigationTitle("New Deal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }

    // MARK: - Partner Header

    private var partnerHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MatchaTokens.Colors.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(MatchaTokens.Colors.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Deal with \(partnerName)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Fill in the terms — they'll review and accept")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        }
    }

    // MARK: - Type Row

    private var typeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Type")

            HStack(spacing: 10) {
                ForEach(DealType.allCases, id: \.self) { type in
                    let selected = dealType == type
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { dealType = type }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type == .barter ? "arrow.left.arrow.right" : "banknote")
                                .font(.system(size: 13, weight: .semibold))
                            Text(type.title)
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(selected ? .black : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            selected ? MatchaTokens.Colors.accent : Color.white.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Text Field Section

    private func fieldSection(title: String, placeholder: String, text: Binding<String>, field: Field, optional: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel(title)
                if optional {
                    Text("Optional")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.2))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }

                TextEditor(text: text)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .focused($focused, equals: field)
                    .frame(minHeight: 60, maxHeight: 100)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .onChange(of: text.wrappedValue) { _, val in
                        if val.count > 200 { text.wrappedValue = String(val.prefix(200)) }
                    }
            }
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        focused == field ? MatchaTokens.Colors.accent.opacity(0.4) : Color.white.opacity(0.08),
                        lineWidth: 0.5
                    )
            }
        }
    }

    // MARK: - Guests

    private var guestsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Guests")

            HStack(spacing: 10) {
                ForEach(DealGuests.allCases, id: \.self) { option in
                    let selected = guests == option
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { guests = option }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: option == .solo ? "person.fill" : "person.2.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text(option.title)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(selected ? .black : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            selected ? MatchaTokens.Colors.accent : Color.white.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Date

    private var dateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $hasDate.animation(.spring(response: 0.25, dampingFraction: 0.8))) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                    Text("Set visit date")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .tint(MatchaTokens.Colors.accent)

            if hasDate {
                DatePicker("", selection: $scheduledDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(MatchaTokens.Colors.accent)
                    .padding(12)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Deadline

    private var deadlineRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $hasContentDeadline.animation(.spring(response: 0.25, dampingFraction: 0.8))) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Content deadline")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Text("Optional")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }
            .tint(MatchaTokens.Colors.accent)

            if hasContentDeadline {
                DatePicker("", selection: $contentDeadline, in: scheduledDate..., displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(MatchaTokens.Colors.accent)
                    .padding(12)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Send

    private var sendButton: some View {
        Button(action: sendDeal) {
            HStack(spacing: 8) {
                if isSending {
                    ProgressView().tint(.black).scaleEffect(0.85)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Send Deal")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isValid ? MatchaTokens.Colors.accent : MatchaTokens.Colors.accent.opacity(0.3),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .disabled(!isValid || isSending)
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.5))
    }

    private func sendDeal() {
        guard isValid else { return }
        isSending = true
        apiError = nil

        let trimOffer = youOffer.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimReceive = youReceive.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimPlace = placeName.trimmingCharacters(in: .whitespacesAndNewlines)

        let request = DealCreateRequest(
            partnerId: partnerId,
            type: dealType == .barter ? .barter : .paid,
            youOffer: trimOffer,
            youReceive: trimReceive.isEmpty ? trimOffer : trimReceive,
            placeName: trimPlace.isEmpty ? nil : trimPlace,
            guests: guests.rawValue,
            dateTime: hasDate ? scheduledDate : nil,
            contentDeadline: hasContentDeadline ? contentDeadline : nil
        )

        Task {
            do {
                _ = try await repository.createDeal(request)
                await MainActor.run { isSending = false }
                await onSend()
                await MainActor.run { dismiss() }
            } catch let networkError as NetworkError {
                if case .conflict = networkError {
                    await onSend()
                    await MainActor.run { isSending = false; dismiss() }
                } else {
                    await MainActor.run {
                        isSending = false
                        apiError = networkError.errorDescription ?? "Something went wrong."
                    }
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    apiError = error.localizedDescription
                }
            }
        }
    }
}
