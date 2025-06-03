import XCTest
import AuthenticationServices // Required for ASAuthorizationAppleIDCredential
@testable import MessagesExtension // Replace 'MessagesExtension' if your module name is different

// --- Mock Keychain Service (Conceptual - not directly injected into AuthenticationService.shared) ---
// This mock helps in reasoning about what *should* happen.
// Actual tests on AuthenticationService.shared will interact with the real Keychain.
class MockKeychainServiceForAuthTests {
    var storedIdentifiers: [String: String] = [:] // serviceName_accountName: identifier
    var saveIdentifierCalled = false
    var loadIdentifierCalled = false
    var deleteIdentifierCalled = false
    var lastSavedIdentifier: String?
    var lastDeletedAccount: String?

    // Using specific service and account names as AuthenticationService does
    private let serviceName = "com.example.ClothingApp.AuthService"
    private let accountName = "currentUserIdentifier"
    private var key: String { "\(serviceName)_\(accountName)" }

    func saveIdentifierToKeychain(identifier: String) {
        storedIdentifiers[key] = identifier
        saveIdentifierCalled = true
        lastSavedIdentifier = identifier
    }

    func loadIdentifierFromKeychain() -> String? {
        loadIdentifierCalled = true
        return storedIdentifiers[key]
    }

    func deleteIdentifierFromKeychain() {
        storedIdentifiers.removeValue(forKey: key)
        deleteIdentifierCalled = true
        lastDeletedAccount = accountName
    }

    func reset() {
        storedIdentifiers.removeAll()
        saveIdentifierCalled = false
        loadIdentifierCalled = false
        deleteIdentifierCalled = false
        lastSavedIdentifier = nil
        lastDeletedAccount = nil
    }
}

// --- Mock ASAuthorizationAppleIDCredential ---
class MockASAuthorizationAppleIDCredential: ASAuthorizationAppleIDCredential {
    private let _user: String
    private let _fullName: PersonNameComponents?
    private let _email: String?

    init(user: String, fullName: PersonNameComponents? = nil, email: String? = nil) {
        self._user = user
        self._fullName = fullName
        self._email = email
        // Other properties like authorizationCode, identityToken, realUserStatus would be nil or default
    }

    override var user: String { _user }
    override var fullName: PersonNameComponents? { _fullName }
    override var email: String? { _email }
    // Ensure all properties of ASAuthorizationAppleIDCredential are implemented if needed,
    // though for this service, only user, fullName, and email are accessed.
}


class AuthenticationServiceTests: XCTestCase {

    var authService: AuthenticationService!
    // We can't directly inject a mock into AuthenticationService.shared.
    // So, tests will interact with the real Keychain.
    // For some tests, we'll clear the keychain item to ensure a known state.

    let testUserIdentifier = "testUser123"
    let testUserEmail = "test@example.com"
    var testUserFullName: PersonNameComponents {
        var components = PersonNameComponents()
        components.givenName = "Test"
        components.familyName = "User"
        return components
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        authService = AuthenticationService.shared
        // Ensure a clean state for Keychain before each test that relies on it.
        // This interacts with the *actual* Keychain through the service's implementation.
        authService.signOut() // Clears current user and calls deleteIdentifierFromKeychain
    }

    override func tearDownWithError() throws {
        // Clean up after each test by signing out and ensuring Keychain is cleared.
        authService.signOut()
        authService = nil
        try super.tearDownWithError()
    }

    func testInitialState() {
        XCTAssertFalse(authService.isAuthenticated, "Service should not be authenticated initially.")
        XCTAssertNil(authService.currentUser, "Current user should be nil initially.")
        XCTAssertNil(authService.authenticationError, "Authentication error should be nil initially.")
    }

