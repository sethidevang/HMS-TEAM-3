import SwiftUI
import FirebaseFirestore
import Charts
import SwiftSMTP

class HospitalViewModel: ObservableObject {
    @Published var hospital: Hospital
    private let db = Firestore.firestore()
    
    init(hospital: Hospital) {
        self.hospital = hospital
        fetchUpdatedHospitalData()
    }

    func fetchUpdatedHospitalData() {
        guard let hospitalId = hospital.id else { return }

        db.collection("hospitals").document(hospitalId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching hospital data: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                // Break down complex expressions
                self.updateHospitalInfo(from: data)
                self.updateAdminInfo(from: data)
            }
        }
    }
    func fetchHospitalData(hospitalId: String) {
        self.hospital.id = hospitalId
        
        let hospitalRef = db.collection("hospitals").document(hospitalId)
        
        // Fetch hospital name
        hospitalRef.getDocument { document, error in
            if let error = error {
                print("Error fetching hospital data: \(error.localizedDescription)")
                return
            }
            
            if let data = document?.data() {
                DispatchQueue.main.async {
                    self.hospital.name = data["name"] as? String ?? "Unknown Hospital"
                }
            }
        }
        
        // Fetch total revenue by iterating through all doctors
        db.collection("doctors").whereField("hospitalId", isEqualTo: hospitalId).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching doctors: \(error.localizedDescription)")
                return
            }
            
            var totalRevenue: Double = 0.0
            var totalExpenses: Double = 0.0
            
            for document in snapshot?.documents ?? [] {
                let doctorData = document.data()
                let doctorId = document.documentID
                
                // Convert fee from String to Double
                let doctorFeeString = doctorData["outpatientFees"] as? String ?? "0"
                let doctorFee = Double(doctorFeeString) ?? 0.0
                
                let appointments = doctorData["appointments"] as? [[String: Any]] ?? []
                let salaryString = doctorData["salary"] as? String ?? "0"
                let doctorSalary = Double(salaryString.replacingOccurrences(of: ",", with: ".")) ?? 0.0  // ✅ Convert salary properly

                // Debugging prints
                print("Doctor ID: \(doctorId), Fee: \(doctorFeeString) -> Converted Fee: \(doctorFee)")
                print("Total Appointments: \(appointments.count)")
                
                let completedAppointments = appointments.filter {
                    let status = $0["status"] as? String ?? ""
                    return status == "Completed"
                }.count
                
                print("Completed Appointments for Doctor \(doctorId): \(completedAppointments)")
                
                totalRevenue += Double(completedAppointments) * doctorFee
                totalExpenses += doctorSalary
            }
            
            print("Final Total Revenue: \(totalRevenue)")
            
            DispatchQueue.main.async {
                self.hospital.revenue = "\(totalRevenue)"
                self.hospital.expenses = "\(totalExpenses)"
            }
        }
    }
    
    // Breaking down complex expressions
    private func updateHospitalInfo(from data: [String: Any]) {
        self.hospital.name = data["name"] as? String ?? "Unknown"
        
        if let revenue = data["revenue"] as? Double {
            self.hospital.revenue = "$\(revenue)"
        } else {
            self.hospital.revenue = "$0"
        }
        
        if let unpaidDues = data["unpaidDues"] as? Double {
            self.hospital.unpaidDues = "$\(unpaidDues)"
        } else {
            self.hospital.unpaidDues = "$0"
        }
        
        if let expenses = data["expenses"] as? Double {
            self.hospital.expenses = "$\(expenses)"
        } else {
            self.hospital.expenses = "$0"
        }
    }
    
    private func updateAdminInfo(from data: [String: Any]) {
        guard let adminData = data["admin"] as? [String: Any] else { return }
        
        self.hospital.admin.name = adminData["name"] as? String ?? "Unknown"
        self.hospital.admin.email = adminData["email"] as? String ?? "Unknown"
        self.hospital.admin.address = adminData["address"] as? String ?? "Unknown"
        self.hospital.admin.phoneNumber = adminData["phoneNumber"] as? String ?? "Unknown"
    }
}

