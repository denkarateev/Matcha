import SwiftUI

/// Offers tab — shows marketplace offers directly (deals moved to Chats tab).
struct OffersAndDealsView: View {
    let currentUser: UserProfile
    let repository: any MatchaRepository

    @State private var showCreateOffer = false
    @State private var showDealsCRM = false
    @State private var showFilter = false
    @State private var isSearchActive = false
    @FocusState private var searchFieldFocused: Bool
    @State private var searchText = ""
    @State private var filterState = OfferFilterState()

    private var isBusiness: Bool { currentUser.role == .business }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack(spacing: 12) {
                Text("Offers")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        isSearchActive.toggle()
                        if !isSearchActive { searchText = "" }
                    }
                    if isSearchActive { searchFieldFocused = true }
                } label: {
                    Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 36, height: 36)
                }

                Button { showFilter = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(filterState.isActive ? MatchaTokens.Colors.accent : .white.opacity(0.85))
                        .frame(width: 36, height: 36)
                }

                Button { showDealsCRM = true } label: {
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 36, height: 36)
                }

                if isBusiness {
                    Button { showCreateOffer = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Expandable search field
            if isSearchActive {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.35))
                    TextField("Search for offers", text: $searchText)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($searchFieldFocused)
                        .submitLabel(.done)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            OffersView(
                repository: repository,
                isBusiness: isBusiness,
                searchText: $searchText,
                filterState: $filterState
            )
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreateOffer) {
            CreateOfferView(repository: repository)
        }
        .sheet(isPresented: $showDealsCRM) {
            NavigationStack { DealsCRMView() }
        }
        .sheet(isPresented: $showFilter) {
            OfferFilterView(
                filterState: $filterState,
                matchingCount: 0
            )
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
    }
}
