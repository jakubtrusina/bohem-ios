import SwiftUI

struct SignInEmailView: View {
    @Binding var showSignInView: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSignInMode: Bool

    // Forgot password prompt
    @State private var showForgotPasswordPrompt = false
    @State private var resetEmail = ""

    init(showSignInView: Binding<Bool>, isSignInMode: Bool = false) {
        self._showSignInView = showSignInView
        self._isSignInMode = State(initialValue: isSignInMode)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // Title
                Text(isSignInMode ? "Sign In" : "Create Account")
                    .font(.title)
                    .bold()
                    .padding(.top, 40)

                // Toggle between Sign In / Sign Up
                Picker("", selection: $isSignInMode) {
                    Text("Sign In").tag(true)
                    Text("Sign Up").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Email Field
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                // Password Field
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                // Forgot password link
                if isSignInMode {
                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            resetEmail = email
                            showForgotPasswordPrompt = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }

                // Auth Button
                Button(action: {
                    Task { await handleAuth() }
                }) {
                    Text(isSignInMode ? "Sign In" : "Create Account")
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()

            // Loading Indicator
            if isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Processing...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        // Forgot Password Alert
        .alert("Reset Password", isPresented: $showForgotPasswordPrompt) {
            TextField("Enter your email", text: $resetEmail)
            Button("Send") {
                Task { await sendPasswordReset() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We'll send a link to reset your password.")
        }

        // Error Alert
        .alert(item: $errorMessage) { msg in
            Alert(title: Text("Error"), message: Text(msg), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Auth Logic

    private func handleAuth() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        isLoading = true
        do {
            if isSignInMode {
                try await AuthenticationManager.shared.signInUser(email: email, password: password)
            } else {
                try await AuthenticationManager.shared.createUser(email: email, password: password)
            }
            showSignInView = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func sendPasswordReset() async {
        guard !resetEmail.isEmpty else {
            errorMessage = "Please enter an email."
            return
        }

        do {
            try await AuthenticationManager.shared.resetPassword(email: resetEmail)
            errorMessage = "Password reset email sent."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

