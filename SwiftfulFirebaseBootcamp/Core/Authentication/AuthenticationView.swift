import SwiftUI

struct AuthenticationView: View {

    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            VStack(spacing: 24) {

                // ✅ Logo
                Image("LOGO") // <- Replace with your asset name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top, 20)

                // ✅ Title
                Text("Sign up for Bohem")
                    .font(.title)
                    .fontWeight(.bold)

                // ✅ Email/Phone CTA
                NavigationLink {
                    SignInEmailView(showSignInView: $showSignInView)
                } label: {
                    Text("Use email")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(12)
                }

                // ✅ Custom OR Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.systemGray4))
                    Text("or")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.systemGray4))
                }
                .padding(.horizontal)

                // ✅ Social Buttons (all custom)
                VStack(spacing: 12) {
                    SignInRow(label: "Continue with Apple", icon: "apple.logo", color: Color(.systemGray6)) {
                        Task {
                            await handleSignIn { try await viewModel.signInApple() }
                        }
                    }

                    SignInRow(label: "Continue with Google", icon: "g.circle", color: Color(.systemGray6)) {
                        Task {
                            await handleSignIn { try await viewModel.signInGoogle() }
                        }
                    }

                    SignInRow(label: "Continue as Guest", icon: "person", color: Color(.systemGray6)) {
                        Task {
                            await handleSignIn { try await viewModel.signInAnonymous() }
                        }
                    }
                }

                Spacer()

                // ✅ Legal Footer
                VStack(spacing: 6) {
                    Text("By continuing, you agree to our Terms of Service and acknowledge that you have read our Privacy Policy and Cookies Policy.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                            .font(.footnote)
                        NavigationLink {
                            SignInEmailView(showSignInView: $showSignInView, isSignInMode: true)
                        } label: {
                            Text("Log in")
                                .foregroundColor(.pink)
                                .fontWeight(.semibold)
                        }

                        .foregroundColor(.gray)
                        .font(.footnote)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding()

            if isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Signing In...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .alert(item: $errorMessage) { msg in
            Alert(title: Text("Error"), message: Text(msg), dismissButton: .default(Text("OK")))
        }
        .navigationBarHidden(true)
    }

    private func handleSignIn(_ action: @escaping () async throws -> Void) async {
        isLoading = true
        do {
            try await action()
            showSignInView = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Custom Unified Social Button
struct SignInRow: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(label)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(12)
        }
    }
}
