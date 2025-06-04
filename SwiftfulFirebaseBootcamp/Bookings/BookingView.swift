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
    @State private var isLoadingTimes = false
    @StateObject private var profileViewModel = ProfileViewModel()


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
                            guard let location = newLocation else { return }
                            setLocation(location)
                            Task {
                                isLoadingTimes = true
                                await viewModel.fetchAvailableTimes(for: viewModel.selectedDate)
                                isLoadingTimes = false
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

                    Divider().padding(.vertical, 8)

                    // MARK: - Date Picker
                    DatePicker("Vyberte datum", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding(.horizontal)
                        .onChange(of: viewModel.selectedDate) { newDate in
                            Task {
                                isLoadingTimes = true
                                try? await Task.sleep(nanoseconds: 250_000_000) // debounce
                                await viewModel.fetchAvailableTimes(for: newDate)
                                isLoadingTimes = false
                            }
                            viewModel.listenToBookingChanges(for: newDate)
                        }

                    // MARK: - Time Picker
                    if isLoadingTimes {
                        ProgressView("Načítám dostupné časy...")
                            .padding()
                    } else if viewModel.availableTimes.isEmpty {
                        Text("Žádné volné termíny pro toto datum.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                Text("Vyberte čas")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                                ForEach(viewModel.availableTimes, id: \.self) { time in
                                    Button {
                                        viewModel.selectedTime = time
                                    } label: {
                                        Text(time)
                                            .padding(10)
                                            .frame(maxWidth: .infinity)
                                            .background(viewModel.selectedTime == time ? Color.black : Color.gray.opacity(0.15))
                                            .foregroundColor(viewModel.selectedTime == time ? .white : .black)
                                            .cornerRadius(8)
                                            .font(.footnote)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Divider().padding(.vertical, 8)

                    // MARK: - Reason Input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Důvod návštěvy")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        TextField("Např. chci vyzkoušet šaty...", text: $viewModel.reason)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .submitLabel(.done)
                    }

                    if !missingInfoMessage.isEmpty {
                        Text(missingInfoMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Book Button
                    Button {
                        Task {
                            await viewModel.bookConsultation()
                            if viewModel.bookingSuccess {
                                AnalyticsManager.shared.logCustomEvent(name: "reservation_made", params: [
                                    "location_id": viewModel.locationId,
                                    "location_name": viewModel.locationName,
                                    "selected_date": ISO8601DateFormatter().string(from: viewModel.selectedDate),
                                    "selected_time": viewModel.selectedTime,
                                    "reason": viewModel.reason
                                ])
                                withAnimation {
                                    showSuccessOverlay = true
                                }
                            }
                        }
                    } label: {
                        Text("Rezervovat konzultaci")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .accessibilityLabel("Tlačítko pro potvrzení rezervace")
                    }
                    .disabled(viewModel.selectedTime.isEmpty || selectedLocation == nil)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)

            // MARK: - Success Overlay
            if showSuccessOverlay {
                BookingSuccessOverlay(profileViewModel: profileViewModel) {
                    withAnimation {
                        showSuccessOverlay = false
                        dismiss()
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            loadLocations()
            AnalyticsManager.shared.logCustomEvent(name: "reservation_viewed")
        }
        .onDisappear {
            viewModel.removeListener()
        }
    }

    private func setLocation(_ location: BookingLocation) {
        viewModel.locationId = location.id ?? ""
        viewModel.locationName = location.name
        viewModel.listenToBookingChanges(for: viewModel.selectedDate)
    }

    private func loadLocations() {
        Task {
            do {
                let snapshot = try await Firestore.firestore().collection("locations").getDocuments()
                let fetched = snapshot.documents.compactMap { try? $0.data(as: BookingLocation.self) }

                await MainActor.run {
                    self.locations = fetched
                    if self.selectedLocation == nil, let first = fetched.first {
                        self.selectedLocation = first
                        setLocation(first)
                        Task {
                            isLoadingTimes = true
                            await viewModel.fetchAvailableTimes(for: viewModel.selectedDate)
                            isLoadingTimes = false
                        }
                    }
                }
            } catch {
                print("❌ Error loading locations: \(error.localizedDescription)")
            }
        }
    }
}

struct BookingSuccessOverlay: View {
    var profileViewModel: ProfileViewModel
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

            NavigationLink(destination: RezervaceListView(viewModel: profileViewModel)) {
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
                }
            }
            .foregroundColor(.gray)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}


extension BookingView {
    private var missingInfoMessage: String {
        var missing: [String] = []
        if selectedLocation == nil { missing.append("showroom") }
        if viewModel.selectedTime.isEmpty { missing.append("čas") }
        return missing.isEmpty ? "" : "Pro dokončení rezervace prosím vyberte: " + missing.joined(separator: ", ")
    }
}
