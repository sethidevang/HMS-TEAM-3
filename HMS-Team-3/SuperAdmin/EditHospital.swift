import SwiftUI
import Firebase

struct EditHospital: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var hospital: Hospital
    @State private var hospitalName: String
    @State private var hospitalLocation: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isDeleting = false

    init(hospital: Binding<Hospital>) {
        self._hospital = hospital
        _hospitalName = State(initialValue: hospital.wrappedValue.name)
        _hospitalLocation = State(initialValue: hospital.wrappedValue.location)
    }

    private var hasChanges: Bool {
        return hospitalName != hospital.name || hospitalLocation != hospital.location
    }

    var body: some View {
        NavigationStack{
            VStack(alignment: .leading, spacing: 16) {
                Text("Hospital Details")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Name")
                        .font(.headline)
                    TextField("Enter hospital name", text: $hospitalName)
                        .padding()
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 1)

                    Text("Location")
                        .font(.headline)
                    TextField("Enter hospital location", text: $hospitalLocation)
                        .padding()
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                }
                .padding(.horizontal)

                Spacer()

                // REMOVE HOSPITAL BUTTON
                Button(action: removeHospital) {
                    Text("Remove Hospital")
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red, lineWidth: 1))
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .navigationBarTitle("Edit Hospital", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: updateHospital) {
                    Text("Save").bold()
                }
                .disabled(!hasChanges) // Disable if no changes
                .foregroundColor(hasChanges ? .blue : .gray) // Change color based on state
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Success"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isDeleting {
                            goToDashboard()
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }

    func updateHospital() {
        guard let id = hospital.id else { return }
        let db = Firestore.firestore()
        let hospitalRef = db.collection("hospitals").document(id)

        hospitalRef.updateData([
            "name": hospitalName,
            "location": hospitalLocation
        ]) { error in
            if let error = error {
                print("Error updating hospital: \(error.localizedDescription)")
            } else {
                hospital.name = hospitalName
                hospital.location = hospitalLocation
                alertMessage = "Hospital updated successfully"
                showAlert = true
            }
        }
    }

    func removeHospital() {
        guard let id = hospital.id else { return }
        let db = Firestore.firestore()
        db.collection("hospitals").document(id).delete { error in
            if let error = error {
                print("Error deleting hospital: \(error.localizedDescription)")
            } else {
                isDeleting = true
                alertMessage = "Hospital deleted successfully"
                showAlert = true
            }
        }
    }

    func goToDashboard() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: SuperAdminDashboardView())
            window.makeKeyAndVisible()
        }
    }
}

// Preview
struct EditHospital_Previews: PreviewProvider {
    @State static var hospital = Hospital(id: "123", name: "Sample Hospital", location: "City", admin: Admin(id: "56", name: "John Doe", email: "admin@example.com", address: "Street 123", experience: "5 years", phoneNumber: "1234567890"))

    static var previews: some View {
        EditHospital(hospital: $hospital)
    }
}
