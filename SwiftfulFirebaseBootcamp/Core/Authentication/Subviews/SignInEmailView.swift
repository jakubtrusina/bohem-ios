import SwiftUI
import FirebaseAuth

struct SignInEmailView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var showSignInView: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSignInMode: Bool
    @State private var showForgotPasswordPrompt = false
    @State private var resetEmail = ""
    @State private var currentImageIndex = 0

    private let backgroundImages = ["bg1", "bg2", "bg3", "bg4", "bg5"]

    init(showSignInView: Binding<Bool>, isSignInMode: Bool = false) {
        _showSignInView = showSignInView
        _isSignInMode = State(initialValue: isSignInMode)
    }

    var body: some View {
        ZStack {
            // MARK: - Background slideshow
            ZStack {
                ForEach(backgroundImages.indices, id: \.self) { i in
                    Image(backgroundImages[i])
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                        .opacity(currentImageIndex == i ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0), value: currentImageIndex)
                }
            }
            .ignoresSafeArea()

            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.4), .clear, .black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // MARK: - VStack wrapped content
            VStack {
                // MARK: - Zpět button top-left
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Zpět")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.top, 50)

                Spacer().frame(height: 30)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Image("LOGO")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)

                        Text(isSignInMode ? "Přihlášení" : "Vytvořit účet")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(radius: 5)

                        Text("Objevuj jedinečné ručně vyráběné oblečení od pečlivě vybraných módních značek a nakupuj své oblíbené styly.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Picker("", selection: $isSignInMode) {
                            Text("Přihlásit se").tag(true)
                            Text("Zaregistrovat se").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .colorScheme(.dark)

                        Group {
                            TextField("Zadej svůj email", text: $email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(14)
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)

                            SecureField("Zadej heslo", text: $password)
                                .textContentType(.password)
                                .padding(14)
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                        }
                        .padding(.horizontal)

                        if isSignInMode {
                            HStack {
                                Spacer()
                                Button("Zapomenuté heslo?") {
                                    resetEmail = email
                                    showForgotPasswordPrompt = true
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal)
                        }

                        Button {
                            Task { await handleAuth() }
                        } label: {
                            Text(isSignInMode ? "Přihlásit se" : "Vytvořit účet")
                                .fontWeight(.bold)
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.white.opacity(0.95))
                                .foregroundColor(.black)
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                        .padding(.horizontal)

                        Spacer()

                        Text("Pokračováním souhlasíte s našimi Podmínkami služby a potvrzujete, že jste si přečetli naše Zásady ochrany osobních údajů a Zásady používání cookies.")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal)
                }
                .scrollContentBackground(.hidden)
                .ignoresSafeArea(.container, edges: .bottom)
            }

            // MARK: - Loading overlay
            if isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Zpracovávám…")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                currentImageIndex = (currentImageIndex + 1) % backgroundImages.count
            }
        }
        .alert("Obnovit heslo", isPresented: $showForgotPasswordPrompt) {
            TextField("Zadej svůj email", text: $resetEmail)
            Button("Odeslat") { Task { await sendPasswordReset() } }
            Button("Zrušit", role: .cancel) {}
        } message: {
            Text("Zašleme ti odkaz pro obnovení hesla.")
        }
        .alert(item: $errorMessage) { msg in
            Alert(title: Text("Chyba"), message: Text(msg), dismissButton: .default(Text("OK")))
        }
        .navigationBarBackButtonHidden(true)
    }

    private func handleAuth() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Vyplň prosím všechny údaje."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if isSignInMode {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                let user = result.user

                if !user.isEmailVerified {
                    try await user.sendEmailVerification()
                    try Auth.auth().signOut()
                    errorMessage = "Před přihlášením ověř svůj email. Ověřovací zpráva byla odeslána."
                    return
                }

                // ✅ Create Firestore profile
                let authModel = AuthDataResultModel(user: user)
                let dbUser = DBUser(auth: authModel)
                try await UserManager.shared.createNewUser(user: dbUser)

            } else {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                try await result.user.sendEmailVerification()
                errorMessage = "Účet vytvořen. Zkontroluj email a potvrď registraci."
                return
            }

            showSignInView = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendPasswordReset() async {
        guard !resetEmail.isEmpty else {
            errorMessage = "Zadej email."
            return
        }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: resetEmail)
            errorMessage = "Email pro obnovu hesla byl odeslán na \(resetEmail)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
