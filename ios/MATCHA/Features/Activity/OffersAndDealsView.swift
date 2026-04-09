import SwiftUI

/// Offers tab — shows marketplace offers directly (deals moved to Chats tab).
struct OffersAndDealsView: View {
    let currentUser: UserProfile
    let repository: any MatchaRepository

    @State private var showSearch = false
    @State private var showFilter = false
    @State private var showCreateOffer = false

    private var isBusiness: Bool { currentUser.role == .business }

    var body: some View {
        VStack(spacing: 0) {
            // Custom top bar
            HStack {
                Text("Offers")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                if isBusiness {
                    Button { showCreateOffer = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                    }
                }

                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.leading, isBusiness ? 12 : 0)

                Button { showFilter = true } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.leading, 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)

            OffersView(repository: repository, isBusiness: isBusiness)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreateOffer) {
            CreateOfferView()
        }
        .sheet(isPresented: $showFilter) {
            OfferFilterView(
                filterState: .constant(OfferFilterState()),
                matchingCount: 0
            )
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
    }
}
