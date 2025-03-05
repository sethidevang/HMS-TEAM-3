import SwiftUI
import Firebase
import FirebaseAuth

struct BookAppointmentView: View {
    let doctor: DoctorModel
    @State private var selectedDate = Date()
    @State private var selectedSlot: String? = nil
    @State private var selectedPatient: String? = nil
    @State private var showPatientPicker = false
    @State private var showAlert = false
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode
    @State private var availableSlots: [(time: String, isBooked: Bool)] = []
    @ObservedObject var patientManager: PatientManager
    var patientEmail:String
    
    // Assume current user ID is available from Firebase Auth
    let currentUserId = AppointmentManager.shared.patientEmail
//    let doc = AppointmentManager.shared.doctor
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Doctor Info
                DoctorInfoView(doctor: doctor)
                
                // Patient Selection
                SelectionRow(title: "Select Patient", value: selectedPatient ?? "Select", action: {
                    showPatientPicker.toggle()
                })
                .actionSheet(isPresented: $showPatientPicker) {
                    ActionSheet(
                        title: Text("Select Patient"),
                        buttons: patientManager.patients.map { patient in
                            .default(Text(patient.name)) { selectedPatient = patient.name }
                        } + [.cancel()]
                    )
                }

                // Date Picker
                DatePickerSection(selectedDate: $selectedDate, onDateChange: fetchSlots)

                // Available Slots
                AvailableSlotsSection(availableTimeSlots: availableSlots, selectedSlot: $selectedSlot)

