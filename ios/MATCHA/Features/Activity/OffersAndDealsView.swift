import SwiftUI

/// Combined Offers + Deals tab — shows marketplace offers and user's active deals in one place.
struct OffersAndDealsView: View {
    let currentUser: UserProfile
    let repository: any MatchaRepository

    @State private var selectedSection: Section = .offers

    enum Section: String, CaseIterable {
        case offers = "Offers"
        case deals = "My Deals"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom top bar — no system toolbar grouping
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

            // Segmented picker
            Picker("", selection: $selectedSection) {
                ForEach(Section.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.bottom, 4)

            switch selectedSection {
            case .offers:
                OffersView(repository: repository, isBusiness: currentUser.role == .business)
            case .deals:
                DealsView(currentUser: currentUser, repository: repository)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showFilter) {
            OfferFilterView(
                filterState: .constant(OfferFilterState()),
                matchingCount: 0
            )
        }
        .background(Color(hex: 0x0A0A0A).ignoresSafeArea())
    }

    @State private var showSearch = false
    @State private var showFilter = false
}
