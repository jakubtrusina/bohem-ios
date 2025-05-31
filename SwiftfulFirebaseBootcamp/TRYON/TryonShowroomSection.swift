import SwiftUI

struct TryonShowroomSection: View {
    @Binding var bannerTarget: BannerNavigationTarget?
    @State private var hasTrackedAppear = false

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
                Text("Zažijte luxusní zážitek v našem showroomu")
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
                Button(action: {
                    AnalyticsManager.shared.logEvent(.buttonClick, params: [
                        "screen": "MainTryOnView",
                        "button_id": "showroom_booking"
                    ])
                    bannerTarget = .booking
                }) {
                    Text("Rezervace")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

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
