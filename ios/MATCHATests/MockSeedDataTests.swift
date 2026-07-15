import Testing
@testable import tuju

@Test
func feedProfilesAreSeeded() {
    #expect(!MockSeedData.feedProfiles.isEmpty)
}
