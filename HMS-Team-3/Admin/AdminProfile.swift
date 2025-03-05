import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AdminProfile: View {
    let hospitalId: String
    @State private var isLoggedOut = false
    @State private var adminName: String = "Loading..."
    @State private var adminEmail: String = "Loading..."

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Text(adminName.prefix(1)) // ✅ First letter as profile icon
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                Text(adminName)
                    .font(.body)
//                    .foregroundColor(.black)
                Text(adminEmail) // ✅ Show fetched email
                    .font(.body)
//                    .foregroundColor(.black)
            }
            .padding(.top, 8)

            VStack(spacing: 10) {
                NavigationLink(destination: AdminChangePassword()) {
                    ProfileOption(title: "Change Password")
                }
                NavigationLink(destination: SpecializationView(hospitalId: hospitalId)) {
                    ProfileOption(title: "Specializations")
                }
                NavigationLink(destination: LeaveRecordsView()) {
                    ProfileOption(title: "Doctor Leave Records")
                }
                
                NavigationLink(destination: DoctorProfileRequestsView()) {
                    ProfileOption(title: "Doctor Profile Change Requests")
                }
                
//                NavigationLink(destination: DoctorProfileRequestsView()) {
//                    ProfileOption(title: "Doctor Appointment Fees")
//                }
                
                NavigationLink(destination: SalariesView(hospitalId : hospitalId)) {
                    ProfileOption(title: "Doctor Salaries")
                        
                }
                
                NavigationLink(destination: CampaignView()) {
                    ProfileOption(title: "Patient Campaigns")
                }

                Button(action: {
                    logOut()
                }) {
                    Text("Log Out")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 0))
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .background(Color(.systemGray6))
        .navigationBarTitle("Profile", displayMode: .large)
        .fullScreenCover(isPresented: $isLoggedOut) {
            LoginView()
        }
        .onAppear {
            fetchAdminDetails()
        }
    }

    /// ✅ **Fetch Admin Details**
    private func fetchAdminDetails() {
        let db = Firestore.firestore()
        db.collection("hospitals").document(hospitalId).getDocument { document, error in
            if let document = document, document.exists {
                if let adminData = document.data()?["admin"] as? [String: Any] {
                    adminName = adminData["name"] as? String ?? "Admin"
                    adminEmail = adminData["email"] as? String ?? "No Email"
                }
            } else {
                print("Error fetching admin details: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    /// ✅ **Logout Function**
    func logOut() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "hospitalId")
            isLoggedOut = true
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

// MARK: - Profile Option Component
struct ProfileOption: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(Color(UIColor.label))
//                .foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.gray.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Preview
struct AdminProfile_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminProfile(hospitalId: "GW3yiW4wbyeKAcFYwyJU")
                .preferredColorScheme(.dark)
        }
    }
}
