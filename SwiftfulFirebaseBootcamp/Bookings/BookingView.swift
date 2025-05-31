import SwiftUI
import FirebaseFirestore
import FirebaseAnalytics


struct BookingLocation: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    var name: String
    var address: String
}

struct BookingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BookingViewModel
    @State private var locations: [BookingLocation] = []
    @State private var selectedLocation: BookingLocation?
    @State private var showSuccessOverlay = false
    @State private var hasInitialized = false


    init(viewModel: BookingViewModel) {
        self.viewModel = viewModel
        UIDatePicker.appearance().locale = Locale(identifier: "cs_CZ")
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Showroom Picker
                    if !locations.isEmpty {
                        Picker("Vyberte showroom", selection: $selectedLocation) {
                            Text("Vyberte showroom").tag(Optional<BookingLocation>.none)
                            ForEach(locations) { location in
                                Text(location.name).tag(Optional(location))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                        .onChange(of: selectedLocation) { newLocation in
                            if !hasInitialized {
                                hasInitialized = true
                                return // skip the first change triggered by loadLocations()
                            }

                            if let location = newLocation, let id = location.id {
                                viewModel.locationId = id
                                viewModel.locationName = location.name
                                Task {
                                    await viewModel.fetchAvailableTimes(for: viewModel.selectedDate)
                                }
                            }
                        }

                    } else {
                        Text("Nebyly nalezeny žádné showroomy.")
                            .foregroundColor(.red)
                            .padding()
                    }

                    // MARK: - Address
                    if let address = selectedLocation?.address {
                        Text(address)
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Date Picker
                    DatePicker("Vyberte datum", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .onChange(of: viewModel.selectedDate) { _ in
                            if let location = selectedLocation, let id = location.id, !id.isEmpty {
                                viewModel.locationId = id
                                viewModel.locationName = location.name
                                Task {
                                    await viewModel.fetchAvailableTimes(for: viewModel.selectedDate)
                                }
                            } else {
                                print("⚠️ Skipping fetch, invalid location")
                            }
                        }
                        .padding(.horizontal)

                    // MARK: - Time Picker
                    if viewModel.availableTimes.isEmpty {
                        Text("Žádné volné termíny pro toto datum.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } else {
                        Picker("Dostupné časy", selection: $viewModel.selectedTime) {
                            ForEach(viewModel.availableTimes, id: \.self) { time in
                                Text(time)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                    }

                    // MARK: - Reason Input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Důvod návštěvy")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        TextField("Např. chci vyzkoušet šaty...", text: $viewModel.reason)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }

                    // MARK: - Book Button
                    Button {
                        Task {
                            await viewModel.bookConsultation()
                            if viewModel.bookingSuccess {
                                AnalyticsManager.shared.logCustomEvent(name: "reservation_made", params: [
                                    "location_id": viewModel.locationId ?? "unknown",
                                    "location_name": viewModel.locationName ?? "unknown",
                                    "selected_date": ISO8601DateFormatter().string(from: viewModel.selectedDate),
                                    "selected_time": viewModel.selectedTime,
                                    "reason": viewModel.reason
                                ])
                                showSuccessOverlay = true
                            }

                        }
                    } label: {
                        Text("Rezervovat konzultaci")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.selectedTime.isEmpty || selectedLocation == nil || viewModel.reason.isEmpty)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)

            // MARK: - Success Overlay
            if showSuccessOverlay {
                BookingSuccessOverlay {
                    showSuccessOverlay = false
                    dismiss()
                }
            }
        }
        .onAppear {
            loadLocations()
            AnalyticsManager.shared.logCustomEvent(name: "reservation_viewed")
        }

    }

    private func loadLocations() {
        Firestore.firestore().collection("locations").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error loading locations: \(error.localizedDescription)")
                return
            }

            guard let docs = snapshot?.documents else { return }

            let fetched = docs.compactMap { try? $0.data(as: BookingLocation.self) }
            locations = fetched

            if selectedLocation == nil, let first = fetched.first, let id = first.id {
                selectedLocation = first
                viewModel.locationId = id
                viewModel.locationName = first.name
                Task {
                    await viewModel.fetchAvailableTimes(for: viewModel.selectedDate)
                }
            }
        }
    }
}

struct BookingSuccessOverlay: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Rezervace úspěšně dokončena!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Detaily najdete ve svém profilu v sekci „Rezervace“.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            NavigationLink(destination: RezervaceListView(viewModel: ProfileViewModel())) {
                Text("Zobrazit moje rezervace")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            Button("Zavřít") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }            }
            .foregroundColor(.gray)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}
