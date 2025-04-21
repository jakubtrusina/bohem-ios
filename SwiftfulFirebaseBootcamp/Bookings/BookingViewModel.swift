//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 4/14/25.
//

import Foundation
import FirebaseFirestore

@MainActor
final class BookingViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var availableTimes: [String] = []
    @Published var selectedTime: String = ""
    @Published var bookingSuccess: Bool = false

    let userId: String
    let userName: String
    let userEmail: String   // 👈 Add this

    init(userId: String, userName: String, userEmail: String) {
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
    }

    func fetchAvailableTimes(for date: Date) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        do {
            let snapshot = try await Firestore.firestore()
                .collection("consultations")
                .whereField("date", isEqualTo: dateString)
                .getDocuments()

            let booked = snapshot.documents.compactMap { $0["time"] as? String }
            let all = (10..<18).map { "\($0):00" } // Slots from 10:00 to 17:00
            self.availableTimes = all.filter { !booked.contains($0) }
        } catch {
            print("❌ Error fetching available times: \(error)")
            self.availableTimes = []
        }
    }

    
    func bookConsultation() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)

        let data: [String: Any] = [
            "userId": userId,
            "name": userName,
            "email": userEmail, // ✅ Use this instead of user.email
            "date": dateString,
            "time": selectedTime,
            "confirmed": true
        ]

        do {
            try await Firestore.firestore().collection("consultations").addDocument(data: data)
            bookingSuccess = true
        } catch {
            print("❌ Error booking consultation: \(error)")
        }
    }
}
