import SwiftUI
import Firebase
import FirebaseFirestore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isAuthenticated = false
    @State private var isSuperAdmin = false
    @State private var isDoctor = false
    @State private var isPatient = false
    @State private var hospitalId: String = ""
    @State private var doctorId: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var hospitalLocation: String = ""
    @State private var PatEmail: String = ""
    
    var dummy = AppointmentManager.shared.patientEmail
    var isEmailValid: Bool {
        return email.contains("@")
    }

    var isLoginDisabled: Bool {
        return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               !isEmailValid
    }

    var body: some View {
        VStack {
            if isAuthenticated {
                if isSuperAdmin {
                    SuperAdminDashboardView()
                } else if isDoctor {
                    DocTabCar( doctorId: doctorId, hospitalId: hospitalId)
                } else if isPatient {
                    MainTabView(hospitalLocation: hospitalLocation, patientEmail: email)
                }
                else {
                    AdminDashboardView(hospitalId: hospitalId)
                }
            } else {
                loginForm
            }
        }
        .background(Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    var loginForm: some View {
        VStack {
            Spacer()

            Text("Log In")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 15) {
                Text("Email")
                    .fontWeight(.medium)

                TextField("Enter your email", text: $email)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 1)
                    .autocapitalization(.none)
                    .onChange(of: email) { _ in
                        errorMessage = ""
                    }

                if !isEmailValid && !email.isEmpty {
                    Text("Invalid email")
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Text("Password")
                    .fontWeight(.medium)

                SecureField("Enter your password", text: $password)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 1)
            }
            .padding(.horizontal, 30)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }

            Button(action: loginUser) {
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoginDisabled ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            .disabled(isLoginDisabled)

            Button(action: forgotPassword) {
                Text("Forgot Password?")
                    .foregroundColor(.blue)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 30)

            Spacer()
            
            Button(action: redirectToRegister) {
                Text("New here? Register")
                    .foregroundColor(.blue)
                    .font(.body)
                    .padding(.vertical, 10)
            }
        }
    }
    func redirectToRegister() {
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView: PatientRegistrationView())
            window.makeKeyAndVisible()
        }
    }


//    func loginUser() {
//        guard !email.isEmpty, !password.isEmpty, isEmailValid else {
//            showAlertMessage("Invalid email or missing fields.")
//            return
//        }
//
//        let db = Firestore.firestore()

        // 🔵 Step 1: Check Super Admins
        func loginUser() {
            guard !email.isEmpty, !password.isEmpty, isEmailValid else {
                showAlertMessage("Invalid email or missing fields.")
                return
            }

            let db = Firestore.firestore()

            // 🔵 Step 1: Check Super Admins
            db.collection("superAdmins").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching superAdmins: \(error.localizedDescription)")
                    showAlertMessage("Error: \(error.localizedDescription)")
                    return
                }

                if let document = snapshot?.documents.first {
                    let storedPassword = document.data()["password"] as? String ?? ""
                    print("✅ Super Admin found with email: \(email)")

                    if password == storedPassword {
                        DispatchQueue.main.async {
                            isAuthenticated = true
                            isSuperAdmin = true
                            errorMessage = ""
                        }
                        return
                    } else {
                        print("❌ Incorrect password for super admin")
                        showAlertMessage("Invalid email or password.")
                        return
                    }
                }

                // 🔵 Step 2: Check Admins
                db.collection("admin_credentials").whereField("email", isEqualTo: email).getDocuments { adminSnapshot, adminError in
                    if let adminError = adminError {
                        print("❌ Error fetching admin_credentials: \(adminError.localizedDescription)")
                        showAlertMessage("Error: \(adminError.localizedDescription)")
                        return
                    }

                    if let adminDoc = adminSnapshot?.documents.first {
                        let storedAdminPassword = adminDoc.data()["password"] as? String ?? ""
                        let fetchedHospitalId = adminDoc.data()["HospitalID"] as? String ?? ""

                        print("✅ Admin found with email: \(email), HospitalID: \(fetchedHospitalId)")

                        if password == storedAdminPassword {
                            DispatchQueue.main.async {
                                isAuthenticated = true
                                isSuperAdmin = false
                                hospitalId = fetchedHospitalId
                            }
                            return
                        } else {
                            print("❌ Incorrect password for admin")
                        }
                    }

                    // 🔵 Step 3: Check Doctors
                    db.collection("doctor_creds").whereField("email", isEqualTo: email).getDocuments { doctorSnapshot, doctorError in
                        if let doctorError = doctorError {
                            print("❌ Error fetching doctor_creds: \(doctorError.localizedDescription)")
                            showAlertMessage("Error: \(doctorError.localizedDescription)")
                            return
                        }

                        if let doctorDoc = doctorSnapshot?.documents.first {
                            let storedDoctorPassword = doctorDoc.data()["password"] as? String ?? ""
                            let fetchedHospitalId = doctorDoc.data()["HospitalId"] as? String ?? ""
                            let fetchedDoctorId = doctorDoc.documentID

                            print("✅ Doctor found with email: \(email), DoctorID: \(fetchedDoctorId), HospitalID: \(fetchedHospitalId)")

                            if password == storedDoctorPassword {
                                DispatchQueue.main.async {
                                    isAuthenticated = true
                                    isDoctor = true
                                    doctorId = fetchedDoctorId
                                    hospitalId = fetchedHospitalId
                                }
                                return
                            } else {
                                print("❌ Incorrect password for doctor")
                            }
                        }

                        // 🔵 Step 4: Check User Credentials
                        db.collection("patients").whereField("email", isEqualTo: email).getDocuments { userSnapshot, userError in
                            if let userError = userError {
                                print("❌ Error fetching user_creds: \(userError.localizedDescription)")
                                showAlertMessage("Error: \(userError.localizedDescription)")
                                return
                            }

                            if let userDoc = userSnapshot?.documents.first {
                                let storedUserPassword = userDoc.data()["password"] as? String ?? ""
                                let fetchedHospitalLocation = userDoc.data()["location"] as? String ?? ""
                                print("✅ User found with email: \(email)")

                                if password == storedUserPassword {
                                    DispatchQueue.main.async {
                                        isAuthenticated = true
                                        isSuperAdmin = false
                                        isDoctor = false
                                        isPatient = true
//                                        hospitalId = ""
//                                        doctorId = ""
                                        hospitalLocation = fetchedHospitalLocation
                                        PatEmail = email
                                        AppointmentManager.shared.setPatientEmail(email)
                                    }
                                    return
                                } else {
                                    print("❌ Incorrect password for user")
                                }
                            }
                            print("❌ No matching user found in any category")
                            showAlertMessage("Invalid email or password.")
                        }
                    }
                }
            }
        }


    
    func forgotPassword() {
        showAlertMessage("Please contact the development team.")
    }
    
    func showAlertMessage(_ message: String) {
        DispatchQueue.main.async {
            alertMessage = message
            showAlert = true
        }
    }
}
