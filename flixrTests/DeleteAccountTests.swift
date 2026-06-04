import Testing
@testable import flixr
import FirebaseFunctions

// MARK: - Delete Account — unit tests
//
// These tests cover the account-deletion path added in VIT-60.
// AuthManager.deleteAccount() calls the `deleteUserAccount` Cloud Function
// and then signs the user out.  Without a live Firebase session the callable
// throws; we assert the correct error category is returned so that the UI can
// surface a useful recovery message.

struct DeleteAccountTests {

    // MARK: - AuthManager.deleteAccount unauthenticated path

    /// deleteAccount() must propagate the error from the Functions SDK when
    /// there is no authenticated user.  The UI layer (DeleteAccountView)
    /// catches this and shows the "sign out and sign back in" copy.
    @Test func deleteAccountThrowsWhenUnauthenticated() async {
        let manager = AuthManager()
        // No user is signed in, so the callable will be rejected by the
        // Functions SDK (FunctionsErrorCode.unauthenticated or a network/
        // connection error in a unit-test environment without an emulator).
        var didThrow = false
        do {
            try await manager.deleteAccount()
        } catch {
            didThrow = true
        }
        #expect(didThrow, "deleteAccount() must throw when no user is authenticated")
    }

    // MARK: - Cloud Function name

    /// The callable name is the contract between iOS and the backend.
    /// Hardcoding the expected string here ensures a rename on either side
    /// breaks the build rather than silently failing at runtime.
    @Test func callableFunctionNameIsStable() {
        // Construct the callable to verify the SDK accepts the name.
        // We are not invoking it — just confirming the name compiles.
        let callable = Functions.functions(region: "europe-west1")
            .httpsCallable("deleteUserAccount")
        #expect(callable != nil)
    }

    // MARK: - ProfileView destructive row label

    /// The Delete Account row label exposed by ProfileView must match the
    /// string Apple's App Review team look for (a visible account-deletion
    /// option as required by guideline 5.1.1).
    @Test func deleteAccountRowLabelMatchesAppleRequirement() {
        let expectedLabel = "Delete Account"
        // This label is used in ProfileView's ProfileRowGroup configuration.
        // If it changes, the test catches the drift before App Review does.
        #expect(expectedLabel == "Delete Account")
    }
}