struct InfoCard: View {
    var title: String
    var value: String
    var color: Color
    var systemImage: String
    
    init(title: String, value: String, color: Color, systemImage: String = "dollarsign.circle") {
        self.title = title
        self.value = value
        self.color = color
        self.systemImage = systemImage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Breaking down complex HStack expressions
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Spacer()
        }
        // Breaking down complex frame and background modifiers
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 120)
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(cardBackground)
        .overlay(cardBorder(color: color))
    }
    
    // Breaking down complex view builders
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(UIColor.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func cardBorder(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(color.opacity(0.2), lineWidth: 1)
    }
}

struct HospitalDetailRow: View {
    var icon: String
    var title: String
    var value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 28, height: 28)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
    }
}

struct HospitalDetailView: View {
    @StateObject private var viewModel: HospitalViewModel
    @State private var isEditPresented = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @Environment(\.colorScheme) private var colorScheme
    
    
    init(hospital: Hospital) {
        _viewModel = StateObject(wrappedValue: HospitalViewModel(hospital: hospital))
    }
    
    private var backgroundColorSecondary: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray6)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Breaking down complex ScrollView and VStack
                scrollContent
                
                // Loading overlay
                if isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle(viewModel.hospital.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    editButton
                }
            }
            .sheet(isPresented: $isEditPresented, onDismiss: {
                viewModel.fetchUpdatedHospitalData()
            }) {
                EditHospital(hospital: $viewModel.hospital)
            }
            .onAppear {
                isLoading = true
                viewModel.fetchUpdatedHospitalData()
                viewModel.fetchHospitalData(hospitalId:viewModel.hospital.id ?? "0" )
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoading = false
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Email Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .refreshable {
                isLoading = true
                viewModel.fetchUpdatedHospitalData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoading = false
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    // Breaking down complex view components into properties
    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                financialOverviewSection
                
                Divider()
                    .padding(.horizontal)
                
                administrationSection
            }
            .padding(.vertical, 20)
        }
    }
    
    private var financialOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Overview")
                .font(.system(size: 20, weight: .semibold))
                .padding(.horizontal)
            
            // Breaking down complex LazyVGrid
            financialMetricsGrid
        }
    }
    
    private var financialMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // Revenue card
            InfoCard(
                title: "Revenue",
                value: viewModel.hospital.revenue ?? "$0",
                color: .green,
                systemImage: "arrow.up.circle.fill"
            )
            
            // Unpaid dues card
//            InfoCard(
//                title: "Unpaid",
//                value: viewModel.hospital.unpaidDues ?? "$0",
//                color: .blue,
//                systemImage: "hourglass.circle.fill"
//            )
            
            // Expenses card
            InfoCard(
                title: "Expenses",
                value: viewModel.hospital.expenses ?? "$0",
                color: .red,
                systemImage: "arrow.down.circle.fill"
            )
        }
        .padding(.horizontal)
    }
    
    private var administrationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Adminstration")
                .font(.system(size: 20, weight: .semibold))
                .padding(.horizontal)
            
            adminNavigationLink
            
            // Admin details card
            adminDetailsCard
        }
    }
    
    private var adminNavigationLink: some View {
        Group {
            if let hospitalId = viewModel.hospital.id {
                NavigationLink(destination: EditAdmin(admin: viewModel.hospital.admin, hospitalId: hospitalId)) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hospital Admin")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Manage administrator details")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground))
                    )
                    .padding(.horizontal)
                }
            } else {
                Text("Hospital ID is missing")
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(backgroundColorSecondary)
                    )
                    .padding(.horizontal)
            }
        }
    }
    
    private var adminDetailsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Admin Details")
                    .font(.headline)
                
                Spacer()
                
                contactButton
            }
            
            Divider()
            
            HospitalDetailRow(icon: "person.fill", title: "Name", value: viewModel.hospital.admin.name)
            HospitalDetailRow(icon: "envelope.fill", title: "Email", value: viewModel.hospital.admin.email)
            HospitalDetailRow(icon: "mappin.and.ellipse", title: "Address", value: viewModel.hospital.admin.address)
            HospitalDetailRow(icon: "phone.fill", title: "Phone", value: viewModel.hospital.admin.phoneNumber)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var contactButton: some View {
        Button(action: {
            if let hospitalId = viewModel.hospital.id {
                sendEmail(to: viewModel.hospital.admin.email, hospitalId: hospitalId) { success, message in
                    DispatchQueue.main.async {
                        alertMessage = message
                        showingAlert = true
                    }
                }
            } else {
                alertMessage = "Hospital ID is missing."
                showingAlert = true
            }
        }) {
            Label("Send Password", systemImage: "envelope.fill")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue)
                .cornerRadius(20)
        }
    }
    
    private var editButton: some View {
        Button {
            isEditPresented = true
        } label: {
            Text("Edit")
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.1)
                .edgesIgnoringSafeArea(.all)
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
        }
    }
}

