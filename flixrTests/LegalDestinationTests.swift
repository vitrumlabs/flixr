import Foundation
import Testing
@testable import flixr

// MARK: - LegalDestination

struct LegalDestinationTests {

    @Test func termsURLIsCorrect() {
        #expect(LegalDestination.terms.url == URL(string: "https://vitrumlabs.com/flixr-terms.html"))
    }

    @Test func privacyURLIsCorrect() {
        #expect(LegalDestination.privacy.url == URL(string: "https://vitrumlabs.com/flixr-privacy.html"))
    }

    @Test func termsIdIsStable() {
        #expect(LegalDestination.terms.id == "terms")
    }

    @Test func privacyIdIsStable() {
        #expect(LegalDestination.privacy.id == "privacy")
    }

    @Test func destinationsAreDistinct() {
        #expect(LegalDestination.terms.url != LegalDestination.privacy.url)
    }
}