                // Book Button
                BookAppointmentButton()
            }
            .padding()
        }
        .background(Color(UIColor.systemGray6))
        .navigationTitle("Book Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Booking Successful"),
                message: Text("Your appointment has been added to the schedule."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            fetchSlots()
            fetchPatients()
        }
    }

    /// Fetches available slots from Firestore based on the selected date
    private func fetchSlots() {
        let db = Firestore.firestore()
        db.collection("doctor_schedules")
            .whereField("doctorId", isEqualTo: doctor.id)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("❌ Firestore Error: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("📌 No schedules found for doctor: \(doctor.id)")
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
    func fetchPatients() {
        print("Fetching patient with email: \(patientEmail)")
        // Ensure we have a non-empty email
        guard !patientEmail.isEmpty else {
            print("Patient email is empty. Skipping fetch.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("patients")
            .whereField("email", isEqualTo: patientEmail)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching patients: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No patient documents found.")
                    return
                }
                
                // For each document, create an array of Patient objects: parent's first, then each family member.
                let fetchedPatients = documents.flatMap { doc -> [Patient] in
                    let data = doc.data()
                    // Extract parent's details
                    guard let parentName = data["name"] as? String else { return [] }
                    let age = data["age"] as? String
                    let gender = data["gender"] as? String
                    let phoneNumber = data["phoneNumber"] as? String
                    let email = data["email"] as? String
                    let appointmentDate = data["appointmentDate"] as? String ?? "N/A"
                    let appointmentSlot = data["appointmentSlot"] as? String ?? "N/A"
                    let isCompleted = data["isCompleted"] as? Bool ?? false
                    
                    // Create the parent patient (index 0)
                    let parentPatient = Patient(name: parentName,
                                                age: age,
                                                gender: gender,
                                                phoneNumber: phoneNumber,
                                                email: email,
                                                appointmentDate: appointmentDate,
                                                appointmentSlot: appointmentSlot,
                                                isCompleted: isCompleted)
                    var results: [Patient] = [parentPatient]
                    
                    // If family_members exist, create a Patient for each member and append them
                    if let familyArray = data["family_members"] as? [[String: Any]] {
                        let familyPatients = familyArray.compactMap { familyDict -> Patient? in
                            guard let memberName = familyDict["name"] as? String else { return nil }
                            let memberAge = familyDict["age"] as? String
                            let memberGender = familyDict["gender"] as? String
                            let memberPhone = familyDict["phoneNumber"] as? String
                            return Patient(name: memberName,
                                           age: memberAge,
                                           gender: memberGender,
                                           phoneNumber: memberPhone,
                                           email: email,
                                           appointmentDate: appointmentDate,
                                           appointmentSlot: appointmentSlot,
                                           isCompleted: isCompleted)
                        }
                        results.append(contentsOf: familyPatients)
                    }
                    return results
                }
                
                DispatchQueue.main.async {
                    self.patientManager.patients = fetchedPatients
                }
            }
    }

    private func BookAppointmentButton() -> some View {
        Button(action: bookAppointment) {
            Text("Book Appointment")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(isButtonDisabled ? Color.gray : Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
        }
        .disabled(isButtonDisabled)
        .opacity(isButtonDisabled ? 0.5 : 1.0)
    }
    
    private var isButtonDisabled: Bool {
        return selectedSlot == nil || selectedPatient == nil
    }

    /// Books an appointment in Firestore and includes user ID + status
    private func bookAppointment() {
        guard let slot = selectedSlot, let patient = selectedPatient else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        // Step 1: Update appointment list inside doctor's document
        let appointmentData: [String: Any] = [
            "date": selectedDate,
            "time": slot,
            "patient": patient,
            "userId": currentUserId, // Sending user ID for doctor visibility
            "status": "Pending"
        ]
        
        let doctorRef = db.collection("doctors").document(doctor.id)
        
        doctorRef.updateData([
            "appointments": FieldValue.arrayUnion([appointmentData])
        ]) { error in
            if let error = error {
                print("Error booking appointment: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            // Step 2: Update slot as booked
            let scheduleRef = db.collection("doctor_schedules")
                .whereField("doctorId", isEqualTo: doctor.id)
            
            scheduleRef.getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching schedule: \(error.localizedDescription)")
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No schedule found for this doctor.")
                    isLoading = false
                    return
                }
                
                for document in documents {
                    let docRef = db.collection("doctor_schedules").document(document.documentID)
                    
                    var updatedSlots = (document.data()["slots"] as? [[String: Any]]) ?? []
                    for i in 0..<updatedSlots.count {
                        if updatedSlots[i]["time"] as? String == slot {
                            updatedSlots[i]["isBooked"] = true // Mark slot as booked
                        }
                    }
                    
                    // Step 3: Save updated slots to Firestore
                    docRef.updateData(["slots": updatedSlots]) { error in
                        isLoading = false
                        if let error = error {
                            print("Error updating slot: \(error.localizedDescription)")
                        } else {
                            showAlert = true
                            print("✅ Slot booked and marked as unavailable.")
                            fetchSlots() // Refresh available slots
                        }
                    }
                }
            }
        }
    }

}

// MARK: - Supporting Views

struct DoctorInfoView: View {
    let doctor: DoctorModel

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .foregroundColor(.gray)

            VStack(alignment: .leading) {
                Text(doctor.firstName + " " + doctor.lastName)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(doctor.specialization)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct DatePickerSection: View {
    @Binding var selectedDate: Date
    var onDateChange: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Choose Date")
                .font(.headline)
                .padding(.top, 5)

            let minDate = Date()
            let maxDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!

            DatePicker("Appointment Date", selection: $selectedDate, in: minDate...maxDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .onChange(of: selectedDate) { _ in
                    onDateChange()
                }
        }
    }
}


struct AvailableSlotsSection: View {
    let availableTimeSlots: [(time: String, isBooked: Bool)]
    @Binding var selectedSlot: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Available Slots")
                .font(.headline)

            if availableTimeSlots.isEmpty {
                Text("No available slots on this date.")
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(availableTimeSlots, id: \.time) { slot in
                        Button(action: {
                            if !slot.isBooked {
                                selectedSlot = slot.time
                            }
                        }) {
                            Text(slot.time)
                                .fontWeight(.semibold)
                                .foregroundColor(slot.isBooked ? .gray : (selectedSlot == slot.time ? .white : .blue))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(slot.isBooked ? Color.gray.opacity(0.5) : (selectedSlot == slot.time ? Color.blue : Color(UIColor.systemGray6)))
                                .cornerRadius(10)
                        }
                        .disabled(slot.isBooked)
                    }
                }
            }
        }
    }
}




struct AppointmentFeeSection: View {
    let fee: String
    
    var body: some View {
        HStack {
            Text("Appointment Fee:")
                .font(.headline)
            Spacer()
            Text(fee)
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

