import FirebaseFirestore
import FirebaseAuth



class AppointmentManager: ObservableObject {
    static let shared = AppointmentManager() // Shared instance
    
    @Published var scheduledAppointments: [Appointment] = []
    @Published var completedAppointments: [Appointment] = []
    @Published var canceledAppointments: [Appointment] = []
    @Published var doctorFeesDict: [String: String] = [:]
    @Published var appointments: [Appointment] = []
    @Published var availableSlots: [(time: String, isBooked: Bool)] = []
    var selectedAppointment: DoctorAppointment?
    private let db = Firestore.firestore()
    var patientEmail: String = ""

    func setPatientEmail(_ email: String) {
        self.patientEmail = email
        print(patientEmail)
        fetchAppointments()
    }
    
    
    func fetchAppointments() {
        guard !patientEmail.isEmpty else {
            print("❌ No patient email set. Cannot fetch appointments.")
            return
        }

        db.collection("doctors").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching doctors: \(error.localizedDescription)")
                return
            }
            
            guard let docs = snapshot?.documents else { return }
            
            var scheduled: [Appointment] = []
            var completed: [Appointment] = []
            var canceled: [Appointment] = []
            var feesDict: [String: String] = [:]
            
            for doc in docs {
                let doctorData = doc.data()
                let doctorName = doctorData["firstName"] as? String ?? "Unknown Doctor"
                let specialty = doctorData["specialization"] as? String ?? "General"
                let fees = doctorData["outpatientFees"] as? String ?? "N/A"
                feesDict[doctorName] = fees
                
                if let appointments = doctorData["appointments"] as? [[String: Any]] {
                    for dict in appointments {
                        guard let patientId = dict["userId"] as? String, patientId == self.patientEmail,
                              let date = (dict["date"] as? Timestamp)?.dateValue(),
                              let status = dict["status"] as? String, // ✅ Status from DB
                              let time = dict["time"] as? String else { continue }
                        
                        let appointment = Appointment(
                            doctorName: doctorName,
                            specialty: specialty,
                            appointmentDate: date.toFormattedString(),
                            appointmentSlot: time
                            
                        )
                        
                        if status == "Pending" {
                            scheduled.append(appointment)
                        } else if status == "Completed" {
                            completed.append(appointment)
                        } else {
                            canceled.append(appointment)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.scheduledAppointments = scheduled
                self.completedAppointments = completed
                self.canceledAppointments = canceled
                self.doctorFeesDict = feesDict
            }
        }
    }
    func cancelAppointment() {
        guard !patientEmail.isEmpty else {
            print("❌ No patient email set. Cannot cancel appointment.")
            return
        }

        guard let appointment = self.selectedAppointment else {
            print("❌ No appointment selected to cancel.")
            return
        }

        db.collection("doctors").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching doctors: \(error.localizedDescription)")
                return
            }

            guard let docs = snapshot?.documents else { return }

            for doc in docs {
                let doctorData = doc.data()
                let doctorFirstName = doctorData["firstName"] as? String ?? "Unknown Doctor"

                if doctorFirstName == appointment.doctorName {
                    if var appointments = doctorData["appointments"] as? [[String: Any]] {
                        
                        // Find the matching appointment
                        if let index = appointments.firstIndex(where: {
                            ($0["userId"] as? String) == self.patientEmail &&
                            ($0["time"] as? String) == appointment.appointmentSlot &&
                            ($0["date"] as? Timestamp)?.dateValue().toFormattedString() == appointment.appointmentDate
                        }) {
                            // ✅ Update only the status field
                            appointments[index]["status"] = "Canceled"

                            let doctorRef = self.db.collection("doctors").document(doc.documentID)

                            // ✅ Save the updated array back to Firestore
                            doctorRef.updateData(["appointments": appointments]) { error in
                                if let error = error {
                                    print("❌ Error updating appointment: \(error.localizedDescription)")
                                } else {
                                    print("✅ Appointment status updated to 'Canceled' successfully!")

                                    // ✅ Refresh UI
                                    DispatchQueue.main.async {
                                        self.fetchAppointments()
                                        self.updateSlotAvailability(doctorId: doc.documentID, date: (appointments[index]["date"] as! Timestamp).dateValue(), time: appointment.appointmentSlot)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    func updateSlotAvailability(doctorId: String, date: Date, time: String) {
        let db = Firestore.firestore()
        
        db.collection("doctor_schedules")
            .whereField("doctorId", isEqualTo: doctorId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching schedule: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📌 No schedules found for doctor: \(doctorId)")
                    return
                }
                
                for document in documents {
                    var slots = document.data()["slots"] as? [[String: Any]] ?? []
                    
                    // Check if the date matches
                    if let timestamp = document.data()["date"] as? Timestamp,
                       Calendar.current.isDate(timestamp.dateValue(), inSameDayAs: date) {
                        
                        // Find and update the matching slot
                        if let index = slots.firstIndex(where: { $0["time"] as? String == time }) {
                            slots[index]["isBooked"] = false  // Make slot available
                            
                            let scheduleRef = db.collection("doctor_schedules").document(document.documentID)
                            scheduleRef.updateData(["slots": slots]) { error in
                                if let error = error {
                                    print("❌ Error updating slot: \(error.localizedDescription)")
                                } else {
                                    print("✅ Slot \(time) on \(date) is now available!")
                                    DispatchQueue.main.async {
                                        self.fetchSlots(for: doctorId, selectedDate: date)

// Refresh available slots in UI
                                    }
                                }
                            }
                            return
                        }
                    }
                }
            }
    }
    func fetchSlots(for doctorId: String, selectedDate: Date) {
        let db = Firestore.firestore()
        db.collection("doctor_schedules")
            .whereField("doctorId", isEqualTo: doctorId)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("❌ Firestore Error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("📌 No schedules found for doctor: \(doctorId)")
                    DispatchQueue.main.async {
                        self.availableSlots = []
                    }
                    return
                }
                
                var slots: [(time: String, isBooked: Bool)] = []
                
                for document in documents {
                    if let timestamp = document.data()["date"] as? Timestamp {
                        let scheduleDate = timestamp.dateValue()
                        
                        if Calendar.current.isDate(scheduleDate, inSameDayAs: selectedDate) {
                            print("✅ Found schedule for selected date: \(scheduleDate)")
                            
                            if let slotsArray = document.data()["slots"] as? [[String: Any]] {
                                for slot in slotsArray {
                                    if let time = slot["time"] as? String,
                                       let isBooked = slot["isBooked"] as? Bool {
                                        slots.append((time: time, isBooked: isBooked))
                                    }
                                }
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.availableSlots = slots.sorted { $0.time < $1.time }
                    print("🕐 Available Slots: \(self.availableSlots)")
                }
            }
    }


    
    func addAppointment(_ appointment: Appointment, forDoctor doctorId: String) {
        guard !patientEmail.isEmpty else {
            print("❌ No patient email set. Cannot book appointment.")
            return
        }

        let patientsRef = db.collection("patients").whereField("email", isEqualTo: patientEmail)
        
        patientsRef.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching patient details: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("❌ No patient found with the given email.")
                return
            }
            
            let patientName = document.data()["name"] as? String ?? "Unknown"

            let appointmentData: [String: Any] = [
                "userId": self.patientEmail,
                "patient": patientName, // Include fetched patient name
                "date": Timestamp(date: Date()), // Use selectedDate if available
                "time": appointment.appointmentSlot,
                "status": "Pending"
            ]

            let doctorRef = self.db.collection("doctors").document(doctorId)

            doctorRef.updateData([
                "appointments": FieldValue.arrayUnion([appointmentData])
            ]) { error in
                if let error = error {
                    print("❌ Error adding appointment: \(error.localizedDescription)")
                } else {
                    print("✅ Appointment booked successfully!")
                    DispatchQueue.main.async {
                        self.scheduledAppointments.append(appointment)
                    }
                }
            }
        }
    }

    
    
    
    
        

}



    
extension Date {
    func toFormattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
