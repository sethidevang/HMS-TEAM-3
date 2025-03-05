import SwiftUI
import FirebaseFirestore

struct EditAdmin: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var admin: Admin?
    var hospitalId: String
    @State private var originalAdmin: Admin?
    @State private var previousAdmins: [Admin] = []
    @State private var showAlert = false
    @State private var isSaving = false
    var doneAction: (() -> Void)?

    private let db = Firestore.firestore()

    init(admin: Admin?, hospitalId: String, doneAction: (() -> Void)? = nil) {
        self._admin = State(initialValue: admin)
        self._originalAdmin = State(initialValue: admin)
        self.hospitalId = hospitalId
        self.doneAction = doneAction
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Admin Details")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                if let admin = admin {
                    adminDetailsSection(admin: admin)
                } else {
                    Text("No admin assigned. You can assign a new admin below.")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                actionButton()
                
                if !previousAdmins.isEmpty {
                    previousAdminsSection()
                }
                
                
            }
        }
        .background(Color(.systemGray6))
        .toolbar(content: toolbarContent)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Success"),
                message: Text("Changes saved successfully."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                    doneAction?()
                }
            )
        }
        .onAppear(perform: fetchPreviousAdmins)
    }

    private func adminDetailsSection(admin: Admin) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            CustomTextField(title: "Name", text: Binding(
                get: { admin.name },
                set: { self.admin?.name = $0 }
            ))
            CustomTextField(title: "Email", text: Binding(
                get: { admin.email },
                set: { self.admin?.email = $0 }
            ))
            CustomTextField(title: "Address", text: Binding(
                get: { admin.address },
                set: { self.admin?.address = $0 }
            ))
            CustomTextField(title: "Phone Number", text: Binding(
                get: { admin.phoneNumber },
                set: { self.admin?.phoneNumber = $0 }
            ))
            CustomTextField(title: "Experience", text: Binding(
                get: { admin.experience },
                set: { self.admin?.experience = $0 }
            ))
        }
        .padding(.horizontal)
    }

    private func previousAdminsSection() -> some View {
        VStack(alignment: .leading) {
            Text("Previous Admins")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(previousAdmins, id: \ .id) { admin in
                VStack(alignment: .leading) {
                    Text(admin.name).font(.headline)
                    Text(admin.email).font(.subheadline).foregroundColor(.gray)
                }
                .padding(.vertical, 5)
            }
        }
        .padding(.horizontal)
    }

    private func actionButton() -> some View {
        Button(action: {
            admin == nil ? assignAdmin() : removeAdmin()
        }) {
            Text(admin == nil ? "Assign Admin" : "Remove Admin")
                .foregroundColor(admin == nil ? .blue : .red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(admin == nil ? Color.blue : Color.red, lineWidth: 1))
        }
        .padding()
    }

    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button("Done") { saveChanges() }
                .foregroundColor(hasChanges() ? .blue : .gray)
                .disabled(!hasChanges())
        }
    }

    private func hasChanges() -> Bool {
        guard let admin = admin, let originalAdmin = originalAdmin else { return false }
        
        return admin.name != originalAdmin.name ||
               admin.email != originalAdmin.email ||
               admin.address != originalAdmin.address ||
               admin.phoneNumber != originalAdmin.phoneNumber ||
               admin.experience != originalAdmin.experience
    }

    private func saveChanges() {
        guard let admin = admin else { return }
        isSaving = true
        let hospitalRef = db.collection("hospitals").document(hospitalId)
        
        hospitalRef.updateData(["admin": admin.toDictionary()]) { error in
            isSaving = false
            if error == nil { showAlert = true; originalAdmin = admin }
        }
    }

    private func removeAdmin() {
        guard let admin = admin else { return }
        let hospitalRef = db.collection("hospitals").document(hospitalId)
        
        hospitalRef.updateData([
            "previousAdmins": FieldValue.arrayUnion([admin.toDictionary()]), // Save current admin to previousAdmins
            "admin": FieldValue.delete() // Remove current admin
        ]) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.admin = nil // Clear current admin
                    self.originalAdmin = nil
                    // self.presentationMode.wrappedValue.dismiss() // Remove this to keep page open
                    doneAction?()
                }
            }
        }
    }


    private func assignAdmin() {
        let hospitalRef = db.collection("hospitals").document(hospitalId)
        let newAdmin = Admin(id: UUID().uuidString, name: "New Admin", email: "", address: "", experience: "", phoneNumber: "")
        
        hospitalRef.updateData(["admin": newAdmin.toDictionary()]) { _ in
            self.admin = newAdmin
            self.originalAdmin = newAdmin
        }
    }

    private func fetchPreviousAdmins() {
        let hospitalRef = db.collection("hospitals").document(hospitalId)
        hospitalRef.getDocument { snapshot, _ in
            if let data = snapshot?.data(), let previousAdminsData = data["previousAdmins"] as? [[String: Any]] {
                self.previousAdmins = previousAdminsData.compactMap { Admin(dictionary: $0) }
            }
        }
    }
}

struct CustomTextField: View {
    var title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .bold()
            TextField(title, text: $text)
                .padding()
                .frame(height: 50)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 1)
        }
    }
}

struct EditAdmin_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditAdmin(
                admin: Admin(id: "admin123", name: "John Doe", email: "admin@hospital.com", address: "123 Main St, NY", experience: "10 years", phoneNumber: "(123) 456-7890"),
                hospitalId: "hospital123",
                doneAction: { print("Done tapped") }
            )
        }
    }
}
