import SwiftUI
import Firebase
import FirebaseAuth
struct PatientDetailView: View {
    @State var patient: Patient  // Make the patient mutable with @State
    @State private var showAllRecords = false
    var onAppointmentEnd: () -> Void  // Callback to notify when the appointment ends
    @Environment(\.dismiss) var dismiss  // Dismiss the current view to go back to the previous screen
    var doctorId: String
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Patient Details")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)

                    DetailField(label: "Name", value: patient.name)
                    DetailField(label: "Age", value: patient.age ?? "NA")
                    DetailField(label: "Gender", value: patient.gender ?? "NA")
//                    DetailField(label: "Appointment Date", value: patient.appointmentDate)
                    DetailField(label: "Appointment Slot", value: patient.appointmentSlot)

                    

                    // End Appointment Button (if it's an upcoming appointment)
                    if !patient.isCompleted {
                        Button(action: {
                            endAppointment()
                        }) {
                            Text("End Appointment")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 5)
                    }
                    
                    // Past Records Section
//                    HStack {
//                        Text("Past Records")
//                            .font(.headline)
//                            .padding(.top)
//
//                        Spacer()
//
//                        NavigationLink(destination: ViewAllPastRecordsView(records: pastRecords)) {
//                            Text("View All")
//                                .font(.caption)
//                                .foregroundColor(.blue)
//                                .padding(.top, 5)
//                        }
//                    }
//
//                    if showAllRecords {
//                        ForEach(pastRecords, id: \.id) { record in
//                            DetailField(label: record.date, value: "\(record.doctorName) - \(record.specialization)")
//                        }
//                    } else {
//                        if let latestRecord = pastRecords.first {
//                            DetailField(label: latestRecord.date, value: "\(latestRecord.doctorName) - \(latestRecord.specialization)")
//                        }
//                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Patient Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }

    func endAppointment() {
        let db = Firestore.firestore()
        let doctorRef = db.collection("doctors").document(doctorId)

        doctorRef.getDocument { document, error in
            if let document = document, document.exists {
                if var data = document.data(), var appointmentsArray = data["appointments"] as? [[String: Any]] {
                    
                    // Find the appointment in the array
                    if let index = appointmentsArray.firstIndex(where: { $0["userId"] as? String == patient.email && $0["time"] as? String == patient.appointmentSlot }) {
                        
                        // Update the status to "Completed"
                        appointmentsArray[index]["status"] = "Completed"

                        // Save the updated appointments array back to Firestore
                        doctorRef.updateData(["appointments": appointmentsArray]) { error in
                            if let error = error {
                                print("Error updating appointment: \(error.localizedDescription)")
                            } else {
                                print("✅ Appointment marked as Completed")
                                
                                // ✅ Update local UI
                                DispatchQueue.main.async {
                                    patient.isCompleted = true
                                    onAppointmentEnd() // Notify parent view
                                    dismiss() // Dismiss current view
                                }
                            }
                        }
                    } else {
                        print("❌ Appointment not found in Firestore")
                    }
                }
            } else if let error = error {
                print("Error fetching doctor appointments: \(error.localizedDescription)")
            }
        }
    }

}



// MARK: - Past Record Model
struct PastRecord: Identifiable {
    let id = UUID()
    let date: String
    let details: String
    let hospitalName: String
    let doctorName: String
    let specialization: String
}

// Sample Past Records Data
let pastRecords = [
    PastRecord(date: "10 Jan 2025", details: "Routine Checkup - No Issues", hospitalName: "City Hospital", doctorName: "Dr. Smith", specialization: "General Physician"),
    PastRecord(date: "15 Dec 2024", details: "Follow-up for blood pressure", hospitalName: "City Hospital", doctorName: "Dr. Johnson", specialization: "Cardiologist"),
    PastRecord(date: "20 Nov 2024", details: "Annual Physical Exam", hospitalName: "Greenfield Clinic", doctorName: "Dr. Lee", specialization: "General Physician")
]

// MARK: - Patient Model


// Sample Patients Data
var upcomingPatientsData: [Patient] = [
    Patient(name: "John Doe", age: "35", gender: "Male", appointmentDate: "20 Feb 2025", appointmentSlot: "10:15 AM", isCompleted: false),
    Patient(name: "Jane Smith", age: "29", gender: "Female", appointmentDate: "21 Feb 2025", appointmentSlot: "11:30 AM", isCompleted: false)
]

var completedPatientsData: [Patient] = [
    Patient(name: "Emily Clark", age: "38", gender: "Female", appointmentDate: "15 Feb 2025", appointmentSlot: "9:00 AM", isCompleted: true),
    Patient(name: "Robert Brown", age: "50", gender: "Male", appointmentDate: "14 Feb 2025", appointmentSlot: "3:45 PM", isCompleted: true)
]


// MARK: - View for Past Records
struct ViewAllPastRecordsView: View {
    let records: [PastRecord]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("All Past Records")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()

                ForEach(records, id: \.id) { record in
                    DetailField(label: record.date, value: "\(record.doctorName) - \(record.specialization)")
                }
            }
            .padding()
        }
        .navigationTitle("Past Records")
    }
}
struct DetailField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
