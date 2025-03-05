import SwiftUI
import Firebase
import FirebaseFirestore

struct DocTabCar: View {
    let doctorId: String
    let hospitalId: String
    @State private var doctorData: DoctorModel? = nil

    var body: some View {
        TabView {
            NavigationStack {
                if let doctor = doctorData {
                    HomeView(doctor: doctor) // ✅ Now correctly passing DoctorModel
                        .navigationTitle("Home")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    ProgressView("Loading...") // Show a loading indicator
                }
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Appointments")
            }
            NavigationStack{
                SetTimingsView(doctorId: doctorId)
                    .navigationTitle("Set Timings")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem{
                Image(systemName: "clock.fill")
                Text("Timings")
            }

            NavigationStack {
                    LeaveRequestView(doctorId: doctorId, hospitalId: hospitalId) // ⬅ No NavigationView inside
                        .navigationTitle("Leave Dashboard")
                        .navigationBarTitleDisplayMode(.large)
                }
                .tabItem {
                    Image(systemName: "briefcase.fill")
                    Text("Leave")
                }
            

            NavigationStack {
                if let doctor = doctorData {
                    SettingsView(doctor: doctor)
                        .navigationTitle("Profile")
                        .navigationBarTitleDisplayMode(.large)
                } else {
                    ProgressView("Loading...")
                }
            }
            .tabItem {
                Image(systemName: "person.circle.fill")
                Text("Profile")
            }
        }
        .onAppear {
            fetchDoctorDetails()
        }
    }

    /// Fetch doctor details from Firestore and map to DoctorModel
    func fetchDoctorDetails() {
        let db = Firestore.firestore()
        db.collection("doctors").document(doctorId).getDocument { document, error in
            if let error = error {
                print("Error fetching doctor data: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                let data = document.data() ?? [:]

                let doctor = DoctorModel(
                    id: document.documentID,
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    specialization: data["specialization"] as? String ?? "",
                    phone: data["phone"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    experience: data["experience"] as? String ?? "",
                    degrees: data["degrees"] as? [String] ?? [],
                    medicalLicenseId: data["medicalLicenseId"] as? String ?? "",
                    bankAccountNumber: data["bankAccountNumber"] as? String ?? "",
                    address: data["address"] as? String ?? ""
                )
                
                DispatchQueue.main.async {
                    doctorData = doctor
                    print("Doctor Data Fetched Successfully: \(doctor)")
                }
            } else {
                print("Doctor document not found.")
            }
        }
    }
}

#Preview {
    DocTabCar(doctorId: "67", hospitalId: "67")
}
