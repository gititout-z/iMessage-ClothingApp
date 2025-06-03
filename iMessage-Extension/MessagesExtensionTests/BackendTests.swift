import XCTest
import CloudKit // Required for CKError
@testable import MessagesExtension // Replace 'MessagesExtension' if your module name is different

// A sample custom error for testing
enum TestAppError: Error, LocalizedError {
    case specificTestError
    var errorDescription: String? { "A specific test error occurred." }
}

class BackendTests: XCTestCase {

    var backend: Backend!
    var mockAuthService: MockAuthenticationServiceForBackendTests! // For testing signOut side effect

    override func setUpWithError() throws {
        try super.setUpWithError()
        backend = Backend.shared
        // For testing the signOut side effect in handleNetworkError,
        // we need to observe if AuthenticationService.shared.signOut() is called.
        // Since we can't easily mock the shared instance, we'll use a simple flag
        // on a mock that would be theoretically used by AuthenticationService if it were injectable.
        // This is an indirect way to test the side effect.
        mockAuthService = MockAuthenticationServiceForBackendTests()
        // In a real DI scenario, AuthenticationService would have a protocol and could be mocked.
        // Here, we are testing the *call* to AuthenticationService.shared.signOut().
        // To make this testable, we'd need to refactor AuthenticationService or use a notification.
        // For now, we'll assume the call happens if the logic path is taken.
    }

    override func tearDownWithError() throws {
        backend = nil
        mockAuthService = nil
        try super.tearDownWithError()
    }

    // MARK: - Tests for handleNetworkError

    func testHandleNetworkError_CKErrorNotAuthenticated() {
        let ckError = CKError(CKError.Code.notAuthenticated)
        let processedError = backend.handleNetworkError(ckError) as NSError

        XCTAssertEqual(processedError.domain, "Backend")
        XCTAssertEqual(processedError.code, 1004) // Specific code for notAuthenticated
        XCTAssertEqual(processedError.localizedDescription, "Authentication expired. Please sign in again.")
        // Ideally, also test that AuthenticationService.shared.signOut() was called.
        // This is hard without DI or notifications. For now, assume it's called if this path is hit.
    }

    func testHandleNetworkError_CKErrorNetworkUnavailable() {
        let ckError = CKError(CKError.Code.networkUnavailable)
        let processedError = backend.handleNetworkError(ckError) as NSError

        XCTAssertEqual(processedError.domain, "Backend")
        XCTAssertEqual(processedError.code, 1002)
        XCTAssertEqual(processedError.localizedDescription, "Network unavailable. Please check your connection and try again.")
    }

    func testHandleNetworkError_CKErrorNetworkFailure() {
        let ckError = CKError(CKError.Code.networkFailure)
        let processedError = backend.handleNetworkError(ckError) as NSError

        XCTAssertEqual(processedError.domain, "Backend")
        XCTAssertEqual(processedError.code, 1002) // Same as networkUnavailable
        XCTAssertEqual(processedError.localizedDescription, "Network unavailable. Please check your connection and try again.")
    }

    func testHandleNetworkError_CKErrorServerRejectedRequest() {
        let ckError = CKError(CKError.Code.serverRejectedRequest)
        let processedError = backend.handleNetworkError(ckError) as NSError

        XCTAssertEqual(processedError.domain, "Backend")
        XCTAssertEqual(processedError.code, 1003)
        XCTAssertEqual(processedError.localizedDescription, "Server error. Please try again later.")
    }

    func testHandleNetworkError_CKErrorOther() {
        let ckError = CKError(CKError.Code.internalError) // Any other CKError
        let processedError = backend.handleNetworkError(ckError) as NSError

        XCTAssertEqual(processedError.domain, "Backend")
        XCTAssertEqual(processedError.code, 1000) // Default "unexpected error"
        XCTAssertEqual(processedError.localizedDescription, "An unexpected error occurred. Please try again later.")
    }

    func testHandleNetworkError_URLErrorNotConnectedToInternet() {
        // Simulate networkMonitor.isConnected = false
        // This requires making NetworkMonitor injectable or observable, which is beyond scope.
        // So, we test the path where networkMonitor.isConnected is true, but a URLError is passed.
        // The current handleNetworkError prioritizes the networkMonitor check.
        // To test this specific URLError conversion, we'd assume networkMonitor IS connected.

        // If we assume networkMonitor.isConnected is true, then this URLError would likely fall
        // into the generic error category by the current `handleNetworkError` implementation,
        // as it only specifically checks for CKError types after the initial networkMonitor check.
        let urlError = URLError(.notConnectedToInternet)
        let processedError = backend.handleNetworkError(urlError) as NSError

        // Given current logic, if networkMonitor.isConnected is true, this becomes a generic error
        XCTAssertEqual(processedError.domain, "Backend")
        XCTAssertEqual(processedError.code, 1000)
        XCTAssertEqual(processedError.localizedDescription, "An unexpected error occurred. Please try again later.")

        // If we COULD mock networkMonitor.isConnected = false, then:
        // XCTAssertEqual(processedError.domain, "Backend")
        // XCTAssertEqual(processedError.code, 1001)
        // XCTAssertEqual(processedError.localizedDescription, "No internet connection. Please check your network settings and try again.")
        // This highlights a small dependency on NetworkMonitor's state that makes this specific error hard to isolate in tests.
    }

