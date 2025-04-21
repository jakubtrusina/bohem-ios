import SwiftUI

struct BookingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BookingViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                DatePicker("Select a Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .onChange(of: viewModel.selectedDate) { _ in
                        Task {
                            await viewModel.fetchAvailableTimes(for: viewModel.selectedDate)
                        }
                    }

                if viewModel.availableTimes.isEmpty {
                    Text("No available slots for this date.")
                        .foregroundColor(.gray)
                } else {
                    Picker("Time Slot", selection: $viewModel.selectedTime) {
                        ForEach(viewModel.availableTimes, id: \.self) { time in
                            Text(time)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Button("Book Consultation") {
                    Task {
                        await viewModel.bookConsultation()
                        // Optional: trigger email function here if implemented
                    }
                }
                .disabled(viewModel.selectedTime.isEmpty)
                .buttonStyle(.borderedProminent)

                if viewModel.bookingSuccess {
                    Text("✅ Booking Confirmed!")
                        .foregroundColor(.green)
                        .font(.headline)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Book In-Store Visit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    BookingView(viewModel: BookingViewModel(
        userId: "preview-user-id",
        userName: "Preview User",
        userEmail: "preview@example.com"
    ))
}
