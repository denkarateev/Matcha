import SwiftUI

/// In-app viewer for legal documents. The canonical texts live at tuju.online;
/// this shows a summary and links out so the app never ships stale legal copy.
struct LegalDocument: Identifiable {
    var id: String { title }
    let title: String
    let webURL: URL
    let summary: String

    static let terms = LegalDocument(
        title: "Terms of Service",
        webURL: URL(string: "https://tuju.online/terms.html")!,
        summary: """
        These Terms govern your use of tuju — the platform connecting content \
        creators and venues for barter collaborations.

        Key points:
        • You must be at least 18 years old to use tuju.
        • Creators and venues agree deal terms directly; tuju is the platform, \
        not a party to your collaborations.
        • Content you post must be yours and must not violate anyone's rights.
        • Completed deals are expected to be honored by both sides — no-shows \
        and unfulfilled content commitments affect your standing.
        • Accounts that abuse the platform may be suspended.

        The full, binding text is published at tuju.online and is pending \
        final legal review before public launch.
        """
    )

    static let privacy = LegalDocument(
        title: "Privacy Policy",
        webURL: URL(string: "https://tuju.online/privacy.html")!,
        summary: """
        This Policy explains how tuju collects, uses, stores, and shares \
        personal information, in line with the Indonesian Personal Data \
        Protection Law (UU PDP №27/2022).

        Key points:
        • We collect the profile data you provide (name, photos, social \
        handles, district) to run matching and deals.
        • Your public profile is visible to other users; contact details \
        are not shared without your action.
        • You can delete your account and data at any time from Settings.
        • We don't sell your personal data.

        The full, binding text is published at tuju.online and is pending \
        final legal review before public launch.
        """
    )
}

struct LegalDocumentView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
                    Text(document.summary)
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        .lineSpacing(4)

                    Button {
                        openURL(document.webURL)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "safari")
                                .font(.subheadline.weight(.semibold))
                            Text("Read the full document")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(MatchaTokens.Colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.top, MatchaTokens.Spacing.small)
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
                .padding(.vertical, MatchaTokens.Spacing.medium)
            }
            .background(MatchaTokens.Colors.background.ignoresSafeArea())
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    LegalDocumentView(document: .terms)
}
