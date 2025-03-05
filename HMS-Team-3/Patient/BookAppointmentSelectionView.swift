import SwiftUI
import FirebaseFirestore
//import FirebaseFirestoreSwift

// Shared Patient Manager
class PatientManager: ObservableObject {
    // You can remove this shared instance if you're always passing your own instance.
     public static var shared = PatientManager()
    @Published var patients: [Patient] = [
//        Patient(name: "Devang", age: "21", gender: "Male", appointmentDate: "21", appointmentSlot: "1", isCompleted: true)
    ]
}


// Book Appointment View
struct BookAppointmentSelectionView: View {
    @ObservedObject var patientManager: PatientManager
    var patientEmail: String
    
    // Call this to fetch patients based on patientEmail and update patientManager.patients
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

    


    @State private var doctorFees: [String: Double] = [:]
    
    @State private var selectedPatient: String? = nil
    @State private var selectedSpecialty: String? = nil
    @State private var selectedDate: Date = Date()
    @State private var showPatientPicker: Bool = false
    @State private var showSpecialtyPicker: Bool = false
    @State private var doctors: [DoctorModel] = []
    @State private var specializations: [String] = []  // Specializations from Firestore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // Select Patient
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
                
                // Select Specialty (Fetched from Firestore)
                SelectionRow(title: "Select Specialty", value: selectedSpecialty ?? "Select", action: {
                    showSpecialtyPicker.toggle()
                })
                .onAppear {
                    fetchSpecializations() // Fetch specializations when view loads
                }
                .actionSheet(isPresented: $showSpecialtyPicker) {
                    ActionSheet(
                        title: Text("Select Specialty"),
                        buttons: specializations.map { specialty in
                            .default(Text(specialty)) {
                                selectedSpecialty = specialty
                                fetchDoctors(for: specialty) // Fetch doctors dynamically
                            }
                        } + [.cancel()]
                    )
                }
                
                // Select Date
                VStack(alignment: .leading) {
                    Text("Select Date")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    let minDate = Date()
                    let maxDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
                    
                    DatePicker("Appointment Date", selection: $selectedDate, in: minDate...maxDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Show Doctors
                if selectedPatient != nil, selectedSpecialty != nil {
                    Text("Available Doctors")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                    
                    if doctors.isEmpty {
                        Text("No doctors available for this specialty.")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        VStack(spacing: 10) {
                            ForEach(doctors, id: \.id) { doctor in
                                DoctorCardView(doctor: doctor, selectedDate: selectedDate, fee: doctorFees[doctor.id] ?? 0.0)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .background(Color(UIColor.systemGray6))
        .navigationTitle("Book Appointment")
        .navigationBarTitleDisplayMode(.inline)
        // Call fetchPatients() when the view appears so that the patients array gets updated
        .onAppear {
            fetchPatients()
        }
    }
    
    // Fetch doctors dynamically from Firestore based on selected specialty
    func fetchDoctors(for specializationName: String) {
        let db = Firestore.firestore()
        db.collection("doctors")
            .whereField("specialization", isEqualTo: specializationName)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching doctors: \(error)")
                    return
                }
                
                self.doctors = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    
                    guard let id = doc.documentID as String?,
                          let firstName = data["firstName"] as? String,
                          let lastName = data["lastName"] as? String,
                          let specialization = data["specialization"] as? String,
                          let phone = data["phone"] as? String,
                          let email = data["email"] as? String,
                          let experience = data["experience"] as? String,
                          let degrees = data["degrees"] as? [String],
                          let medicalLicenseId = data["medicalLicenseId"] as? String,
                          let bankAccountNumber = data["bankAccountNumber"] as? String,
                          let address = data["address"] as? String else {
                        return nil
                    }
                    
                    let fees = data["fees"] as? Double ?? 0.0
                    
                    let doctor = DoctorModel(
                        id: id,
                        firstName: firstName,
                        lastName: lastName,
                        specialization: specialization,
                        phone: phone,
                        email: email,
                        experience: experience,
                        degrees: degrees,
                        medicalLicenseId: medicalLicenseId,
                        bankAccountNumber: bankAccountNumber,
                        address: address
                    )
                    
                    self.doctorFees[id] = fees
                    return doctor
                } ?? []
            }
    }
    
    // Fetch unique specializations from Firestore
    func fetchSpecializations() {
        let db = Firestore.firestore()
        db.collection("specializations")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching specializations: \(error)")
                    return
                }
                
                self.specializations = snapshot?.documents.compactMap { doc in
                    doc["name"] as? String
                } ?? []
            }
    }
}


// MARK: - Selection Row Component
struct SelectionRow: View {
    var title: String
    var value: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.black)
                Spacer()
                Text(value)
                    .foregroundColor(.blue)
                Image(systemName: "chevron.down")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
    }
}

// MARK: - Doctor Card View
struct DoctorCardView: View {
    let doctor: DoctorModel
    let selectedDate: Date
    let fee: Double
    var body: some View {
        NavigationLink(destination: BookView(doctor: doctor, selectedDate: selectedDate)) {
            HStack(spacing: 16) {
                Image(systemName: "person.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(doctor.firstName) \(doctor.lastName)")
                        .font(.headline)
                    Text(doctor.specialization)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("Exp: \(doctor.experience) years")
                            .foregroundColor(.black)
                    }
                    .font(.subheadline)
                    Text("Fee: ₹\(fee, specifier: "%.2f")")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.gray.opacity(0.2), radius: 1, x: 0, y: 2)
        }
    }
}

// Preview
struct BookAppointmentSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Use the same instance for both patientManager and in the actionSheet
            BookAppointmentSelectionView(patientManager: PatientManager(), patientEmail: "9")
        }
    }
}
