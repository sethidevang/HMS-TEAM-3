import SwiftUI
import Firebase
import FirebaseAuth

struct ChangePasswordView: View {
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""

    let doctorId: String
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                PasswordField(title: "Old Password", text: $oldPassword)
                PasswordField(title: "New Password", text: $newPassword)
                PasswordField(title: "Confirm New Password", text: $confirmNewPassword)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }

                if !successMessage.isEmpty {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
//            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline) // Ensures proper title display
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: changePassword) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
        }
    }

    func changePassword() {
        guard !oldPassword.isEmpty, !newPassword.isEmpty, !confirmNewPassword.isEmpty else {
            errorMessage = "All fields are required!"
            return
        }

        guard newPassword == confirmNewPassword else {
            errorMessage = "New passwords do not match!"
            return
        }

        let docRef = db.collection("doctor_creds").document(doctorId)

        docRef.getDocument { document, error in
            if let error = error {
                errorMessage = "Error fetching doctor: \(error.localizedDescription)"
                return
            }

            guard let document = document, document.exists,
                  let storedPassword = document.get("password") as? String else {
                errorMessage = "Doctor not found!"
                return
            }

            if storedPassword != oldPassword {
                errorMessage = "Old password is incorrect!"
                return
            }

            docRef.updateData(["password": newPassword]) { err in
                if let err = err {
                    errorMessage = "Failed to update password: \(err.localizedDescription)"
                } else {
                    successMessage = "Password updated successfully!"

                    do {
                        try Auth.auth().signOut()
                        if let window = UIApplication.shared.windows.first {
                            window.rootViewController = UIHostingController(rootView: LoginView())
                            window.makeKeyAndVisible()
                        }
                    } catch let signOutError {
                        errorMessage = "Error signing out: \(signOutError.localizedDescription)"
                    }
                }
            }
        }
    }
}


struct PasswordField: View {
    var title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            SecureField(title, text: $text)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
        }
    }
}

#Preview {
    ChangePasswordView(doctorId: "80A0EF9B-F0F5-4D80-B8A8-401BD3A9B3F7")
}
