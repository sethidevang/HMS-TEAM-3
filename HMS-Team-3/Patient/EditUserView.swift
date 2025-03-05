import SwiftUI

struct EditUserView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var user: User
    var onDelete: () -> Void  // Closure to delete user
    
    @State private var name: String
    @State private var age: String
    @State private var gender: String
    @State private var phoneNumber: String
    @State private var email: String
    @State private var relation: String
    
    @State private var isModified = false
    @State private var showDeleteAlert = false  // Alert confirmation
    
    var relations = ["Father", "Mother", "Child", "Other"]
    
    init(user: Binding<User>, onDelete: @escaping () -> Void) {
        _user = user
        self.onDelete = onDelete
        _name = State(initialValue: user.wrappedValue.name)
        _age = State(initialValue: "\(user.wrappedValue.age)")
        _gender = State(initialValue: user.wrappedValue.gender ?? "NA")
        _phoneNumber = State(initialValue: user.wrappedValue.phoneNumber)
        _email = State(initialValue: user.wrappedValue.email)
        _relation = State(initialValue: user.wrappedValue.relation)
    }
    
    var isFormValid: Bool {
        !name.isEmpty &&
        !age.isEmpty &&
        Int(age) != nil &&
        !gender.isEmpty &&
        !phoneNumber.isEmpty &&
        phoneNumber.count >= 10 &&
        phoneNumber.allSatisfy({ $0.isNumber }) &&
        !email.isEmpty &&
        email.contains("@") &&
        !relation.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Personal Information")) {
                        TextField("Name", text: $name)
                            .onChange(of: name) { _ in checkIfModified() }
                        
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .onChange(of: age) { _ in checkIfModified() }
                        
                        Picker("Gender", selection: $gender) {
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                            Text("Other").tag("Other")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: gender) { _ in checkIfModified() }
                    }
                    
                    Section(header: Text("Contact Information")) {
                        TextField("Phone Number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .onChange(of: phoneNumber) { _ in checkIfModified() }
                        
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .onChange(of: email) { _ in checkIfModified() }
                    }
                    
                    Section(header: Text("Relation")) {
                        Picker("Relation", selection: $relation) {
                            ForEach(relations, id: \.self) { relation in
                                Text(relation).tag(relation)
                            }
                        }
                        .onChange(of: relation) { _ in checkIfModified() }
                    }
                }
                
                // Styled Remove Button
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Text("Remove User")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.red)
                        .cornerRadius(10)  // Rounded corners
                        .padding(.horizontal, 16)  // Side padding
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text("Delete User"),
                        message: Text("Are you sure you want to remove this user?"),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteUser()
                        },
                        secondaryButton: .cancel()
                    )
                }
                .padding(.bottom, 10)  // Extra spacing at the bottom
            }
            .navigationTitle("Edit User")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isModified || !isFormValid)
                }
            }
        }
    }
    
    private func saveChanges() {
        user.name = name
        user.age = age
        user.gender = gender
        user.phoneNumber = phoneNumber
        user.email = email
        user.relation = relation
        
        isModified = false
        presentationMode.wrappedValue.dismiss()
    }
    
    private func deleteUser() {
        onDelete()  // Call the deletion function
        presentationMode.wrappedValue.dismiss()
    }
    
    private func checkIfModified() {
        isModified = name != user.name ||
        age != "\(user.age)" ||
        gender != user.gender ||
        phoneNumber != user.phoneNumber ||
        email != user.email ||
        relation != user.relation
    }
}
    // Preview
//    struct EditUserView_Previews: PreviewProvider {
//        static var previews: some View {
//            EditUserView(
//                user: .constant(User(name: "John Doe", age: 30, gender: "Male", phoneNumber: "1234567890", email: "john@example.com", relation: "Father")),
//                onDelete: {}
//            )
//        }
//    }
//}

