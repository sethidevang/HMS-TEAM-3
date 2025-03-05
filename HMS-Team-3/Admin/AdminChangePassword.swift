import SwiftUI
import FirebaseFirestore

struct AdminChangePassword: View {
    @Environment(\.dismiss) var dismiss  // ✅ Correct way to handle navigation
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var errorMessage: String = ""

    // Computed property to check if all fields are filled and valid
    private var isFormValid: Bool {
        return !oldPassword.isEmpty && !newPassword.isEmpty && !confirmNewPassword.isEmpty && newPassword == confirmNewPassword
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Old Password")
                .font(.headline)
            SecureField("Enter Old Password", text: $oldPassword)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 1)
            
            Text("New Password")
                .font(.headline)
            SecureField("Enter New Password", text: $newPassword)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 1)
            
            Text("Confirm New Password")
                .font(.headline)
            SecureField("Re-enter New Password", text: $confirmNewPassword)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 1)
            
            Spacer()
            
            Button(action: savePassword) {
                Text("Save")
                    .foregroundColor(isFormValid ? .white : .gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isFormValid ? Color.red : Color.gray.opacity(0.5))
                    .cornerRadius(10)
            }
            .padding()
            .disabled(!isFormValid) // Disables button if form is not valid
        }
        .padding()
        .background(Color(.systemGray6))
        .navigationBarTitle("Change Password", displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    /// ✅ **Change Password Function**
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
        
        // ✅ Search for the admin in `admin_credentials` where password matches old password
        db.collection("admin_credentials")
            .whereField("password", isEqualTo: oldPassword)
            .getDocuments { snapshot, error in
                if let error = error {
                    showError("Error fetching admin: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, let document = documents.first else {
                    showError("Old password is incorrect.")
                    return
                }

                let docID = document.documentID

                // ✅ Update password in Firestore
                db.collection("admin_credentials").document(docID).updateData(["password": newPassword]) { error in
                    if let error = error {
                        showError("Error updating password: \(error.localizedDescription)")
                    } else {
                        showSuccess("Password updated successfully!")
                    }
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
            dismiss() // ✅ Navigate back after success
        }
    }
}

// MARK: - Preview
struct AdminChangePassword_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminChangePassword()
        }
    }
}
