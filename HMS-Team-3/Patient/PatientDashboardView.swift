import SwiftUI
import FirebaseFirestore



struct PatientDashboardView: View {
    @State private var showEmergencyAlert: Bool = false
    var hospitalName: String
    @State private var isScrolled = false
    var hospitalLocation: String
    let patientEmail: String
    let specializationIcons: [String: String] = [
        "General":"stethoscope",
        "General Medicine": "stethoscope",
        "Nephrology": "drop.fill",
        "Nephrologist": "drop.fill",
        "Cardiology": "heart.fill",
        "Cardiologist": "heart.fill",
        "Neurology": "brain.head.profile",
        "Neurologist": "brain.head.profile",
        "Dentistry": "mouth.fill",
        "Dentist": "mouth.fill",
        "Obstetrics and Gynecology": "person.2.fill",
        "OB-GYN": "person.2.fill",
        "Pediatrics": "figure.child",
        "Pediatrician": "figure.child",
        "Surgery": "scissors",
        "Surgeon": "scissors",
        "Orthopedics": "figure.walk",
        "Orthopedic": "figure.walk",
        "Dermatology": "sun.max.fill",
        "Dermatologist": "sun.max.fill",
        "ENT": "ear.fill",
        "ENT Specialist": "ear.fill",
        "Psychiatry": "brain",
        "Psychiatrist": "brain",
        "Ophthalmology": "eye.fill",
        "Ophthalmologist": "eye.fill",
        "Endocrinology": "drop.circle.fill",
        "Endocrinologist": "drop.circle.fill",
        "Urology": "bolt.heart.fill",
        "Urologist": "bolt.heart.fill",
        "Oncology": "stethoscope",
        "Oncologist": "stethoscope",
        "Pulmonology": "lungs.fill",
        "Pulmonologist": "lungs.fill",
        "Gastroenterology": "rectangle.portrait.and.arrow.right.fill",
        "Gastroenterologist": "rectangle.portrait.and.arrow.right.fill",
        "Hematology": "drop.triangle.fill",
        "Hematologist": "drop.triangle.fill",
        "Rheumatology": "figure.wave",
        "Rheumatologist": "figure.wave",
        "Anesthesiology": "bed.double.fill",
        "Anesthesiologist": "bed.double.fill",
        "Radiology": "waveform.path.ecg",
        "Radiologist": "waveform.path.ecg",
        "Pathology": "testtube.2",
        "Pathologist": "testtube.2",
        "Immunology": "allergens",
        "Immunologist": "allergens",
        "Neurosurgery": "brain.filled.head.profile",
        "Neurosurgeon": "brain.filled.head.profile",
        "Plastic Surgery": "person.crop.rectangle",
        "Plastic Surgeon": "person.crop.rectangle",
        "Thoracic Surgery": "lungs.fill",
        "Thoracic Surgeon": "lungs.fill",
        "Hepatology": "pills.fill",
        "Hepatologist": "pills.fill",
        "Toxicology": "exclamationmark.triangle.fill",
        "Toxicologist": "exclamationmark.triangle.fill",
        "Geriatrics": "figure.older",
        "Geriatrician": "figure.older",
        "Podiatry": "shoe.fill",
        "Podiatrist": "shoe.fill",
        "Otolaryngology": "ear",
        "Otolaryngologist": "ear",
        "Sports Medicine": "figure.run",
        "Sports Physician": "figure.run",
        "Emergency Medicine": "cross.fill",
        "Emergency Physician": "cross.fill",
        "Intensive Care": "bed.double.circle.fill",
        "Critical Care Medicine": "bed.double.circle.fill",
        "Neonatology": "figure.baby",
        "Neonatologist": "figure.baby"
    ]

    @State private var hospitalId: String = ""
    @State private var specializations: [SpecializationModel] = []
    @State private var doctors: [DoctorModel] = []
    @State private var earliestAppointment: Appointment?
    @State private var appointmentFee: String = "0"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Upcoming Appointment Section
                    upcomingAppointmentSection
                    
                    // Specialties Section
                    specialtiesHeaderSection
                    
                    // Specialties Grid
                    specialtiesGridSection
                    
                    // Doctors Section
                    doctorsHeaderSection
                    
                    // Doctors List
                    doctorsListSection
                    
