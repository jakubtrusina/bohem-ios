import Foundation
import UserNotifications

class RezervaceNotificationManager {
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleNotification(for rezervace: ProfileViewModel.Rezervace) {
        let content = UNMutableNotificationContent()
        content.title = "Připomenutí rezervace"
        content.body = "Vaše rezervace ve \(rezervace.locationName) je dnes v \(rezervace.time)."
        content.sound = .default

        guard let date = rezervace.fullDateTime else { return }
        let notifyDate = Calendar.current.date(byAdding: .minute, value: -60, to: date) ?? date

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notifyDate),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: rezervace.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleRatingPrompt(for rezervace: ProfileViewModel.Rezervace) {
        guard let date = rezervace.fullDateTime else { return }
        let feedbackDate = Calendar.current.date(byAdding: .hour, value: 1, to: date) ?? date
        if feedbackDate < Date() { return } // Don't schedule past notifications

        let content = UNMutableNotificationContent()
        content.title = "Jaká byla vaše schůzka?"
        content.body = "Dejte nám vědět, jak jste byli spokojeni s rezervací ve \(rezervace.locationName)."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: feedbackDate),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: rezervace.id + "-feedback", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(for rezervace: ProfileViewModel.Rezervace) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            rezervace.id,
            rezervace.id + "-feedback"
        ])
    }
}
