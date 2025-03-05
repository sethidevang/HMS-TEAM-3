import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Charts

struct AdminDashboardView: View {
    let hospitalId: String
    @StateObject private var viewModel = AdminDashboardViewModel()
    @State private var timer: Timer?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(viewModel: viewModel)
                    .navigationTitle("Dashboard")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            
            NavigationStack {
                DoctorListView(hospitalId: hospitalId)
                    .navigationTitle("Doctors")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Doctors", systemImage: "stethoscope")
            }

            NavigationStack {
                AdminLeaveDashboard(hospitalId: hospitalId)
                    .navigationTitle("Leave")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Leave", systemImage: "calendar.badge.clock")
            }
            
            NavigationStack {
                AdminProfile(hospitalId: hospitalId)
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(Color.accentColor)
        .onAppear {
            fetchDashboardData()
            startAutoRefresh()
            
            // Set the tab bar appearance for iOS-native look
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }
    
    private func fetchDashboardData() {
        viewModel.fetchHospitalData(hospitalId: hospitalId)
        viewModel.fetchDoctorCount(hospitalId: hospitalId)
        viewModel.fetchLeaveCount(hospitalId: hospitalId)
    }

    private func startAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            fetchDashboardData()
        }
    }

    private func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hospital Name Header with Card
                VStack(spacing: 12) {
                    HStack {
                        Text(viewModel.hospitalName.isEmpty ? "Loading..." : viewModel.hospitalName)
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            Text(formattedDate())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                }
                .padding(.horizontal)
                
                // Financial Overview
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Financial Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("This Month")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        FinanceCard(title: "Total Revenue", amount: "$\(Int(viewModel.totalRevenue))", icon: "arrow.up.right.circle.fill", color: .green)
//                        FinanceCard(title: "Unpaid Dues", amount: "$\(Int(viewModel.unpaidDues))", icon: "exclamationmark.circle.fill", color: .blue)
                        FinanceCard(title: "Expenses", amount: "$\(Int(viewModel.expenses))", icon: "arrow.down.circle.fill", color: .red)
                    }
                    .padding(.horizontal)
                }
                
                // Activity Overview
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Activity Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            // Refresh data
                            fetchData()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ActivityCard(icon: "stethoscope", label: "\(viewModel.doctorCount)", description: "Doctors", color: .blue.opacity(0.2), systemColor: .blue)
                        ActivityCard(icon: "person.2.fill", label: "\(viewModel.patientCount)", description: "Patients", color: .green.opacity(0.2), systemColor: .green)
                        ActivityCard(icon: "calendar.badge.clock", label: "\(viewModel.leaveCount)", description: "Leave Applications", color: .orange.opacity(0.2), systemColor: .orange)
                        ActivityCard(icon: "cross.circle.fill", label: "\(viewModel.AmbulanceCount)", description: "Total Ambulances", color: .purple.opacity(0.2), systemColor: .purple)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .refreshable {
            fetchData()
        }
    }
    
    private func fetchData() {
        viewModel.fetchHospitalData(hospitalId: viewModel.hospitalId)
        viewModel.fetchDoctorCount(hospitalId: viewModel.hospitalId)
        viewModel.fetchLeaveCount(hospitalId: viewModel.hospitalId)
    }
}

// MARK: - ViewModel for Firestore Data Fetching
class AdminDashboardViewModel: ObservableObject {
    @Published var hospitalId: String = ""
    @Published var hospitalName: String = "Loading..."
    @Published var totalRevenue: Double = 0.0
    @Published var unpaidDues: Double = 0.0
    @Published var expenses: Double = 0.0
    @Published var doctorCount: Int = 0
    @Published var leaveCount: Int = 0
    @Published var patientCount: Int = 1 // Default placeholder value
    @Published var AmbulanceCount: Int = 50 // Default placeholder value

    private let db = Firestore.firestore()
    init() {
           listenToPatientCount()
        getAmbulanceCount()
       }

//    func fetchHospitalData(hospitalId: String) {
//        self.hospitalId = hospitalId
//        db.collection("hospitals").document(hospitalId).getDocument { document, error in
//            if let error = error {
//                print("Error fetching hospital data: \(error.localizedDescription)")
//                return
//            }
//
//            if let data = document?.data() {
//                DispatchQueue.main.async {
//                    self.hospitalName = data["name"] as? String ?? "Unknown Hospital"
//                    self.totalRevenue = data["totalRevenue"] as? Double ?? 0.0
//                    self.unpaidDues = data["unpaidDues"] as? Double ?? 0.0
//                    self.expenses = data["expenses"] as? Double ?? 0.0
//                    
//                    // Optional: fetch additional data if available
//                    self.patientCount = data["patientCount"] as? Int ?? 50
//                }
//            }
//        }
//    }

    func fetchDoctorCount(hospitalId: String) {
        db.collection("doctors").whereField("hospitalId", isEqualTo: hospitalId).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.doctorCount = snapshot?.documents.count ?? 0
            }
        }
    }

    func fetchLeaveCount(hospitalId: String) {
        db.collection("leaveRequests").whereField("hospitalId", isEqualTo: hospitalId).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.leaveCount = snapshot?.documents.count ?? 0
            }
        }
    }
    
    func fetchHospitalData(hospitalId: String) {
        self.hospitalId = hospitalId
        
        let hospitalRef = db.collection("hospitals").document(hospitalId)
        
        // Fetch hospital name
        hospitalRef.getDocument { document, error in
            if let error = error {
                print("Error fetching hospital data: \(error.localizedDescription)")
                return
            }
            
            if let data = document?.data() {
                DispatchQueue.main.async {
                    self.hospitalName = data["name"] as? String ?? "Unknown Hospital"
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
                self.totalRevenue = totalRevenue
                self.expenses = totalExpenses
            }
        }
    }
    func listenToPatientCount() {
        db.collection("patients").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching patient count: \(error.localizedDescription)")
                return
            }
            
            // Count the number of documents in the patients collection
            let count = snapshot?.documents.count ?? 0
            DispatchQueue.main.async {
                self.patientCount = count
            }
            
            print("Total Patients: \(count)")
        }
    }
    
    func getAmbulanceCount(){
        db.collection("emergencyBookings").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching patient count: \(error.localizedDescription)")
                return
            }
            
            // Count the number of documents in the patients collection
            let bookedCount = snapshot?.documents.count ?? 0
            let availableAmbulances = max(50 - bookedCount, 0)
            self.AmbulanceCount = availableAmbulances
            
            print("Total Patients: \(availableAmbulances)")
        }
    }

}

// MARK: - Finance Card
struct FinanceCard: View {
    var title: String
    var amount: String
    var icon: String
    var color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(amount)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Activity Card
struct ActivityCard: View {
    var icon: String
    var label: String
    var description: String
    var color: Color
    var systemColor: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(systemColor)
                    .padding(16)
                    .background(
                        Circle()
                            .fill(color)
                    )
                
                Spacer()
            }
            
            Text(label)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// Function to format date
func formattedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: Date())
}

// MARK: - Preview
struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AdminDashboardView(hospitalId: "dummyHospitalId")
                .preferredColorScheme(.light)
            
            AdminDashboardView(hospitalId: "dummyHospitalId")
                .preferredColorScheme(.dark)
        }
    }
}
