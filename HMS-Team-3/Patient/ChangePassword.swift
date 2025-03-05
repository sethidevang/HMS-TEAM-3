import SwiftUI
import FirebaseFirestore

struct PatientChangePasswordView: View {
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var patientEmail: String

    var isNewPasswordValid: Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*\\d).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: newPassword)
    }

    var isFormValid: Bool {
        return !oldPassword.isEmpty &&
               isNewPasswordValid &&
               newPassword == confirmPassword
    }

    var body: some View {
        VStack(spacing: 20) {
            SecureFieldView(title: "Old Password", text: $oldPassword)

            SecureFieldView(title: "New Password", text: $newPassword)
            if !newPassword.isEmpty && !isNewPasswordValid {
                Text("Password must be at least 8 characters, include a capital letter and a number.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .multilineTextAlignment(.leading)
            }

            SecureFieldView(title: "Confirm Password", text: $confirmPassword)
            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                Text("Passwords do not match.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .multilineTextAlignment(.leading)
            }

            Button(action: {
                handleChangePassword()
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                    .opacity(isFormValid ? 1.0 : 0.5)
            }
            .disabled(!isFormValid)
            .padding(.top, 10)

            Spacer()
        }
        .padding()
        .navigationTitle("Change Password")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                if alertMessage == "Password successfully changed!" {
                    redirectToLogin() // ✅ Reset Root View
                }
            })
        }
    }

    private func handleChangePassword() {
        let db = Firestore.firestore()
        let usersCollection = db.collection("patients")

        usersCollection.whereField("email", isEqualTo: patientEmail).getDocuments { (snapshot, error) in
            if let error = error {
                alertMessage = "Error: \(error.localizedDescription)"
                showAlert = true
                return
            }

            guard let document = snapshot?.documents.first else {
                alertMessage = "User not found."
                showAlert = true
                return
            }

            let userData = document.data()
            let storedPassword = userData["password"] as? String ?? ""

            if oldPassword != storedPassword {
                alertMessage = "Old password is incorrect."
                showAlert = true
                return
            }

            // Update password in Firestore
            usersCollection.document(document.documentID).updateData(["password": newPassword]) { error in
                if let error = error {
                    alertMessage = "Failed to update password: \(error.localizedDescription)"
                } else {
                    alertMessage = "Password successfully changed!"
                }
                showAlert = true
            }
        }
    }

    private func redirectToLogin() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = UIHostingController(rootView: LoginView())
                window.makeKeyAndVisible()
            }
        }
    }
}

// Reusable SecureField Component
struct SecureFieldView: View {
    var title: String
    @Binding var text: String
    @State private var isSecure: Bool = true

    var body: some View {
        HStack {
            if isSecure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
            }
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
