import SwiftUI
import FirebaseFirestore

// **Doctor List View**
struct DoctorList: View {
    @State private var searchText: String = ""
    let doctors: [DoctorModel]  // ✅ Dynamic List Passed
    var patientEmail:String
    var filteredDoctors: [DoctorModel] {
        if searchText.isEmpty {
            return doctors
        } else {
            return doctors.filter {
                $0.firstName.localizedCaseInsensitiveContains(searchText) ||
                $0.lastName.localizedCaseInsensitiveContains(searchText) ||
                $0.specialization.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView { // ✅ Wrap in NavigationView
            VStack {
                Text("Doctors")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)

                SearchBar(searchText: $searchText)
                    .padding(.horizontal)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(filteredDoctors) { doctor in
                            NavigationLink(destination: PatientDoctorDetailView(doctor: doctor, patientEmail: patientEmail)) { // ✅ Navigate on tap
                                DoctorCard(doctor: doctor)
                                    .frame(width: 170, height: 260)
                            }
                            .buttonStyle(PlainButtonStyle()) // Removes default NavigationLink styling
                        }
                    }
                    .padding()
                }
            }
            .background(Color(uiColor: UIColor.systemGroupedBackground))
        }
    }
}

// **Doctor Card Component**
struct DoctorCard: View {
    let doctor: DoctorModel
    @State private var outpatientFees: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 10) {
            // Profile Image
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
                .background(Color(uiColor: UIColor.systemGray5))
                .clipShape(Circle())
//                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            
            // Doctor's Name
            Text("Dr. \(doctor.firstName) ")
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 160)
            
            // Specialization
            Text(doctor.specialization)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // Experience with Apple Logo
            HStack(spacing: 6) {
                Image(systemName: "stethoscope")
                    .foregroundColor(.blue)
                Text("\(doctor.experience) years experience")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            
            // Fees Section
            Text("₹\(outpatientFees)")
                .font(.footnote)
                .foregroundColor(.blue)
                .bold()
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
//                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .onAppear {
                    fetchOutpatientFees()
                }
        }
        .padding()
        
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 3)
    }
    // **Function to Fetch Outpatient Fees**
    private func fetchOutpatientFees() {
        let db = Firestore.firestore()
        let doctorRef = db.collection("doctors").document(doctor.id) // Assuming `doctor.id` is the document ID

        doctorRef.getDocument { document, error in
            if let document = document, document.exists {
                if let fees = document.get("outpatientFees") as? String {
                    self.outpatientFees = fees
                } else {
                    self.outpatientFees = "N/A"
                }
            } else {
                self.outpatientFees = "Error"
                print("Error fetching fees: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

// **Preview with Sample Data**
struct DoctorList_Previews: PreviewProvider {
    static var previews: some View {
        DoctorList(doctors: [
            DoctorModel(
                id: "1",
                firstName: "John",
                lastName: "Doe",
                specialization: "Cardiologist",
                phone: "1234567890",
                email: "johndoe@example.com",
                experience: "10",
                degrees: ["MBBS", "MD"],
                medicalLicenseId: "ABC123",
                bankAccountNumber: "123456789012",
                address: "123 Main Street"
            ),
            DoctorModel(
                id: "2",
                firstName: "Sarah",
                lastName: "Lee",
                specialization: "Dermatologist",
                phone: "0987654321",
                email: "sarahlee@example.com",
                experience: "8",
                degrees: ["MBBS", "DDV"],
                medicalLicenseId: "XYZ456",
                bankAccountNumber: "987654321098",
                address: "456 Elm Street"
            )
        ], patientEmail: "shivamdubey177@gmail.com")
    }
}
