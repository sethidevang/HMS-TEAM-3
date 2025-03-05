import SwiftUI
import Firebase
import FirebaseFirestore

struct HomeView: View {
    @State private var selectedTab = 0
    @State private var upcomingAppointments: [SeeAppointment] = []
    @State private var completedAppointments: [SeeAppointment] = []
    @State private var extraPatientData: [String: (age: String, gender: String, date: Date)] = [:]
    @State private var selectedFilter: String = "All"
    
    private var db = Firestore.firestore()
    var doctor: DoctorModel
    public init(doctor: DoctorModel) {  // ✅ Public initializer
            self.doctor = doctor
        }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Dr. \(doctor.firstName) \(doctor.lastName)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Appointments")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    
                    Menu {
                        Button("All (\(upcomingAppointments.count + completedAppointments.count))") { selectedFilter = "All" }
                        Button("Pending (\(countAppointments(status: "Pending")))") { selectedFilter = "Pending" }
                        Button("Approved (\(countAppointments(status: "Approved")))") { selectedFilter = "Approved" }
                        Button("Completed (\(countAppointments(status: "Completed")))") { selectedFilter = "Completed" }
                        Button("Canceled (\(countAppointments(status: "Canceled")))") { selectedFilter = "Canceled" }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.headline)
                    }
                }
                .padding()
                
                Picker("", selection: $selectedTab) {
                    Text("Upcoming").tag(0)
                    Text("Completed").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if filteredAppointments.isEmpty {
                    Spacer()
                    Text(selectedTab == 0 ? "You don't have any upcoming appointments." : "No completed appointments yet.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(filteredAppointments, id: \.id) { appointment in
                                let patientDetails = extraPatientData[appointment.userId]

                                NavigationLink(destination: AppointmentDetailView(
                                    appointment: appointment,
                                    doctorId: doctor.id,
                                    onUpdate: {
                                        fetchAppointments(for: doctor.id)
                                    }
                                )) {
                                    AppointmentCard(appointment: appointment)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                fetchAppointments(for: doctor.id)
            }
        }
    }

    private var filteredAppointments: [SeeAppointment] {
        let baseList = selectedTab == 0 ? upcomingAppointments : completedAppointments
        return selectedFilter == "All" ? baseList : baseList.filter { $0.status == selectedFilter }
    }

    private func countAppointments(status: String) -> Int {
        return (upcomingAppointments + completedAppointments).filter { $0.status == status }.count
    }

    func fetchAppointments(for doctorId: String) {
        let doctorRef = db.collection("doctors").document(doctorId)

        doctorRef.getDocument { document, error in
            guard let document = document, document.exists, let data = document.data(),
                  let appointmentsArray = data["appointments"] as? [[String: Any]] else {
                print("🔥 Error fetching doctor appointments: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            var fetchedUpcomingAppointments: [SeeAppointment] = []
            var fetchedCompletedAppointments: [SeeAppointment] = []
            let dispatchGroup = DispatchGroup()

            for dict in appointmentsArray {
                if let patientName = dict["patient"] as? String,
                   let time = dict["time"] as? String,
                   let status = dict["status"] as? String,
                   let userId = dict["userId"] as? String {

                    var appointmentDate: Date = Date() // Default to current date
                    if let timestamp = dict["date"] as? Timestamp {
                        appointmentDate = timestamp.dateValue()
                    } else if let dateString = dict["date"] as? String {
                        appointmentDate = self.parseDate(from: dateString) ?? Date()
                    }

                    let appointment = SeeAppointment(
                        id: UUID().uuidString,
                        patient: patientName,
                        age: "NA", // Placeholder, fetched separately
                        gender: "NA", // Placeholder, fetched separately
                        time: time,
                        date: appointmentDate, // ✅ Now storing the date in model
                        status: status,
                        userId: userId
                    )

                    if status == "Completed" {
                        fetchedCompletedAppointments.append(appointment)
                    } else {
                        fetchedUpcomingAppointments.append(appointment)
                    }

                    dispatchGroup.enter()
                    self.fetchPatientDetails(email: userId) { age, gender in
                        DispatchQueue.main.async {
                            let updatedAppointment = SeeAppointment(
                                id: appointment.id,
                                patient: appointment.patient,
                                age: age ?? "NA",
                                gender: gender ?? "NA",
                                time: appointment.time,
                                date: appointment.date,
                                status: appointment.status,
                                userId: appointment.userId
                            )

                            if status == "Completed" {
                                if let index = fetchedCompletedAppointments.firstIndex(where: { $0.id == appointment.id }) {
                                    fetchedCompletedAppointments[index] = updatedAppointment
                                }
                            } else {
                                if let index = fetchedUpcomingAppointments.firstIndex(where: { $0.id == appointment.id }) {
                                    fetchedUpcomingAppointments[index] = updatedAppointment
                                }
                            }
                            dispatchGroup.leave()
                        }
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                DispatchQueue.main.async {
                    self.upcomingAppointments = fetchedUpcomingAppointments
                    self.completedAppointments = fetchedCompletedAppointments
                }
            }
        }
    }

    private func parseDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    private func fetchPatientDetails(email: String, completion: @escaping (String?, String?) -> Void) {
        let patientRef = db.collection("patients").whereField("email", isEqualTo: email)
        
        patientRef.getDocuments { snapshot, error in
            guard let document = snapshot?.documents.first else {
                print("⚠️ Patient not found for email: \(email)")
                completion(nil, nil)
                return
            }
            
            let data = document.data()
            let age = data["age"] as? String
            let gender = data["gender"] as? String
            completion(age, gender)
        }
    }
}


/// ✅ Appointment Model
//import Foundation

struct SeeAppointment: Identifiable {
    var id: String
    var patient: String
    var age: String
    var gender: String
    var time: String
    var date: Date // ✅ Added date field
    var status: String
    var userId: String
}



/// ✅ Appointment Card (Reusable)
import SwiftUI

struct AppointmentCard: View {
    var appointment: SeeAppointment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patient: \(appointment.patient)")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Date: \(formattedDate(appointment.date))") // ✅ Uses date from model
                .font(.subheadline)
                .foregroundColor(.gray)

            Text("Time: \(appointment.time)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text("Status: \(appointment.status)")
                .font(.footnote)
                .foregroundColor(
                    appointment.status == "Completed" ? .green :
                    appointment.status == "Approved" ? .blue :
                    appointment.status == "Canceled" ? .red :
                    .yellow
                )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


/// ✅ Appointment Detail View
struct AppointmentDetailView: View {
    var appointment: SeeAppointment
        var doctorId: String
        var onUpdate: () -> Void
        
        @State private var status: String
        @Environment(\.presentationMode) var presentationMode
        @State private var showSuccessMessage = false
        
        init(appointment: SeeAppointment, doctorId: String, onUpdate: @escaping () -> Void) {
            self.appointment = appointment
            self.doctorId = doctorId
            self.onUpdate = onUpdate
            _status = State(initialValue: appointment.status)
        }
        
        var body: some View {
            Form {
                Section(header: Text("Patient Details")) {
                    HStack {
                        Text("Name:")
                        Spacer()
                        Text(appointment.patient)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Appointment Details")) {
                    HStack {
                        Text("Time:")
                        Spacer()
                        Text(appointment.time)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Date:")
                        Spacer()
                        Text(formatAppointmentDate(appointment.date))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Status:")
                        Spacer()
                        Text(status)
                            .foregroundColor(.primary)
                    }
                }
                
                if showSuccessMessage {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Appointment Ended Successfully!")
                                .font(.subheadline)
                        }
                    }
                    .transition(.opacity)
                }
                
                Section {
                    if status == "Pending" {
                        Button(action: {
                            approveAppointment()
                        }) {
                            Text("End Appointment")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    
                    
                }
            }
            .navigationTitle("Appointment Details")
        }
    
    private func approveAppointment() {
        let db = Firestore.firestore()
        let doctorRef = db.collection("doctors").document(doctorId)
        
        doctorRef.getDocument { document, error in
            if let document = document, document.exists {
                if var appointmentsArray = document.data()?["appointments"] as? [[String: Any]] {
                    
                    // Find the correct appointment using patient & time
                    if let index = appointmentsArray.firstIndex(where: {
                        ($0["userId"] as? String == appointment.userId) &&
                        ($0["time"] as? String == appointment.time)
                    }) {
                        // Update the status
                        appointmentsArray[index]["status"] = "Completed"
                        
                        // Write back to Firestore
                        doctorRef.updateData(["appointments": appointmentsArray]) { error in
                            if let error = error {
                                print("Error updating appointment: \(error.localizedDescription)")
                            } else {
                                DispatchQueue.main.async {
                                    self.status = "Completed"
                                    self.showSuccessMessage = true
                                    
                                    // ✅ Auto-refresh HomeView after approval
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        self.presentationMode.wrappedValue.dismiss()
                                        self.onUpdate()  // Ensures HomeView reloads
                                    }
                                }
                            }
                        }
                    } else {
                        print("Error: Appointment not found in array.")
                    }
                } else {
                    print("Error: Appointments array not found.")
                }
            } else if let error = error {
                print("Error fetching doctor document: \(error.localizedDescription)")
            }
        }
    }
}
/// ✅ Preview Example
//#Preview {
//    HomeView(doctor: DoctorModel(
//        id: "12345",
//        firstName: "John",
//        lastName: "Doe",
//        specialization: "Cardiologist",
//        phone: "123-456-7890",
//        email: "johndoe@example.com",
//        experience: "10",
//        degrees: ["MD", "PhD"],
//        medicalLicenseId: "MED123456",
//        bankAccountNumber: "9876543210",
//        address: "123 Main Street, City, Country"
//    ))
//}
private func formatAppointmentDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}
