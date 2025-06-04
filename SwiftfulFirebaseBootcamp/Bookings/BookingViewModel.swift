import Foundation
import FirebaseFirestore

@MainActor
final class BookingViewModel: ObservableObject {

    // MARK: - Booking State
    @Published var selectedDate: Date = Date()
    @Published var availableTimes: [String] = []
    @Published var selectedTime: String = ""
    @Published var reason: String = ""
    @Published var bookingSuccess: Bool = false
    @Published var locationId: String
    @Published var locationName: String = ""

    // MARK: - User Info (Injected)
    private let userId: String
    private let userName: String
    private let userEmail: String
    private let userPhone: String

    // MARK: - Firestore Listener
    private var listener: ListenerRegistration?

    // MARK: - Init
    init(userId: String, userName: String, userEmail: String, userPhone: String, locationId: String) {
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.userPhone = userPhone
        self.locationId = locationId
    }

    // MARK: - Fetch Available Times
    func fetchAvailableTimes(for date: Date) async {
        guard !locationId.trimmingCharacters(in: .whitespaces).isEmpty,
              locationId.lowercased() != "temporary" else {
            await MainActor.run {
                self.availableTimes = []
            }
            #if DEBUG
            print("❌ Skipping fetch: locationId is invalid")
            #endif
            return
        }


        let dateString = formatDate(date)

        #if DEBUG
        print("📅 Checking booked times for: \(locationId) on \(dateString)")
        #endif

        do {
            let snapshot = try await Firestore.firestore()
                .collection("locations")
                .document(locationId)
                .collection("consultations")
                .whereField("date", isEqualTo: dateString)
                .getDocuments()

            let booked = snapshot.documents.compactMap { $0["time"] as? String }
            let all = (10..<18).map { "\($0):00" }  // 10:00 to 17:00
            let available = all.filter { !booked.contains($0) }

            await MainActor.run {
                self.availableTimes = available
                if !available.contains(self.selectedTime) {
                    self.selectedTime = ""
                }
            }

        } catch {
            await MainActor.run {
                self.availableTimes = []
            }
            #if DEBUG
            print("❌ Failed to fetch times: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Listen for Real-Time Changes
    func listenToBookingChanges(for date: Date) {
        listener?.remove()

        guard !locationId.trimmingCharacters(in: .whitespaces).isEmpty,
              locationId.lowercased() != "temporary" else {
            #if DEBUG
            print("❌ Skipping listener: locationId is invalid")
            #endif
            return
        }

        let dateStr = formatDate(date)
        #if DEBUG
        print("🔄 Listening for booking changes on \(dateStr)")
        #endif

        listener = Firestore.firestore()
            .collection("locations")
            .document(locationId)
            .collection("consultations")
            .whereField("date", isEqualTo: dateStr)
            .addSnapshotListener { [weak self] _, _ in
                guard let self = self else { return }
                Task {
                    await self.fetchAvailableTimes(for: date)
                }
            }
    }


    // MARK: - Stop Listening
    func removeListener() {
        listener?.remove()
        listener = nil
        #if DEBUG
        print("🛑 Removed Firestore listener")
        #endif
    }

    // MARK: - Book Consultation
    func bookConsultation() async {
        let dateStr = formatDate(selectedDate)

        guard !selectedTime.isEmpty else {
            #if DEBUG
            print("⚠️ Missing time.")
            #endif
            return
        }

        let booking: [String: Any] = [
            "userId": userId,
            "name": userName,
            "email": userEmail,
            "phone": userPhone,
            "date": dateStr,
            "time": selectedTime,
            "reason": reason,
            "locationId": locationId,
            "locationName": locationName,
            "confirmed": true,
            "createdAt": Timestamp()
        ]

        do {
            // Save to location's bookings
            try await Firestore.firestore()
                .collection("locations")
                .document(locationId)
                .collection("consultations")
                .addDocument(data: booking)

            // Save to user's reservations
            try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("rezervace")
                .addDocument(data: booking)

            await MainActor.run {
                bookingSuccess = true
            }

            #if DEBUG
            print("✅ Booking confirmed for \(userName) at \(selectedTime) on \(dateStr)")
            #endif

        } catch {
            await MainActor.run {
                bookingSuccess = false
            }

            #if DEBUG
            print("❌ Booking failed: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Helper
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