                    // Health Initiatives Section
                    healthInitiativesSection
                }
                .padding(.vertical)
            }
            // Setting ScrollOffsetKey preference
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: geo.frame(in: .global).minY
                    )
                }
            )
            .navigationTitle(hospitalName)
            .navigationBarTitleDisplayMode(.automatic)
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                isScrolled = value < -50
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: isScrolled ? 0 : 2) {
                        Text(hospitalLocation)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .opacity(isScrolled ? 0 : 1)
                    }
                    .animation(.easeInOut(duration: 0.3), value: isScrolled)
                }
            }
            .background(Color(UIColor.systemGray6))
            .refreshable {
                fetchHospitalId(from: hospitalName, location: hospitalLocation) { id in
                    if let id = id {
                        self.hospitalId = id
                        fetchSpecializations(for: id)
                        fetchDoctors(for: id)
                    }
                }
                fetchEarliestAppointment()
            }
            .onAppear {
                fetchHospitalId(from: hospitalName, location: hospitalLocation) { id in
                    if let id = id {
                        self.hospitalId = id
                        fetchSpecializations(for: id)
                        fetchDoctors(for: id)
                    }
                }
                fetchEarliestAppointment()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showEmergencyAlert = true
                    }) {
                        Image(systemName: "cross.circle.fill")
                            .foregroundColor(.red)
                    }
                    .alert("Emergency", isPresented: $showEmergencyAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Book", role: .destructive) {
                            bookEmergencyAmbulance(for: patientEmail)
                        }
                    } message: {
                        Text("You are about to book an ambulance. Are you sure you want to proceed?")
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var upcomingAppointmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Appointment")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let appointment = earliestAppointment {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dr. \(appointment.doctorName)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(appointment.specialty)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("₹\(appointmentFee)")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Divider()
                    
                    HStack {
                        Label(appointment.appointmentDate, systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Label(appointment.appointmentSlot, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                Text("No upcoming appointments")
                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity) // Full width
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth:.infinity)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        .padding()
    }
    
    private var specialtiesHeaderSection: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack {
                Text("Specialties")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            
            NavigationLink(destination: Specialization(specializations: specializations, doctors: doctors,patientEmail: patientEmail)) {
                Text("See All")
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal)
    }
    
    private var specialtiesGridSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
            ForEach(specializations.prefix(8), id: \.name) { specialization in
                SpecialtyCard(
                    specialization: specialization,
                    doctors: doctors,
                    patientEmail: patientEmail
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var doctorsHeaderSection: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack {
                Text("Doctors")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            
            NavigationLink(destination: DoctorList(doctors: doctors, patientEmail: patientEmail)) {
                Text("See All")
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal)
    }
    
    private var doctorsListSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(doctors.prefix(4), id: \.id) { doctor in
                    NavigationLink(destination: PatientDoctorDetailView(doctor: doctor, patientEmail: patientEmail)) {
                        DoctorCard(doctor: doctor)
                            .frame(width: 200, height: 260)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 10)
            .padding(.horizontal)
        }
    }
    
    private var healthInitiativesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Our Latest Health Initiatives")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                HealthInitiativeCard(title: "360° Woodlands Healthcare", description: "Comprehensive healthcare solutions.", systemImage: "stethoscope")
                HealthInitiativeCard(title: "Advanced Cardiac Care", description: "Hospital in Surat", systemImage: "heart.text.square.fill")
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Data Fetching Methods
    
    func fetchHospitalId(from name: String, location: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("hospitals")
            .whereField("name", isEqualTo: name)
            .whereField("location", isEqualTo: location)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching hospitalId: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("❌ No hospital found for name: \(name) & location: \(location)")
                    completion(nil)
                    return
                }
                
                let hospitalId = document.documentID
                completion(hospitalId)
            }
    }
    
    func fetchDoctors(for hospitalId: String) {
        let db = Firestore.firestore()
        db.collection("doctors")
            .whereField("hospitalId", isEqualTo: hospitalId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching doctors: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                
                self.doctors = documents.compactMap { doc -> DoctorModel? in
                    let data = doc.data()
                    guard let firstName = data["firstName"] as? String,
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
                    return DoctorModel(
                        id: doc.documentID,
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
                }
            }
    }
    
    func fetchSpecializations(for hospitalId: String) {
        let db = Firestore.firestore()
        
        db.collection("specializations")
            .whereField("hospitalId", isEqualTo: hospitalId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching specializations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ No specializations found for hospitalId: \(hospitalId)")
                    return
                }
                
                let fetchedSpecializations = documents.compactMap { doc -> SpecializationModel? in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String else {
                        return nil
                    }
                    
                    let imageName = specializationIcons[name] ?? "questionmark.circle"
                    
                    return SpecializationModel(name: name, description: description, imageName: imageName)
                }
                
                DispatchQueue.main.async {
                    self.specializations = fetchedSpecializations
                }
            }
    }
    
    func fetchEarliestAppointment() {
        let db = Firestore.firestore()
        let currentDateLocal = Calendar.current.startOfDay(for: Date())

        db.collection("doctors").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching doctors: \(error.localizedDescription)")
                return
            }

            var matchedAppointments: [(Appointment, String, Date)] = []

            for document in snapshot?.documents ?? [] {
                let doctorData = document.data()
                let doctorName = doctorData["firstName"] as? String ?? "Unknown"
                let specialty = doctorData["specialization"] as? String ?? "Unknown"
                let fee = doctorData["outpatientFees"] as? String ?? "0"

                if let appointments = doctorData["appointments"] as? [[String: Any]] {
                    for appointment in appointments {
                        if let userId = appointment["userId"] as? String,
                           userId == patientEmail,
                           let dateTimestamp = appointment["date"] as? Timestamp,
                           let status = appointment["status"] as? String, status.lowercased() == "pending",
                           let time = appointment["time"] as? String {

                            let appointmentDateUTC = dateTimestamp.dateValue()
                            let appointmentDateLocal = Calendar.current.startOfDay(for: appointmentDateUTC)

                            print("📆 Found Appointment: \(appointmentDateLocal) for user \(userId)")

                            if appointmentDateLocal >= currentDateLocal {
                                let appointmentModel = Appointment(
                                    doctorName: doctorName,
                                    specialty: specialty,
                                    appointmentDate: dateFormatter.string(from: appointmentDateUTC),
                                    appointmentSlot: time
                                )
                                matchedAppointments.append((appointmentModel, fee, appointmentDateLocal))
                            }
                        }
                    }
                }
            }

            if let earliest = matchedAppointments.min(by: { $0.2 < $1.2 }) {
                DispatchQueue.main.async {
                    self.earliestAppointment = earliest.0
                    self.appointmentFee = earliest.1
                }
                print("✅ Earliest Appointment: \(earliest.0.appointmentDate)")
            } else {
                print("❌ No upcoming appointments found")
                DispatchQueue.main.async {
                    self.earliestAppointment = nil
                    self.appointmentFee = ""
                }
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }
    
    func bookEmergencyAmbulance(for patientEmail: String) {
        let db = Firestore.firestore()
        let currentDate = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd" // Format for storing only the date
        let formattedDate = dateFormatter.string(from: currentDate)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss" // Format for storing only the time
        let formattedTime = timeFormatter.string(from: currentDate)
        
        let bookingData: [String: Any] = [
            "ambulanceRequired": true,
            "patientEmail": patientEmail,
            "bookingDate": formattedDate,  // Storing as "YYYY-MM-DD"
            "bookingTime": formattedTime   // Storing as "HH:MM:SS"
        ]
        
        db.collection("emergencyBookings").addDocument(data: bookingData) { error in
            if let error = error {
                print("Error saving emergency booking: \(error.localizedDescription)")
            } else {
                print("Emergency booking stored successfully!")
            }
        }
    }

}

