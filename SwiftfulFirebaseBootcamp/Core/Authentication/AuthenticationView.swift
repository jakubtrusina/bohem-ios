import SwiftUI
import FirebaseAnalytics


struct AuthenticationView: View {
    @State private var currentImageIndex = 0
    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Background images in Assets
    let backgroundImages = ["bg1", "bg2", "bg3", "bg4", "bg5"]

    var body: some View {
        ZStack {
            // ✅ Background with smooth fade
            ZStack {
                ForEach(backgroundImages.indices, id: \.self) { index in
                    Image(backgroundImages[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width,
                               height: UIScreen.main.bounds.height)
                        .clipped()
                        .opacity(currentImageIndex == index ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0), value: currentImageIndex)
                }
            }
            .ignoresSafeArea()

            // ✅ Dark overlay for contrast
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.6), .clear, .black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // ✅ Main UI
            VStack(spacing: 24) {
                Spacer().frame(height: 80) // top safe spacing

                // ✅ Logo
                Image("LOGO")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)

                // ✅ Title
                Text("Zaregistruj se do Bohem")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Objevuj jedinečné ručně vyráběné oblečení od pečlivě vybraných módních značek a nakupuj své oblíbené styly.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                // ✅ Email login
                NavigationLink(destination: SignInEmailView(showSignInView: $showSignInView)) {
                    Text("Použít e-mail")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .onTapGesture {
                    Analytics.logEvent("sign_in_nav", parameters: ["method": "email"])
                }


                // ✅ Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.3))
                    Text("nebo")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal)

                // ✅ Social sign-in buttons
                VStack(spacing: 12) {
                    SignInRow(label: "Pokračovat přes Apple", icon: "apple.logo", color: .white.opacity(0.95)) {
                        Analytics.logEvent("sign_in_tapped", parameters: ["method": "apple"])
                        Task {
                            await handleSignIn({ try await viewModel.signInApple() }, method: "apple")
                        }
                    }

                    SignInRow(label: "Pokračovat přes Google", icon: "g.circle", color: .white.opacity(0.95)) {
                        Analytics.logEvent("sign_in_tapped", parameters: ["method": "google"])
                        Task {
                            await handleSignIn({ try await viewModel.signInGoogle() }, method: "google")
                        }
                    }

                    SignInRow(label: "Pokračovat jako host", icon: "person", color: .white.opacity(0.95)) {
                        Analytics.logEvent("sign_in_tapped", parameters: ["method": "guest"])
                        Task {
                            await handleSignIn({ try await viewModel.signInAnonymous() }, method: "guest")
                        }
                    }


                }

                Spacer()

                // ✅ Legal text & Login link
                VStack(spacing: 6) {
                    Text("Pokračováním souhlasíte s našimi Podmínkami služby a potvrzujete, že jste si přečetli naše Zásady ochrany osobních údajů a Zásady používání cookies.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal)

                    HStack(spacing: 4) {
                        Text("Už máš účet?")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.footnote)

                        NavigationLink(destination: SignInEmailView(showSignInView: $showSignInView, isSignInMode: true)) {
                            Text("Přihlásit se")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .onTapGesture {
                            Analytics.logEvent("sign_in_nav", parameters: ["method": "email_login"])
                        }

                        .font(.footnote)

                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal)

            // ✅ Loading overlay
            if isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Přihlašuji...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: "AuthenticationView",
                AnalyticsParameterScreenClass: "AuthenticationView"
            ])

            Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                currentImageIndex = (currentImageIndex + 1) % backgroundImages.count
            }
        }
        .alert(item: $errorMessage) { msg in
            Alert(title: Text("Chyba"), message: Text(msg), dismissButton: .default(Text("OK")))
        }
        .navigationBarHidden(true)
    }

    private func handleSignIn(_ action: @escaping () async throws -> Void, method: String) async {
        isLoading = true
        do {
            try await action()

            // ✅ Track success
            Analytics.logEvent("sign_in_success", parameters: [
                "method": method
            ])

            showSignInView = false
        } catch {
            errorMessage = error.localizedDescription

            // ❌ Optional: Track failure
            Analytics.logEvent("sign_in_failure", parameters: [
                "method": method,
                "error": error.localizedDescription
            ])
        }
        isLoading = false
    }

}

// MARK: - Social SignIn Button View
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
                    .foregroundColor(.black)

                Text(label)
                    .font(.headline)
                    .foregroundColor(.black)

                Spacer()
            }
            .padding()
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}