    func testSignOut() {
        // Simulate a logged-in state by manually setting properties (and Keychain if possible)
        // For this test, directly manipulating internal state is okay for shared instance.
        authService.currentUser = User(id: testUserIdentifier, username: "test", displayName: "Test", email: "test@example.com", avatarURL: nil, joinDate: Date())
        authService.isAuthenticated = true
        // Manually save to keychain to simulate a previous login
        authService.saveIdentifierToKeychain(identifier: testUserIdentifier)

        authService.signOut()

        XCTAssertFalse(authService.isAuthenticated, "isAuthenticated should be false after sign out.")
        XCTAssertNil(authService.currentUser, "currentUser should be nil after sign out.")
        // Verify Keychain item was deleted (indirectly, by trying to load it)
        XCTAssertNil(authService.loadIdentifierFromKeychain(), "Keychain identifier should be deleted on sign out.")
    }

    func testCheckAuthenticationStatus_NoIdentifierInKeychain() {
        // Assumes Keychain is clean due to setUpWithError's signOut call
        let expectation = XCTestExpectation(description: "Check authentication status with no identifier in Keychain")

        authService.checkAuthenticationStatus { isAuthenticated in
            XCTAssertFalse(isAuthenticated, "Should not be authenticated if no identifier in Keychain.")
            XCTAssertNil(self.authService.currentUser, "User should be nil.")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0) // Increased timeout for potential async operations
    }

    // This test is more of an integration test due to CloudKit dependency.
    // It also relies on a successful sign-in to populate Keychain first.
    func testCheckAuthenticationStatus_IdentifierInKeychain_UserFetchSuccess() {
        // 1. Simulate a successful sign-in to get identifier into Keychain & a user into CloudKit (simulated)
        let signInExpectation = XCTestExpectation(description: "Sign in to populate Keychain and CloudKit")
        let credential = MockASAuthorizationAppleIDCredential(user: testUserIdentifier, fullName: testUserFullName, email: testUserEmail)

        // Temporarily assign a completion handler for signInWithApple
        var tempAuthCompletionHandler: ((Bool) -> Void)?
        let signInCompletion: (Bool) -> Void = { success in
            XCTAssertTrue(success, "Sign-in should be successful for setup.")
            signInExpectation.fulfill()
        }
        tempAuthCompletionHandler = signInCompletion // Keep a strong reference
        authService.signInWithApple(completion: tempAuthCompletionHandler!)


        // Simulate the delegate call
        // In a real XCTest environment for UI elements, this would be triggered by UI interaction.
        // Here, we call the delegate method directly.
        // This assumes ASAuthorizationController is not crucial for the *logic* being tested here, only its result.
        let mockController = ASAuthorizationController(authorizationRequests: []) // Dummy controller
        authService.authorizationController(controller: mockController, didCompleteWithAuthorization: ASAuthorization(credential: credential, provider: ASAuthorizationAppleIDProvider()))

        wait(for: [signInExpectation], timeout: 10.0) // Wait for sign-in to complete (includes async CloudKit)

        // Ensure currentUser is set by sign-in before proceeding
        guard authService.currentUser != nil else {
            XCTFail("currentUser was not set after simulated sign-in during test setup.")
            return
        }

        // 2. Sign out to clear in-memory state but keep Keychain entry
        authService.isAuthenticated = false // Manually reset for the test's purpose
        authService.currentUser = nil     // Manually reset

        // 3. Now check authentication status
        let checkStatusExpectation = XCTestExpectation(description: "Check authentication status with identifier in Keychain")
        authService.checkAuthenticationStatus { isAuthenticated in
            XCTAssertTrue(isAuthenticated, "Should be authenticated if identifier is in Keychain and user fetch succeeds.")
            XCTAssertNotNil(self.authService.currentUser, "Current user should be populated.")
            XCTAssertEqual(self.authService.currentUser?.id, self.testUserIdentifier, "Fetched user ID should match.")
            checkStatusExpectation.fulfill()
        }
        wait(for: [checkStatusExpectation], timeout: 10.0) // Increased timeout for CloudKit
    }