    func testHandleNetworkError_GenericNSError() {
        let genericError = NSError(domain: "MyCustomDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "A custom error."])
        let processedError = backend.handleNetworkError(genericError) as NSError

        // The current implementation wraps generic errors if it doesn't recognize them.
        XCTAssertEqual(processedError.domain, "Backend")
        XCTAssertEqual(processedError.code, 1000)
        XCTAssertEqual(processedError.localizedDescription, "An unexpected error occurred. Please try again later.")
    }

    func testHandleNetworkError_CustomAppError() {
        let customError = TestAppError.specificTestError
        let processedError = backend.handleNetworkError(customError) as NSError

        // Custom errors are also wrapped by the default case.
        XCTAssertEqual(processedError.domain, "Backend")
        XCTAssertEqual(processedError.code, 1000)
        XCTAssertEqual(processedError.localizedDescription, "An unexpected error occurred. Please try again later.")
    }

    // MARK: - Tests for retry Mechanism

    func testRetry_OperationSucceedsFirstTry() {
        let expectation = XCTestExpectation(description: "Retry operation succeeds on the first try")
        var operationCallCount = 0

        let successfulTask: (@escaping (Result<String, Error>) -> Void) -> Void = { completion in
            operationCallCount += 1
            completion(.success("Success!"))
        }

        backend.retry(task: successfulTask) { result in
            switch result {
            case .success(let value):
                XCTAssertEqual(value, "Success!")
                XCTAssertEqual(operationCallCount, 1, "Operation should be called only once.")
            case .failure(let error):
                XCTFail("Retry should have succeeded on the first try, but failed with \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testRetry_OperationFailsConsistently() {
        let expectation = XCTestExpectation(description: "Retry operation fails consistently after multiple attempts")
        var operationCallCount = 0
        let maxAttempts = 3 // Default in Backend.retry

        let failingTask: (@escaping (Result<String, Error>) -> Void) -> Void = { completion in
            operationCallCount += 1
            completion(.failure(TestAppError.specificTestError))
        }

        backend.retry(maxAttempts: maxAttempts, delay: 0.01, task: failingTask) { result in // Using small delay for test speed
            switch result {
            case .success:
                XCTFail("Retry should have failed consistently.")
            case .failure(let error):
                // Error should be processed by handleNetworkError
                let nsError = error as NSError
                XCTAssertEqual(nsError.domain, "Backend")
                XCTAssertEqual(nsError.code, 1000) // Default unexpected error
                XCTAssertEqual(nsError.localizedDescription, "An unexpected error occurred. Please try again later.")
                XCTAssertEqual(operationCallCount, maxAttempts, "Operation should be called maxAttempts times.")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0) // Timeout needs to accommodate retries + delays
    }

    func testRetry_OperationSucceedsAfterFailures() {
        let expectation = XCTestExpectation(description: "Retry operation succeeds after a few failures")
        var operationCallCount = 0
        let succeedOnAttempt = 2 // Make it succeed on the 2nd attempt

        let taskThatSucceedsLater: (@escaping (Result<String, Error>) -> Void) -> Void = { completion in
            operationCallCount += 1
            if operationCallCount == succeedOnAttempt {
                completion(.success("Success on attempt \(operationCallCount)"))
            } else {
                completion(.failure(TestAppError.specificTestError))
            }
        }

        backend.retry(maxAttempts: 3, delay: 0.01, task: taskThatSucceedsLater) { result in
            switch result {
            case .success(let value):
                XCTAssertEqual(value, "Success on attempt \(succeedOnAttempt)")
                XCTAssertEqual(operationCallCount, succeedOnAttempt, "Operation should be called until it succeeds.")
            case .failure(let error):
                XCTFail("Retry should have succeeded eventually, but failed with \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }
}

// Minimal mock for conceptual testing of AuthenticationService.shared.signOut() side effect
// In a real DI scenario, AuthenticationService would conform to a protocol.
class MockAuthenticationServiceForBackendTests {
    var signOutCalled = false

    // This would be the method called by Backend.swift if it had an injectable auth service.
    // Since it calls AuthenticationService.shared.signOut(), this mock is just for illustrative purposes.
    func signOut() {
        signOutCalled = true
    }
}
