import SwiftUI

/// Offers tab — shows marketplace offers directly (deals moved to Chats tab).
struct OffersAndDealsView: View {
    let currentUser: UserProfile
    let repository: any MatchaRepository

    @State private var showSearch = false
    @State private var showFilter = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom top bar
            HStack {
                Text("Offers")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.8))
                }

                Button { showFilter = true } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.leading, 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)

            OffersView(repository: repository, isBusiness: currentUser.role == .business)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showFilter) {
            OfferFilterView(
                filterState: .constant(OfferFilterState()),
                matchingCount: 0
            )
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
    }
}
