import Foundation
import Testing
@testable import flixr

// MARK: - PermissionGateView — unit tests
//
// These tests cover the "show once per install" gate logic introduced in VIT-53.
// They exercise the UserDefaults key contract without requiring a live device
// or simulator, so they run cleanly on CI.

@Suite(.serialized)
struct PermissionGateTests {

    // MARK: - hasBeenSeen reflects UserDefaults state

    /// When the UserDefaults key is absent the gate must report it has NOT
    /// been seen, so the first-launch flow is triggered correctly.
    @Test func notSeenWhenKeyIsAbsent() {
        UserDefaults.standard.removeObject(forKey: "hasSeenPermissionGate")
        #expect(PermissionGateView.hasBeenSeen == false,
                "Gate should not be considered seen before the key is written")
    }

    /// After writing `true` to the key (mimicking a completed gate flow) the
    /// static helper must return `true` so the gate is suppressed on relaunch.
    @Test func seenAfterKeyIsSet() {
        UserDefaults.standard.set(true, forKey: "hasSeenPermissionGate")
        defer { UserDefaults.standard.removeObject(forKey: "hasSeenPermissionGate") }
        #expect(PermissionGateView.hasBeenSeen == true,
                "Gate should be considered seen once the key is written")
    }

    /// Setting the key to `false` explicitly must behave the same as the key
    /// being absent — the gate should show again (e.g. after a settings reset).
    @Test func notSeenWhenKeyIsExplicitlyFalse() {
        UserDefaults.standard.set(false, forKey: "hasSeenPermissionGate")
        defer { UserDefaults.standard.removeObject(forKey: "hasSeenPermissionGate") }
        #expect(PermissionGateView.hasBeenSeen == false,
                "Gate should not be seen when key is explicitly false")
    }

    // MARK: - UserDefaults key contract

    /// The key string is part of the public contract between the gate and
    /// DiscoveryFlowView.  Hardcoding the expected value here ensures a rename
    /// is caught before it silently breaks the "show once" guarantee.
    @Test func userDefaultsKeyIsStable() {
        let expectedKey = "hasSeenPermissionGate"
        // Write via the known key and read back to verify PermissionGateView
        // uses the same string.
        UserDefaults.standard.set(true, forKey: expectedKey)
        defer { UserDefaults.standard.removeObject(forKey: expectedKey) }
        #expect(PermissionGateView.hasBeenSeen,
                "hasBeenSeen must read from key '\(expectedKey)'")
    }
}
