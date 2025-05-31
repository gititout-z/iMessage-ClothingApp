// iMessage-Extension/ClothingApp/MessagesViewController.swift
import Messages
import SwiftUI
import ClothingKit
import Combine // Added for observing authentication state

class MessagesViewController: MSMessagesAppViewController {
    private let authService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>() // To store Combine subscriptions

    override func viewDidLoad() {
        super.viewDidLoad()

        // Observe authentication changes
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main) // Ensure UI updates are on the main thread
            .sink { [weak self] _ in
                // Only attempt to present if the view is currently part of a window hierarchy
                // and activeConversation is available (which implies willBecomeActive has been called)
                guard let self = self, self.view.window != nil, let conversation = self.activeConversation else {
                    return
                }
                self.presentViewController(for: conversation, with: self.presentationStyle)
            }
            .store(in: &cancellables)
    }

    override
    func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation) // It's good practice to call super

        // Active conversation contains the message send information
        // It is used to determine the presentation style.
        // This is the primary trigger for initial UI setup.
        // The Combine subscriber will handle subsequent changes if the view is already active.
        authService.checkAuthenticationStatus { [weak self] _ in
             guard let self = self else { return }
             self.presentViewController(for: conversation, with: self.presentationStyle)
        }
    }

    // MARK: - Conversation Handling

    private func presentViewController(for conversation: MSConversation, with presentationStyle: MSMessagesAppPresentationStyle) {
        // Ensure this runs on the main thread as it manipulates UI
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.presentViewController(for: conversation, with: presentationStyle)
            }
            return
        }

        // Remove any existing child view controllers
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        let vc: UIViewController
        if authService.isAuthenticated, let user = authService.currentUser {
            // If user is authenticated, present the main interface
            let mainView = TabView {
                // Assuming ProfileView, SearchView, CameraView, SocialView are defined SwiftUI views
                // And User is a struct/class that ProfileView expects
                ProfileView(user: user) // You might need to ensure 'user' is @ObservedObject or @StateObject if it's a class
                    .tabItem { Label("Profile", systemImage: "person") }

                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }

                CameraView()
                    .tabItem { Label("Add", systemImage: "plus") }

                SocialView()
                    .tabItem { Label("Social", systemImage: "person.2") }
            }
            vc = UIHostingController(rootView: mainView)
        } else {
            // If user is not authenticated, present the authentication flow
            // AuthenticationView's completion handler (isSuccessful) is now simplified.
            // The AuthenticationService is responsible for updating its own state.
            // The Combine subscriber in this ViewController will react to that state change.
            let authView = AuthenticationView { [weak self] isSuccessful in
                // This completion is from AuthenticationService's signInWithApple.
                // If successful, AuthenticationService has updated its @Published properties,
                // which the Combine sink will pick up and re-trigger presentViewController.
                // If not successful, an error might be displayed by AuthenticationView or handled by AuthenticationService.
                if !isSuccessful {
                    Logger.shared.info("AuthenticationView completion: Authentication was not successful.")
                    // Optionally, handle specific UI feedback here if needed, though errors
                    // are often better handled within AuthenticationService or AuthenticationView itself.
                }
                // No explicit call to self?.presentViewController needed here if Combine observer is robust.
                // However, to ensure immediate refresh post-login screen, one could be added,
                // but it might be redundant with the Combine-driven update.
                // For now, relying on Combine observer.
            }
            vc = UIHostingController(rootView: authView)
        }

        addChild(vc)
        vc.view.frame = self.view.bounds
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(vc.view)

        NSLayoutConstraint.activate([
            vc.view.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            vc.view.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            vc.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

        vc.didMove(toParent: self)
    }

    // Removed `presentMainInterface(for user: User)` method.
    // UI updates are now driven by `willBecomeActive` and Combine subscription to `authService.$isAuthenticated`.
    // The following methods from MSMessagesAppViewController are often overridden:
    // override func didStartSending(_ message: MSMessage, conversation: MSConversation) { ... }
    // override func didCancelSending(_ message: MSMessage, conversation: MSConversation) { ... }
    // override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) { ... }
    // override func didReceive(_ message: MSMessage, conversation: MSConversation) { ... }
}

// Ensure these supporting types are defined elsewhere in the project,
// potentially within the ClothingKit or as part of the app's main target if shared.
// For example:
// struct User: Identifiable { /* ... */ var id: String }
// struct ProfileView: View { /* ... */ var user: User }
// struct SearchView: View { /* ... */ }
// struct CameraView: View { /* ... */ }
// struct SocialView: View { /* ... */ }
// struct AuthenticationView: View { /* ... */ var onAuthComplete: (User) -> Void }
// class AuthenticationService { /* ... */ static let shared = AuthenticationService(); var currentUser: User? }
// import ClothingKit // Assuming ClothingKit provides some of these or other necessary types.
