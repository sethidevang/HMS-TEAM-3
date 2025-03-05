import SwiftUI
import FirebaseFirestore
import FirebaseAuth


struct ProfileView: View {
    @State private var isAddUserPresented = false
    @State private var users: [User] = []
    @State private var selectedUser: User?
    var patientEmail: String
    @State private var patient: Patient?
    @State private var isEditProfilePresented = false
    
    // Colors for profile avatars
    private let profileColors: [Color] = [
        .green, .orange, .purple, .pink, .teal, .yellow, .red
    ]
    
    var body: some View {
        NavigationStack {
            ProfileContentView(
                isAddUserPresented: $isAddUserPresented,
                users: $users,
                selectedUser: $selectedUser,
                patient: $patient,
                isEditProfilePresented: $isEditProfilePresented,
                patientEmail: patientEmail,
                profileColors: profileColors
            )
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button(action: {
                isEditProfilePresented = true
            }) {
                Text("Edit")
                    .foregroundColor(.blue)
            })
            .sheet(isPresented: $isAddUserPresented) {
                AddUserView(users: $users, patientEmail: patientEmail)
            }
            .sheet(isPresented: $isEditProfilePresented) {
                if let selectedUser = selectedUser {
                    EditProfileView(
                        user: $selectedUser,
                        patientEmail: patientEmail,
                        isPatient: false
                    )
                } else if let patient = patient {
                    EditProfileView(
                        patient: $patient,
                        patientEmail: patientEmail,
                        isPatient: true
                    )
                }
            }
            .onAppear {
                fetchPatientData()
            }
        }
    }
    
    // Fetch logged-in patient data and family members
    private func fetchPatientData() {
        let db = Firestore.firestore()
        db.collection("patients").whereField("email", isEqualTo: patientEmail).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching patient: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("No patient document found")
                return
            }
            
            let data = document.data()
            patient = Patient(
                name: data["name"] as? String ?? "",
                age: data["age"] as? String ?? "",
                gender: data["gender"] as? String ?? "",
                phoneNumber: data["phoneNumber"] as? String ?? "",
                email: data["email"] as? String ?? ""
            )
            
            if let familyArray = data["family_members"] as? [[String: Any]] {
                users = familyArray.compactMap { memberData in
                    return User(
                        name: memberData["name"] as? String ?? "",
                        age: memberData["age"] as? String ?? "",
                        gender: memberData["gender"] as? String ?? "",
                        phoneNumber: memberData["phoneNumber"] as? String ?? "",
                        email: memberData["email"] as? String ?? "",
                        relation: memberData["relation"] as? String ?? ""
                    )
                }
            }
        }
    }
}

// Extracted main content view
struct ProfileContentView: View {
    @Binding var isAddUserPresented: Bool
    @Binding var users: [User]
    @Binding var selectedUser: User?
    @Binding var patient: Patient?
    @Binding var isEditProfilePresented: Bool
    var patientEmail: String
    var profileColors: [Color]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile selection area
                ProfileSelectionView(
                    users: users,
                    selectedUser: $selectedUser,
                    patient: patient,
                    isAddUserPresented: $isAddUserPresented,
                    profileColors: profileColors
                )
                
                // Profile details card
                ProfileDetailsCardView(selectedUser: selectedUser, patient: patient)
                    .animation(.spring(), value: selectedUser?.id) // Use the ID instead of the whole User object
                
                // Action buttons
                ActionButtonsView(patientEmail: patientEmail)
                
                Spacer()
                
                // Logout button
                LogoutButtonView()
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

// Profile selection view
struct ProfileSelectionView: View {
    let users: [User]
    @Binding var selectedUser: User?
    let patient: Patient?
    @Binding var isAddUserPresented: Bool
    let profileColors: [Color]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Family Profiles")
                .font(.headline)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // Patient profile
                    if let patient = patient {
                        ProfileButton(
                            initials: patient.initials,
                            name: patient.name,
                            color: .blue,
                            isSelected: selectedUser == nil,
                            action: {
                                selectedUser = nil
                            }
                        )
                    }
                    
