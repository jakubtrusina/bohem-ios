import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Custom title under your BohemHeaderBar
            Text("Nastavení")
                .font(.title2.bold())
                .foregroundColor(.black)
                .padding(.horizontal)
                .padding(.top, 4)
            List {
                // MARK: - Help Section
                Section {
                    NavigationLink(destination: HelpPageView()) {
                        Label("Nápověda a podpora", systemImage: "questionmark.circle")
                            .foregroundColor(.black)
                    }
                }
                .listRowBackground(Color(.systemGray6))
                
                // MARK: - Email Functions
                if viewModel.authProviders.contains(.email) {
                    emailSection
                }
                
                // MARK: - Anonymous Linking
                if viewModel.authUser?.isAnonymous == true {
                    anonymousSection
                }
                
                // MARK: - Sign Out & Delete
                Section {
                    Button {
                        Task {
                            do {
                                try viewModel.signOut()
                                showSignInView = true
                            } catch {
                                print(error)
                            }
                        }
                    } label: {
                        Label("Odhlásit se", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.black)
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            do {
                                try await viewModel.deleteAccount()
                                showSignInView = true
                            } catch {
                                print(error)
                            }
                        }
                    } label: {
                        Label("Smazat účet", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                .listRowBackground(Color(.systemGray6))
            }
            .listStyle(.insetGrouped)
            .background(Color.white.ignoresSafeArea())
            .onAppear {
                viewModel.loadAuthProviders()
                viewModel.loadAuthUser()
            }
        }
    }
    // MARK: - Email Section
    private var emailSection: some View {
        Section(header:
            Text("Funkce pro e-mail")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.black)
        ) {
            Button {
                Task {
                    try? await viewModel.resetPassword()
                }
            } label: {
                Label("Obnovit heslo", systemImage: "key.fill")
                    .foregroundColor(.black)
            }

            Button {
                Task {
                    try? await viewModel.updatePassword()
                }
            } label: {
                Label("Změnit heslo", systemImage: "lock.rotation")
                    .foregroundColor(.black)
            }

            Button {
                Task {
                    try? await viewModel.updateEmail()
                }
            } label: {
                Label("Změnit e-mail", systemImage: "envelope")
                    .foregroundColor(.black)
            }
        }
        .listRowBackground(Color(.systemGray6))
    }

    // MARK: - Anonymous User Linking
    private var anonymousSection: some View {
        Section(header:
            Text("Propojit účet")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.black)
        ) {
            Button {
                Task {
                    try? await viewModel.linkGoogleAccount()
                }
            } label: {
                Label("Propojit Google účet", systemImage: "globe")
                    .foregroundColor(.black)
            }

            Button {
                Task {
                    try? await viewModel.linkAppleAccount()
                }
            } label: {
                Label("Propojit Apple účet", systemImage: "apple.logo")
                    .foregroundColor(.black)
            }

            Button {
                Task {
                    try? await viewModel.linkEmailAccount()
                }
            } label: {
                Label("Propojit e-mailový účet", systemImage: "envelope")
                    .foregroundColor(.black)
            }
        }
        .listRowBackground(Color(.systemGray6))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView(showSignInView: .constant(false))
        }
    }
}