    func testSignInWithApple_SuccessfulCredential_SaveToKeychain_AndFetchUser() {
        let expectation = XCTestExpectation(description: "Sign In with Apple success")
        let credential = MockASAuthorizationAppleIDCredential(user: testUserIdentifier, fullName: testUserFullName, email: testUserEmail)

        // We need to use the internal completion handler mechanism of AuthenticationService
        var tempAuthCompletionHandler: ((Bool) -> Void)?
        let signInCompletion: (Bool) -> Void = { success in
            XCTAssertTrue(success, "Sign-in success completion should be true.")
            XCTAssertTrue(self.authService.isAuthenticated, "isAuthenticated should be true after successful sign-in.")
            XCTAssertNotNil(self.authService.currentUser, "currentUser should be populated.")
            XCTAssertEqual(self.authService.currentUser?.id, self.testUserIdentifier)
            // Verify Keychain item was saved (indirectly)
            XCTAssertEqual(self.authService.loadIdentifierFromKeychain(), self.testUserIdentifier, "Identifier should be saved to Keychain.")
            expectation.fulfill()
        }
        tempAuthCompletionHandler = signInCompletion
        authService.signInWithApple(completion: tempAuthCompletionHandler!)


        let mockController = ASAuthorizationController(authorizationRequests: [])
        authService.authorizationController(controller: mockController, didCompleteWithAuthorization: ASAuthorization(credential: credential, provider: ASAuthorizationAppleIDProvider()))

        wait(for: [expectation], timeout: 10.0) // Increased timeout for async operations including CloudKit
    }

    // This test focuses on the logic within AuthenticationService when CloudKit interaction fails *after* Apple Sign-In.
    func testSignInWithApple_ProfileFetchFails_DeletesKeychainIdentifier() {
        let failingUserIdentifier = "userWhoWillFailCloudKitFetch"
        let credential = MockASAuthorizationAppleIDCredential(user: failingUserIdentifier, fullName: testUserFullName, email: "fail@example.com")

        // Save to ensure it's there before the "failed" fetch causes deletion
        authService.saveIdentifierToKeychain(identifier: failingUserIdentifier)
        XCTAssertNotNil(authService.loadIdentifierFromKeychain(), "Identifier should be in Keychain before fetch failure.")

        let expectation = XCTestExpectation(description: "Sign In with Apple, but CloudKit fetch/save fails")

        var tempAuthCompletionHandler: ((Bool) -> Void)?
        let signInCompletion: (Bool) -> Void = { success in
            XCTAssertFalse(success, "Sign-in success completion should be false due to CloudKit failure.")
            XCTAssertFalse(self.authService.isAuthenticated, "isAuthenticated should be false.")
            XCTAssertNil(self.authService.currentUser, "currentUser should be nil.")
            // Verify Keychain item was deleted due to CloudKit failure after Apple Sign In
            XCTAssertNil(self.authService.loadIdentifierFromKeychain(), "Keychain identifier should be deleted after CloudKit failure post-Apple Sign In.")
            expectation.fulfill()
        }
        tempAuthCompletionHandler = signInCompletion
        authService.signInWithApple(completion: tempAuthCompletionHandler!)

        // To make CloudKit fail for *this specific user ID* is hard without mocking CloudKitManager.
        // The current AuthenticationService.fetchUserFromCloudKit has logic:
        // if user is nil (from fetch) AND name/email are provided (from Apple ID Credential), it tries to SAVE a new user.
        // If THAT save fails, then the overall operation fails.
        // We assume here that for 'failingUserIdentifier', the `cloudKitManager.saveUser` call will result in a failure (e.g. returns (false, nil)).
        // This part is an "assumption" as we can't directly inject a mock CloudKitManager that fails on demand for this ID.
        // The logic inside `fetchUserFromCloudKit` that calls `deleteIdentifierFromKeychain` *if* the user object is nil *after* trying to fetch/create IS testable.

        let mockController = ASAuthorizationController(authorizationRequests: [])
        // Simulate the delegate call which triggers fetchUserFromCloudKit
        authService.authorizationController(controller: mockController, didCompleteWithAuthorization: ASAuthorization(credential: credential, provider: ASAuthorizationAppleIDProvider()))

        wait(for: [expectation], timeout: 10.0) // Allow time for async operations
    }
}
