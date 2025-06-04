import SwiftUI

struct RezervaceListView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert: Bool = false
    @State private var rezervaceToDelete: ProfileViewModel.Rezervace? = nil
    @State private var notificationsEnabled: [String: Bool] = [:]

    var body: some View {
        AnalyticsTrackedView(screenName: "RezervaceListView") {
            Group {
                if viewModel.rezervace.isEmpty {
                    VStack(spacing: 20) {
                        Text("Nemáte žádné rezervace.")
                            .font(.headline)
                            .padding(.top, 40)

                        if let user = viewModel.user {
                            let bookingVM = BookingViewModel(
                                userId: user.userId,
                                userName: viewModel.name,
                                userEmail: user.email ?? "",
                                userPhone: user.phoneNumber ?? "",
                                locationId: "temporary" // a placeholder that won't cause crash
                            )

                            NavigationLink(destination: BookingView(viewModel: bookingVM)) {
                                Text("Vytvořit novou rezervaci")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                AnalyticsManager.shared.logEvent(.buttonClick, params: [
                                    "button_id": "new_reservation",
                                    "screen": "RezervaceListView"
                                ])
                                AnalyticsManager.shared.logEvent(.startCheckout, params: [
                                    "screen": "RezervaceListView"
                                ])
                            })
                        } else {
                            VStack(spacing: 12) {
                                Text("Pro vytvoření rezervace se prosím přihlaste.")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)

                                NavigationLink("Přihlásit se", destination: AuthenticationView(showSignInView: .constant(true)))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.rezervace) { rezervace in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("📍 Místo:").font(.caption)
                                    Text(rezervace.locationName).font(.subheadline)
                                }
                                HStack {
                                    Text("📅 Datum:").font(.caption)
                                    Text(rezervace.date).font(.subheadline)
                                }
                                HStack {
                                    Text("🕒 Čas:").font(.caption)
                                    Text(rezervace.time).font(.subheadline)
                                }
                                if !rezervace.reason.isEmpty {
                                    HStack {
                                        Text("📝 Důvod:").font(.caption)
                                        Text(rezervace.reason).font(.subheadline)
                                    }
                                }
                                HStack {
                                    Text("✅ Potvrzeno:").font(.caption)
                                    Text(rezervace.confirmed ? "Ano" : "Ne")
                                        .font(.subheadline)
                                        .foregroundColor(rezervace.confirmed ? .green : .red)
                                }

                                Toggle("🔔 Připomenout hodinu předem", isOn: Binding(
                                    get: { notificationsEnabled[rezervace.id] ?? false },
                                    set: { newValue in
                                        notificationsEnabled[rezervace.id] = newValue
                                        if newValue {
                                            viewModel.rezervaceNotificationManager.scheduleNotification(for: rezervace)
                                        } else {
                                            viewModel.rezervaceNotificationManager.cancelNotification(for: rezervace)
                                        }

                                        AnalyticsManager.shared.logCustomEvent(name: "notification_toggle", params: [
                                            "reservation_id": rezervace.id,
                                            "enabled": newValue.description
                                        ])
                                    }
                                ))
                                .font(.caption)

                                Button(role: .destructive) {
                                    rezervaceToDelete = rezervace
                                    showingAlert = true
                                    AnalyticsManager.shared.logCustomEvent(name: "delete_reservation_initiated", params: [
                                        "reservation_id": rezervace.id
                                    ])
                                } label: {
                                    Label("Smazat rezervaci", systemImage: "trash")
                                }
                                .font(.caption)
                            }
                            .padding(.vertical, 8)
                            .onAppear {
                                viewModel.rezervaceNotificationManager.scheduleRatingPrompt(for: rezervace)
                                AnalyticsManager.shared.logEvent(.debug, params: [
                                    "event": "rating_prompt_shown",
                                    "reservation_id": rezervace.id
                                ])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Moje Rezervace")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Zpět")
                        }
                        .foregroundColor(.black)
                        .font(.headline)
                    }
                }
            }
            .onAppear {
                viewModel.rezervaceNotificationManager.requestPermission()
                Task {
                    if viewModel.user == nil {
                        try? await viewModel.loadCurrentUser()
                    }
                    await viewModel.loadRezervace()
                }            }
            .alert("Opravdu chcete rezervaci smazat?", isPresented: $showingAlert, presenting: rezervaceToDelete) { rezervace in
                Button("Smazat", role: .destructive) {
                    Task {
                        await viewModel.deleteRezervace(rezervace)
                        AnalyticsManager.shared.logCustomEvent(name: "delete_reservation_confirmed", params: [
                            "reservation_id": rezervace.id
                        ])
                    }
                }
                Button("Zrušit", role: .cancel) {}
            } message: { _ in
                Text("Tato akce je nevratná.")
            }
        }
    }
}
