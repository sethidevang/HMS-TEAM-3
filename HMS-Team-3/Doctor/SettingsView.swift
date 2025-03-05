import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    var doctor: DoctorModel // Change from DoctorListView to DoctorModel
    @Environment(\.presentationMode) var presentationMode // To dismiss the current view

    var body: some View {
        List {
            // Doctor Profile Section
            Section {
                NavigationLink(destination: DoctorDetailView(doctor: doctor)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(doctor.firstName)
                                .font(.headline)
                                .fontWeight(.bold)
                            Text(doctor.specialization)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }

            // Settings List
            Section {
                NavigationLink(destination: PatientRecordsView()) {
                    Label("Patient Records", systemImage: "folder")
                }
                
                NavigationLink(destination: ChangePasswordView(doctorId: doctor.id)) {
                    Label("Change Password", systemImage: "key")
                }
            }

            // Logout Button
            Section {
                Button(action: handleLogout) {
                    HStack {
                        Spacer()
                        Text("Log Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Logout Function
    func handleLogout() {
        do {
            try Auth.auth().signOut()
            
            // Redirect to Login View
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = UIHostingController(rootView: LoginView())
                window.makeKeyAndVisible()
            }
        } catch let signOutError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(doctor: DoctorModel(id: "1", firstName: "John", lastName: "Doe", specialization: "Cardiology", phone: "", email: "", experience: "", degrees: [], medicalLicenseId: "", bankAccountNumber: "", address: ""))
    }
}
