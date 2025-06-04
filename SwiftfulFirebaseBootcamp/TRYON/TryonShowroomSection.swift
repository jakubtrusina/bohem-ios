import SwiftUI
import FirebaseAuth

struct TryonShowroomSection: View {
    @Binding var bannerTarget: BannerNavigationTarget?
    @State private var hasTrackedAppear = false
    @State private var showLoginAlert = false

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Full Width Showroom Image
            Image("interior")
                .resizable()
                .scaledToFill()
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(0)
                .ignoresSafeArea(edges: .horizontal)

            // MARK: - Persuasive Text
            VStack(spacing: 8) {
                Text("Zarezervujte si luxusní zážitek v našem showroomu")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text("Vyzkoušejte si naše exkluzivní kousky osobně. Stylová atmosféra, individuální přístup a pomoc s výběrem na míru – to vše na vás čeká v srdci Litoměřic.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // MARK: - Side-by-side Buttons
            HStack(spacing: 16) {
                // ✅ Rezervace Button with Auth Check
                Button(action: {
                    AnalyticsManager.shared.logEvent(.buttonClick, params: [
                        "screen": "MainTryOnView",
                        "button_id": "showroom_booking"
                    ])

                    if Auth.auth().currentUser != nil {
                        bannerTarget = .booking
                    } else {
                        print("🔒 User not logged in — showing login alert")
                        showLoginAlert = true
                    }

                }) {
                    Text("Rezervace")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }


                // 🗺️ Zobrazit trasu Button
                Button(action: {
                    AnalyticsManager.shared.logEvent(.buttonClick, params: [
                        "screen": "MainTryOnView",
                        "button_id": "show_in_maps"
                    ])
                    openInMaps()
                }) {
                    HStack {
                        Image(systemName: "map")
                        Text("Zobrazit trasu")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)

            // MARK: - Address
            VStack(spacing: 4) {
                Text("Adresa Showroomu")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Text("Michalská 34/17, 41201 Litoměřice")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical)
        .onAppear {
            if !hasTrackedAppear {
                hasTrackedAppear = true
                AnalyticsManager.shared.logCustomEvent(name: "section_viewed", params: [
                    "screen": "MainTryOnView",
                    "section_id": "TryonShowroom"
                ])
            }
        }
        .alert("Přihlášení vyžadováno", isPresented: $showLoginAlert) {
            Button("Přihlásit se") {
                bannerTarget = .authRequired  // This should navigate to your login or settings view
            }
            Button("Zrušit", role: .cancel) { }
        } message: {
            Text("Abyste mohli vytvořit rezervaci v showroomu, musíte být přihlášeni ke svému účtu.")
        }

    }

    // MARK: - Apple Maps Integration
    private func openInMaps() {
        let address = "Michalská 34/17, 41201 Litoměřice"
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?address=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}
