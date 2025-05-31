//
//  BookingViewModel.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 4/14/25.
//

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

    // MARK: - Init
    init(userId: String, userName: String, userEmail: String, locationId: String) {
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.locationId = locationId
    }

    // MARK: - Fetch Available Times
    func fetchAvailableTimes(for date: Date) async {
        guard !locationId.isEmpty else {
            print("❌ Cannot fetch times: locationId is empty")
            availableTimes = []
            return
        }
        let dateString = formatDate(date)

        print("📅 Checking booked times for: \(locationId) on \(dateString)")

        do {
            let snapshot = try await Firestore.firestore()
                .collection("locations")
                .document(locationId)
                .collection("consultations")
                .whereField("date", isEqualTo: dateString)
                .getDocuments()

            let booked = snapshot.documents.compactMap { $0["time"] as? String }
            let all = (10..<18).map { "\($0):00" }  // 10:00 to 17:00
            availableTimes = all.filter { !booked.contains($0) }

        } catch {
            print("❌ Failed to fetch times: \(error.localizedDescription)")
            availableTimes = []
        }
    }

    // MARK: - Book Consultation
    func bookConsultation() async {
        let dateStr = formatDate(selectedDate)

        guard !selectedTime.isEmpty, !reason.isEmpty else {
            print("⚠️ Missing time or reason.")
            return
        }

        let booking: [String: Any] = [
            "userId": userId,
            "name": userName,
            "email": userEmail,
            "date": dateStr,
            "time": selectedTime,
            "reason": reason,
            "locationId": locationId,
            "locationName": locationName,
            "confirmed": true,
            "createdAt": Timestamp()
        ]

        do {
            // Global consultation record
            try await Firestore.firestore()
                .collection("locations")
                .document(locationId)
                .collection("consultations")
                .addDocument(data: booking)

            // User-specific reservation record
            try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("rezervace")
                .addDocument(data: booking)

            bookingSuccess = true
            print("✅ Rezervace potvrzena pro \(userName) v \(selectedTime) dne \(dateStr)")

        } catch {
            print("❌ Booking failed: \(error.localizedDescription)")
        }
    }


    // MARK: - Helper
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