                    // Family member profiles
                    ForEach(Array(zip(users.indices, users)), id: \.1.id) { index, user in
                        ProfileButton(
                            initials: user.initials,
                            name: user.name,
                            color: profileColors[index % profileColors.count],
                            isSelected: selectedUser?.id == user.id,
                            action: {
                                selectedUser = user
                            }
                        )
                    }
                    
                    // Add family button
                    AddFamilyButton {
                        isAddUserPresented = true
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

// Profile details card view
struct ProfileDetailsCardView: View {
    let selectedUser: User?
    let patient: Patient?
    
    var body: some View {
        VStack {
            if let selectedUser = selectedUser {
                UserDetailsView(user: selectedUser)
                    .transition(.opacity)
            } else if let patient = patient {
                PatientDetailsView(patient: patient)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .animation(.spring(), value: selectedUser?.id) // Use the ID instead of the whole User object
    }
}

// Action buttons view
struct ActionButtonsView: View {
    var patientEmail: String
    
    var body: some View {
        VStack(spacing: 15) {
            NavigationLink(destination: ChangeHospitalView(patientEmail: patientEmail)) {
                ActionRow(title: "Change Hospital", icon: "building.2")
            }
            
            NavigationLink(destination: PatientChangePasswordView(patientEmail: patientEmail)) {
                ActionRow(title: "Change Password", icon: "lock.rotation")
            }
        }
        .padding(.horizontal)
    }
}

// Logout button view
struct LogoutButtonView: View {
    var body: some View {
        Button(action: {
            do {
                try Auth.auth().signOut()
                // Navigate to login view
                (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController = UIHostingController(rootView: LoginView())
            } catch let signOutError {
                print("Error signing out: \(signOutError.localizedDescription)")
            }
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.body)
                
                Text("Log Out")
                    .font(.body.bold())
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Profile Button with Color and Stroke
struct ProfileButton: View {
    var initials: String
    var name: String
    var color: Color
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 70, height: 70)
                    
                    if isSelected {
                        Circle()
                            .stroke(Color.blue, lineWidth: 3)
                            .frame(width: 74, height: 74)
                    }
                    
                    Text(initials)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                Text(name.split(separator: " ").first.map(String.init) ?? name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(width: 70, alignment: .center)
                    .truncationMode(.tail)



            }
        }
    }
}

// MARK: - Add Family Button
struct AddFamilyButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Text("Add Family")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - User Details View
struct UserDetailsView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Family Member Profile")
                .font(.headline)
                .padding(.top)
            
            Divider()
            
            InfoRow(title: "Name", value: user.name)
            InfoRow(title: "Age", value: user.age ?? "NA")
            InfoRow(title: "Gender", value: user.gender ?? "NA")
            InfoRow(title: "Phone", value: user.phoneNumber)
            InfoRow(title: "Email", value: user.email)
            InfoRow(title: "Relation", value: user.relation)
        }
        .padding()
    }
}

// MARK: - Patient Details View
struct PatientDetailsView: View {
    let patient: Patient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Profile")
                .font(.headline)
                .padding(.top)
            
            Divider()
            
            InfoRow(title: "Name", value: patient.name)
            InfoRow(title: "Age", value: patient.age ?? "NA")
            InfoRow(title: "Gender", value: patient.gender ?? "NA")
            InfoRow(title: "Phone", value: patient.phoneNumber ?? "NA")
            InfoRow(title: "Email", value: patient.email ?? "NA")
        }
        .padding()
    }
}



// MARK: - Action Row
struct ActionRow: View {
    var title: String
    var icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Add User View
struct AddUserView: View {
    @Binding var users: [User]
    var patientEmail: String
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var age = ""
    @State private var gender = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var relation = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    
                    Picker("Gender", selection: $gender) {
                        Text("Select").tag("")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Relationship")) {
                    Picker("Relation", selection: $relation) {
                        Text("Select").tag("")
                        Text("Spouse").tag("Spouse")
                        Text("Child").tag("Child")
                        Text("Parent").tag("Parent")
                        Text("Sibling").tag("Sibling")
                        Text("Other").tag("Other")
                    }
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveNewUser()
                }
                .disabled(!isFormValid)
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !age.isEmpty && !gender.isEmpty &&
        !phoneNumber.isEmpty && !relation.isEmpty
    }
    
