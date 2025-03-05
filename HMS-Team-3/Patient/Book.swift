import SwiftUI
import FirebaseFirestore
import Firebase

// MARK: - Model for Doctor Schedule
struct DoctorSchedule: Codable {
    let doctorId: String
    let date: Timestamp
    let endTime: Timestamp
    let maxPatients: Int
    let slots: [Slot]
}

struct Slot: Codable {
    let isBooked: Bool
    let time: String
}

// MARK: - ViewModel to Handle Firestore Fetching
class DoctorScheduleViewModel: ObservableObject {
    @Published var availableSlots: [String] = []
    
    func fetchAvailableSlots(for doctorId: String) {
        let db = Firestore.firestore()
        db.collection("doctor_schedules")
            .whereField("doctorId", isEqualTo: doctorId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching doctor schedules: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.availableSlots = []
                    guard let documents = snapshot?.documents else { return }
                    
                    for document in documents {
                        if let slotsArray = document.data()["slots"] as? [[String: Any]] {
                            for slot in slotsArray {
                                if let isBooked = slot["isBooked"] as? Bool, !isBooked,
                                   let time = slot["time"] as? String {
                                    self.availableSlots.append(time)
                                }
                            }
                        }
                    }
                }
            }
    }
}

// MARK: - Book View
struct BookView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedSlot: String? = nil
    @StateObject private var viewModel = DoctorScheduleViewModel()
    
    let doctor: DoctorModel
    let selectedDate: Date

    var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        VStack {
            DoctorInfoView(doctor: doctor)
                .padding()
            Text("Available Slots")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 10)

            if viewModel.availableSlots.isEmpty {
                Text("No available slots")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                AvailableSlotsGrid(availableSlots: viewModel.availableSlots, selectedSlot: $selectedSlot)
            }

            Spacer()

            BookAppointmentButton()
        }
        
        .navigationTitle("Book Appointment")
        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button("Doctors") {
//                    presentationMode.wrappedValue.dismiss()
//                }
//                .foregroundColor(.blue)
//            }
//        }
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .onAppear {
            viewModel.fetchAvailableSlots(for: doctor.id)
        }
    }

    private func BookAppointmentButton() -> some View {
        Button(action: {
            if let selectedSlot = selectedSlot {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd MMM yyyy"
                let formattedDate = formatter.string(from: selectedDate)

                let newAppointment = Appointment(
                    doctorName: doctor.firstName + " " + doctor.lastName,
                    specialty: doctor.specialization,
                    appointmentDate: formattedDate,
                    appointmentSlot: selectedSlot
                )

                AppointmentManager.shared.addAppointment(newAppointment, forDoctor: doctor.id)
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            Text("Book Appointment")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
        }
        .disabled(selectedSlot == nil)
        .opacity(selectedSlot == nil ? 0.5 : 1.0)
    }
}

// MARK: - Doctor Profile View
//struct PatientDoctorProfileView: View {
//    let doctor: DoctorModel
//
//    var body: some View {
//        HStack(spacing: 16) {
//            if let image = UIImage(named: doctor.firstName), !doctor.firstName.isEmpty {
//                Image(uiImage: image)
//                    .resizable()
//                    .frame(width: 80, height: 80)
//                    .clipShape(RoundedRectangle(cornerRadius: 10))
//                    .shadow(radius: 2)
//            } else {
//                Image(systemName: "person.crop.square.fill")
//                    .resizable()
//                    .frame(width: 80, height: 80)
//                    .clipShape(RoundedRectangle(cornerRadius: 10))
//            }
//
//            VStack(alignment: .leading) {
//                Text(doctor.firstName + " " + doctor.lastName)
//                    .font(.title2)
//                    .fontWeight(.bold)
//
//                Text(doctor.specialization)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//            Spacer()
//        }
//        .padding()
//        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(radius: 2))
//        .padding(.horizontal)
//    }
//}

// MARK: - Available Slots Grid
struct AvailableSlotsGrid: View {
    let availableSlots: [String]
    @Binding var selectedSlot: String?

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(availableSlots, id: \.self) { slot in
                Button {
                    selectedSlot = slot
                } label: {
                    Text(slot)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedSlot == slot ? .white : .blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedSlot == slot ? Color.blue : Color.clear)
                        .cornerRadius(10)
//                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 5)
    }
}
