struct ActivitySummary: Hashable {
    let likes: [UserProfile]
    let activeDeals: [Deal]
    let finishedDeals: [Deal]
    let cancelledDeals: [Deal]
    let noShowDeals: [Deal]
    let applications: [OfferApplication]
}