    private func saveNewUser() {
        let db = Firestore.firestore()
        
        // Validate form
        if name.isEmpty || age.isEmpty || gender.isEmpty ||
           phoneNumber.isEmpty || relation.isEmpty {
            alertMessage = "Please fill in all required fields"
            showingAlert = true
            return
        }
        
        // Find patient document
        db.collection("patients").whereField("email", isEqualTo: patientEmail).getDocuments { snapshot, error in
            if let error = error {
                alertMessage = "Error: \(error.localizedDescription)"
                showingAlert = true
                return
            }
            
            guard let document = snapshot?.documents.first else {
                alertMessage = "Patient record not found"
                showingAlert = true
                return
            }
            
            let patientID = document.documentID
            
            // Create new user data
            let newUserData: [String: Any] = [
                "name": name,
                "age": age,
                "gender": gender,
                "phoneNumber": phoneNumber,
                "email": email,
                "relation": relation
            ]
            
            // Update Firestore
            db.collection("patients").document(patientID).updateData([
                "family_members": FieldValue.arrayUnion([newUserData])
            ]) { error in
                if let error = error {
                    alertMessage = "Error saving: \(error.localizedDescription)"
                    showingAlert = true
                } else {
                    // Add to local state
                    let newUser = User(
                        name: name,
                        age: age,
                        gender: gender,
                        phoneNumber: phoneNumber,
                        email: email,
                        relation: relation
                    )
                    users.append(newUser)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Binding var patient: Patient?
    @Binding var user: User?
    var patientEmail: String
    var isPatient: Bool
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var gender: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var relation: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteConfirmation = false
    
    init(patient: Binding<Patient?> = .constant(nil),
         user: Binding<User?> = .constant(nil),
         patientEmail: String,
         isPatient: Bool) {
        self._patient = patient
        self._user = user
        self.patientEmail = patientEmail
        self.isPatient = isPatient
        
        if isPatient, let patient = patient.wrappedValue {
            _name = State(initialValue: patient.name)
            _age = State(initialValue: patient.age ?? "NA")
            _gender = State(initialValue: patient.gender ?? "NA")
            _phoneNumber = State(initialValue: patient.phoneNumber ?? "NA")
            _email = State(initialValue: patient.email ?? "NA")
        } else if !isPatient, let user = user.wrappedValue {
            _name = State(initialValue: user.name)
            _age = State(initialValue: user.age ?? "NA")
            _gender = State(initialValue: user.gender ?? "NA")
            _phoneNumber = State(initialValue: user.phoneNumber)
            _email = State(initialValue: user.email)
            _relation = State(initialValue: user.relation)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    
                    Picker("Gender", selection: $gender) {
                        Text("Select").tag("")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    // Only show email for patient
                    if isPatient {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(true) // Email can't be changed
                    }
                }
                
                // Only show relation for family members
                if !isPatient {
                    Section(header: Text("Relationship")) {
                        Picker("Relation", selection: $relation) {
                            Text("Select").tag("")
                            Text("Spouse").tag("Spouse")
                            Text("Child").tag("Child")
                            Text("Parent").tag("Parent")
                            Text("Sibling").tag("Sibling")
                            Text("Other").tag("Other")
                        }
                    }
                    
                    // Add Remove Member button for family members
                    Section {
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "person.fill.xmark")
                                    .foregroundColor(.red)
                                Text("Remove Member")
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle(isPatient ? "Edit Your Profile" : "Edit Family Member")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                }
                .disabled(!isFormValid)
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .confirmationDialog(
                "Remove Family Member",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove \(name)", role: .destructive) {
                    removeFamilyMember()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to remove this family member? This action cannot be undone.")
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !age.isEmpty && !gender.isEmpty && !phoneNumber.isEmpty &&
        (isPatient || !relation.isEmpty)
    }
    
    private func saveChanges() {
        let db = Firestore.firestore()
        
        // Find patient document
        db.collection("patients").whereField("email", isEqualTo: patientEmail).getDocuments { snapshot, error in
            if let error = error {
                alertMessage = "Error: \(error.localizedDescription)"
                showingAlert = true
                return
            }
            
            guard let document = snapshot?.documents.first else {
                alertMessage = "Patient record not found"
                showingAlert = true
                return
            }
            
            let patientID = document.documentID
            
            if isPatient {
                // Update patient profile
                db.collection("patients").document(patientID).updateData([
                    "name": name,
                    "age": age,
                    "gender": gender,
                    "phoneNumber": phoneNumber
                ]) { error in
                    if let error = error {
                        alertMessage = "Error updating: \(error.localizedDescription)"
                        showingAlert = true
                    } else {
                        // Update local state
                        patient?.name = name
                        patient?.age = age
                        patient?.gender = gender
                        patient?.phoneNumber = phoneNumber
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } else if var existingUser = user {
                // First get existing family members
                db.collection("patients").document(patientID).getDocument { snapshot, error in
                    if let error = error {
                        alertMessage = "Error: \(error.localizedDescription)"
                        showingAlert = true
                        return
                    }
                    
                    guard let document = snapshot, document.exists else {
                        alertMessage = "Patient document not found"
                        showingAlert = true
                        return
                    }
                    
                    // Get current family members array
                    guard var familyMembers = document.data()?["family_members"] as? [[String: Any]] else {
                        alertMessage = "Could not retrieve family members"
                        showingAlert = true
                        return
                    }
                    
                    // Find and update the specific family member
                    for (index, var member) in familyMembers.enumerated() {
                        if member["name"] as? String == existingUser.name &&
                           member["phoneNumber"] as? String == existingUser.phoneNumber {
                            
                            // Update the member with new data
                            member["name"] = name
                            member["age"] = age
                            member["gender"] = gender
                            member["phoneNumber"] = phoneNumber
                            member["relation"] = relation
                            familyMembers[index] = member
                            
                            // Update Firestore
                            db.collection("patients").document(patientID).updateData([
                                "family_members": familyMembers
                            ]) { error in
                                if let error = error {
                                    alertMessage = "Error updating: \(error.localizedDescription)"
                                    showingAlert = true
                                } else {
                                    // Update local state
                                    existingUser.name = name
                                    existingUser.age = age
                                    existingUser.gender = gender
                                    existingUser.phoneNumber = phoneNumber
                                    existingUser.relation = relation
                                    user = existingUser
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                            return
                        }
                    }
                    
                    alertMessage = "Could not find the family member to update"
                    showingAlert = true
                }
            }
        }
    }
    
    private func removeFamilyMember() {
        guard let existingUser = user else {
            alertMessage = "Family member information not available"
            showingAlert = true
            return
        }
        
        let db = Firestore.firestore()
        
        // Find patient document
        db.collection("patients").whereField("email", isEqualTo: patientEmail).getDocuments { snapshot, error in
            if let error = error {
                alertMessage = "Error: \(error.localizedDescription)"
                showingAlert = true
                return
            }
            
            guard let document = snapshot?.documents.first else {
                alertMessage = "Patient record not found"
                showingAlert = true
                return
            }
            
            let patientID = document.documentID
            
            // Get current family members
            db.collection("patients").document(patientID).getDocument { snapshot, error in
                if let error = error {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }
                
                guard let document = snapshot, document.exists else {
                    alertMessage = "Patient document not found"
                    showingAlert = true
                    return
                }
                
                // Get current family members array
                guard var familyMembers = document.data()?["family_members"] as? [[String: Any]] else {
                    alertMessage = "Could not retrieve family members"
                    showingAlert = true
                    return
                }
                
                // Filter out the family member to remove
                let initialCount = familyMembers.count
                familyMembers = familyMembers.filter { member in
                    return !(member["name"] as? String == existingUser.name &&
                             member["phoneNumber"] as? String == existingUser.phoneNumber)
                }
                
                // Check if we actually removed someone
                if familyMembers.count == initialCount {
                    alertMessage = "Could not find the family member to remove"
                    showingAlert = true
                    return
                }
                
                // Update Firestore
                db.collection("patients").document(patientID).updateData([
                    "family_members": familyMembers
                ]) { error in
                    if let error = error {
                        alertMessage = "Error removing member: \(error.localizedDescription)"
                        showingAlert = true
                    } else {
                        // Clear the user binding and dismiss the sheet
                        user = nil
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
