
import SwiftUI
import FirebaseFirestore
struct MainTabView: View {
    let hospitalLocation : String
    let patientEmail : String
    @State private var hospitalName: String = "loading"
//    let hospitalName : String = "hello"


    /// **Fetch hospital name from Firestore based on location and return as a String**
    func fetchHospitalName(from location: String, completion: @escaping (String) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("hospitals")
            .whereField("location", isEqualTo: hospitalLocation)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching hospital: \(error.localizedDescription)")
                    completion("Error fetching hospital")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("❌ No hospital found for location: \(location)")
                    completion("No hospital found")
                    return
                }

                // Fetch hospital name from the first matching document
                let fetchedHospitalName = documents.first?.data()["name"] as? String ?? "Unknown Hospital"
                
                completion(fetchedHospitalName) // ✅ Return hospital name
            }
    }

    //func to fetch hospital name from location
    @State private var medicalRecords: [Record] = [
        Record(hospitalName: "City Hospital", doctorName: "Dr. John Doe", specialization: "Cardiology", date: "2025-02-18", prescriptionURL: "https://example.com", billAmount: nil)
    ]
    
    @State private var billRecords: [Record] = [
        Record(hospitalName: "City Hospital", doctorName: "Dr. John Doe", specialization: nil, date: "2025-02-18", prescriptionURL: nil, billAmount: "500")
    ]
    @StateObject private var appointmentManager = AppointmentManager()

    
    
    var body: some View {
        TabView {
            NavigationStack {
                PatientDashboardView(hospitalName: hospitalName, hospitalLocation: hospitalLocation , patientEmail : patientEmail)
                    .onAppear {  // ✅ Fetch when Dashboard appears
                        fetchHospitalName(from: hospitalLocation) { name in
                            DispatchQueue.main.async {
                                self.hospitalName = name
                            }
                        }
                    }
            }
            .tabItem { Label("Dashboard", systemImage: "house.fill") }

            NavigationStack {
                Appointments(patientEmail:patientEmail)
                    .environmentObject(appointmentManager) // ✅ Inject here
            }
            .tabItem { Label("Appointments", systemImage: "calendar.badge.clock") }

            NavigationStack {
                RecordsView(medicalRecords: .constant([]), billRecords: .constant([]))
            }
            .tabItem { Label("Records", systemImage: "folder.fill") }

            NavigationStack {
                ProfileView(patientEmail: patientEmail)
            }
            .tabItem { Label("Profile", systemImage: "person.fill") }
        }
    }
    
}


#Preview {
    Group{
        MainTabView(hospitalLocation: "Bihar", patientEmail: "shivamdubey177@gmail.com")
            .preferredColorScheme(.dark)
    }
        
}


