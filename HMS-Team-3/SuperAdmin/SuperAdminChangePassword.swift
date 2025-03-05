import SwiftUI
import Firebase
import FirebaseFirestore

struct SuperAdminChangePassword: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let adminEmail = "admin@example.com" // Change this to dynamic email if needed
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Old Password")
                .font(.headline)
            SecureField("Old Password", text: $oldPassword)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 1)
            
            Text("New Password")
                .font(.headline)
            SecureField("New Password", text: $newPassword)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 1)
            
            Text("Confirm New Password")
                .font(.headline)
            SecureField("Confirm New Password", text: $confirmNewPassword)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 1)

            // Error message display
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
            
            Spacer()
            
            Button(action: savePassword) {
                Text("Save")
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red, lineWidth: 1))
            }
            .padding()
        }
        .padding()
        .background(Color(.systemGray6))
        .navigationBarTitle("Change Password", displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func savePassword() {
        guard !oldPassword.isEmpty, !newPassword.isEmpty, !confirmNewPassword.isEmpty else {
            showError("All fields are required.")
            return
        }

        guard newPassword == confirmNewPassword else {
            showError("New passwords do not match.")
            return
        }

        let db = Firestore.firestore()
        db.collection("superAdmins").whereField("email", isEqualTo: adminEmail).getDocuments { snapshot, error in
            if let error = error {
                showError("Error fetching admin: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents, let document = documents.first else {
                showError("Admin account not found.")
                return
            }

            let storedPassword = document.data()["password"] as? String ?? ""
            let docID = document.documentID

            if oldPassword == storedPassword { // Verify old password
                db.collection("superAdmins").document(docID).updateData(["password": newPassword]) { error in
                    if let error = error {
                        showError("Error updating password: \(error.localizedDescription)")
                    } else {
                        showSuccess("Password updated successfully!")
                    }
                }
            } else {
                showError("Old password is incorrect.")
            }
        }
    }

    func showError(_ message: String) {
        errorMessage = message
        alertMessage = message
        showAlert = true
    }

    func showSuccess(_ message: String) {
        errorMessage = ""
        alertMessage = message
        showAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Navigate to LoginView after success
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(rootView: LoginView())
                window.makeKeyAndVisible()
            }
        }
    }
}

struct SuperAdminChangePassword_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SuperAdminChangePassword()
        }
    }
}