// MARK: - Supporting Structs

struct SpecialtyCard: View {
    let specialization: SpecializationModel
    let doctors: [DoctorModel]
    let patientEmail: String
    
    var body: some View {
        NavigationLink(destination: SpecialisationDoctorView(specialization: specialization, patientEmail: patientEmail)) {
            VStack {
                Image(systemName: specialization.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(specialization.name)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 70)
            }
        }
    }
}

//struct DoctorCard: View {
//    let doctor: DoctorModel
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            VStack(alignment: .center) {
//                Image(systemName: "person.circle.fill")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 80, height: 80)
//                    .foregroundColor(.blue)
//            }
//            .frame(maxWidth: .infinity)
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Dr. \(doctor.firstName) \(doctor.lastName)")
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                
//                Text(doctor.specialization)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                HStack {
//                    Image(systemName: "star.fill")
//                        .foregroundColor(.yellow)
//                    
//                    Text("4.8")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    Text("(\(Int.random(in: 50...200)))")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//        }
//        .frame(width: 160, height: 180)
//        .padding()
//        .background(Color(.systemBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
//    }
//}

struct HealthInitiativeCard: View {
    var title: String
    var description: String
    var systemImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
                    .padding(10)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .frame(height: 180)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Placeholder views for the navigation destinations

#Preview {
    PatientDashboardView(hospitalName: "HMS", hospitalLocation: "INDIA", patientEmail: "patient@gmail.com")
}