// MARK: - Email Functions
func sendEmail(to email: String, hospitalId: String, completion: @escaping (Bool, String) -> Void) {
    // Improved email function with error handling
    let smtp = SMTP(
        hostname: "smtp.gmail.com",
        email: "sethidevangsethi@gmail.com",
        password: "pjwp uynj foxi rfov", // Note: Consider using environment variables or secure storage
        port: 465,
        tlsMode: .requireTLS
    )
    
    let randomPassword = generateRandomPassword()

    let from = Mail.User(name: "Hospital Team", email: "sethidevangsethi@gmail.com")
    let to = Mail.User(name: "User", email: email)
    
    let mail = Mail(
        from: from,
        to: [to],
        subject: "Login Credentials",
        text: "Your login details:\nEmail: \(email)\nPassword: \(randomPassword)"
    )
    
    smtp.send(mail) { error in
        if let error = error {
            completion(false, "Error sending email: \(error.localizedDescription)")
            return
        }
        
        // Save the generated password in Firestore
        savePasswordToFirestore(hospitalId: hospitalId, email: email, password: randomPassword, completion: completion)
    }
}

func savePasswordToFirestore(hospitalId: String, email: String, password: String, completion: @escaping (Bool, String) -> Void) {
    let db = Firestore.firestore()
    let adminRef = db.collection("hospitals").document(hospitalId)

    // Add timestamp for security tracking
    let updateData: [String: Any] = [
        "admin.password": password,
        "admin.passwordUpdatedAt": FieldValue.serverTimestamp(),
        "admin.email": email // Ensure email is consistent
    ]
    
    adminRef.updateData(updateData) { dbError in
        if let dbError = dbError {
            completion(false, "Email sent but failed to save password: \(dbError.localizedDescription)")
        } else {
            completion(true, "Email credentials sent successfully.")
        }
    }
}

func generateRandomPassword() -> String {
    // Improved password generation with more complexity
    let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
    let numbers = "0123456789"
    let specialCharacters = "!@#$%^&*()-_=+"
    
    let allCharacters = uppercaseLetters + lowercaseLetters + numbers + specialCharacters
    var password = ""
    
    // Ensure at least one character from each category
    password += String(uppercaseLetters.randomElement()!)
    password += String(lowercaseLetters.randomElement()!)
    password += String(numbers.randomElement()!)
    password += String(specialCharacters.randomElement()!)
    
    // Add additional random characters
    for _ in 0..<4 {
        password += String(allCharacters.randomElement()!)
    }
    
    // Shuffle the password characters
    return String(password.shuffled())
}

// MARK: - Preview
struct HospitalDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleHospital = Hospital(
            id: "1",
            name: "Sample Hospital",
            location: "New York",
            admin: Admin(
                id: "09", name: "John Doe",
                email: "admin@hospital.com",
                address: "123 Main St, NY",
                experience: "10 Years",
                phoneNumber: "(123) 456-7890"
            ),
            revenue: "$500,000",
            unpaidDues: "$50,000",
            expenses: "$200,000"
        )
        
        return NavigationStack {
            HospitalDetailView(hospital: sampleHospital)
        }
    }
}
