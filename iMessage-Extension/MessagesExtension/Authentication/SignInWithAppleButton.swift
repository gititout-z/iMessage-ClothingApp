import SwiftUI
import AuthenticationServices

struct SignInWithAppleButton: View {
    var onCompletion: () -> Void
    
    var body: some View {
        AppleSignInButton(onCompletion: onCompletion)
            .frame(maxWidth: .infinity)
            .cornerRadius(8)
    }
}

struct AppleSignInButton: UIViewRepresentable {
    var onCompletion: () -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject {
        var onCompletion: () -> Void
        
        init(onCompletion: @escaping () -> Void) {
            self.onCompletion = onCompletion
        }
        
        @objc func buttonTapped() {
            onCompletion()
        }
    }
}